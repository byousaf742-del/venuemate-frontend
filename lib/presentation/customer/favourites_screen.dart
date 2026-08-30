import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:venuemate/core/services/user_service.dart';
import 'package:venuemate/presentation/customer/venues_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = true;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await UserService.getUser();
    if (mounted) setState(() => _currentUserId = user?.id ?? '');
    try {
      final res = await ApiClient.get('/venues/favourites');
      setState(() {
        _venues = List<Map<String, dynamic>>.from(
          (res['venues'] as List).map((v) => {
            'id': v['id'] ?? '',
            'name': v['name'] ?? '',
            'type': v['type'] ?? '',
            'location': v['location']?['address'] ?? '',
            'price': v['pricing']?['base_per_day'] ?? 0,
            'capacity': v['capacity']?['max'] ?? 0,
            'rating': (v['rating'] ?? 0.0).toDouble(),
            'reviews': v['review_count'] ?? 0,
            'owner_id': v['owner_id'] ?? '',
            'image': (v['media'] != null && (v['media'] as List).isNotEmpty)
                ? v['media'][0]['url']
                : '',
            'images': (v['media'] as List?)
                    ?.map((m) => m['url'].toString())
                    .toList() ??
                [],
          }),
        );
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavourite(String venueId) async {
    try {
      await ApiClient.post('/venues/$venueId/favourite', {});
      setState(() => _venues.removeWhere((v) => v['id'] == venueId));
    } catch (_) {}
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
        title: Text('My Favourites',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _venues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border_rounded,
                          size: 56, color: AppTheme.outlineVariant),
                      const SizedBox(height: 12),
                      Text('No saved venues yet',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: AppTheme.onSurfaceMuted)),
                      const SizedBox(height: 4),
                      Text('Tap the heart icon on any venue to save it',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.onSurfaceMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: _venues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _buildVenueTile(theme, _venues[i]),
                ),
    );
  }

  Widget _buildVenueTile(ThemeData theme, Map<String, dynamic> venue) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VenueDetailScreen(
            venue: venue,
            currentUserId: _currentUserId,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            if ((venue['image'] as String).isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: CustomImageWidget(
                  imageUrl: venue['image'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venue['name'],
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: AppTheme.onSurfaceMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(venue['location'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.onSurfaceMuted),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFFB300)),
                        const SizedBox(width: 2),
                        Text('${venue['rating']}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('PKR ${venue['price']}',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_rounded,
                  color: Colors.redAccent, size: 20),
              onPressed: () => _removeFavourite(venue['id']),
            ),
          ],
        ),
      ),
    );
  }
}
