import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ifest_app/models/user_data.dart';
import 'package:ifest_app/services/cart_service.dart';

class OrderModel {
  final String id;
  final String userId;
  final UserData customerData;
  final String eventId;
  final String eventTitle;
  final Timestamp eventDate;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMethod; // 'pix', 'credit_card'
  final int installments;
  final String status; // 'in_progress', 'completed', 'cancelled'
  final Timestamp createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.customerData,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    this.installments = 1,
    this.status = 'in_progress',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerData': customerData.toMap(),
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDate': eventDate,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'installments': installments,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      customerData: UserData.fromMap(map['customerData'] as Map<String, dynamic>),
      eventId: map['eventId'] as String? ?? '',
      eventTitle: map['eventTitle'] as String? ?? '',
      eventDate: map['eventDate'] as Timestamp? ?? Timestamp.now(),
      items: (map['items'] as List?)
              ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num? ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] as String? ?? 'pix',
      installments: map['installments'] as int? ?? 1,
      status: map['status'] as String? ?? 'in_progress',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
