import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ApplyRheologyPage extends StatelessWidget {
  const ApplyRheologyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MudController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Rheology', style: TextStyle(fontSize: 14)),
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        toolbarHeight: 44,
      ),
      body: Obx(() {
        return Row(children: [
          SizedBox(width: 420, child: _buildRheologyTable(c)),
          VerticalDivider(width: 1, color: Colors.grey.shade300),
          Expanded(child: _buildGraph(c)),
        ]);
      }),
    );
  }

  Widget _buildRheologyTable(MudController c) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('Rheology',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
        const SizedBox(height: 8),

        // Model label
        Row(children: [
          Text('Model',
              style: TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(c.rheologyModel.value,
                style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
          ),
        ]),
        const SizedBox(height: 8),

        // Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(children: [
              // Header
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                ),
                child: Row(children: [
                  _tableHeaderCell('RPM/Property', width: 160),
                  ...c.samples.map((s) => Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.grey.shade200))),
                          child: Text(s,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary)),
                        ),
                      )),
                ]),
              ),
              // Rows
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: c.rheologyTable.entries.map((entry) {
                      final isCalcRow = double.tryParse(entry.key) == null;
                      return Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: isCalcRow ? const Color(0xFFFFFDE7) : Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 160,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(right: BorderSide(color: Colors.grey.shade200))),
                            child: Text(entry.key,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                  fontWeight: isCalcRow ? FontWeight.w600 : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis),
                          ),
                          ...entry.value.asMap().entries.map((cell) {
                            final isLast = cell.key == entry.value.length - 1;
                            return Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  border: Border(right: BorderSide(
                                    color: isLast ? Colors.transparent : Colors.grey.shade200))),
                                child: Obx(() => Text(
                                      cell.value.value.isEmpty ? '-' : cell.value.value,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: cell.value.value.isEmpty
                                            ? Colors.grey.shade400
                                            : AppTheme.textPrimary,
                                        fontWeight: isCalcRow ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    )),
                              ),
                            );
                          }),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildGraph(MudController c) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Shear Stress vs. Shear Rate',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _RheologyChart(c: c),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Wrap(
          spacing: 16,
          children: List.generate(c.samples.length, (i) {
            final color = _sampleColor(i);
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 24, height: 2, color: color),
              const SizedBox(width: 4),
              Text('Sample ${c.samples[i]}', style: const TextStyle(fontSize: 10)),
            ]);
          }),
        ),
      ]),
    );
  }

  Widget _tableHeaderCell(String text, {double? width}) {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return child;
  }

  static Color _sampleColor(int index) {
    const colors = [
      Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFFC62828),
      Color(0xFFE65100), Color(0xFF6A1B9A),
    ];
    return colors[index % colors.length];
  }
}

class _RheologyChart extends StatelessWidget {
  final MudController c;
  const _RheologyChart({required this.c});

  static const Map<String, double> _shearRates = {
    '600': 1021.8, '300': 510.9, '200': 340.6, '100': 170.3, '6': 10.2, '3': 5.1,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      return CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _ChartPainter(c: c, shearRates: _shearRates),
      );
    });
  }
}

class _ChartPainter extends CustomPainter {
  final MudController c;
  final Map<String, double> shearRates;

  _ChartPainter({required this.c, required this.shearRates});

  static const _colors = [
    Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFFC62828),
    Color(0xFFE65100), Color(0xFF6A1B9A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 50.0, rightPad = 16.0, topPad = 16.0, bottomPad = 40.0;
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    final List<List<Offset>> samplePoints = List.generate(c.samples.length, (_) => []);

    for (var entry in c.rheologyTable.entries) {
      final sr = shearRates[entry.key];
      if (sr == null) continue;
      for (int i = 0; i < entry.value.length; i++) {
        final ss = double.tryParse(entry.value[i].value);
        if (ss != null && ss > 0) samplePoints[i].add(Offset(sr, ss));
      }
    }

    for (var pts in samplePoints) {
      pts.sort((a, b) => a.dx.compareTo(b.dx));
    }

    double maxX = 1200, maxY = 50;
    for (var pts in samplePoints) {
      for (var p in pts) {
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }
    maxY = (maxY * 1.2).ceilToDouble();
    maxY = maxY < 10 ? 10 : maxY;

    // Background
    canvas.drawRect(
        Rect.fromLTWH(leftPad, topPad, chartW, chartH),
        Paint()..color = Colors.white);

    // Grid
    final gridPaint = Paint()..color = const Color(0xFFE0E8F0)..strokeWidth = 0.7;
    for (int i = 0; i <= 6; i++) {
      final x = leftPad + (i / 6) * chartW;
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + chartH), gridPaint);
      _drawText(canvas, ((i / 6) * maxX).round().toString(),
          Offset(x, topPad + chartH + 4), 9, Colors.grey.shade600, center: true);
    }
    for (int i = 0; i <= 5; i++) {
      final y = topPad + chartH - (i / 5) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);
      _drawText(canvas, ((i / 5) * maxY).round().toString(),
          Offset(leftPad - 4, y), 9, Colors.grey.shade600, rightAlign: true);
    }

    _drawText(canvas, 'Shear Rate (1/s)',
        Offset(leftPad + chartW / 2, topPad + chartH + 28), 10, Colors.grey.shade700, center: true);

    canvas.drawRect(Rect.fromLTWH(leftPad, topPad, chartW, chartH),
        Paint()..color = Colors.grey.shade400..strokeWidth = 1..style = PaintingStyle.stroke);

    // Plot lines
    for (int s = 0; s < samplePoints.length; s++) {
      final pts = samplePoints[s];
      if (pts.length < 2) continue;
      final linePaint = Paint()
        ..color = _colors[s % _colors.length]..strokeWidth = 2..style = PaintingStyle.stroke;
      final path = Path();
      bool first = true;
      for (var p in pts) {
        final px = leftPad + (p.dx / maxX) * chartW;
        final py = topPad + chartH - (p.dy / maxY) * chartH;
        first ? path.moveTo(px, py) : path.lineTo(px, py);
        first = false;
      }
      canvas.drawPath(path, linePaint);
      for (var p in pts) {
        canvas.drawCircle(
            Offset(leftPad + (p.dx / maxX) * chartW, topPad + chartH - (p.dy / maxY) * chartH),
            3, Paint()..color = _colors[s % _colors.length]);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, double size, Color color,
      {bool center = false, bool rightAlign = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    double dx = pos.dx;
    if (center) dx -= tp.width / 2;
    if (rightAlign) dx -= tp.width;
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_ChartPainter old) => true;
}