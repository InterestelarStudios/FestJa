import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ifest_app/models/booking.dart';
import 'package:ifest_app/models/review.dart';
import 'package:ifest_app/services/notification_service.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica se o cliente tem algum serviço concluído pendente de avaliação
  Future<Booking?> checkPendingReview(String clientId) async {
    try {
      final query = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'completed')
          .limit(5)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final isReviewed = data['reviewed'] == true;
        if (!isReviewed) {
          if (!data.containsKey('id')) data['id'] = doc.id;
          return Booking.fromMap(data);
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar avaliações pendentes: $e');
    }
    return null;
  }

  /// Submete uma avaliação e atualiza as métricas da empresa
  Future<void> submitReview({
    required Booking booking,
    required double rating,
    required String comment,
    required User user,
  }) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc();
      final review = Review(
        id: reviewRef.id,
        bookingId: booking.id,
        businessId: booking.businessId,
        serviceId: booking.serviceId,
        serviceTitle: booking.serviceTitle,
        authorId: user.uid,
        authorName: user.displayName ?? 'Cliente',
        authorPhoto: user.photoURL,
        rating: rating,
        comment: comment.trim(),
        created: Timestamp.now(),
      );

      // 1. Salvar documento na coleção reviews
      await reviewRef.set(review.toMap());

      // 2. Atualizar o documento da reserva
      await _firestore.collection('bookings').doc(booking.id).update({
        'reviewed': true,
        'reviewRating': rating,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // 3. Recalcular média e total de avaliações da empresa
      final reviewsSnap = await _firestore
          .collection('reviews')
          .where('businessId', isEqualTo: booking.businessId)
          .get();

      final totalReviews = reviewsSnap.docs.length;
      final sumRating = reviewsSnap.docs.fold<double>(
        0.0,
        (acc, doc) => acc + ((doc.data()['rating'] as num?)?.toDouble() ?? 5.0),
      );
      final averageRating = totalReviews > 0 ? sumRating / totalReviews : rating;

      await _firestore.collection('businesses').doc(booking.businessId).update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
        'reviewCount': totalReviews,
      });

      // 4. Notificar a empresa
      await NotificationService().sendNotificationToBusiness(
        businessId: booking.businessId,
        title: 'Nova Avaliação Recebida! ⭐',
        body: '${user.displayName ?? "Um cliente"} avaliou seu serviço "${booking.serviceTitle}" com ${rating.toInt()} estrelas.',
        type: 'new_review',
        data: {
          'reviewId': reviewRef.id,
          'bookingId': booking.id,
          'rating': rating,
        },
      );
    } catch (e) {
      debugPrint('Erro ao submeter avaliação: $e');
      rethrow;
    }
  }

  /// Stream das avaliações de uma empresa
  Stream<List<Review>> streamBusinessReviews(String businessId) {
    return _firestore
        .collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .orderBy('created', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }
}
