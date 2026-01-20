import '../../domain/entities/report_entity.dart';

class SalesReportModel extends SalesReportEntity {
  const SalesReportModel({
    required super.totalRevenue,
    required super.totalOrders,
    required super.averageOrderValue,
    required super.salesByDate,
  });

  factory SalesReportModel.fromJson(Map<String, dynamic> json) {
    return SalesReportModel(
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      totalOrders: json['total_orders'] as int,
      averageOrderValue: (json['average_order_value'] as num).toDouble(),
      salesByDate: (json['sales_by_date'] as List)
          .map((item) => SalesReportItemModel.fromJson(item))
          .toList(),
    );
  }
}

class SalesReportItemModel extends SalesReportItem {
  const SalesReportItemModel({
    required super.date,
    required super.revenue,
    required super.orders,
  });

  factory SalesReportItemModel.fromJson(Map<String, dynamic> json) {
    return SalesReportItemModel(
      date: json['date'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      orders: json['orders'] as int,
    );
  }
}

class ProductReportModel extends ProductReportEntity {
  const ProductReportModel({
    required super.totalProducts,
    required super.lowStockProducts,
    required super.totalInventoryValue,
    required super.topProducts,
  });

  factory ProductReportModel.fromJson(Map<String, dynamic> json) {
    return ProductReportModel(
      totalProducts: json['total_products'] as int,
      lowStockProducts: json['low_stock_products'] as int,
      totalInventoryValue: (json['total_inventory_value'] as num).toDouble(),
      topProducts: (json['top_products'] as List)
          .map((item) => ProductReportItemModel.fromJson(item))
          .toList(),
    );
  }
}

class ProductReportItemModel extends ProductReportItem {
  const ProductReportItemModel({
    required super.productName,
    required super.quantitySold,
    required super.revenue,
    required super.currentStock,
  });

  factory ProductReportItemModel.fromJson(Map<String, dynamic> json) {
    return ProductReportItemModel(
      productName: json['product_name'] as String,
      quantitySold: json['quantity_sold'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      currentStock: json['current_stock'] as int,
    );
  }
}

class CustomerReportModel extends CustomerReportEntity {
  const CustomerReportModel({
    required super.totalCustomers,
    required super.activeCustomers,
    required super.averageOrdersPerCustomer,
    required super.topCustomers,
  });

  factory CustomerReportModel.fromJson(Map<String, dynamic> json) {
    return CustomerReportModel(
      totalCustomers: json['total_customers'] as int,
      activeCustomers: json['active_customers'] as int,
      averageOrdersPerCustomer:
          (json['average_orders_per_customer'] as num).toDouble(),
      topCustomers: (json['top_customers'] as List)
          .map((item) => CustomerReportItemModel.fromJson(item))
          .toList(),
    );
  }
}

class CustomerReportItemModel extends CustomerReportItem {
  const CustomerReportItemModel({
    required super.customerName,
    required super.totalOrders,
    required super.totalSpent,
    super.phone,
  });

  factory CustomerReportItemModel.fromJson(Map<String, dynamic> json) {
    return CustomerReportItemModel(
      customerName: json['customer_name'] as String,
      totalOrders: json['total_orders'] as int,
      totalSpent: (json['total_spent'] as num).toDouble(),
      phone: json['phone'] as String?,
    );
  }
}
