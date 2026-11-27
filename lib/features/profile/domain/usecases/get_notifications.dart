import '../repositories/profile_repository.dart';

/// Use Case: Mengambil daftar notifikasi pengguna dari backend.
class GetNotifications {
  final ProfileRepository _repository;

  const GetNotifications(this._repository);

  Future<List<Map<String, dynamic>>> execute({required String token}) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('Token sesi tidak valid untuk mengambil notifikasi.');
    }
    return _repository.getMyNotifications(token: token);
  }
}

