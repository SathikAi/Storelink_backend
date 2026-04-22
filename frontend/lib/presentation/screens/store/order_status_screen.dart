import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/store_api_datasource.dart';
import '../../../data/models/store_models.dart';

class OrderStatusScreen extends StatefulWidget {
  final String businessUuid;
  final String orderNumber;

  const OrderStatusScreen({
    super.key,
    required this.businessUuid,
    required this.orderNumber,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final _datasource = StoreApiDatasource();
  StoreOrderResult? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _datasource.getOrderStatus(
          widget.businessUuid, widget.orderNumber);
      setState(() => _order = result);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  static const _statusSteps = [
    'PENDING',
    'CONFIRMED',
    'PROCESSING',
    'SHIPPED',
    'DELIVERED',
  ];

  int _stepIndex(String status) {
    final idx = _statusSteps.indexOf(status.toUpperCase());
    return idx >= 0 ? idx : 0;
  }

  Color _paymentColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.success;
      case 'FAILED':
        return AppColors.error;
      case 'REFUNDED':
        return AppColors.warning;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        OutlinedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Order number header ─────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: const Border.fromBorderSide(
                                BorderSide(color: AppColors.cardBorder)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.receipt_long_rounded,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _order!.orderNumber,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.primary),
                                    ),
                                    Text(
                                      dateFmt.format(_order!.createdAt),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _paymentColor(_order!.paymentStatus)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _order!.paymentStatus,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _paymentColor(
                                              _order!.paymentStatus)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${fmt.format(_order!.totalAmount)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Status timeline ─────────────────────────────
                        if (_order!.status.toUpperCase() != 'CANCELLED')
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: const Border.fromBorderSide(
                                  BorderSide(color: AppColors.cardBorder)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Order Progress',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                _StatusTimeline(
                                    currentStep: _stepIndex(_order!.status)),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.cancel_rounded, color: AppColors.error),
                                SizedBox(width: 12),
                                Text('This order has been cancelled',
                                    style:
                                        TextStyle(color: AppColors.error,
                                            fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // ── Payment info ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: const Border.fromBorderSide(
                                BorderSide(color: AppColors.cardBorder)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.payment_rounded,
                                  color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 10),
                              Text(_order!.paymentMethod,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _paymentColor(_order!.paymentStatus)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _order!.paymentStatus,
                                  style: TextStyle(
                                      color: _paymentColor(_order!.paymentStatus),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Order items ─────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: const Border.fromBorderSide(
                                BorderSide(color: AppColors.cardBorder)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Items',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 12),
                              ..._order!.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                          '${item.productName} × ${item.quantity}',
                                          style:
                                              const TextStyle(fontSize: 13),
                                        )),
                                        Text(
                                          '₹${fmt.format(item.totalPrice)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  )),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                    '₹${fmt.format(_order!.totalAmount)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go('/store/${widget.businessUuid}'),
                            child: const Text('Continue Shopping'),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final int currentStep;
  static const _steps = ['Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered'];

  const _StatusTimeline({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          final completed = stepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: completed ? AppColors.primary : AppColors.cardBorder,
            ),
          );
        }
        // Step dot
        final stepIndex = index ~/ 2;
        final completed = stepIndex <= currentStep;
        final active = stepIndex == currentStep;
        return Column(
          children: [
            Container(
              width: active ? 28 : 20,
              height: active ? 28 : 20,
              decoration: BoxDecoration(
                color: completed ? AppColors.primary : AppColors.inputFill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: completed ? AppColors.primary : AppColors.cardBorder,
                  width: active ? 3 : 1.5,
                ),
              ),
              child: completed && !active
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 52,
              child: Text(
                _steps[stepIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                  color: completed ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
