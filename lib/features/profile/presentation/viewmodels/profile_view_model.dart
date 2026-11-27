import 'package:flutter/foundation.dart';
import '../../../../state/app_state.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_notifications_read.dart';

/// ViewModel (MVVM + ChangeNotifier) untuk fitur Profil & Notifikasi.
class ProfileViewModel extends ChangeNotifier {
  final GetNotifications _getNotifications;
  final MarkNotificationsRead _markNotificationsRead;

  ProfileViewModel({
    required GetNotifications getNotifications,
    required MarkNotificationsRead markNotificationsRead,
  })  : _getNotifications = getNotifications,
        _markNotificationsRead = markNotificationsRead;

  bool _isVip = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  bool get isVip => _isVip;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  void activateVip() {
    _isVip = true;
    notifyListeners();
  }

  Future<void> syncAndReadNotifications(AppState appState) async {
    final jwt = appState.jwtToken;
    if (jwt == null || jwt.isEmpty) return;

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _getNotifications.execute(token: jwt);
      await _markNotificationsRead.execute(token: jwt);
      appState.setNotificationsRead(rows);
    } catch (_) {
      _errorMessage = 'Gagal menyinkronkan notifikasi dari server.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}

