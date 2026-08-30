import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/api_client.dart';

class OwnerKpiCardsWidget extends StatefulWidget {
  const OwnerKpiCardsWidget({super.key});

  @override
  State<OwnerKpiCardsWidget> createState() => _OwnerKpiCardsWidgetState();
}

class _OwnerKpiCardsWidgetState extends State<OwnerKpiCardsWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _kpis = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _loadKpis);
  }

  Future<void> _loadKpis() async {
    try {
      final res = await ApiClient.get('/dashboard/owner/stats');
      print('KPI response: $res');
      final kpiList = res['kpis'] as List;
      setState(() {
        _kpis = kpiList.asMap().entries.map((e) {
          final kpi = e.value as Map<String, dynamic>;
          final icons = [
            Icons.account_balance_wallet_rounded,
            Icons.event_available_rounded,
            Icons.gavel_rounded,
            Icons.star_rounded,
          ];
          final colors = [
            const Color(0xFFAD1457),
            const Color(0xFF1565C0),
            const Color(0xFFF57C00),
            const Color(0xFF2E7D32),
          ];
          final bgColors = [
            const Color(0xFFFCE4EC),
            const Color(0xFFE3F2FD),
            const Color(0xFFFFF3E0),
            const Color(0xFFE8F5E9),
          ];
          return {
            'title': kpi['title'],
            'value': kpi['value'],
            'subtitle': kpi['subtitle'],
            'icon': icons[e.key % icons.length],
            'color': colors[e.key % colors.length],
            'bgColor': bgColors[e.key % bgColors.length],
            'changePercent': (kpi['change_percent'] ?? 0).toDouble(),
            'isPositive': kpi['is_positive'] ?? true,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('KPI error type: ${e.runtimeType}');
      print('KPI error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (_isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_kpis.isEmpty) {
      return const SizedBox(
          height: 160,
          child: Center(child: Text('No data available')));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 4 : 2,
          childAspectRatio: isTablet ? 1.4 : 1.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _kpis.length,
        itemBuilder: (context, index) {
          return _buildKpiCard(theme, _kpis[index]);
        },
      ),
    );
  }

  Widget _buildKpiCard(ThemeData theme, Map<String, dynamic> kpi) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kpi['bgColor'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(kpi['icon'] as IconData,
                    size: 18, color: kpi['color'] as Color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (kpi['isPositive'] as bool)
                      ? AppTheme.successContainer
                      : AppTheme.warningContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (kpi['isPositive'] as bool)
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 10,
                      color: (kpi['isPositive'] as bool)
                          ? AppTheme.success
                          : AppTheme.warning,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${kpi['changePercent']}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: (kpi['isPositive'] as bool)
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kpi['value'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kpi['title'] as String,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            kpi['subtitle'] as String,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceMuted,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
