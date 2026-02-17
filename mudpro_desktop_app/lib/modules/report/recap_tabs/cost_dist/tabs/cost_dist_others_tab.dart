import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/model/cost_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class CostDistOtherTab extends StatelessWidget {
  const CostDistOtherTab({super.key});

  @override
  Widget build(BuildContext context) {
    final chart1 = [
      CostData('Drilling Tools', 35.5),
      CostData('Casing & Tubing', 28.2),
      CostData('Wellhead Equip', 18.7),
      CostData('Safety Equipment', 12.4),
      CostData('Miscellaneous', 5.2),
    ];

    final chart2 = [
      CostData('Transportation', 42.3),
      CostData('Logistics', 25.8),
      CostData('Catering', 15.6),
      CostData('Accommodation', 10.9),
      CostData('Admin Costs', 5.4),
    ];

    final engineeringData = [
      CostData('Mud Supervisor-I', 45.2),
      CostData('Drilling Engineer', 28.7),
      CostData('Site Manager', 15.8),
      CostData('Geologist', 7.3),
      CostData('Support Staff', 3.0),
    ];

    final allCategoriesData = [
      CostData('Product & Materials', 65.8),
      CostData('Engineering Services', 18.4),
      CostData('Equipment Rental', 8.7),
      CostData('Logistics & Transport', 4.9),
      CostData('Other Services', 2.2),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundColor,
            AppTheme.backgroundColor.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        

          // Charts Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return _buildDesktopGrid(chart1, chart2, engineeringData, allCategoriesData);
                } else {
                  return _buildMobileGrid(chart1, chart2, engineeringData, allCategoriesData);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(
    List<CostData> chart1,
    List<CostData> chart2,
    List<CostData> engineeringData,
    List<CostData> allCategoriesData,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      padding: const EdgeInsets.all(4),
      children: [
        _buildChartCard(
          'Cost Distribution - Package',
          chart1,
          Icons.build,
          AppTheme.primaryColor,
        ),
        _buildChartCard(
          'Cost Distribution - Service',
          chart2,
          Icons.local_shipping,
          AppTheme.secondaryColor,
        ),
        _buildChartCard(
          'Cost Distribution - Engineering',
          engineeringData,
          Icons.engineering,
          AppTheme.accentColor,
        ),
        _buildChartCard(
          'Cost Distribution - All Categories',
          allCategoriesData,
          Icons.pie_chart_outline,
          AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildMobileGrid(
    List<CostData> chart1,
    List<CostData> chart2,
    List<CostData> engineeringData,
    List<CostData> allCategoriesData,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildChartCard(
            'Equipment & Tools Cost',
            chart1,
            Icons.build,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            'Logistics & Support Cost',
            chart2,
            Icons.local_shipping,
            AppTheme.secondaryColor,
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            'Engineering Services Cost',
            engineeringData,
            Icons.engineering,
            AppTheme.accentColor,
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            'All Categories Distribution',
            allCategoriesData,
            Icons.pie_chart_outline,
            AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    String title,
    List<CostData> data,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        "Daily cost distribution analysis",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${data.fold<double>(0, (sum, item) => sum + item.value).toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chart Area with Custom Height
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: _CustomHorizontalChart(
                data: data,
                maxValue: 100,
                barHeightMultiplier: 0.55, // Increased from 0.4 to 0.55
                spacingMultiplier: 0.45, // Decreased from 0.6 to 0.45
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Chart Widget with adjustable bar height
class _CustomHorizontalChart extends StatelessWidget {
  final List<CostData> data;
  final double maxValue;
  final double barHeightMultiplier;
  final double spacingMultiplier;

  const _CustomHorizontalChart({
    required this.data,
    required this.maxValue,
    this.barHeightMultiplier = 0.55,
    this.spacingMultiplier = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight;
        // बार्स की height increase की गई है: 0.55 कर दिया
        final barHeight = chartHeight / data.length * barHeightMultiplier;
        // Spacing decrease किया गया है: 0.45 कर दिया
        final spacing = chartHeight / data.length * spacingMultiplier;

        return Stack(
          children: [
            // Grid Background
            _buildGridBackground(constraints.maxWidth),

            // Vertical Axis
            Positioned(
              left: 40,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: Colors.grey.shade300,
              ),
            ),

            // Bars with increased height
            ...List.generate(data.length, (index) {
              final item = data[index];
              final color = CostData.chartColors[index % CostData.chartColors.length];
              final barWidth = (item.value / maxValue) * (constraints.maxWidth - 90);

              return Positioned(
                left: 50,
                top: index * (barHeight + spacing),
                child: TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 800 + index * 100),
                  curve: Curves.easeOutBack,
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Container(
                      width: barWidth * value,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withOpacity(0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(1, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Label
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 1,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          
                          // Percentage Value
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                '${item.value.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 2,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),

            // Y-Axis Labels
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${maxValue.toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${(maxValue * 0.75).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${(maxValue * 0.5).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${(maxValue * 0.25).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '0%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridBackground(double width) {
    return Column(
      children: List.generate(5, (index) {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: index % 2 == 0 ? 0.5 : 0.3,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}