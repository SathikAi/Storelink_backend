import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import 'category_form_screen.dart';
import 'category_detail_screen.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false)
          .loadCategories(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<CategoryProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        provider.loadCategories();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          PopupMenuButton<bool?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (isActive) {
              Provider.of<CategoryProvider>(context, listen: false)
                  .setFilter(isActive: isActive);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: true,
                child: Text('Active Only'),
              ),
              const PopupMenuItem(
                value: false,
                child: Text('Inactive Only'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadCategories(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.categories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadCategories(refresh: true),
            child: ListView.separated(
              controller: _scrollController,
              itemCount: provider.categories.length + (provider.hasMore ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == provider.categories.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final category = provider.categories[index];
                return ListTile(
                  title: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: category.isActive ? null : TextDecoration.lineThrough,
                      color: category.isActive ? null : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    category.description ?? 'No description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: category.isActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: category.isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryDetailScreen(
                          categoryUuid: category.uuid,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CategoryFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
