class SalesReportEntity {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final List<SalesReportItem> salesByDate;

  const SalesReportEntity({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.salesByDate,
  });
}

class SalesReportItem {
  final String date;
  final double revenue;
  final int orders;

  const SalesReportItem({
    required this.date,
    required this.revenue,
    required this.orders,
  });
}

class ProductReportEntity {
  final int totalProducts;
  final int lowStockProducts;
  final double totalInventoryValue;
  final List<ProductReportItem> topProducts;

  const ProductReportEntity({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.totalInventoryValue,
    required this.topProducts,
  });
}

class ProductReportItem {
  final String productName;
  final int quantitySold;
  final double revenue;
  final int currentStock;

  const ProductReportItem({
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.currentStock,
  });
}

class CustomerReportEntity {
  final int totalCustomers;
  final int activeCustomers;
  final double averageOrdersPerCustomer;
  final List<CustomerReportItem> topCustomers;

  const CustomerReportEntity({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.averageOrdersPerCustomer,
    required this.topCustomers,
  });
}

class CustomerReportItem {
  final String customerName;
  final int totalOrders;
  final double totalSpent;
  final String? phone;

  const CustomerReportItem({
    required this.customerName,
    required this.totalOrders,
    required this.totalSpent,
    this.phone,
  });
}
