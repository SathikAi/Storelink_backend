import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/category_provider.dart';
import 'category_form_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryUuid;

  const CategoryDetailScreen({
    super.key,
    required this.categoryUuid,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false)
          .loadCategory(widget.categoryUuid);
    });
  }

  Future<void> _deleteCategory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text(
            'Are you sure you want to delete this category? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      final success = await provider.deleteCategory(widget.categoryUuid);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to delete category'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        final category = provider.currentCategory;

        if (provider.isLoading && category == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (category == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Category Details')),
            body: Center(
              child: Text(provider.error ?? 'Category not found'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Category Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryFormScreen(
                        category: category,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteCategory,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.loadCategory(widget.categoryUuid),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: category.isActive
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: category.isActive
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.description ?? 'No description provided',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Divider(height: 32),
                        _buildInfoRow(
                          context,
                          'Created At',
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(category.createdAt),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          context,
                          'Last Updated',
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(category.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
