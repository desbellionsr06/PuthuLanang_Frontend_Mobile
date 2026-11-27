import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Verifikasi OTP & registrasi akun baru dengan validasi input lengkap.
class VerifyAuthOtp {
  final AuthRepository _repository;

  const VerifyAuthOtp(this._repository);

  Future<AuthSession> execute({
    required String phone,
    required String otpCode,
    required String name,
    required String password,
    required bool isRegister,
  }) async {
    final cleanPhone = phone.trim();
    final cleanOtp = otpCode.trim();
    final cleanName = name.trim();
    final cleanPassword = password.trim();

    if (!RegExp(r'^\d{9,15}$').hasMatch(cleanPhone)) {
      throw ArgumentError('Nomor WhatsApp harus berupa 9–15 digit angka.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(cleanOtp)) {
      throw ArgumentError('Kode OTP harus 4 digit angka.');
    }
    if (isRegister) {
      if (cleanName.length < 3) {
        throw ArgumentError('Nama lengkap minimal 3 karakter.');
      }
      if (cleanPassword.length < 6) {
        throw ArgumentError('Password minimal 6 karakter.');
      }
    }

    final result = await _repository.verifyOtp(
      phone: cleanPhone,
      otpCode: cleanOtp,
      name: cleanName,
      password: cleanPassword,
      isRegister: isRegister,
    );

    final dataMap = result['data'] as Map<String, dynamic>?;
    final userId = int.tryParse('${dataMap?['id']}');
    if (userId == null) {
      throw StateError('Data akun dari server tidak valid.');
    }

    final session = AuthSession(
      userId: userId,
      name: cleanName,
      phone: cleanPhone,
      token: dataMap?['token']?.toString() ?? 'server-token-$cleanPhone',
      jwtToken: dataMap?['jwt_token']?.toString(),
      loginTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.saveSession(session);
    return session;
  }
}

