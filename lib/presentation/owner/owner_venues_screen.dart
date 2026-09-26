import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import 'package:venuemate/core/services/api_client.dart';
import '../../widgets/venue_image_slider_widget.dart';
import 'package:venuemate/presentation/customer/venue_map_screen.dart';
import 'package:venuemate/presentation/owner/venue_availability_screen.dart';

class OwnerVenuesScreen extends StatefulWidget {
  const OwnerVenuesScreen({super.key});

  @override
  State<OwnerVenuesScreen> createState() => _OwnerVenuesScreenState();
}

class _OwnerVenuesScreenState extends State<OwnerVenuesScreen> {
  
  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = false;
  
  @override
  void initState() {
  super.initState();
  _loadVenues();
  }

  @override
void dispose() {
  super.dispose();
}

Future<void> _loadVenues() async {
  setState(() => _isLoading = true);
  try {
    final res = await ApiClient.get('/venues/mine');
    final venues = (res['venues'] as List).map((v) {
      return {
        'id': v['id'] ?? '',
        'name': v['name'] ?? '',
        'type': v['type'] ?? '',
        'location': v['location']?['address'] ?? '',
        'lat': ((v['location']?['coordinates'] as List?)?.elementAtOrNull(1) ?? 32.1877).toDouble(),
        'lng': ((v['location']?['coordinates'] as List?)?.elementAtOrNull(0) ?? 74.1945).toDouble(),
        'capacity': '${v['capacity']?['min'] ?? 0}–${v['capacity']?['max'] ?? 0}',
        'capacity_raw': v['capacity'] ?? {}, // raw {min, max} for edit form prefill
        'pricePerEvent': _formatAmount(v['pricing']?['base_per_day']),
        'pricing': v['pricing'] ?? {}, // raw pricing object (base_per_day, standard/premium menu prices)
        'status': v['is_verified'] == true ? 'active' : 'pending',
        'totalBookings': v['total_bookings'] ?? 0,
        'rating': (v['rating'] ?? 0.0).toDouble(),
        'reviews': v['review_count'] ?? 0,
        'revenue': '0',
        'image': (v['media'] != null && (v['media'] as List).isNotEmpty)
            ? v['media'][0]['url']
            : '',
        'images': (v['media'] != null && (v['media'] as List).isNotEmpty)
            ? (v['media'] as List).map((m) => m['url'].toString()).toList()
            : [],
        'semanticLabel': v['name'] ?? '',
        'pendingRequests': v['pending_requests'] ?? 0,
        'is_verified': v['is_verified'] ?? false,
      };
    }).toList();
    setState(() {
      _venues = venues;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
  child: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : _venues.isEmpty
    ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_city_outlined, size: 52, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No venues yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Tap Add Venue to list your first venue',
                style: theme.textTheme.bodySmall),
          ],
        ),
      )
    : ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _venues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _buildVenueCard(theme, _venues[i]),
      ),
      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVenueSheet(theme),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded, size: 20),
        label: Text(
          'Add Venue',
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
                Text('My Venues', style: theme.textTheme.headlineMedium),
                Text(
                  'Manage your venue listings',
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

  Widget _buildVenueCard(ThemeData theme, Map<String, dynamic> venue) {
    return Container(
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child:VenueImageSlider(
                images: (venue['images'] as List<dynamic>?)
                        ?.map((e) => e.toString()).toList() ??
                    [venue['image'] ?? ''],
                height: 160,
                semanticLabel: venue['semanticLabel'] ?? '',
              ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: venue['status'] == 'active'
                        ? AppTheme.successContainer
                        : AppTheme.warningContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: venue['status'] == 'active'
                              ? AppTheme.success
                              : AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        venue['status'] == 'active' ? 'Active' : 'Inactive',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: venue['status'] == 'active'
                              ? AppTheme.success
                              : AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (venue['pendingRequests'] > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${venue['pendingRequests']} Pending',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                      child: Text(
                        venue['name'],
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppTheme.gold,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${venue['rating']}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppTheme.onSurfaceMuted,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        venue['location'],
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statChip(
                      theme,
                      Icons.calendar_month_rounded,
                      '${venue['totalBookings']} bookings',
                      AppTheme.info,
                    ),
                    const SizedBox(width: 8),
                    _statChip(
                      theme,
                      Icons.people_outline_rounded,
                      venue['capacity'],
                      AppTheme.onSurfaceMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price/Event',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.onSurfaceMuted,
                              ),
                            ),
                            Text(
                              'PKR ${venue['pricePerEvent']}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppTheme.outlineVariant,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Revenue',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceMuted,
                                ),
                              ),
                              Text(
                                'PKR ${venue['revenue']}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditVenueSheet(theme, venue),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAvailabilitySheet(theme, venue),
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 15,
                        ),
                        label: const Text('Availability'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
    );
  }

  Widget _statChip(ThemeData theme, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVenueSheet(ThemeData theme) {
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final areaCtrl = TextEditingController();
  final minCapacityCtrl = TextEditingController();
  final maxCapacityCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final standardMenuCtrl = TextEditingController();
  final premiumMenuCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final facilitiesCtrl = TextEditingController();
  String selectedType = 'hall';
  List<String> uploadedImages = [];
  bool isUploading = false;
  bool isSubmitting = false;
  double selectedLat = 32.1877;
  double selectedLng = 74.1945;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
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
                    Text('Add New Venue', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [

                    // IMAGE UPLOAD
                    Text('Venue Photo', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFiles = await picker.pickMultiImage(
                          imageQuality: 80,
                          maxWidth: 1024,
                        );
                        if (pickedFiles.isEmpty) return;

                        setSheetState(() => isUploading = true);

                        try {
                          for (final picked in pickedFiles) {
                            final bytes = await picked.readAsBytes();
                            final base64Image = base64Encode(bytes);

                            final res = await ApiClient.post('/venues/upload-image-base64', {
                              'image': base64Image,
                              'filename': picked.name,
                            });
                            uploadedImages.add(res['url']);
                          }

                          setSheetState(() => isUploading = false);
                        } catch (e) {
                          print('Image upload error: $e');
                          setSheetState(() => isUploading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Some images failed to upload.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.outlineVariant),
                        ),
                        child: isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : uploadedImages.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_rounded,
                                  size: 40, color: AppTheme.primary),
                              const SizedBox(height: 8),
                              Text('Tap to upload venue photos (multiple)',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.onSurfaceMuted)),
                            ],
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: PageView.builder(
                                  itemCount: uploadedImages.length,
                                  itemBuilder: (_, i) => uploadedImages[i].startsWith('data:image')
                                    ? Image.memory(
                                        base64Decode(uploadedImages[i].split(',')[1]),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Image.network(
                                        uploadedImages[i],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                ),
                              ),
                              Positioned(
                                bottom: 8, right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${uploadedImages.length} photos',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // VENUE TYPE
                    Text('Venue Type', style: theme.textTheme.titleSmall),
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
                          value: selectedType,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'hall', child: Text('Marriage Hall')),
                            DropdownMenuItem(value: 'marquee', child: Text('Marquee')),
                            DropdownMenuItem(value: 'palace', child: Text('Palace')),
                            DropdownMenuItem(value: 'farmhouse', child: Text('Farmhouse')),
                          ],
                          onChanged: (val) => setSheetState(() => selectedType = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // BASIC INFO
                    _addVenueField('Venue Name', 'e.g. Royal Palace Hall',
                        Icons.business_rounded, nameCtrl),
                    const SizedBox(height: 14),
                    _addVenueField('Description', 'Describe your venue...',
                        Icons.description_outlined, descCtrl, maxLines: 3),
                    const SizedBox(height: 14),

                    // LOCATION
                    Text('Location', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _addVenueField('Full Address', 'e.g. Main GT Road, Kangni Wala',
                        Icons.location_on_outlined, addressCtrl),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _addVenueField('City', 'Gujranwala',
                            Icons.location_city_rounded, cityCtrl)),
                        const SizedBox(width: 10),
                        Expanded(child: _addVenueField('Area', 'Satellite Town',
                            Icons.map_outlined, areaCtrl)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                        this.context,
                        MaterialPageRoute(
                          builder: (_) => LocationPickerScreen(
                            initialLat: selectedLat,
                            initialLng: selectedLng,
                          ),
                        ),
                      );
                      if (result != null) {
                        setSheetState(() {
                          selectedLat = result['point'].latitude;
                          selectedLng = result['point'].longitude;
                          if ((result['address'] as String).isNotEmpty) {
                            addressCtrl.text = result['address'];
                          }
                        });
                      }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLighter,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.primary.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_rounded,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedLat == 32.1877 && selectedLng == 74.1945
                                    ? 'Pick Location on Map'
                                    : 'Location: ${selectedLat.toStringAsFixed(4)}, ${selectedLng.toStringAsFixed(4)}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 12, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // CAPACITY
                    Text('Guest Capacity', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _addVenueField('Min Guests', '100',
                            Icons.people_outline_rounded, minCapacityCtrl,
                            keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: _addVenueField('Max Guests', '1000',
                            Icons.people_rounded, maxCapacityCtrl,
                            keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    
                    _addVenueField('Price Per Day (PKR)', 'e.g. 150000',
                        null, priceCtrl, 
                        keyboardType: TextInputType.number, prefixText: 'Rs  '),
                    const SizedBox(height: 14),

                    // MENU PRICING
                    Text('Menu Pricing (per head)', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _addVenueField('Standard Menu', 'e.g. 1400',
                            Icons.restaurant_menu_rounded, standardMenuCtrl,
                            keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: _addVenueField('Premium Menu', 'e.g. 2200',
                            Icons.restaurant_rounded, premiumMenuCtrl,
                            keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    
                    _addVenueField('Facilities & Services', 'AC Halls, Parking, Catering...',
                        Icons.business_center_outlined, facilitiesCtrl),
                    const SizedBox(height: 24),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting ? null : () async {
                          if (nameCtrl.text.isEmpty ||
                              addressCtrl.text.isEmpty ||
                              priceCtrl.text.isEmpty ||
                              minCapacityCtrl.text.isEmpty ||
                              maxCapacityCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all required fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setSheetState(() => isSubmitting = true);

                          try {
                            final body = {
                              'name': nameCtrl.text.trim(),
                              'description': descCtrl.text.trim().isEmpty
                                  ? 'A venue in Gujranwala'
                                  : descCtrl.text.trim(),
                              'type': selectedType,
                              'location': {
                                'address': addressCtrl.text.trim(),
                                'city': cityCtrl.text.trim().isEmpty
                                    ? 'Gujranwala'
                                    : cityCtrl.text.trim(),
                                'area': areaCtrl.text.trim().isEmpty
                                    ? addressCtrl.text.trim()
                                    : areaCtrl.text.trim(),
                                'latitude': selectedLat,
                                'longitude': selectedLng,
                              },
                              'capacity': {
                                'min': int.tryParse(minCapacityCtrl.text) ?? 100,
                                'max': int.tryParse(maxCapacityCtrl.text) ?? 1000,
                              },
                              'pricing': {
                                'base_per_day': int.tryParse(priceCtrl.text) ?? 0,
                                'advance_percent': 30,
                                'peak_multiplier': 1.5,
                                'standard_menu_per_head': int.tryParse(standardMenuCtrl.text) ?? 0,
                                'premium_menu_per_head': int.tryParse(premiumMenuCtrl.text) ?? 0,
                              },
                              'facilities': facilitiesCtrl.text.isEmpty
                                  ? []
                                  : facilitiesCtrl.text
                                      .split(',')
                                      .map((s) => s.trim())
                                      .where((s) => s.isNotEmpty)
                                      .toList(),
                            };

                            final res = await ApiClient.post('/venues', body);

                           if (uploadedImages.isNotEmpty && res['venue_id'] != null) {
                                await ApiClient.put('/venues/${res['venue_id']}', {
                                  'media': uploadedImages.asMap().entries.map((e) => {
                                    'url': e.value,
                                    'type': 'image',
                                    'is_primary': e.key == 0,
                                  }).toList(),
                                });
                              }

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Venue submitted! Admin will verify within 24 hours.'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                              _loadVenues();
                            }
                          } catch (e) {
                            setSheetState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to add venue. Try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.add_business_rounded, size: 18),
                        label: Text(isSubmitting ? 'Submitting...' : 'Submit for Review'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _addVenueField(
  String label,
  String hint,
  IconData? icon,
  TextEditingController ctrl, {
  TextInputType? keyboardType,
  int maxLines = 1,
  String? prefixText,
}) {
  return TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    maxLines: maxLines,
    style: GoogleFonts.plusJakartaSans(fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: AppTheme.primary) : null,
      prefixText: prefixText,
      prefixStyle: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppTheme.onSurface,
      ),
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
  }

  void _showEditVenueSheet(ThemeData theme, Map<String, dynamic> venue) {
  final nameCtrl = TextEditingController(text: venue['name']);
  final priceCtrl = TextEditingController(
      text: venue['pricePerEvent'].toString().replaceAll(',', ''));
  final standardMenuCtrl = TextEditingController(
      text: (venue['pricing']?['standard_menu_per_head'] ?? '').toString());
  final premiumMenuCtrl = TextEditingController(
      text: (venue['pricing']?['premium_menu_per_head'] ?? '').toString());
  final addressCtrl = TextEditingController(text: venue['location']);
  final minCapacityCtrl = TextEditingController(
      text: (venue['capacity_raw']?['min'] ?? '').toString());
  final maxCapacityCtrl = TextEditingController(
      text: (venue['capacity_raw']?['max'] ?? '').toString());
  bool isActive = venue['status'] == 'active';
  bool isSubmitting = false;
  bool isUploading = false;
  double selectedLat = (venue['lat'] ?? 32.1877).toDouble();
  double selectedLng = (venue['lng'] ?? 74.1945).toDouble();
  List<String> currentImages = List<String>.from(
    (venue['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
    (venue['image'] != null && venue['image'].toString().isNotEmpty
        ? [venue['image'].toString()]
        : []),
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Text('Edit Venue',
                        style: theme.textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [

                    // CURRENT PHOTOS
                    Text('Venue Photos',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),

                    if (currentImages.isNotEmpty) ...[
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: currentImages.length,
                          itemBuilder: (_, i) => Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 90,
                                height: 90,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CustomImageWidget(
                                    imageUrl: currentImages[i],
                                    fit: BoxFit.cover,
                                    width: 90,
                                    height: 90,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () => setSheetState(
                                      () => currentImages.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFiles = await picker.pickMultiImage(
                          imageQuality: 80,
                          maxWidth: 1024,
                        );
                        if (pickedFiles.isEmpty) return;
                        setSheetState(() => isUploading = true);
                        try {
                          for (final picked in pickedFiles) {
                            final bytes = await picked.readAsBytes();
                            final base64Image = base64Encode(bytes);
                            final res = await ApiClient.post(
                                '/venues/upload-image-base64', {
                              'image': base64Image,
                              'filename': picked.name,
                            });
                            currentImages.add(res['url']);
                          }
                          setSheetState(() => isUploading = false);
                        } catch (e) {
                          setSheetState(() => isUploading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Image upload failed.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary),
                        ),
                        child: isUploading
                            ? const Center(
                                child: CircularProgressIndicator())
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.add_photo_alternate_rounded,
                                      color: AppTheme.primary,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentImages.isEmpty
                                        ? 'Add Photos'
                                        : 'Add More Photos',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                            color: AppTheme.primary),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FIELDS
                    _addVenueField('Venue Name', '',
                        Icons.business_rounded, nameCtrl),
                    const SizedBox(height: 12),
                    _addVenueField('Price Per Day (PKR)', '',
                        null, priceCtrl,
                        keyboardType: TextInputType.number, prefixText: 'Rs  '),
                    const SizedBox(height: 12),
                      _addVenueField('Address', '',
                        Icons.location_on_outlined, addressCtrl),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          this.context,
                          MaterialPageRoute(
                            builder: (_) => LocationPickerScreen(
                              initialLat: selectedLat,
                              initialLng: selectedLng,
                            ),
                          ),
                        );
                        if (result != null) {
                          setSheetState(() {
                            selectedLat = result['point'].latitude;
                            selectedLng = result['point'].longitude;
                            if ((result['address'] as String).isNotEmpty) {
                              addressCtrl.text = result['address'];
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLighter,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.primary.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_rounded,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedLat == 32.1877 && selectedLng == 74.1945
                                    ? 'Pick Location on Map'
                                    : 'Location: ${selectedLat.toStringAsFixed(4)}, ${selectedLng.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 12, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text('Guest Capacity', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _addVenueField('Min Guests', '100',
                            Icons.people_outline_rounded, minCapacityCtrl,
                            keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: _addVenueField('Max Guests', '1000',
                            Icons.people_rounded, maxCapacityCtrl,
                            keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text('Menu Pricing (per head)', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _addVenueField('Standard Menu', 'e.g. 1400',
                            Icons.restaurant_menu_rounded, standardMenuCtrl,
                            keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: _addVenueField('Premium Menu', 'e.g. 2200',
                            Icons.restaurant_rounded, premiumMenuCtrl,
                            keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Text('Venue Active',
                              style: theme.textTheme.bodyMedium),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (v) =>
                              setSheetState(() => isActive = v),
                          activeColor: AppTheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final minCap = int.tryParse(minCapacityCtrl.text);
                                final maxCap = int.tryParse(maxCapacityCtrl.text);
                                if (minCap == null || maxCap == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter valid min and max guest capacity'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (maxCap < minCap) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Max guests must be greater than or equal to min guests'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                setSheetState(
                                    () => isSubmitting = true);
                                try {
                                  await ApiClient.put(
                                      '/venues/${venue['id']}', {
                                    'name': nameCtrl.text.trim(),
                                    'capacity': {
                                      'min': minCap,
                                      'max': maxCap,
                                    },
                                    'pricing': {
                                      'base_per_day': int.tryParse(
                                              priceCtrl.text
                                                  .replaceAll(',', '')) ??
                                          0,
                                      'advance_percent': 30,
                                      'peak_multiplier': 1.5,
                                      'standard_menu_per_head':
                                          int.tryParse(standardMenuCtrl.text) ?? 0,
                                      'premium_menu_per_head':
                                          int.tryParse(premiumMenuCtrl.text) ?? 0,
                                    },
                                    'location': {
                                      'address': addressCtrl.text.trim(),
                                      'city': 'Gujranwala',
                                      'area': addressCtrl.text.trim(),
                                      'latitude': selectedLat,
                                      'longitude': selectedLng,
                                    },
                                    'is_active': isActive,
                                    'media': currentImages
                                        .asMap()
                                        .entries
                                        .map((e) => {
                                              'url': e.value,
                                              'type': 'image',
                                              'is_primary': e.key == 0,
                                            })
                                        .toList(),
                                  });
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Venue updated successfully!'),
                                        backgroundColor: AppTheme.success,
                                      ),
                                    );
                                    _loadVenues();
                                  }
                                } catch (e) {
                                  setSheetState(
                                      () => isSubmitting = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Update failed. Try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Venue'),
                              content: Text(
                                  'Are you sure you want to delete "${venue['name']}"? This will remove all its bookings and data permanently.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ApiClient.delete('/venues/${venue['id']}');
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Venue deleted successfully'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                _loadVenues();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Delete failed. Try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Delete Venue',
                            style: TextStyle(color: Colors.red, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showAvailabilitySheet(ThemeData theme, Map<String, dynamic> venue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueAvailabilityScreen(
          venueId: venue['id'],
          venueName: venue['name'],
        ),
      ),
    );
  }
  }