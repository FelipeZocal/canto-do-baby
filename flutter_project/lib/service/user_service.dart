import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart'; // Garante que UserModel/User do seu projeto seja reconhecido

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}