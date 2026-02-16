import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:mudpro_desktop_app/modules/daily_report/widgets/wellbore_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class WellboreDashboard extends StatelessWidget {
  const WellboreDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WellboreController());
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - 32; // Subtract padding
          final sectionWidth = availableWidth / 4; // Divide equally among 4 sections

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: math.max(constraints.maxWidth, 1200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Wellbore Schematic
                    Flexible(
                      flex: 1,
                      child: Container(
                        width: math.max(sectionWidth, 250),
                        height: constraints.maxHeight - 32,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildWellboreSchematic(),
                      ),
                    ),

                    // Section 2: KPI Section
                    Flexible(
                      flex: 1,
                      child: Container(
                        width: math.max(sectionWidth, 250),
                        height: constraints.maxHeight - 32,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildKPISection(controller),
                      ),
                    ),

                    // Section 3: Cost Distribution
                    Flexible(
                      flex: 1,
                      child: Container(
                        width: math.max(sectionWidth, 250),
                        height: constraints.maxHeight - 32,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildCostDistribution(controller),
                      ),
                    ),

                    // Section 4: Progress Charts
                    Flexible(
                      flex: 1,
                      child: Container(
                        width: math.max(sectionWidth, 250),
                        height: constraints.maxHeight - 32,
                        child: _buildProgressCharts(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWellboreSchematic() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Wellbore Schematic',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Depth Analysis',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MD/TVD (ft)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Shoe (ft)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              children: [
                Text(
                  '0.0 ● 0.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: CustomPaint(
                painter: EnhancedWellborePainter(),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection(WellboreController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'KPI Metrics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Live Data',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Obx(() => _buildGaugeChart(
                    'Depth',
                    controller.depthKPI.value,
                    controller.maxDepthKPI.value,
                    '${controller.depthKPI.value.toStringAsFixed(2)} ft',
                    AppTheme.primaryColor,
                    (controller.depthKPI.value / controller.maxDepthKPI.value * 100).toStringAsFixed(1),
                  )),
                  const SizedBox(height: 16),
                  Obx(() => _buildGaugeChart(
                    'Cost',
                    controller.costKPI.value,
                    controller.maxCostKPI.value,
                    '€${controller.costKPI.value.toStringAsFixed(2)}',
                    AppTheme.secondaryColor,
                    (controller.costKPI.value / controller.maxCostKPI.value * 100).toStringAsFixed(1),
                  )),
                  const SizedBox(height: 16),
                  Obx(() => _buildGaugeChart(
                    'Day',
                    controller.dayKPI.value,
                    controller.maxDayKPI.value,
                    '${controller.dayKPI.value.toStringAsFixed(0)} Days',
                    AppTheme.accentColor,
                    (controller.dayKPI.value / controller.maxDayKPI.value * 100).toStringAsFixed(1),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeChart(String title, double value, double maxValue, String valueText, Color color, String percentage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            height: 130,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(200, 130),
                  painter: EnhancedGaugePainter(
                    value: value,
                    maxValue: maxValue,
                    color: color,
                  ),
                ),
                Positioned(
                  bottom: 15,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        valueText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostDistribution(WellboreController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Cost Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Expense Analysis',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Products Used',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Obx(() => _buildBarChart(controller.topProducts, AppTheme.primaryColor)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'All Categories',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Obx(() => _buildBarChart(controller.categories, AppTheme.secondaryColor)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> items, Color color) {
    final maxPercentage = items.isNotEmpty
        ? items.map((item) => item['percentage'] as double).reduce((a, b) => a > b ? a : b)
        : 100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32; // Account for padding
        return Column(
          children: items.map((item) {
            final percentage = item['percentage'] as double;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Bar with gradient
                  Stack(
                    children: [
                      Container(
                        height: 20,
                        width: availableWidth,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 20,
                        width: availableWidth * (percentage / maxPercentage),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color,
                              color.withOpacity(0.7),
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
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProgressCharts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Progress Trends',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                ),
                child: Text(
                  'Trend Analysis',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.infoColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildLineChart(
                    'Depth Progress',
                    [0, 20, 45, 70, 100],
                    '(ft)',
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildLineChart(
                    'Cum. Total Cost',
                    [0, 1, 2, 3, 4],
                    '(1000k USD)',
                    AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildLineChart(
                    'Mud Weight',
                    [9.4, 9.8, 10.2, 10.6],
                    '(ppg)',
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(String title, List<double> data, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: CustomPaint(
                painter: EnhancedLineChartPainter(data: data, unit: unit, color: color),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Wellbore Painter
class EnhancedWellborePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pipePaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw vertical pipes with better spacing
    final pipeWidth = size.width / 16; // Thinner pipes
    final leftMargin = 80.0; // Space for depth labels
    final availableWidth = size.width - leftMargin - 20;
    final positions = [0.25, 0.45, 0.65, 0.85];

    for (var pos in positions) {
      final x = leftMargin + availableWidth * pos;
      
      // Draw top thin pipe
      canvas.drawRect(
        Rect.fromLTWH(x - pipeWidth / 2, 0, pipeWidth, size.height * 0.20),
        pipePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - pipeWidth / 2, 0, pipeWidth, size.height * 0.20),
        outlinePaint,
      );

      // Draw wider middle section
      final widerWidth = pipeWidth * 1.6; // Slightly narrower
      canvas.drawRect(
        Rect.fromLTWH(x - widerWidth / 2, size.height * 0.20, widerWidth, size.height * 0.60),
        pipePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - widerWidth / 2, size.height * 0.20, widerWidth, size.height * 0.60),
        outlinePaint,
      );

      // Draw bottom thin pipe
      canvas.drawRect(
        Rect.fromLTWH(x - pipeWidth / 2, size.height * 0.80, pipeWidth, size.height * 0.20),
        pipePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - pipeWidth / 2, size.height * 0.80, pipeWidth, size.height * 0.20),
        outlinePaint,
      );
    }

    // Draw depth markers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    final depthPositions = [
      {'depth': '20.0 ● 20.0', 'position': 0.15},
      {'depth': '40.0 ● 40.0', 'position': 0.30},
      {'depth': '60.0 ● 60.0', 'position': 0.50},
      {'depth': '65.0', 'position': 0.60},
      {'depth': '80.0 ● 80.0', 'position': 0.75},
      {'depth': '96.0 ● 96.0', 'position': 0.92},
    ];

    for (var item in depthPositions) {
      textPainter.text = TextSpan(
        text: item['depth'] as String,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, size.height * (item['position'] as double) - 6));
      
      // Draw horizontal guide line
      final linePaint = Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(textPainter.width + 15, size.height * (item['position'] as double)),
        Offset(leftMargin - 5, size.height * (item['position'] as double)),
        linePaint,
      );
    }

    // Draw wavy measurement line
    final wavyPaint = Paint()
      ..color = AppTheme.secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final startY = size.height * 0.60;
    path.moveTo(leftMargin - 20, startY);
    
    for (var i = 0; i < 20; i++) {
      final y = startY + i * 12;
      if (y > size.height * 0.95) break;
      final x = leftMargin - 20 + math.sin(i * 0.6) * 8;
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, wavyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Enhanced Gauge Painter
class EnhancedGaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  EnhancedGaugePainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = (size.width / 2) - 20;

    // Background arc (semi-circle)
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    // Value arc (gradient)
    final valuePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color,
          color.withOpacity(0.7),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (value / maxValue) * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      valuePaint,
    );

    // Draw needle
    final needleAngle = math.pi + sweepAngle;
    final needlePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final needleEndX = center.dx + (radius - 8) * math.cos(needleAngle);
    final needleEndY = center.dy + (radius - 8) * math.sin(needleAngle);
    
    canvas.drawLine(center, Offset(needleEndX, needleEndY), needlePaint);
    
    // Draw center circle
    canvas.drawCircle(center, 6, Paint()..color = Colors.black);

    // Draw labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Start label
    textPainter.text = const TextSpan(
      text: '0',
      style: TextStyle(color: Colors.grey, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas,  Offset(25, size.height - 20));

    // End label
    textPainter.text = TextSpan(
      text: maxValue.toStringAsFixed(0),
      style: const TextStyle(color: Colors.grey, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 25, size.height - 20));
  }

  @override
  bool shouldRepaint(covariant EnhancedGaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.maxValue != maxValue || oldDelegate.color != color;
}

// Enhanced Line Chart Painter
class EnhancedLineChartPainter extends CustomPainter {
  final List<double> data;
  final String unit;
  final Color color;

  EnhancedLineChartPainter({
    required this.data,
    required this.unit,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final leftPadding = 35.0;
    final rightPadding = 15.0;
    final topPadding = 25.0;
    final bottomPadding = 35.0;
    
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = topPadding + chartHeight * i / 5;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    // Vertical grid lines
    for (int i = 0; i <= 5; i++) {
      final x = leftPadding + chartWidth * i / 5;
      canvas.drawLine(
        Offset(x, topPadding),
        Offset(x, size.height - bottomPadding),
        gridPaint,
      );
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5;

    // Y-axis
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, size.height - bottomPadding),
      axisPaint,
    );

    // X-axis
    canvas.drawLine(
      Offset(leftPadding, size.height - bottomPadding),
      Offset(size.width - rightPadding, size.height - bottomPadding),
      axisPaint,
    );

    // Calculate data range
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue == 0 ? 1 : maxValue - minValue;

    // Draw line and points
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (var i = 0; i < data.length; i++) {
      final x = leftPadding + chartWidth * i / (data.length - 1);
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - bottomPadding - (chartHeight * normalizedValue);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = Colors.white,
      );
    }

    canvas.drawPath(path, linePaint);

    // Draw axis labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // X-axis labels (Days)
    for (var i = 0; i <= 5; i++) {
      textPainter.text = TextSpan(
        text: 'Day $i',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 9,
        ),
      );
      textPainter.layout();
      final x = leftPadding + chartWidth * i / 5 - textPainter.width / 2;
      textPainter.paint(canvas, Offset(x, size.height - bottomPadding + 8));
    }

    // X-axis label
    textPainter.text = const TextSpan(
      text: 'Timeline',
      style: TextStyle(
        color: Colors.black,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height - 12),
    );

    // Y-axis labels
    for (var i = 0; i <= 5; i++) {
      final value = minValue + (range * (5 - i) / 5);
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 9,
        ),
      );
      textPainter.layout();
      final y = topPadding + chartHeight * i / 5 - textPainter.height / 2;
      textPainter.paint(canvas, Offset(5, y));
    }

    // Y-axis unit label (rotated)
    textPainter.text = TextSpan(
      text: unit,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 9,
      ),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(12, size.height / 2 + textPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant EnhancedLineChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}