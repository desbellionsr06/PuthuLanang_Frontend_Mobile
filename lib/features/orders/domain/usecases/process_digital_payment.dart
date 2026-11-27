import '../repositories/orders_repository.dart';

/// Use Case: Memproses pembayaran digital (Midtrans Snap) dengan validasi input.
class ProcessDigitalPayment {
  final OrdersRepository _repository;

  const ProcessDigitalPayment(this._repository);

  Future<Map<String, dynamic>> execute({
    required int userId,
    required String token,
    required String pickupTime,
    required String pickupDate,
    required List<Map<String, dynamic>> items,
    required int total,
    required String notes,
    required String paymentMethod,
  }) async {
    if (userId <= 0 || token.trim().isEmpty) {
      throw StateError('Silakan masuk terlebih dahulu.');
    }
    if (items.isEmpty || total <= 0) {
      throw ArgumentError('Item pesanan atau total pembayaran tidak valid.');
    }
    if (paymentMethod.trim().isEmpty) {
      throw ArgumentError('Metode pembayaran wajib dipilih.');
    }

    return _repository.createPaymentOrder(
      userId: userId,
      token: token,
      pickupTime: pickupTime,
      pickupDate: pickupDate,
      items: items,
      total: total,
      notes: notes,
      paymentMethod: paymentMethod.trim().toLowerCase(),
    );
  }
}

