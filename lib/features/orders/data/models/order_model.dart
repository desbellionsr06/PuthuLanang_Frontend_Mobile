import '../../domain/entities/order_entity.dart';

/// Data Model mapper (JSON <-> OrderEntity) untuk fitur Orders.
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.status,
    required super.total,
    required super.summaryItems,
    required super.pickupDate,
    required super.pickupTime,
    super.notes,
    super.paymentMethod,
    super.paymentStatus,
    super.estimatedMinutes,
    super.estimatedReadyAt,
    super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: '${json['order_id'] ?? json['id'] ?? ''}',
      status: json['status']?.toString() ?? 'Sedang Dikukus',
      total: int.tryParse('${json['total'] ?? json['total_harga'] ?? 0}') ?? 0,
      summaryItems:
          json['summary_items']?.toString() ?? 'Pesanan Puthu Lanang',
      pickupDate: json['pickup_date']?.toString() ?? '',
      pickupTime: json['pickup_time']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      estimatedMinutes: int.tryParse('${json['estimated_minutes']}'),
      estimatedReadyAt: json['estimated_ready_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

