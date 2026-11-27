import '../repositories/orders_repository.dart';

/// Use Case: Mengambil riwayat pesanan milik pengguna.
class GetOrderHistory {
  final OrdersRepository _repository;

  const GetOrderHistory(this._repository);

  Future<List<Map<String, dynamic>>> execute({
    required int userId,
    required String token,
  }) async {
    if (userId <= 0 || token.trim().isEmpty) {
      throw ArgumentError('Sesi pengguna tidak valid untuk memuat pesanan.');
    }
    return _repository.getOrders(userId: userId, token: token);
  }
}

