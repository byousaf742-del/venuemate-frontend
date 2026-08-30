import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/api_client.dart';
import '../../core/services/user_service.dart';
import '../../core/models/user_model.dart';

class AdminDashboardScreen extends StatefulWidget {
   final VoidCallback? onNavigateToVenues;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToBookings;

  const AdminDashboardScreen({
    super.key,
    this.onNavigateToVenues,
    this.onNavigateToUsers,
    this.onNavigateToBookings,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  UserModel? _user;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await UserService.getUser();
    if (mounted) setState(() => _user = user);
    try {
      final res = await ApiClient.get('/admin/stats');
      if (mounted) setState(() { _stats = res; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final a = amount is int ? amount : (amount as num).toInt();
    if (a >= 1000000) return 'PKR ${(a / 1000000).toStringAsFixed(1)}M';
    if (a >= 1000) return 'PKR ${(a / 1000).toStringAsFixed(0)}K';
    return 'PKR $a';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(theme)),
              SliverToBoxAdapter(child: _buildStatsGrid(theme)),
              SliverToBoxAdapter(child: _buildPlatformHealth(theme)),
              SliverToBoxAdapter(child: _buildQuickActions(theme)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded,
                          size: 12, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text('Admin Panel',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppTheme.success)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('Welcome,',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
                Text(_user?.name ?? 'Admin',
                    style: theme.textTheme.headlineMedium),
              ],
            ),
          ),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.success.withAlpha(77)),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: AppTheme.success, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    if (_isLoading) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()));
    }

    final cards = [
      {
        'title': 'Total Customers',
        'value': '${_stats['total_customers'] ?? 0}',
        'icon': Icons.people_rounded,
        'color': const Color(0xFF1565C0),
        'bg': const Color(0xFFE3F2FD),
      },
      {
        'title': 'Total Owners',
        'value': '${_stats['total_owners'] ?? 0}',
        'icon': Icons.store_rounded,
        'color': const Color(0xFFAD1457),
        'bg': const Color(0xFFFCE4EC),
      },
      {
        'title': 'Verified Venues',
        'value': '${_stats['verified_venues'] ?? 0}',
        'icon': Icons.verified_rounded,
        'color': AppTheme.success,
        'bg': AppTheme.successContainer,
      },
      {
        'title': 'Pending Venues',
        'value': '${_stats['pending_venues'] ?? 0}',
        'icon': Icons.pending_rounded,
        'color': AppTheme.warning,
        'bg': AppTheme.warningContainer,
      },
      {
        'title': 'Total Bookings',
        'value': '${_stats['total_bookings'] ?? 0}',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF6A1B9A),
        'bg': const Color(0xFFF3E5F5),
      },
      {
        'title': 'Platform Revenue',
        'value': _formatAmount(_stats['total_revenue']),
        'icon': Icons.currency_rupee_rounded,
        'color': AppTheme.success,
        'bg': AppTheme.successContainer,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final card = cards[i];
          return Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: card['bg'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(card['icon'] as IconData,
                      size: 18, color: card['color'] as Color),
                ),
                const SizedBox(height: 8),
                Text(card['value'] as String,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface)),
                Text(card['title'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceMuted)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlatformHealth(ThemeData theme) {
    if (_isLoading) return const SizedBox.shrink();
    final total = (_stats['total_venues'] ?? 0) as int;
    final verified = (_stats['verified_venues'] ?? 0) as int;
    final percent = total > 0 ? verified / total : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Health', style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Venue Verification Rate',
                  style: theme.textTheme.bodySmall),
              Text('${(percent * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppTheme.outlineVariant,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _healthChip('$verified Verified', AppTheme.success,
                  AppTheme.successContainer),
              const SizedBox(width: 8),
              _healthChip(
                  '${(_stats['pending_venues'] ?? 0)} Pending',
                  AppTheme.warning,
                  AppTheme.warningContainer),
              const SizedBox(width: 8),
              _healthChip('${(_stats['active_bids'] ?? 0)} Active Bids',
                  AppTheme.info, AppTheme.infoContainer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthChip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _actionTile(theme, Icons.pending_rounded, 'Pending Venues',
              '${_stats['pending_venues'] ?? 0} awaiting approval',
              AppTheme.warning, AppTheme.warningContainer,
              () => widget.onNavigateToVenues?.call()),
                
          const Divider(height: 1),
          _actionTile(theme, Icons.people_rounded, 'Manage Users',
              '${(_stats['total_customers'] ?? 0) + (_stats['total_owners'] ?? 0)} total users',
              AppTheme.info, AppTheme.infoContainer, 
              () => widget.onNavigateToUsers?.call()),
               
          const Divider(height: 1),
          _actionTile(theme, Icons.calendar_month_rounded, 'All Bookings',
              '${_stats['total_bookings'] ?? 0} total bookings',
              const Color(0xFF6A1B9A), const Color(0xFFF3E5F5),
              () => widget.onNavigateToBookings?.call()),
                
        ],
      ),
    );
  }

  Widget _actionTile(ThemeData theme, IconData icon, String title,
      String subtitle, Color color, Color bg, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppTheme.onSurfaceMuted)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppTheme.onSurfaceMuted, size: 20),
    );
  }
}
