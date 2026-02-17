import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PlanViewChart extends StatelessWidget {
  final List<PlanPoint> points;

  const PlanViewChart({
    super.key,
    required this.points,
  });

  // Sample data if points are empty
  static final List<PlanPoint> demoPoints = [
    PlanPoint(-800, -1000),
    PlanPoint(-600, -800),
    PlanPoint(-400, -650),
    PlanPoint(-200, -550),
    PlanPoint(0, -500),
    PlanPoint(100, -480),
    PlanPoint(200, -460),
    PlanPoint(200, -300),
    PlanPoint(150, -150),
    PlanPoint(100, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;
        final isMediumScreen = constraints.maxWidth < 1200;
        
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
                    Icon(Icons.map, size: 20, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Plan View - Well Trajectory",
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
                    border: Border.all(color: Colors.grey.shade200),
                ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppTheme.infoColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "East-West vs North-South coordinates of well trajectory",
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          "Scale: 1:2000",
                          style: AppTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= CHART CONTAINER =================
                Container(
                  height: isSmallScreen
                      ? 350
                      : isMediumScreen
                        ? 450
                        : 500,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: LineChart(
                    _chartData(
                      isSmallScreen: isSmallScreen,
                      isMediumScreen: isMediumScreen,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= COORDINATE LEGEND =================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _coordinateInfo("Start Point", "-800, -1000"),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _coordinateInfo("Kick-off Point", "-400, -650"),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _coordinateInfo("Target", "100, 0"),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ================= QUADRANT INDICATOR =================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.compass_calibration, size: 16, color: AppTheme.infoColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Coordinates: E+/W- (East-West), N+/S- (North-South)",
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.infoColor,
                          ),
                        ),
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

  Widget _coordinateInfo(String label, String coordinates) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          coordinates,
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  LineChartData _chartData({
    bool isSmallScreen = false,
    bool isMediumScreen = false,
  }) {
    final currentPoints = points.isNotEmpty ? points : demoPoints;
    
    return LineChartData(
      backgroundColor: Colors.white,

      // ================= GRID =================
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
        horizontalInterval: isSmallScreen ? 200 : 250,
        verticalInterval: isSmallScreen ? 200 : 250,
      ),

      // ================= AXES =================
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              "N+/S- (ft)",
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            interval: isSmallScreen ? 200 : 250,
            reservedSize: isSmallScreen ? 30 : 40,
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
              "E+/W- (ft)",
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          axisNameSize: 20,
          sideTitles: SideTitles(
            showTitles: true,
            interval: isSmallScreen ? 200 : 250,
            reservedSize: isSmallScreen ? 28 : 32,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      // ================= BORDER =================
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),

      // ================= LIMITS =================
      minX: -900,
      maxX: 300,
      minY: -1100,
      maxY: 100,

      // ================= LINES =================
      lineBarsData: [
        // Main well trajectory line
        LineChartBarData(
          spots: currentPoints.map((e) => FlSpot(e.ew, e.ns)).toList(),
          isCurved: true,
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: isSmallScreen ? 2.5 : 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final isKeyPoint = index == 0 || 
                               index == currentPoints.length ~/ 2 || 
                               index == currentPoints.length - 1;
              
              return FlDotCirclePainter(
                radius: isKeyPoint ? 4 : 3,
                color: isKeyPoint ? AppTheme.primaryColor : AppTheme.secondaryColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.15),
                AppTheme.secondaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Reference lines (optional)
        LineChartBarData(
          spots: [
            FlSpot(-900, 0),
            FlSpot(300, 0),
          ],
          isCurved: false,
          color: Colors.grey.shade400,
          barWidth: 0.5,
          dashArray: [3, 3],
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: [
            FlSpot(0, -1100),
            FlSpot(0, 100),
          ],
          isCurved: false,
          color: Colors.grey.shade400,
          barWidth: 0.5,
          dashArray: [3, 3],
          dotData: const FlDotData(show: false),
        ),
      ],

      // ================= INTERACTION =================
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor:(spot) => AppTheme.primaryColor.withOpacity(0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              return LineTooltipItem(
                'E/W: ${touchedSpot.x.toInt()} ft\nN/S: ${touchedSpot.y.toInt()} ft',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              );
            }).toList();
          },
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          // Handle touch interactions if needed
        },
      ),

      // ================= EXTRA POINTS =================
      extraLinesData: ExtraLinesData(
        verticalLines: [
          VerticalLine(
            x: 0,
            color: Colors.grey.shade400,
            strokeWidth: 0.5,
            dashArray: [3, 3],
          ),
        ],
        horizontalLines: [
          HorizontalLine(
            y: 0,
            color: Colors.grey.shade400,
            strokeWidth: 0.5,
            dashArray: [3, 3],
          ),
        ],
      ),
    );
  }
}