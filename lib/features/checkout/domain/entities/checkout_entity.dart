import 'package:flutter/foundation.dart';

/// Metode pembayaran yang didukung Puthu Lanang Malang.
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

/// Entity murni untuk permintaan pembuatan pesanan checkout.
@immutable
class CheckoutOrderRequest {
  final int userId;
  final String token;
  final String pickupTime;
  final String pickupDate;
  final List<Map<String, dynamic>> items;
  final int subtotal;
  final int discount;
  final String notes;
  final String paymentMethod;
  final String? promoCode;

  const CheckoutOrderRequest({
    required this.userId,
    required this.token,
    required this.pickupTime,
    required this.pickupDate,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.notes = '',
    this.paymentMethod = 'cash',
    this.promoCode,
  });

  int get finalTotal => (subtotal - discount).clamp(0, subtotal).toInt();
}

/// Entity murni untuk state Checkout & Smart Takeaway.
@immutable
class CheckoutEntity {
  /// 8 Slot Waktu Pengambilan sesuai jam buka Puthu Lanang (17:30 - 21:30 WIB).
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

  static const String promoCodeVip = 'PUTHUHEMAT10';
  static const int promoDiscountAmount = 10000;
  static const int promoMinTransaction = 50000;

  final String selectedTimeSlot;
  final String selectedDate;
  final String selectedIsoDate;
  final PaymentMethodType paymentMethod;
  final bool isProcessing;
  final String? errorMessage;
  final String? paymentRedirectUrl;
  final Map<String, dynamic>? createdOrder;

  const CheckoutEntity({
    this.selectedTimeSlot = '17:30 - 18:00',
    this.selectedDate = 'Hari Ini',
    required this.selectedIsoDate,
    this.paymentMethod = PaymentMethodType.cash,
    this.isProcessing = false,
    this.errorMessage,
    this.paymentRedirectUrl,
    this.createdOrder,
  });
}

