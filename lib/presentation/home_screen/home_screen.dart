import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import './widgets/home_category_row_widget.dart';
import './widgets/home_featured_banner_widget.dart';
import './widgets/home_trending_venues_widget.dart';
import '../../core/services/api_client.dart';
import '../../core/services/user_service.dart';
import '../customer/notifications_screen.dart';
import '../customer/venues_screen.dart';
import '../customer/venues_map_all_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToVenues;
  final void Function(int tabIndex)? onNavigateToTab;
  const HomeScreen({super.key, this.onNavigateToVenues, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  String _selectedCategory = 'All';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await ApiClient.get('/notifications');
      if (mounted) setState(() => _unreadCount = res['unread_count'] ?? 0);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          onNavigate: widget.onNavigateToTab,
        ),
      ),
    );
    _loadUnreadCount();
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: isTablet ? _buildTabletLayout(theme) : _buildPhoneLayout(theme),
      ),
      floatingActionButton: _buildAiFab(theme),
    );
  }

  Widget _buildPhoneLayout(ThemeData theme) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 800));
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(theme)),
          SliverToBoxAdapter(
            child: HomeCategoryRowWidget(
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
            ),
          ),
          SliverToBoxAdapter(
            child: HomeFeaturedBannerWidget(
              onNavigateToVenues: widget.onNavigateToVenues,
            ),
          ),
          SliverToBoxAdapter(
            child: HomeTrendingVenuesWidget(
              selectedCategory: _selectedCategory,
              crossAxisCount: 2,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _buildHeader(theme),
              HomeCategoryRowWidget(
                selectedCategory: _selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),
            ],
          ),
        ),
        Container(width: 1, color: AppTheme.outlineVariant),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {},
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HomeFeaturedBannerWidget(
                    onNavigateToVenues: widget.onNavigateToVenues,
                  ),
                ),
                SliverToBoxAdapter(
                  child: HomeTrendingVenuesWidget(
                    selectedCategory: _selectedCategory,
                    crossAxisCount: 3,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Gujranwala, Punjab',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.primary),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Find Your ',
                        style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.onSurface),
                      ),
                      TextSpan(
                        text: 'Perfect Venue',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AllVenuesMapScreen()),
                ),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.outlineVariant, width: 1),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    size: 22,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              InkWell(
                onTap: _openNotifications,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.outlineVariant, width: 1),
                  ),
                  child: Icon(
                    _unreadCount > 0
                        ? Icons.notifications_rounded
                        : Icons.notifications_outlined,
                    size: 22,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: _unreadCount < 10 ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: _unreadCount >= 10 ? BorderRadius.circular(8) : null,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiFab(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.extended(
        onPressed: () => _showAiAssistantSheet(theme),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
        label: Text(
          'AI Assistant',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAiAssistantSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AiAssistantSheet(),
    );
  }
}



class _AiAssistantSheet extends StatefulWidget {
  @override
  State<_AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<_AiAssistantSheet> {
  final _queryController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  bool _hasSearched = false;
  String? _error;
  String _currentUserId = '';

  final List<String> _suggestions = [
    'Wedding for 500 guests under PKR 5 lakhs',
    'Best rated venues',
    'Corporate event with A/C and catering',
    'Farmhouses for 200 guests',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = await UserService.getUser();
    if (mounted) setState(() => _currentUserId = user?.id ?? '');
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations({String? chipQuery}) async {
    final query = chipQuery ?? _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() { _isLoading = true; _error = null; _results = []; });
    try {
      final res = await ApiClient.post('/ai/recommendations', {
        'query': query,
        'event_type': '',
        'budget': 0,
        'guest_count': 0,
      });
      final list = (res['recommendations'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() { _results = list; _hasSearched = true; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = 'Could not get recommendations. Try again.';
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
            const SizedBox(height: 16),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(102),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text('VenueMate AI', style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              'Describe your event and I\'ll find the best venues',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (!_hasSearched) ...[
                    Text(
                      'Try a suggestion or describe your event below:',
                      style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.onSurfaceMuted),
                    ),
                    const SizedBox(height: 10),
                    ..._suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _getRecommendations(chipQuery: s),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_outlined, size: 16, color: AppTheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.onSurfaceMuted),
                            ],
                          ),
                        ),
                      ),
                    )).toList(),
                  ],
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Finding best venues for you...', style: TextStyle(color: AppTheme.onSurfaceMuted)),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error!, style: const TextStyle(color: AppTheme.error), textAlign: TextAlign.center),
                    ),
                  if (_hasSearched && !_isLoading && _results.isEmpty && _error == null)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Text(
                        'No matching venues found. Try different criteria.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.onSurfaceMuted),
                      ),
                    ),
                  if (_results.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text('AI Recommendations', style: theme.textTheme.titleSmall),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {
                            _hasSearched = false;
                            _results = [];
                            _queryController.clear();
                          }),
                          child: const Text('Search Again'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._results.asMap().entries.map((entry) {
                      final i = entry.key;
                      final v = entry.value;
                      return GestureDetector(
                        onTap: () async {
                          try {
                            final res = await ApiClient.get('/venues/${v['id']}');
                            final full = res['venue'];
                            if (full == null) return;
                            final venue = {
                              'id': v['id'],
                              'name': full['name'] ?? v['name'],
                              'location': full['location']?['area'] ?? v['area'] ?? '',
                              'type': full['type'] ?? v['type'],
                              'capacity': full['capacity']?['max'] ?? v['max_capacity'],
                              'price': full['pricing']?['base_per_day'] ?? v['price_per_day'],
                              'rating': full['rating'] ?? v['rating'],
                              'reviews': full['review_count'] ?? v['reviews'],
                              'owner_id': full['owner_id'] ?? '',
                              'image': v['image'] ?? '',
                              'images': (full['media'] as List?)
                                      ?.map((m) => m['url'].toString())
                                      .toList() ??
                                  [v['image'] ?? ''],
                              // ── raw numeric fields for dynamic price-tier + menu widgets ──
                              'base_price': (full['pricing']?['base_per_day'] ?? 0).toDouble(),
                              'max_capacity': (full['capacity']?['max'] ?? 0) as int,
                              'min_capacity': (full['capacity']?['min'] ?? 1) as int,
                              'standard_menu_price': (full['pricing']?['standard_menu_per_head'] ?? 0).toDouble(),
                              'premium_menu_price': (full['pricing']?['premium_menu_per_head'] ?? 0).toDouble(),
                              // ────────────────────────────────────────────────────────────
                            };
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VenueDetailScreen(
                                    venue: venue,
                                    currentUserId: _currentUserId,
                                    // onBook intentionally omitted (defaults to null) so
                                    // VenueDetailScreen uses its own _BookingScreen with
                                    // the price-tier + menu widgets, instead of a no-op.
                                  ),
                                ),
                              );
                            }
                          } catch (_) {}
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: i == 0
                                ? Border.all(color: AppTheme.primary, width: 2)
                                : Border.all(color: AppTheme.outlineVariant),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (v['image'] != null && v['image'].toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                  child: CustomImageWidget(
                                    imageUrl: v['image'],
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (i == 0)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'Best Match',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(v['name'] ?? '', style: theme.textTheme.titleSmall),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withAlpha(25),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${v['match_score']}% match',
                                            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 12, color: AppTheme.onSurfaceMuted),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${v['area']}, ${v['city']}',
                                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceMuted),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB300)),
                                        const SizedBox(width: 2),
                                        Text('${v['rating']}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLighter,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              v['reason'] ?? '',
                                              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primary, height: 1.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          'PKR ${v['price_per_day']}',
                                          style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700),
                                        ),
                                        Text('/day', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceMuted)),
                                        const Spacer(),
                                        Text('${v['min_capacity']}–${v['max_capacity']} guests', style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            if (!_hasSearched)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        decoration: InputDecoration(
                          hintText: 'Describe your event...',
                          filled: true,
                          fillColor: AppTheme.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _getRecommendations,
                      child: Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}