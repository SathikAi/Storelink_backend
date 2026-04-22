import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/store_provider.dart';
import '../../../core/constants/api_constants.dart';

class StoreProductScreen extends StatefulWidget {
  final String businessUuid;
  final String productUuid;

  const StoreProductScreen({
    super.key,
    required this.businessUuid,
    required this.productUuid,
  });

  @override
  State<StoreProductScreen> createState() => _StoreProductScreenState();
}

class _StoreProductScreenState extends State<StoreProductScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StoreProvider>();
      if (provider.products.isEmpty && provider.error == null) {
        provider.loadStore(widget.businessUuid);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.products.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFF070B19), // Deep navy blue
            body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
          );
        }

        final product = provider.products.where((p) => p.uuid == widget.productUuid).firstOrNull;

        if (product == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF070B19),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: Colors.white),
            ),
            body: Center(
              child: Text(
                'Product not found.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF070B19), // Deep navy blue
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const BackButton(color: Colors.white),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                            onPressed: () => context.push('/store/${widget.businessUuid}/cart'),
                          ),
                          if (provider.cartItemCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.cyan,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${provider.cartItemCount}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Background glow
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withValues(alpha: 0.3),
                        blurRadius: 150,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 200,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.2),
                        blurRadius: 150,
                      )
                    ],
                  ),
                ),
              ),

              // Scrollable Content
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Parallax Image Header
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 450,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // PageView handles multi-images with parallax effect
                          (product.imageUrls != null && product.imageUrls!.isNotEmpty)
                              ? PageView.builder(
                                  itemCount: product.imageUrls!.length,
                                  onPageChanged: (index) {
                                    // Could add state for dot indicator if needed
                                  },
                                  itemBuilder: (context, index) {
                                    return Hero(
                                      tag: index == 0 ? 'product-${product.uuid}' : 'product-img-${product.uuid}-$index',
                                      child: CachedNetworkImage(
                                        imageUrl: ApiConstants.fullUrl(product.imageUrls![index]),
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
                                        errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
                                      ),
                                    );
                                  },
                                )
                              : Hero(
                                  tag: 'product-${product.uuid}',
                                  child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: ApiConstants.fullUrl(product.imageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/images/holographic_product.png',
                                          fit: BoxFit.cover,
                                        ),
                                ),
                          // Indicator dots if multiple images
                          if (product.imageUrls != null && product.imageUrls!.length > 1)
                            Positioned(
                              bottom: 30,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  product.imageUrls!.length,
                                  (index) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Gradient fade at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 150,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xFF070B19),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          product.categoryName?.toUpperCase() ?? 'DIGITAL PRODUCT',
                          style: TextStyle(
                            color: Colors.cyan.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(product.price),
                          style: const TextStyle(
                            color: Colors.cyan,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (product.description != null && product.description!.isNotEmpty)
                          Text(
                            product.description!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 30),

                        // Bento Box Specs
                        Row(
                          children: [
                            Expanded(
                              child: _BentoCard(
                                title: 'Status',
                                value: product.isAvailable ? 'In Stock' : 'Out of Stock',
                                icon: Icons.inventory_2_outlined,
                                color: product.isAvailable ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _BentoCard(
                                title: 'Unit',
                                value: product.unit ?? 'Pcs',
                                icon: Icons.category_outlined,
                                color: Colors.purpleAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _BentoCard(
                          title: 'Available Quantity',
                          value: '${product.stockQuantity} Items',
                          icon: Icons.layers_outlined,
                          color: Colors.cyanAccent,
                          isWide: true,
                        ),
                        
                        const SizedBox(height: 120), // padding for bottom bar
                      ]),
                    ),
                  ),
                ],
              ),
              
              // Floating Buy Now Action / Cart Action
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (provider.cartQuantityFor(product.uuid) > 0)
                            Row(
                              children: [
                                _GlassIconButton(
                                  icon: Icons.remove,
                                  onTap: () => provider.removeFromCart(product.uuid),
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${provider.cartQuantityFor(product.uuid)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _GlassIconButton(
                                  icon: Icons.add,
                                  onTap: () => provider.addToCart(product),
                                ),
                                const SizedBox(width: 15),
                              ],
                            ),
                          
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: product.isAvailable
                                    ? () {
                                        if (provider.cartQuantityFor(product.uuid) == 0) {
                                          provider.addToCart(product);
                                        } else {
                                          context.push('/store/${widget.businessUuid}/cart');
                                        }
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                splashColor: Colors.cyan.withValues(alpha: 0.3),
                                highlightColor: Colors.cyan.withValues(alpha: 0.1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: product.isAvailable
                                          ? [Colors.cyan.shade400, Colors.blue.shade600]
                                          : [Colors.grey.shade700, Colors.grey.shade800],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      if (product.isAvailable)
                                        BoxShadow(
                                          color: Colors.cyan.withValues(alpha: 0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        )
                                    ],
                                  ),
                                  child: Text(
                                    product.isAvailable
                                        ? (provider.cartQuantityFor(product.uuid) > 0 ? 'Checkout' : 'Add to Cart')
                                        : 'Currently Unavailable',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _BentoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
