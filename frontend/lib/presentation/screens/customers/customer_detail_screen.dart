import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/customer_provider.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerUuid;

  const CustomerDetailScreen({super.key, required this.customerUuid});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false)
          .loadCustomer(widget.customerUuid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          Consumer<CustomerProvider>(
            builder: (context, provider, _) {
              if (provider.currentCustomer != null) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerFormScreen(
                            customerUuid: widget.customerUuid,
                          ),
                        ),
                      );
                      if (result == true) {
                        provider.loadCustomer(widget.customerUuid);
                      }
                    } else if (value == 'delete') {
                      _confirmDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.currentCustomer == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.currentCustomer == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadCustomer(widget.customerUuid),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final customer = provider.currentCustomer;
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadCustomer(widget.customerUuid),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: customer.isActive
                              ? Colors.blue.shade100
                              : Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: customer.isActive
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          customer.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: customer.isActive
                                ? Colors.green
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            customer.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoCard(
                    context,
                    'Contact Information',
                    [
                      _buildInfoRow(
                        Icons.phone,
                        'Phone',
                        customer.displayPhone,
                      ),
                      if (customer.email != null)
                        _buildInfoRow(
                          Icons.email,
                          'Email',
                          customer.email!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (customer.hasCompleteAddress)
                    _buildInfoCard(
                      context,
                      'Address',
                      [
                        if (customer.address != null)
                          _buildInfoRow(
                            Icons.location_on,
                            'Street',
                            customer.address!,
                          ),
                        if (customer.city != null)
                          _buildInfoRow(
                            Icons.location_city,
                            'City',
                            customer.city!,
                          ),
                        if (customer.state != null)
                          _buildInfoRow(
                            Icons.map,
                            'State',
                            customer.state!,
                          ),
                        if (customer.pincode != null)
                          _buildInfoRow(
                            Icons.pin_drop,
                            'Pincode',
                            customer.pincode!,
                          ),
                      ],
                    ),
                  if (customer.hasCompleteAddress) const SizedBox(height: 16),
                  if (customer.notes != null && customer.notes!.isNotEmpty)
                    _buildInfoCard(
                      context,
                      'Notes',
                      [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            customer.notes!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  if (customer.notes != null && customer.notes!.isNotEmpty)
                    const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    'Account Information',
                    [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Created',
                        DateFormat('MMM dd, yyyy').format(customer.createdAt),
                      ),
                      _buildInfoRow(
                        Icons.update,
                        'Last Updated',
                        DateFormat('MMM dd, yyyy').format(customer.updatedAt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<CustomerProvider>(context, listen: false);
              final success = await provider.deleteCustomer(widget.customerUuid);
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Customer deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${provider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
