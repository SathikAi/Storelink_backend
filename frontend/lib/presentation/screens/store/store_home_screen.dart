import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/store_provider.dart';
import '../../../data/models/store_models.dart';
import '../../../core/constants/api_constants.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _orange      = Color(0xFFFF6F00);
const _bgTop       = Color(0xFF08091A);   // deep navy
const _bgBottom    = Color(0xFF13042A);   // deep violet
const _glass       = Color(0x0DFFFFFF);   // 5% white
const _glassBorder = Color(0x1AFFFFFF);   // 10% white
const _textPri     = Colors.white;
const _textSec     = Color(0x99FFFFFF);   // 60% white
const _textHint    = Color(0x4DFFFFFF);   // 30% white

// ─────────────────────────────────────────────────────────────────────────────

class StoreHomeScreen extends StatefulWidget {
  final String businessUuid;
  const StoreHomeScreen({super.key, required this.businessUuid});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  final _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadStore(widget.businessUuid);
    });
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _bannerPage++);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  String _img(String? url) =>
      (url == null || url.isEmpty) ? '' : ApiConstants.fullUrl(url);

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, _) {
        final store = provider.storeInfo;

        if (provider.isLoading && store == null) {
          return const Scaffold(
            backgroundColor: _bgTop,
            body: Center(child: CircularProgressIndicator(color: _orange)),
          );
        }

        if (provider.error != null && store == null) {
          return Scaffold(
            backgroundColor: _bgTop,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.store_mall_directory_outlined,
                        size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(provider.error ?? 'Store not found',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _textSec)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => provider.loadStore(widget.businessUuid),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (store == null) {
          return const Scaffold(
            backgroundColor: _bgTop,
            body: Center(child: CircularProgressIndicator(color: _orange)),
          );
        }

        // Collect banner images
        final banners = <String>[];
        if (store.bannerUrl != null && store.bannerUrl!.isNotEmpty) {
          banners.add(_img(store.bannerUrl));
        }
        for (final u in store.profileImageUrls ?? []) {
          final full = _img(u);
          if (full.isNotEmpty && !banners.contains(full)) banners.add(full);
        }

        // Responsive: on wide screens centre at phone width so the store
        // looks identical in browser and on mobile.
        final screenW = MediaQuery.of(context).size.width;
        const maxW = 480.0;
        final isWide = screenW > maxW;

        Widget content = Column(
          children: [
            _Header(
              store: store,
              searchController: _searchController,
              provider: provider,
              businessUuid: widget.businessUuid,
              onTrackOrder: () => _showTrackOrderDialog(context),
              onSearch: (v) {
                provider.searchProducts(widget.businessUuid, v);
                setState(() {});
              },
              onClearSearch: () {
                _searchController.clear();
                provider.searchProducts(widget.businessUuid, '');
                setState(() {});
              },
            ),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (banners.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _BannerCarousel(
                        images: banners,
                        controller: _bannerController,
                        currentPage: _bannerPage,
                        onPageChanged: (i) => setState(() => _bannerPage = i),
                      ),
                    ),

                  if (provider.categories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _Categories(
                        provider: provider,
                        businessUuid: widget.businessUuid,
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          const Text('Products',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _textPri)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _glass,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _glassBorder),
                            ),
                            child: Text(
                              '${provider.products.length} items',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _textSec,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (provider.products.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 56, color: Colors.white24),
                            SizedBox(height: 12),
                            Text('No products found',
                                style:
                                    TextStyle(color: _textSec, fontSize: 15)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final p = provider.products[i];
                            return _ProductCard(
                              product: p,
                              cartQty: provider.cartQuantityFor(p.uuid),
                              imageUrl: _img(
                                (p.imageUrls != null &&
                                        p.imageUrls!.isNotEmpty)
                                    ? p.imageUrls!.first
                                    : p.imageUrl,
                              ),
                              onAdd: () => provider.addToCart(p),
                              onRemove: () => provider.updateQuantity(
                                  p.uuid,
                                  provider.cartQuantityFor(p.uuid) - 1),
                              onTap: () => context.push(
                                  '/store/${widget.businessUuid}/product/${p.uuid}'),
                            );
                          },
                          childCount: provider.products.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(child: _Footer(store: store)),
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              ),
            ),
          ],
        );

        // On wide screens: centre the phone-width column, show side
        // panels with the same dark gradient so the bg looks seamless.
        if (isWide) {
          content = Row(
            children: [
              Expanded(child: Container(color: _bgTop)),
              SizedBox(
                width: maxW,
                child: content,
              ),
              Expanded(child: Container(color: _bgTop)),
            ],
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Full-width dark gradient background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_bgTop, _bgBottom],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),

              // Ambient glow orbs
              Positioned(
                top: -80, right: isWide ? (screenW - maxW) / 2 - 60 : -60,
                child: Container(
                  width: 260, height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_orange.withOpacity(0.18), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 200, left: isWide ? (screenW - maxW) / 2 - 80 : -80,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6C63FF).withOpacity(0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              content,
            ],
          ),
          bottomSheet: provider.cartItemCount > 0
              ? isWide
                  ? Center(
                      child: SizedBox(
                        width: maxW,
                        child: _CartBar(
                            provider: provider,
                            businessUuid: widget.businessUuid),
                      ),
                    )
                  : _CartBar(
                      provider: provider,
                      businessUuid: widget.businessUuid)
              : null,
        );
      },
    );
  }

  void _showTrackOrderDialog(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16112A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _glassBorder)),
        title: const Text('Track Order',
            style: TextStyle(fontWeight: FontWeight.w800, color: _textPri)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your order number',
                style: TextStyle(color: _textSec, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: c,
              style: const TextStyle(color: _textPri),
              decoration: InputDecoration(
                hintText: 'e.g. ORD-0001',
                hintStyle: const TextStyle(color: _textHint),
                labelText: 'Order Number',
                labelStyle: const TextStyle(color: _textSec),
                filled: true,
                fillColor: _glass,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _glassBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _glassBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _orange, width: 1.5)),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _textSec))),
          FilledButton(
            onPressed: () {
              final num = c.text.trim().toUpperCase();
              if (num.isNotEmpty) {
                Navigator.pop(ctx);
                context.push('/store/${widget.businessUuid}/order/$num');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _orange),
            child: const Text('Track'),
          ),
        ],
      ),
    );
  }
}

