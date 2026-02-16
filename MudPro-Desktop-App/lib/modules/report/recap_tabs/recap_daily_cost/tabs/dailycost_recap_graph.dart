import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/controller/dailycost_recap_controller.dart';



class DailyCostGraphsPage extends StatelessWidget {
  final controller = Get.put(DailyCostGraphController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildPageHeader(),
            // SizedBox(height: 20),
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
          Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            'Daily Cost (€)',
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
            height: 280,
            padding: EdgeInsets.all(20),
            child: _buildBarChart(data, color, section),
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
        ],
      ),
    );
  }

  Widget _buildBarChart(List<double> data, Color barColor, String section) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final hasData = maxValue > 0;

    return Obx(() => BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: hasData ? maxValue * 1.2 : 100,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (touchedSpot) => barColor.withOpacity(0.9),
                tooltipBorderRadius: BorderRadius.circular(8),
                tooltipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    'Day ${group.x + 1}\n€${rod.toY.toStringAsFixed(0)}',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                },
              ),
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                if (event is FlTapUpEvent || event is FlPanEndEvent) {
                  controller.clearHovered();
                } else if (barTouchResponse != null &&
                    barTouchResponse.spot != null) {
                  controller.setHoveredBar(
                    barTouchResponse.spot!.touchedBarGroupIndex,
                    section,
                  );
                }
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
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.textSecondary.withOpacity(0.2),
                  width: 1,
                ),
                left: BorderSide(
                  color: AppTheme.textSecondary.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            barGroups: List.generate(
              data.length,
              (index) {
                final isHovered = controller.hoveredIndex.value == index &&
                    controller.hoveredSection.value == section;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data[index],
                      color: isHovered
                          ? barColor
                          : barColor.withOpacity(0.8),
                      width: isHovered ? 18 : 14,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: hasData ? maxValue * 1.2 : 100,
                        color: barColor.withOpacity(0.05),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          swapAnimationDuration: Duration(milliseconds: 300),
          swapAnimationCurve: Curves.easeInOutCubic,
        ));
  }
}

// AppTheme class
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