enum AuthState {
  isAuthenticated,
  isLoading,
  needsAuthentication,
}

class AuthenticationState {
  late AuthState status;

  AuthenticationState({
    required this.status,
  });

  AuthenticationState copyWith({
    AuthState? status,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
    );
  }
}
