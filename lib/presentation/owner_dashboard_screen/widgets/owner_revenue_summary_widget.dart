import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/api_client.dart';

class OwnerRevenueSummaryWidget extends StatefulWidget {
  const OwnerRevenueSummaryWidget({super.key});

  @override
  State<OwnerRevenueSummaryWidget> createState() =>
      _OwnerRevenueSummaryWidgetState();
}

class _OwnerRevenueSummaryWidgetState
    extends State<OwnerRevenueSummaryWidget> {
  bool _isLoading = true;
  int _totalRevenue = 0;
  List<Map<String, dynamic>> _breakdown = [];

  final List<Color> _colors = const [
    Color(0xFFE91E8C),
    Color(0xFF1565C0),
    Color(0xFFF57C00),
    Color(0xFF2E7D32),
  ];

  @override
  void initState() {
    super.initState();
    _loadRevenue();
  }

  Future<void> _loadRevenue() async {
    try {
      final res = await ApiClient.get('/dashboard/owner/stats');
      final total = (res['total_revenue'] ?? 0) as int;
      setState(() {
        _totalRevenue = total;
        _breakdown = [
          {
            'label': 'Hall Bookings',
            'amount': total,
            'percent': 100.0,
          }
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatRevenue(int amount) {
    if (amount >= 100000) {
      return 'PKR ${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return 'PKR ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'PKR $amount';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Revenue Summary',
                  style: theme.textTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLighter,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'All Time',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.primaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Revenue',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatRevenue(_totalRevenue),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_totalRevenue == 0)
                    Text(
                      'No revenue yet',
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
}