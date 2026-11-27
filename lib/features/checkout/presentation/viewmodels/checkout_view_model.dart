import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/location_service.dart';
import '../../../../state/app_state.dart';
import '../../../ai_insight/domain/usecases/calculate_queue_estimate.dart';
import '../../domain/entities/checkout_entity.dart';
import '../../domain/usecases/validate_checkout_input.dart';

/// ViewModel (MVVM + ChangeNotifier) untuk fitur Checkout & Smart Takeaway.
class CheckoutViewModel extends ChangeNotifier {
  final ValidateCheckoutInput _validateCheckoutInput;
  final CalculateQueueEstimate _calculateQueueEstimate;

  CheckoutViewModel({
    required ValidateCheckoutInput validateCheckoutInput,
    required CalculateQueueEstimate calculateQueueEstimate,
  })  : _validateCheckoutInput = validateCheckoutInput,
        _calculateQueueEstimate = calculateQueueEstimate,
        _selectedIsoDate = _formatTodayIso();

  static String _formatTodayIso() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${pad(now.month)}-${pad(now.day)}';
  }

  String _selectedTimeSlot = '17:30 - 18:00';
  String _selectedDate = 'Hari Ini';
  String _selectedIsoDate;
  PaymentMethodType _paymentMethod = PaymentMethodType.cash;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _paymentRedirectUrl;
  Map<String, dynamic>? _createdOrder;

  // State untuk Smart Queue Estimator di halaman Takeaway
  Map<String, dynamic>? _queueEstimate;
  bool _loadingQueue = false;
  double? _gpsDistanceKm;
  bool _detectingGps = false;

  String get selectedTimeSlot => _selectedTimeSlot;
  String get selectedDate => _selectedDate;
  String get selectedIsoDate => _selectedIsoDate;
  PaymentMethodType get paymentMethod => _paymentMethod;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get paymentRedirectUrl => _paymentRedirectUrl;
  Map<String, dynamic>? get createdOrder => _createdOrder;

  Map<String, dynamic>? get queueEstimate => _queueEstimate;
  bool get loadingQueue => _loadingQueue;
  double? get gpsDistanceKm => _gpsDistanceKm;
  bool get detectingGps => _detectingGps;

  void setTimeSlot(String slot) {
    if (CheckoutEntity.pickupTimeSlots.contains(slot)) {
      _selectedTimeSlot = slot;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void setPaymentMethod(PaymentMethodType method) {
    _paymentMethod = method;
    _errorMessage = null;
    notifyListeners();
  }

  void setDate({required String title, required String isoDate}) {
    _selectedDate = title;
    _selectedIsoDate = isoDate;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchQueueEstimate({
    required String outlet,
    required String day,
    required String timeSlot,
    String? token,
  }) async {
    _loadingQueue = true;
    notifyListeners();

    try {
      _queueEstimate = await _calculateQueueEstimate.execute(
        outlet: outlet,
        day: day,
        timeSlot: timeSlot,
        distanceKm: _gpsDistanceKm,
        token: token,
      );
    } catch (_) {
      // Abaikan jika gagal; fallback sudah disediakan repository/service
    } finally {
      _loadingQueue = false;
      notifyListeners();
    }
  }

  Future<String?> detectDistanceViaGps({
    required String outlet,
    required String day,
    required String timeSlot,
    String? token,
  }) async {
    _detectingGps = true;
    notifyListeners();

    try {
      final loc = await LocationService.getCurrentLocationToOutlet();
      _gpsDistanceKm = loc.distanceKm;
      notifyListeners();
      await fetchQueueEstimate(
        outlet: outlet,
        day: day,
        timeSlot: timeSlot,
        token: token,
      );
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _detectingGps = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> submitCheckout({
    required AppState appState,
    String notes = '',
    int discount = 0,
    String? promoCode,
    String? overrideTimeSlot,
    String? overrideIsoDate,
    String? overridePaymentMethodCode,
  }) async {
    final slot = overrideTimeSlot ?? _selectedTimeSlot;
    final isoDate = overrideIsoDate ?? _selectedIsoDate;
    final paymentCode = overridePaymentMethodCode ?? _paymentMethod.code;

    _errorMessage = null;
    try {
      _validateCheckoutInput.execute(
        isLoggedIn: appState.loggedIn,
        isOperatingHours: appState.isOperatingHours,
        itemCount: appState.cart.length,
        subtotal: appState.totalPrice,
        pickupTimeSlot: slot,
        pickupIsoDate: isoDate,
        promoCode: promoCode,
        discount: discount,
      );
    } on ArgumentError catch (e) {
      _errorMessage = e.message?.toString() ?? 'Data pesanan tidak valid.';
      notifyListeners();
      return null;
    } on StateError catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final resultData = await appState.submitOrder(
        pickupTime: slot,
        pickupDate: isoDate,
        notes: notes,
        discount: discount,
        paymentMethod: paymentCode,
        promoCode: promoCode,
      );

      final redirectUrl =
          (resultData['payment_url'] ?? resultData['snap_redirect_url'])
              ?.toString();

      _createdOrder = resultData;
      _paymentRedirectUrl = redirectUrl;
      _isProcessing = false;
      notifyListeners();

      if (paymentCode != 'cash' &&
          redirectUrl != null &&
          redirectUrl.isNotEmpty) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      return resultData;
    } catch (e) {
      _isProcessing = false;
      _errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Invalid argument(s): ', '')
          .replaceFirst('Bad state: ', '');
      notifyListeners();
      return null;
    }
  }
}
