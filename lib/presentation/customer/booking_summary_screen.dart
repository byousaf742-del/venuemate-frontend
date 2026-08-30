import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'price_tier_selector.dart';
import 'add_menu_selector.dart';

/// Booking summary / confirmation screen.
///
/// Navigate to this from [_BookingScreen] instead of calling the API directly.
/// Pass all collected form values; this screen shows a full read-only summary
/// and fires the actual POST /bookings on "Confirm Booking".
class BookingSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> venue;
  final DateTime selectedDay;
  final String eventTime;
  final String eventType;
  final int guestCount;
  final String? notes;
  final bool menuEnabled;
  final MenuChoice? selectedMenu;
  final VoidCallback onBooked;

  const BookingSummaryScreen({
    super.key,
    required this.venue,
    required this.selectedDay,
    required this.eventTime,
    required this.eventType,
    required this.guestCount,
    this.notes,
    required this.menuEnabled,
    this.selectedMenu,
    required this.onBooked,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _isSubmitting = false;

  // ── Derived pricing ──────────────────────────────────────────────────────
  List<PriceTier> get _tiers => generatePriceTiers(
        basePrice: (widget.venue['base_price'] ?? 0).toDouble(),
        maxCapacity: (widget.venue['max_capacity'] ?? 0) as int,
      );

  PriceTier? get _matchedTier => findMatchingTier(_tiers, widget.guestCount);

  double get _venuePrice => _matchedTier?.price ?? 0;

  double get _menuTotal {
    if (!widget.menuEnabled || widget.selectedMenu == null) return 0;
    final pricePerHead =
        widget.selectedMenu!.option == MenuOption.standard
            ? (widget.venue['standard_menu_price'] ?? 0).toDouble()
            : (widget.venue['premium_menu_price'] ?? 0).toDouble();
    return pricePerHead * widget.guestCount;
  }

  double get _totalAmount => _venuePrice + _menuTotal;

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _fmt(double value) {
    final s = value.toStringAsFixed(0);
    if (s.length <= 3) return 'PKR $s';
    final last3 = s.substring(s.length - 3);
    String rest = s.substring(0, s.length - 3);
    rest = rest.replaceAllMapped(
        RegExp(r'(\d)(?=(\d\d)+(?!\d))'), (m) => '${m[1]},');
    return 'PKR $rest,$last3';
  }

  String _monthName(int m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[m - 1];
  }

  String get _formattedDate =>
      '${widget.selectedDay.day} ${_monthName(widget.selectedDay.month)} ${widget.selectedDay.year}';

  String get _dateStr =>
      '${widget.selectedDay.year}-'
      '${widget.selectedDay.month.toString().padLeft(2, '0')}-'
      '${widget.selectedDay.day.toString().padLeft(2, '0')}';

  String? get _menuLabel {
    if (!widget.menuEnabled || widget.selectedMenu == null) return null;
    return widget.selectedMenu!.option == MenuOption.standard
        ? 'Standard Menu'
        : 'Premium Menu';
  }

  double get _menuPricePerHead {
    if (!widget.menuEnabled || widget.selectedMenu == null) return 0;
    return widget.selectedMenu!.option == MenuOption.standard
        ? (widget.venue['standard_menu_price'] ?? 0).toDouble()
        : (widget.venue['premium_menu_price'] ?? 0).toDouble();
  }

  // ── API call ─────────────────────────────────────────────────────────────
  Future<void> _confirmBooking() async {
    setState(() => _isSubmitting = true);
    try {
      await ApiClient.post('/bookings', {
        'venue_id': widget.venue['id'],
        'event_date': _dateStr,
        'event_time': widget.eventTime,
        'event_type': widget.eventType,
        'guest_count': widget.guestCount,
        'notes': (widget.notes?.isEmpty ?? true) ? null : widget.notes,
        'services_requested': [],
        'menu_selected': (widget.menuEnabled && widget.selectedMenu != null)
            ? (widget.selectedMenu!.option == MenuOption.standard
                ? 'standard'
                : 'premium')
            : null,
      });
      if (mounted) {
        // Pop both the summary AND the booking form
        Navigator.pop(context);
        Navigator.pop(context);
        widget.onBooked();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              widget.venue['name'] ?? '',
              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted),
            ),
          ],
        ),
      ),

      // ── Bottom CTA ───────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total at a glance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
                Text(
                  _fmt(_totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Confirm Booking',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Success banner ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event_available_rounded,
                        color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review your booking',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Please confirm the details below before sending your request.',
                          style: TextStyle(
                            color: AppTheme.primary.withAlpha(180),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Venue card ─────────────────────────────────────────────────
            _SectionCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.venue['image'] ??
                          'https://images.unsplash.com/photo-1674021864708-ed33fcf3c18b',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: AppTheme.surfaceVariant,
                        child: const Icon(Icons.image_not_supported_rounded,
                            color: AppTheme.outlineVariant),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.venue['name'] ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 13, color: AppTheme.onSurfaceMuted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                widget.venue['location'] ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.onSurfaceMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.venue['type'] ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.onSurfaceMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Event details ──────────────────────────────────────────────
            _SectionLabel(label: 'Event Details'),
            const SizedBox(height: 8),
            _SectionCard(
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _formattedDate,
                  ),
                  const _Divider(),
                  _SummaryRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: widget.eventTime,
                  ),
                  const _Divider(),
                  _SummaryRow(
                    icon: Icons.celebration_rounded,
                    label: 'Event Type',
                    value: widget.eventType,
                  ),
                  const _Divider(),
                  _SummaryRow(
                    icon: Icons.people_outline_rounded,
                    label: 'Guests',
                    value: '${widget.guestCount}',
                  ),
                  if (widget.notes != null && widget.notes!.isNotEmpty) ...[
                    const _Divider(),
                    _SummaryRow(
                      icon: Icons.notes_rounded,
                      label: 'Special Requirements',
                      value: widget.notes!,
                      valueMaxLines: 3,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Pricing breakdown ──────────────────────────────────────────
            _SectionLabel(label: 'Pricing Breakdown'),
            const SizedBox(height: 8),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier info banner
                  if (_matchedTier != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt_rounded,
                              size: 15, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_matchedTier!.name} · '
                              '${_matchedTier!.minGuests}–${_matchedTier!.maxGuests} guests',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _PriceRow(
                    label: _matchedTier != null
                        ? 'Venue Price (${_matchedTier!.name})'
                        : 'Venue Price',
                    value: _fmt(_venuePrice),
                  ),

                  if (_menuLabel != null) ...[
                    const SizedBox(height: 8),
                    _PriceRow(
                      label:
                          '$_menuLabel · ${_fmt(_menuPricePerHead).replaceFirst('PKR ', '')}/head × ${widget.guestCount}',
                      value: _fmt(_menuTotal),
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 1),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _fmt(_totalAmount),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 15, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Final price is confirmed by the venue owner. '
                            'You will only be charged for your actual guest count, '
                            'not the full tier range.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_menuLabel != null) ...[
              const SizedBox(height: 14),

              // ── Menu selection recap ─────────────────────────────────────
              _SectionLabel(label: 'Menu Selection'),
              const SizedBox(height: 8),
              _SectionCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLighter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _menuLabel!,
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmt(_menuPricePerHead).replaceFirst('PKR ', 'PKR ')}/head '
                            '× ${widget.guestCount} guests',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _fmt(_menuTotal),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ── Cancellation note ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 18, color: AppTheme.onSurfaceMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is a booking request, not a confirmed reservation. '
                      'The venue owner will review and accept or reject your request.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int valueMaxLines;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueMaxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 10),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceMuted)),
        const Spacer(),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: valueMaxLines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceMuted)),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1, thickness: 0.8),
      );
}
