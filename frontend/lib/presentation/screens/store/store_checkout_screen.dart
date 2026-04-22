import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/store_provider.dart';
import '../../../core/theme/app_theme.dart';

class StoreCheckoutScreen extends StatefulWidget {
  final String businessUuid;
  const StoreCheckoutScreen({super.key, required this.businessUuid});

  @override
  State<StoreCheckoutScreen> createState() => _StoreCheckoutScreenState();
}

class _StoreCheckoutScreenState extends State<StoreCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'COD';
  bool _upiPaid = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _buildUpiLink(StoreProvider provider) {
    final store = provider.storeInfo;
    if (store?.upiId == null || store!.upiId!.isEmpty) return '';
    final fmt = NumberFormat('0.00');
    final amount = fmt.format(provider.cartTotal);
    final note = Uri.encodeComponent('Payment for ${store.businessName}');
    final name = Uri.encodeComponent(store.businessName);
    return 'upi://pay?pa=${store.upiId}&pn=$name&am=$amount&tn=$note&cu=INR';
  }

  Future<void> _openUpiApp(String upiLink) async {
    final uri = Uri.parse(upiLink);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open UPI apps. Please scan the QR code instead.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UPI apps not supported on this device. Please scan.')),
        );
      }
    }
  }

  void _offerWhatsAppNotification(StoreProvider provider, dynamic order) {
    final store = provider.storeInfo;
    if (store == null || store.phone.isEmpty) return;

    final phone = store.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final dialCode = phone.length == 10 ? '91$phone' : phone;

    // Build order summary message
    final items = provider.cart.map((item) =>
      '• ${item.product.name} x${item.quantity} = ₹${item.total.toStringAsFixed(0)}'
    ).join('\n');

    final orderNumber = order is Map ? (order['order_number'] ?? '') : '';
    final message = '🛍️ New Order${orderNumber.isNotEmpty ? ' #$orderNumber' : ''}\n'
        'Customer: ${_nameController.text.trim()}\n'
        'Phone: ${_phoneController.text.trim()}\n'
        '─────────────\n'
        '$items\n'
        '─────────────\n'
        'Total: ₹${provider.cartTotal.toStringAsFixed(0)}\n'
        'Payment: $_paymentMethod\n'
        '${_notesController.text.trim().isNotEmpty ? 'Notes: ${_notesController.text.trim()}' : ''}';

    final encoded = Uri.encodeComponent(message);
    final waUri = Uri.parse('whatsapp://send?phone=$dialCode&text=$encoded');

    launchUrl(waUri, mode: LaunchMode.externalApplication).catchError((_) => false);
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<StoreProvider>();

    if (_paymentMethod == 'UPI' && !_upiPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark payment as complete after scanning the QR code.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final result = await provider.placeOrder(
      businessUuid: widget.businessUuid,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;

    if (result != null) {
      // Offer WhatsApp notification to merchant
      _offerWhatsAppNotification(provider, result);
      context.pushReplacement('/store/${widget.businessUuid}/confirmed', extra: result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Order placement failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);

    return Consumer<StoreProvider>(
      builder: (context, provider, _) {
        final upiId = provider.storeInfo?.upiId;
        final hasUpi = upiId != null && upiId.isNotEmpty;
        final upiLink = _buildUpiLink(provider);

        return Scaffold(
          backgroundColor: const Color(0xFF070B19),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Complete Order', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            leading: const BackButton(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary Section
                  _CheckoutSection(
                    title: 'ORDER SUMMARY',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...provider.cart.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.product.name} x${item.quantity}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(currencyFmt.format(item.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        )),
                        const Divider(color: Colors.white10, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(currencyFmt.format(provider.cartTotal), style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Customer Details
                  _CheckoutSection(
                    title: 'WHERE SHOULD WE DELIVER?',
                    child: Column(
                      children: [
                        _ModernInput(
                          controller: _nameController,
                          label: 'Your Name',
                          hint: 'Full name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v!.isEmpty ? 'Name required' : null,
                        ),
                        const SizedBox(height: 16),
                        _ModernInput(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: '10 digit number',
                          icon: Icons.phone_android_rounded,
                          keyboard: TextInputType.phone,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v!.length != 10 ? 'Invalid number' : null,
                        ),
                        const SizedBox(height: 16),
                        _ModernInput(
                          controller: _notesController,
                          label: 'Address / Notes',
                          hint: 'Complete address or instructions',
                          icon: Icons.map_outlined,
                          lines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Method
                  _CheckoutSection(
                    title: 'CHOOSE PAYMENT',
                    child: Column(
                      children: [
                        if (hasUpi) ...[
                          _PaymentTile(
                            selected: _paymentMethod == 'UPI',
                            title: 'Pay with UPI',
                            subtitle: 'GPay · PhonePe · Paytm · Any UPI app',
                            icon: Icons.qr_code_scanner_rounded,
                            onTap: () => setState(() { _paymentMethod = 'UPI'; _upiPaid = false; }),
                          ),
                          const SizedBox(height: 4),
                        ],
                        _PaymentTile(
                          selected: _paymentMethod == 'COD',
                          title: 'Cash on Delivery',
                          subtitle: 'Pay when you receive',
                          icon: Icons.local_shipping_outlined,
                          onTap: () => setState(() { _paymentMethod = 'COD'; _upiPaid = false; }),
                        ),
                        if (!hasUpi) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.white24),
                              const SizedBox(width: 6),
                              const Text('UPI payment not available for this store', style: TextStyle(color: Colors.white24, fontSize: 11)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // UPI QR Display
                  if (_paymentMethod == 'UPI' && hasUpi) ...[
                    const SizedBox(height: 24),
                    _CheckoutSection(
                      title: 'SCAN TO PAY',
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                            child: QrImageView(
                              data: upiLink,
                              version: QrVersions.auto,
                              size: 200,
                              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('UPI ID: $upiId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Amount: ${currencyFmt.format(provider.cartTotal)}', style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _openUpiApp(upiLink),
                                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                  label: const Text('Open App'),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.accentBlue),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => setState(() => _upiPaid = true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _upiPaid ? AppColors.success : Colors.white12,
                                    foregroundColor: _upiPaid ? Colors.black : Colors.white,
                                  ),
                                  child: Text(_upiPaid ? 'Paid ✓' : 'Mark as Paid'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                  FilledButton(
                    onPressed: provider.isLoading ? null : _placeOrder,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('CONFIRM ORDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _CheckoutSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title, style: TextStyle(color: AppColors.accentBlue.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ModernInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int lines;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;

  const _ModernInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.lines = 1,
    this.keyboard,
    this.formatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: lines,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PaymentTile({required this.selected, required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentBlue.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.accentBlue : Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: selected ? AppColors.accentBlue : Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: selected ? Colors.black : Colors.white38, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: selected ? AppColors.accentBlue : Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.accentBlue, size: 20),
          ],
        ),
      ),
    );
  }
}
