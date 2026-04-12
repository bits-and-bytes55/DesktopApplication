import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertUsagePage extends StatefulWidget {
  const AlertUsagePage({super.key});

  @override
  State<AlertUsagePage> createState() => _AlertUsagePageState();
}

class _AlertUsagePageState extends State<AlertUsagePage> {
  double? hoverX;
  double? hoverY;
  List<Map<String, double>> dataPoints = [
    {'x': 0, 'y': 0.2},
    {'x': 1, 'y': 0.8},
    {'x': 2, 'y': 0.4},
    {'x': 3, 'y': 0.6},
    {'x': 4, 'y': 0.9},
    {'x': 5, 'y': 0.3},
    {'x': 6, 'y': 0.7},
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
                    'Usage Chart Analysis',
                    style: AppTheme.titleMedium.copyWith(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
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
                      'Daily Usage Pattern',
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
                    painter: _EnhancedUsageChartPainter(
                      hoverX: hoverX,
                      hoverY: hoverY,
                      dataPoints: dataPoints,
                    ),
                    child: Container(),
                  ),
                ),
              ),
            ),

            // CHART INFO
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
                  Text(
                    'Hover over chart to see cursor lines • Drag to interact',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${dataPoints.length} Data Points',
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

class _EnhancedUsageChartPainter extends CustomPainter {
  final double? hoverX;
  final double? hoverY;
  final List<Map<String, double>> dataPoints;

  _EnhancedUsageChartPainter({
    this.hoverX,
    this.hoverY,
    required this.dataPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 60;
    const double bottomPadding = 50;
    const double topPadding = 30;
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

      final label = '${100 - i * 20}';
      _drawText(
        canvas,
        label,
        Offset(20, y - 6),
        TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // ================= GRID VERTICAL =================
    for (int i = 0; i <= 6; i++) {
      final x = leftPadding + chartWidth * i / 6;
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

    // ================= PLOT DATA POINTS =================
    final linePaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final x = leftPadding + (point['x']! / 6) * chartWidth;
      final y = topPadding + chartHeight - (point['y']! * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = AppTheme.primaryColor.withOpacity(0.3));
    }

    // Draw line
    canvas.drawPath(path, linePaint);

    // ================= CURSOR LINES =================
    if (hoverX != null && hoverY != null) {
      final cursorX = hoverX!.clamp(leftPadding, leftPadding + chartWidth);
      final cursorY = hoverY!.clamp(topPadding, topPadding + chartHeight);

      final cursorPaint = Paint()
        ..color = AppTheme.secondaryColor.withOpacity(0.7)
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
        Paint()..color = AppTheme.accentColor,
      );

      // Coordinates display
      final xValue = ((cursorX - leftPadding) / chartWidth * 6).toStringAsFixed(1);
      final yValue = (100 - ((cursorY - topPadding) / chartHeight * 100)).toStringAsFixed(1);

      final coordText = 'X: $xValue, Y: $yValue%';
      _drawText(
        canvas,
        coordText,
        Offset(cursorX + 10, cursorY - 20),
        TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        background: AppTheme.secondaryColor,
      );
    }

    // ================= AXIS LABELS =================
    _drawText(
      canvas,
      'Usage (%)',
      Offset(10, topPadding + chartHeight / 2 - 20),
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
      Offset(leftPadding + chartWidth / 2 - 15, size.height - 20),
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