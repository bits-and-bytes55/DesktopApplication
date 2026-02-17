import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertProductInventoryPage extends StatefulWidget {
  const AlertProductInventoryPage({super.key});

  @override
  State<AlertProductInventoryPage> createState() => _AlertProductInventoryPageState();
}

class _AlertProductInventoryPageState extends State<AlertProductInventoryPage> {
  double? hoverX;
  double? hoverY;
  List<Map<String, double>> inventoryData = [
    {'x': 0, 'y': 0.8},
    {'x': 1, 'y': 0.6},
    {'x': 2, 'y': 0.9},
    {'x': 3, 'y': 0.4},
    {'x': 4, 'y': 0.7},
    {'x': 5, 'y': 0.5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CHART HEADER
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Product Inventory Analysis',
                    style: AppTheme.titleMedium.copyWith(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Inventory Levels',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // CHART CONTAINER
            Expanded(
              child: Container(
                decoration: AppTheme.cardDecoration.copyWith(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: MouseRegion(
                  onHover: (event) {
                    setState(() {
                      hoverX = event.localPosition.dx;
                      hoverY = event.localPosition.dy;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      hoverX = null;
                      hoverY = null;
                    });
                  },
                  child: CustomPaint(
                    painter: _EnhancedProductInventoryChartPainter(
                      hoverX: hoverX,
                      hoverY: hoverY,
                      dataPoints: inventoryData,
                    ),
                    child: Container(),
                  ),
                ),
              ),
            ),

            // CHART LEGEND
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Normal Range',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Warning Range',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Critical Range',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Interactive Chart',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedProductInventoryChartPainter extends CustomPainter {
  final double? hoverX;
  final double? hoverY;
  final List<Map<String, double>> dataPoints;

  _EnhancedProductInventoryChartPainter({
    this.hoverX,
    this.hoverY,
    required this.dataPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 70;
    const double bottomPadding = 50;
    const double topPadding = 40;
    const double rightPadding = 30;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // ================= BACKGROUND =================
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // ================= TITLE =================
    _drawText(
      canvas,
      'Product Inventory Levels',
      Offset(size.width / 2 - 80, 15),
      TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );

    // ================= RANGE ZONES =================
    final safeZonePaint = Paint()
      ..color = AppTheme.successColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final warningZonePaint = Paint()
      ..color = AppTheme.warningColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final criticalZonePaint = Paint()
      ..color = AppTheme.errorColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Safe zone (0.7 - 1.0)
    canvas.drawRect(
      Rect.fromLTWH(
        leftPadding,
        topPadding,
        chartWidth,
        chartHeight * 0.3,
      ),
      safeZonePaint,
    );

    // Warning zone (0.4 - 0.7)
    canvas.drawRect(
      Rect.fromLTWH(
        leftPadding,
        topPadding + chartHeight * 0.3,
        chartWidth,
        chartHeight * 0.3,
      ),
      warningZonePaint,
    );

    // Critical zone (0.0 - 0.4)
    canvas.drawRect(
      Rect.fromLTWH(
        leftPadding,
        topPadding + chartHeight * 0.6,
        chartWidth,
        chartHeight * 0.4,
      ),
      criticalZonePaint,
    );

    // ================= GRID HORIZONTAL =================
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 5; i++) {
      final y = topPadding + chartHeight * i / 5;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      final label = (1 - i * 0.2).toStringAsFixed(1);
      _drawText(
        canvas,
        label,
        Offset(35, y - 6),
        TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // ================= GRID VERTICAL =================
    for (int i = 0; i <= 5; i++) {
      final x = leftPadding + chartWidth * i / 5;
      canvas.drawLine(
        Offset(x, topPadding),
        Offset(x, topPadding + chartHeight),
        gridPaint,
      );

      _drawText(
        canvas,
        i.toString(),
        Offset(x - 4, size.height - 35),
        TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // ================= AXIS =================
    final axisPaint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(leftPadding + chartWidth, topPadding + chartHeight),
      axisPaint,
    );

    // ================= REFERENCE LINE =================
    final refPaint = Paint()
      ..color = AppTheme.accentColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final refX = leftPadding + chartWidth * 0.5;
    canvas.drawLine(
      Offset(refX, topPadding),
      Offset(refX, topPadding + chartHeight),
      refPaint,
    );

    _drawText(
      canvas,
      'Mid-point',
      Offset(refX - 25, topPadding - 5),
      TextStyle(
        fontSize: 10,
        color: AppTheme.accentColor,
        fontWeight: FontWeight.w600,
      ),
    );

    // ================= BAR CHART =================
    final barWidth = chartWidth / dataPoints.length * 0.7;
    final barSpacing = chartWidth / dataPoints.length * 0.3;

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final x = leftPadding + i * (barWidth + barSpacing) + barSpacing / 2;
      final barHeight = point['y']! * chartHeight;
      final y = topPadding + chartHeight - barHeight;

      Color barColor;
      if (point['y']! >= 0.7) {
        barColor = AppTheme.successColor;
      } else if (point['y']! >= 0.4) {
        barColor = AppTheme.warningColor;
      } else {
        barColor = AppTheme.errorColor;
      }

      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      // Draw bar
      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        barPaint,
      );

      // Bar shadow
      final shadowPaint = Paint()
        ..color = barColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(x + 2, y + 2, barWidth, barHeight),
        shadowPaint,
      );

      // Value label
      _drawText(
        canvas,
        point['y']!.toStringAsFixed(1),
        Offset(x + barWidth / 2 - 8, y - 15),
        TextStyle(
          fontSize: 10,
          color: barColor,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // ================= CURSOR LINES =================
    if (hoverX != null && hoverY != null) {
      final cursorX = hoverX!.clamp(leftPadding, leftPadding + chartWidth);
      final cursorY = hoverY!.clamp(topPadding, topPadding + chartHeight);

      final cursorPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.7)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Vertical cursor line
      canvas.drawLine(
        Offset(cursorX, topPadding),
        Offset(cursorX, topPadding + chartHeight),
        cursorPaint,
      );

      // Horizontal cursor line
      canvas.drawLine(
        Offset(leftPadding, cursorY),
        Offset(leftPadding + chartWidth, cursorY),
        cursorPaint,
      );

      // Cursor circle
      canvas.drawCircle(
        Offset(cursorX, cursorY),
        6,
        Paint()..color = AppTheme.primaryColor,
      );

      // Coordinates display
      final xValue = ((cursorX - leftPadding) / chartWidth * 5).toStringAsFixed(1);
      final yValue = (1 - ((cursorY - topPadding) / chartHeight)).toStringAsFixed(2);

      final coordText = 'Day: $xValue, Value: $yValue';
      _drawText(
        canvas,
        coordText,
        Offset(cursorX + 10, cursorY - 20),
        TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        background: AppTheme.primaryColor,
      );
    }

    // ================= AXIS LABELS =================
    _drawText(
      canvas,
      'Inventory Level',
      Offset(15, topPadding + chartHeight / 2 - 20),
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      rotate: true,
    );

    _drawText(
      canvas,
      'Day',
      Offset(leftPadding + chartWidth / 2 - 10, size.height - 20),
      TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    TextStyle style, {
    bool rotate = false,
    Color? background,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    if (background != null) {
      final backgroundPaint = Paint()..color = background;
      final rect = Rect.fromCenter(
        center: Offset(pos.dx + painter.width / 2, pos.dy + painter.height / 2),
        width: painter.width + 8,
        height: painter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        backgroundPaint,
      );
    }

    canvas.save();
    if (rotate) {
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(-1.5708); // -90 degrees
      painter.paint(canvas, Offset.zero);
    } else {
      painter.paint(canvas, pos);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}