import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'package:venuemate/core/services/api_client.dart';

class OwnerRequestsScreen extends StatefulWidget {
  const OwnerRequestsScreen({super.key});

  @override
  State<OwnerRequestsScreen> createState() => _OwnerRequestsScreenState();
}

class _OwnerRequestsScreenState extends State<OwnerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBids();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBids() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/bids/owner/received');
      final bids = (res['bids'] as List).map((b) {
        return {
          'id': b['id'] ?? '',
          'customerName': b['customer_name'] ?? 'Customer',
          'customerPhone': b['customer_phone'] ?? '',
          'eventType': b['event_type'] ?? '',
          'eventDate': b['event_date'] ?? '',
          'budget': _formatAmount(b['budget']),
          'guests': b['guest_count'] ?? 0,
          'services': List<String>.from(b['services_required'] ?? []),
          'status': b['already_quoted'] == true ? 'quoted' : 'new',
          'customerPhoto': b['customer_photo'] ?? '',
          'apiStatus': b['status'] ?? 'open',
          'message': b['message'] ?? '',
        };
      }).where((b) => b['apiStatus'] != 'rejected').toList();

      // Load sent quotations
      final quotesRes = await ApiClient.get('/bids/owner/quotations');
      final quotations = (quotesRes['quotations'] as List).map((q) => {
        'bid_id': q['bid_id'] ?? '',
        'quotation_id': q['quotation_id'] ?? '',
        'customerName': q['customerName'] ?? '',
        'offeredPrice': q['offeredPrice']?.toString() ?? '0',
        'validUntil': q['validUntil'] ?? '',
        'message': q['message'] ?? '',
        'status': q['status'] ?? 'pending',
        'venue_name': q['venue_name'] ?? '',
        'bidId': q['bidId'] ?? '',
        'event_type': q['event_type'] ?? '',
        'event_date': q['event_date'] ?? '',
      }).toList();

      setState(() {
        _bids = bids;
        _sentQuotations = quotations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _declineBid(Map<String, dynamic> bid) async {
    try {
      await ApiClient.put('/bids/${bid['id']}/action', {'action': 'reject'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bid from ${bid['customerName']} declined.'),
            backgroundColor: AppTheme.error,
          ),
        );
        _loadBids();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to decline bid. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _bids = [];
  List<Map<String, dynamic>> _sentQuotations = [];
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
                children: [
                  _buildBidsList(theme),
                  _buildSentQuotationsList(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final newBids = _bids.where((b) => b['status'] == 'new').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bid Requests', style: theme.textTheme.headlineMedium),
                Text(
                  'Respond to customer bids',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceMuted),
                ),
              ],
            ),
          ),
          if (newBids > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$newBids New',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
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
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: 'Incoming (${_bids.length})'),
          Tab(text: 'Sent Quotes (${_sentQuotations.length})'),
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
            Icon(Icons.inbox_outlined,
                size: 52, color: AppTheme.outlineVariant),
            const SizedBox(height: 12),
            Text('No bids received yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
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
    final isNew = bid['status'] == 'new';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isNew
            ? Border.all(color: AppTheme.primary.withAlpha(77), width: 1.5)
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
                    backgroundImage: (bid['customerPhoto'] != null &&
                        bid['customerPhoto'].toString().isNotEmpty)
                        ? NetworkImage(bid['customerPhoto'])
                        : null,
                    child: (bid['customerPhoto'] == null ||
                        bid['customerPhoto'].toString().isEmpty)
                        ? const Icon(Icons.person_rounded, color: AppTheme.primary, size: 24)
                        : null,
                  ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bid['customerName'],
                              style: theme.textTheme.titleSmall),
                          Text(bid['id'],
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.onSurfaceMuted)),
                        ],
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLighter,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  bid['message'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _bidChip(theme, Icons.celebration_rounded, bid['eventType']),
                    const SizedBox(width: 8),
                    _bidChip(
                        theme, Icons.calendar_today_rounded, bid['eventDate']),
                    const SizedBox(width: 8),
                    _bidChip(theme, Icons.people_outline_rounded,
                        '${bid['guests']}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee_rounded,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 2),
                    Text(
                      'Budget: PKR ${bid['budget']}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (bid['services'] as List)
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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
              ],
            ),
          ),
          if (isNew)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineBid(bid),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.onSurfaceMuted),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text('Decline',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: AppTheme.onSurfaceMuted)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showSendQuoteSheet(theme, bid),
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const Text('Send Quote'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _bidChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.onSurfaceMuted),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppTheme.onSurfaceMuted)),
        ],
      ),
    );
  }

  Widget _buildSentQuotationsList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sentQuotations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined,
                size: 52, color: AppTheme.outlineVariant),
            const SizedBox(height: 12),
            Text('No quotations sent yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _sentQuotations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _buildSentQuoteCard(theme, _sentQuotations[i]),
    );
  }

  Widget _buildSentQuoteCard(ThemeData theme, Map<String, dynamic> q) {
    final status = q['status'] ?? 'pending';
    Color statusColor = AppTheme.warning;
    String statusLabel = 'AWAITING';
    if (status == 'accepted') {
      statusColor = AppTheme.success;
      statusLabel = 'ACCEPTED';
    } else if (status == 'rejected') {
      statusColor = AppTheme.error;
      statusLabel = 'DECLINED';
    }

    return Container(
      padding: const EdgeInsets.all(14),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q['customerName'] ?? '',
                        style: theme.textTheme.titleSmall),
                    if ((q['venue_name'] ?? '').isNotEmpty)
                      Text(q['venue_name'],
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _bidChip(theme, Icons.celebration_rounded, q['event_type'] ?? ''),
              const SizedBox(width: 8),
              _bidChip(theme, Icons.calendar_today_rounded, q['event_date'] ?? ''),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Offered Price',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.onSurfaceMuted)),
                    Text('PKR ${q['offeredPrice']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Valid Until',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.onSurfaceMuted)),
                    Text(q['validUntil'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warning)),
                  ],
                ),
              ],
            ),
          ),
          if ((q['message'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(q['message'],
                style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  void _showSendQuoteSheet(ThemeData theme, Map<String, dynamic> bid) async {
    List<Map<String, dynamic>> ownerVenues = [];
    try {
      final res = await ApiClient.get('/venues/mine');
      ownerVenues = List<Map<String, dynamic>>.from(
          (res['venues'] as List).map((v) => {'id': v['id'], 'name': v['name']}));
    } catch (_) {}

    if (!mounted) return;

    final priceCtrl = TextEditingController();
    final validUntilCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String? selectedVenueId =
        ownerVenues.isNotEmpty ? ownerVenues[0]['id'] : null;

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
                Text('Send Quotation', style: theme.textTheme.titleMedium),
                Text(
                  'To: ${bid['customerName']} • ${bid['eventType']}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.onSurfaceMuted),
                ),
                const SizedBox(height: 20),
                if (ownerVenues.length > 1) ...[
                  Text('Select Venue to Offer',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedVenueId,
                        isExpanded: true,
                        items: ownerVenues
                            .map((v) => DropdownMenuItem<String>(
                                  value: v['id'] as String,
                                  child: Text(v['name'] as String),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setSheetState(() => selectedVenueId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (ownerVenues.length == 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLighter,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_city_rounded,
                            size: 14, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Venue: ${ownerVenues[0]['name']}',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Your Offered Price (PKR)',
                    prefixIcon:
                        const Icon(Icons.currency_rupee_rounded, size: 18),
                    hintText: 'Customer budget: PKR ${bid['budget']}',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: validUntilCtrl,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      validUntilCtrl.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Valid Until',
                    prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message to Customer',
                    hintText:
                        'Describe your offer, included services, special packages...',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (priceCtrl.text.isEmpty ||
                          validUntilCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please enter price and valid until date'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      try {
                        await ApiClient.post(
                            '/bids/${bid['id']}/quotation', {
                          'amount': int.tryParse(priceCtrl.text) ?? 0,
                          'message': messageCtrl.text,
                          'valid_until': validUntilCtrl.text,
                          'discount_percent': 0,
                          'venue_id': selectedVenueId,
                        });
                        if (mounted) {
                          setState(() => bid['status'] = 'quoted');
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Quotation sent to ${bid['customerName']}!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                          _loadBids();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Failed to send quotation. Try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Quotation'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
}
