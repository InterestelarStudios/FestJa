import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String? bookingId;
  final String? orderId;
  final String serviceId;
  final String serviceTitle;
  final String serviceImage;
  final double servicePrice;
  final String businessId;
  final String businessName;
  final String businessLogo;
  final String clientId;
  final String clientName;
  final String clientImage;
  final String clientPhone;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageSenderId;
  final Timestamp lastMessageTime;
  final int unreadCountClient;
  final int unreadCountBusiness;
  final String? bookingStatus;
  final Timestamp? eventDate;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ChatRoom({
    required this.id,
    this.bookingId,
    this.orderId,
    required this.serviceId,
    required this.serviceTitle,
    this.serviceImage = '',
    required this.servicePrice,
    required this.businessId,
    required this.businessName,
    this.businessLogo = '',
    required this.clientId,
    required this.clientName,
    this.clientImage = '',
    this.clientPhone = '',
    required this.participants,
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    required this.lastMessageTime,
    this.unreadCountClient = 0,
    this.unreadCountBusiness = 0,
    this.bookingStatus,
    this.eventDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'orderId': orderId,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'serviceImage': serviceImage,
      'servicePrice': servicePrice,
      'businessId': businessId,
      'businessName': businessName,
      'businessLogo': businessLogo,
      'clientId': clientId,
      'clientName': clientName,
      'clientImage': clientImage,
      'clientPhone': clientPhone,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime,
      'unreadCountClient': unreadCountClient,
      'unreadCountBusiness': unreadCountBusiness,
      'bookingStatus': bookingStatus,
      'eventDate': eventDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ChatRoom(
      id: docId ?? (map['id'] as String? ?? ''),
      bookingId: map['bookingId'] as String?,
      orderId: map['orderId'] as String?,
      serviceId: map['serviceId'] as String? ?? '',
      serviceTitle: map['serviceTitle'] as String? ?? 'Serviço',
      serviceImage: map['serviceImage'] as String? ?? '',
      servicePrice: (map['servicePrice'] as num? ?? 0.0).toDouble(),
      businessId: map['businessId'] as String? ?? '',
      businessName: map['businessName'] as String? ?? 'Fornecedor',
      businessLogo: map['businessLogo'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? 'Cliente',
      clientImage: map['clientImage'] as String? ?? '',
      clientPhone: map['clientPhone'] as String? ?? '',
      participants: List<String>.from(map['participants'] as List? ?? []),
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] as String? ?? '',
      lastMessageTime: map['lastMessageTime'] as Timestamp? ?? Timestamp.now(),
      unreadCountClient: map['unreadCountClient'] as int? ?? 0,
      unreadCountBusiness: map['unreadCountBusiness'] as int? ?? 0,
      bookingStatus: map['bookingStatus'] as String?,
      eventDate: map['eventDate'] as Timestamp?,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final Timestamp timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ChatMessage(
      id: docId ?? (map['id'] as String? ?? ''),
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] as Timestamp? ?? Timestamp.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}
