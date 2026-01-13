import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/admin_models.dart';

class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({super.key});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  String? _planFilter;
  bool? _activeFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusinesses();
    });
  }

  void _loadBusinesses({int page = 1}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    if (authProvider.accessToken != null) {
      adminProvider.setToken(authProvider.accessToken!);
      adminProvider.loadBusinesses(
        page: page,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        plan: _planFilter,
        isActive: _activeFilter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Businesses'),
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
                hintText: 'Search businesses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadBusinesses();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadBusinesses(),
            ),
          ),
          Expanded(
            child: adminProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : adminProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${adminProvider.error}'),
                            ElevatedButton(
                              onPressed: _loadBusinesses,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : adminProvider.businesses.isEmpty
                        ? const Center(child: Text('No businesses found'))
                        : RefreshIndicator(
                            onRefresh: () async => _loadBusinesses(),
                            child: ListView.builder(
                              itemCount: adminProvider.businesses.length,
                              itemBuilder: (context, index) {
                                final business = adminProvider.businesses[index];
                                return _buildBusinessCard(business);
                              },
                            ),
                          ),
          ),
          if (adminProvider.businessPagination != null)
            _buildPagination(adminProvider.businessPagination!),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(AdminBusinessListItem business) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: business.isActive ? Colors.green : Colors.red,
          child: Text(
            business.businessName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(business.businessName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${business.ownerName}'),
            Text('Plan: ${business.plan} | Products: ${business.totalProducts}'),
            Text('Revenue: ₹${business.totalRevenue.toStringAsFixed(2)}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Text(business.isActive ? 'Deactivate' : 'Activate'),
              onTap: () => _toggleBusinessStatus(business),
            ),
            const PopupMenuItem(
              value: 'plan',
              child: Text('Change Plan'),
            ),
          ],
          onSelected: (value) {
            if (value == 'plan') {
              _showPlanChangeDialog(business);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPagination(PaginationMeta pagination) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Page ${pagination.page} of ${pagination.totalPages}'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: pagination.page > 1
                    ? () => _loadBusinesses(page: pagination.page - 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: pagination.page < pagination.totalPages
                    ? () => _loadBusinesses(page: pagination.page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Businesses'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _planFilter,
              decoration: const InputDecoration(labelText: 'Plan'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'FREE', child: Text('FREE')),
                DropdownMenuItem(value: 'PAID', child: Text('PAID')),
              ],
              onChanged: (value) {
                setState(() => _planFilter = value);
              },
            ),
            DropdownButtonFormField<bool>(
              value: _activeFilter,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: true, child: Text('Active')),
                DropdownMenuItem(value: false, child: Text('Inactive')),
              ],
              onChanged: (value) {
                setState(() => _activeFilter = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _planFilter = null;
                _activeFilter = null;
              });
              Navigator.pop(context);
              _loadBusinesses();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadBusinesses();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _toggleBusinessStatus(AdminBusinessListItem business) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    try {
      await adminProvider.updateBusinessStatus(business.uuid, !business.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Business ${!business.isActive ? "activated" : "deactivated"} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showPlanChangeDialog(AdminBusinessListItem business) {
    String selectedPlan = business.plan;
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Business Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedPlan,
              decoration: const InputDecoration(labelText: 'Plan'),
              items: const [
                DropdownMenuItem(value: 'FREE', child: Text('FREE')),
                DropdownMenuItem(value: 'PAID', child: Text('PAID')),
              ],
              onChanged: (value) {
                selectedPlan = value!;
              },
            ),
            if (selectedPlan == 'PAID')
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1825)),
                  );
                  if (date != null) {
                    expiryDate = date;
                  }
                },
                child: Text(
                  expiryDate == null
                      ? 'Select Expiry Date'
                      : 'Expiry: ${expiryDate!.toLocal().toString().split(' ')[0]}',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);
              try {
                await adminProvider.updateBusinessPlan(
                  business.uuid,
                  selectedPlan,
                  expiryDate,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plan updated successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
