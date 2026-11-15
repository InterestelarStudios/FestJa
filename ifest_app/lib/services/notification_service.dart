import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ifest_app/models/chat_model.dart';
import 'package:ifest_app/models/event.dart';
import 'package:ifest_app/models/notification_model.dart';
import 'package:ifest_app/screens/chat/chat_room_screen.dart';
import 'package:ifest_app/screens/events/event_details_screen.dart';
import 'package:ifest_app/screens/events/my_events_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Executado em segundo plano ou quando o app está fechado
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
    'Notificações Fest\'Ja',
    description: 'Canal de notificações importantes do Fest\'Ja',
    importance: Importance.max,
    playSound: true,
  );

  GlobalKey<NavigatorState>? navigatorKey;
  bool _initialized = false;
  String? _lastSyncedToken;
  String? _lastSyncedUid;
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

    // 3. Inicializar Local Notifications para Android/iOS em primeiro plano
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification clicked with payload: ${response.payload}');
      },
    );

    // 4. Criar o canal de alta importância no Android
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    // 5. Escutar mensagens com app em primeiro plano (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 6. Escutar clique na notificação quando o app está em segundo plano (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened from background: ${message.data}');
      _handleMessageData(message.data);
    });

    // 7. Verificar se o app foi aberto por um push quando estava completamente fechado (Terminated)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM initial message: ${initialMessage.data}');
      _handleMessageData(initialMessage.data);
    }

    // 8. Inscrever no tópico geral dos clientes
    try {
      await _fcm.subscribeToTopic('all_clients');
    } catch (e) {
      debugPrint('Erro ao se inscrever no topico all_clients: $e');
    }

    // 9. Configurar listener de refresh do token apenas uma vez
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        syncFcmToken(user.uid, force: true);
      }
    });

    // 10. Sincronizar token se o usuário já estiver logado
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      syncFcmToken(user.uid);
    }

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        syncFcmToken(user.uid);
      } else {
        _lastSyncedToken = null;
        _lastSyncedUid = null;
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

  Future<void> syncFcmToken(String uid, {bool force = false}) async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      if (!force && _lastSyncedToken == token && _lastSyncedUid == uid) {
        return;
      }

      _lastSyncedToken = token;
      _lastSyncedUid = uid;

      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
      debugPrint('FCM Token synced for client user $uid');
    } catch (e) {
      debugPrint('Erro ao sincronizar FCM token: $e');
    }
  }

  // --- NAVEGAÇÃO CONTEXTUAL (DEEP-LINKING) ---

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
      } else if ((type == 'booking_approved' || type == 'booking_declined') && data.containsKey('eventId')) {
        final eventId = data['eventId'] as String;
        final doc = await _firestore.collection('events').doc(eventId).get();
        if (doc.exists && context.mounted) {
          final event = Event.fromMap(doc.data()!);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)),
          );
        } else if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyEventsScreen()),
          );
        }
      } else if (type == 'event_reminder') {
        if (data.containsKey('eventId')) {
          final eventId = data['eventId'] as String;
          final doc = await _firestore.collection('events').doc(eventId).get();
          if (doc.exists && context.mounted) {
            final event = Event.fromMap(doc.data()!);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)),
            );
            return;
          }
        }
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyEventsScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro na navegação da notificação: $e');
    }
  }

  // --- CENTRAL DE NOTIFICAÇÕES INTERNAS (IN-APP) ---

  Stream<List<AppNotification>> streamNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AppNotification.fromDoc(doc)).toList());
  }

  Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> clearAll(String userId) async {
    final batch = _firestore.batch();
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get();

    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Dispara a gravação da notificação in-app para uma empresa (usado ao enviar reserva/proposta)
  Future<void> sendNotificationToBusiness({
    required String businessId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final docRef = _firestore
          .collection('businesses')
          .doc(businessId)
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
      debugPrint('Erro ao enviar notificação in-app para empresa: $e');
    }
  }

  /// Dispara a gravação da notificação in-app para um cliente
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
