import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/product_model.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _taxController = TextEditingController(text: '0.00');
  final _discountController = TextEditingController(text: '0.00');

  CustomerModel? _selectedCustomer;
  String? _paymentMethod;
  final List<OrderLineItem> _lineItems = [];

  final List<String> _paymentMethods = [
    'Cash',
    'Card',
    'UPI',
    'Bank Transfer',
    'Credit',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false)
          .loadCustomers(refresh: true);
      Provider.of<ProductProvider>(context, listen: false)
          .loadProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _lineItems.fold(0.0, (sum, item) => sum + item.total);
  }

  double get _taxAmount {
    return double.tryParse(_taxController.text) ?? 0.0;
  }

  double get _discountAmount {
    return double.tryParse(_discountController.text) ?? 0.0;
  }

  double get _totalAmount {
    return _subtotal + _taxAmount - _discountAmount;
  }

  void _addLineItem() {
    showDialog(
      context: context,
      builder: (context) => _AddLineItemDialog(
        onAdd: (item) {
          setState(() {
            _lineItems.add(item);
          });
        },
      ),
    );
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
    });
  }

  void _editLineItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _AddLineItemDialog(
        initialItem: _lineItems[index],
        onAdd: (item) {
          setState(() {
            _lineItems[index] = item;
          });
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final request = OrderCreateRequest(
      customerUuid: _selectedCustomer?.uuid,
      items: _lineItems
          .map((item) => OrderItemCreateRequest(
                productUuid: item.productUuid,
                quantity: item.quantity,
              ))
          .toList(),
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      taxAmount: _taxAmount,
      discountAmount: _discountAmount,
    );

    final provider = Provider.of<OrderProvider>(context, listen: false);
    final success = await provider.createOrder(request);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<CustomerProvider>(
                builder: (context, customerProvider, child) {
                  return DropdownButtonFormField<CustomerModel>(
                    initialValue: _selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: 'Customer (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<CustomerModel>(
                        value: null,
                        child: Text('Walk-in Customer'),
                      ),
                      ...customerProvider.customers.map((customer) {
                        return DropdownMenuItem<CustomerModel>(
                          value: customer,
                          child: Text('${customer.name} - ${customer.phone}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomer = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addLineItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_lineItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No items added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lineItems.length,
                  itemBuilder: (context, index) {
                    final item = _lineItems[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.productName),
                        subtitle: Text(
                          '₹${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editLineItem(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () => _removeLineItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              const Text(
                'Payment & Pricing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taxController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Amount',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Discount Amount',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text(
                            '₹${_subtotal.toStringAsFixed(2)}',
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
                            '₹${_taxAmount.toStringAsFixed(2)}',
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
                            '- ₹${_discountAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
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
                            '₹${_totalAmount.toStringAsFixed(2)}',
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
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Consumer<OrderProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton(
                      onPressed: provider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Create Order',
                              style: TextStyle(fontSize: 16),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderLineItem {
  final String productUuid;
  final String productName;
  final double unitPrice;
  final int quantity;

  OrderLineItem({
    required this.productUuid,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;
}

class _AddLineItemDialog extends StatefulWidget {
  final OrderLineItem? initialItem;
  final Function(OrderLineItem) onAdd;

  const _AddLineItemDialog({
    this.initialItem,
    required this.onAdd,
  });

  @override
  State<_AddLineItemDialog> createState() => _AddLineItemDialogState();
}

class _AddLineItemDialogState extends State<_AddLineItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _quantityController.text = widget.initialItem!.quantity.toString();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialItem == null ? 'Add Item' : 'Edit Item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                return DropdownButtonFormField<ProductModel>(
                  initialValue: _selectedProduct,
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    border: OutlineInputBorder(),
                  ),
                  items: productProvider.products
                      .where((p) => p.isActive)
                      .map((product) {
                    return DropdownMenuItem<ProductModel>(
                      value: product,
                      child: Text(
                        '${product.name} - ₹${product.price.toStringAsFixed(2)}',
                      ),
                    );
                  }).toList(),
                  onChanged: widget.initialItem == null
                      ? (value) {
                          setState(() {
                            _selectedProduct = value;
                          });
                        }
                      : null,
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a product';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final quantity = int.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Quantity must be greater than 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final product = _selectedProduct!;
              final quantity = int.parse(_quantityController.text);

              widget.onAdd(OrderLineItem(
                productUuid: product.uuid,
                productName: product.name,
                unitPrice: product.price,
                quantity: quantity,
              ));

              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
