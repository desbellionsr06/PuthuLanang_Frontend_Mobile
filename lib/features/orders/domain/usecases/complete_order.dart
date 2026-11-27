import '../repositories/orders_repository.dart';

/// Use Case: Menandai pesanan telah diterima/selesai oleh pelanggan.
class CompleteOrder {
  final OrdersRepository _repository;

  const CompleteOrder(this._repository);

  Future<void> execute({
    required String orderId,
    required int userId,
    required String token,
  }) async {
    if (orderId.trim().isEmpty) {
      throw ArgumentError('ID pesanan tidak valid.');
    }
    if (userId <= 0 || token.trim().isEmpty) {
      throw StateError('Sesi pengguna tidak valid.');
    }
    await _repository.completeOrder(
      orderId: orderId.trim(),
      userId: userId,
      token: token,
    );
  }
}

