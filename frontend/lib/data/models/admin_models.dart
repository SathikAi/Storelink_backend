class AdminBusinessListItem {
  final String uuid;
  final String businessName;
  final String ownerName;
  final String phone;
  final String? email;
  final String plan;
  final DateTime? planExpiryDate;
  final bool isActive;
  final DateTime createdAt;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;

  AdminBusinessListItem({
    required this.uuid,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    this.email,
    required this.plan,
    this.planExpiryDate,
    required this.isActive,
    required this.createdAt,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
  });

  factory AdminBusinessListItem.fromJson(Map<String, dynamic> json) {
    return AdminBusinessListItem(
      uuid: json['uuid'] as String,
      businessName: json['business_name'] as String,
      ownerName: json['owner_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      plan: json['plan'] as String,
      planExpiryDate: json['plan_expiry_date'] != null
          ? DateTime.parse(json['plan_expiry_date'] as String)
          : null,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalProducts: json['total_products'] as int,
      totalOrders: json['total_orders'] as int,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
    );
  }
}

class AdminUserListItem {
  final String uuid;
  final String fullName;
  final String phone;
  final String? email;
  final String role;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final int businessCount;

  AdminUserListItem({
    required this.uuid,
    required this.fullName,
    required this.phone,
    this.email,
    required this.role,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.businessCount,
  });

  factory AdminUserListItem.fromJson(Map<String, dynamic> json) {
    return AdminUserListItem(
      uuid: json['uuid'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      isVerified: json['is_verified'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      businessCount: json['business_count'] as int,
    );
  }
}

class PlatformStats {
  final int totalBusinesses;
  final int activeBusinesses;
  final int inactiveBusinesses;
  final int freePlanBusinesses;
  final int paidPlanBusinesses;
  final int totalUsers;
  final int activeUsers;
  final int superAdmins;
  final int businessOwners;
  final int totalProducts;
  final int totalOrders;
  final int totalCustomers;
  final double totalRevenue;
  final double revenueThisMonth;
  final int newBusinessesThisMonth;
  final int newUsersThisMonth;

  PlatformStats({
    required this.totalBusinesses,
    required this.activeBusinesses,
    required this.inactiveBusinesses,
    required this.freePlanBusinesses,
    required this.paidPlanBusinesses,
    required this.totalUsers,
    required this.activeUsers,
    required this.superAdmins,
    required this.businessOwners,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalCustomers,
    required this.totalRevenue,
    required this.revenueThisMonth,
    required this.newBusinessesThisMonth,
    required this.newUsersThisMonth,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      totalBusinesses: json['total_businesses'] as int,
      activeBusinesses: json['active_businesses'] as int,
      inactiveBusinesses: json['inactive_businesses'] as int,
      freePlanBusinesses: json['free_plan_businesses'] as int,
      paidPlanBusinesses: json['paid_plan_businesses'] as int,
      totalUsers: json['total_users'] as int,
      activeUsers: json['active_users'] as int,
      superAdmins: json['super_admins'] as int,
      businessOwners: json['business_owners'] as int,
      totalProducts: json['total_products'] as int,
      totalOrders: json['total_orders'] as int,
      totalCustomers: json['total_customers'] as int,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      revenueThisMonth: (json['revenue_this_month'] as num).toDouble(),
      newBusinessesThisMonth: json['new_businesses_this_month'] as int,
      newUsersThisMonth: json['new_users_this_month'] as int,
    );
  }
}

class PaginationMeta {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalItems: json['total_items'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}
