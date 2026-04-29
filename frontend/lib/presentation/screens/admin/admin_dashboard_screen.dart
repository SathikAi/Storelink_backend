import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loading.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  void _loadStats() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    if (authProvider.accessToken != null) {
      adminProvider.loadPlatformStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final stats = adminProvider.platformStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: adminProvider.isLoading
          ? _buildLoadingState()
          : adminProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${adminProvider.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : stats == null
                  ? const Center(child: Text('No data available'))
                  : RefreshIndicator(
                      onRefresh: () async => _loadStats(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Overview',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.1,
                              children: [
                                _buildStatCard(
                                  'Total Businesses',
                                  stats.totalBusinesses.toString(),
                                  Icons.business,
                                  Colors.blue,
                                ),
                                _buildStatCard(
                                  'Active Businesses',
                                  stats.activeBusinesses.toString(),
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                                _buildStatCard(
                                  'FREE Plan',
                                  (stats.freePlanBusinesses + stats.trialPlanBusinesses).toString(),
                                  Icons.free_breakfast,
                                  Colors.orange,
                                ),
                                _buildStatCard(
                                  'PAID Plan',
                                  (stats.paidPlanBusinesses - stats.trialPlanBusinesses).toString(),
                                  Icons.star,
                                  Colors.purple,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (stats.totalBusinesses > 0) ...[
                              Text(
                                'Plan Distribution',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              _buildPlanChart(stats),
                              const SizedBox(height: 24),
                            ],
                            Text(
                              'User Overview',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.1,
                              children: [
                                _buildStatCard(
                                  'Total Users',
                                  stats.totalUsers.toString(),
                                  Icons.people,
                                  Colors.teal,
                                ),
                                _buildStatCard(
                                  'Active Users',
                                  stats.activeUsers.toString(),
                                  Icons.person,
                                  Colors.green,
                                ),
                                _buildStatCard(
                                  'Business Owners',
                                  stats.businessOwners.toString(),
                                  Icons.store,
                                  Colors.indigo,
                                ),
                                _buildStatCard(
                                  'Super Admins',
                                  stats.superAdmins.toString(),
                                  Icons.admin_panel_settings,
                                  Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Platform Activity',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.1,
                              children: [
                                _buildStatCard(
                                  'Total Products',
                                  stats.totalProducts.toString(),
                                  Icons.inventory,
                                  Colors.cyan,
                                ),
                                _buildStatCard(
                                  'Total Orders',
                                  stats.totalOrders.toString(),
                                  Icons.shopping_cart,
                                  Colors.amber,
                                ),
                                _buildStatCard(
                                  'Total Customers',
                                  stats.totalCustomers.toString(),
                                  Icons.people_outline,
                                  Colors.pink,
                                ),
                                _buildStatCard(
                                  'Total Revenue',
                                  '₹${stats.totalRevenue.toStringAsFixed(0)}',
                                  Icons.currency_rupee,
                                  Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'This Month Performance',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.1,
                              children: [
                                _buildStatCard(
                                  'New Businesses',
                                  stats.newBusinessesThisMonth.toString(),
                                  Icons.add_business,
                                  Colors.blue,
                                ),
                                _buildStatCard(
                                  'New Users',
                                  stats.newUsersThisMonth.toString(),
                                  Icons.person_add,
                                  Colors.green,
                                ),
                                _buildStatCard(
                                  'Monthly Revenue',
                                  '₹${stats.revenueThisMonth.toStringAsFixed(0)}',
                                  Icons.trending_up,
                                  Colors.green,
                                  subtitle: 'Current month',
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 200, height: 24),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: List.generate(
              4,
              (index) => const ShimmerLoading(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ShimmerLoading(width: 150, height: 24),
          const SizedBox(height: 16),
          const ShimmerLoading(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          const SizedBox(height: 24),
          const ShimmerLoading(width: 200, height: 24),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: List.generate(
              4,
              (index) => const ShimmerLoading(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanChart(dynamic stats) {
    final freeCount = stats.freePlanBusinesses + stats.trialPlanBusinesses;
    final paidCount = stats.paidPlanBusinesses - stats.trialPlanBusinesses;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: freeCount.toDouble(),
                    title: '$freeCount',
                    color: Colors.orange,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: paidCount.toDouble(),
                    title: '$paidCount',
                    color: Colors.purple,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartLegend('FREE Plan', Colors.orange),
                const SizedBox(height: 8),
                _buildChartLegend('PAID Plan', Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, {String? subtitle}) {
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
              right: -15,
              bottom: -15,
              child: Icon(
                icon,
                size: 80,
                color: color.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
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
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const Spacer(),
                  FittedBox(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
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
