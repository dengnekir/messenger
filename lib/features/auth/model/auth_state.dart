enum AuthStatus {
  initial,
  registering,
  loggingIn,
  authenticated,
  unauthenticated,
  pendingApproval,
  rejected,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? errorMessage;
  final bool isApproved;
  final bool isAdmin;
  final String? rejectionReason;

  AuthState({
    this.status = AuthStatus.initial,
    this.email,
    this.errorMessage,
    this.isApproved = false,
    this.isAdmin = false,
    this.rejectionReason,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? errorMessage,
    bool? isApproved,
    bool? isAdmin,
    String? rejectionReason,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: errorMessage,
      isApproved: isApproved ?? this.isApproved,
      isAdmin: isAdmin ?? this.isAdmin,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
