import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import 'package:venuemate/core/services/api_client.dart';
import 'package:venuemate/core/services/user_service.dart';
import 'package:venuemate/presentation/customer/venues_screen.dart';

class AllVenuesMapScreen extends StatefulWidget {
  const AllVenuesMapScreen({super.key});

  @override
  State<AllVenuesMapScreen> createState() => _AllVenuesMapScreenState();
}

class _AllVenuesMapScreenState extends State<AllVenuesMapScreen> {
  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedVenue;
  String _currentUserId = '';
  final MapController _mapController = MapController();
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _loadUser();
    _getUserLocation();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getUser();
    if (mounted) setState(() => _currentUserId = user?.id ?? '');
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  Future<void> _loadVenues() async {
    try {
      final res = await ApiClient.get('/venues', params: {'limit': 100});
      final venues = (res['venues'] as List).where((v) {
        final coords = v['location']?['coordinates'];
        return coords != null &&
            coords is List &&
            coords.length == 2 &&
            coords[0] != 0 &&
            coords[1] != 0;
      }).map((v) {
        final coords = v['location']['coordinates'];
        return {
          'id': v['id'] ?? '',
          'name': v['name'] ?? '',
          'type': v['type'] ?? '',
          'location': v['location']?['address'] ?? '',
          'price': v['pricing']?['base_per_day'] ?? 0,
          'capacity': v['capacity']?['max'] ?? 0,
          // ── raw numeric fields for dynamic price-tier + menu widgets ──
          'base_price': (v['pricing']?['base_per_day'] ?? 0).toDouble(),
          'max_capacity': (v['capacity']?['max'] ?? 0) as int,
          'min_capacity': (v['capacity']?['min'] ?? 1) as int,
          'standard_menu_price': (v['pricing']?['standard_menu_per_head'] ?? 0).toDouble(),
          'premium_menu_price': (v['pricing']?['premium_menu_per_head'] ?? 0).toDouble(),
          // ────────────────────────────────────────────────────────────
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
          'lat': (coords[1] as num).toDouble(),
          'lng': (coords[0] as num).toDouble(),
        };
      }).toList();

      setState(() {
        _venues = venues;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _openVenueDetail(Map<String, dynamic> venue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueDetailScreen(
          venue: venue,
          currentUserId: _currentUserId,
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All Venues in Gujranwala',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text('${_venues.length} venues on map',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _venues.isNotEmpty
                        ? LatLng(_venues[0]['lat'], _venues[0]['lng'])
                        : const LatLng(32.1877, 74.1945),
                    initialZoom: 13,
                    onTap: (_, __) => setState(() => _selectedVenue = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.venuelink',
                    ),
                    MarkerLayer(
                      markers: _venues.map((venue) {
                        final isSelected = _selectedVenue?['id'] == venue['id'];
                        return Marker(
                          point: LatLng(venue['lat'], venue['lng']),
                          width: 140,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedVenue = venue);
                              _mapController.move(
                                LatLng(venue['lat'], venue['lng']),
                                14,
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(40),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: AppTheme.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    venue['name'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.location_on_rounded,
                                  color: AppTheme.primary,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_userLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withAlpha(80),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Selected venue card at bottom
                if (_selectedVenue != null)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _openVenueDetail(_selectedVenue!),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if ((_selectedVenue!['image'] as String).isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: CustomImageWidget(
                                  imageUrl: _selectedVenue!['image'],
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
                                    Text(
                                      _selectedVenue!['name'],
                                      style: theme.textTheme.titleSmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded,
                                            size: 12,
                                            color: AppTheme.onSurfaceMuted),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            _selectedVenue!['location'],
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color:
                                                        AppTheme.onSurfaceMuted),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            size: 13,
                                            color: Color(0xFFFFB300)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${_selectedVenue!['rating']}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w700),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'PKR ${_selectedVenue!['price']}',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'View Details',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}