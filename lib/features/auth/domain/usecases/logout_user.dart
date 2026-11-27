import '../repositories/auth_repository.dart';

/// Use Case: Menghapus sesi pengguna saat logout.
class LogoutUser {
  final AuthRepository _repository;

  const LogoutUser(this._repository);

  Future<void> execute() async {
    await _repository.clearPersistedSession();
  }
}

