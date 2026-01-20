import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../../data/models/product_model.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false)
          .loadInventory(refresh: true);
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
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        provider.loadInventory();
      }
    }
  }

  void _showUpdateStockDialog(ProductModel product) {
    final TextEditingController quantityController = TextEditingController();
    bool isAddition = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Stock: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${product.stockQuantity}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Add'),
                    selected: isAddition,
                    onSelected: (selected) {
                      if (selected) setState(() => isAddition = true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Reduce'),
                    selected: !isAddition,
                    onSelected: (selected) {
                      if (selected) setState(() => isAddition = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  hintText: 'Enter quantity',
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
                final int? quantity = int.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid quantity')),
                  );
                  return;
                }

                final int change = isAddition ? quantity : -quantity;
                final provider = Provider.of<InventoryProvider>(context, listen: false);
                
                Navigator.pop(context);
                final success = await provider.updateStock(product.uuid, change);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Stock updated successfully'
                        : 'Error: ${provider.error}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Update'),
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
        title: const Text('Inventory Management'),
        actions: [
          Consumer<InventoryProvider>(
            builder: (context, provider, _) => IconButton(
              icon: Icon(
                provider.filterLowStock ? Icons.warning : Icons.warning_amber,
                color: provider.filterLowStock ? Colors.orange : null,
              ),
              tooltip: 'Filter Low Stock',
              onPressed: () => provider.toggleLowStockFilter(),
            ),
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
                          Provider.of<InventoryProvider>(context, listen: false)
                              .searchInventory('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                Provider.of<InventoryProvider>(context, listen: false)
                    .searchInventory(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
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
                              provider.loadInventory(refresh: true),
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
                          provider.filterLowStock 
                            ? 'No low stock products' 
                            : 'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadInventory(refresh: true),
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
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: product.isOutOfStock
                                  ? Colors.red.shade100
                                  : product.isLowStock
                                      ? Colors.orange.shade100
                                      : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              product.isOutOfStock
                                  ? Icons.error_outline
                                  : product.isLowStock
                                      ? Icons.warning_amber
                                      : Icons.check_circle_outline,
                              color: product.isOutOfStock
                                  ? Colors.red.shade900
                                  : product.isLowStock
                                      ? Colors.orange.shade900
                                      : Colors.green.shade900,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.sku != null)
                                Text('SKU: ${product.sku}', style: const TextStyle(fontSize: 12)),
                              Text(
                                'Current Stock: ${product.stockQuantity} ${product.unit ?? ''}',
                                style: TextStyle(
                                  color: product.isLowStock ? Colors.orange.shade900 : null,
                                  fontWeight: product.isLowStock ? FontWeight.bold : null,
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _showUpdateStockDialog(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue.shade900,
                            ),
                            child: const Text('Update'),
                          ),
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
    );
  }
}
