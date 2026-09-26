import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:dio/dio.dart';
import '../../widgets/venue_image_slider_widget.dart';
import 'package:venuemate/presentation/customer/chat_screen.dart';
import 'package:venuemate/core/services/user_service.dart';
import 'package:venuemate/presentation/customer/venue_map_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'price_tier_selector.dart';
import 'add_menu_selector.dart';
import 'booking_summary_screen.dart';

class CustomerVenuesScreen extends StatefulWidget {
  const CustomerVenuesScreen({super.key});

  @override
  State<CustomerVenuesScreen> createState() => _CustomerVenuesScreenState();
}

class _CustomerVenuesScreenState extends State<CustomerVenuesScreen> {
  String _selectedFilter = 'All';
  String _sortBy = 'Recommended';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _guestController = TextEditingController();
  final TextEditingController _eventTypeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isBooking = false;
  String _currentUserId = '';
  final List<String> _filters = [
    'All', 'Halls', 'Marquees', 'Palaces', 'Farmhouses',
  ];
  final List<String> _sortOptions = [
    'Recommended', 'Price: Low to High', 'Price: High to Low',
    'Nearest', 'Top Rated',
  ];

  // ── NEW: active filter values passed back from the sheet ──
  RangeValues _activeBudget = const RangeValues(50000, 500000);
  RangeValues _activeCapacity = const RangeValues(100, 1000);
  String _activeSort = 'recommended';
  bool get _filtersActive =>
      _activeBudget.start > 50000 ||
      _activeBudget.end < 500000 ||
      _activeCapacity.start > 100 ||
      _activeCapacity.end < 1000 ||
      _activeSort != 'recommended';
  // ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get _filteredVenues {
    if (_searchController.text.isEmpty) return _venues;
    final query = _searchController.text.toLowerCase();
    return _venues.where((v) =>
      v['name'].toString().toLowerCase().contains(query) ||
      v['location'].toString().toLowerCase().contains(query)
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    _guestController.dispose();
    _eventTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVenues() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      String? typeParam;
      if (_selectedFilter == 'Halls') typeParam = 'hall';
      else if (_selectedFilter == 'Marquees') typeParam = 'marquee';
      else if (_selectedFilter == 'Palaces') typeParam = 'palace';
      else if (_selectedFilter == 'Farmhouses') typeParam = 'farmhouse';

      // ── CHANGED: use _activeSort instead of local _sortBy ──
      final params = <String, dynamic>{'sort': _activeSort};
      if (typeParam != null) params['type'] = typeParam;
      if (_searchController.text.isNotEmpty) params['q'] = _searchController.text;

      // ── NEW: pass budget + capacity params to API ──
      if (_activeBudget.start > 10000) params['min_price'] = _activeBudget.start.toInt();
      if (_activeBudget.end < 2000000) params['max_price'] = _activeBudget.end.toInt();
      if (_activeCapacity.start > 50) params['min_capacity'] = _activeCapacity.start.toInt();
      // ──────────────────────────────────────────────

      final res = await ApiClient.get('/venues', params: params);

      final venues = (res['venues'] as List).map((v) {
        return {
          'id': v['id'] ?? '',
          'name': v['name'] ?? '',
          'type': v['type'] ?? '',
          'owner_id': v['owner_id'] ?? '',
          'location': v['location']?['area'] ?? v['location']?['address'] ?? '',
          'price': _formatPrice(v['pricing']?['base_per_day']),
          'capacity': '${v['capacity']?['min'] ?? 0}–${v['capacity']?['max'] ?? 0}',
          // ── raw numeric fields for dynamic price-tier + menu widgets ──
          'base_price': (v['pricing']?['base_per_day'] ?? 0).toDouble(),
          'max_capacity': (v['capacity']?['max'] ?? 0) as int,
          'min_capacity': (v['capacity']?['min'] ?? 1) as int,
          'standard_menu_price': (v['pricing']?['standard_menu_per_head'] ?? 0).toDouble(),
          'premium_menu_price': (v['pricing']?['premium_menu_per_head'] ?? 0).toDouble(),
          // ────────────────────────────────────────────────────────────
          'rating': (v['rating'] ?? 0.0).toDouble(),
          'reviews': v['review_count'] ?? 0,
          'available': v['is_active'] ?? true,
          'image': (v['media'] != null && (v['media'] as List).isNotEmpty)
              ? v['media'][0]['url']
              : 'https://images.unsplash.com/photo-1674021864708-ed33fcf3c18b',
          'images': (v['media'] != null && (v['media'] as List).isNotEmpty)
              ? (v['media'] as List).map((m) => m['url'].toString()).toList()
              : ['https://images.unsplash.com/photo-1674021864708-ed33fcf3c18b'],
          'badge': v['badge'],
          'semanticLabel': v['name'] ?? '',
        };
      }).toList();

      setState(() { _venues = venues; _isLoading = false; });
    } on DioException catch (_) {
      setState(() { _isLoading = false; _error = 'Failed to load venues'; });
    } catch (e) {
      setState(() { _isLoading = false; _error = 'Something went wrong'; });
    }
  }

  Future<void> _loadCurrentUser() async {
  final user = await UserService.getUser();
  if (mounted) setState(() => _currentUserId = user?.id ?? '');
}

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final p = price as int;
    if (p >= 100000) return '${(p / 1000).toStringAsFixed(0)},000';
    return p.toString();
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
            _buildFilterRow(theme),
            _buildSortBar(theme),
            Expanded(child: _buildVenueList(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explore Venues', style: theme.textTheme.headlineMedium),
                Text('Gujranwala, Punjab',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() {});
          _loadVenues();
        },
        decoration: InputDecoration(
          hintText: 'Search Venues...',
          hintStyle: const TextStyle(
          color: Color.fromARGB(185, 0, 0, 0), 
        ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color.fromARGB(185, 0, 0, 0),
               size: 20,
            ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterRow(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = _selectedFilter == _filters[i];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = _filters[i]);
              _loadVenues();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.outlineVariant),
              ),
              child: Text(_filters[i],
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? Colors.white : AppTheme.onSurfaceMuted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text('${_filteredVenues.length} venues found',
              style: theme.textTheme.bodySmall),
          const Spacer(),
          GestureDetector(
            onTap: () => _showFilterSheet(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                // ── CHANGED: filled when filters active ──
                color: _filtersActive ? AppTheme.primary : AppTheme.primaryLighter,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 15,
                      color: _filtersActive ? Colors.white : AppTheme.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Filter',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _filtersActive ? Colors.white : AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ── CHANGED: pass current values + onApply callback ──
      builder: (_) => _FilterBottomSheet(
        initialBudget: _activeBudget,
        initialCapacity: _activeCapacity,
        initialSort: _activeSort,
        onApply: (budget, capacity, sort) {
          setState(() {
            _activeBudget = budget;
            _activeCapacity = capacity;
            _activeSort = sort;
          });
          _loadVenues();
        },
      ),
    );
  }

  Widget _buildVenueList(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadVenues, child: const Text('Retry')),
          ],
        ),
      );
    }
    final venues = _filteredVenues;
    if (venues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48,
                color: AppTheme.outlineVariant),
            const SizedBox(height: 12),
            Text('No venues found',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: venues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _buildVenueCard(theme, venues[i]),
    );
  }

  Widget _buildVenueCard(ThemeData theme, Map<String, dynamic> venue) {
    return GestureDetector(
      onTap: () => _showVenueDetail(theme, venue),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(13),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: _buildVenueImageSlider(venue),
                ),
                if (venue['badge'] != null)
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(venue['badge'],
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: venue['available']
                          ? AppTheme.successContainer
                          : AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      venue['available'] ? 'Available' : 'Booked',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: venue['available']
                            ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: StatefulBuilder(
                    builder: (context, setIconState) {
                      bool fav = false;
                      return GestureDetector(
                        onTap: () async {
                          try {
                            await ApiClient.post('/venues/${venue['id']}/favourite', {});
                            setIconState(() => fav = !fav);
                          } catch (_) {}
                        },
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                                color: Colors.black.withAlpha(26), blurRadius: 6)],
                          ),
                          child: Icon(
                            fav ? Icons.favorite_border_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(venue['name'],
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14,
                              color: AppTheme.gold),
                          const SizedBox(width: 2),
                          Text('${venue['rating']}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700)),
                          Text(' (${venue['reviews']})',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13,
                          color: AppTheme.onSurfaceMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(venue['location'],
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: _infoChip(theme, Icons.people_outline_rounded,
                            '${venue['capacity']} guests'),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _infoChip(
                            theme, Icons.category_outlined, venue['type']),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('PKR ${venue['price']}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis),
                            Text('per event',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.onSurfaceMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showVenueDetail(theme, venue),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text('View Details',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: AppTheme.primary)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: venue['available']
                              ? () => _showBookingSheet(theme, venue)
                              : null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            venue['available'] ? 'Book Now' : 'Unavailable',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String label) {
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
           Flexible(
            child: Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppTheme.onSurfaceMuted),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _showVenueDetail(ThemeData theme, Map<String, dynamic> venue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueDetailScreen(
          venue: venue,
          currentUserId: _currentUserId,
          onBook: () => _showBookingSheet(theme, venue),
        ),
      ),
    );
  }

  Widget _detailChip(ThemeData theme, IconData icon, String label,
      String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(ThemeData theme, Map<String, dynamic> venue) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _BookingScreen(
        venue: venue,
        onBooked: () {
          _dateController.clear();
          _guestController.clear();
          _eventTypeController.clear();
          _notesController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking request sent to ${venue['name']}!'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    ),
  );
}

  Widget _buildVenueImageSlider(Map<String, dynamic> venue) {
    final images = venue['images'] as List<dynamic>? ??
        [venue['image'] ??
            'https://images.unsplash.com/photo-1674021864708-ed33fcf3c18b'];
    return VenueImageSlider(
      images: images.map((e) => e.toString()).toList(),
      height: 220,
      semanticLabel: venue['semanticLabel'] ?? '',
    );
  }
}


class VenueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> venue;
  final String currentUserId;
  final VoidCallback? onBook;

  const VenueDetailScreen({
    super.key,
    required this.venue,
    required this.currentUserId,
    this.onBook,
  });

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  List<String> _images = [];
  bool _loadingImages = true;
  double _lat = 32.1877;
  double _lng = 74.1945;
  List<String> _facilities = [];
  List<String> _services = [];
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _images = (widget.venue['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [widget.venue['image'] ?? ''];
      _lat = (widget.venue['lat'] ?? 32.1877).toDouble();
      _lng = (widget.venue['lng'] ?? 74.1945).toDouble();
     _loadCurrentUser();
    _fetchFullVenue();
  }
  
 Future<void> _loadCurrentUser() async {
    final user = await UserService.getUser();
    if (mounted) setState(() => _currentUserId = user?.id ?? '');
  }

  Future<void> _fetchFullVenue() async {
    try {
      final res = await ApiClient.get('/venues/${widget.venue['id']}');
      final v = res['venue'];
      if (v != null && mounted) {
        final allImages = (v['media'] as List?)
            ?.map((m) => m['url'].toString())
            .toList() ?? _images;
        setState(() {
          _images = allImages.isNotEmpty ? allImages : _images;
          _lat = (v['location']?['coordinates'] as List?)?.last?.toDouble() ?? 32.1877;
          _lng = (v['location']?['coordinates'] as List?)?.first?.toDouble() ?? 74.1945;
          _facilities = (v['facilities'] as List?)?.map((e) => e.toString()).toList() ?? [];
          _services = (v['services'] as List?)?.map((e) => e.toString()).toList() ?? [];
          _loadingImages = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingImages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final venue = widget.venue;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Stack(
            children: [
              VenueImageSlider(
                images: _images,
                height: 280,
                semanticLabel: venue['semanticLabel'] ?? '',
              ),
              if (_loadingImages)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
          // ── Scrollable content below ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(venue['name'],
                            style: theme.textTheme.headlineSmall),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: Color(0xFFFFB300)),
                          const SizedBox(width: 3),
                          Text('${venue['rating']}',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(' (${venue['reviews']})',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(venue['location'],
                            style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VenueMapScreen(
                          venueName: venue['name'],
                          address: venue['location'],
                          latitude: _lat,
                          longitude: _lng,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLighter,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primary.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map_rounded,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text('View on Map',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 12, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _infoChip(theme, Icons.people_outline_rounded,
                          'Capacity', '${venue['capacity']} guests'),
                      const SizedBox(width: 12),
                      _infoChip(theme, Icons.category_outlined,
                          'Type', venue['type']),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('About This Venue',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'A premium ${venue['type'].toString().toLowerCase()} venue in Gujranwala offering world-class facilities for weddings, corporate events, and celebrations. Features air conditioning, dedicated parking, catering services, and professional event management support.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceMuted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                    if (_facilities.isNotEmpty || _services.isNotEmpty) ...[
                    Text('Facilities & Services', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [..._facilities, ..._services].map((f) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLighter,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(f,
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600)),
                          )).toList(),
                    ),
                  const SizedBox(height: 20),
                ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Starting Price',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceMuted)),
                  Text('PKR ${venue['price']}',
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      conversation: {
                        'room_id': 'venue:${venue['id']}:$_currentUserId',
                        'other_user_id': venue['owner_id'],
                        'name': venue['name'],
                        'context_type': 'venue',
                        'context_name': venue['name'],
                        'context_image': venue['image'],
                        'online': false,
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Chat'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                foregroundColor: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onBook != null) {
                  Navigator.pop(context);
                  widget.onBook!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _BookingScreen(
                        venue: widget.venue,
                        onBooked: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Booking request sent to ${widget.venue['name']}!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: const Text('Book Now'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _BookingScreen extends StatefulWidget {
  final Map<String, dynamic> venue;
  final VoidCallback onBooked;

  const _BookingScreen({
    required this.venue,
    required this.onBooked,
  });

  @override
  State<_BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<_BookingScreen> {
  Set<DateTime> _blockedDates = {};
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  bool _loadingDates = true;
  bool _isBooking = false;

  final _guestController = TextEditingController();
  final _eventTypeController = TextEditingController();
  final _notesController = TextEditingController();
  final _timeController = TextEditingController();

  // ── Add Menu state ──
  bool _menuEnabled = false;
  MenuChoice? _selectedMenu;

  @override
  void initState() {
    super.initState();
    _loadBlockedDates();
  }

  @override
  void dispose() {
    _guestController.dispose();
    _eventTypeController.dispose();
    _notesController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadBlockedDates() async {
    try {
      final res = await ApiClient.get('/venues/${widget.venue['id']}/blocked-dates');
      final list = (res['blocked_dates'] as List?) ?? [];
      setState(() {
        _blockedDates = list
            .map((d) => DateTime.parse(d.toString()).toLocal())
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet();
        _loadingDates = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDates = false);
    }
  }

  bool _isBlocked(DateTime day) {
    return _blockedDates.contains(DateTime(day.year, day.month, day.day));
  }

  void _submitBooking() {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event date'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_guestController.text.isEmpty || _eventTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill guest count and event type'), backgroundColor: Colors.red),
      );
      return;
    }
    final guestCount = int.tryParse(_guestController.text);
    final minCap = (widget.venue['min_capacity'] ?? 1) as int;
    final maxCap = (widget.venue['max_capacity'] ?? 0) as int;
    if (guestCount == null || guestCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid guest count'), backgroundColor: Colors.red),
      );
      return;
    }
    if (guestCount < minCap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This venue requires a minimum of $minCap guests. Please enter within capacity.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (maxCap > 0 && guestCount > maxCap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This venue can host a maximum of $maxCap guests. Please enter within capacity.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event time'), backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryScreen(
          venue: widget.venue,
          selectedDay: _selectedDay!,
          eventTime: _timeController.text,
          eventType: _eventTypeController.text,
          guestCount: guestCount!,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          menuEnabled: _menuEnabled,
          selectedMenu: _selectedMenu,
          onBooked: widget.onBooked,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book Venue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(widget.venue['name'],
                style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingDates
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Event Date', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text('Greyed out dates are unavailable',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                      selectedDayPredicate: (day) =>
                          _selectedDay != null &&
                          isSameDay(_selectedDay!, day),
                      enabledDayPredicate: (day) => !_isBlocked(day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) =>
                          setState(() => _focusedDay = focusedDay),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(color: Colors.white),
                        todayDecoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(color: AppTheme.primary),
                        disabledTextStyle: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                        disabledDecoration: BoxDecoration(
                          color: Colors.grey.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.onSurface),
                        leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppTheme.primary),
                        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                        weekendStyle: TextStyle(
                            color: AppTheme.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                  ),
                  if (_selectedDay != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLighter,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Selected: ${_selectedDay!.day} ${_monthName(_selectedDay!.month)} ${_selectedDay!.year}',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Dynamic price tiers, generated from the venue's base
                  // price + max capacity. Re-highlights as guest count changes.
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _guestController,
                    builder: (context, value, _) {
                      return PriceTierSelector(
                        basePrice: (widget.venue['base_price'] ?? 0).toDouble(),
                        minCapacity: (widget.venue['min_capacity'] ?? 1) as int,
                        maxCapacity: (widget.venue['max_capacity'] ?? 0) as int,
                        guestCount: int.tryParse(value.text),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // ─────────────────────────────────────────────────────

                  Text('Event Details', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _guestController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Guest Count',
                      prefixIcon: Icon(Icons.people_outline_rounded, size: 18),
                      hintText: 'e.g. 500',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _eventTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Event Type',
                      prefixIcon: Icon(Icons.celebration_rounded, size: 18),
                      hintText: 'Wedding, Birthday, Corporate...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 18, minute: 0),
                      );
                      if (picked != null) {
                        setState(() => _timeController.text = picked.format(context));
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Event Time',
                      prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                      hintText: 'Select event start time',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Add Menu: standard/premium priced per head, set by the
                  // venue owner. Total shown uses the EXACT guest count typed
                  // (never the 200/500 tier band) so there's no over-charge.
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _guestController,
                    builder: (context, value, _) {
                      return AddMenuSelector(
                        standardPricePerHead: (widget.venue['standard_menu_price'] ?? 0).toDouble(),
                        premiumPricePerHead: (widget.venue['premium_menu_price'] ?? 0).toDouble(),
                        guestCount: int.tryParse(value.text),
                        onChanged: (enabled, selection) {
                          setState(() {
                            _menuEnabled = enabled;
                            _selectedMenu = selection;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // ─────────────────────────────────────────────

                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Special Requirements',
                      hintText: 'Any specific needs...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitBooking,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Review & Confirm', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

// ─── Filter Bottom Sheet ─────────────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  // ── CHANGED: accept initial values and onApply callback ──
  final RangeValues initialBudget;
  final RangeValues initialCapacity;
  final String initialSort;
  final void Function(RangeValues budget, RangeValues capacity, String sort) onApply;

  const _FilterBottomSheet({
    required this.initialBudget,
    required this.initialCapacity,
    required this.initialSort,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late RangeValues _budgetRange;
  late RangeValues _capacityRange;
  late double _distanceRadius;
  late String _sortBy;
  final Set<String> _selectedFacilities = {};

  // Sort label → API param
  static const _sortApiMap = <String, String>{
    'Best Match':          'recommended',
    'Price: Low to High':  'price_asc',
    'Price: High to Low':  'price_desc',
    'Highest Rated':       'rating',
  };

  final List<String> _sortOptions = [
    'Best Match',
    'Price: Low to High',
    'Price: High to Low',
    'Highest Rated',
  ];

  final List<String> _facilities = [
    'Air Conditioning',
    'Catering',
    'Parking',
    'Generator',
    'Decoration',
    'Sound System',
    'Stage',
    'Bridal Room',
  ];

  @override
  void initState() {
    super.initState();
    _budgetRange = widget.initialBudget;
    _capacityRange = widget.initialCapacity;
    _distanceRadius = 15;
    // reverse-map API param back to label
    _sortBy = _sortApiMap.entries
        .firstWhere((e) => e.value == widget.initialSort,
            orElse: () => _sortApiMap.entries.first)
        .key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text('Filter Venues', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _budgetRange = const RangeValues(50000, 500000);
                      _capacityRange = const RangeValues(100, 1000);
                      _distanceRadius = 15;
                      _sortBy = 'Best Match';
                      _selectedFacilities.clear();
                    }),
                    child: Text('Reset All',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: AppTheme.primary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Budget
                  Text('Budget Range (PKR)', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${(_budgetRange.start / 1000).toStringAsFixed(0)}K',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'PKR ${(_budgetRange.end / 1000).toStringAsFixed(0)}K',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.primaryLighter,
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withAlpha(31),
                    ),
                    child: RangeSlider(
                      values: _budgetRange,
                      min: 10000,
                      max: 2000000,
                      divisions: 100,
                      onChanged: (v) => setState(() => _budgetRange = v),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Capacity
                  Text('Guest Capacity', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_capacityRange.start.toInt()} guests',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_capacityRange.end.toInt()} guests',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.primaryLighter,
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withAlpha(31),
                    ),
                    child: RangeSlider(
                      values: _capacityRange,
                      min: 50,
                      max: 2000,
                      divisions: 50,
                      onChanged: (v) => setState(() => _capacityRange = v),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Distance
                  Text('Distance Radius', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${_distanceRadius.toInt()} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.primaryLighter,
                      thumbColor: AppTheme.primary,
                    ),
                    child: Slider(
                      value: _distanceRadius,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      onChanged: (v) => setState(() => _distanceRadius = v),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sort By
                  Text('Sort By', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.map((option) {
                      final isSelected = _sortBy == option;
                      return GestureDetector(
                        onTap: () => setState(() => _sortBy = option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryLighter
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            option,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Facilities
                  Text('Facilities', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _facilities.map((facility) {
                      final isSelected = _selectedFacilities.contains(facility);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedFacilities.remove(facility);
                          } else {
                            _selectedFacilities.add(facility);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryLighter
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            facility,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // ── CHANGED: call onApply instead of just pop ──
                  onPressed: () {
                    widget.onApply(
                      _budgetRange,
                      _capacityRange,
                      _sortApiMap[_sortBy] ?? 'recommended',
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply Filters',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}