import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/billing_api_datasource.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';

class UpgradePlanScreen extends StatefulWidget {
  const UpgradePlanScreen({super.key});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  bool _isYearly = false;
  late AnimationController _toggleController;
  String? _referralCode;
  int _totalReferrals = 0;
  int _rewardedReferrals = 0;
  bool _affiliateLoaded = false;

  @override
  void initState() {
    super.initState();
    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadAffiliateCode();
  }

  Future<void> _loadAffiliateCode() async {
    try {
      final sl = ServiceLocator();
      final token = await sl.tokenService.getAccessToken();
      final res = await sl.dio.get(
        '${ApiConstants.baseUrl}/affiliate/my-code',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        setState(() {
          _referralCode = res.data['referral_code'] as String?;
          _totalReferrals = (res.data['total_referrals'] as int?) ?? 0;
          _rewardedReferrals = (res.data['rewarded_referrals'] as int?) ?? 0;
          _affiliateLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Affiliate load error: $e');
      if (mounted) setState(() => _affiliateLoaded = true);
    }
  }

  @override
  void dispose() {
    _toggleController.dispose();
    super.dispose();
  }

  void _selectPlan(bool yearly) {
    setState(() => _isYearly = yearly);
    if (yearly) {
      _toggleController.forward();
    } else {
      _toggleController.reverse();
    }
  }

  Future<void> _startPayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final serviceLocator = ServiceLocator();
      final datasource = BillingApiDatasource(
        serviceLocator.dio,
        serviceLocator.tokenService,
      );
      final planType = _isYearly ? 'yearly' : 'monthly';
      final paymentUrl =
          await datasource.createUpgradePaymentLink(planType: planType);
      final uri = Uri.parse(paymentUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1A1A2E),
              content: Text(
                'Payment initiated! Your ${_isYearly ? "yearly" : "monthly"} plan will activate once payment is confirmed.',
                style: const TextStyle(color: Colors.white),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
          Provider.of<BusinessProvider>(context, listen: false).loadProfile();
          Provider.of<AuthProvider>(context, listen: false).refreshBusiness();
        }
      } else {
        throw Exception('Could not open payment link: $paymentUrl');
      }
    } catch (e) {
      debugPrint('Upgrade plan error: $e');
      String msg;
      if (e is DioException) {
        msg = e.response?.data?['detail'] ?? e.message ?? 'Network error';
      } else {
        msg = e.toString();
      }
      setState(() {
        _error = msg;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = '₹699';
    final yearlyPrice = '₹6,999';
    final effectiveMonthlyYearly = '₹583';
    final savings = '₹1,389';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upgrade to PRO',
          style:
              TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero icon ────────────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFBB86FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    size: 52, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unlock Full Potential',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Everything your business needs to grow.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 32),

            // ── Monthly / Yearly toggle ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(child: _PlanTab(
                    label: 'Monthly',
                    selected: !_isYearly,
                    onTap: () => _selectPlan(false),
                    badge: null,
                  )),
                  Expanded(child: _PlanTab(
                    label: 'Yearly',
                    selected: _isYearly,
                    onTap: () => _selectPlan(true),
                    badge: 'SAVE 17%',
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Price card ───────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.07),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _isYearly
                  ? _PriceCard(
                      key: const ValueKey('yearly'),
                      mainPrice: yearlyPrice,
                      period: '/year',
                      sub: '$effectiveMonthlyYearly/month billed yearly',
                      savingsTag: 'Save $savings vs monthly',
                      gradient: const [Color(0xFF6C63FF), Color(0xFF3B3ACF)],
                      glowColor: const Color(0xFF6C63FF),
                      isPopular: true,
                    )
                  : _PriceCard(
                      key: const ValueKey('monthly'),
                      mainPrice: monthlyPrice,
                      period: '/month',
                      sub: 'Billed monthly, cancel anytime',
                      savingsTag: null,
                      gradient: const [Color(0xFF434343), Color(0xFF1A1A2E)],
                      glowColor: Colors.transparent,
                      isPopular: false,
                    ),
            ),
            const SizedBox(height: 28),

            // ── Feature list ─────────────────────────────────────────────
            _SectionTitle('WHAT YOU GET'),
            const SizedBox(height: 12),
            _featureItem(Icons.all_inclusive_rounded, 'Unlimited Products',
                'No cap on inventory — add as many products as you need.',
                const Color(0xFF6C63FF)),
            _featureItem(Icons.insights_rounded, 'Advanced Analytics',
                'Sales trends, revenue charts & customer behavior data.',
                const Color(0xFF03DAC6)),
            _featureItem(Icons.picture_as_pdf_rounded, 'PDF & CSV Export',
                'Professional invoices and inventory reports in one tap.',
                const Color(0xFFBB86FC)),
            _featureItem(Icons.storefront_rounded, 'Branded Storefront',
                'A shareable store link for your customers — no login needed.',
                const Color(0xFFFFB300)),
            _featureItem(Icons.support_agent_rounded, 'Priority Support',
                'Get faster help when you need it most.',
                const Color(0xFF4CAF50)),
            const SizedBox(height: 28),

            // ── Error banner ─────────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── CTA button ───────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: _isLoading
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFBB86FC)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isLoading ? null : _startPayment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                _isYearly
                                    ? 'GET YEARLY FOR ₹6,999'
                                    : 'GET MONTHLY FOR ₹699',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Affiliate Programme ──────────────────────────────────────
            const SizedBox(height: 12),
            _SectionTitle('AFFILIATE PROGRAMME'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2340), Color(0xFF0D1526)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.people_alt_rounded,
                            color: Color(0xFFFFB300), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Refer & Earn',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text('Get 30 free days per paid referral',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _AffStat('Total\nRefers', '$_totalReferrals', const Color(0xFF6C63FF)),
                      const SizedBox(width: 12),
                      _AffStat('Rewarded', '$_rewardedReferrals', const Color(0xFF4CAF50)),
                      const SizedBox(width: 12),
                      _AffStat('Days\nEarned', '${_rewardedReferrals * 30}', const Color(0xFFFFB300)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Referral code box
                  if (!_affiliateLoaded)
                    const Center(
                      child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
                    )
                  else if (_referralCode != null) ...[
                    const Text('Your Referral Code',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(_referralCode!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: 3)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _referralCode!));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Referral code copied!'),
                                backgroundColor: Color(0xFF4CAF50),
                                duration: Duration(seconds: 2),
                              ));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: Color(0xFF6C63FF), size: 20),
                            onPressed: () async {
                              final msg = 'Join StoreLink — India\'s best business manager app!\nUse my referral code *$_referralCode* to get 1 month FREE.\nDownload: https://storelink.in';
                              final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(msg)}');
                              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                await launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(msg)}'));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Trust badges ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TrustBadge(Icons.lock_rounded, 'Secure'),
                const SizedBox(width: 20),
                _TrustBadge(Icons.cancel_rounded, 'Cancel Anytime'),
                const SizedBox(width: 20),
                _TrustBadge(Icons.receipt_long_rounded, 'GST Invoice'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Secured by Dodo Payments · Instant activation',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(
      IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.3),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ── Plan tab (toggle button) ─────────────────────────────────────────────────
class _PlanTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const _PlanTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9B93FF)],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge != null)
              Positioned(
                top: -2,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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

// ── Price card ───────────────────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final String mainPrice;
  final String period;
  final String sub;
  final String? savingsTag;
  final List<Color> gradient;
  final Color glowColor;
  final bool isPopular;

  const _PriceCard({
    super.key,
    required this.mainPrice,
    required this.period,
    required this.sub,
    this.savingsTag,
    required this.gradient,
    required this.glowColor,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: glowColor != Colors.transparent
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : [],
        border: Border.all(
          color: Colors.white.withOpacity(isPopular ? 0.15 : 0.06),
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '⭐ MOST POPULAR',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mainPrice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  period,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (savingsTag != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                savingsTag!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Affiliate stat card ───────────────────────────────────────────────────────
class _AffStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AffStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Trust badge ───────────────────────────────────────────────────────────────
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white24, size: 16),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
