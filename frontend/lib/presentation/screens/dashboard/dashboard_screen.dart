import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      dashboardProvider.loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final user = authProvider.user;
    final business = authProvider.business;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              dashboardProvider.refreshStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.fullName ?? 'User'}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Phone: ${user?.phone ?? 'N/A'}'),
                    if (user?.email != null) Text('Email: ${user!.email}'),
                    Text('Role: ${user?.role ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (business != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Name: ${business.businessName}'),
                      Text('Plan: ${business.plan.toUpperCase()}'),
                      Text(
                        'Status: ${business.isActive ? "Active" : "Inactive"}',
                        style: TextStyle(
                          color: business.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildStatsContent(dashboardProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent(DashboardProvider dashboardProvider) {
    if (dashboardProvider.status == DashboardStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboardProvider.status == DashboardStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${dashboardProvider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => dashboardProvider.refreshStats(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = dashboardProvider.stats;
    if (stats == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Products',
                stats.products.total.toString(),
                Icons.inventory,
                Colors.blue,
                subtitle: '${stats.products.active} active',
              ),
              _buildStatCard(
                'Orders',
                stats.orders.total.toString(),
                Icons.shopping_cart,
                Colors.green,
                subtitle: '${stats.orders.completed} completed',
              ),
              _buildStatCard(
                'Customers',
                stats.customers.total.toString(),
                Icons.people,
                Colors.orange,
                subtitle: '${stats.customers.active} active',
              ),
              _buildStatCard(
                'Revenue',
                '₹${stats.revenue.total.toStringAsFixed(2)}',
                Icons.currency_rupee,
                Colors.purple,
                subtitle: 'Total revenue',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (stats.lowStock > 0)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${stats.products.lowStock} products have low stock',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ],
                ),
              ),
            ),
          if (stats.topProducts != null && stats.topProducts!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Top Products',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...stats.topProducts!.take(5).map((product) => Card(
                  child: ListTile(
                    title: Text(product.productName),
                    subtitle: Text('${product.quantitySold} sold'),
                    trailing: Text('₹${product.revenue.toStringAsFixed(2)}'),
                  ),
                )),
          ],
          if (stats.recentOrders != null && stats.recentOrders!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Recent Orders',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...stats.recentOrders!.take(5).map((order) => Card(
                  child: ListTile(
                    title: Text(order.orderNumber),
                    subtitle: Text(order.status),
                    trailing: Text('₹${order.totalAmount.toStringAsFixed(2)}'),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
