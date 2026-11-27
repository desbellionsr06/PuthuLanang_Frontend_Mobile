import '../repositories/auth_repository.dart';

/// Use Case: Mengirim kode OTP WhatsApp untuk registrasi atau lupa password.
class SendAuthOtp {
  final AuthRepository _repository;

  const SendAuthOtp(this._repository);

  Future<Map<String, dynamic>> execute({
    required String phone,
    required String type,
  }) async {
    final cleanPhone = phone.trim();
    final cleanType = type.trim();

    if (!RegExp(r'^\d{9,15}$').hasMatch(cleanPhone)) {
      throw ArgumentError('Nomor WhatsApp harus berupa 9–15 digit angka.');
    }
    if (cleanType != 'register' && cleanType != 'forgot') {
      throw ArgumentError('Tipe pengiriman OTP tidak valid.');
    }

    return _repository.sendOtp(phone: cleanPhone, type: cleanType);
  }
}

