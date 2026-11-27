import '../../../../services/api_service.dart';
import '../../domain/repositories/profile_repository.dart';

/// Implementasi Repository (Data Layer) untuk fitur Profil & Notifikasi.
class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<List<Map<String, dynamic>>> getMyNotifications({
    required String token,
  }) {
    return ApiService.getMyNotifications(token: token);
  }

  @override
  Future<void> markAllNotificationsRead({required String token}) {
    return ApiService.markNotificationsRead(token: token);
  }

  @override
  Future<void> syncFcmToken({
    required String token,
    required String fcmToken,
  }) {
    return ApiService.syncFcmToken(token: token, fcmToken: fcmToken);
  }
}

