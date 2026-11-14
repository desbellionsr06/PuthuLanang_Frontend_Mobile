import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../state/app_state.dart';
import '../../domain/models/checkout_state.dart';

class CheckoutViewModel extends StateNotifier<CheckoutState> {
  CheckoutViewModel()
      : super(CheckoutState(
          selectedIsoDate: _formatTodayIso(),
        ));

  static String _formatTodayIso() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${pad(now.month)}-${pad(now.day)}';
  }

  /// Memilih slot waktu pengambilan (Interval 30 menit antara 17:30 - 21:30)
  void setTimeSlot(String slot) {
    if (CheckoutState.pickupTimeSlots.contains(slot)) {
      state = state.copyWith(selectedTimeSlot: slot, errorMessage: null);
    }
  }

  /// Memilih metode pembayaran (cash / qris / transfer)
  void setPaymentMethod(PaymentMethodType method) {
    state = state.copyWith(paymentMethod: method, errorMessage: null);
  }

  /// Memilih tanggal pengambilan
  void setDate({required String title, required String isoDate}) {
    state = state.copyWith(
      selectedDate: title,
      selectedIsoDate: isoDate,
      errorMessage: null,
    );
  }

  /// Mengirim pesanan ke Backend Express REST API
  Future<Map<String, dynamic>?> submitCheckout({
    required AppState appState,
    String notes = '',
    int discount = 0,
  }) async {
    if (!appState.loggedIn) {
      state = state.copyWith(errorMessage: 'Silakan masuk ke akun Anda terlebih dahulu.');
      return null;
    }

    if (appState.cart.isEmpty) {
      state = state.copyWith(errorMessage: 'Keranjang belanja Anda masih kosong.');
      return null;
    }

    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final resultData = await appState.submitOrder(
        pickupTime: state.selectedTimeSlot,
        pickupDate: state.selectedIsoDate,
        notes: notes,
        discount: discount,
        paymentMethod: state.paymentMethod.code,
      );

      final redirectUrl = (resultData['payment_url'] ?? resultData['snap_redirect_url'])?.toString();

      state = state.copyWith(
        isProcessing: false,
        createdOrder: resultData,
        paymentRedirectUrl: redirectUrl,
      );

      // Jika user memilih pembayaran online (QRIS/Transfer), buka halaman Midtrans Snap
      if (state.paymentMethod != PaymentMethodType.cash &&
          redirectUrl != null &&
          redirectUrl.isNotEmpty) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      return resultData;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }
}

final checkoutViewModelProvider =
    StateNotifierProvider<CheckoutViewModel, CheckoutState>((ref) {
  return CheckoutViewModel();
});
