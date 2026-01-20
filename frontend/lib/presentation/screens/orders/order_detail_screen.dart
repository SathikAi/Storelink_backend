import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../../data/models/order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderUuid;

  const OrderDetailScreen({
    super.key,
    required this.orderUuid,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false)
          .loadOrder(widget.orderUuid);
    });
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

  Future<void> _updateOrderStatus(OrderModel order) async {
    final status = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pending'),
              onTap: () => Navigator.pop(context, 'pending'),
            ),
            ListTile(
              title: const Text('Completed'),
              onTap: () => Navigator.pop(context, 'completed'),
            ),
          ],
        ),
      ),
    );

    if (status != null && mounted) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final success = await provider.updateOrder(
        widget.orderUuid,
        OrderUpdateRequest(status: status),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order status updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to update order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updatePaymentStatus(OrderModel order) async {
    final paymentStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Payment Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Unpaid'),
              onTap: () => Navigator.pop(context, 'unpaid'),
            ),
            ListTile(
              title: const Text('Partially Paid'),
              onTap: () => Navigator.pop(context, 'partially_paid'),
            ),
            ListTile(
              title: const Text('Paid'),
              onTap: () => Navigator.pop(context, 'paid'),
            ),
          ],
        ),
      ),
    );

    if (paymentStatus != null && mounted) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final success = await provider.updateOrder(
        widget.orderUuid,
        OrderUpdateRequest(paymentStatus: paymentStatus),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment status updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to update payment status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final success = await provider.cancelOrder(widget.orderUuid);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to cancel order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final success = await provider.deleteOrder(widget.orderUuid);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to delete order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          Consumer<OrderProvider>(
            builder: (context, provider, child) {
              final order = provider.currentOrder;
              if (order == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'update_status':
                      _updateOrderStatus(order);
                      break;
                    case 'update_payment':
                      _updatePaymentStatus(order);
                      break;
                    case 'cancel':
                      if (!order.isCancelled) _cancelOrder();
                      break;
                    case 'delete':
                      _deleteOrder();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!order.isCancelled)
                    const PopupMenuItem(
                      value: 'update_status',
                      child: Text('Update Status'),
                    ),
                  if (!order.isCancelled)
                    const PopupMenuItem(
                      value: 'update_payment',
                      child: Text('Update Payment'),
                    ),
                  if (!order.isCancelled)
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('Cancel Order'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Order'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
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
                        provider.loadOrder(widget.orderUuid),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final order = provider.currentOrder;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.orderDate)}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getPaymentStatusColor(order.paymentStatus)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                order.paymentStatus
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getPaymentStatusColor(order.paymentStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Items',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ...order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (item.productSku != null)
                                        Text(
                                          'SKU: ${item.productSku}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      Text(
                                        '₹${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pricing',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text(
                              '₹${order.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tax:'),
                            Text(
                              '₹${order.taxAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount:'),
                            Text(
                              '- ₹${order.discountAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (order.paymentMethod != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.payment, size: 20),
                                const SizedBox(width: 8),
                                Text('Payment Method: ${order.paymentMethod}'),
                              ],
                            ),
                          ),
                        if (order.notes != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Notes: ${order.notes}'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order History',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
                        ),
                        Text(
                          'Last Updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.updatedAt)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
