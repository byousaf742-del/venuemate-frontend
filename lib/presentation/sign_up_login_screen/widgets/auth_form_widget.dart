import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/user_service.dart';
import '../../../theme/app_theme.dart';
import '../sign_up_login_screen.dart';
import 'package:dio/dio.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:venuemate/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthFormWidget extends StatefulWidget {
  final AuthMode authMode;
  final UserRole selectedRole;
  final Function(UserRole) onSuccess;

  const AuthFormWidget({
    super.key,
    required this.authMode,
    required this.selectedRole,
    required this.onSuccess,
  });

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      Map<String, dynamic> res;
      if (widget.authMode == AuthMode.login) {
        res = await ApiClient.post('/auth/login', {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        });
      } else {
        res = await ApiClient.post('/auth/register', {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'role': widget.selectedRole == UserRole.owner ? 'owner' : 'customer',
        });
      }

      final user = UserModel.fromJson(res['user']);
      await UserService.saveUser(user, token: res['token']);
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');
      if (fcmToken != null) {
        await UserService.saveFcmToken(fcmToken);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          // Navigate based on actual role from database
          if (user.userRole == 'admin') {
            Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.adminMainScreen, (route) => false);
          } else if (user.userRole == 'owner') {
            Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.ownerMainScreen, (route) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.customerMainScreen, (route) => false);
          }
        }
      }
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data?['detail'] ?? 'Request failed. Try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  void _handleForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ForgotPasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withAlpha(77), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppTheme.error,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          if (widget.authMode == AuthMode.signup) ...[
            _buildField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Muhammad Hassan / Ayesha Malik',
              icon: Icons.person_outline_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Full name is required';
                if (v.trim().length < 3) return 'Name must be at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '03XX-XXXXXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => null,
            ),
            const SizedBox(height: 14),
          ],
          _buildField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password',
            obscure: _obscurePassword,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          if (widget.authMode == AuthMode.signup) ...[
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) {
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
          if (widget.authMode == AuthMode.login) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _handleForgotPassword,
                child: Text('Forgot Password?',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(
                      widget.authMode == AuthMode.login
                          ? 'Sign In'
                          : widget.selectedRole == UserRole.owner
                              ? 'Create Owner Account'
                              : 'Create Account',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primary),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20,
            color: AppTheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20, color: AppTheme.onSurfaceMuted),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}


class _ForgotPasswordSheet extends StatefulWidget {
  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  int _step = 0;
  String _email = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiClient.post('/auth/forgot-password', {
        'email': _emailController.text.trim(),
      });
      setState(() {
        _email = _emailController.text.trim();
        _step = 1;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data?['detail'] ?? 'Email not found. Try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send OTP. Try again.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiClient.post('/auth/verify-otp', {
        'email': _email,
        'otp': _otpController.text.trim(),
      });
      setState(() { _step = 2; _isLoading = false; });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data?['detail'] ?? 'Invalid or expired OTP.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed. Try again.';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await ApiClient.post('/auth/reset-password', {
        'email': _email,
        'otp': _otpController.text.trim(),
        'new_password': _newPasswordController.text,
      });
      setState(() { _step = 3; _isLoading = false; });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.response?.data?['detail'] ?? 'Reset failed. Try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_errorMessage!,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppTheme.error)),
            ),
          if (_step == 0) _buildEmailStep(theme),
          if (_step == 1) _buildOtpStep(theme),
          if (_step == 2) _buildNewPasswordStep(theme),
          if (_step == 3) _buildSuccessStep(theme),
        ],
      ),
    );
  }

  Widget _buildEmailStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter, shape: BoxShape.circle),
              child: const Icon(Icons.lock_reset_rounded,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset Password', style: theme.textTheme.titleLarge),
                Text('Enter your registered email',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Form(
          key: _emailFormKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined,
                  size: 20, color: AppTheme.primary),
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.outlineVariant, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: FilledButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text('Send OTP Code',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter, shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_read_rounded,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check Your Email', style: theme.textTheme.titleLarge),
                  Text('OTP sent to $_email',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceMuted),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Form(
          key: _otpFormKey,
          child: TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 24, fontWeight: FontWeight.w700,
                letterSpacing: 12, color: AppTheme.primary),
            validator: (v) {
              if (v == null || v.trim().length != 6) return 'Enter 6 digit OTP';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Enter OTP Code',
              counterText: '',
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.outlineVariant, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.primary, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _sendOtp,
            child: Text('Resend OTP',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: AppTheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 50,
          child: FilledButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text('Verify OTP',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter, shape: BoxShape.circle),
              child: const Icon(Icons.lock_open_rounded,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Password', style: theme.textTheme.titleLarge),
                Text('Create a strong password',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Form(
          key: _passwordFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscurePassword,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'At least 6 characters';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      size: 20, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20, color: AppTheme.onSurfaceMuted),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.outlineVariant, width: 1)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      size: 20, color: AppTheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20, color: AppTheme.onSurfaceMuted),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.outlineVariant, width: 1)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primary, width: 1.5)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: FilledButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text('Reset Password',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppTheme.successContainer, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Password Reset!', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Your password has been reset successfully. You can now sign in with your new password.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.onSurfaceMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Back to Sign In',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}