import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../../data/models/order_model.dart';
import '../../../core/theme/app_theme.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderUuid;
  const OrderDetailScreen({super.key, required this.orderUuid});

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

  // ── Backend enum values (must match exactly) ─────────────────────────────
  static const _orderStatuses = [
    'PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'
  ];
  static const _paymentStatuses = ['PENDING', 'PAID', 'FAILED', 'REFUNDED'];

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'DELIVERED': return const Color(0xFF2E7D32);
      case 'CONFIRMED':
      case 'PROCESSING':
      case 'SHIPPED':   return const Color(0xFF1565C0);
      case 'CANCELLED': return const Color(0xFFC62828);
      default:          return const Color(0xFFE65100); // PENDING
    }
  }

  Color _paymentColor(String s) {
    switch (s.toUpperCase()) {
      case 'PAID':     return const Color(0xFF2E7D32);
      case 'FAILED':   return const Color(0xFFC62828);
      case 'REFUNDED': return const Color(0xFF6A1B9A);
      default:         return const Color(0xFFE65100); // PENDING
    }
  }

  Future<void> _updateOrderStatus(OrderModel order) async {
    final status = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Order Status',
            style: TextStyle(fontWeight: FontWeight.w700)),
        children: _orderStatuses
            .where((s) => s != order.status.toUpperCase())
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _statusColor(s),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(s,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _statusColor(s))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );

    if (status != null && mounted) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final success = await provider.updateOrder(
        widget.orderUuid,
        OrderUpdateRequest(status: status),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Order status → $status' : (provider.error ?? 'Update failed')),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  Future<void> _updatePaymentStatus(OrderModel order) async {
    final status = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Payment Status',
            style: TextStyle(fontWeight: FontWeight.w700)),
        children: _paymentStatuses
            .where((s) => s != order.paymentStatus.toUpperCase())
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _paymentColor(s),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(s,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _paymentColor(s))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );

    if (status != null && mounted) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final success = await provider.updateOrder(
        widget.orderUuid,
        OrderUpdateRequest(paymentStatus: status),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Payment → $status' : (provider.error ?? 'Update failed')),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  Future<void> _cancelOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final success = await provider.cancelOrder(widget.orderUuid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Order cancelled' : (provider.error ?? 'Failed')),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  Future<void> _deleteOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Delete this order permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final success = await provider.deleteOrder(widget.orderUuid);
      if (!mounted) return;
      if (success) Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Order deleted' : (provider.error ?? 'Failed')),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Consumer<OrderProvider>(
            builder: (_, provider, __) {
              final order = provider.currentOrder;
              if (order == null) return const SizedBox.shrink();
              final cancelled = order.status.toUpperCase() == 'CANCELLED';
              return PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'status') _updateOrderStatus(order);
                  if (v == 'payment') _updatePaymentStatus(order);
                  if (v == 'cancel') _cancelOrder();
                  if (v == 'delete') _deleteOrder();
                },
                itemBuilder: (_) => [
                  if (!cancelled) ...[
                    const PopupMenuItem(value: 'status', child: Text('Update Status')),
                    const PopupMenuItem(value: 'payment', child: Text('Update Payment')),
                    const PopupMenuItem(value: 'cancel',
                        child: Text('Cancel Order', style: TextStyle(color: Colors.red))),
                  ],
                  const PopupMenuItem(value: 'delete',
                      child: Text('Delete Order', style: TextStyle(color: Colors.red))),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(provider.error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => provider.loadOrder(widget.orderUuid),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final order = provider.currentOrder;
          if (order == null) return const Center(child: Text('Order not found'));

          final statusUp = order.status.toUpperCase();
          final payUp = order.paymentStatus.toUpperCase();

          return RefreshIndicator(
            onRefresh: () => provider.loadOrder(widget.orderUuid),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header card ─────────────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(order.orderNumber,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary)),
                            ),
                            Text(dateFmt.format(order.orderDate),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _StatusChip(
                              label: statusUp,
                              color: _statusColor(statusUp),
                              onTap: statusUp != 'CANCELLED'
                                  ? () => _updateOrderStatus(order)
                                  : null,
                            ),
                            _StatusChip(
                              label: payUp,
                              color: _paymentColor(payUp),
                              icon: Icons.payment_rounded,
                              onTap: statusUp != 'CANCELLED'
                                  ? () => _updatePaymentStatus(order)
                                  : null,
                            ),
                          ],
                        ),
                        if (statusUp != 'CANCELLED') ...[
                          const SizedBox(height: 8),
                          Text('Tap a badge to update',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Items ───────────────────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Items',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 12),
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        if (item.productSku != null)
                                          Text('SKU: ${item.productSku}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary)),
                                        Text(
                                            '${fmt.format(item.unitPrice)} × ${item.quantity}',
                                            style: const TextStyle(fontSize: 12,
                                                color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Text(fmt.format(item.totalPrice),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                ],
                              ),
                            )),
                        const Divider(height: 20),
                        _PriceRow('Subtotal', fmt.format(order.subtotal)),
                        if (order.taxAmount > 0) ...[
                          const SizedBox(height: 4),
                          _PriceRow('Tax', fmt.format(order.taxAmount)),
                        ],
                        if (order.discountAmount > 0) ...[
                          const SizedBox(height: 4),
                          _PriceRow('Discount', '- ${fmt.format(order.discountAmount)}',
                              color: Colors.red),
                        ],
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            Text(fmt.format(order.totalAmount),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Payment & Notes ─────────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Details',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 12),
                        if (order.paymentMethod != null)
                          _InfoRow(Icons.payment_rounded,
                              'Payment: ${order.paymentMethod}'),
                        if (order.notes != null && order.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _InfoRow(Icons.location_on_rounded,
                              'Address / Notes: ${order.notes}'),
                        ],
                        const SizedBox(height: 8),
                        _InfoRow(Icons.access_time_rounded,
                            'Created: ${dateFmt.format(order.createdAt)}'),
                        const SizedBox(height: 4),
                        _InfoRow(Icons.update_rounded,
                            'Updated: ${dateFmt.format(order.updatedAt)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Quick action buttons ─────────────────────────────────
                  if (statusUp != 'CANCELLED') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _updateOrderStatus(order),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Status'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _updatePaymentStatus(order),
                            icon: const Icon(Icons.payment_rounded, size: 16),
                            label: const Text('Payment'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelOrder,
                        icon: const Icon(Icons.cancel_rounded, size: 16),
                        label: const Text('Cancel Order'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;
  const _StatusChip(
      {required this.label, required this.color, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.edit_rounded, size: 11, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _PriceRow(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color ?? AppColors.textPrimary)),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary))),
        ],
      );
}
