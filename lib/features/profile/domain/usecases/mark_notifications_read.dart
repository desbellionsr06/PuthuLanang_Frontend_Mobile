import '../repositories/profile_repository.dart';

/// Use Case: Menandai seluruh notifikasi pengguna telah dibaca.
class MarkNotificationsRead {
  final ProfileRepository _repository;

  const MarkNotificationsRead(this._repository);

  Future<void> execute({required String token}) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('Token sesi tidak valid.');
    }
    await _repository.markAllNotificationsRead(token: token);
  }
}

