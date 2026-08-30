import 'package:flutter/material.dart';

/// A single pricing tier (computed, not stored).
class PriceTier {
  final String name;
  final int minGuests;
  final int maxGuests;
  final double multiplier;
  final double basePrice;

  const PriceTier({
    required this.name,
    required this.minGuests,
    required this.maxGuests,
    required this.multiplier,
    required this.basePrice,
  });

  double get price => basePrice * multiplier;

  bool matches(int guestCount) => guestCount >= minGuests && guestCount <= maxGuests;

  String get rangeLabel => '$minGuests – $maxGuests Guests';
}

/// Generates tiers from the owner-set base price, min capacity, and max
/// capacity. The first tier starts at [minCapacity] (base price, 1x) and
/// each subsequent 200-guest band's multiplier increases by 1.5 (1, 2.5,
/// 4, 5.5, 7, 8.5 ...) until the venue's max capacity is covered. Guest
/// counts below minCapacity or above maxCapacity fall outside every tier.
List<PriceTier> generatePriceTiers({
  required double basePrice,
  required int maxCapacity,
  int minCapacity = 1,
  int rangeSize = 200,
}) {
  final tiers = <PriceTier>[];
  if (basePrice <= 0 || maxCapacity <= 0 || minCapacity > maxCapacity) return tiers;

  int start = minCapacity < 1 ? 1 : minCapacity;
  int tierIndex = 0;
  while (start <= maxCapacity) {
    final end = (start + rangeSize - 1) > maxCapacity ? maxCapacity : (start + rangeSize - 1);
    final multiplier = 1 + (1.5 * tierIndex);
    tiers.add(PriceTier(
      name: 'Tier ${tierIndex + 1}',
      minGuests: start,
      maxGuests: end,
      multiplier: multiplier,
      basePrice: basePrice,
    ));
    start = end + 1;
    tierIndex++;
  }
  return tiers;
}

/// Finds the tier that a guest count falls into, if any.
PriceTier? findMatchingTier(List<PriceTier> tiers, int? guestCount) {
  if (guestCount == null) return null;
  for (final t in tiers) {
    if (t.matches(guestCount)) return t;
  }
  return null;
}

/// Rs. 1,25,000 style formatting used across the booking flow.
String formatPkr(double price) {
  final s = price.toStringAsFixed(0);
  if (s.length <= 3) return 'Rs. $s';
  final last3 = s.substring(s.length - 3);
  String rest = s.substring(0, s.length - 3);
  final regExp = RegExp(r'(\d)(?=(\d\d)+(?!\d))');
  rest = rest.replaceAllMapped(regExp, (m) => '${m[1]},');
  return 'Rs. $rest,$last3';
}

class BookingColors {
  static const pink = Color(0xFFE91E63);
  static const lightPinkBg = Color(0xFFFDF2F5);
  static const cardBg = Colors.white;
  static const border = Color(0xFFF0D9E0);
  static const grey = Color(0xFF8A8A8A);
}

/// Price tier container: place below the calendar. Give it the venue's
/// base price + max capacity (owner-set) and the guest count currently
/// typed in the Guest Count field — it generates and highlights tiers
/// automatically. Returns nothing itself; read the selected tier from
/// the parent using [generatePriceTiers] + [findMatchingTier] when needed
/// (e.g. at booking submit time), so this stays display-only and never
/// drifts from what the parent computes.
class PriceTierSelector extends StatelessWidget {
  final double basePrice;
  final int minCapacity;
  final int maxCapacity;
  final int? guestCount;

  const PriceTierSelector({
    super.key,
    required this.basePrice,
    required this.minCapacity,
    required this.maxCapacity,
    required this.guestCount,
  });

  @override
  Widget build(BuildContext context) {
    final tiers = generatePriceTiers(
      basePrice: basePrice,
      maxCapacity: maxCapacity,
      minCapacity: minCapacity,
    );

    if (tiers.isEmpty) return const SizedBox.shrink();

    final selectedTier = findMatchingTier(tiers, guestCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// TITLE
        Text(
          'Venue Price (Based on Guest Count)',
          style: TextStyle(
            color: BookingColors.pink,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 12),


        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: tiers.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final tier = tiers[index];

              final isSelected =
                  selectedTier != null &&
                  tier.name == selectedTier.name;

              return _TierCard(
                tier: tier,
                isSelected: isSelected,
              );
            },
          ),
        ),

        /// SELECTED TIER INFORMATION BELOW
        if (selectedTier != null && guestCount != null) ...[
          const SizedBox(height: 12),

          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: BookingColors.pink.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: BookingColors.pink.withOpacity(0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: BookingColors.pink,
                  size: 20,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have selected ${selectedTier.name} '
                        '(${selectedTier.rangeLabel})',
                        style: TextStyle(
                          color: BookingColors.pink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Your guest count of $guestCount falls in this tier. '
                        'You won\'t be charged for extra guests in this tier.',
                        style: TextStyle(
                          color: BookingColors.grey,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}


class _TierCard extends StatelessWidget {
  final PriceTier tier;
  final bool isSelected;

  const _TierCard({
    required this.tier,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 135,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? BookingColors.pink.withOpacity(0.07)
            : BookingColors.cardBg,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isSelected
              ? BookingColors.pink
              : BookingColors.border,
          width: isSelected ? 2 : 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_alt_rounded,
                color: BookingColors.pink,
                size: 25,
              ),

              const SizedBox(height: 7),

              Text(
                tier.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? BookingColors.pink
                      : Colors.black87,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                '${tier.minGuests}–${tier.maxGuests}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: BookingColors.grey,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Guests',
                style: TextStyle(
                  fontSize: 11,
                  color: BookingColors.grey,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                formatPkr(tier.price),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? BookingColors.pink
                      : Colors.black87,
                ),
              ),
            ],
          ),

          /// CHECK MARK WHEN SELECTED
          if (isSelected)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: BookingColors.pink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}