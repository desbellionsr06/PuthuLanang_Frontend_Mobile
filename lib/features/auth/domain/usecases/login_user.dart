import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Login pengguna dengan validasi input nomor WhatsApp & password.
class LoginUser {
  final AuthRepository _repository;

  const LoginUser(this._repository);

  Future<AuthSession> execute({
    required String phone,
    required String password,
  }) async {
    final cleanPhone = phone.trim();
    final cleanPassword = password.trim();

    if (cleanPhone.isEmpty || cleanPassword.isEmpty) {
      throw ArgumentError('Nomor WhatsApp dan password wajib diisi.');
    }
    if (!RegExp(r'^\d{9,15}$').hasMatch(cleanPhone)) {
      throw ArgumentError('Nomor WhatsApp harus berupa 9–15 digit angka.');
    }

    final session = await _repository.login(
      phone: cleanPhone,
      password: cleanPassword,
    );
    await _repository.saveSession(session);
    return session;
  }
}

