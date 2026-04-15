import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/drilling_data/controller/drilling_data_controller.dart';

class RecapDrillingDataGraphPage extends StatelessWidget {
  final controller = Get.put(RecapDrillingDataController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            SizedBox(height: 20),
            _buildGraphCard(
              title: 'Product',
              data: controller.productData,
              color: Color(0xff4A90E2),
              section: 'product',
            ),
            SizedBox(height: 16),
            _buildGraphCard(
              title: 'Premix/Mud',
              data: controller.premixData,
              color: Color(0xff50C9CE),
              section: 'premix',
            ),
            SizedBox(height: 16),
            _buildGraphCard(
              title: 'Rig2dx',
              data: controller.rig2dxData,
              color: Color(0xff7B68EE),
              section: 'rig2dx',
            ),
            SizedBox(height: 16),
            _buildGraphCard(
              title: 'Service',
              data: controller.serviceData,
              color: Color(0xffE57373),
              section: 'service',
            ),
            SizedBox(height: 16),
            _buildGraphCard(
              title: 'Engineering',
              data: controller.engineeringData,
              color: Color(0xff9575CD),
              section: 'engineering',
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.show_chart_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            'Drilling Data Analysis',
            style: AppTheme.titleLarge.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Recap Report',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphCard({
    required String title,
    required List<double> data,
    required Color color,
    required String section,
  }) {
    return Container(
      decoration: AppTheme.elevatedCardDecoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphHeader(title, color),
          Container(
            height: 220, // Reduced height
            padding: EdgeInsets.all(20),
            child: _buildLineChart(data, color, section),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphHeader(String title, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: AppTheme.titleMedium.copyWith(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Text(
            'Total: €${controller.getTotalForSection(title).toStringAsFixed(0)}',
            style: AppTheme.bodyMedium.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<double> data, Color lineColor, String section) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final hasData = maxValue > 0;
    final List<FlSpot> spots = data
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    return Obx(() {
      final hoveredIndex = controller.hoveredIndex.value;
      final hoveredSection = controller.hoveredSection.value;
      return LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: hasData ? maxValue / 4 : 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.textSecondary.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Day',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '${value.toInt() + 1}',
                      style: AppTheme.caption.copyWith(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return Text('0');
                  if (!hasData) return Container();
                  return Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(0)}k'
                        : value.toStringAsFixed(0),
                    style: AppTheme.caption.copyWith(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          minX: 0,
          maxX: data.length.toDouble() - 1,
          minY: 0,
          maxY: hasData ? maxValue * 1.2 : 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isHovered = hoveredIndex == index && hoveredSection == section;
                  return FlDotCirclePainter(
                    radius: isHovered ? 5 : 3,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withOpacity(0.3),
                    lineColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => lineColor.withOpacity(0.9),
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    'Day ${spot.x.toInt() + 1}\n€${spot.y.toStringAsFixed(0)}',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
            touchCallback: (FlTouchEvent event, lineTouchResponse) {
              if (event is FlTapUpEvent || event is FlPanEndEvent) {
                controller.clearHovered();
              } else if (lineTouchResponse != null &&
                  lineTouchResponse.lineBarSpots != null &&
                  lineTouchResponse.lineBarSpots!.isNotEmpty) {
                final spot = lineTouchResponse.lineBarSpots!.first;
                controller.setHoveredBar(
                  spot.spotIndex,
                  section,
                );
              }
            },
          ),
        ),
      );
    });
  }
}

// AppTheme class with additional styles
class AppTheme {
  static const Color primaryColor = Color(0xff6C9BCF);
  static const Color backgroundColor = Color(0xffFAF9F6);
  static const Color surfaceColor = Color(0xffFFFFFF);
  static const Color cardColor = Color(0xffF8F9FA);
  static const Color textPrimary = Color(0xff2D3748);
  static const Color textSecondary = Color(0xff718096);

  static LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xff1E4E79), Color(0xff2C5A8B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [surfaceColor, cardColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
}