// ── Header (Glassmorphism) ───────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final StoreInfo store;
  final TextEditingController searchController;
  final StoreProvider provider;
  final String businessUuid;
  final VoidCallback onTrackOrder;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;

  const _Header({
    required this.store,
    required this.searchController,
    required this.provider,
    required this.businessUuid,
    required this.onTrackOrder,
    required this.onSearch,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl != null && store.logoUrl!.isNotEmpty
        ? ApiConstants.fullUrl(store.logoUrl!)
        : '';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: _orange.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: logoUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: logoUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Center(
                                    child: Text(
                                      store.businessName[0].toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          fontSize: 18),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  store.businessName[0].toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontSize: 18),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.businessName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _textPri)),
                            if (store.city != null &&
                                store.city!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 10, color: _orange),
                                  const SizedBox(width: 2),
                                  Text(store.city!,
                                      style: const TextStyle(
                                          fontSize: 11, color: _textSec)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Track order button
                      GestureDetector(
                        onTap: onTrackOrder,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _glass,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _glassBorder),
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              color: _textSec, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _glassBorder),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearch,
                      style: const TextStyle(color: _textPri, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle:
                            const TextStyle(color: _textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: _textHint, size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18, color: _textSec),
                                onPressed: onClearSearch,
                              )
                            : null,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Banner Carousel ───────────────────────────────────────────────────────────
