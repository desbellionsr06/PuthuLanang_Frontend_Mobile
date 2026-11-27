/// Kontrak Repository (Domain Layer) untuk fitur Profil & Notifikasi.
abstract class ProfileRepository {
  Future<List<Map<String, dynamic>>> getMyNotifications({
    required String token,
  });

  Future<void> markAllNotificationsRead({
    required String token,
  });

  Future<void> syncFcmToken({
    required String token,
    required String fcmToken,
  });
}

