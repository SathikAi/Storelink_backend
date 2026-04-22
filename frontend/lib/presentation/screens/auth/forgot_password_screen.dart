import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid phone number')));
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(
      phone: _phoneController.text.trim(),
      purpose: 'PASSWORD_RESET',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your phone')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error ?? 'Failed to send OTP')));
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(
      phone: _phoneController.text.trim(),
      otpCode: _otpController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful! Please login.')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.error ?? 'Reset failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.1), blurRadius: 150)]),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Reset Password', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                        const SizedBox(height: 8),
                        Text('Secure your account access', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15)),
                        
                        const SizedBox(height: 40),
                        _buildInput(
                          controller: _phoneController, 
                          label: 'Phone Number', 
                          icon: Icons.phone_android_rounded, 
                          type: TextInputType.phone,
                          enabled: !_otpSent,
                        ),
                        
                        if (_otpSent) ...[
                          const SizedBox(height: 14),
                          _buildInput(
                            controller: _otpController, 
                            label: '6-Digit OTP', 
                            icon: Icons.pin_rounded, 
                            type: TextInputType.number,
                          ),
                          const SizedBox(height: 14),
                          _buildInput(
                            controller: _passwordController, 
                            label: 'New Password', 
                            icon: Icons.lock_outline_rounded, 
                            obscure: _obscurePassword, 
                            isPassword: true,
                          ),
                          const SizedBox(height: 14),
                          _buildInput(
                            controller: _confirmPasswordController, 
                            label: 'Confirm New Password', 
                            icon: Icons.lock_rounded, 
                            obscure: true,
                          ),
                        ],
    
                        const SizedBox(height: 40),
                        FilledButton(
                          onPressed: _isLoading ? null : (_otpSent ? _resetPassword : _sendOtp),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Text(_otpSent ? 'Update Password' : 'Send OTP', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            child: const Text('Resend OTP', style: TextStyle(color: AppColors.accentBlue)),
                          ),
                        ],
                      ],
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

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    bool isPassword = false,
    bool enabled = true,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          enabled: enabled,
          style: TextStyle(color: enabled ? Colors.white : Colors.white24, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.white24, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accentBlue, width: 0.5)),
            suffixIcon: isPassword ? IconButton(
              icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white38, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ) : null,
          ),
          validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ),
    );
  }
}
