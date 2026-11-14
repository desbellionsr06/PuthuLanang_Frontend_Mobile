import 'package:flutter/foundation.dart';

enum PaymentMethodType {
  cash,
  qris,
  transfer;

  String get code {
    switch (this) {
      case PaymentMethodType.cash:
        return 'cash';
      case PaymentMethodType.qris:
        return 'qris';
      case PaymentMethodType.transfer:
        return 'transfer';
    }
  }

  String get title {
    switch (this) {
      case PaymentMethodType.cash:
        return 'Bayar di Tempat (Kasir)';
      case PaymentMethodType.qris:
        return 'QRIS (GoPay, OVO, Dana, Shopee)';
      case PaymentMethodType.transfer:
        return 'Transfer Bank (Virtual Account)';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethodType.cash:
        return 'Bayar tunai di kasir gerai saat mengambil pesanan';
      case PaymentMethodType.qris:
        return 'Scan kode QR instan dari semua e-wallet & m-banking';
      case PaymentMethodType.transfer:
        return 'Bayar via BCA, BNI, BRI, Mandiri (Midtrans Snap)';
    }
  }
}

@immutable
class CheckoutState {
  /// 8 Slot Waktu Pengambilan Sesuai Jam Buka Puthu Lanang (17:30 - 21:30)
  static const List<String> pickupTimeSlots = [
    '17:30 - 18:00',
    '18:00 - 18:30',
    '18:30 - 19:00',
    '19:00 - 19:30',
    '19:30 - 20:00',
    '20:00 - 20:30',
    '20:30 - 21:00',
    '21:00 - 21:30',
  ];

  final String selectedTimeSlot;
  final String selectedDate;
  final String selectedIsoDate;
  final PaymentMethodType paymentMethod;
  final bool isProcessing;
  final String? errorMessage;
  final String? paymentRedirectUrl;
  final Map<String, dynamic>? createdOrder;

  const CheckoutState({
    this.selectedTimeSlot = '17:30 - 18:00',
    this.selectedDate = 'Hari Ini',
    required this.selectedIsoDate,
    this.paymentMethod = PaymentMethodType.cash,
    this.isProcessing = false,
    this.errorMessage,
    this.paymentRedirectUrl,
    this.createdOrder,
  });

  CheckoutState copyWith({
    String? selectedTimeSlot,
    String? selectedDate,
    String? selectedIsoDate,
    PaymentMethodType? paymentMethod,
    bool? isProcessing,
    String? errorMessage,
    String? paymentRedirectUrl,
    Map<String, dynamic>? createdOrder,
  }) {
    return CheckoutState(
      selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedIsoDate: selectedIsoDate ?? this.selectedIsoDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
      paymentRedirectUrl: paymentRedirectUrl ?? this.paymentRedirectUrl,
      createdOrder: createdOrder ?? this.createdOrder,
    );
  }
}

