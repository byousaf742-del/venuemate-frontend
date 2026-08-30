import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:venuemate/core/services/user_service.dart';
import 'package:venuemate/presentation/customer/venues_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class HomeFeaturedBannerWidget extends StatefulWidget {
  final VoidCallback? onNavigateToVenues;
  const HomeFeaturedBannerWidget({super.key, this.onNavigateToVenues});

  @override
  State<HomeFeaturedBannerWidget> createState() =>
      _HomeFeaturedBannerWidgetState();
}

class _HomeFeaturedBannerWidgetState extends State<HomeFeaturedBannerWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, dynamic>> _banners = [];
  bool _isLoadingBanners = true;

  @override
  void initState() {
    super.initState();
    _loadFeatured().then((_) => _startAutoPlay());
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _pageController.hasClients && _banners.isNotEmpty) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
        _startAutoPlay();
      }
    });
  }

  Future<void> _loadFeatured() async {
    try {
      final res = await ApiClient.get('/venues/featured');
      final venues = res['venues'] as List;
      if (venues.isEmpty) return;
      setState(() {
        _banners = venues.map((v) => {
          'title': v['name'] ?? '',
          'subtitle': '${v['location']?['area'] ?? ''}, ${v['location']?['city'] ?? ''}',
          'tag': v['badge'] ?? 'Featured',
          'discount': 'PKR ${_formatPrice(v['pricing']?['base_per_day'])}',
          'imageUrl': (v['media'] != null && (v['media'] as List).isNotEmpty)
              ? v['media'][0]['url']
              : 'https://images.unsplash.com/photo-1629307095660-d73f0cc2fb03',
          'semanticLabel': v['name'] ?? '',
          'id': v['id'] ?? '',
          'type': v['type'] ?? '',
          'location': '${v['location']?['area'] ?? ''}, ${v['location']?['city'] ?? ''}',
          'price': (v['pricing']?['base_per_day'] ?? 0),
          'capacity': v['capacity']?['max'] ?? 0,
          'minCapacity': v['capacity']?['min'] ?? 1,
          'standard_menu_price': (v['pricing']?['standard_menu_per_head'] ?? 0).toDouble(),
          'premium_menu_price': (v['pricing']?['premium_menu_per_head'] ?? 0).toDouble(),
          'rating': (v['rating'] ?? 0.0).toDouble(),
          'reviews': v['review_count'] ?? 0,
          'owner_id': v['owner_id'] ?? '',
          'images': (v['media'] != null && (v['media'] as List).isNotEmpty)
              ? (v['media'] as List).map((m) => m['url'].toString()).toList()
              : <String>[],
        }).toList();
        _isLoadingBanners = false;
      });
    } catch (e) {
      setState(() => _isLoadingBanners = false);
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final p = price as int;
    if (p >= 100000) return '${(p / 1000).toStringAsFixed(0)}K';
    return p.toString();
  }

  void _openVenueDetail(Map<String, dynamic> banner) async {
    final user = await UserService.getUser();
    final currentUserId = user?.id ?? '';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueDetailScreen(
          venue: {
            'id': banner['id'],
            'name': banner['title'],
            'location': banner['location'],
            'type': banner['type'],
            'capacity': banner['capacity'],
            'price': banner['price'],
            'rating': banner['rating'],
            'reviews': banner['reviews'],
            'owner_id': banner['owner_id'],
            'image': banner['imageUrl'],
            'images': banner['images'],
            // ── raw numeric fields for dynamic price-tier + menu widgets ──
            'base_price': (banner['price'] ?? 0).toDouble(),
            'max_capacity': (banner['capacity'] ?? 0) as int,
            'min_capacity': (banner['minCapacity'] ?? 1) as int,
            'standard_menu_price': (banner['standard_menu_price'] ?? 0).toDouble(),
            'premium_menu_price': (banner['premium_menu_price'] ?? 0).toDouble(),
            // ────────────────────────────────────────────────────────────
          },
          currentUserId: currentUserId,
          onBook: null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Text('Featured Venues', style: theme.textTheme.titleMedium),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onNavigateToVenues?.call(),
                child: Text(
                  'View All',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingBanners)
          const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_banners.isEmpty)
          const SizedBox(
              height: 200,
              child: Center(child: Text('No featured venues')))
        else
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 20 : 8,
                    right: index == _banners.length - 1 ? 20 : 8,
                  ),
                  child: _buildBannerCard(theme, banner),
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? AppTheme.primary
                    : AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(ThemeData theme, Map<String, dynamic> banner) {
    return GestureDetector(
      onTap: () => _openVenueDetail(banner),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomImageWidget(
                imageUrl: banner['imageUrl'] as String,
                fit: BoxFit.cover,
                semanticLabel: banner['semanticLabel'] as String,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(179)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    banner['tag'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    banner['discount'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      banner['subtitle'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(217),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}