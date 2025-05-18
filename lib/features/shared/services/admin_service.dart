import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının admin olup olmadığını kontrol et
  Future<bool> isUserAdmin(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      return userData != null && userData['role'] == 'admin';
    }
    return false;
  }

  // İlk kullanıcıyı admin olarak kaydet
  Future<void> registerFirstUserAsAdmin(
      User user, String email, String firstName, String lastName) async {
    // Kullanıcılar koleksiyonunu kontrol et
    final usersSnapshot = await _firestore.collection('users').get();

    // Eğer kullanıcılar koleksiyonu boşsa, ilk kullanıcıyı admin olarak kaydet
    if (usersSnapshot.docs.isEmpty) {
      final userData = UserModel(
        uid: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        isApproved: true,
        createdAt: DateTime.now(),
        role: 'admin',
      );

      await _firestore.collection('users').doc(user.uid).set(userData.toMap());
      return;
    }

    // Kullanıcı zaten varsa, pending_users koleksiyonuna ekle
    final userData = UserModel(
      uid: user.uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      isApproved: false,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('pending_users')
        .doc(user.uid)
        .set(userData.toMap());
  }

  // Bekleyen kullanıcıları getir
  Future<List<UserModel>> getPendingUsers() async {
    final snapshot = await _firestore.collection('pending_users').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // Onaylı kullanıcıları getir
  Future<List<UserModel>> getApprovedUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // Kullanıcıyı onayla
  Future<void> approveUser(String uid) async {
    // Kullanıcıyı pending_users koleksiyonundan al
    final userDoc = await _firestore.collection('pending_users').doc(uid).get();
    if (!userDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    // Kullanıcı verilerini al ve onaylı olarak işaretle
    final userData = userDoc.data()!;
    userData['isApproved'] = true;

    // Kullanıcıyı users koleksiyonuna taşı
    await _firestore.collection('users').doc(uid).set(userData);

    // Kullanıcıyı pending_users koleksiyonundan sil
    await _firestore.collection('pending_users').doc(uid).delete();
  }

  // Kullanıcıyı reddet
  Future<void> rejectUser(String uid) async {
    final userDoc = await _firestore.collection('pending_users').doc(uid).get();
    if (!userDoc.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    // Firestore'dan kullanıcıyı sil
    await _firestore.collection('pending_users').doc(uid).delete();

    try {
      // Firebase Auth'dan kullanıcıyı silmek için email bilgisini al
      final email = userDoc.data()!['email'] as String;
      if (email.isNotEmpty) {
        final authResult = await _auth.fetchSignInMethodsForEmail(email);
        if (authResult.isNotEmpty) {
          // Cloud Functions veya admin SDK ile silme işlemi yapılabilir
          // Burada sadece işaretleme yapıyoruz
          print('Kullanıcı Authentication\'dan silinmesi gerekiyor: $email');
        }
      }
    } catch (e) {
      print('Kullanıcı kimliği kontrol edilemedi: $e');
    }
  }
}
