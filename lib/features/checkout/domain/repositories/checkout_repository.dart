import '../entities/checkout_entity.dart';

/// Kontrak Repository (Domain Layer) untuk fitur Checkout & Smart Takeaway.
abstract class CheckoutRepository {
  Future<Map<String, dynamic>> createOrder(CheckoutOrderRequest request);
}

