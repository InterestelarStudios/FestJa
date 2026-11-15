import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  String id;
  String serviceId;
  String serviceTitle;
  String businessId;
  String? businessName;
  String clientId;
  String clientName;
  String clientPhone;
  num price;
  Timestamp eventDate;
  String status; // 'in_progress', 'completed', 'cancelled'
  bool reviewed;
  double? reviewRating;
  Timestamp created;

  Booking({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.businessId,
    this.businessName,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.price,
    required this.eventDate,
    required this.status,
    this.reviewed = false,
    this.reviewRating,
    required this.created,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'businessId': businessId,
      'businessName': businessName,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'price': price,
      'eventDate': eventDate,
      'status': status,
      'reviewed': reviewed,
      'reviewRating': reviewRating,
      'created': created,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String? ?? '',
      serviceId: map['serviceId'] as String? ?? '',
      serviceTitle: map['serviceTitle'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      businessName: map['businessName'] as String?,
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      clientPhone: map['clientPhone'] as String? ?? '',
      price: map['price'] as num? ?? 0,
      eventDate: map['eventDate'] as Timestamp? ?? Timestamp.now(),
      status: map['status'] as String? ?? 'in_progress',
      reviewed: map['reviewed'] as bool? ?? false,
      reviewRating: (map['reviewRating'] as num?)?.toDouble(),
      created: map['created'] as Timestamp? ?? Timestamp.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Booking.fromJson(String source) =>
      Booking.fromMap(json.decode(source) as Map<String, dynamic>);
}
