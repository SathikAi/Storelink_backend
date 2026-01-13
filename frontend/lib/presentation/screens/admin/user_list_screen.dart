import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/admin_models.dart';

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
      adminProvider.setToken(authProvider.accessToken!);
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                ? const Center(child: CircularProgressIndicator())
                : adminProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${adminProvider.error}'),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : adminProvider.users.isEmpty
                        ? const Center(child: Text('No users found'))
                        : RefreshIndicator(
                            onRefresh: () async => _loadUsers(),
                            child: ListView.builder(
                              itemCount: adminProvider.users.length,
                              itemBuilder: (context, index) {
                                final user = adminProvider.users[index];
                                return _buildUserCard(user);
                              },
                            ),
                          ),
          ),
          if (adminProvider.userPagination != null)
            _buildPagination(adminProvider.userPagination!),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUserListItem user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.red,
          child: Icon(
            user.role == 'SUPER_ADMIN' ? Icons.admin_panel_settings : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(user.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${user.phone}'),
            Text('Role: ${user.role} | Businesses: ${user.businessCount}'),
            Text('Verified: ${user.isVerified ? "Yes" : "No"}'),
          ],
        ),
        trailing: user.role != 'SUPER_ADMIN'
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                    onTap: () => _toggleUserStatus(user),
                  ),
                ],
              )
            : const Icon(Icons.lock, color: Colors.grey),
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
                    ? () => _loadUsers(page: pagination.page - 1)
                    : null,
              ),
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
              value: _roleFilter,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${!user.isActive ? "activated" : "deactivated"} successfully',
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
