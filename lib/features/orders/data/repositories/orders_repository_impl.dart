import '../../../../services/api_service.dart';
import '../../domain/repositories/orders_repository.dart';

/// Implementasi Repository (Data Layer) untuk fitur Orders.
class OrdersRepositoryImpl implements OrdersRepository {
  @override
  Future<List<Map<String, dynamic>>> getOrders({
    required int userId,
    required String token,
  }) {
    return ApiService.getOrders(userId: userId, token: token);
  }

  @override
  Future<void> completeOrder({
    required String orderId,
    required int userId,
    required String token,
  }) {
    return ApiService.completeOrder(
      orderId: orderId,
      userId: userId,
      token: token,
    );
  }

  @override
  Future<Map<String, dynamic>> getInvoice(String orderId) {
    return ApiService.getInvoice(orderId);
  }

  @override
  Future<Map<String, dynamic>> createPaymentOrder({
    required int userId,
    required String token,
    required String pickupTime,
    required String pickupDate,
    required List<Map<String, dynamic>> items,
    required int total,
    required String notes,
    required String paymentMethod,
  }) {
    return ApiService.createOrder(
      userId: userId,
      token: token,
      pickupTime: pickupTime,
      pickupDate: pickupDate,
      items: items,
      total: total,
      notes: notes,
      paymentMethod: paymentMethod,
    );
  }
}

