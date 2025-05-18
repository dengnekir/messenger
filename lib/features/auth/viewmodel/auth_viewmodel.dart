import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/user_service.dart';
import '../../shared/services/admin_service.dart';
import '../model/auth_state.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final AdminService _adminService = AdminService();

  AuthState _state = AuthState();
  AuthState get state => _state;

  // Email ve şifre ile kayıt ol
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _state = _state.copyWith(
      status: AuthStatus.registering,
      email: email,
      errorMessage: null,
    );
    notifyListeners();

    try {
      // Kullanıcıyı kaydet
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (userCredential.user != null) {
        // Kullanıcının onay durumunu, admin durumunu ve reddedilme durumunu kontrol et
        final isApproved =
            await _userService.isUserApproved(userCredential.user!.uid);
        final isAdmin =
            await _adminService.isUserAdmin(userCredential.user!.uid);
        final isRejected =
            await _userService.isUserRejected(userCredential.user!.uid);

        if (isRejected) {
          final rejectionReason =
              await _userService.getRejectionReason(userCredential.user!.uid);
          _state = _state.copyWith(
            status: AuthStatus.rejected,
            email: userCredential.user!.email,
            isApproved: false,
            isAdmin: false,
            rejectionReason: rejectionReason,
          );
        } else if (isApproved) {
          _state = _state.copyWith(
            status: AuthStatus.authenticated,
            isApproved: true,
            isAdmin: isAdmin,
          );
        } else {
          _state = _state.copyWith(
            status: AuthStatus.pendingApproval,
            isApproved: false,
            isAdmin: false,
          );
        }
      } else {
        _state = _state.copyWith(
          status: AuthStatus.unauthenticated,
        );
      }

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Bu e-posta adresi zaten kullanımda.';
          break;
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf. En az 6 karakter kullanın.';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Çok fazla başarısız kayıt denemesi. Lütfen daha sonra tekrar deneyin.';
          break;
        case 'captcha-check-failed':
        case 'missing-recaptcha-token':
          errorMessage =
              'Güvenlik doğrulaması başarısız. Lütfen tekrar deneyin veya uygulamayı yeniden başlatın.';
          break;
        default:
          errorMessage = e.message ?? 'Kayıt işleminde bir hata oluştu.';
          break;
      }

      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMessage,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      notifyListeners();
    }
  }

  // Email ve şifre ile giriş yap
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _state = _state.copyWith(
      status: AuthStatus.loggingIn,
      email: email,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Kullanıcının onay durumunu, admin durumunu ve reddedilme durumunu kontrol et
        final isApproved =
            await _userService.isUserApproved(userCredential.user!.uid);
        final isAdmin =
            await _adminService.isUserAdmin(userCredential.user!.uid);
        final isRejected =
            await _userService.isUserRejected(userCredential.user!.uid);

        if (isRejected) {
          final rejectionReason =
              await _userService.getRejectionReason(userCredential.user!.uid);
          _state = _state.copyWith(
            status: AuthStatus.rejected,
            email: userCredential.user!.email,
            isApproved: false,
            isAdmin: false,
            rejectionReason: rejectionReason,
          );
        } else if (isApproved) {
          _state = _state.copyWith(
            status: AuthStatus.authenticated,
            isApproved: true,
            isAdmin: isAdmin,
          );
        } else {
          _state = _state.copyWith(
            status: AuthStatus.pendingApproval,
            isApproved: false,
            isAdmin: false,
          );
        }
      } else {
        _state = _state.copyWith(
          status: AuthStatus.unauthenticated,
        );
      }

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu e-posta adresine kayıtlı kullanıcı bulunamadı.';
          break;
        case 'wrong-password':
          errorMessage = 'Yanlış şifre.';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi.';
          break;
        case 'user-disabled':
          errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.';
          break;
        case 'captcha-check-failed':
        case 'missing-recaptcha-token':
          errorMessage =
              'Güvenlik doğrulaması başarısız. Lütfen tekrar deneyin veya uygulamayı yeniden başlatın.';
          break;
        default:
          errorMessage = e.message ?? 'Giriş yapılırken bir hata oluştu.';
          break;
      }

      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMessage,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      notifyListeners();
    }
  }

  // Kullanıcı çıkış yap
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _state = AuthState();
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }

  // Kullanıcının reddedilip reddedilmediğini kontrol et (doğrudan erişim)
  Future<bool> isUserRejected() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        return await _userService.isUserRejected(user.uid);
      } catch (e) {
        print('Kullanıcı red durumu kontrol edilirken hata: $e');
        // Firebase kuralları nedeniyle yetki hataları alınabilir
        return false;
      }
    }
    return false;
  }

  // Kullanıcının durumunu kontrol et
  Future<void> checkUserStatus() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        // Onaylanma durumunu kontrol et
        final isApproved = await _userService.isUserApproved(user.uid);
        final isAdmin = await _adminService.isUserAdmin(user.uid);
        final isPending = await _userService.isUserPending(user.uid);

        // Onaylı ise
        if (isApproved) {
          _state = _state.copyWith(
            status: AuthStatus.authenticated,
            email: user.email,
            isApproved: true,
            isAdmin: isAdmin,
          );
        }
        // Beklemede ise
        else if (isPending) {
          _state = _state.copyWith(
            status: AuthStatus.pendingApproval,
            email: user.email,
            isApproved: false,
            isAdmin: false,
          );
        }
        // Ne onaylı ne beklemede ise reddedilmiştir
        else {
          final rejectionReason =
              await _userService.getRejectionReason(user.uid);
          _state = _state.copyWith(
            status: AuthStatus.rejected,
            email: user.email,
            isApproved: false,
            isAdmin: false,
            rejectionReason: rejectionReason,
          );
        }

        notifyListeners();
      } catch (e) {
        print('Kullanıcı durumu kontrol edilirken hata: $e');
        // Hata durumunda mevcut durumu koru
      }
    }
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _state = _state.copyWith(
        status: AuthStatus.error,
        errorMessage:
            'Şifre sıfırlama e-postası gönderilirken hata oluştu: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  // Hata mesajını temizle
  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }
}
