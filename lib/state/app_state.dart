import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/di/injection.dart';
import '../features/auth/domain/entities/auth_session.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/logout_user.dart';
import '../features/auth/domain/usecases/restore_auth_session.dart';
import '../features/checkout/domain/entities/checkout_entity.dart';
import '../features/checkout/domain/usecases/create_checkout_order.dart';
import '../features/menu/domain/usecases/get_menu_catalog.dart';
import '../features/orders/domain/usecases/complete_order.dart';
import '../features/orders/domain/usecases/get_order_history.dart';
import '../features/orders/domain/usecases/get_order_invoice.dart';
import '../features/profile/domain/usecases/get_notifications.dart';
import '../features/profile/domain/usecases/mark_notifications_read.dart';
import '../features/profile/domain/usecases/sync_device_fcm_token.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart' show SessionExpiredException;
import '../services/notification_service.dart';

/// Shared application state (tab aktif, keranjang, sesi, tiket, notifikasi).
/// Seluruh akses data & aturan bisnis didelegasikan ke Domain Use Cases melalui GetIt.
class AppState extends ChangeNotifier {
  int tab = 0;
  bool loading = false;
  String? error;
  bool isRestored = false;

  String userName = '';
  String phone = '';
  String? token;
  String? jwtToken;
  int? userId;

  List<MenuItem> menu = const [];
  final List<CartItem> cart = [];
  Map<String, dynamic>? ticket;

  List<Map<String, dynamic>> orderHistory = [];
  List<Map<String, dynamic>> notifications = [];
  final Set<int> _shownNotifIds = {};
  Timer? _notifTimer;

  int get unreadNotificationCount =>
      notifications.where((n) => (n['is_read'] ?? 0) == 0).length;

  bool get loggedIn => token != null;

  /// Validasi jam operasional Puthu Lanang (17:30 – 21:30 WIB)
  bool get isOperatingHours {
    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final currentMinutes = nowWib.hour * 60 + nowWib.minute;
    return currentMinutes >= 1050 && currentMinutes <= 1290;
  }

  int get totalItems => cart.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice => cart.fold(0, (sum, item) => sum + item.subtotal);

  // =========================
  // TAB NAVIGATION
  // =========================

  void setTab(int index) {
    tab = index;
    notifyListeners();
  }

  // =========================
  // SESSION MANAGEMENT (via Auth UseCases)
  // =========================

  Future<void> restore() async {
    final session = await getIt<RestoreAuthSession>().execute();
    if (session == null) {
      await logout();
      return;
    }

    await applySession(session);
  }

  Future<void> applySession(AuthSession session) async {
    userId = session.userId;
    token = session.token;
    jwtToken = session.jwtToken;
    userName = session.name;
    phone = session.phone;

    final prefs = await SharedPreferences.getInstance();
    _loadHistory(prefs);

    if (jwtToken != null && jwtToken!.isNotEmpty) {
      unawaited(_startNotificationSync());
    }
    isRestored = true;
    notifyListeners();
  }

  Future<void> login(String p, String pass) async {
    final session = await getIt<LoginUser>().execute(
      phone: p,
      password: pass,
    );
    await applySession(session);
  }

  Future<void> logout() async {
    await getIt<LogoutUser>().execute();

    _notifTimer?.cancel();
    _notifTimer = null;
    notifications = [];
    _shownNotifIds.clear();

    userId = null;
    token = null;
    jwtToken = null;
    userName = '';
    phone = '';
    orderHistory = [];

    cart.clear();
    ticket = null;
    tab = 0;
    isRestored = true;

    notifyListeners();
  }

  // =========================
  // NOTIFICATIONS (via Profile UseCases)
  // =========================