class _BannerCarousel extends StatelessWidget {
  final List<String> images;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _BannerCarousel({
    required this.images,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final count = images.length;
    final current = currentPage % count;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients && count > 1) {
        controller.animateToPage(
          current,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: controller,
                itemCount: count,
                onPageChanged: onPageChanged,
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: images[i % count],
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _orange.withOpacity(0.3),
                          Colors.purple.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.storefront_rounded,
                          size: 48, color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Dot indicators
            if (count > 1)
              Positioned(
                bottom: 10,
                left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    count,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: i == current ? 22 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == current
                            ? _orange
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Categories ────────────────────────────────────────────────────────────────
class _Categories extends StatelessWidget {
  final StoreProvider provider;
  final String businessUuid;

  const _Categories({required this.provider, required this.businessUuid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: provider.categories.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              final sel = provider.selectedCategoryUuid == null;
              return _Pill(
                  label: 'All',
                  selected: sel,
                  onTap: () =>
                      provider.filterByCategory(businessUuid, null));
            }
            final cat = provider.categories[i - 1];
            final sel = provider.selectedCategoryUuid == cat.uuid;
            return _Pill(
                label: cat.name,
                selected: sel,
                onTap: () =>
                    provider.filterByCategory(businessUuid, cat.uuid));
          },
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _orange : _glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? _orange
                  : Colors.white.withOpacity(0.15),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: _orange.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _textSec,
              fontWeight:
                  selected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Product Card (Glass) ──────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final String imageUrl;

  const _ProductCard({
    required this.product,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
    required this.onTap,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
    final isOut = !product.isAvailable;
    final lowStock =
        !isOut && product.stockQuantity > 0 && product.stockQuantity <= 5;

    return GestureDetector(
      onTap: isOut ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: Colors.white.withOpacity(0.04)),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white.withOpacity(0.04),
                              child: const Icon(Icons.shopping_bag_outlined,
                                  color: Colors.white24, size: 32),
                            ),
                          )
                        : Container(
                            color: Colors.white.withOpacity(0.04),
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: Colors.white24, size: 32),
                          ),
                    // Bottom gradient on image
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    if (isOut)
                      Container(
                        color: Colors.black.withOpacity(0.6),
                        child: const Center(
                          child: Text('SOLD OUT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 1)),
                        ),
                      ),
                    if (lowStock)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Only ${product.stockQuantity} left',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info panel
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textPri,
                              height: 1.3)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fmt.format(product.price),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _textPri)),
                          const SizedBox(height: 5),
                          if (isOut)
                            const Text('Unavailable',
                                style: TextStyle(
                                    color: _textHint, fontSize: 11))
                          else if (cartQty == 0)
                            SizedBox(
                              width: double.infinity,
                              height: 30,
                              child: OutlinedButton(
                                onPressed: onAdd,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _orange,
                                  side: const BorderSide(color: _orange),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Add',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ),
                            )
                          else
                            Container(
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_orange, Color(0xFFFFB300)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                      color: _orange.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: onRemove,
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      child: Icon(Icons.remove,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                  Text('$cartQty',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14)),
                                  InkWell(
                                    onTap: onAdd,
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      child: Icon(Icons.add,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cart Bar (Glass) ───────────────────────────────────────────────────────────
class _CartBar extends StatelessWidget {
  final StoreProvider provider;
  final String businessUuid;

  const _CartBar({required this.provider, required this.businessUuid});

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
    return GestureDetector(
      onTap: () => context.push('/store/$businessUuid/cart'),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_orange, Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: _orange.withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${provider.cartItemCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                ),
                const SizedBox(width: 12),
                const Text('View Cart',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const Spacer(),
                Text(fmt.format(provider.cartTotal),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Footer (Glass) ────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final StoreInfo store;
  const _Footer({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final phone =
                  store.phone.replaceAll(RegExp(r'[^0-9]'), '');
              final dialCode =
                  phone.length == 10 ? '91$phone' : phone;
              final msg =
                  'Hello ${store.businessName}, I would like to share my feedback: ';
              final uri = Uri.parse(
                  'whatsapp://send?phone=$dialCode&text=${Uri.encodeComponent(msg)}');
              await launchUrl(uri,
                      mode: LaunchMode.externalApplication)
                  .catchError((_) => false);
            },
            icon: const Icon(Icons.chat_rounded, size: 16),
            label: const Text('Send Feedback on WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(
                  color: Color(0xFF25D366), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_rounded,
                  size: 13, color: Colors.white38),
              const SizedBox(width: 5),
              const Text('Powered by ',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              const Text('StoreLink',
                  style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
