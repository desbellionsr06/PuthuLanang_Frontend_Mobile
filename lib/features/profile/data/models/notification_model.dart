import '../../domain/entities/user_profile.dart';

/// Data Model mapper (JSON <-> AppNotification) untuk notifikasi gerai.
class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.isRead,
    super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? 'Pembaruan Gerai',
      body: json['body']?.toString() ?? '',
      isRead: (json['is_read'] ?? 0) == 1,
      createdAt: json['created_at']?.toString(),
    );
  }
}

