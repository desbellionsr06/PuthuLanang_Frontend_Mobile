import '../../../../services/api_service.dart';
import '../../domain/entities/checkout_entity.dart';
import '../../domain/repositories/checkout_repository.dart';

/// Implementasi Repository (Data Layer) untuk fitur Checkout.
class CheckoutRepositoryImpl implements CheckoutRepository {
  @override
  Future<Map<String, dynamic>> createOrder(CheckoutOrderRequest request) async {
    return ApiService.createOrder(
      userId: request.userId,
      token: request.token,
      pickupTime: request.pickupTime,
      pickupDate: request.pickupDate,
      items: request.items,
      total: request.finalTotal,
      notes: request.notes,
      paymentMethod: request.paymentMethod,
    );
  }
}

