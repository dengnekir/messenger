import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının giriş durumunu kontrol et
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Email ve şifre ile kayıt ol
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Kullanıcı oluşturulduktan sonra, kullanıcıyı veritabanına kaydet
    if (userCredential.user != null) {
      // İlk kullanıcı mı kontrol et
      final isFirstUser =
          (await _firestore.collection('users').get()).docs.isEmpty;

      final userData = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        createdAt: DateTime.now(),
        role: isFirstUser ? 'admin' : null,
        isApproved: isFirstUser, // İlk kullanıcı otomatik onaylı
      );

      // İlk kullanıcıyı direkt users koleksiyonuna, diğerlerini pending_users koleksiyonuna ekle
      if (isFirstUser) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData.toMap());
      } else {
        await _firestore
            .collection('pending_users')
            .doc(userCredential.user!.uid)
            .set(userData.toMap());
      }
    }

    return userCredential;
  }

  // Email ve şifre ile giriş yap
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Kullanıcının onay durumunu kontrol et
  Future<bool> checkIfUserApproved(String uid) async {
    // Önce users koleksiyonunda kontrol et
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return true;
    }
    return false;
  }

  // Kullanıcı çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
