import '../repositories/auth_repository.dart';

/// Use Case: Reset password menggunakan kode OTP WhatsApp.
class ResetPassword {
  final AuthRepository _repository;

  const ResetPassword(this._repository);

  Future<Map<String, dynamic>> execute({
    required String phone,
    required String otpCode,
    required String newPassword,
  }) async {
    final cleanPhone = phone.trim();
    final cleanOtp = otpCode.trim();
    final cleanNewPass = newPassword.trim();

    if (!RegExp(r'^\d{9,15}$').hasMatch(cleanPhone)) {
      throw ArgumentError('Nomor WhatsApp tidak valid.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(cleanOtp)) {
      throw ArgumentError('Kode OTP harus 4 digit angka.');
    }
    if (cleanNewPass.length < 6) {
      throw ArgumentError('Kata sandi baru minimal 6 karakter.');
    }

    return _repository.forgotPassword(
      phone: cleanPhone,
      otpCode: cleanOtp,
      newPassword: cleanNewPass,
    );
  }
}

