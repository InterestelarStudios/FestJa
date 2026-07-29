import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // -- BUSINESSES --

  Future<void> toggleFavoriteBusiness(String businessId, bool isFavorite) async {
    if (_uid == null) return;
    
    final docRef = _db
        .collection('users')
        .doc(_uid)
        .collection('favorite_businesses')
        .doc(businessId);

    if (isFavorite) {
      await docRef.set({'addedAt': FieldValue.serverTimestamp()});
    } else {
      await docRef.delete();
    }
  }

  Stream<bool> isBusinessFavorite(String businessId) {
    if (_uid == null) return Stream.value(false);
    
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favorite_businesses')
        .doc(businessId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // -- SERVICES / PRODUCTS --

  Future<void> toggleFavoriteService(String serviceId, bool isFavorite) async {
    if (_uid == null) return;
    
    final docRef = _db
        .collection('users')
        .doc(_uid)
        .collection('favorite_services')
        .doc(serviceId);

    if (isFavorite) {
      await docRef.set({'addedAt': FieldValue.serverTimestamp()});
    } else {
      await docRef.delete();
    }
  }

  Stream<bool> isServiceFavorite(String serviceId) {
    if (_uid == null) return Stream.value(false);
    
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favorite_services')
        .doc(serviceId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // -- GET ALL FAVORITES --

  Stream<List<String>> getFavoriteBusinesses() {
    if (_uid == null) return Stream.value([]);
    
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favorite_businesses')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Stream<List<String>> getFavoriteServices() {
    if (_uid == null) return Stream.value([]);
    
    return _db
        .collection('users')
        .doc(_uid)
        .collection('favorite_services')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}
