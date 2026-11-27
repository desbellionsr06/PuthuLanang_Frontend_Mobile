import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../state/app_state.dart';
import '../../domain/usecases/process_digital_payment.dart';

/// ViewModel (MVVM + ChangeNotifier) untuk fitur Orders, Ticket & Digital Payment.
class OrdersViewModel extends ChangeNotifier {
  final ProcessDigitalPayment _processDigitalPayment;

  OrdersViewModel({
    required ProcessDigitalPayment processDigitalPayment,
  }) : _processDigitalPayment = processDigitalPayment;

  bool _isLoading = false;
  bool _isCompleting = false;
  bool _isProcessingPayment = false;
  String? _errorMessage;
  String? _snapRedirectUrl;
  String? _createdOrderId;

  bool get isLoading => _isLoading;
  bool get isCompleting => _isCompleting;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get errorMessage => _errorMessage;
  String? get snapRedirectUrl => _snapRedirectUrl;
  String? get createdOrderId => _createdOrderId;

  String _cleanError(Object e) => e
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Bad state: ', '');

  Future<void> refreshOrderHistory(AppState appState) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await appState.loadOrderHistory();
    } catch (_) {
      _errorMessage =
          'Tidak dapat terhubung ke server. Menampilkan data yang tersimpan di perangkat.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> markActiveOrderCompleted(AppState appState) async {
    _isCompleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await appState.completeOrder();
      return null;
    } catch (e) {
      final msg = _cleanError(e);
      _errorMessage = msg;
      return msg;
    } finally {
      _isCompleting = false;
      notifyListeners();
    }
  }

  Future<String?> processMidtransPayment({
    required AppState appState,
    required List<Map<String, dynamic>> cartItems,
    required int totalPrice,
    required String notes,
    required String pickupTime,
    required String pickupDate,
    required String selectedMethod,
  }) async {
    final userId = appState.userId;
    final token = appState.token;
    if (userId == null || token == null) {
      return 'Silakan masuk terlebih dahulu.';
    }

    _isProcessingPayment = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateIso = pickupDate.isNotEmpty
          ? pickupDate
          : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await _processDigitalPayment.execute(
        userId: userId,
        token: token,
        pickupTime: pickupTime,
        pickupDate: dateIso,
        items: cartItems,
        total: totalPrice,
        notes: '$notes [Midtrans Snap: $selectedMethod]',
        paymentMethod: selectedMethod.toLowerCase(),
      );

      final orderData = (response['data'] as Map<String, dynamic>?) ?? {};
      final redirectUrl =
          (orderData['snap_redirect_url'] ?? orderData['payment_url'])
              ?.toString();
      final orderId = (orderData['order_id'] ??
              orderData['id'] ??
              orderData['qr_code_token'])
          ?.toString();

      _snapRedirectUrl = redirectUrl;
      _createdOrderId = orderId;

      appState.ticket = orderData;
      await appState.recordOrderHistory(
        summaryItems: cartItems
            .map((e) =>
                '${e['quantity'] ?? 1}x ${e['nama'] ?? e['name'] ?? 'Puthu'}')
            .join(', '),
        total: totalPrice,
        pickupDate: orderData['pickup_date']?.toString() ?? 'Hari Ini',
        pickupTime: orderData['pickup_time']?.toString() ?? pickupTime,
        notes: notes,
        orderId: orderId,
      );
      appState.cart.clear();

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      return null;
    } catch (e) {
      final msg = _cleanError(e);
      _errorMessage = msg;
      return msg;
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }
}

