import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ifest_business/models/booking.dart';
import 'package:ifest_business/services/notification_service.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream incoming bookings for a specific business
  Stream<List<Booking>> streamBusinessBookings(String businessId) {
    return _db
        .collection('bookings')
        .where('businessId', isEqualTo: businessId)
        .orderBy('created', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('id')) {
          data['id'] = doc.id;
        }
        return Booking.fromMap(data);
      }).toList();
    });
  }

  // Update booking status (approved / declined / completed)
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final docSnap = await _db.collection('bookings').doc(bookingId).get();

    final updateData = <String, dynamic>{
      'status': newStatus,
    };
    if (newStatus == 'completed') {
      updateData['completedAt'] = FieldValue.serverTimestamp();
      updateData['reviewed'] = false;
    }

    await _db.collection('bookings').doc(bookingId).update(updateData);

    // Also update linked chat room bookingStatus
    final chatsQuery = await _db.collection('chats').where('bookingId', isEqualTo: bookingId).limit(1).get();
    if (chatsQuery.docs.isNotEmpty) {
      await chatsQuery.docs.first.reference.update({'bookingStatus': newStatus});
    }

    if (docSnap.exists) {
      final data = docSnap.data()!;
      final clientId = data['clientId'] as String? ?? '';
      final serviceTitle = data['serviceTitle'] as String? ?? 'Serviço';
      final eventId = data['eventId'] as String? ?? '';

      String title;
      String body;
      String type;

      if (newStatus == 'completed') {
        title = 'Serviço Finalizado! ⭐';
        body = 'O serviço "$serviceTitle" foi finalizado pelo fornecedor. Que tal avaliá-lo agora?';
        type = 'booking_completed';
      } else if (newStatus == 'cancelled') {
        title = 'Pedido Cancelado';
        body = 'O fornecedor precisou cancelar o pedido para "$serviceTitle".';
        type = 'booking_cancelled';
      } else {
        title = 'Atualização do Pedido';
        body = 'O status do seu pedido para "$serviceTitle" foi alterado.';
        type = 'booking_updated';
      }

      if (clientId.isNotEmpty) {
        await NotificationService().sendNotificationToClient(
          clientId: clientId,
          title: title,
          body: body,
          type: type,
          data: {
            'bookingId': bookingId,
            'eventId': eventId,
            'status': newStatus,
            'type': type,
          },
        );
      }
    }
  }
}
