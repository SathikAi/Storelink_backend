import '../../domain/entities/dashboard_entity.dart';

class DashboardStatsModel extends DashboardStatsEntity {
  const DashboardStatsModel({
    required super.period,
    required super.products,
    required super.customers,
    required super.orders,
    required super.revenue,
    super.dailySales,
    super.topProducts,
    super.recentOrders,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      period: PeriodModel.fromJson(json['period']),
      products: ProductStatsModel.fromJson(json['products']),
      customers: CustomerStatsModel.fromJson(json['customers']),
      orders: OrderStatsModel.fromJson(json['orders']),
      revenue: RevenueStatsModel.fromJson(json['revenue']),
      dailySales: json['daily_sales'] != null
          ? (json['daily_sales'] as List)
              .map((e) => DailySalesModel.fromJson(e))
              .toList()
          : null,
      topProducts: json['top_products'] != null
          ? (json['top_products'] as List)
              .map((e) => TopProductModel.fromJson(e))
              .toList()
          : null,
      recentOrders: json['recent_orders'] != null
          ? (json['recent_orders'] as List)
              .map((e) => RecentOrderModel.fromJson(e))
              .toList()
          : null,
    );
  }
}

class PeriodModel extends PeriodEntity {
  const PeriodModel({
    required super.fromDate,
    required super.toDate,
  });

  factory PeriodModel.fromJson(Map<String, dynamic> json) {
    return PeriodModel(
      fromDate: json['from_date'],
      toDate: json['to_date'],
    );
  }
}

class ProductStatsModel extends ProductStatsEntity {
  const ProductStatsModel({
    required super.total,
    required super.active,
    required super.lowStock,
  });

  factory ProductStatsModel.fromJson(Map<String, dynamic> json) {
    return ProductStatsModel(
      total: json['total'],
      active: json['active'],
      lowStock: json['low_stock'],
    );
  }
}

class CustomerStatsModel extends CustomerStatsEntity {
  const CustomerStatsModel({
    required super.total,
    required super.active,
  });

  factory CustomerStatsModel.fromJson(Map<String, dynamic> json) {
    return CustomerStatsModel(
      total: json['total'],
      active: json['active'],
    );
  }
}

class OrderStatsModel extends OrderStatsEntity {
  const OrderStatsModel({
    required super.total,
    required super.pending,
    required super.processing,
    required super.completed,
    required super.cancelled,
  });

  factory OrderStatsModel.fromJson(Map<String, dynamic> json) {
    return OrderStatsModel(
      total: json['total'],
      pending: json['pending'],
      processing: json['processing'],
      completed: json['completed'],
      cancelled: json['cancelled'],
    );
  }
}

class RevenueStatsModel extends RevenueStatsEntity {
  const RevenueStatsModel({
    required super.total,
    required super.pending,
  });

  factory RevenueStatsModel.fromJson(Map<String, dynamic> json) {
    return RevenueStatsModel(
      total: (json['total'] as num).toDouble(),
      pending: (json['pending'] as num).toDouble(),
    );
  }
}

class DailySalesModel extends DailySalesEntity {
  const DailySalesModel({
    required super.date,
    required super.orderCount,
    required super.revenue,
  });

  factory DailySalesModel.fromJson(Map<String, dynamic> json) {
    return DailySalesModel(
      date: json['date'],
      orderCount: json['order_count'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class TopProductModel extends TopProductEntity {
  const TopProductModel({
    required super.productUuid,
    required super.productName,
    super.productSku,
    required super.quantitySold,
    required super.revenue,
  });

  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    return TopProductModel(
      productUuid: json['product_uuid'],
      productName: json['product_name'],
      productSku: json['product_sku'],
      quantitySold: json['quantity_sold'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class RecentOrderModel extends RecentOrderEntity {
  const RecentOrderModel({
    required super.orderUuid,
    required super.orderNumber,
    required super.status,
    required super.paymentStatus,
    required super.totalAmount,
    required super.orderDate,
  });

  factory RecentOrderModel.fromJson(Map<String, dynamic> json) {
    return RecentOrderModel(
      orderUuid: json['order_uuid'],
      orderNumber: json['order_number'],
      status: json['status'],
      paymentStatus: json['payment_status'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      orderDate: json['order_date'],
    );
  }
}
