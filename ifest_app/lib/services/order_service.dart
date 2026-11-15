import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ifest_app/models/event.dart';
import 'package:ifest_app/models/order.dart';
import 'package:ifest_app/models/user_data.dart';
import 'package:ifest_app/services/cart_service.dart';
import 'package:ifest_app/services/chat_service.dart';
import 'package:ifest_app/services/notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Retrieve saved customer data
  Future<UserData?> getUserData() async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('customerData') && data['customerData'] != null) {
          return UserData.fromMap(data['customerData'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      // Ignored / fallback to null
    }
    return null;
  }

  // Save customer billing data to user's profile
  Future<void> saveUserData(UserData data) async {
    final uid = _uid;
    if (uid == null) throw Exception("Usuário não autenticado");

    await _firestore.collection('users').doc(uid).set({
      'customerData': data.toMap(),
    }, SetOptions(merge: true));
  }

  // Create full order, dispatch bookings to businesses, and clear the cart
  Future<String> createOrder({
    required UserData customerData,
    required Event event,
    required List<CartItem> items,
    required double totalAmount,
    required String paymentMethod,
    int installments = 1,
    bool saveCustomerInfo = true,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception("Usuário não autenticado");

    if (saveCustomerInfo) {
      await saveUserData(customerData);
    }

    final orderId = _firestore.collection('orders').doc().id;
    final order = OrderModel(
      id: orderId,
      userId: uid,
      customerData: customerData,
      eventId: event.id,
      eventTitle: event.title,
      eventDate: event.date,
      items: items,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      installments: installments,
      status: 'approved', // Simulated successful authorization
      createdAt: Timestamp.now(),
    );

    // 1. Save order
    await _firestore.collection('orders').doc(orderId).set(order.toMap());

    // 2. Create bookings for each item/business
    for (final item in items) {
      final bookingId = _firestore.collection('bookings').doc().id;
      final optionsSummary = item.selectedOptionsSummary;
      final fullTitle = optionsSummary.isNotEmpty
          ? '${item.title} ($optionsSummary)'
          : item.title;

      await _firestore.collection('bookings').doc(bookingId).set({
        'id': bookingId,
        'orderId': orderId,
        'eventId': event.id,
        'eventTitle': event.title,
        'serviceId': item.serviceAdId,
        'serviceTitle': fullTitle,
        'businessId': item.businessId,
        'businessName': item.businessName,
        'clientId': uid,
        'clientName': customerData.name,
        'clientPhone': customerData.phone,
        'price': item.finalPrice * item.quantity,
        'quantity': item.quantity,
        'categories': item.categories,
        'eventDate': event.date,
        'status': 'in_progress',
        'created': FieldValue.serverTimestamp(),
      });

      // Also record under the event services subcollection for fast event details lookup
      await _firestore
          .collection('events')
          .doc(event.id)
          .collection('services')
          .doc(bookingId)
          .set({
        'id': bookingId,
        'orderId': orderId,
        'serviceId': item.serviceAdId,
        'serviceTitle': fullTitle,
        'businessId': item.businessId,
        'businessName': item.businessName,
        'image': item.image ?? '',
        'price': item.finalPrice * item.quantity,
        'quantity': item.quantity,
        'categories': item.categories,
        'created': FieldValue.serverTimestamp(),
      });

      // 3. Initialize the contextual chat room tied to this booking
      await ChatService().getOrCreateBookingChat(
        bookingId: bookingId,
        orderId: orderId,
        serviceId: item.serviceAdId,
        serviceTitle: fullTitle,
        serviceImage: item.image ?? '',
        servicePrice: item.finalPrice * item.quantity,
        businessId: item.businessId,
        businessName: item.businessName,
        clientId: uid,
        clientName: customerData.name,
        clientPhone: customerData.phone,
        bookingStatus: 'in_progress',
        eventDate: event.date,
      );

      // 4. Enviar notificação in-app para a empresa
      await NotificationService().sendNotificationToBusiness(
        businessId: item.businessId,
        title: 'Novo Pedido Confirmado! 🎉',
        body: '${customerData.name} confirmou o pedido de "$fullTitle".',
        type: 'booking_request',
        data: {
          'bookingId': bookingId,
          'orderId': orderId,
          'serviceId': item.serviceAdId,
          'eventId': event.id,
          'clientId': uid,
          'type': 'booking_request',
        },
      );
    }

    // 4. Clear user's cart
    await CartService().clearCart();

    return orderId;
  }
}
