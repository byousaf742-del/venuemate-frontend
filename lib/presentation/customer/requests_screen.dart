import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import 'package:venuemate/core/services/api_client.dart';

class CustomerRequestsScreen extends StatefulWidget {
  const CustomerRequestsScreen({super.key});

  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
void initState() {
  super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
  setState(() => _isLoading = true);
  try {
    final bidsRes = await ApiClient.get('/bids/my');
    final quotesRes = await ApiClient.get('/bids/quotations/received');

    final bids = (bidsRes['bids'] as List).map((b) {
      return {
        'id': b['id'] ?? '',
        'eventDate': b['event_date'] ?? '',
        'eventType': b['event_type'] ?? '',
        'budget': _formatAmount(b['budget']),
        'guests': b['guest_count'] ?? 0,
        'services': List<String>.from(b['services_required'] ?? []),
        'status': _mapBidStatus(b['status']),
        'quotations': b['quotation_count'] ?? 0,
        'sentTo': List<String>.from(b['venue_names'] ?? []),
      };
    }).toList();

    final quotations = (quotesRes['quotations'] as List).map((q) {
      return {
        'bid_id': q['bid_id'] ?? '',
        'quotation_id': q['quotation_id'] ?? '',
        'venue': q['venue'] ?? '',
        'bidId': q['bid_id'] ?? '',
        'offeredPrice': _formatAmount(q['offered_price']),
        'originalBudget': _formatAmount(q['original_budget']),
        'discount': '${q['discount'] ?? 0}%',
        'validUntil': q['valid_until'] ?? '',
        'status': q['status'] ?? 'pending',
        'message': q['message'] ?? '',
        'image': q['image'] ?? 'https://images.unsplash.com/photo-1674021864708-ed33fcf3c18b',
        'semanticLabel': q['venue'] ?? '',
        'rating': (q['rating'] ?? 0.0).toDouble(),
      };
    }).toList();

    setState(() {
      _bids = bids;
      _quotations = quotations;
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
  }
}

String _mapBidStatus(String? status) {
  switch (status) {
    case 'open': return 'active';
    case 'countered': return 'active';
    case 'accepted': return 'accepted';
    case 'converted': return 'accepted';
    case 'expired': return 'expired';
    case 'rejected': return 'expired';
    default: return 'active';
  }
}

String _formatAmount(dynamic amount) {
  if (amount == null) return '0';
  final a = amount is int ? amount : (amount as num).toInt();
  return a.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

  List<Map<String, dynamic>> _bids = [];
  List<Map<String, dynamic>> _quotations = [];
  bool _isLoading = false;

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
                children: [_buildBidsList(theme), _buildQuotationsList(theme)],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewBidSheet(theme),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'New Bid',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
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
                Text('Requests & Bids', style: theme.textTheme.headlineMedium),
                Text(
                  'Send bids and compare quotations',
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(text: 'My Bids (${_bids.length})'),
          Tab(text: 'Quotations (${_quotations.length})'),
        ],
      ),
    );
  }

