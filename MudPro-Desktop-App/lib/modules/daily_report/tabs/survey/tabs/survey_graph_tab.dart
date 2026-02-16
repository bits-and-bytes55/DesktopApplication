import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SurveyChartsPage extends StatelessWidget {
  const SurveyChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // CHART 1 - Smaller fixed height
            Expanded(
              child: _ChartCard(
                title: 'Survey Distribution - Chart 1',
                data: [
                  _SurveyData('Measurement', 42.5),
                  _SurveyData('Calculation', 28.3),
                  _SurveyData('Analysis', 18.7),
                  _SurveyData('Reporting', 10.5),
                ],
                gradientColors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // CHART 2 - Same height as Chart 1
            Expanded(
              child: _ChartCard(
                title: 'Survey Distribution - Chart 2',
                data: [
                  _SurveyData('Planning', 35.2),
                  _SurveyData('Execution', 40.8),
                  _SurveyData('Verification', 15.6),
                  _SurveyData('Documentation', 8.4),
                ],
                gradientColors: [
                  AppTheme.accentColor,
                  AppTheme.successColor,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurveyData {
  final String label;
  final double value;

  const _SurveyData(this.label, this.value);
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<_SurveyData> data;
  final List<Color> gradientColors;

  const _ChartCard({
    required this.title,
    required this.data,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.elevatedCardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SIMPLE TITLE BAR
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradientColors[0].withOpacity(0.1),
                  gradientColors[1].withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          
          // SIMPLE DUMMY CHART AREA - Takes all remaining space
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Y-AXIS LABELS - Compact
                  SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: data.map((e) {
                        return Container(
                          padding: const EdgeInsets.only(right: 8),
                          alignment: Alignment.centerRight,
                          child: Text(
                            e.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // SIMPLE CHART BARS
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: data.asMap().entries.map((entry) {
                          final index = entry.key;
                          final e = entry.value;
                          final color = Color.lerp(
                            gradientColors[0],
                            gradientColors[1],
                            index / data.length,
                          )!;
                          
                          return Row(
                            children: [
                              // Simple bar with value inside
                              Container(
                                height: 24,
                                width: (e.value / 100) * (MediaQuery.of(context).size.width - 150),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.value.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // SIMPLE X-AXIS
          Container(
            padding: const EdgeInsets.only(bottom: 8, left: 120),
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0%', style: TextStyle(fontSize: 9)),
                Text('25%', style: TextStyle(fontSize: 9)),
                Text('50%', style: TextStyle(fontSize: 9)),
                Text('75%', style: TextStyle(fontSize: 9)),
                Text('100%', style: TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}