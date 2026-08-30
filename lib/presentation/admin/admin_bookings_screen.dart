import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/services/api_client.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/admin/bookings');
      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(res['bookings'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filtered(String status) {
    var list = status == 'all'
        ? _bookings
        : _bookings.where((b) => b['status'] == status).toList();
    if (_searchQuery.isNotEmpty) {
      list = list.where((b) =>
          (b['customer_name'] ?? '').toString().toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (b['venue_name'] ?? '').toString().toLowerCase()
              .contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final a = amount is int ? amount : (amount as num).toInt();
    return a.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return AppTheme.success;
      case 'requested': return AppTheme.warning;
      case 'completed': return AppTheme.info;
      case 'cancelled': return AppTheme.error;
      default: return AppTheme.onSurfaceMuted;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'confirmed': return AppTheme.successContainer;
      case 'requested': return AppTheme.warningContainer;
      case 'completed': return AppTheme.infoContainer;
      case 'cancelled': return AppTheme.errorContainer;
      default: return AppTheme.surfaceVariant;
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
            _buildSearchBar(theme),
            _buildTabBar(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(theme, 'all'),
                  _buildList(theme, 'requested'),
                  _buildList(theme, 'confirmed'),
                  _buildList(theme, 'completed'),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bookings Overview', style: theme.textTheme.headlineMedium),
          Text('Platform-wide booking management',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceMuted)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          hintText: 'Search by customer or venue name...',
          prefixIcon: Icon(Icons.search_rounded,
              color: AppTheme.onSurfaceMuted, size: 20),
        ),
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
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.onSurfaceMuted,
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Confirmed'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme, String status) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final list = _filtered(status);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 48, color: AppTheme.outlineVariant),
            const SizedBox(height: 12),
            Text('No bookings found',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildBookingCard(theme, list[i]),
      ),
    );
  }

  Widget _buildBookingCard(ThemeData theme, Map<String, dynamic> booking) {
    final status = booking['status'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking['customer_name'] ?? 'Customer',
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    Text(booking['event_type'] ?? '',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: _statusColor(status)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _row(theme, 'Venue', booking['venue_name'] ?? ''),
                const SizedBox(height: 4),
                _row(theme, 'Date', booking['event_date'] ?? ''),
                const SizedBox(height: 4),
                _row(theme, 'Amount',
                    'PKR ${_formatAmount(booking['total_amount'])}',
                    valueColor: AppTheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceMuted)),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.onSurface)),
      ],
    );
  }
}
