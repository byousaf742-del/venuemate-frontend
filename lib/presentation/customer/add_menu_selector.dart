import 'package:flutter/material.dart';
import 'price_tier_selector.dart'; // reuses BookingColors + formatPkr

enum MenuOption { standard, premium }

class MenuChoice {
  final MenuOption option;
  final String name;
  final double pricePerHead;

  const MenuChoice({required this.option, required this.name, required this.pricePerHead});
}

/// Builds the Standard/Premium choices from the venue's owner-set prices.
List<MenuChoice> buildMenuChoices({required double standardPrice, required double premiumPrice}) => [
      MenuChoice(option: MenuOption.standard, name: 'Standard Menu', pricePerHead: standardPrice),
      MenuChoice(option: MenuOption.premium, name: 'Premium Menu', pricePerHead: premiumPrice),
    ];

/// "Add Menu" card: toggle to enable, then pick Standard or Premium.
/// Place this below the Event Time field. Prices come from the venue
/// (owner-set), not hardcoded.
class AddMenuSelector extends StatefulWidget {
  final double standardPricePerHead;
  final double premiumPricePerHead;
  final int? guestCount; // exact count typed by customer — never tier-rounded
  final bool initialEnabled;
  final MenuOption? initialSelection;
  final void Function(bool enabled, MenuChoice? selection)? onChanged;

  const AddMenuSelector({
    super.key,
    required this.standardPricePerHead,
    required this.premiumPricePerHead,
    this.guestCount,
    this.initialEnabled = false,
    this.initialSelection,
    this.onChanged,
  });

  @override
  State<AddMenuSelector> createState() => _AddMenuSelectorState();
}

class _AddMenuSelectorState extends State<AddMenuSelector> {
  late bool _enabled;
  MenuOption? _selected;
  late List<MenuChoice> _choices;

  @override
  void initState() {
    super.initState();
    _choices = buildMenuChoices(
      standardPrice: widget.standardPricePerHead,
      premiumPrice: widget.premiumPricePerHead,
    );
    _enabled = widget.initialEnabled;
    _selected = widget.initialSelection ?? (_enabled ? _choices.first.option : null);
  }

  void _notify() {
    final choice = _selected == null
        ? null
        : _choices.firstWhere((c) => c.option == _selected, orElse: () => _choices.first);
    widget.onChanged?.call(_enabled, _enabled ? choice : null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BookingColors.lightPinkBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Toggle to add food menu to booking',
                        style: TextStyle(color: BookingColors.grey, fontSize: 12.5)),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: BookingColors.pink,
                onChanged: (val) {
                  setState(() {
                    _enabled = val;
                    if (_enabled && _selected == null) _selected = _choices.first.option;
                  });
                  _notify();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final choice in _choices) ...[
            _MenuTile(
              choice: choice,
              enabled: _enabled,
              selected: _selected == choice.option,
              guestCount: widget.guestCount,
              onTap: _enabled
                  ? () {
                      setState(() => _selected = choice.option);
                      _notify();
                    }
                  : null,
            ),
            if (choice != _choices.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final MenuChoice choice;
  final bool enabled;
  final bool selected;
  final int? guestCount;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.choice,
    required this.enabled,
    required this.selected,
    required this.guestCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        !enabled ? const Color(0xFFE3E3E3) : (selected ? BookingColors.pink : BookingColors.border);
    final Color bg = !enabled ? const Color(0xFFF2F2F2) : BookingColors.cardBg;
    final Color textColor = !enabled ? const Color(0xFFB5B5B5) : Colors.black87;
    final Color subtitleColor = !enabled ? const Color(0xFFC2C2C2) : BookingColors.grey;

    final showTotal = enabled && selected && guestCount != null && guestCount! > 0;
    final total = choice.pricePerHead * (guestCount ?? 0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected && enabled ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(choice.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                      const SizedBox(height: 2),
                      Text('${formatPkr(choice.pricePerHead)} per head',
                          style: TextStyle(fontSize: 13, color: subtitleColor)),
                    ],
                  ),
                ),
                _RadioDot(selected: selected, enabled: enabled),
              ],
            ),
            if (showTotal) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: BookingColors.pink.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${formatPkr(total)} total for exactly $guestCount guests',
                  style: TextStyle(fontSize: 12, color: BookingColors.pink, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  final bool enabled;

  const _RadioDot({required this.selected, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = !enabled ? const Color(0xFFD5D5D5) : (selected ? BookingColors.pink : const Color(0xFFD5D5D5));
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
      child: selected && enabled
          ? Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(shape: BoxShape.circle, color: BookingColors.pink),
              ),
            )
          : null,
    );
  }
}
