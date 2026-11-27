/// Entity murni untuk sesi autentikasi pengguna.
class AuthSession {
  final int userId;
  final String name;
  final String phone;
  final String token;
  final String? jwtToken;
  final int loginTimestamp;

  const AuthSession({
    required this.userId,
    required this.name,
    required this.phone,
    required this.token,
    this.jwtToken,
    required this.loginTimestamp,
  });
}

