/// Kontrak Repository (Domain Layer) untuk fitur Pesanan, Tiket & Pembayaran Midtrans.
abstract class OrdersRepository {
  Future<List<Map<String, dynamic>>> getOrders({
    required int userId,
    required String token,
  });

  Future<void> completeOrder({
    required String orderId,
    required int userId,
    required String token,
  });

  Future<Map<String, dynamic>> getInvoice(String orderId);

  Future<Map<String, dynamic>> createPaymentOrder({
    required int userId,
    required String token,
    required String pickupTime,
    required String pickupDate,
    required List<Map<String, dynamic>> items,
    required int total,
    required String notes,
    required String paymentMethod,
  });
}

