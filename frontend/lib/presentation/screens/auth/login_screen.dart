import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'google_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      context.go('/dashboard');
    } else if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result['status']) {
      case 'logged_in':
        context.go('/dashboard');
        break;
      case 'needs_registration':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GoogleRegisterScreen(
            googleEmail: result['email'] ?? '',
            googleName: result['name'] ?? '',
            supabaseToken: result['token'] ?? '',
          ),
        ));
        break;
      case 'cancelled':
      case 'redirect':
        break;
      default:
        _showError(result['message'] ?? 'Google sign-in failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──
          Container(
            height: size.height * 0.52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFF3B3ACF), Color(0xFF2D2D8F)],
              ),
            ),
          ),
          // ── Decorative circles ──
          Positioned(
            top: -60, right: -60,
            child: _GlowCircle(size: 220, color: Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            top: 80, left: -40,
            child: _GlowCircle(size: 140, color: Colors.white.withOpacity(0.05)),
          ),
          // ── Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      const SizedBox(height: 40),
                      // Logo + Brand
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.store_rounded,
                            size: 38, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'StoreLink',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Indian MSME Business Manager',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // ── Card ──
                      Container(
                        width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.18),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back 👋',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sign in to your account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // Phone
                                _buildLabel('Phone Number'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: _inputDeco(
                                    hint: '10-digit mobile number',
                                    icon: Icons.phone_rounded,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Phone number required';
                                    if (v.length < 10) return 'Enter 10-digit number';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Password
                                _buildLabel('Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _inputDeco(
                                    hint: 'Enter your password',
                                    icon: Icons.lock_rounded,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password required';
                                    if (v.length < 8) return 'Minimum 8 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen()),
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Login button
                                _GradientButton(
                                  onPressed: _isLoading ? null : _login,
                                  isLoading: _isLoading,
                                  label: 'Sign In',
                                ),
                                const SizedBox(height: 14),
                                // Google Sign-In button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _loginWithGoogle,
                                    icon: Image.network(
                                      'https://developers.google.com/identity/images/g-logo.png',
                                      height: 20,
                                      width: 20,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.login, size: 18),
                                    ),
                                    label: const Text('Sign In with Google'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF444444),
                                      side: const BorderSide(
                                          color: Color(0xFFDDDDDD), width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16)),
                                      textStyle: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Register row
                      Container(
                        width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "New to StoreLink? ",
                                    style: TextStyle(color: Color(0xFF666680), fontSize: 14),
                                  ),
                                  GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => const RegisterScreen()),
                                            ),
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '🎉 Free for 1 month — No credit card needed',
                                  style: TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      // ── Legal footer ──
                      _LegalFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.inputFill,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      );
}

// ─────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────

// ─────────────────────────────────────────
// Legal / Privacy footer
// ─────────────────────────────────────────

class _LegalFooter extends StatelessWidget {
  void _showSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.all(24),
                child: Text(content,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Color(0xFFDDDDEE), thickness: 1),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            _FooterLink(
              label: 'Privacy Policy',
              onTap: () => _showSheet(
                context,
                'Privacy Policy',
                'StoreLink ("we", "our", "us") is committed to protecting your privacy.\n\n'
                '1. Information We Collect\nWe collect your phone number, business name, and transaction data to provide our services.\n\n'
                '2. How We Use It\nYour data is used to operate the app, process orders, and improve our services. We never sell your personal data.\n\n'
                '3. Data Security\nAll data is encrypted in transit (TLS) and at rest. We use industry-standard security practices.\n\n'
                '4. Your Rights\nYou can request deletion of your account and data at any time by contacting contactus@zeramai.com.\n\n'
                '5. Cookies\nWe use minimal cookies for session management only.\n\n'
                'Last updated: April 2026',
              ),
            ),
            const Text('·', style: TextStyle(color: Color(0xFFAAAAAA))),
            _FooterLink(
              label: 'Terms of Use',
              onTap: () => _showSheet(
                context,
                'Terms of Use',
                'By using StoreLink, you agree to the following terms:\n\n'
                '1. Eligibility\nYou must be 18 years or older and a registered business owner to use this app.\n\n'
                '2. Acceptable Use\nYou agree not to misuse the platform for fraudulent, illegal, or harmful activities.\n\n'
                '3. Payments\nAll payment transactions are processed securely. StoreLink is not liable for third-party payment failures.\n\n'
                '4. Intellectual Property\nAll content, trademarks, and logos within StoreLink are owned by StoreLink Pvt. Ltd.\n\n'
                '5. Termination\nWe reserve the right to suspend accounts that violate these terms without prior notice.\n\n'
                '6. Limitation of Liability\nStoreLink is not liable for indirect or consequential damages arising from app usage.\n\n'
                'Last updated: April 2026',
              ),
            ),
            const Text('·', style: TextStyle(color: Color(0xFFAAAAAA))),
            _FooterLink(
              label: 'Contact Us',
              onTap: () => _showSheet(
                context,
                'Contact & Support',
                '📧  Email: contactus@zeramai.com\n\n'
                '📞  Phone: 9080537845, 9384364069\n\n'
                '🌐  Website: www.zeramai.com\n\n'
                '📍  Office:\n     1st Floor, Covai Tech Park,\n'
                '     Near Viswasapuram Bus Stop,\n'
                '     Sathy Road, Saravanampatti,\n'
                '     Coimbatore – 641035, TN\n\n'
                '💬  Live Chat: Available inside the app after login.\n\n'
                'For billing or account issues, email contactus@zeramai.com.\n'
                'We typically respond within 24 business hours.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '© 2026 StoreLink Pvt. Ltd. All rights reserved.',
          style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary,
          ),
        ),
      );
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  const _GradientButton(
      {required this.onPressed,
      required this.isLoading,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? const LinearGradient(
                  colors: [Color(0xFFB0ACFF), Color(0xFF9490E8)])
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF4B44CC)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
