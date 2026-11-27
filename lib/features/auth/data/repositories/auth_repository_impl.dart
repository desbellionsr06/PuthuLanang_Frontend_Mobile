import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementasi Repository (Data Layer) untuk fitur Auth.
/// Menghubungkan ApiService (REST API Railway) & SharedPreferences (persistensi sesi).
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    final result = await ApiService.login(phone, password);
    final data = result['data'] as Map<String, dynamic>? ?? const {};
    final id = int.tryParse('${data['id']}');
    if (id == null) {
      throw StateError('Data akun dari server tidak valid.');
    }

    return AuthSession(
      userId: id,
      name: data['nama'] as String? ?? 'Pecinta Kuliner',
      phone: phone,
      token: data['token'] as String? ?? 'server-token-$phone',
      jwtToken: data['jwt_token'] as String?,
      loginTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    required String type,
  }) {
    return ApiService.sendOtp(phone, type: type);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otpCode,
    String? name,
    String? password,
    required bool isRegister,
  }) {
    return ApiService.verifyOtp(
      phone: phone,
      otpCode: otpCode,
      name: name,
      password: password,
      isRegister: isRegister,
    );
  }

  @override
  Future<Map<String, dynamic>> forgotPassword({
    required String phone,
    required String otpCode,
    required String newPassword,
  }) {
    return ApiService.forgotPassword(
      phone: phone,
      otpCode: otpCode,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> verifySession(String jwtToken) async {
    await ApiService.verifySession(jwtToken);
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', session.userId);
    await prefs.setString('token', session.token);
    await prefs.setString('name', session.name);
    await prefs.setString('phone', session.phone);
    await prefs.setInt('login_timestamp', session.loginTimestamp);
    if (session.jwtToken != null) {
      await prefs.setString('jwt_token', session.jwtToken!);
    }
  }

  @override
  Future<AuthSession?> loadPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('user_id');
    if (token == null || userId == null) return null;

    return AuthSession(
      userId: userId,
      name: prefs.getString('name') ?? '',
      phone: prefs.getString('phone') ?? '',
      token: token,
      jwtToken: prefs.getString('jwt_token'),
      loginTimestamp: prefs.getInt('login_timestamp') ?? 0,
    );
  }

  @override
  Future<void> clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('token');
    await prefs.remove('jwt_token');
    await prefs.remove('name');
    await prefs.remove('phone');
    await prefs.remove('login_timestamp');
  }
}

