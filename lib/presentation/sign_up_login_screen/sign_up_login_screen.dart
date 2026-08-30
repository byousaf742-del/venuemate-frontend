import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/auth_form_widget.dart';
import './widgets/auth_role_selector_widget.dart';
import 'package:venuemate/core/services/user_service.dart';

enum AuthMode { login, signup }

enum UserRole { customer, owner }

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with TickerProviderStateMixin {
  AuthMode _authMode = AuthMode.login;
  UserRole _selectedRole = UserRole.customer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
    _checkIfLoggedIn();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLoggedIn() async {
  final token = await UserService.getAuthToken();
  final user = await UserService.getUser();
  if (token != null && user != null && mounted) {
    if (user.userRole == 'admin') {
      Navigator.pushReplacementNamed(context, AppRoutes.adminMainScreen);
    } else if (user.userRole == 'owner') {
      Navigator.pushReplacementNamed(context, AppRoutes.ownerMainScreen);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.customerMainScreen);
    }
  }
}

  void _switchMode(AuthMode mode) {
    if (_authMode == mode) return;
    _slideController.reset();
    setState(() => _authMode = mode);
    _slideController.forward();
  }

  void _onRoleSelected(UserRole role) {
    setState(() => _selectedRole = role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: isTablet
                ? _buildTabletLayout(theme)
                : _buildPhoneLayout(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        Container(
          height: size.height * 0.42,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFAD1457), Color(0xFFE91E8C), Color(0xFFF06292)],
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(15),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: -40,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildLogo(theme),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildFormCard(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48),
            _buildLogo(theme),
            const SizedBox(height: 32),
            SizedBox(
              width: 480,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildFormCard(theme),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_city_rounded,
            size: 38,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'VenueMate',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find Book & Enjoy!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.white.withAlpha(217),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeToggle(theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_authMode == AuthMode.signup) ...[
                    AuthRoleSelectorWidget(
                      selectedRole: _selectedRole,
                      onRoleSelected: _onRoleSelected,
                    ),
                    const SizedBox(height: 20),
                  ],
                const SizedBox(height: 20),
                AuthFormWidget(
                  authMode: _authMode,
                  selectedRole: _selectedRole,
                  onSuccess: (role) {
                    if (role == UserRole.owner) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.ownerMainScreen,
                        (route) => false,
                      );
                    } else {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.customerMainScreen,
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 16),
                _buildBottomLinks(theme),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(AuthMode.login),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _authMode == AuthMode.login
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _authMode == AuthMode.login
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: _authMode == AuthMode.login
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _authMode == AuthMode.login
                          ? AppTheme.primary
                          : AppTheme.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(AuthMode.signup),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _authMode == AuthMode.signup
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _authMode == AuthMode.signup
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Create Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: _authMode == AuthMode.signup
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _authMode == AuthMode.signup
                          ? AppTheme.primary
                          : AppTheme.onSurfaceMuted,
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

  Widget _buildBottomLinks(ThemeData theme) {
    if (_authMode == AuthMode.login) {
      return Center(
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.onSurfaceMuted,
            ),
            children: [
              const TextSpan(text: 'Don\'t have an account? '),
              TextSpan(
                text: 'Sign Up',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _switchMode(AuthMode.signup),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.onSurfaceMuted,
            ),
            children: [
              const TextSpan(text: 'By creating an account, you agree to our '),
              TextSpan(
                text: 'Terms of Service',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()..onTap = () {},
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()..onTap = () {},
              ),
            ],
          ),
        ),
      );
    }
  }
}
