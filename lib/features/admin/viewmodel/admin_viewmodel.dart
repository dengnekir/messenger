import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/services/admin_service.dart';
import '../model/admin_state.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  AdminState _state = AdminState();
  AdminState get state => _state;

  // Kullanıcı admin mi kontrol et
  Future<void> checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _state = _state.copyWith(
          status: AdminStatus.error,
          errorMessage: 'Kullanıcı oturum açmamış',
          isAdmin: false,
        );
        notifyListeners();
        return;
      }

      final isAdmin = await _adminService.isUserAdmin(user.uid);
      _state = _state.copyWith(isAdmin: isAdmin);
      notifyListeners();

      if (isAdmin) {
        await loadUsers();
      }
    } catch (e) {
      _state = _state.copyWith(
        status: AdminStatus.error,
        errorMessage: 'Admin durumu kontrol edilirken hata: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  // Kullanıcıları yükle
  Future<void> loadUsers() async {
    try {
      _state = _state.copyWith(
        status: AdminStatus.loading,
        errorMessage: null,
      );
      notifyListeners();

      final pendingUsers = await _adminService.getPendingUsers();
      final approvedUsers = await _adminService.getApprovedUsers();

      _state = _state.copyWith(
        status: AdminStatus.loaded,
        pendingUsers: pendingUsers,
        approvedUsers: approvedUsers,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: AdminStatus.error,
        errorMessage: 'Kullanıcılar yüklenirken hata: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  // Kullanıcıyı onayla
  Future<void> approveUser(String uid) async {
    try {
      await _adminService.approveUser(uid);
      await loadUsers(); // Kullanıcıları yeniden yükle
    } catch (e) {
      _state = _state.copyWith(
        status: AdminStatus.error,
        errorMessage: 'Kullanıcı onaylanırken hata: ${e.toString()}',
      );
      notifyListeners();
    }
  }

  // Kullanıcıyı reddet
  Future<void> rejectUser(String uid) async {
    try {
      await _adminService.rejectUser(uid);
      await loadUsers(); // Kullanıcıları yeniden yükle
    } catch (e) {
      _state = _state.copyWith(
        status: AdminStatus.error,
        errorMessage: 'Kullanıcı reddedilirken hata: ${e.toString()}',
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
