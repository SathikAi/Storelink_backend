import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loading.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

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
      final p = Provider.of<ProductProvider>(context, listen: false);
      if (!p.isLoading && p.hasMore) p.loadProducts();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        onFilter: (isActive) {
          final p =
              Provider.of<ProductProvider>(context, listen: false);
          if (isActive == null) {
            p.clearFilters();
          } else {
            p.setFilters(isActive: isActive);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded,
                    color: AppColors.textPrimary),
                onPressed: _showFilterSheet,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Products',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF3B3ACF)],
                  ),
                ),
              ),
            ),
          ),

          // ── Search bar ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => Provider.of<ProductProvider>(
                        context,
                        listen: false)
                    .searchProducts(v),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<ProductProvider>(context,
                                    listen: false)
                                .searchProducts('');
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          // ── FREE plan upgrade nudge ──
          SliverToBoxAdapter(
            child: Consumer2<AuthProvider, ProductProvider>(
              builder: (context, auth, products, _) {
                if (auth.isPro) return const SizedBox.shrink();
                final total = products.products.length;
                if (total < 8) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => context.push('/upgrade'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "You've used $total/10 products — Upgrade to PRO for unlimited",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Upgrade →',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Product list ──
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.products.isEmpty) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: ShimmerListTile(),
                    ),
                    childCount: 6,
                  ),
                );
              }

              if (provider.error != null && provider.products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 56, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(provider.error!,
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              provider.loadProducts(refresh: true),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.inventory_2_rounded,
                              size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No products yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add your first product to get started',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    if (i == provider.products.length) {
                      if (provider.isLoading && provider.hasMore) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    final product = provider.products[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _ProductCard(
                        product: product,
                        onTap: () async {
                          await Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                  productUuid: product.uuid),
                            ),
                          );
                          if (!ctx.mounted) return;
                          provider.loadProducts(refresh: true);
                        },
                        onOptions: () =>
                            _showOptionsSheet(ctx, product.uuid),
                      ),
                    );
                  },
                  childCount: provider.products.length +
                      (provider.hasMore ? 1 : 0),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: _AnimatedFab(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (!mounted) return;
          if (result == true) {
            // ignore: use_build_context_synchronously
            Provider.of<ProductProvider>(context, listen: false)
                .loadProducts(refresh: true);
          }
        },
      ),
    );
  }

  void _showOptionsSheet(BuildContext ctx, String uuid) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Product',
              color: AppColors.primary,
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProductFormScreen(productUuid: uuid)),
                );
                if (!ctx.mounted) return;
                if (result == true) {
                  Provider.of<ProductProvider>(ctx, listen: false)
                      .loadProducts(refresh: true);
                }
              },
            ),
            _OptionTile(
              icon: Icons.toggle_on_rounded,
              label: 'Toggle Active / Inactive',
              color: AppColors.secondary,
              onTap: () async {
                Navigator.pop(ctx);
                final p =
                    Provider.of<ProductProvider>(ctx, listen: false);
                final ok = await p.toggleProductStatus(uuid);
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(
                      ok ? 'Status updated' : p.error ?? 'Error'),
                  backgroundColor:
                      ok ? AppColors.success : AppColors.error,
                ));
              },
            ),
            _OptionTile(
              icon: Icons.delete_rounded,
              label: 'Delete Product',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(ctx, uuid);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, String uuid) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This product will be permanently deleted. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final p =
                  Provider.of<ProductProvider>(ctx, listen: false);
              final ok = await p.deleteProduct(uuid);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(ok
                    ? 'Product deleted'
                    : p.error ?? 'Error'),
                backgroundColor:
                    ok ? AppColors.success : AppColors.error,
              ));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Product Card
// ─────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;
  final VoidCallback onOptions;
  const _ProductCard(
      {required this.product,
      required this.onTap,
      required this.onOptions});

  @override
  Widget build(BuildContext context) {
    final stockColor = product.isOutOfStock
        ? AppColors.error
        : product.isLowStock
            ? AppColors.warning
            : AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image — use imageUrls[0] if imageUrl is null
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: () {
                  final imgUrl = (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                      ? product.imageUrl!
                      : (product.imageUrls != null && product.imageUrls!.isNotEmpty)
                          ? product.imageUrls!.first
                          : null;
                  return imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _ProductImagePlaceholder(),
                        )
                      : _ProductImagePlaceholder();
                }(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name.isNotEmpty ? product.name : '(No name)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Badge(
                          label:
                              'Stock: ${product.stockQuantity}',
                          color: stockColor,
                        ),
                        const SizedBox(width: 6),
                        _Badge(
                          label: product.isActive
                              ? 'Active'
                              : 'Inactive',
                          color: product.isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textSecondary),
              onPressed: onOptions,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(Icons.shopping_bag_rounded,
              color: AppColors.primary, size: 32),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

// ─────────────────────────────────────────
// Filter Sheet
// ─────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  final void Function(bool? isActive) onFilter;
  const _FilterSheet({required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Filter Products',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _FilterOption(
            icon: Icons.all_inclusive_rounded,
            label: 'All Products',
            onTap: () {
              Navigator.pop(context);
              onFilter(null);
            },
          ),
          _FilterOption(
            icon: Icons.check_circle_rounded,
            label: 'Active Only',
            color: AppColors.success,
            onTap: () {
              Navigator.pop(context);
              onFilter(true);
            },
          ),
          _FilterOption(
            icon: Icons.cancel_rounded,
            label: 'Inactive Only',
            color: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              onFilter(false);
            },
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FilterOption({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 15)),
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      );
}

// ─────────────────────────────────────────
// Option Tile
// ─────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: color == AppColors.error ? AppColors.error : null)),
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      );
}

// ─────────────────────────────────────────
// Animated FAB
// ─────────────────────────────────────────
class _AnimatedFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _AnimatedFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4B44CC)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Product',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ),
    );
  }
}
