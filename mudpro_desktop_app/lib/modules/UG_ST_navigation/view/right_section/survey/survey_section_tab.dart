import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SectionViewChart extends StatelessWidget {
  final List<SectionPoint> points;

  const SectionViewChart({
    super.key,
    required this.points,
  });

  // Demo data for the chart
  static final List<SectionPoint> demoPoints = [
    SectionPoint(0, 0),
    SectionPoint(1000, 500),
    SectionPoint(2000, 1200),
    SectionPoint(3000, 2100),
    SectionPoint(4000, 3200),
    SectionPoint(5000, 4500),
    SectionPoint(6000, 6000),
    SectionPoint(7000, 7700),
    SectionPoint(8000, 9600),
    SectionPoint(9000, 11700),
    SectionPoint(10000, 14000),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: ScrollController(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                Row(
                  children: [
                    Icon(Icons.show_chart, size: 20, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Section View",
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${(points.isNotEmpty ? points : demoPoints).length} points",
                        style: AppTheme.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ================= CHART INFO =================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Well Trajectory: Horizontal Displacement vs True Vertical Depth",
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= CHART CONTAINER =================
                Container(
                  height: isSmallScreen ? 300 : 400, // Smaller height for chart
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: LineChart(
                    _chartData(isSmallScreen: isSmallScreen),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= LEGEND =================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Legend",
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Well Path",
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.successColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Target Depth",
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  LineChartData _chartData({bool isSmallScreen = false}) {
    return LineChartData(
      backgroundColor: Colors.white,

      // ================= GRID =================
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
        horizontalInterval: isSmallScreen ? 2000 : 2500,
        verticalInterval: isSmallScreen ? 2000 : 2500,
      ),

      // ================= AXIS =================
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              "TVD (ft)",
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: isSmallScreen ? 30 : 40,
            interval: isSmallScreen ? 2000 : 2500,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value.toInt().toString(),
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Horizontal Displacement (ft)",
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: isSmallScreen ? 28 : 32,
            interval: isSmallScreen ? 2000 : 2500,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  value.toInt().toString(),
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                )
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      // ================= BOUNDS =================
      minX: 0,
      maxX: 10000,
      minY: 0,
      maxY: 15000,

      // ================= BORDER =================
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),

      // ================= LINE =================
      lineBarsData: [
        LineChartBarData(
          spots: (points.isNotEmpty ? points : demoPoints)
              .map((e) => FlSpot(e.hd, e.tvd))
              .toList(),
          isCurved: true,
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.accentColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: AppTheme.primaryColor,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.accentColor.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        
        // Target depth indicator
        LineChartBarData(
          spots: [
            FlSpot(0, 12000),
            FlSpot(10000, 12000),
          ],
          isCurved: false,
          color: AppTheme.successColor.withOpacity(0.5),
          barWidth: 1,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
      ],

      // ================= EXTRA LINES =================
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => AppTheme.primaryColor.withOpacity(0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              return LineTooltipItem(
                'HD: ${touchedSpot.x.toInt()} ft\nTVD: ${touchedSpot.y.toInt()} ft',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}