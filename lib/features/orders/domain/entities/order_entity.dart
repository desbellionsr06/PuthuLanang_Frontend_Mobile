/// Entity murni untuk data pesanan pelanggan Puthu Lanang.
class OrderEntity {
  final String id;
  final String status;
  final int total;
  final String summaryItems;
  final String pickupDate;
  final String pickupTime;
  final String notes;
  final String paymentMethod;
  final String paymentStatus;
  final int? estimatedMinutes;
  final String? estimatedReadyAt;
  final String? createdAt;

  const OrderEntity({
    required this.id,
    required this.status,
    required this.total,
    required this.summaryItems,
    required this.pickupDate,
    required this.pickupTime,
    this.notes = '',
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.estimatedMinutes,
    this.estimatedReadyAt,
    this.createdAt,
  });
}