  Widget _buildBidsList(ThemeData theme) {
    if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (_bids.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.request_quote_outlined, size: 52, color: AppTheme.outlineVariant),
          const SizedBox(height: 12),
          Text('No bids sent yet', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.onSurfaceMuted)),
          const SizedBox(height: 4),
          Text('Tap + New Bid to send your first bid', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _bids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _buildBidCard(theme, _bids[i]),
    );
  }

  Widget _buildBidCard(ThemeData theme, Map<String, dynamic> bid) {
    final statusColors = {
      'active': AppTheme.info,
      'accepted': AppTheme.success,
      'expired': AppTheme.onSurfaceMuted,
    };
    final statusBg = {
      'active': AppTheme.infoContainer,
      'accepted': AppTheme.successContainer,
      'expired': AppTheme.surfaceVariant,
    };
    final color = statusColors[bid['status']] ?? AppTheme.onSurfaceMuted;
    final bg = statusBg[bid['status']] ?? AppTheme.surfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.request_quote_rounded,
                  size: 20,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bid['eventType'], style: theme.textTheme.titleSmall),
                    Text(
                      bid['id'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bid['status'].toString().toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(child: _bidInfo(theme, Icons.calendar_today_rounded, bid['eventDate'])),
              const SizedBox(width: 16),
              Flexible(child: _bidInfo(theme, Icons.people_outline_rounded, '${bid['guests']} guests')),
              const SizedBox(width: 16),
              Flexible(child: _bidInfo(theme, Icons.currency_rupee_rounded, 'PKR ${bid['budget']}')),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: (bid['services'] as List)
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLighter,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.send_rounded,
                size: 13,
                color: AppTheme.onSurfaceMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Sent to: ${(bid['sentTo'] as List).join(', ')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (bid['quotations'] > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.successContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mark_email_read_rounded,
                    size: 16,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${bid['quotations']} quotation(s) received',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Text(
                      'View →',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bidInfo(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuotationsList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _quotations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _buildQuotationCard(theme, _quotations[i]),
    );
  }

  Widget _buildQuotationCard(ThemeData theme, Map<String, dynamic> q) {
    final isPending = q['status'] == 'pending';
    final isAccepted = q['status'] == 'accepted';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAccepted
            ? Border.all(color: AppTheme.success, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: CustomImageWidget(
                  imageUrl: q['image'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  semanticLabel: q['semanticLabel'],
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
                              q['venue'],
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAccepted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ACCEPTED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppTheme.gold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${q['rating']}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'PKR ${q['offeredPrice']}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${q['discount']} off',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q['message'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Valid until ${q['validUntil']}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectQuotation(q),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            'Decline',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptQuotation(q),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Accept Offer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptQuotation(Map<String, dynamic> q) async {
  try {
    await ApiClient.put('/bids/${q['bid_id']}/action', {
      'action': 'accept',
      'quotation_id': q['quotation_id'],
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer from ${q['venue']} accepted! Booking created.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadData();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept offer. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Future<void> _rejectQuotation(Map<String, dynamic> q) async {
  try {
    await ApiClient.put('/bids/${q['bid_id']}/action', {
      'action': 'reject',
      'quotation_id': q['quotation_id'],
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer from ${q['venue']} declined.'),
          backgroundColor: AppTheme.error,
        ),
      );
      _loadData();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to decline offer. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  void _showNewBidSheet(ThemeData theme) {
    final eventTypeCtrl = TextEditingController();
    final eventDateCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final guestCtrl = TextEditingController();
    final servicesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Send New Bid', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Send your requirements to multiple venues',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: eventTypeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  prefixIcon: Icon(Icons.celebration_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: eventDateCtrl,
                readOnly: true,
                onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      eventDateCtrl.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    }
                  },
                decoration: const InputDecoration(
                  labelText: 'Event Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget (PKR)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: guestCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Guest Count',
                  prefixIcon: Icon(Icons.people_outline_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: servicesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Required Services',
                  hintText: 'Catering, Decoration, Sound...',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                  if (eventTypeCtrl.text.isEmpty ||
                      eventDateCtrl.text.isEmpty ||
                      budgetCtrl.text.isEmpty ||
                      guestCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  try {
                    final venuesRes = await ApiClient.get('/venues');
                    final allVenueIds = (venuesRes['venues'] as List)
                        .map((v) => v['id'].toString())
                        .toList();

                    await ApiClient.post('/bids', {
                      'venue_ids': allVenueIds,
                      'event_type': eventTypeCtrl.text,
                      'event_date': eventDateCtrl.text,
                      'budget': int.tryParse(budgetCtrl.text) ?? 0,
                      'guest_count': int.tryParse(guestCtrl.text) ?? 0,
                      'services_required': servicesCtrl.text
                          .split(',')
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .toList(),
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bid posted!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to post bid. Try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Post Bid'),
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
    ).then((_) => _loadData());
  }
}
