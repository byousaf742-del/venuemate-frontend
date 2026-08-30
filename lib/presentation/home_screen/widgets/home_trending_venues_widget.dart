import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/loading_skeleton_widget.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:venuemate/core/services/user_service.dart';
import 'package:venuemate/presentation/customer/venues_screen.dart';


class HomeTrendingVenuesWidget extends StatefulWidget {
  final String selectedCategory;
  final int crossAxisCount;

  const HomeTrendingVenuesWidget({
    super.key,
    required this.selectedCategory,
    this.crossAxisCount = 2,
  });

  @override
  State<HomeTrendingVenuesWidget> createState() =>
      _HomeTrendingVenuesWidgetState();
}

class _HomeTrendingVenuesWidgetState extends State<HomeTrendingVenuesWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _venueData = [];
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    try {
      final res = await ApiClient.get('/venues/trending');
      final venues = (res['venues'] as List).map((v) => {
        'id': v['id'] ?? '',
        'name': v['name'] ?? '',
        'area': v['location']?['area'] ?? '',
        'city': v['location']?['city'] ?? '',
        'type': v['type'] ?? '',
        'capacity': v['capacity']?['max'] ?? 0,
        'minCapacity': v['capacity']?['min'] ?? 1,
        'pricePerDay': (v['pricing']?['base_per_day'] ?? 0).toDouble(),
        'standardMenuPrice': (v['pricing']?['standard_menu_per_head'] ?? 0).toDouble(),
        'premiumMenuPrice': (v['pricing']?['premium_menu_per_head'] ?? 0).toDouble(),
        'rating': (v['rating'] ?? 0.0).toDouble(),
        'reviewCount': v['review_count'] ?? 0,
        'imageUrl': (v['media'] != null && (v['media'] as List).isNotEmpty)
            ? v['media'][0]['url']
            : 'https://images.unsplash.com/photo-1674021864708-ed33fcf3c18b',
        'images': (v['media'] != null && (v['media'] as List).isNotEmpty)
            ? (v['media'] as List).map((m) => m['url'].toString()).toList()
            : <String>[],
        'semanticLabel': v['name'] ?? '',
        'isAvailable': v['is_active'] ?? true,
        'isFeatured': v['badge'] != null,
        'facilities': List<String>.from(v['facilities'] ?? []),
        'owner_id': v['owner_id'] ?? '',
        'distanceKm': 0.0,
      }).toList();

      setState(() {
        _venueData = venues;
        _isLoading = false;
      });
      _animController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredData {
    if (widget.selectedCategory == 'All') return _venueData;
    final categoryMap = {
      'Halls': 'hall',
      'Marquees': 'marquee',
      'Palaces': 'palace',
      'Farmhouses': 'farmhouse',
    };
    final typeFilter = categoryMap[widget.selectedCategory];
    if (typeFilter == null) return _venueData;
    return _venueData
        .where((v) => v['type'].toString().toLowerCase() == typeFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trending Venues', style: theme.textTheme.titleMedium),
                  Text(
                    '${filtered.length} venues in Gujranwala',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
        if (_isLoading)
          _buildSkeletonGrid()
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.location_city_outlined,
                      size: 56, color: AppTheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text('No ${widget.selectedCategory} venues found',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Try a different category or expand your search area',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return _buildAnimatedVenueCard(index, filtered[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedVenueCard(int index, Map<String, dynamic> venue) {
    final delay = (index * 80).clamp(0, 400);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _VenueCardWidget(venue: venue),
    );
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const VenueCardSkeletonWidget(),
      ),
    );
  }
}

class _VenueCardWidget extends StatefulWidget {
  final Map<String, dynamic> venue;
  const _VenueCardWidget({required this.venue});

  @override
  State<_VenueCardWidget> createState() => _VenueCardWidgetState();
}

class _VenueCardWidgetState extends State<_VenueCardWidget> {
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _checkFavourite();
  }

  Future<void> _checkFavourite() async {
    try {
      final res = await ApiClient.get('/venues/favourites');
      final ids = (res['venues'] as List).map((v) => v['id'].toString()).toList();
      if (mounted) setState(() => _isFavorited = ids.contains(widget.venue['id']));
    } catch (_) {}
  }

  Future<void> _toggleFavourite() async {
    try {
      await ApiClient.post('/venues/${widget.venue['id']}/favourite', {});
      setState(() => _isFavorited = !_isFavorited);
    } catch (_) {}
  }

  void _openVenueDetail() async {
    final venue = widget.venue;
    final user = await UserService.getUser();
    final currentUserId = user?.id ?? '';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueDetailScreen(
          venue: {
            'id': venue['id'],
            'name': venue['name'],
            'location': '${venue['area']}, ${venue['city']}',
            'type': venue['type'],
            'capacity': venue['capacity'],
            'price': venue['pricePerDay'].toInt(),
            'rating': venue['rating'],
            'reviews': venue['reviewCount'],
            'owner_id': venue['owner_id'],
            'image': venue['imageUrl'],
            'images': venue['images'],
            // ── raw numeric fields for dynamic price-tier + menu widgets ──
            'base_price': venue['pricePerDay'],
            'max_capacity': venue['capacity'],
            'min_capacity': venue['minCapacity'],
            'standard_menu_price': venue['standardMenuPrice'],
            'premium_menu_price': venue['premiumMenuPrice'],
            // ────────────────────────────────────────────────────────────
          },
          currentUserId: currentUserId,
          onBook: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final venue = widget.venue;

    return GestureDetector(
      onTap: _openVenueDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CustomImageWidget(
                      imageUrl: venue['imageUrl'],
                      fit: BoxFit.cover,
                      semanticLabel: venue['semanticLabel'],
                    ),
                  ),
                  if (!venue['isAvailable'])
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(115),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Booked',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavourite(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          size: 16,
                          color: _isFavorited
                              ? AppTheme.primary
                              : AppTheme.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
                  if (venue['isFeatured'])
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '✦ Featured',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue['name'],
                      style:
                          theme.textTheme.titleSmall?.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 10, color: AppTheme.onSurfaceMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${venue['area']}, ${venue['city']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10, color: AppTheme.onSurfaceMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 10, color: AppTheme.onSurfaceMuted),
                        const SizedBox(width: 2),
                        Text('${venue['capacity']} guests',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 10)),
                        const Spacer(),
                        const Icon(Icons.star_rounded,
                            size: 11, color: Color(0xFFFFB300)),
                        const SizedBox(width: 2),
                        Text(
                          venue['rating'].toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface),
                        ),
                        Text(
                          ' (${venue['reviewCount']})',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9, color: AppTheme.onSurfaceMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PKR ${_formatPrice(venue['pricePerDay'])}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              Text('per day',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontSize: 9)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _openVenueDetail,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: venue['isAvailable']
                                  ? AppTheme.primary
                                  : AppTheme.outlineVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              venue['isAvailable'] ? 'Book' : 'Notify',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 100000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}