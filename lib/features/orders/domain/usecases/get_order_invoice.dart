import '../repositories/orders_repository.dart';

/// Use Case: Mengambil detail invoice / struk pesanan berdasarkan ID.
class GetOrderInvoice {
  final OrdersRepository _repository;

  const GetOrderInvoice(this._repository);

  Future<Map<String, dynamic>> execute(String orderId) async {
    final cleanId = orderId.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError('Order ID tidak boleh kosong.');
    }
    return _repository.getInvoice(cleanId);
  }
}

