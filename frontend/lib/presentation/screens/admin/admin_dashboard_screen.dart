import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

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
      adminProvider.setToken(authProvider.accessToken!);
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
          ? const Center(child: CircularProgressIndicator())
          : adminProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${adminProvider.error}'),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: const Text('Retry'),
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
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
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
                                  'Free Plan',
                                  stats.freePlanBusinesses.toString(),
                                  Icons.free_breakfast,
                                  Colors.orange,
                                ),
                                _buildStatCard(
                                  'Paid Plan',
                                  stats.paidPlanBusinesses.toString(),
                                  Icons.star,
                                  Colors.purple,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'User Overview',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
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
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
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
                                  '₹${stats.totalRevenue.toStringAsFixed(2)}',
                                  Icons.currency_rupee,
                                  Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'This Month',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
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
                                  'Revenue',
                                  '₹${stats.revenueThisMonth.toStringAsFixed(2)}',
                                  Icons.trending_up,
                                  Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
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
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
