import 'package:venuemate/presentation/owner/owner_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'package:venuemate/core/services/api_client.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final res = await ApiClient.get('/bookings/owner');
      print('DEBUG BOOKING KEYS: ${(res['bookings'] as List).first.keys.toList()}');
      final bookings = (res['bookings'] as List).map((b) {
        return {
          'id': b['id'] ?? '',
          'user_id': b['user_id'] ?? '',
          'venue_id': b['venue_id'] ?? '',
          'customerName': b['customer_name'] ?? 'Customer',
          'customerPhone': b['customer_phone'] ?? '',
          'venue': b['venue_name'] ?? '',
          'image': b['venue_image'],
          'event': b['event_type'] ?? '',
          'date': b['event_date'] ?? '',
          'time': b['event_time'] ?? '',
          'guests': b['guest_count'] ?? 0,
          'amount': _formatAmount(b['total_amount']),
          'priceTier': b['price_tier'],
          'venuePrice': b['venue_price'] ?? 0,
          'menuSelected': b['menu_selected'], // 'standard' | 'premium' | null
          'menuPricePerHead': b['menu_price_per_head'] ?? 0,
          'menuTotal': b['menu_total'] ?? 0,
          'advance': b['advance_paid'] == 0
              ? '0'
              : _formatAmount(b['advance_paid']),
          'status': b['status'] ?? 'requested',
          'customerPhoto': b['customer_photo'] ?? '',
        };
      }).toList();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final a = amount as int;
    return a.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  List<Map<String, dynamic>> _getByStatus(String status) {
    if (status == 'all') return _bookings;
    if (status == 'pending') {
      return _bookings
          .where((b) =>
              b['status'] == 'requested' ||
              b['status'] == 'approved' ||
              b['status'] == 'payment_pending')
          .toList();
    }
    if (status == 'confirmed') {
      return _bookings
          .where((b) => b['status'] == 'confirmed')
          .toList();
    }
    return _bookings
        .where(
            (b) => b['status'] == 'completed' || b['status'] == 'cancelled')
        .toList();
  }

  void _openChat(Map<String, dynamic> booking) {
  final venueId = booking['venue_id'] ?? '';
  final customerId = booking['user_id'] ?? '';
  final roomId = venueId.isNotEmpty && customerId.isNotEmpty
      ? 'venue:$venueId:$customerId'
      : 'booking:${booking['id']}';

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OwnerChatDetailScreen(
        conversation: {
          'room_id': roomId,
          'other_user_id': customerId,
          'name': booking['customerName'] ?? 'Customer',
          'context_type': 'booking',
          'context_name': booking['venue'],
          'context_image': booking['image'],
          'online': false,
        },
      ),
    ),
  );
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
                  _buildBookingList(theme, _getByStatus('pending')),
                  _buildBookingList(theme, _getByStatus('confirmed')),
                  _buildBookingList(theme, _getByStatus('completed')),
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
                Text('Bookings', style: theme.textTheme.headlineMedium),
                Text(
                  'Manage incoming booking requests',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceMuted),
                ),
              ],
            ),
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
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Confirmed'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildBookingList(
      ThemeData theme, List<Map<String, dynamic>> bookings) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 52, color: AppTheme.outlineVariant),
            const SizedBox(height: 12),
            Text('No bookings here',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _buildBookingCard(theme, bookings[i]),
    );
  }

  Widget _buildBookingCard(ThemeData theme, Map<String, dynamic> booking) {
    final isPending = booking['status'] == 'requested';
    final isConfirmed = booking['status'] == 'confirmed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
  radius: 22,
  backgroundColor: AppTheme.primaryLighter,
  backgroundImage: () {
    print('DEBUG PHOTO URL: ${booking['customerPhoto']}');
    return (booking['customerPhoto'] != null &&
        booking['customerPhoto'].toString().isNotEmpty)
        ? NetworkImage(booking['customerPhoto'])
        : null;
  }(),
  child: (booking['customerPhoto'] == null ||
      booking['customerPhoto'].toString().isEmpty)
      ? const Icon(Icons.person_rounded, color: AppTheme.primary, size: 24)
      : null,
),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking['customerName'],
                              style: theme.textTheme.titleSmall),
                          Text(booking['customerPhone'],
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.onSurfaceMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.call_rounded,
                          color: AppTheme.primary, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryLighter,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // CHAT ICON BUTTON — wired
                    IconButton(
                      onPressed: () => _openChat(booking),
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          color: AppTheme.info, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.infoContainer,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _infoRow(theme, 'Venue', booking['venue']),
                      const SizedBox(height: 6),
                      _infoRow(theme, 'Event', booking['event']),
                      const SizedBox(height: 6),
                      _infoRow(theme, 'Date', booking['date']),
                      const SizedBox(height: 6),
                      if ((booking['time'] ?? '').isNotEmpty)
                        _infoRow(theme, 'Time', booking['time']),
                      const SizedBox(height: 6),
                      _infoRow(theme, 'Guests', '${booking['guests']}'),
                      const Divider(height: 16),
                      _infoRow(
                        theme,
                        booking['priceTier'] != null
                            ? 'Venue Price (${booking['priceTier']})'
                            : 'Venue Price',
                        'PKR ${_formatAmount(booking['venuePrice'])}',
                      ),
                      if (booking['menuSelected'] != null) ...[
                        const SizedBox(height: 6),
                        _infoRow(
                          theme,
                          '${booking['menuSelected'] == 'premium' ? 'Premium' : 'Standard'} Menu '
                          '(${_formatAmount(booking['menuPricePerHead'])}/head × ${booking['guests']})',
                          'PKR ${_formatAmount(booking['menuTotal'])}',
                        ),
                      ],
                      const Divider(height: 16),
                      _infoRow(theme, 'Total Amount',
                          'PKR ${booking['amount']}',
                          valueColor: AppTheme.primary),
                      const SizedBox(height: 4),
                      _infoRow(
                        theme,
                        'Advance Paid',
                        booking['advance'] == '0'
                            ? 'Not Paid'
                            : 'PKR ${booking['advance']}',
                        valueColor: booking['advance'] == '0'
                            ? AppTheme.error
                            : AppTheme.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PENDING — Accept / Reject buttons
          if (isPending)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectBooking(booking),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text('Reject',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: AppTheme.error)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptBooking(booking),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ),

          // CONFIRMED — Mark as Completed + Message Customer
          if (isConfirmed) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeBooking(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Mark as Completed'),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(booking),
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 15),
                  label: const Text('Message Customer'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    foregroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceMuted)),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.onSurface)),
      ],
    );
  }

  Future<void> _acceptBooking(Map<String, dynamic> booking) async {
    try {
      await ApiClient.put('/bookings/${booking['id']}/action',
          {'action': 'approve'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Booking from ${booking['customerName']} accepted!'),
          backgroundColor: AppTheme.success,
        ));
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to accept booking. Try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _rejectBooking(Map<String, dynamic> booking) async {
    try {
      await ApiClient.put('/bookings/${booking['id']}/action',
          {'action': 'cancel'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Booking from ${booking['customerName']} rejected.'),
          backgroundColor: AppTheme.error,
        ));
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to reject booking. Try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _completeBooking(Map<String, dynamic> booking) async {
    try {
      await ApiClient.put('/bookings/${booking['id']}/action',
          {'action': 'complete'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Booking marked as completed!'),
          backgroundColor: AppTheme.success,
        ));
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to complete booking. Try again.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}