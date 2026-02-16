import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class TimeDistributionGraph extends StatelessWidget {
  const TimeDistributionGraph({super.key});

  final List<_TimeData> data = const [
    _TimeData('Mud DP Stds', 15.00, 62.5),
    _TimeData('Pick Up BHA', 5.00, 20.8),
    _TimeData('Rig-up / Service', 3.00, 12.5),
    _TimeData('Drilling Formation', 1.00, 4.2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         
          const SizedBox(height: 20),

          Expanded(
            child: Row(
              children: [
               

                // GRAPH AREA
                Expanded(
                  child: Stack(
                    children: [
                      // GRID LINES WITH BACKGROUND
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          children: List.generate(
                            5,
                            (i) => Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: i == 4 
                                          ? Colors.transparent
                                          : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: List.generate(
                                    11,
                                    (j) => Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: j == 10
                                                  ? Colors.transparent
                                                  : Colors.grey.shade100,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // BARS
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: data.asMap().entries.map((entry) {
                            final index = entry.key;
                            final e = entry.value;
                            final color = _getBarColor(index);
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    height: 32,
                                    width: (MediaQuery.of(context).size.width *
                                                (e.percent / 100) *
                                                0.6)
                                            .clamp(120.0, double.infinity),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color,
                                          color.withOpacity(0.8),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            e.name,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${e.hours.toStringAsFixed(1)}h',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // X AXIS
          Row(
            children: [
              const SizedBox(width: 180),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      11,
                      (i) => Text(
                        '${i * 10}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // X AXIS LABEL
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Percentage (%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),

          // LEGEND
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Wrap(
              spacing: 20,
              runSpacing: 8,
              children: data.asMap().entries.map((entry) {
                final index = entry.key;
                final e = entry.value;
                final color = _getBarColor(index);
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${e.name}: ${e.percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
    ];
    return colors[index % colors.length];
  }
}

class _TimeData {
  final String name;
  final double hours;
  final double percent;

  const _TimeData(this.name, this.hours, this.percent);
}