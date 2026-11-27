import '../../../../services/api_service.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Memulihkan sesi tersimpan saat aplikasi dibuka kembali (maks. 30 hari + cek JWT).
class RestoreAuthSession {
  final AuthRepository _repository;

  const RestoreAuthSession(this._repository);

  Future<AuthSession?> execute() async {
    final session = await _repository.loadPersistedSession();
    if (session == null) return null;

    if (session.loginTimestamp > 0) {
      final loginDate =
          DateTime.fromMillisecondsSinceEpoch(session.loginTimestamp);
      if (DateTime.now().difference(loginDate).inDays > 30) {
        await _repository.clearPersistedSession();
        return null;
      }
    }

    if (session.jwtToken != null && session.jwtToken!.isNotEmpty) {
      try {
        await _repository.verifySession(session.jwtToken!);
      } on SessionExpiredException {
        await _repository.clearPersistedSession();
        return null;
      } catch (_) {
        // Backend tidak terjangkau → tetap izinkan sesi offline
      }
    }

    return session;
  }
}

