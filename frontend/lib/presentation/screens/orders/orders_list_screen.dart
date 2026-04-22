import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../widgets/shimmer_loading.dart';
import 'order_form_screen.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false)
          .loadOrders(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        provider.loadOrders();
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: const Text('All Statuses'),
                onTap: () {
                  Provider.of<OrderProvider>(context, listen: false)
                      .clearFilters();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Pending'),
                onTap: () {
                  Provider.of<OrderProvider>(context, listen: false)
                      .setFilters(status: 'pending');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Completed'),
                onTap: () {
                  Provider.of<OrderProvider>(context, listen: false)
                      .setFilters(status: 'completed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Cancelled'),
                onTap: () {
                  Provider.of<OrderProvider>(context, listen: false)
                      .setFilters(status: 'cancelled');
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              const Text(
                'Payment Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: const Text('Unpaid'),
                onTap: () {
                  Provider.of<OrderProvider>(context, listen: false)
                      .setFilters(paymentStatus: 'unpaid');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Partially Paid'),
                onTap: () {
                  Provider.of<OrderProvider>(context, listen: false)
                      .setFilters(paymentStatus: 'partially_paid');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Paid'),
                onTap: () {
                  Provider.of<OrderProvider>(context, listen: false)
                      .setFilters(paymentStatus: 'paid');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partially_paid':
        return Colors.orange;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by order number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<OrderProvider>(context, listen: false)
                              .searchOrders('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                Provider.of<OrderProvider>(context, listen: false)
                    .searchOrders(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.orders.isEmpty) {
                  return ListView.builder(
                    itemCount: 6,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) => const ShimmerListTile(),
                  );
                }

                if (provider.error != null && provider.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              provider.loadOrders(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.orders.isEmpty) {
                  return const Center(
                    child: Text('No orders found'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadOrders(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.orders.length +
                        (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= provider.orders.length) {
                        if (provider.isLoading && provider.hasMore) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final order = provider.orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            order.orderNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${DateFormat('dd MMM yyyy').format(order.orderDate)}',
                              ),
                              Text(
                                'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      order.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getStatusColor(order.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPaymentStatusColor(
                                              order.paymentStatus)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      order.paymentStatus
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getPaymentStatusColor(
                                            order.paymentStatus),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${order.totalItems} items',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailScreen(orderUuid: order.uuid),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OrderFormScreen(),
            ),
          );
          if (result == true) {
            if (!context.mounted) return;
            Provider.of<OrderProvider>(context, listen: false)
                .loadOrders(refresh: true);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
