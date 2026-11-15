const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Utilitário para enviar FCM para uma lista de tokens ou token único
 */
async function sendPushNotification(tokens, payload) {
  if (!tokens || tokens.length === 0) return;
  const tokenList = Array.isArray(tokens) ? [...new Set(tokens.filter(Boolean))] : [tokens];
  if (tokenList.length === 0) return;

  const message = {
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: Object.keys(payload.data || {}).reduce((acc, key) => {
      acc[key] = String(payload.data[key]);
      return acc;
    }, {}),
    android: {
      priority: "high",
      notification: {
        channelId: "festja_high_importance_channel",
        sound: "default",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
    tokens: tokenList,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`Pushes enviados: ${response.successCount} sucesso, ${response.failureCount} falhas.`);
  } catch (error) {
    console.error("Erro ao enviar multicast FCM:", error);
  }
}

/**
 * 1. Gatilho: Nova Reserva / Solicitação de Proposta
 * Envia notificação nativa para a Empresa destinatária
 */
exports.onBookingCreated = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    const { businessId, clientName, serviceTitle, eventId, orderId } = booking;
    if (!businessId) return null;

    console.log(`Nova reserva ${context.params.bookingId} para a empresa ${businessId}`);

    // Buscar tokens FCM da empresa
    const bizDoc = await db.collection("businesses").doc(businessId).get();
    if (!bizDoc.exists) return null;

    const bizData = bizDoc.data();
    const tokens = bizData.fcmTokens || (bizData.fcmToken ? [bizData.fcmToken] : []);

    // Se a empresa possui o criador (usuário proprietário), buscar também nos tokens do usuário
    if (bizData.creator && bizData.creator.id) {
      const userDoc = await db.collection("users").doc(bizData.creator.id).get();
      if (userDoc.exists) {
        const uData = userDoc.data();
        if (uData.fcmTokens) tokens.push(...uData.fcmTokens);
        else if (uData.fcmToken) tokens.push(uData.fcmToken);
      }
    }

    const title = "Nova Solicitação de Reserva! 🎉";
    const body = `${clientName || "Um cliente"} enviou uma solicitação para "${serviceTitle || "seu serviço"}".`;

    // 1. Enviar push nativo para o device da empresa
    await sendPushNotification(tokens, {
      title,
      body,
      data: {
        bookingId: context.params.bookingId,
        eventId: eventId || "",
        orderId: orderId || "",
        type: "booking_request",
      },
    });

    // 2. Gravar notificação in-app na subcoleção da empresa se ainda não gravada
    const notifRef = db.collection("businesses").doc(businessId).collection("notifications").doc();
    await notifRef.set({
      id: notifRef.id,
      title,
      body,
      type: "booking_request",
      data: {
        bookingId: context.params.bookingId,
        eventId: eventId || "",
        orderId: orderId || "",
        type: "booking_request",
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * 2. Gatilho: Atualização de Status da Reserva (Aprovada ou Recusada)
 * Envia notificação nativa para o Cliente que realizou o pedido
 */
exports.onBookingStatusUpdated = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return null;
    if (after.status !== "approved" && after.status !== "declined") return null;

    const { clientId, serviceTitle, eventId } = after;
    if (!clientId) return null;

    const isApproved = after.status === "approved";
    console.log(`Reserva ${context.params.bookingId} foi ${after.status}. Notificando cliente ${clientId}.`);

    // Buscar tokens do cliente
    const userDoc = await db.collection("users").doc(clientId).get();
    if (!userDoc.exists) return null;

    const uData = userDoc.data();
    const tokens = uData.fcmTokens || (uData.fcmToken ? [uData.fcmToken] : []);

    const title = isApproved ? "Reserva Aprovada! 🎉" : "Atualização da Reserva";
    const body = isApproved
      ? `Sua reserva para "${serviceTitle || "o serviço"}" foi aprovada pelo fornecedor!`
      : `Sua solicitação de reserva para "${serviceTitle || "o serviço"}" foi recusada.`;

    const type = isApproved ? "booking_approved" : "booking_declined";

    // 1. Enviar push nativo
    await sendPushNotification(tokens, {
      title,
      body,
      data: {
        bookingId: context.params.bookingId,
        eventId: eventId || "",
        status: after.status,
        type,
      },
    });

    // 2. Gravar notificação in-app para o cliente
    const notifRef = db.collection("users").doc(clientId).collection("notifications").doc();
    await notifRef.set({
      id: notifRef.id,
      title,
      body,
      type,
      data: {
        bookingId: context.params.bookingId,
        eventId: eventId || "",
        status: after.status,
        type,
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * 3. Gatilho: Nova Mensagem no Chat
 * Envia notificação para o participante que não é o remetente da mensagem
 */
exports.onNewChatMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { chatId } = context.params;

    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) return null;

    const chat = chatDoc.data();
    const isSenderClient = message.senderId === chat.clientId;

    // Se o remetente foi o cliente, o destinatário é a empresa; caso contrário, é o cliente
    let tokens = [];
    let title = "";

    if (isSenderClient) {
      // Notificar Empresa
      title = chat.clientName || "Cliente";
      const bizDoc = await db.collection("businesses").doc(chat.businessId).get();
      if (bizDoc.exists) {
        const bData = bizDoc.data();
        if (bData.fcmTokens) tokens.push(...bData.fcmTokens);
        else if (bData.fcmToken) tokens.push(bData.fcmToken);

        if (bData.creator && bData.creator.id) {
          const userDoc = await db.collection("users").doc(bData.creator.id).get();
          if (userDoc.exists) {
            const uData = userDoc.data();
            if (uData.fcmTokens) tokens.push(...uData.fcmTokens);
            else if (uData.fcmToken) tokens.push(uData.fcmToken);
          }
        }
      }
    } else {
      // Notificar Cliente
      title = chat.businessName || "Fornecedor Fest'Ja";
      const userDoc = await db.collection("users").doc(chat.clientId).get();
      if (userDoc.exists) {
        const uData = userDoc.data();
        if (uData.fcmTokens) tokens.push(...uData.fcmTokens);
        else if (uData.fcmToken) tokens.push(uData.fcmToken);
      }
    }

    await sendPushNotification(tokens, {
      title,
      body: message.text || "Enviou uma nova mensagem.",
      data: {
        chatId,
        type: "new_message",
      },
    });

    return null;
  });

/**
 * 4. Cron diário: Lembrete de Evento Próximo (24 horas antes)
 * Executado todo dia às 09:00 (horário de Brasília)
 */
exports.eventReminderCron = functions.pubsub
  .schedule("0 9 * * *")
  .timeZone("America/Sao_Paulo")
  .onRun(async (context) => {
    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const in48Hours = new Date(now.getTime() + 48 * 60 * 60 * 1000);

    const snapshot = await db
      .collection("events")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(in24Hours))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(in48Hours))
      .get();

    console.log(`Cron: Encontrados ${snapshot.size} eventos próximos para lembrete.`);

    for (const doc of snapshot.docs) {
      const event = doc.data();
      const ownerId = event.owner ? event.owner.id : null;
      if (!ownerId) continue;

      const userDoc = await db.collection("users").doc(ownerId).get();
      if (!userDoc.exists) continue;

      const tokens = userDoc.data().fcmTokens || [];
      const title = "Lembrete do seu Evento! 🎈";
      const body = `Faltam menos de 48h para o seu evento "${event.title}"! Verifique os serviços confirmados.`;

      await sendPushNotification(tokens, {
        title,
        body,
        data: {
          eventId: doc.id,
          type: "event_reminder",
        },
      });

      // Gravar in-app
      await db.collection("users").doc(ownerId).collection("notifications").add({
        title,
        body,
        type: "event_reminder",
        data: { eventId: doc.id, type: "event_reminder" },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return null;
  });

/**
 * 5. Disparo de Pushes em Massa / Tópicos (Ex: all_clients, all_businesses)
 */
exports.sendBroadcastPush = functions.https.onCall(async (data, context) => {
  const { topic, title, body, customData } = data;
  if (!topic || !title || !body) {
    throw new functions.https.HttpsError("invalid-argument", "topic, title e body são obrigatórios.");
  }

  const message = {
    notification: { title, body },
    data: Object.keys(customData || {}).reduce((acc, key) => {
      acc[key] = String(customData[key]);
      return acc;
    }, {}),
    topic,
  };

  try {
    const response = await admin.messaging().send(message);
    return { success: true, messageId: response };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
