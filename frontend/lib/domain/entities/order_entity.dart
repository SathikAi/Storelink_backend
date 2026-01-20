class OrderItemEntity {
  final int id;
  final int orderId;
  final int? productId;
  final String productName;
  final String? productSku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;

  const OrderItemEntity({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    this.productSku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
  });
}

class OrderEntity {
  final int id;
  final String uuid;
  final String orderNumber;
  final int businessId;
  final int? customerId;
  final DateTime orderDate;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String? paymentMethod;
  final String paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemEntity> items;

  const OrderEntity({
    required this.id,
    required this.uuid,
    required this.orderNumber,
    required this.businessId,
    this.customerId,
    required this.orderDate,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    this.paymentMethod,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';
  bool get isUnpaid => paymentStatus.toLowerCase() == 'unpaid';
  bool get isPartiallyPaid => paymentStatus.toLowerCase() == 'partially_paid';

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
