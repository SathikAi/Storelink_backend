import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/shimmer_loading.dart';
import 'customer_form_screen.dart';
import 'customer_detail_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false)
          .loadCustomers(refresh: true);
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
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        provider.loadCustomers();
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Customers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Customers'),
              onTap: () {
                Provider.of<CustomerProvider>(context, listen: false)
                    .clearFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Active Only'),
              onTap: () {
                Provider.of<CustomerProvider>(context, listen: false)
                    .setFilters(isActive: true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Inactive Only'),
              onTap: () {
                Provider.of<CustomerProvider>(context, listen: false)
                    .setFilters(isActive: false);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
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
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<CustomerProvider>(context, listen: false)
                              .searchCustomers('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                Provider.of<CustomerProvider>(context, listen: false)
                    .searchCustomers(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.customers.isEmpty) {
                  return ListView.builder(
                    itemCount: 6,
                    itemBuilder: (context, index) => const ShimmerListTile(),
                  );
                }

                if (provider.error != null && provider.customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${provider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              provider.loadCustomers(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Add your first customer to get started'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadCustomers(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.customers.length +
                        (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.customers.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final customer = provider.customers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: customer.isActive
                                ? Colors.blue.shade100
                                : Colors.grey.shade300,
                            child: Icon(
                              Icons.person,
                              color: customer.isActive
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 14),
                                  const SizedBox(width: 4),
                                  Text(customer.displayPhone),
                                ],
                              ),
                              if (customer.email != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 14),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        customer.email!,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: customer.isActive
                                      ? Colors.green.shade100
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  customer.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: customer.isActive
                                        ? Colors.green.shade900
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showCustomerOptions(customer.uuid),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerDetailScreen(customerUuid: customer.uuid),
                              ),
                            );
                            if (!context.mounted) return;
                            provider.loadCustomers(refresh: true);
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
              builder: (context) => const CustomerFormScreen(),
            ),
          );
          if (!context.mounted) return;
          if (result == true) {
            Provider.of<CustomerProvider>(context, listen: false)
                .loadCustomers(refresh: true);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCustomerOptions(String uuid) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Customer'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CustomerFormScreen(customerUuid: uuid),
                  ),
                );
                if (!context.mounted) return;
                if (result == true) {
                  Provider.of<CustomerProvider>(context, listen: false)
                      .loadCustomers(refresh: true);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Customer',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(uuid);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String uuid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content:
            const Text('Are you sure you want to delete this customer?'),
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
              final success = await provider.deleteCustomer(uuid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Customer deleted successfully'
                      : 'Error: ${provider.error}'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
