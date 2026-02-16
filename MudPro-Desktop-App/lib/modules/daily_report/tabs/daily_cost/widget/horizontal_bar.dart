import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/model/cost_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class HorizontalCostChart extends StatelessWidget {
  final String title;
  final List<CostData> data;
  final bool showValues;
  final double maxValue;

  const HorizontalCostChart({
    super.key,
    required this.title,
    required this.data,
    this.showValues = true,
    this.maxValue = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Total: ${data.fold<double>(0, (sum, item) => sum + item.value).toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chart Area - Takes remaining space
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate grid sections based on data length
                final gridSections = data.length;
                final sectionHeight = constraints.maxHeight / gridSections;
                
                // Bar height remains fixed
                final barHeight = 30.0;
                
                // Calculate bar position to center it in each grid section
                final barTopOffset = (sectionHeight - barHeight) / 2;

                return Stack(
                  children: [
                    // Grid Background - matches data length
                    _buildGridBackground(constraints.maxHeight, gridSections),

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

                    // Bars aligned with grid sections
                    ...List.generate(data.length, (index) {
                      final item = data[index];
                      final color = CostData.chartColors[index % CostData.chartColors.length];
                      final barWidth = (item.value / maxValue) * (constraints.maxWidth - 100);

                      return Positioned(
                        left: 50,
                        top: (index * sectionHeight) + barTopOffset,
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
                                  topRight: Radius.circular(barHeight / 5),
                                  bottomRight: Radius.circular(barHeight / 5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(2, 0),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Label
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 2,
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
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Text(
                                        '${item.value.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.5),
                                              blurRadius: 3,
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

                    // Y-Axis Labels - aligned with grid lines
                    Positioned(
                      left: 0,
                      top: 0,
                      child: SizedBox(
                        width: 40,
                        height: constraints.maxHeight,
                        child: Column(
                          children: List.generate(gridSections + 1, (index) {
                            final percentage = maxValue * (1 - index / gridSections);
                            return Expanded(
                              child: Align(
                                alignment: index == 0 ? Alignment.topCenter : 
                                          index == gridSections ? Alignment.bottomCenter :
                                          Alignment.center,
                                child: Text(
                                  '${percentage.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: index == 0 || index == gridSections 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Legend
          if (showValues && data.length > 0) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final color = CostData.chartColors[index % CostData.chartColors.length];
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridBackground(double totalHeight, int sections) {
    return Column(
      children: List.generate(sections, (index) {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}