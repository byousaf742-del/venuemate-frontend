import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class HomeSearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;

  const HomeSearchBarWidget({super.key, required this.onSearch});

  @override
  State<HomeSearchBarWidget> createState() => _HomeSearchBarWidgetState();
}

class _HomeSearchBarWidgetState extends State<HomeSearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(31),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              onChanged: widget.onSearch,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search halls, marquees, palaces...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.onSurfaceMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                suffixIcon: InkWell(
                  onTap: () => _showFilterSheet(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLighter,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickFilter(
                  context,
                  Icons.location_on_outlined,
                  'Near Me',
                ),
                const SizedBox(width: 8),
                _buildQuickFilter(
                  context,
                  Icons.currency_rupee_rounded,
                  'Budget',
                ),
                const SizedBox(width: 8),
                _buildQuickFilter(
                  context,
                  Icons.people_outline_rounded,
                  'Capacity',
                ),
                const SizedBox(width: 8),
                _buildQuickFilter(
                  context,
                  Icons.event_available_outlined,
                  'Date',
                ),
                const SizedBox(width: 8),
                _buildQuickFilter(
                  context,
                  Icons.star_outline_rounded,
                  'Rating',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  RangeValues _budgetRange = const RangeValues(50000, 500000);
  RangeValues _capacityRange = const RangeValues(100, 1000);
  double _distanceRadius = 15;
  String _sortBy = 'Best Match';

  final List<String> _sortOptions = [
    'Best Match',
    'Nearest First',
    'Price: Low to High',
    'Price: High to Low',
    'Highest Rated',
    'Newest Listed',
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

  final Set<String> _selectedFacilities = {};

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
              width: 40,
              height: 4,
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
                    onPressed: () {
                      setState(() {
                        _budgetRange = const RangeValues(50000, 500000);
                        _capacityRange = const RangeValues(100, 1000);
                        _distanceRadius = 15;
                        _selectedFacilities.clear();
                      });
                    },
                    child: Text(
                      'Reset All',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
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
                  Text('Budget Range (PKR)', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${(_budgetRange.start / 1000).toStringAsFixed(0)}K',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'PKR ${(_budgetRange.end / 1000).toStringAsFixed(0)}K',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
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
                  Text('Guest Capacity', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_capacityRange.start.toInt()} guests',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_capacityRange.end.toInt()} guests',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
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
                  Text('Distance Radius', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${_distanceRadius.toInt()} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
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
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryLighter
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Facilities', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _facilities.map((facility) {
                      final isSelected = _selectedFacilities.contains(facility);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFacilities.remove(facility);
                            } else {
                              _selectedFacilities.add(facility);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.onSurface,
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
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
