import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı bilgilerini getir
  Future<UserModel?> getUserById(String uid) async {
    try {
      // Önce users koleksiyonunda ara
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }

      // Eğer yoksa pending_users koleksiyonunda ara
      DocumentSnapshot pendingUserDoc =
          await _firestore.collection('pending_users').doc(uid).get();

      if (pendingUserDoc.exists) {
        return UserModel.fromMap(pendingUserDoc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Kullanıcı bilgileri alınırken hata: $e');
      return null;
    }
  }

  // Kullanıcının onay durumunu kontrol et
  Future<bool> isUserApproved(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      return userDoc.exists;
    } catch (e) {
      print('Kullanıcı onay durumu kontrol edilirken hata: $e');
      return false;
    }
  }

  // Kullanıcı onay bekliyor mu?
  Future<bool> isUserPending(String uid) async {
    try {
      DocumentSnapshot pendingDoc =
          await _firestore.collection('pending_users').doc(uid).get();
      return pendingDoc.exists;
    } catch (e) {
      print('Kullanıcı bekleme durumu kontrol edilirken hata: $e');
      return false;
    }
  }

  // Kullanıcının reddedilip reddedilmediğini onay beklemeden kontrol et
  Future<bool> isUserRejected(String uid) async {
    try {
      // Kullanıcı onaylanmış veya beklemede değilse, reddedilmiştir
      bool isApproved = await isUserApproved(uid);
      if (isApproved) return false; // Onaylanmış kullanıcı

      bool isPending = await isUserPending(uid);
      return !isPending; // Beklemede değilse reddedilmiştir
    } catch (e) {
      print('Kullanıcı red durumu kontrol edilirken hata: $e');
      return false;
    }
  }

  // Son görülme zamanını güncelle
  Future<void> updateLastSeen(String uid) async {
    try {
      // Kullanıcı onaylı ise son görülme zamanını güncelle
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        await _firestore.collection('users').doc(uid).update({
          'lastSeen': DateTime.now(),
        });
      }
    } catch (e) {
      print('Son görülme zamanı güncellenirken hata: $e');
    }
  }

  // Kullanıcı profil bilgilerini güncelle
  Future<void> updateUserProfile(String uid,
      {String? displayName, String? profilePicture}) async {
    try {
      Map<String, dynamic> updateData = {};

      if (displayName != null) {
        updateData['displayName'] = displayName;
      }

      if (profilePicture != null) {
        updateData['profilePicture'] = profilePicture;
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updateData);
      }
    } catch (e) {
      print('Profil bilgileri güncellenirken hata: $e');
    }
  }

  // Reddedilme sebebini getir
  Future<String?> getRejectionReason(String uid) async {
    try {
      bool isRejected = await isUserRejected(uid);

      if (isRejected) {
        // Firebase'de ayrı bir reddedilme sebebi varsa buradan alabiliriz
        // Ancak basit implementasyon için sabit bir mesaj dönelim
        return 'Başvurunuz admin tarafından reddedildi. Lütfen daha sonra tekrar deneyin veya destek ekibiyle iletişime geçin.';
      }
      return null;
    } catch (e) {
      print('Reddedilme sebebi alınırken hata: $e');
      return 'Hesap durumunuz kontrol edilirken bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
    }
  }
}
