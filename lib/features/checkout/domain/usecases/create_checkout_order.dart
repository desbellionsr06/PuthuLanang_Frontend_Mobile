import '../entities/checkout_entity.dart';
import '../repositories/checkout_repository.dart';
import 'validate_checkout_input.dart';

/// Use Case: Memvalidasi dan membuat pesanan Checkout ke backend.
class CreateCheckoutOrder {
  final CheckoutRepository _repository;
  final ValidateCheckoutInput _validator;

  const CreateCheckoutOrder(
    this._repository, {
    ValidateCheckoutInput validator = const ValidateCheckoutInput(),
  }) : _validator = validator;

  Future<Map<String, dynamic>> execute({
    required CheckoutOrderRequest request,
    required bool isOperatingHours,
  }) async {
    _validator.execute(
      isLoggedIn: request.userId > 0 && request.token.trim().isNotEmpty,
      isOperatingHours: isOperatingHours,
      itemCount: request.items.length,
      subtotal: request.subtotal,
      pickupTimeSlot: request.pickupTime,
      pickupIsoDate: request.pickupDate,
      promoCode: request.promoCode,
      discount: request.discount,
    );

    return _repository.createOrder(request);
  }
}

