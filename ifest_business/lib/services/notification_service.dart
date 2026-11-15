import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ifest_business/models/business.dart';
import 'package:ifest_business/models/chat_model.dart';
import 'package:ifest_business/models/notification_model.dart';
import 'package:ifest_business/screens/business/bookings_screen.dart';
import 'package:ifest_business/screens/chat/chat_room_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'festja_high_importance_channel',
    'Notificações Fest\'Ja Empresas',
    description: 'Canal de notificações importantes para empresas do Fest\'Ja',
    importance: Importance.max,
    playSound: true,
  );

  GlobalKey<NavigatorState>? navigatorKey;
  bool _initialized = false;
  Business? currentBusiness;

  String? _lastSyncedToken;
  String? _lastSyncedUid;
  String? _lastSyncedBusinessId;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> init({GlobalKey<NavigatorState>? navKey}) async {
    if (_initialized) return;
    _initialized = true;
    navigatorKey = navKey;

    // 1. Configurar Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Solicitar permissões nativas
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM Notification permission status: ${settings.authorizationStatus}');

    // 3. Inicializar Local Notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(initSettings);

    // 4. Criar o canal de alta importância
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    // 5. Escutar mensagens em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 6. Escutar clique na notificação em segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened from background: ${message.data}');
      _handleMessageData(message.data);
    });

    // 7. Verificar notificação inicial (estado terminado)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM initial message: ${initialMessage.data}');
      _handleMessageData(initialMessage.data);
    }

    // 8. Inscrever no tópico geral dos negócios
    try {
      await _fcm.subscribeToTopic('all_businesses');
    } catch (e) {
      debugPrint('Erro ao se inscrever no topico all_businesses: $e');
    }

    // 9. Configurar listener de refresh do token apenas uma vez
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        syncFcmToken(uid: user.uid, businessId: currentBusiness?.id, force: true);
      }
    });

    // 10. Sincronizar token se o usuário já estiver logado
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      syncFcmToken(uid: user.uid);
    }

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        syncFcmToken(uid: user.uid, businessId: currentBusiness?.id);
      } else {
        _lastSyncedToken = null;
        _lastSyncedUid = null;
        _lastSyncedBusinessId = null;
      }
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['type'],
      );
    }
  }

  Future<void> syncFcmToken({
    required String uid,
    String? businessId,
    bool force = false,
  }) async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      // Evitar escritas repetidas no Firestore se o token já foi sincronizado
      if (!force &&
          _lastSyncedToken == token &&
          _lastSyncedUid == uid &&
          _lastSyncedBusinessId == businessId) {
        return;
      }

      _lastSyncedToken = token;
      _lastSyncedUid = uid;
      _lastSyncedBusinessId = businessId;

      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      if (businessId != null && businessId.isNotEmpty) {
        await _firestore.collection('businesses').doc(businessId).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));
      }

      debugPrint('FCM Token synced for business user $uid (business: $businessId)');
    } catch (e) {
      debugPrint('Erro ao sincronizar FCM token: $e');
    }
  }

  // --- NAVEGAÇÃO CONTEXTUAL ---

  void _handleMessageData(Map<String, dynamic> data) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    navigateToDestination(context, data);
  }

  Future<void> navigateToDestination(BuildContext context, Map<String, dynamic> data) async {
    final type = data['type'] as String?;

    try {
      if (type == 'new_message' && data.containsKey('chatId')) {
        final chatId = data['chatId'] as String;
        final doc = await _firestore.collection('chats').doc(chatId).get();
        if (doc.exists && context.mounted) {
          final chat = ChatRoom.fromMap(doc.data()!, doc.id);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatRoomScreen(chat: chat)),
          );
        }
      } else if (type == 'booking_request') {
        if (currentBusiness != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingsScreen(business: currentBusiness!),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro na navegação da notificação no app business: $e');
    }
  }

  // --- NOTIFICAÇÕES INTERNAS (IN-APP) DA EMPRESA ---

  Stream<List<AppNotification>> streamBusinessNotifications(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AppNotification.fromDoc(doc)).toList());
  }

  Stream<int> streamBusinessUnreadCount(String businessId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String businessId, String notificationId) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String businessId) async {
    final batch = _firestore.batch();
    final query = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String businessId, String notificationId) async {
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> clearAll(String businessId) async {
    final batch = _firestore.batch();
    final query = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('notifications')
        .get();

    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Dispara a gravação da notificação in-app para um cliente (usado ao aprovar/recusar reserva)
  Future<void> sendNotificationToClient({
    required String clientId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(clientId)
          .collection('notifications')
          .doc();

      final notification = AppNotification(
        id: docRef.id,
        title: title,
        body: body,
        type: type,
        data: data ?? {},
        isRead: false,
        createdAt: Timestamp.now(),
      );

      await docRef.set(notification.toMap());
    } catch (e) {
      debugPrint('Erro ao enviar notificação in-app para cliente: $e');
    }
  }
}
