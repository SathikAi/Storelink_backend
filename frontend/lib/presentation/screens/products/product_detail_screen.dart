import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productUuid;

  const ProductDetailScreen({super.key, required this.productUuid});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false)
          .loadProduct(widget.productUuid);
      Provider.of<CategoryProvider>(context, listen: false)
          .loadCategories(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              if (provider.currentProduct != null) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductFormScreen(
                            productUuid: widget.productUuid,
                          ),
                        ),
                      );
                      if (result == true) {
                        provider.loadProduct(widget.productUuid);
                      }
                    } else if (value == 'toggle') {
                      final success =
                          await provider.toggleProductStatus(widget.productUuid);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Product status updated'
                              : 'Error: ${provider.error}'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      if (success) {
                        provider.loadProduct(widget.productUuid);
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
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(Icons.toggle_on),
                          SizedBox(width: 8),
                          Text('Toggle Status'),
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
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.currentProduct == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.currentProduct == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadProduct(widget.productUuid),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final product = provider.currentProduct;
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadProduct(widget.productUuid),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product images carousel
                  if (product.imageUrls != null && product.imageUrls!.isNotEmpty)
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        itemCount: product.imageUrls!.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              product.imageUrls![i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported, size: 48),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shopping_bag, size: 64, color: Colors.grey[400]),
                    ),
                  if (product.imageUrls != null && product.imageUrls!.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Swipe to see ${product.imageUrls!.length} photos',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: product.isActive
                              ? Colors.green
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (product.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      product.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildInfoCard(
                    context,
                    'Pricing',
                    [
                      _buildInfoRow(
                        Icons.currency_rupee,
                        'Price',
                        '₹${product.price.toStringAsFixed(2)}',
                      ),
                      if (product.costPrice != null)
                        _buildInfoRow(
                          Icons.price_change,
                          'Cost Price',
                          '₹${product.costPrice!.toStringAsFixed(2)}',
                        ),
                      if (product.profitMargin != null)
                        _buildInfoRow(
                          Icons.trending_up,
                          'Profit Margin',
                          '${product.profitMargin!.toStringAsFixed(2)}%',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    'Inventory',
                    [
                      _buildInfoRow(
                        Icons.inventory,
                        'Stock Quantity',
                        '${product.stockQuantity}',
                        valueColor: product.isOutOfStock
                            ? Colors.red
                            : product.isLowStock
                                ? Colors.orange
                                : null,
                      ),
                      if (product.unit != null)
                        _buildInfoRow(
                          Icons.straighten,
                          'Unit',
                          product.unit!,
                        ),
                      if (product.isLowStock)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: product.isOutOfStock
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: product.isOutOfStock
                                    ? Colors.red.shade900
                                    : Colors.orange.shade900,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  product.isOutOfStock
                                      ? 'Out of stock'
                                      : 'Low stock alert',
                                  style: TextStyle(
                                    color: product.isOutOfStock
                                        ? Colors.red.shade900
                                        : Colors.orange.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    'Product Information',
                    [
                      if (product.sku != null)
                        _buildInfoRow(
                          Icons.qr_code,
                          'SKU',
                          product.sku!,
                        ),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, _) {
                          final category = categoryProvider.categories
                              .where((c) => c.id == product.categoryId)
                              .firstOrNull;
                          return _buildInfoRow(
                            Icons.category,
                            'Category',
                            category?.name ?? 'No Category',
                          );
                        },
                      ),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Created',
                        DateFormat('MMM dd, yyyy').format(product.createdAt),
                      ),
                      _buildInfoRow(
                        Icons.update,
                        'Last Updated',
                        DateFormat('MMM dd, yyyy').format(product.updatedAt),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
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
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
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
              final success = await provider.deleteProduct(widget.productUuid);
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product deleted successfully'),
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
