import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../core/services/api_client.dart';

class OwnerBookingsChartWidget extends StatefulWidget {
  const OwnerBookingsChartWidget({super.key});

  @override
  State<OwnerBookingsChartWidget> createState() =>
      _OwnerBookingsChartWidgetState();
}

class _OwnerBookingsChartWidgetState
    extends State<OwnerBookingsChartWidget> {
  int _touchedIndex = -1;
  String _selectedPeriod = '6M';
  bool _isLoading = true;
  List<Map<String, dynamic>> _monthlyData = [];
  int _totalBookings = 0;

  final List<String> _periods = ['1M', '3M', '6M', '1Y'];

  @override
  void initState() {
    super.initState();
    _loadRevenue();
  }

  Future<void> _loadRevenue() async {
    try {
      final res = await ApiClient.get('/dashboard/owner/revenue');
      final monthly = res['monthly'] as List? ?? [];
      setState(() {
        _monthlyData = List<Map<String, dynamic>>.from(monthly);
        _totalBookings = _monthlyData.fold(
            0, (sum, m) => sum + ((m['bookings'] as int?) ?? 0));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Bookings',
                        style: theme.textTheme.titleMedium),
                    Text(
                      'Wedding & event season overview',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: _periods.map((p) {
                    final isSelected = _selectedPeriod == p;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPeriod = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          p,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.onSurfaceMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$_totalBookings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'Total bookings in selected period',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.onSurfaceMuted),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()))
          else if (_monthlyData.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text('No booking data yet',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceMuted)),
              ),
            )
          else
            SizedBox(
              height: isTablet ? 200 : 160,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.spot == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response.spot!.touchedBarGroupIndex;
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gi, rod, ri) {
                        if (gi >= _monthlyData.length) return null;
                        final d = _monthlyData[gi];
                        return BarTooltipItem(
                          '${d['month']}\n${d['bookings']} bookings',
                          GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= _monthlyData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _monthlyData[i]['month'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.onSurfaceMuted),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value % 5 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppTheme.onSurfaceMuted),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.outlineVariant,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  barGroups: List.generate(
                    _monthlyData.length,
                    (i) {
                      final isTouched = i == _touchedIndex;
                      final bookings =
                          (_monthlyData[i]['bookings'] as int)
                              .toDouble();
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: bookings,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                            gradient: LinearGradient(
                              colors: isTouched
                                  ? [
                                      AppTheme.primaryDark,
                                      AppTheme.primary
                                    ]
                                  : [
                                      AppTheme.primary.withAlpha(153),
                                      AppTheme.primary
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  maxY: _monthlyData.isEmpty
                      ? 10
                      : (_monthlyData
                                  .map((m) => m['bookings'] as int)
                                  .reduce((a, b) => a > b ? a : b)
                                  .toDouble() +
                              5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}