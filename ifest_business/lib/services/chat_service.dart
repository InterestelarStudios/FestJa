import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ifest_business/models/chat_model.dart';
import 'package:ifest_business/services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Retrieves or initializes a chat room tied to a booking/order.
  Future<ChatRoom> getOrCreateBookingChat({
    required String bookingId,
    required String orderId,
    required String serviceId,
    required String serviceTitle,
    required String serviceImage,
    required double servicePrice,
    required String businessId,
    required String businessName,
    String businessLogo = '',
    String? businessOwnerId,
    required String clientId,
    required String clientName,
    String clientImage = '',
    String clientPhone = '',
    String bookingStatus = 'in_progress',
    Timestamp? eventDate,
  }) async {
    final chatDocRef = _firestore.collection('chats').doc(bookingId);
    final docSnapshot = await chatDocRef.get();

    final effectiveParticipants = <String>{
      clientId,
      businessId,
      if (businessOwnerId != null && businessOwnerId.isNotEmpty) businessOwnerId,
    }.toList();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return ChatRoom.fromMap(docSnapshot.data()!, docSnapshot.id);
    }

    final now = Timestamp.now();
    final newChat = ChatRoom(
      id: bookingId,
      bookingId: bookingId,
      orderId: orderId,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      serviceImage: serviceImage,
      servicePrice: servicePrice,
      businessId: businessId,
      businessName: businessName,
      businessLogo: businessLogo,
      clientId: clientId,
      clientName: clientName,
      clientImage: clientImage,
      clientPhone: clientPhone,
      participants: effectiveParticipants,
      lastMessage: 'Pedido criado! Inicie a conversa com o cliente.',
      lastMessageSenderId: 'system',
      lastMessageTime: now,
      unreadCountClient: 1,
      unreadCountBusiness: 0,
      bookingStatus: bookingStatus,
      eventDate: eventDate,
      createdAt: now,
      updatedAt: now,
    );

    await chatDocRef.set(newChat.toMap());
    return newChat;
  }

  /// Streams the list of all chats associated with a business.
  Stream<List<ChatRoom>> streamBusinessChats(String businessId) {
    return _firestore
        .collection('chats')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  /// Stream messages for a specific chat room with pagination limit.
  Stream<List<ChatMessage>> streamMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Sends a message using an atomic WriteBatch to update both the message collection and the parent chat summary.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    required bool isClient,
  }) async {
    if (text.trim().isEmpty) return;

    final trimmedText = text.trim();
    final batch = _firestore.batch();
    final messageDocRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();

    final messageData = {
      'id': messageDocRef.id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': trimmedText,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    batch.set(messageDocRef, messageData);

    final chatDocRef = _firestore.collection('chats').doc(chatId);
    final updateData = <String, dynamic>{
      'lastMessage': trimmedText,
      'lastMessageSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isClient) {
      updateData['unreadCountBusiness'] = FieldValue.increment(1);
    } else {
      updateData['unreadCountClient'] = FieldValue.increment(1);
    }

    batch.update(chatDocRef, updateData);
    await batch.commit();

    try {
      final chatSnap = await chatDocRef.get();
      if (chatSnap.exists) {
        final chatData = chatSnap.data()!;
        final clientId = chatData['clientId'] as String?;
        final businessName =
            chatData['businessName'] as String? ?? 'Fornecedor';
        if (clientId != null && clientId.isNotEmpty) {
          await NotificationService().sendNotificationToClient(
            clientId: clientId,
            title: businessName,
            body: trimmedText,
            type: 'new_message',
            data: {
              'chatId': chatId,
              'type': 'new_message',
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao notificar mensagem in-app: $e');
    }
  }

  /// Resets unread counter when entering the chat screen.
  Future<void> markChatAsRead({
    required String chatId,
    required bool isClient,
  }) async {
    try {
      final field = isClient ? 'unreadCountClient' : 'unreadCountBusiness';
      await _firestore.collection('chats').doc(chatId).update({field: 0});
    } catch (_) {}
  }

  /// Stream total unread messages count for business badge.
  Stream<int> streamTotalUnreadCount(String businessId) {
    return _firestore
        .collection('chats')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        count += (doc.data()['unreadCountBusiness'] as int? ?? 0);
      }
      return count;
    });
  }
}
