import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ifest_app/models/service_ads.dart';

class SelectedVariantOption {
  final String variantName;
  final String optionName;
  final double priceAdjustment;

  SelectedVariantOption({
    required this.variantName,
    required this.optionName,
    required this.priceAdjustment,
  });

  Map<String, dynamic> toMap() {
    return {
      'variantName': variantName,
      'optionName': optionName,
      'priceAdjustment': priceAdjustment,
    };
  }

  factory SelectedVariantOption.fromMap(Map<String, dynamic> map) {
    return SelectedVariantOption(
      variantName: map['variantName'] as String,
      optionName: map['optionName'] as String,
      priceAdjustment: (map['priceAdjustment'] as num).toDouble(),
    );
  }
}

class CartItem {
  final String id;
  final String serviceAdId;
  final String title;
  final double basePrice;
  final double finalPrice;
  final String? image;
  final String businessId;
  final String businessName;
  final int quantity;
  final List<SelectedVariantOption> selectedOptions;
  final List<String> categories;

  CartItem({
    required this.id,
    required this.serviceAdId,
    required this.title,
    required this.basePrice,
    required this.finalPrice,
    this.image,
    required this.businessId,
    required this.businessName,
    required this.quantity,
    required this.selectedOptions,
    this.categories = const [],
  });

  String get selectedOptionsSummary {
    if (selectedOptions.isEmpty) return '';
    final Map<String, List<String>> grouped = {};
    for (final opt in selectedOptions) {
      grouped.putIfAbsent(opt.variantName, () => []).add(opt.optionName);
    }
    return grouped.entries.map((e) => "${e.key}: ${e.value.join(', ')}").join(' | ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceAdId': serviceAdId,
      'title': title,
      'basePrice': basePrice,
      'finalPrice': finalPrice,
      'image': image,
      'businessId': businessId,
      'businessName': businessName,
      'quantity': quantity,
      'selectedOptions': selectedOptions.map((opt) => opt.toMap()).toList(),
      'categories': categories,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      serviceAdId: map['serviceAdId'] as String? ?? '',
      title: map['title'] as String,
      basePrice: (map['basePrice'] as num? ?? map['price'] as num? ?? 0).toDouble(),
      finalPrice: (map['finalPrice'] as num? ?? map['price'] as num? ?? 0).toDouble(),
      image: map['image'] as String?,
      businessId: map['businessId'] as String,
      businessName: map['businessName'] as String,
      quantity: map['quantity'] as int? ?? 1,
      selectedOptions: (map['selectedOptions'] as List?)
              ?.map((opt) => SelectedVariantOption.fromMap(opt as Map<String, dynamic>))
              .toList() ??
          [],
      categories: (map['categories'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _cartRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('cart');
  }

  // Stream of cart items
  Stream<List<CartItem>> getCartItems() {
    final ref = _cartRef;
    if (ref == null) return Stream.value([]);

    // Sort by created time
    return ref.orderBy('created', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CartItem.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Add item to cart
  Future<void> addToCart(ServiceAds ad, List<SelectedVariantOption> options, int quantity) async {
    final ref = _cartRef;
    if (ref == null) throw Exception("Usuário não logado");

    // Calculate final unit price
    double adjustments = 0;
    for (final opt in options) {
      adjustments += opt.priceAdjustment;
    }
    double finalPrice = ad.price.toDouble() + adjustments;

    // Check if there is an item in the cart with the exact same ad ID and selected options
    final querySnapshot = await ref.where('serviceAdId', isEqualTo: ad.id).get();
    DocumentSnapshot? matchingDoc;

    for (final doc in querySnapshot.docs) {
      final cartItem = CartItem.fromMap(doc.data() as Map<String, dynamic>);
      if (_areOptionsEqual(cartItem.selectedOptions, options)) {
        matchingDoc = doc;
        break;
      }
    }

    if (matchingDoc != null) {
      // Increment quantity of existing configuration
      final currentQuantity = matchingDoc['quantity'] as int? ?? 1;
      await matchingDoc.reference.update({
        'quantity': currentQuantity + quantity,
      });
    } else {
      // Create new configuration card
      final docId = ref.doc().id;
      final item = CartItem(
        id: docId,
        serviceAdId: ad.id,
        title: ad.title,
        basePrice: ad.price.toDouble(),
        finalPrice: finalPrice,
        image: ad.images.isNotEmpty ? ad.images.first : null,
        businessId: ad.business.id,
        businessName: ad.business.name,
        quantity: quantity,
        selectedOptions: options,
        categories: ad.categories.map((e) => e.toString()).toList(),
      );

      final map = item.toMap();
      map['created'] = FieldValue.serverTimestamp();
      await ref.doc(docId).set(map);
    }
  }

  bool _areOptionsEqual(List<SelectedVariantOption> a, List<SelectedVariantOption> b) {
    if (a.length != b.length) return false;
    final sortedA = [...a]..sort((x, y) => "${x.variantName}_${x.optionName}".compareTo("${y.variantName}_${y.optionName}"));
    final sortedB = [...b]..sort((x, y) => "${x.variantName}_${x.optionName}".compareTo("${y.variantName}_${y.optionName}"));
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i].variantName != sortedB[i].variantName ||
          sortedA[i].optionName != sortedB[i].optionName) {
        return false;
      }
    }
    return true;
  }

  // Remove item from cart
  Future<void> removeFromCart(String id) async {
    final ref = _cartRef;
    if (ref == null) throw Exception("Usuário não logado");

    await ref.doc(id).delete();
  }

  // Check if item is in cart (any configuration of this service)
  Stream<bool> isInCart(String adId) {
    final ref = _cartRef;
    if (ref == null) return Stream.value(false);

    return ref.where('serviceAdId', isEqualTo: adId).snapshots().map((snapshot) => snapshot.docs.isNotEmpty);
  }

  // Update quantity directly (e.g. inside the cart screen)
  Future<void> updateQuantity(String id, int newQuantity) async {
    final ref = _cartRef;
    if (ref == null) throw Exception("Usuário não logado");
    if (newQuantity <= 0) {
      await removeFromCart(id);
    } else {
      await ref.doc(id).update({'quantity': newQuantity});
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    final ref = _cartRef;
    if (ref == null) return;

    final snapshot = await ref.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
