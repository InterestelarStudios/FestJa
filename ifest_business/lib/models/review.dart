import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookingId;
  final String businessId;
  final String? serviceId;
  final String serviceTitle;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final double rating;
  final String comment;
  final Timestamp created;

  Review({
    required this.id,
    required this.bookingId,
    required this.businessId,
    this.serviceId,
    required this.serviceTitle,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.rating,
    required this.comment,
    required this.created,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'businessId': businessId,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'rating': rating,
      'comment': comment,
      'created': created,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Review(
      id: docId ?? map['id'] as String? ?? '',
      bookingId: map['bookingId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      serviceId: map['serviceId'] as String?,
      serviceTitle: map['serviceTitle'] as String? ?? 'Serviço',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Cliente',
      authorPhoto: map['authorPhoto'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String? ?? '',
      created: map['created'] as Timestamp? ?? Timestamp.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Review.fromJson(String source) =>
      Review.fromMap(json.decode(source) as Map<String, dynamic>);
}
