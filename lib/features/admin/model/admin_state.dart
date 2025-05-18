import '../../shared/model/user_model.dart';

enum AdminStatus {
  initial,
  loading,
  loaded,
  error,
}

class AdminState {
  final AdminStatus status;
  final List<UserModel> pendingUsers;
  final List<UserModel> approvedUsers;
  final String? errorMessage;
  final bool isAdmin;

  AdminState({
    this.status = AdminStatus.initial,
    this.pendingUsers = const [],
    this.approvedUsers = const [],
    this.errorMessage,
    this.isAdmin = false,
  });

  AdminState copyWith({
    AdminStatus? status,
    List<UserModel>? pendingUsers,
    List<UserModel>? approvedUsers,
    String? errorMessage,
    bool? isAdmin,
  }) {
    return AdminState(
      status: status ?? this.status,
      pendingUsers: pendingUsers ?? this.pendingUsers,
      approvedUsers: approvedUsers ?? this.approvedUsers,
      errorMessage: errorMessage,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
