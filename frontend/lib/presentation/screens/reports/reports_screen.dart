import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCurrentReport();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadCurrentReport();
    }
  }

  void _loadCurrentReport() {
    final provider = Provider.of<ReportProvider>(context, listen: false);
    final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

    switch (_tabController.index) {
      case 0:
        provider.loadSalesReport(startDate: startDateStr, endDate: endDateStr);
        break;
      case 1:
        provider.loadProductReport(
            startDate: startDateStr, endDate: endDateStr);
        break;
      case 2:
        provider.loadCustomerReport(
            startDate: startDateStr, endDate: endDateStr);
        break;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadCurrentReport();
    }
  }

  Future<void> _exportReport(String format) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.business?.plan != 'PAID') {
      _showUpgradeDialog();
      return;
    }

    final reportType = ['sales', 'products', 'customers'][_tabController.index];
    final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final provider = Provider.of<ReportProvider>(context, listen: false);
    final result = format == 'pdf'
        ? await provider.exportPDF(
            reportType: reportType,
            startDate: startDateStr,
            endDate: endDateStr,
          )
        : await provider.exportCSV(
            reportType: reportType,
            startDate: startDateStr,
            endDate: endDateStr,
          );

    if (mounted) Navigator.pop(context);

    if (result != null) {
      final blob = web.Blob([result.bytes.toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = result.filename;
      anchor.click();
      web.URL.revokeObjectURL(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported: ${result.filename}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
          'Export functionality is only available for PAID plan users. Upgrade your plan to access this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Export'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Products'),
            Tab(text: 'Customers'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: _exportReport,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectDateRange,
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesReport(),
                _buildProductReport(),
                _buildCustomerReport(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadCurrentReport,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSalesReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCurrentReport,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final report = provider.salesReport;
        if (report == null || report.salesByDate.isEmpty) {
          return const Center(child: Text('No sales data available'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadCurrentReport(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Revenue',
                      '₹${report.totalRevenue.toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Orders',
                      '${report.totalOrders}',
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Average Order Value',
                '₹${report.averageOrderValue.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Sales by Date',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...report.salesByDate.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('MMM dd, yyyy')
                          .format(DateTime.parse(item.date))),
                      subtitle: Text('${item.orders} orders'),
                      trailing: Text(
                        '₹${item.revenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCurrentReport,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final report = provider.productReport;
        if (report == null || report.topProducts.isEmpty) {
          return const Center(child: Text('No product data available'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadCurrentReport(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Products',
                      '${report.totalProducts}',
                      Icons.inventory,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Low Stock',
                      '${report.lowStockProducts}',
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Inventory Value',
                '₹${report.totalInventoryValue.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                'Revenue Contribution by Product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildProductRevenueChart(report.topProducts),
              const SizedBox(height: 24),
              const Text(
                'Top Products Detail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...report.topProducts.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.shopping_bag),
                      title: Text(item.productName),
                      subtitle: Text(
                        'Sold: ${item.quantitySold} | Stock: ${item.currentStock}',
                      ),
                      trailing: Text(
                        '₹${item.revenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductRevenueChart(List<dynamic> topProducts) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    return Container(
      height: 300,
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
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return PieChartSectionData(
              color: colors[index % colors.length],
              value: product.revenue as double,
              title: '${product.productName.substring(0, product.productName.length > 5 ? 5 : product.productName.length)}...',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCustomerReport() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCurrentReport,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final report = provider.customerReport;
        if (report == null || report.topCustomers.isEmpty) {
          return const Center(child: Text('No customer data available'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadCurrentReport(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Customers',
                      '${report.totalCustomers}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Active Customers',
                      '${report.activeCustomers}',
                      Icons.person,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Avg Orders/Customer',
                report.averageOrdersPerCustomer.toStringAsFixed(1),
                Icons.trending_up,
                Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Top Customers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...report.topCustomers.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(item.customerName),
                      subtitle: Text(
                        '${item.totalOrders} orders${item.phone != null ? ' | ${item.phone}' : ''}',
                      ),
                      trailing: Text(
                        '₹${item.totalSpent.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
