import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ifest_app/models/event.dart';
import 'package:path/path.dart' as p;

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Criar Evento
  Future<void> createEvent(Event event, File? imageFile) async {
    if (_uid == null) throw Exception("Usuário não logado");

    final docRef = _db.collection('events').doc();
    event.id = docRef.id;

    if (imageFile != null) {
      final ext = p.extension(imageFile.path);
      final ref = _storage.ref().child('events/${event.id}/cover$ext');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      event.image = downloadUrl;
    }

    await docRef.set(event.toMap());
  }

  // Atualizar Evento
  Future<void> updateEvent(Event event, File? imageFile) async {
    if (_uid == null) throw Exception("Usuário não logado");

    if (imageFile != null) {
      final ext = p.extension(imageFile.path);
      final ref = _storage.ref().child('events/${event.id}/cover$ext');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      event.image = downloadUrl;
    }

    await _db.collection('events').doc(event.id).update(event.toMap());
  }

  // Buscar Eventos do Usuário
  Stream<List<Event>> getUserEvents() {
    if (_uid == null) return Stream.value([]);
    
    return _db
        .collection('events')
        .where('owner.id', isEqualTo: _uid)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Event.fromMap(data);
      }).toList();
    });
  }

  // Excluir Evento
  Future<void> deleteEvent(String eventId) async {
    if (_uid == null) return;
    await _db.collection('events').doc(eventId).delete();
  }
}
