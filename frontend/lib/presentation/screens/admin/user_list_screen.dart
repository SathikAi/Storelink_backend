import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/admin_models.dart';
import '../../widgets/shimmer_loading.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String? _roleFilter;
  bool? _activeFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  void _loadUsers({int page = 1}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    
    if (authProvider.accessToken != null) {
      adminProvider.loadUsers(
        page: page,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        role: _roleFilter,
        isActive: _activeFilter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
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
                hintText: 'Search users...',
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
                          _loadUsers();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadUsers(),
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
                              onPressed: _loadUsers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : adminProvider.users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text('No users found'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadUsers(),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: adminProvider.users.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final user = adminProvider.users[index];
                                return _buildUserCard(user);
                              },
                            ),
                          ),
          ),
          if (adminProvider.userPagination != null && 
              adminProvider.userPagination!.totalPages > 1)
            _buildPagination(adminProvider.userPagination!),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUserListItem user) {
    return InkWell(
      onTap: () {
        // Future: Navigate to user detail
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
                  backgroundColor: user.isActive 
                      ? Colors.teal.shade50 
                      : Colors.grey.shade100,
                  child: Icon(
                    user.role == 'SUPER_ADMIN' 
                        ? Icons.admin_panel_settings 
                        : Icons.person,
                    color: user.isActive ? Colors.teal : Colors.grey,
                    size: 28,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: user.isActive ? Colors.green : Colors.red,
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
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (user.isVerified)
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.phone,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.role == 'SUPER_ADMIN' 
                              ? Colors.red.shade50 
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: user.role == 'SUPER_ADMIN' 
                                ? Colors.red 
                                : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.business, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${user.businessCount} businesses',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (user.role != 'SUPER_ADMIN')
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          user.isActive ? Icons.block : Icons.check_circle_outline,
                          size: 20,
                          color: user.isActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Text(user.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                    onTap: () => _toggleUserStatus(user),
                  ),
                ],
              )
            else
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(Icons.lock_outline, size: 20, color: Colors.grey),
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
                      ? () => _loadUsers(page: pagination.page - 1)
                      : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: pagination.page < pagination.totalPages
                      ? () => _loadUsers(page: pagination.page + 1)
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
        title: const Text('Filter Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _roleFilter,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('SUPER_ADMIN')),
                DropdownMenuItem(value: 'BUSINESS_OWNER', child: Text('BUSINESS_OWNER')),
              ],
              onChanged: (value) {
                setState(() => _roleFilter = value);
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
                _roleFilter = null;
                _activeFilter = null;
              });
              Navigator.pop(context);
              _loadUsers();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadUsers();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(AdminUserListItem user) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    try {
      await adminProvider.updateUserStatus(user.uuid, !user.isActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User ${!user.isActive ? "activated" : "deactivated"} successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
