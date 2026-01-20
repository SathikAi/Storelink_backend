import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/admin_models.dart';
import '../../widgets/shimmer_loading.dart';

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
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search businesses...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                ? ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) => const ShimmerListTile(),
                  )
                : adminProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text('Error: ${adminProvider.error}'),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadBusinesses,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : adminProvider.businesses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text('No businesses found'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadBusinesses(),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: adminProvider.businesses.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final business = adminProvider.businesses[index];
                                return _buildBusinessCard(business);
                              },
                            ),
                          ),
          ),
          if (adminProvider.businessPagination != null && 
              adminProvider.businessPagination!.totalPages > 1)
            _buildPagination(adminProvider.businessPagination!),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(AdminBusinessListItem business) {
    return InkWell(
      onTap: () {
        // Future: Navigate to business detail
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: business.isActive 
                      ? Colors.blue.shade50 
                      : Colors.grey.shade100,
                  child: Text(
                    business.businessName[0].toUpperCase(),
                    style: TextStyle(
                      color: business.isActive ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: business.isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          business.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: business.plan == 'PAID' 
                              ? Colors.purple.shade50 
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          business.plan,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: business.plan == 'PAID' 
                                ? Colors.purple 
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${business.ownerName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${business.totalProducts} products',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.currency_rupee, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        business.totalRevenue.toStringAsFixed(0),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        business.isActive ? Icons.block : Icons.check_circle_outline,
                        size: 20,
                        color: business.isActive ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Text(business.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                  onTap: () => _toggleBusinessStatus(business),
                ),
                const PopupMenuItem(
                  value: 'plan',
                  child: Row(
                    children: [
                      Icon(Icons.star_outline, size: 20, color: Colors.purple),
                      SizedBox(width: 12),
                      Text('Change Plan'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'plan') {
                  _showPlanChangeDialog(business);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(PaginationMeta pagination) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page ${pagination.page} of ${pagination.totalPages}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: pagination.page > 1
                      ? () => _loadBusinesses(page: pagination.page - 1)
                      : null,
                ),
                const SizedBox(width: 8),
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
              initialValue: _planFilter,
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
              initialValue: _activeFilter,
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
    DateTime? expiryDate = business.planExpiryDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Business Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedPlan,
                decoration: const InputDecoration(labelText: 'Plan'),
                items: const [
                  DropdownMenuItem(value: 'FREE', child: Text('FREE')),
                  DropdownMenuItem(value: 'PAID', child: Text('PAID')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedPlan = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (selectedPlan == 'PAID')
                ListTile(
                  title: const Text('Expiry Date'),
                  subtitle: Text(
                    expiryDate == null
                        ? 'Not set'
                        : expiryDate!.toLocal().toString().split(' ')[0],
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 1825)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        expiryDate = date;
                      });
                    }
                  },
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
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plan updated successfully'),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
