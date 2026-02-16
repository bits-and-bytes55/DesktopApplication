import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudPropertiesController extends GetxController {
  final hoveredIndex = (-1).obs;
  final hoveredSection = ''.obs;

  // Sample data for 5 properties over 15 days
  final List<double> mwData = [8.5, 8.5, 8.6, 8.7, 9.0, 9.2, 10.5, 10.8, 11.0, 10.5, 8.0, 8.0, 8.0, 8.0, 8.0];
  final List<double> pvData = [12, 12, 12, 15, 14, 13, 12, 11, 10, 12, 15, 16, 17, 18, 18];
  final List<double> ypData = [8, 8, 9, 10, 12, 15, 16, 18, 20, 18, 16, 15, 15, 16, 16];
  final List<double> gelStrengthData = [3, 3, 3, 4, 5, 6, 7, 8, 8, 7, 6, 5, 4, 4, 4];
  final List<double> phData = [9.0, 9.0, 9.5, 9.5, 10.0, 10.0, 9.5, 9.0, 8.5, 8.0, 7.5, 7.5, 8.0, 8.5, 9.0];

  void setHoveredBar(int index, String section) {
    hoveredIndex.value = index;
    hoveredSection.value = section;
  }

  void clearHovered() {
    hoveredIndex.value = -1;
    hoveredSection.value = '';
  }

  double getAverageForSection(String title) {
    List<double> data;
    switch (title) {
      case 'MW (Mud Weight)':
        data = mwData;
        break;
      case 'PV (Plastic Viscosity)':
        data = pvData;
        break;
      case 'YP (Yield Point)':
        data = ypData;
        break;
      case 'Gel Strength':
        data = gelStrengthData;
        break;
      case 'pH':
        data = phData;
        break;
      default:
        return 0;
    }
    return data.reduce((a, b) => a + b) / data.length;
  }
}

class MudPropertiesGraphPage extends StatelessWidget {
  final controller = Get.put(MudPropertiesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
    
            _buildDiscriminationBar(),
            SizedBox(height: 20),
            _buildGraphCard(
              title: 'MW (Mud Weight)',
              data: controller.mwData,
              color: Color(0xff4A90E2),
              section: 'mw',
              unit: 'ppg',
            ),
            SizedBox(height: 16),
            _buildGraphCard(
              title: 'PV (Plastic Viscosity)',
              data: controller.pvData,
              color: Color(0xff50C9CE),
              section: 'pv',
              unit: 'cP',
            ),
            SizedBox(height: 16),
            _buildGraphCard(
              title: 'YP (Yield Point)',
              data: controller.ypData,
              color: Color(0xff7B68EE),
              section: 'yp',
              unit: 'lbs/100ft²',
            ),
            SizedBox(height: 16),
            _buildGraphCard(
              title: 'Gel Strength',
              data: controller.gelStrengthData,
              color: Color(0xffE57373),
              section: 'gel',
              unit: 'lbs/100ft²',
            ),
            SizedBox(height: 16),
            _buildGraphCard(
              title: 'pH',
              data: controller.phData,
              color: Color(0xff9575CD),
              section: 'ph',
              unit: '',
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

 


  Widget _buildDiscriminationBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 45,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xffB39DDB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(0xffB39DDB),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Water-based',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 55,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xff81C784),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(0xff81C784),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Oil-based',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
    required String unit,
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
          _buildGraphHeader(title, color, data, unit),
          Container(
            height: 220,
            padding: EdgeInsets.all(20),
            child: _buildLineChart(data, color, section, unit, title: title),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphHeader(String title, Color color, List<double> data, String unit) {
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
            'Avg: ${controller.getAverageForSection(title).toStringAsFixed(1)}${unit.isNotEmpty ? " $unit" : ""}',
            style: AppTheme.bodyLarge.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<double> data, Color lineColor, String section, String unit, {String title = ''}) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
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
            drawVerticalLine: true,
            horizontalInterval: hasData ? (maxValue - minValue) / 4 : 5,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.textSecondary.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
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
                interval: 1,
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
              axisNameWidget: Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  unit.isNotEmpty ? unit : title.split('(')[0].trim(),
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (!hasData) return Container();
                  return Text(
                    value.toStringAsFixed(1),
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
          minY: minValue > 0 ? minValue * 0.8 : 0,
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
                    'Day ${spot.x.toInt() + 1}\n${spot.y.toStringAsFixed(1)}${unit.isNotEmpty ? " $unit" : ""}',
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

