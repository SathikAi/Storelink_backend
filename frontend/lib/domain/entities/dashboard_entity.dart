class DashboardStatsEntity {
  final PeriodEntity period;
  final ProductStatsEntity products;
  final CustomerStatsEntity customers;
  final OrderStatsEntity orders;
  final RevenueStatsEntity revenue;
  final List<DailySalesEntity>? dailySales;
  final List<TopProductEntity>? topProducts;
  final List<RecentOrderEntity>? recentOrders;

  const DashboardStatsEntity({
    required this.period,
    required this.products,
    required this.customers,
    required this.orders,
    required this.revenue,
    this.dailySales,
    this.topProducts,
    this.recentOrders,
  });
}

class PeriodEntity {
  final String fromDate;
  final String toDate;

  const PeriodEntity({
    required this.fromDate,
    required this.toDate,
  });
}

class ProductStatsEntity {
  final int total;
  final int active;
  final int lowStock;

  const ProductStatsEntity({
    required this.total,
    required this.active,
    required this.lowStock,
  });
}

class CustomerStatsEntity {
  final int total;
  final int active;

  const CustomerStatsEntity({
    required this.total,
    required this.active,
  });
}

class OrderStatsEntity {
  final int total;
  final int pending;
  final int processing;
  final int completed;
  final int cancelled;

  const OrderStatsEntity({
    required this.total,
    required this.pending,
    required this.processing,
    required this.completed,
    required this.cancelled,
  });
}

class RevenueStatsEntity {
  final double total;
  final double pending;

  const RevenueStatsEntity({
    required this.total,
    required this.pending,
  });
}

class DailySalesEntity {
  final String date;
  final int orderCount;
  final double revenue;

  const DailySalesEntity({
    required this.date,
    required this.orderCount,
    required this.revenue,
  });
}

class TopProductEntity {
  final String productUuid;
  final String productName;
  final String? productSku;
  final int quantitySold;
  final double revenue;

  const TopProductEntity({
    required this.productUuid,
    required this.productName,
    this.productSku,
    required this.quantitySold,
    required this.revenue,
  });
}

class RecentOrderEntity {
  final String orderUuid;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final String orderDate;

  const RecentOrderEntity({
    required this.orderUuid,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.orderDate,
  });
}
