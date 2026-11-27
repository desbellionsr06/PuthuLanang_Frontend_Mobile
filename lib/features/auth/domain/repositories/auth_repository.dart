import '../entities/auth_session.dart';

/// Kontrak Repository (Domain Layer) untuk fitur Autentikasi & Persistensi Sesi.
abstract class AuthRepository {
  Future<AuthSession> login({
    required String phone,
    required String password,
  });

  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required String type,
  });

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otpCode,
    String? name,
    String? password,
    required bool isRegister,
  });

  Future<Map<String, dynamic>> forgotPassword({
    required String phone,
    required String otpCode,
    required String newPassword,
  });

  Future<void> verifySession(String jwtToken);

  Future<void> saveSession(AuthSession session);

  Future<AuthSession?> loadPersistedSession();

  Future<void> clearPersistedSession();
}

