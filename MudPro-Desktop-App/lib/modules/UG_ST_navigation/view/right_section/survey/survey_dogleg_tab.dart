import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DoglegChart extends StatelessWidget {
  final List<DoglegPoint> points;

  const DoglegChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;
        final isMediumScreen = constraints.maxWidth < 1200;
        
        final currentPoints = points.isNotEmpty ? points : _demoDoglegData();
        
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.elevatedCardDecoration.copyWith(
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                Row(
                  children: [
                    Icon(Icons.show_chart, size: 20, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Dogleg Severity Chart",
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
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Dogleg Severity",
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
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
                          "Dogleg Severity (°/100ft) vs Measured Depth (ft) - Shows directional wellbore curvature",
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
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.warningColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Max: ${_findMaxDogleg(currentPoints).toStringAsFixed(1)}°/100ft",
                              style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= CHART CONTAINER =================
                Container(
                  height: isSmallScreen 
                      ? 300 
                      : isMediumScreen 
                        ? 400 
                        : 500, // Increased height
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: const EdgeInsets.all(20), // Increased padding
                  child: LineChart(
                    _chartData(
                      points: currentPoints,
                      isSmallScreen: isSmallScreen,
                      isMediumScreen: isMediumScreen,
                      chartHeight: isSmallScreen ? 500 : isMediumScreen ? 600 : 700,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= DOGLEG SEVERITY INDICATOR =================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _doglegIndicator("Low", "0-2°/100ft", AppTheme.successColor),
                          _doglegIndicator("Medium", "2-4°/100ft", AppTheme.warningColor),
                          _doglegIndicator("High", "4-6°/100ft", AppTheme.errorColor),
                          _doglegIndicator("Critical", ">6°/100ft", Colors.red),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.successColor,
                              AppTheme.warningColor,
                              AppTheme.errorColor,
                              Colors.red,
                            ],
                            stops: const [0.0, 0.33, 0.66, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ================= STATISTICS BAR =================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.05),
                        AppTheme.secondaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                  ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem("Avg DLS", 
                        "${_calculateAverageDogleg(currentPoints).toStringAsFixed(1)}°/100ft",
                        Icons.trending_up
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _statItem("Max DLS", 
                        "${_findMaxDogleg(currentPoints).toStringAsFixed(1)}°/100ft",
                        Icons.warning
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _statItem("Min Depth", 
                        "${_findMinDepth(currentPoints).toInt()} ft",
                        Icons.vertical_align_top
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _statItem("Max Depth", 
                        "${_findMaxDepth(currentPoints).toInt()} ft",
                        Icons.vertical_align_bottom
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= DATA TABLE =================
                if (!isSmallScreen) _buildDataTable(currentPoints),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _doglegIndicator(String title, String range, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          range,
          style: AppTheme.caption.copyWith(
            fontSize: 9,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<DoglegPoint> points) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: AppTheme.tableHeaderDecoration,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "Point #",
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Measured Depth (ft)",
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Dogleg Severity (°/100ft)",
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Severity Level",
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Table Data
          ...List.generate(points.length, (index) {
            final point = points[index];
            final severityColor = _getSeverityColor(point.dogleg);
            final severityText = _getSeverityText(point.dogleg);
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: index.isOdd ? Colors.grey.shade50 : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      (index + 1).toString(),
                      style: AppTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      point.md.toStringAsFixed(0),
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      point.dogleg.toStringAsFixed(2),
                      style: AppTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: severityColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          severityText,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  double _findMaxDogleg(List<DoglegPoint> points) {
    if (points.isEmpty) return 0;
    return points.map((p) => p.dogleg).reduce((a, b) => a > b ? a : b);
  }

  double _calculateAverageDogleg(List<DoglegPoint> points) {
    if (points.isEmpty) return 0;
    final sum = points.map((p) => p.dogleg).reduce((a, b) => a + b);
    return sum / points.length;
  }

  double _findMinDepth(List<DoglegPoint> points) {
    if (points.isEmpty) return 0;
    return points.map((p) => p.md).reduce((a, b) => a < b ? a : b);
  }

  double _findMaxDepth(List<DoglegPoint> points) {
    if (points.isEmpty) return 0;
    return points.map((p) => p.md).reduce((a, b) => a > b ? a : b);
  }

  Color _getSeverityColor(double dogleg) {
    if (dogleg <= 2) return AppTheme.successColor;
    if (dogleg <= 4) return AppTheme.warningColor;
    if (dogleg <= 6) return AppTheme.errorColor;
    return Colors.red;
  }

  String _getSeverityText(double dogleg) {
    if (dogleg <= 2) return "Low";
    if (dogleg <= 4) return "Medium";
    if (dogleg <= 6) return "High";
    return "Critical";
  }

  List<DoglegPoint> _demoDoglegData() {
    return [
      DoglegPoint(0, 0.2),
      DoglegPoint(500, 0.5),
      DoglegPoint(1200, 2.0),
      DoglegPoint(2000, 1.8),
      DoglegPoint(2800, 0.6),
      DoglegPoint(3500, 0.8),
      DoglegPoint(4500, 0.4),
      DoglegPoint(6000, 0.7),
      DoglegPoint(7000, 2.5),
      DoglegPoint(7800, 4.5),
      DoglegPoint(8500, 5.8),
      DoglegPoint(9200, 6.3),
    ];
  }

  LineChartData _chartData({
    required List<DoglegPoint> points,
    bool isSmallScreen = false,
    bool isMediumScreen = false,
    double chartHeight = 600,
  }) {
    final double maxDepth = _findMaxDepth(points);
    final double maxDogleg = _findMaxDogleg(points);
    
    // Adjust font sizes based on chart height
    final axisFontSize = chartHeight > 650 ? 9 : 8;
    final axisTitleFontSize = chartHeight > 650 ? 10 : 9;
    
    return LineChartData(
      backgroundColor: Colors.white,

      // ================= GRID =================
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.grey.shade200, strokeWidth: 0.5),
        getDrawingHorizontalLine: (value) {
          // Highlight key depth intervals
          if (value % 1000 == 0) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          }
          return FlLine(color: Colors.grey.shade100, strokeWidth: 0.5);
        },
        horizontalInterval: isSmallScreen ? 1000 : 500,
        verticalInterval: isSmallScreen ? 1 : 0.5,
      ),

      // ================= AXES =================
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              "Measured Depth (ft)",
              style: AppTheme.caption.copyWith(
                fontSize: axisTitleFontSize.toDouble(),
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          axisNameSize: chartHeight > 650 ? 24 : 20,
          sideTitles: SideTitles(
            showTitles: true,
            interval: isSmallScreen ? 2000 : 1000,
            reservedSize: chartHeight > 650 ? 50 : 40,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value.toInt().toString(),
                  style: AppTheme.caption.copyWith(
                    fontSize: axisFontSize.toDouble(),
                    color: AppTheme.textSecondary,
                  ),
                )
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Dogleg Severity (°/100ft)",
              style: AppTheme.caption.copyWith(
                fontSize: axisTitleFontSize.toDouble(),
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          axisNameSize: chartHeight > 650 ? 24 : 20,
          sideTitles: SideTitles(
            showTitles: true,
            interval: isSmallScreen ? 2 : 1,
            reservedSize: chartHeight > 650 ? 36 : 32,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  value.toStringAsFixed(1),
                  style: AppTheme.caption.copyWith(
                    fontSize: axisFontSize.toDouble(),
                    color: AppTheme.textSecondary,
                  ),
                )
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
      minX: 0,
      maxX: (maxDogleg * 1.1).ceilToDouble(), // Add 10% padding
      minY: 0,
      maxY: (maxDepth * 1.05).ceilToDouble(), // Add 5% padding

      // ================= LINES =================
      lineBarsData: [
        // Main dogleg severity line
        LineChartBarData(
          spots: points.map((e) => FlSpot(e.dogleg, e.md)).toList(),
          isCurved: true,
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.accentColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          barWidth: isSmallScreen ? 2.5 : 3.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final doglegValue = spot.x;
              Color dotColor = _getSeverityColor(doglegValue);
              
              return FlDotCirclePainter(
                radius: isSmallScreen ? 3.5 : 4,
                color: dotColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.15),
                AppTheme.accentColor.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Threshold lines for dogleg severity
        if (maxDogleg >= 2) ..._createThresholdLines(maxDepth),
      ],

      // ================= INTERACTION =================
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => AppTheme.primaryColor.withOpacity(0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final doglegValue = touchedSpot.x;
              Color severityColor = _getSeverityColor(doglegValue);
              String severityLevel = _getSeverityText(doglegValue);
              
              return LineTooltipItem(
                'Depth: ${touchedSpot.y.toInt()} ft\n'
                'DLS: ${touchedSpot.x.toStringAsFixed(1)}°/100ft\n'
                'Severity: $severityLevel',
                TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                children: [
                  TextSpan(
                    text: ' ●',
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),

      // ================= THRESHOLD REGIONS =================
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          for (int i = 1000; i <= maxDepth; i += 1000)
            HorizontalLine(
              y: i.toDouble(),
              color: Colors.grey.shade200,
              strokeWidth: 1,
              dashArray: [3, 3],
            ),
        ],
        verticalLines: [
          for (double i = 1; i <= maxDogleg; i += 1)
            VerticalLine(
              x: i,
              color: Colors.grey.shade200,
              strokeWidth: 0.5,
              dashArray: [2, 2],
            ),
        ],
      ),
    );
  }

  List<LineChartBarData> _createThresholdLines(double maxDepth) {
    return [
      LineChartBarData(
        spots: [
          FlSpot(2, 0),
          FlSpot(2, maxDepth),
        ],
        isCurved: false,
        color: AppTheme.successColor.withOpacity(0.4),
        barWidth: 1,
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: [
          FlSpot(4, 0),
          FlSpot(4, maxDepth),
        ],
        isCurved: false,
        color: AppTheme.warningColor.withOpacity(0.4),
        barWidth: 1,
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: [
          FlSpot(6, 0),
          FlSpot(6, maxDepth),
        ],
        isCurved: false,
        color: AppTheme.errorColor.withOpacity(0.4),
        barWidth: 1,
        dotData: const FlDotData(show: false),
      ),
    ];
  }
}