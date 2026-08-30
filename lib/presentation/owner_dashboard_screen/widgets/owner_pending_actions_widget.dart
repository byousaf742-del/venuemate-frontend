import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/api_client.dart';

class OwnerPendingActionsWidget extends StatefulWidget {
  const OwnerPendingActionsWidget({super.key});

  @override
  State<OwnerPendingActionsWidget> createState() =>
      _OwnerPendingActionsWidgetState();
}

class _OwnerPendingActionsWidgetState
    extends State<OwnerPendingActionsWidget> {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _bids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final res = await ApiClient.get('/dashboard/owner/pending');
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(
            res['pending_bookings'] ?? []);
        _bids = List<Map<String, dynamic>>.from(
            res['pending_bids'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptBooking(String id) async {
    try {
      await ApiClient.put('/bookings/$id/action', {'action': 'approve'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking accepted! Client will be notified.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadPending();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(String id) async {
    try {
      await ApiClient.put('/bookings/$id/action', {'action': 'cancel'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking declined.'),
            backgroundColor: AppTheme.error,
          ),
        );
        _loadPending();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decline. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _bookings.length + _bids.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pending Actions',
                      style: theme.textTheme.titleMedium),
                  Text(
                    '$total requests need your response',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: total > 0
                          ? AppTheme.warning
                          : AppTheme.onSurfaceMuted,
                      fontWeight: total > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.warningContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total pending',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (total == 0)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 48, color: AppTheme.success),
                  const SizedBox(height: 8),
                  Text('All caught up!',
                      style: theme.textTheme.titleSmall),
                  Text(
                    'No pending requests at the moment',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Pending bookings
          ..._bookings.map((b) => _buildBookingCard(theme, b)),
          // Pending bids
          ..._bids.map((b) => _buildBidCard(theme, b)),
        ],
      ],
    );
  }

  Widget _buildBookingCard(ThemeData theme, Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.warning.withAlpha(77), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
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
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLighter,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['customer_name'] ?? 'Customer',
                              style: theme.textTheme.titleSmall),
                          Text(b['event_type'] ?? '',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLighter,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Booking Req',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary)),
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
                  child: Row(
                    children: [
                      _chip(Icons.calendar_today_outlined,
                          b['event_date'] ?? ''),
                      const SizedBox(width: 12),
                      _chip(Icons.people_outline_rounded,
                          '${b['guest_count'] ?? 0} guests'),
                      const SizedBox(width: 12),
                      _chip(Icons.currency_rupee_rounded,
                          'PKR ${_fmt(b['total_amount'])}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppTheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectBooking(b['id']),
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(
                          color: AppTheme.error, width: 1),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _acceptBooking(b['id']),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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

  Widget _buildBidCard(ThemeData theme, Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.info.withAlpha(77), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.infoContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gavel_rounded,
                      color: AppTheme.info, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b['customer_name'] ?? 'Customer',
                          style: theme.textTheme.titleSmall),
                      Text(b['event_type'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.info,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.infoContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Bid Request',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.info)),
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
              child: Row(
                children: [
                  _chip(Icons.calendar_today_outlined,
                      b['event_date'] ?? ''),
                  const SizedBox(width: 12),
                  _chip(Icons.people_outline_rounded,
                      '${b['guest_count'] ?? 0} guests'),
                  const SizedBox(width: 12),
                  _chip(Icons.currency_rupee_rounded,
                      'Budget: ${_fmt(b['budget'])}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Go to Requests tab to send a quotation',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppTheme.primary),
        const SizedBox(width: 3),
        Text(text,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface)),
      ],
    );
  }

  String _fmt(dynamic amount) {
    if (amount == null) return '0';
    final a = amount is int ? amount : (amount as num).toInt();
    if (a >= 100000) return '${(a / 1000).toStringAsFixed(0)}K';
    return a.toString();
  }
}