  Future<void> _startNotificationSync() async {
    final jwt = jwtToken;
    if (jwt == null || jwt.isEmpty) return;

    await NotificationService.initialize();
    final deviceToken = 'puthu-mobile-device-${userId ?? 0}';
    try {
      await getIt<SyncDeviceFcmToken>().execute(
        token: jwt,
        fcmToken: deviceToken,
      );
    } catch (_) {}
    await refreshNotifications();

    _notifTimer?.cancel();
    _notifTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(refreshNotifications());
    });
  }

  Future<void> refreshNotifications() async {
    final jwt = jwtToken;
    if (jwt == null || jwt.isEmpty) return;

    try {
      final rows = await getIt<GetNotifications>().execute(token: jwt);
      for (final item in rows) {
        final id = int.tryParse('${item['id']}');
        final isRead = (item['is_read'] ?? 0) == 1;
        if (id != null && !isRead && !_shownNotifIds.contains(id)) {
          _shownNotifIds.add(id);
          await NotificationService.showLocalNotification(
            id: id,
            title: '${item['title'] ?? 'Pembaruan Puthu Lanang'}',
            body: '${item['body'] ?? ''}',
          );
        }
      }
      notifications = rows;
      notifyListeners();
    } catch (_) {}
  }

  void setNotificationsRead(List<Map<String, dynamic>> rows) {
    notifications = rows.map((n) => {...n, 'is_read': 1}).toList();
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final jwt = jwtToken;
    if (jwt == null || jwt.isEmpty) return;
    await getIt<MarkNotificationsRead>().execute(token: jwt);
    notifications = notifications.map((n) => {...n, 'is_read': 1}).toList();
    notifyListeners();
  }

  // =========================
  // LOAD MENU (via Menu UseCase)
  // =========================

  Future<void> loadMenu() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      menu = await getIt<GetMenuCatalog>().execute();
    } catch (_) {
      error = 'Gagal memuat menu.';
    }

    loading = false;
    notifyListeners();
  }

  // =========================
  // CART
  // =========================

  void add(MenuItem item) {
    final index = cart.indexWhere((x) => x.item.id == item.id);
    if (index >= 0) {
      cart[index].quantity++;
    } else {
      cart.add(CartItem(item: item));
    }
    notifyListeners();
  }

  void remove(MenuItem item) {
    final index = cart.indexWhere((x) => x.item.id == item.id);
    if (index < 0) return;

    if (cart[index].quantity > 1) {
      cart[index].quantity--;
    } else {
      cart.removeAt(index);
    }
    notifyListeners();
  }

  // =========================
  // ORDER HISTORY (via Orders UseCases)
  // =========================

  String get _historyKey => 'order_history_u${userId ?? 0}';

  void _loadHistory(SharedPreferences prefs) {
    try {
      final raw = userId == null ? null : prefs.getString(_historyKey);
      orderHistory = raw == null
          ? []
          : (jsonDecode(raw) as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
    } catch (_) {
      orderHistory = [];
    }
  }

  Future<void> recordOrderHistory({
    required String summaryItems,
    required int total,
    required String pickupDate,
    required String pickupTime,
    String notes = '',
    String? orderId,
  }) async {
    orderHistory.insert(0, {
      'id': orderId ?? 'PL-${DateTime.now().millisecondsSinceEpoch}',
      'created_at': DateTime.now().toIso8601String(),
      'summary_items': summaryItems,
      'total': total,
      'status': 'Sedang Dikukus',
      'outlet': 'Gerai Pusat Celaket',
      'pickup_date': pickupDate,
      'pickup_time': pickupTime,
      'notes': notes,
    });

    await _saveHistoryCache();
  }

  Future<void> loadOrderHistory() async {
    final id = userId;
    final tk = token;
    if (id == null || tk == null) return;

    try {
      orderHistory = await getIt<GetOrderHistory>().execute(
        userId: id,
        token: tk,
      );
    } on SessionExpiredException {
      await logout();
      rethrow;
    }
    await _saveHistoryCache();
    notifyListeners();
  }

  Future<void> completeOrder() async {
    final id = userId;
    final tk = token;
    final orderId = ticket?['id']?.toString();
    if (id == null || tk == null || orderId == null) {
      throw StateError('Tidak ada pesanan aktif untuk diselesaikan.');
    }

    try {
      await getIt<CompleteOrder>().execute(
        orderId: orderId,
        userId: id,
        token: tk,
      );
    } on SessionExpiredException {
      await logout();
      rethrow;
    }

    final index =
        orderHistory.indexWhere((o) => o['id']?.toString() == orderId);
    if (index >= 0) orderHistory[index]['status'] = 'Selesai';
    await _saveHistoryCache();

    ticket = null;
    notifyListeners();
  }

  Future<void> _saveHistoryCache() async {
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(orderHistory));
    } catch (_) {}
  }

  // =========================
  // SUBMIT CHECKOUT ORDER (via Checkout UseCase)
  // =========================

  Future<Map<String, dynamic>> submitOrder({
    required String pickupTime,
    required String pickupDate,
    String notes = '',
    int discount = 0,
    String paymentMethod = 'cash',
    String? promoCode,
  }) async {
    final id = userId;
    final tk = token;
    if (id == null || tk == null) {
      throw StateError('Silakan masuk terlebih dahulu.');
    }

    final payTotal = (totalPrice - discount).clamp(0, totalPrice).toInt();
    final summaryItems =
        cart.map((e) => '${e.quantity}x ${e.item.name}').join(', ');

    final request = CheckoutOrderRequest(
      userId: id,
      token: tk,
      pickupTime: pickupTime,
      pickupDate: pickupDate,
      items: cart
          .map(
            (e) => {
              'menu_id': e.item.id,
              'nama': e.item.name,
              'quantity': e.quantity,
              'harga': e.item.price,
              'catatan': e.notes,
            },
          )
          .toList(),
      subtotal: totalPrice,
      discount: discount,
      notes: notes,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
    );

    final Map<String, dynamic> result;
    try {
      result = await getIt<CreateCheckoutOrder>().execute(
        request: request,
        isOperatingHours: isOperatingHours,
      );
    } on SessionExpiredException {
      await logout();
      rethrow;
    }

    final data = (result['data'] as Map<String, dynamic>?) ?? {};
    ticket = {
      ...data,
      'notes': (data['notes'] != null && data['notes'].toString().isNotEmpty)
          ? data['notes']
          : notes,
      'pickup_time': data['pickup_time'] ?? pickupTime,
      'pickup_date': data['pickup_date'] ?? pickupDate,
      'payment_method': data['payment_method'] ?? paymentMethod,
      'summary_items': data['summary_items'] ??
          (summaryItems.isNotEmpty ? summaryItems : '1x Puthu / Paket Pilihan'),
    };

    await recordOrderHistory(
      summaryItems: ticket!['summary_items'].toString(),
      total: payTotal,
      pickupDate: ticket!['pickup_date'].toString(),
      pickupTime: ticket!['pickup_time'].toString(),
      notes: ticket!['notes']?.toString() ?? '',
      orderId: (data['id'] ?? data['qr_code_token'])?.toString(),
    );

    cart.clear();
    tab = 3;
    notifyListeners();
    return data;
  }

  // =========================
  // RE-ORDER & INVOICE LOOKUP (via Orders UseCase)
  // =========================

  Future<void> loadInvoiceTicket(String orderId) async {
    try {
      final inv = await getIt<GetOrderInvoice>().execute(orderId);
      if (inv.isNotEmpty) {
        ticket = {
          ...inv,
          'id': inv['order_id'] ?? inv['id'] ?? orderId,
          'summary_items': inv['summary_items'] ?? 'Pesanan Puthu Lanang',
        };
        tab = 3;
        notifyListeners();
      }
    } catch (_) {}
  }

  void reorderFromMap(Map<String, dynamic> order) {
    cart.clear();
    final summary = (order['summary_items'] ?? '').toString().trim();
    if (summary.isNotEmpty) {
      final parts = summary.split(',');
      for (final part in parts) {
        final trimmed = part.trim();
        final match = RegExp(r'^(\d+)x\s*(.*)$').firstMatch(trimmed);
        if (match != null) {
          final qty = int.tryParse(match.group(1) ?? '1') ?? 1;
          final name = match.group(2)?.trim() ?? '';
          final cleanName = name.toLowerCase();

          final found = menu.where((m) =>
              m.name.toLowerCase() == cleanName ||
              m.name.toLowerCase().contains(cleanName) ||
              cleanName.contains(m.name.toLowerCase()));

          if (found.isNotEmpty) {
            cart.add(CartItem(item: found.first, quantity: qty));
          } else {
            cart.add(CartItem(
              item: MenuItem(
                id: 'reorder-${cleanName.replaceAll(' ', '-')}',
                name: name,
                category: 'pusaka',
                description: 'Menu favorit Puthu Lanang',
                image: 'assets/images/puthu_bambu.png',
                price: 18000,
                stock: 100,
                rating: 5.0,
              ),
              quantity: qty,
            ));
          }
        }
      }
    }

    if (cart.isEmpty && menu.isNotEmpty) {
      cart.add(CartItem(item: menu.first, quantity: 1));
    }

    notifyListeners();
  }
}
