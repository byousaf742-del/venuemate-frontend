import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import './widgets/owner_bookings_chart_widget.dart';
import './widgets/owner_kpi_cards_widget.dart';
import './widgets/owner_pending_actions_widget.dart';
import './widgets/owner_revenue_summary_widget.dart';
import 'package:venuemate/core/services/user_service.dart';
import 'package:venuemate/core/models/user_model.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:venuemate/presentation/customer/notifications_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  const OwnerDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentNavIndex = 0;
  UserModel? _user;
  int _unreadCount = 0;

  final List<String> _navLabels = [
    'Home',
    'Bookings',
    'Bids',
    'Venues',
    'Profile',
  ];

  final List<IconData> _navIcons = [
    Icons.dashboard_rounded,
    Icons.calendar_month_rounded,
    Icons.request_quote_rounded,
    Icons.location_city_rounded,
    Icons.person_rounded,
  ];

  final List<IconData> _navIconsOutlined = [
    Icons.dashboard_outlined,
    Icons.calendar_month_outlined,
    Icons.request_quote_outlined,
    Icons.location_city_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUnreadCount();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await ApiClient.get('/notifications');
      if (mounted) setState(() => _unreadCount = res['unread_count'] ?? 0);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          onNavigate: widget.onNavigateToTab,
        ),
      ),
    );
    _loadUnreadCount();
  }

  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    try {
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      final res = await ApiClient.post('/venues/upload-image-base64', {
        'image': base64Image,
        'folder': 'profiles',
      });
      final photoUrl = res['url'];
      await ApiClient.put('/users/me', {'profile_photo': photoUrl});
      final updatedUser = _user!.copyWith(profileImageUrl: photoUrl);
      await UserService.saveUser(updatedUser, token: await UserService.getAuthToken() ?? '');
      if (mounted) {
        setState(() => _user = updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!'), backgroundColor: AppTheme.success),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: isTablet ? _buildTabletLayout(theme) : _buildPhoneLayout(theme),
      ),
    );
  }

  Widget _buildPhoneLayout(ThemeData theme) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        await _loadUser();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildOwnerHeader(theme)),
          SliverToBoxAdapter(child: OwnerKpiCardsWidget()),
          SliverToBoxAdapter(child: OwnerRevenueSummaryWidget()),
          SliverToBoxAdapter(child: OwnerBookingsChartWidget()),
          SliverToBoxAdapter(child: OwnerPendingActionsWidget()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () async {
                    await _loadUser();
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildOwnerHeader(theme)),
                      SliverToBoxAdapter(child: OwnerKpiCardsWidget()),
                      SliverToBoxAdapter(child: OwnerBookingsChartWidget()),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
              ),
              Container(width: 1, color: AppTheme.outlineVariant),
              Expanded(
                flex: 4,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: OwnerRevenueSummaryWidget()),
                    SliverToBoxAdapter(child: OwnerPendingActionsWidget()),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLighter,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withAlpha(77)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_rounded, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Owner Dashboard',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome,',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceMuted),
                ),
                Text(_user?.name ?? 'Owner', style: theme.textTheme.headlineMedium),
              ],
            ),
          ),
          // Bell icon
          Stack(
            children: [
              InkWell(
                onTap: _openNotifications,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.outlineVariant, width: 1),
                  ),
                  child: Icon(
                    _unreadCount > 0
                        ? Icons.notifications_rounded
                        : Icons.notifications_outlined,
                    size: 22,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.warning,
                      shape: _unreadCount < 10 ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: _unreadCount >= 10 ? BorderRadius.circular(8) : null,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // Profile avatar
          InkWell(
            onTap: () => _showOwnerProfileMenu(theme),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLighter,
                border: Border.all(color: AppTheme.primary, width: 2),
              ),
              child: _user?.profileImageUrl != null
                  ? ClipOval(
                      child: CustomImageWidget(
                        imageUrl: _user!.profileImageUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        (_user?.name ?? 'O').substring(0, 1).toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOwnerProfileMenu(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _user?.profileImageUrl != null
                ? ClipOval(
                    child: CustomImageWidget(
                      imageUrl: _user!.profileImageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLighter,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        (_user?.name ?? 'O').substring(0, 1).toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 10),
            Text(_user?.name ?? 'Owner', style: theme.textTheme.titleLarge),
            Text(
              _user?.email ?? '',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceMuted),
            ),
            const SizedBox(height: 20),
            const Divider(),
            _buildMenuTile(Icons.photo_camera_outlined, 'Change Photo', () {
              Navigator.pop(context);
              _uploadProfilePhoto();
            }),
            _buildMenuTile(Icons.person_outline_rounded, 'View Profile', () {
              Navigator.pop(context);
              widget.onNavigateToTab?.call(5);
            }),
            const Divider(),
            _buildMenuTile(Icons.logout_rounded, 'Sign Out', () async {
              await UserService.clearUser();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.signUpLoginScreen,
                  (route) => false,
                );
              }
            }, color: AppTheme.error),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: color ?? AppTheme.onSurface),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? AppTheme.onSurface,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
    );
  }
}
