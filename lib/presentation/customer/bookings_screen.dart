import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import 'package:dio/dio.dart';
import 'booking_token_screen.dart';
import 'package:venuemate/core/services/api_client.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final res = await ApiClient.get('/bookings/my');
    final bookings = (res['bookings'] as List).map((b) {
      return {
        'id': b['id'] ?? '',
        'venue': b['venue_name'] ?? '',
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
        'status': b['status'] ?? 'pending',
        'token': b['confirmation_token'] ?? 'Pending',
        'image': b['venue_image'] ?? 'https://images.unsplash.com/photo-1674021864708-ed33fcf3c18b',
        'semanticLabel': b['venue_name'] ?? '',
        'paid': (b['advance_paid'] ?? 0) > 0,
        'venue_id': b['venue_id'] ?? '',
        'has_review': b['has_review'] ?? false,
      };
    }).toList();
    setState(() { _bookings = bookings; _isLoading = false; });
  } on DioException catch (_) {
    setState(() => _isLoading = false);
  } catch (e) {
    setState(() => _isLoading = false);
  }
}

String _formatAmount(dynamic amount) {
  if (amount == null) return '0';
  final a = amount as int;
  final formatted = a.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return formatted;
}
    List<Map<String, dynamic>> _bookings = [];
    bool _isLoading = false;

  List<Map<String, dynamic>> _getByStatus(String status) {
  if (status == 'all') return _bookings;
  if (status == 'active') {
    return _bookings.where((b) =>
      b['status'] == 'confirmed' ||
      b['status'] == 'requested' ||
      b['status'] == 'payment_pending' ||
      b['status'] == 'approved'
    ).toList();
  }
  return _bookings.where((b) =>
    b['status'] == 'completed' || b['status'] == 'cancelled'
  ).toList();
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
                _buildBookingList(theme, _getByStatus('all')),
                _buildBookingList(theme, _getByStatus('active')),
                _buildBookingList(theme, _getByStatus('history')),
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
                Text('My Bookings', style: theme.textTheme.headlineMedium),
                Text(
                  'Track all your venue bookings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                  ),
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Active'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildBookingList(ThemeData theme, List<Map<String, dynamic>> bookings)
   { 
    if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
    }
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 52,
              color: AppTheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No bookings here',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your bookings will appear here',
              style: theme.textTheme.bodySmall,
            ),
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
    final statusColors = {
      'confirmed': AppTheme.success,
      'pending': AppTheme.warning,
      'completed': AppTheme.info,
      'cancelled': AppTheme.error,
    };
    final statusBg = {
      'confirmed': AppTheme.successContainer,
      'pending': AppTheme.warningContainer,
      'completed': AppTheme.infoContainer,
      'cancelled': AppTheme.errorContainer,
    };
    final color = statusColors[booking['status']] ?? AppTheme.onSurfaceMuted;
    final bg = statusBg[booking['status']] ?? AppTheme.surfaceVariant;

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
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: CustomImageWidget(
                  imageUrl: booking['image'],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  semanticLabel: booking['semanticLabel'],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking['venue'],
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              booking['status'].toString().toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['event'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking['date'],
                            style: theme.textTheme.bodySmall,
                          ),
                          if ((booking['time'] ?? '').isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppTheme.onSurfaceMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking['time'],
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 12,
                            color: AppTheme.onSurfaceMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${booking['guests']} guests',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (booking['priceTier'] != null || booking['menuSelected'] != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    booking['priceTier'] != null
                                        ? 'Venue Price (${booking['priceTier']})'
                                        : 'Venue Price',
                                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceMuted),
                                  ),
                                  Text(
                                    'PKR ${_formatAmount(booking['venuePrice'])}',
                                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceMuted,fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (booking['menuSelected'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${booking['menuSelected'] == 'premium' ? 'Premium' : 'Standard'} Menu '
                                        '(${_formatAmount(booking['menuPricePerHead'])}/head × ${booking['guests']})',
                                        style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'PKR ${_formatAmount(booking['menuTotal'])}',
                                      style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.onSurfaceMuted,fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 13,
                    color: AppTheme.onSurfaceMuted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      booking['token'],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                Text(
                  'PKR ${booking['amount']}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                if (!booking['paid'] && 
                    (booking['status'] == 'approved' || 
                    booking['status'] == 'payment_pending'))
                  GestureDetector(
                    onTap: () => _showPaymentSheet(theme, booking),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Pay Now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (booking['paid'])
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 13, color: AppTheme.success),
                      const SizedBox(width: 3),
                      Text('Paid',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                const SizedBox(width: 8),
                if (booking['status'] == 'completed' && !booking['has_review'])
                  GestureDetector(
                    onTap: () => _showReviewSheet(theme, booking),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLighter,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary),
                      ),
                      child: Text(
                        'Review',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (booking['status'] == 'completed' && booking['has_review'])
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: AppTheme.gold),
                      const SizedBox(width: 3),
                      Text('Reviewed',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.onSurfaceMuted,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewSheet(ThemeData theme, Map<String, dynamic> booking) {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Write a Review', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  booking['venue'],
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceMuted),
                ),
                const SizedBox(height: 20),
                // Star rating
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedRating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i < selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 40,
                            color: i < selectedRating
                                ? AppTheme.gold
                                : AppTheme.outlineVariant,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][selectedRating],
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience (optional)...',
                    labelText: 'Comment',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setSheetState(() => isSubmitting = true);
                            try {
                              await ApiClient.post(
                                '/venues/${booking['venue_id']}/review',
                                {
                                  'booking_id': booking['id'],
                                  'rating': selectedRating,
                                  'comment': commentCtrl.text.trim(),
                                },
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Review submitted! Thank you.'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                                _loadBookings();
                              }
                            } catch (e) {
                              setSheetState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to submit review.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.star_rounded, size: 18),
                    label:
                        Text(isSubmitting ? 'Submitting...' : 'Submit Review'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet(ThemeData theme, Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Advance Payment', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Pay 30% advance to confirm your booking',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _payRow(theme, 'Venue', booking['venue']),
                  const SizedBox(height: 8),
                  _payRow(theme, 'Event Date', booking['date']),
                  if ((booking['time'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _payRow(theme, 'Event Time', booking['time']),
                  ],
                  const SizedBox(height: 8),
                  _payRow(
                    theme,
                    booking['priceTier'] != null
                        ? 'Venue Price (${booking['priceTier']})'
                        : 'Venue Price',
                    'PKR ${_formatAmount(booking['venuePrice'])}',
                  ),
                  if (booking['menuSelected'] != null) ...[
                    const SizedBox(height: 8),
                    _payRow(
                      theme,
                      '${booking['menuSelected'] == 'premium' ? 'Premium' : 'Standard'} Menu',
                      'PKR ${_formatAmount(booking['menuTotal'])}',
                    ),
                  ],
                  const Divider(height: 20),
                  _payRow(theme, 'Total Amount', 'PKR ${booking['amount']}'),
                  const Divider(height: 20),
                  _payRow(
                    theme,
                    'Advance (30%)',
                    'PKR ${(int.parse(booking['amount'].toString().replaceAll(',', '')) * 0.3).toStringAsFixed(0)}',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final totalStr = booking['amount'].toString().replaceAll(',', '');
                  final total = int.tryParse(totalStr) ?? 0;
                  final advance = (total * 0.3).toInt();
                  try {
                    final res = await ApiClient.post('/bookings/${booking['id']}/pay', {
                      'booking_id': booking['id'],
                     'amount': advance,
                      'gateway': 'jazzcash',
                      'gateway_ref': 'DEMO-${DateTime.now().millisecondsSinceEpoch}',
                          });

                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingTokenScreen(
                              bookingId:         booking['id'],
                              confirmationToken: res['confirmation_token'],
                              venueName:         booking['venue'],
                              eventDate:         booking['date'],
                            ),
                          ),
                        );
                        _loadBookings();
                      }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment failed. Try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: const Text('Pay via JazzCash / EasyPaisa'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _payRow(
    ThemeData theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? AppTheme.primary : AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}