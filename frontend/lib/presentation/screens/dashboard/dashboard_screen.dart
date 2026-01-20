import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    business?.businessName ?? 'StoreLink',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.fullName ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Products'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/products');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Inventory'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/inventory');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/categories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Customers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/customers');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/orders');
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Business Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/business-profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/reports');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
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
          if (stats.dailySales != null && stats.dailySales!.isNotEmpty) ...[
            Text(
              'Sales Revenue (Last 30 Days)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildRevenueChart(stats.dailySales!),
            const SizedBox(height: 24),
          ],
          if (stats.products.lowStock > 0)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/inventory'),
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${stats.products.lowStock} products have low stock',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.orange.shade700),
                    ],
                  ),
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

  Widget _buildRevenueChart(List<dynamic> dailySales) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: dailySales.map((e) => e.revenue as double).reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueAccent,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '₹${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < dailySales.length) {
                    // Show every 5th date to avoid crowding
                    if (value.toInt() % 5 == 0) {
                      final date = DateTime.parse(dailySales[value.toInt()].date);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                  }
                  return const SizedBox();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '₹${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: dailySales.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.revenue as double,
                  color: Colors.blue,
                  width: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 100,
                color: color.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
