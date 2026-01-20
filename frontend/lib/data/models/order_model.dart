import '../../domain/entities/order_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.id,
    required super.orderId,
    super.productId,
    required super.productName,
    super.productSku,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
    required super.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      productId: json['product_id'] as int?,
      productName: json['product_name'] as String,
      productSku: json['product_sku'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] is String)
          ? double.parse(json['unit_price'] as String)
          : (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] is String)
          ? double.parse(json['total_price'] as String)
          : (json['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      if (productId != null) 'product_id': productId,
      'product_name': productName,
      if (productSku != null) 'product_sku': productSku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.uuid,
    required super.orderNumber,
    required super.businessId,
    super.customerId,
    required super.orderDate,
    required super.status,
    required super.subtotal,
    required super.taxAmount,
    required super.discountAmount,
    required super.totalAmount,
    super.paymentMethod,
    required super.paymentStatus,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    required super.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      orderNumber: json['order_number'] as String,
      businessId: json['business_id'] as int,
      customerId: json['customer_id'] as int?,
      orderDate: DateTime.parse(json['order_date'] as String),
      status: json['status'] as String,
      subtotal: (json['subtotal'] is String)
          ? double.parse(json['subtotal'] as String)
          : (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] is String)
          ? double.parse(json['tax_amount'] as String)
          : (json['tax_amount'] as num).toDouble(),
      discountAmount: (json['discount_amount'] is String)
          ? double.parse(json['discount_amount'] as String)
          : (json['discount_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] is String)
          ? double.parse(json['total_amount'] as String)
          : (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: (json['items'] as List?)
              ?.map((item) => OrderItemModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'order_number': orderNumber,
      'business_id': businessId,
      if (customerId != null) 'customer_id': customerId,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => (item as OrderItemModel).toJson()).toList(),
    };
  }
}

class OrderItemCreateRequest {
  final String productUuid;
  final int quantity;

  const OrderItemCreateRequest({
    required this.productUuid,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_uuid': productUuid,
      'quantity': quantity,
    };
  }
}

class OrderCreateRequest {
  final String? customerUuid;
  final List<OrderItemCreateRequest> items;
  final String? paymentMethod;
  final String? notes;
  final double taxAmount;
  final double discountAmount;

  const OrderCreateRequest({
    this.customerUuid,
    required this.items,
    this.paymentMethod,
    this.notes,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      if (customerUuid != null && customerUuid!.isNotEmpty)
        'customer_uuid': customerUuid,
      'items': items.map((item) => item.toJson()).toList(),
      if (paymentMethod != null && paymentMethod!.isNotEmpty)
        'payment_method': paymentMethod,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
    };
  }
}

class OrderUpdateRequest {
  final String? status;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? notes;

  const OrderUpdateRequest({
    this.status,
    this.paymentStatus,
    this.paymentMethod,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (status != null) data['status'] = status;
    if (paymentStatus != null) data['payment_status'] = paymentStatus;
    if (paymentMethod != null) data['payment_method'] = paymentMethod;
    if (notes != null) data['notes'] = notes;
    return data;
  }
}
