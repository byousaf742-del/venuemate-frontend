import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/api_client.dart';
import '../../widgets/custom_image_widget.dart';

class AdminVenuesScreen extends StatefulWidget {
  const AdminVenuesScreen({super.key});

  @override
  State<AdminVenuesScreen> createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends State<AdminVenuesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingVenues = [];
  List<Map<String, dynamic>> _allVenues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVenues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    try {
      final pending = await ApiClient.get('/admin/venues/pending');
      final all = await ApiClient.get('/admin/venues/all');
      if (mounted) {
        setState(() {
          _pendingVenues =
              List<Map<String, dynamic>>.from(pending['venues'] ?? []);
          _allVenues =
              List<Map<String, dynamic>>.from(all['venues'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyVenue(String id, bool approve) async {
    try {
      await ApiClient.put(
          '/admin/venues/$id/verify?approve=$approve', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve
              ? 'Venue approved and is now live!'
              : 'Venue request rejected.'),
          backgroundColor:
              approve ? AppTheme.success : AppTheme.error,
        ));
        _loadVenues();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Action failed. Try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }


  Future<void> _rejectVenue(String id) async {
    print('Rejecting venue: $id');
  try {
    final res = await ApiClient.delete('/admin/venues/$id/reject');
    print('Reject response: $res');
    await ApiClient.delete('/admin/venues/$id/reject');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Venue request cancelled. Owner has been notified.'),
        backgroundColor: AppTheme.error,
      ));
      _loadVenues();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Action failed. Try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }
}


  Future<void> _suspendVenue(String id, bool isCurrentlyActive) async {
    try {
      await ApiClient.put(
          '/admin/venues/$id/suspend?suspend=$isCurrentlyActive', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isCurrentlyActive
              ? 'Venue suspended. Hidden from customers.'
              : 'Venue reactivated and is now live.'),
          backgroundColor:
              isCurrentlyActive ? AppTheme.error : AppTheme.success,
        ));
        _loadVenues();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Action failed. Try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            _buildTabBar(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingList(theme),
                  _buildAllList(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Venue Management',
                    style: theme.textTheme.headlineMedium),
                Text('Approve or reject venue listings',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
              ],
            ),
          ),
          if (_pendingVenues.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.warningContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_pendingVenues.length} pending',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AppTheme.warning,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.onSurfaceMuted,
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: 'Pending (${_pendingVenues.length})'),
          Tab(text: 'All Venues (${_allVenues.length})'),
        ],
      ),
    );
  }


  Widget _buildPendingList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendingVenues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 52, color: AppTheme.success),
            const SizedBox(height: 12),
            Text('All caught up!', style: theme.textTheme.titleMedium),
            Text('No pending venue approvals',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadVenues,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _pendingVenues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _buildPendingTile(theme, _pendingVenues[i]),
      ),
    );
  }

  Widget _buildPendingTile(
      ThemeData theme, Map<String, dynamic> venue) {
    final media = venue['media'] as List? ?? [];
    final imageUrl =
        media.isNotEmpty ? media[0]['url'] : null;
    final location = venue['location'] as Map? ?? {};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.warning.withAlpha(77), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Venue image thumbnail
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomImageWidget(
                            imageUrl: imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.location_city_rounded,
                          color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 12),
                // Venue info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(venue['name'] ?? '',
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warningContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (venue['type'] ?? '')
                                  .toString()
                                  .toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.warning),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location['address'] ?? '',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                      color: AppTheme.onSurfaceMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${venue['owner_name'] ?? 'Unknown'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Three dots menu
                GestureDetector(
                  onTap: () => _showCancelConfirmDialog(theme, venue),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppTheme.error),
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _showVenueDetail(theme, venue),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: AppTheme.primary,
                    ),
                    child: const Text('View Details',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _verifyVenue(venue['id'], true),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog(
      ThemeData theme, Map<String, dynamic> venue) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_rounded,
                  color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Cancel Verification Request'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  const TextSpan(
                      text:
                          'Are you sure you want to cancel the verification request for '),
                  TextSpan(
                    text: venue['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The owner will be notified that their venue request was not approved.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
          onPressed: () {
            print('Cancel Request tapped for: ${venue['id']}');
            Navigator.pop(context);
            _rejectVenue(venue['id']);
          },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  void _showVenueDetail(
      ThemeData theme, Map<String, dynamic> venue) {
    final media = venue['media'] as List? ?? [];
    final imageUrl =
        media.isNotEmpty ? media[0]['url'] : null;
    final location = venue['location'] as Map? ?? {};
    final pricing = venue['pricing'] as Map? ?? {};
    final capacity = venue['capacity'] as Map? ?? {};
    final isVerified = venue['is_verified'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: ctrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    child: CustomImageWidget(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLighter,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    child: const Icon(
                        Icons.location_city_rounded,
                        size: 48,
                        color: AppTheme.primary),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and type
                      Row(
                        children: [
                          Expanded(
                            child: Text(venue['name'] ?? '',
                                style: theme
                                    .textTheme.headlineSmall),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? AppTheme.successContainer
                                  : AppTheme.warningContainer,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              isVerified
                                  ? 'VERIFIED'
                                  : 'PENDING',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isVerified
                                      ? AppTheme.success
                                      : AppTheme.warning),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLighter,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          (venue['type'] ?? '')
                              .toString()
                              .toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary),
                        ),
                      ),

                      // Location
                      const SizedBox(height: 16),
                      Text('Location',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _detailRow(
                                Icons.location_on_rounded,
                                'Address',
                                location['address'] ?? ''),
                            const SizedBox(height: 6),
                            _detailRow(
                                Icons.location_city_rounded,
                                'City',
                                location['city'] ?? ''),
                            const SizedBox(height: 6),
                            _detailRow(Icons.map_rounded,
                                'Area', location['area'] ?? ''),
                          ],
                        ),
                      ),

                      // Capacity & Pricing
                      const SizedBox(height: 16),
                      Text('Capacity & Pricing',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _infoCard(
                                theme,
                                Icons.people_rounded,
                                'Guest Capacity',
                                '${capacity['min'] ?? 0} – ${capacity['max'] ?? 0}',
                                AppTheme.info,
                                AppTheme.infoContainer),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _infoCard(
                                theme,
                                Icons.currency_rupee_rounded,
                                'Price Per Day',
                                'PKR ${pricing['base_per_day'] ?? 0}',
                                AppTheme.success,
                                AppTheme.successContainer),
                          ),
                        ],
                      ),

                      // Owner info
                      const SizedBox(height: 16),
                      Text('Owner Information',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLighter,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (venue['owner_name'] ?? 'O')
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: GoogleFonts
                                      .plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.w700,
                                          color:
                                              AppTheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      venue['owner_name'] ??
                                          'Unknown',
                                      style: theme.textTheme
                                          .titleSmall),
                                  Text(
                                      venue['owner_email'] ?? '',
                                      style: theme
                                          .textTheme.bodySmall
                                          ?.copyWith(
                                              color: AppTheme
                                                  .onSurfaceMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      if (!isVerified) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await Future.delayed(const Duration(milliseconds: 300));
                                _rejectVenue(venue['id']);
                              },
                              icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppTheme.error),
                                foregroundColor: AppTheme.error,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _verifyVenue(venue['id'], true);
                              },
                              icon: const Icon(
                                  Icons.check_rounded,
                                  size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.onSurfaceMuted,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _infoCard(ThemeData theme, IconData icon, String label,
      String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: color)),
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }


  Widget _buildAllList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allVenues.isEmpty) {
      return Center(
        child: Text('No venues found',
            style: theme.textTheme.bodyMedium),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadVenues,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _allVenues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) =>
            _buildAllVenueTile(theme, _allVenues[i]),
      ),
    );
  }

  Widget _buildAllVenueTile(
      ThemeData theme, Map<String, dynamic> venue) {
    final isVerified = venue['is_verified'] == true;
    final isActive = venue['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: !isActive
            ? Border.all(color: AppTheme.error.withAlpha(77))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: !isActive
                  ? AppTheme.errorContainer
                  : isVerified
                      ? AppTheme.successContainer
                      : AppTheme.warningContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              !isActive
                  ? Icons.block_rounded
                  : isVerified
                      ? Icons.verified_rounded
                      : Icons.pending_rounded,
              color: !isActive
                  ? AppTheme.error
                  : isVerified
                      ? AppTheme.success
                      : AppTheme.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Venue info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(venue['name'] ?? '',
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Text(
                      (venue['type'] ?? '')
                          .toString()
                          .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary),
                    ),
                    Text(' • ',
                        style: TextStyle(
                            color: AppTheme.onSurfaceMuted)),
                    Text(
                      !isActive
                          ? 'Suspended'
                          : isVerified
                              ? 'Verified'
                              : 'Pending',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: !isActive
                            ? AppTheme.error
                            : isVerified
                                ? AppTheme.success
                                : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Three dots menu
          GestureDetector(
            onTap: () => _showAllVenueOptions(
                theme, venue, isVerified, isActive),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_vert_rounded,
                  size: 18, color: AppTheme.onSurfaceMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllVenueOptions(ThemeData theme,
      Map<String, dynamic> venue, bool isVerified, bool isActive) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(venue['name'] ?? '',
                          style: theme.textTheme.titleMedium),
                      Text(
                        !isActive
                            ? 'Currently suspended'
                            : isVerified
                                ? 'Active and verified'
                                : 'Pending approval',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: !isActive
                                ? AppTheme.error
                                : isVerified
                                    ? AppTheme.success
                                    : AppTheme.warning,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Approve (only for pending)
            if (!isVerified)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success),
                title: Text('Approve Venue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _verifyVenue(venue['id'], true);
                },
              ),
            // Suspend (only for active verified)
            if (isVerified && isActive)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block_rounded,
                    color: AppTheme.error),
                title: Text('Suspend Venue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Venue will be hidden from customers',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
                onTap: () {
                  Navigator.pop(context);
                  _suspendVenue(venue['id'], true);
                },
              ),
            // Reactivate (only for suspended)
            if (!isActive)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success),
                title: Text('Reactivate Venue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Venue will be visible to customers again',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
                onTap: () {
                  Navigator.pop(context);
                  _suspendVenue(venue['id'], false);
                },
              ),
          ],
        ),
      ),
    );
  }
}