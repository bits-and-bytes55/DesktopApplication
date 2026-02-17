// ======================== FILE 3: graph_tab.dart ========================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CumCostGraphTab extends StatelessWidget {
  const CumCostGraphTab({super.key});

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Product',
      'Premixed Mud',
      'Package',
      'Service',
      'Engineering',
      'Total',
      
    ];

    final colors = [
      Color(0xff6C9BCF),
      Color(0xffA8D5BA),
      Color(0xffFFB6C1),
      Color(0xff38B2AC),
      Color(0xffED8936),
      Color(0xffED8936),
      Color.fromARGB(255, 54, 237, 142),
    ];

    final ScrollController scrollController = ScrollController();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              titles.length,
              (index) => Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: _graphCard(titles[index], colors[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _graphCard(String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xffF8F9FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xffE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2D3748),
                  ),
                ),
              ],
            ),
          ),
          // Graph Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Color(0xffE2E8F0),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1000,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '\$${value.toInt()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xff718096),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Day ${value.toInt()}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xff718096),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Color(0xffE2E8F0),
                      width: 1,
                    ),
                  ),
                  minX: 1,
                  maxX: 5,
                  minY: 0,
                  maxY: 5000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(1, 1200),
                        FlSpot(2, 2800),
                        FlSpot(3, 1900),
                        FlSpot(4, 3200),
                        FlSpot(5, 2500),
                      ],
                      isCurved: true,
                      color: color,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: color,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.3),
                            color.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Summary at bottom
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xffF8F9FA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                top: BorderSide(color: Color(0xffE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff718096),
                  ),
                ),
                Text(
                  '\$12,600',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff2D3748),
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