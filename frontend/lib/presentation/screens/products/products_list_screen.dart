import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/shimmer_loading.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false)
          .loadProducts(refresh: true);
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
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        provider.loadProducts();
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Products'),
              onTap: () {
                Provider.of<ProductProvider>(context, listen: false)
                    .clearFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Active Only'),
              onTap: () {
                Provider.of<ProductProvider>(context, listen: false)
                    .setFilters(isActive: true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Inactive Only'),
              onTap: () {
                Provider.of<ProductProvider>(context, listen: false)
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
        title: const Text('Products'),
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
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<ProductProvider>(context, listen: false)
                              .searchProducts('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                Provider.of<ProductProvider>(context, listen: false)
                    .searchProducts(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.products.isEmpty) {
                  return ListView.builder(
                    itemCount: 6,
                    itemBuilder: (context, index) => const ShimmerListTile(),
                  );
                }

                if (provider.error != null && provider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${provider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              provider.loadProducts(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Add your first product to get started'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadProducts(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.products.length +
                        (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final product = provider.products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag,
                                    color: Colors.blue.shade700,
                                    size: 30,
                                  ),
                                ),
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '₹${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: product.isOutOfStock
                                          ? Colors.red.shade100
                                          : product.isLowStock
                                              ? Colors.orange.shade100
                                              : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Stock: ${product.stockQuantity}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: product.isOutOfStock
                                            ? Colors.red.shade900
                                            : product.isLowStock
                                                ? Colors.orange.shade900
                                                : Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: product.isActive
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      product.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: product.isActive
                                            ? Colors.blue.shade900
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showProductOptions(product.uuid),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(productUuid: product.uuid),
                              ),
                            );
                            if (!context.mounted) return;
                            provider.loadProducts(refresh: true);
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
              builder: (context) => const ProductFormScreen(),
            ),
          );
          if (!context.mounted) return;
          if (result == true) {
            Provider.of<ProductProvider>(context, listen: false)
                .loadProducts(refresh: true);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showProductOptions(String uuid) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Product'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductFormScreen(productUuid: uuid),
                  ),
                );
                if (!context.mounted) return;
                if (result == true) {
                  Provider.of<ProductProvider>(context, listen: false)
                      .loadProducts(refresh: true);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.toggle_on),
              title: const Text('Toggle Status'),
              onTap: () async {
                Navigator.pop(context);
                final provider =
                    Provider.of<ProductProvider>(context, listen: false);
                final success = await provider.toggleProductStatus(uuid);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Product status updated'
                        : 'Error: ${provider.error}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Product',
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
        title: const Text('Delete Product'),
        content:
            const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<ProductProvider>(context, listen: false);
              final success = await provider.deleteProduct(uuid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Product deleted successfully'
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
