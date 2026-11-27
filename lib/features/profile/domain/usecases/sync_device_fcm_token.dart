import '../repositories/profile_repository.dart';

/// Use Case: Menyinkronkan FCM device token ke backend untuk push notification.
class SyncDeviceFcmToken {
  final ProfileRepository _repository;

  const SyncDeviceFcmToken(this._repository);

  Future<void> execute({
    required String token,
    required String fcmToken,
  }) async {
    if (token.trim().isEmpty || fcmToken.trim().isEmpty) {
      throw ArgumentError('Token autentikasi dan FCM token wajib diisi.');
    }
    await _repository.syncFcmToken(token: token, fcmToken: fcmToken);
  }
}

