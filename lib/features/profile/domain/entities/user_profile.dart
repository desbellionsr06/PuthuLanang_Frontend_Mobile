/// Entity murni untuk profil pengguna.
class UserProfile {
  final int userId;
  final String name;
  final String phone;
  final bool isVip;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.phone,
    this.isVip = true,
  });
}

/// Entity murni untuk notifikasi gerai.
class AppNotification {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final String? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });
}

