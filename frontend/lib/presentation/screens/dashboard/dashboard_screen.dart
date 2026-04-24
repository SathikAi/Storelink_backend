import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/biometric_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false)
          .loadDashboardStats();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      Provider.of<DashboardProvider>(context, listen: false)
          .loadDashboardStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final dashboard = Provider.of<DashboardProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _navIndex == 0
              ? _DashboardBody(auth: auth, dashboard: dashboard)
              : _buildNavPlaceholder(_navIndex),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      drawer: _buildDrawer(auth),
    );
  }

  Future<void> _showBiometricSettings(BuildContext context) async {
    final bio = BiometricService();
    final available = await bio.isAvailable();
    if (!context.mounted) return;

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication is not available on this device')),
      );
      return;
    }

    final enabled = await bio.isEnabled();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Security'),
          content: SwitchListTile(
            title: const Text('Fingerprint / Face unlock'),
            subtitle: const Text('Use biometrics to unlock the app'),
            value: enabled,
            activeColor: const Color(0xFF6C63FF),
            activeTrackColor: const Color(0xFF6C63FF).withOpacity(0.4),
            inactiveThumbColor: const Color(0xFF888888),
            inactiveTrackColor: const Color(0xFFCCCCCC),
            onChanged: (val) async {
              if (val) {
                final auth = await bio.authenticate();
                if (!auth) return;
              }
              await bio.setEnabled(val);
              setDialogState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(val ? 'Biometric login enabled' : 'Biometric login disabled'),
                ));
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
      BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_rounded), label: 'Products'),
      BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
      BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded), label: 'Customers'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) async {
          if (i == 1) {
            await context.push('/products');
            if (mounted) {
              Provider.of<DashboardProvider>(context, listen: false)
                  .loadDashboardStats();
            }
          } else if (i == 2) {
            await context.push('/orders');
            if (mounted) {
              Provider.of<DashboardProvider>(context, listen: false)
                  .loadDashboardStats();
            }
          } else if (i == 3) {
            await context.push('/customers');
            if (mounted) {
              Provider.of<DashboardProvider>(context, listen: false)
                  .loadDashboardStats();
            }
          } else {
            setState(() => _navIndex = i);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: items,
      ),
    );
  }

  Widget _buildNavPlaceholder(int index) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildDrawer(AuthProvider auth) {
    final user = auth.user;
    final business = auth.business;
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFF3B3ACF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: (business?.logoUrl != null &&
                          business!.logoUrl!.isNotEmpty)
                      ? NetworkImage(business.logoUrl!)
                      : null,
                  child: (business?.logoUrl == null ||
                          business!.logoUrl!.isEmpty)
                      ? Text(
                          (user?.fullName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  business?.businessName ?? 'StoreLink',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.phone ?? '',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    business?.plan.toUpperCase() ?? 'FREE',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(Icons.dashboard_rounded, 'Dashboard', () {
                  Navigator.pop(context);
                }),
                _drawerItem(Icons.inventory_2_rounded, 'Products', () {
                  Navigator.pop(context);
                  context.push('/products');
                }),
                _drawerItem(Icons.warehouse_rounded, 'Inventory', () {
                  Navigator.pop(context);
                  context.push('/inventory');
                }),
                _drawerItem(Icons.category_rounded, 'Categories', () {
                  Navigator.pop(context);
                  context.push('/categories');
                }),
                _drawerItem(Icons.people_rounded, 'Customers', () {
                  Navigator.pop(context);
                  context.push('/customers');
                }),
                _drawerItem(Icons.receipt_long_rounded, 'Orders', () {
                  Navigator.pop(context);
                  context.push('/orders');
                }),
                _drawerItem(Icons.store_rounded, 'Business Profile', () {
                  Navigator.pop(context);
                  context.push('/business-profile');
                }),
                _drawerItem(Icons.bar_chart_rounded, 'Reports', () {
                  Navigator.pop(context);
                  context.push('/reports');
                }),
                _drawerItem(Icons.workspace_premium_rounded, 'Upgrade to PRO', () {
                  Navigator.pop(context);
                  context.push('/upgrade');
                }, color: const Color(0xFF6C63FF)),
                _drawerItem(Icons.fingerprint_rounded, 'Security', () {
                  Navigator.pop(context);
                  _showBiometricSettings(context);
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(),
                ),
                _drawerItem(Icons.logout_rounded, 'Logout', () async {
                  Navigator.pop(context);
                  await auth.logout();
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    context.go('/login');
                  }
                }, color: AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color ?? AppColors.primary),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: c)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ─────────────────────────────────────────
// Dashboard Body
// ─────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final AuthProvider auth;
  final DashboardProvider dashboard;
  const _DashboardBody({required this.auth, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    final business = auth.business;
    final stats = dashboard.stats;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return RefreshIndicator(
      onRefresh: () => dashboard.refreshStats(),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF3B3ACF)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting,',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              business?.businessName ?? 'Store',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(children: [
                              Icon(Icons.store_rounded,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.75)),
                              const SizedBox(width: 4),
                              Text(
                                business?.businessName ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 13,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      // Avatar + refresh
                      Column(
                        children: [
                          Builder(builder: (ctx) => GestureDetector(
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: (business?.logoUrl != null &&
                                      business!.logoUrl!.isNotEmpty)
                                  ? NetworkImage(business.logoUrl!)
                                  : null,
                              child: (business?.logoUrl == null ||
                                      business!.logoUrl!.isEmpty)
                                  ? Text(
                                      (user?.fullName ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18),
                                    )
                                  : null,
                            ),
                          )),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => dashboard.refreshStats(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (dashboard.status == DashboardStatus.loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (dashboard.status == DashboardStatus.error)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 56, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(dashboard.error ?? 'Something went wrong',
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => dashboard.refreshStats(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (stats != null) ...[
            // ── Stat cards ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _StatCard(
                      label: 'Products',
                      value: stats.products.total.toString(),
                      sub: '${stats.products.active} active',
                      icon: Icons.inventory_2_rounded,
                      gradient: const [Color(0xFF6C63FF), Color(0xFF9B93FF)],
                    ),
                    _StatCard(
                      label: 'Orders',
                      value: stats.orders.total.toString(),
                      sub: '${stats.orders.completed} done',
                      icon: Icons.receipt_long_rounded,
                      gradient: const [Color(0xFF26D782), Color(0xFF00B09B)],
                    ),
                    _StatCard(
                      label: 'Customers',
                      value: stats.customers.total.toString(),
                      sub: '${stats.customers.active} active',
                      icon: Icons.people_rounded,
                      gradient: const [Color(0xFFFFB142), Color(0xFFFF6F00)],
                    ),
                    _StatCard(
                      label: 'Revenue',
                      value:
                          '₹${_compact(stats.revenue.total)}',
                      sub: 'Total earned',
                      icon: Icons.currency_rupee_rounded,
                      gradient: const [Color(0xFFFF4757), Color(0xFFFF6B81)],
                    ),
                  ],
                ),
              ),
            ),

            // ── Subscription Status Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _SubscriptionCard(business: business),
              ),
            ),

            // ── My Store Share Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _StoreShareCard(business: business),
              ),
            ),

            // ── Low stock warning ──
            if (stats.products.lowStock > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () =>
                        context.push('/inventory'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${stats.products.lowStock} products running low on stock',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A5300)),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.warning),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Revenue Chart ──
            if (stats.dailySales != null && stats.dailySales!.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(children: [
                    const Text('Sales (30 Days)',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Last 30d',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _RevenueChart(dailySales: stats.dailySales!),
                ),
              ),
            ],

            // ── Top Products ──
            if (stats.topProducts != null &&
                stats.topProducts!.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(children: [
                    const Text('Top Products',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          context.push('/products'),
                      child: const Text('See all',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final p = stats.topProducts![i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _TopProductTile(
                          rank: i + 1,
                          name: p.productName,
                          sold: p.quantitySold,
                          revenue: p.revenue),
                    );
                  },
                  childCount:
                      stats.topProducts!.length.clamp(0, 5),
                ),
              ),
            ],

            // ── Recent Orders ──
            if (stats.recentOrders != null &&
                stats.recentOrders!.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(children: [
                    const Text('Recent Orders',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          context.push('/orders'),
                      child: const Text('See all',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final o = stats.recentOrders![i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _RecentOrderTile(
                          number: o.orderNumber,
                          status: o.status,
                          amount: o.totalAmount),
                    );
                  },
                  childCount:
                      stats.recentOrders!.length.clamp(0, 5),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────
// Subscription Status Card
// ─────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final dynamic business;
  const _SubscriptionCard({required this.business});

  @override
  Widget build(BuildContext context) {
    final isPaid = (business?.plan as String?)?.toUpperCase() == 'PAID';
    final expiryDate = business?.planExpiryDate as DateTime?;
    final subType = business?.subscriptionType as String?;

    int? daysRemaining;
    if (expiryDate != null) {
      daysRemaining = expiryDate.difference(DateTime.now()).inDays.clamp(0, 99999);
    }

    if (isPaid && daysRemaining != null && daysRemaining > 0) {
      // ── PRO Active card ──
      final maxDays = (subType == 'monthly') ? 30 : 365;
      final progress = (daysRemaining / maxDays).clamp(0.0, 1.0);
      final planLabel = subType == 'monthly' ? 'PRO Monthly' : 'PRO Yearly';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        planLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$daysRemaining days remaining',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      color: const Color(0xFF69F0AE),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── FREE plan upgrade nudge ──
    return GestureDetector(
      onTap: () => context.push('/upgrade'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6F00).withOpacity(0.9),
              const Color(0xFFFFB300).withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upgrade to PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlock unlimited products & analytics from ₹699/mo',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(
                  color: Color(0xFFFF6F00),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Store Share Card
// ─────────────────────────────────────────
class _StoreShareCard extends StatelessWidget {
  final dynamic business;
  const _StoreShareCard({required this.business});

  void _openInBrowser(String url, BuildContext context) {
    // Navigate directly inside the Flutter app — no browser/web server needed
    final uuid = business?.uuid as String?;
    if (uuid != null && uuid.isNotEmpty) {
      context.push('/store/$uuid');
    }
  }

  Future<void> _shareViaWhatsApp(String url, String businessName, BuildContext context) async {
    final text = Uri.encodeComponent('Shop at $businessName!\n$url');
    final waUri = Uri.parse('whatsapp://send?text=$text');
    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri);
    } else {
      // fallback to general share
      await Share.share('Shop at $businessName!\n$url', subject: 'Visit our store');
    }
  }

  void _showQrSheet(String url, String businessName, BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Store QR Code',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Customers can scan to open your store',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 220,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              businessName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              url,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Share.share('Shop at $businessName!\n$url', subject: 'Scan to visit our store');
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share QR', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11998E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uuid = business?.uuid as String?;
    if (uuid == null || uuid.isEmpty) return const SizedBox.shrink();
    final url = ApiConstants.storeUrl(uuid);
    final businessName = business?.businessName as String? ?? 'our store';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998E).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Customer Store',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Share this link with your customers',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Preview icon button in header
              GestureDetector(
                onTap: () => _openInBrowser(url, context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.open_in_browser_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // URL display — tap to preview
          GestureDetector(
            onTap: () => _openInBrowser(url, context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_outward_rounded,
                      color: Colors.white54, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action buttons — 4 in a row
          Row(
            children: [
              // Preview
              Expanded(
                child: _ActionBtn(
                  icon: Icons.visibility_rounded,
                  label: 'Preview',
                  onTap: () => _openInBrowser(url, context),
                  filled: false,
                ),
              ),
              const SizedBox(width: 6),
              // Copy
              Expanded(
                child: _ActionBtn(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Store link copied!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  filled: false,
                ),
              ),
              const SizedBox(width: 6),
              // Share (WhatsApp first, fallback to system share)
              Expanded(
                child: _ActionBtn(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () => _shareViaWhatsApp(url, businessName, context),
                  filled: false,
                ),
              ),
              const SizedBox(width: 6),
              // QR Code
              Expanded(
                child: _ActionBtn(
                  icon: Icons.qr_code_rounded,
                  label: 'QR',
                  onTap: () => _showQrSheet(url, businessName, context),
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Action Button (used in store card)
// ─────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF11998E),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 9),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        padding: const EdgeInsets.symmetric(vertical: 9),
        textStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final List<Color> gradient;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.icon,
      required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              Text(
                sub,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Revenue Chart
// ─────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  final List<dynamic> dailySales;
  const _RevenueChart({required this.dailySales});

  @override
  Widget build(BuildContext context) {
    final max = dailySales
            .map((e) => e.revenue as double)
            .reduce((a, b) => a > b ? a : b) *
        1.25;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: max,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.primary,
              getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                '₹${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i % 7 != 0 || i >= dailySales.length) {
                    return const SizedBox();
                  }
                  final d = DateTime.parse(dailySales[i].date as String);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(DateFormat('dd/MM').format(d),
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.textSecondary)),
                  );
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: dailySales.asMap().entries.map((e) {
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value.revenue as double,
                width: 6,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF9B93FF), Color(0xFF6C63FF)],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Top Product Tile
// ─────────────────────────────────────────
class _TopProductTile extends StatelessWidget {
  final int rank;
  final String name;
  final int sold;
  final double revenue;
  const _TopProductTile(
      {required this.rank,
      required this.name,
      required this.sold,
      required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFFF3E0)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: rank == 1 ? Colors.orange : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text('$sold sold',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '₹${revenue.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Recent Order Tile
// ─────────────────────────────────────────
class _RecentOrderTile extends StatelessWidget {
  final String number, status;
  final double amount;
  const _RecentOrderTile(
      {required this.number, required this.status, required this.amount});

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: info.$2.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 18, color: info.$2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: info.$2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(info.$1,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: info.$2)),
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusInfo(String s) {
    switch (s.toUpperCase()) {
      case 'DELIVERED':
        return ('Delivered', AppColors.success);
      case 'CANCELLED':
        return ('Cancelled', AppColors.error);
      case 'PROCESSING':
        return ('Processing', AppColors.primary);
      case 'SHIPPED':
        return ('Shipped', AppColors.secondary);
      default:
        return ('Pending', AppColors.warning);
    }
  }
}
