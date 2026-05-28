import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class Survey3DTab extends StatelessWidget {
  Survey3DTab({super.key});

  final SurveyController controller = Get.find<SurveyController>();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 6, 10),
                child: CustomPaint(
                  painter: _Survey3DPainter(
                    points: controller.plotPoints,
                    rotationX: controller.rotationX.value,
                    rotationY: controller.rotationY.value,
                    zoom: controller.zoom.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Container(
              width: 34,
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFC8CED6)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  _tool(
                    icon: Icons.undo,
                    tooltip: 'Rotate Left',
                    onTap: controller.rotateLeft,
                  ),
                  _tool(
                    icon: Icons.redo,
                    tooltip: 'Rotate Right',
                    onTap: controller.rotateRight,
                  ),
                  _tool(
                    icon: Icons.keyboard_double_arrow_down,
                    tooltip: 'Tilt Down',
                    onTap: controller.rotateDown,
                  ),
                  _tool(
                    icon: Icons.rotate_90_degrees_ccw,
                    tooltip: 'Tilt Up',
                    onTap: controller.rotateUp,
                  ),
                  _tool(
                    icon: Icons.arrow_upward,
                    tooltip: 'Move Up',
                    onTap: controller.rotateUp,
                  ),
                  _tool(
                    icon: Icons.arrow_downward,
                    tooltip: 'Move Down',
                    onTap: controller.rotateDown,
                  ),
                  _tool(
                    icon: Icons.arrow_back,
                    tooltip: 'Move Left',
                    onTap: controller.rotateLeft,
                  ),
                  _tool(
                    icon: Icons.arrow_forward,
                    tooltip: 'Move Right',
                    onTap: controller.rotateRight,
                  ),
                  _tool(
                    icon: Icons.zoom_in,
                    tooltip: 'Zoom In',
                    onTap: controller.zoomIn,
                  ),
                  _tool(
                    icon: Icons.zoom_out,
                    tooltip: 'Zoom Out',
                    onTap: controller.zoomOut,
                  ),
                  _tool(
                    icon: Icons.camera_alt_outlined,
                    tooltip: 'Reset View',
                    onTap: controller.reset3DView,
                  ),
                  _tool(
                    icon: Icons.center_focus_strong,
                    tooltip: 'Center',
                    onTap: controller.reset3DView,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tool({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 26,
            height: 26,
            child: Icon(icon, size: 18, color: const Color(0xFF2A82E5)),
          ),
        ),
      ),
    );
  }
}

class _Survey3DPainter extends CustomPainter {
  _Survey3DPainter({
    required this.points,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
  });

  final List<dynamic> points;
  final double rotationX;
  final double rotationY;
  final double zoom;

  static const double _minEastWest = -12000;
  static const double _maxEastWest = 12000;
  static const double _minNorthSouth = 0;
  static const double _maxNorthSouth = 12000;
  static const double _maxTvd = 12000;
  static const int _gridDivisions = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = _buildProjection(size);
    final gridPaint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 0.9;
    final axisPaint = Paint()
      ..color = const Color(0xFF202020)
      ..strokeWidth = 1.2;
    final pathPaint = Paint()
      ..color = const Color(0xFF707070)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final pathShadowPaint = Paint()
      ..color = const Color(0xFF4A4A4A)
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cube = [
      const _V3(0, 0, 0),
      const _V3(1, 0, 0),
      const _V3(1, 1, 0),
      const _V3(0, 1, 0),
      const _V3(0, 0, 1),
      const _V3(1, 0, 1),
      const _V3(1, 1, 1),
      const _V3(0, 1, 1),
    ];
    const cubeEdges = [
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 0],
      [4, 5],
      [5, 6],
      [6, 7],
      [7, 4],
      [0, 4],
      [1, 5],
      [2, 6],
      [3, 7],
    ];

    final projectedCube = cube.map((point) {
      return _project(point, projection);
    }).toList();

    for (final edge in cubeEdges) {
      canvas.drawLine(
        projectedCube[edge[0]],
        projectedCube[edge[1]],
        axisPaint,
      );
    }

    for (var i = 1; i < _gridDivisions; i++) {
      final t = i / _gridDivisions;

      _draw3DLine(
        canvas,
        _V3(t, 0, 1),
        _V3(t, 1, 1),
        projection,
        gridPaint,
      );
      _draw3DLine(
        canvas,
        _V3(0, t, 1),
        _V3(1, t, 1),
        projection,
        gridPaint,
      );
      _draw3DLine(
        canvas,
        _V3(t, 1, 0),
        _V3(t, 1, 1),
        projection,
        gridPaint,
      );
      _draw3DLine(
        canvas,
        _V3(0, t, 0),
        _V3(0, t, 1),
        projection,
        gridPaint,
      );
      _draw3DLine(
        canvas,
        _V3(0, 1, t),
        _V3(1, 1, t),
        projection,
        gridPaint,
      );
      _draw3DLine(
        canvas,
        _V3(1, 0, t),
        _V3(1, 1, t),
        projection,
        gridPaint,
      );
    }

    if (points.isNotEmpty) {
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        final normalized = _V3(
          _normalizeEastWest(point.eastWest as double),
          _normalizeNorthSouth(point.northSouth as double),
          _normalizeTvd(point.tvd as double),
        );
        final projected = _project(normalized, projection);
        if (i == 0) {
          path.moveTo(projected.dx, projected.dy);
        } else {
          path.lineTo(projected.dx, projected.dy);
        }
      }
      canvas.drawPath(path, pathShadowPaint);
      canvas.drawPath(path, pathPaint);
    }

    _drawAxisLabels(canvas, projection);

    _drawLabel(
      canvas,
      'E+/- ${AppUnits.unitText('(ft)')}',
      _project(const _V3(0.5, 0, 1), projection) + const Offset(-34, 24),
    );
    _drawRotatedLabel(
      canvas,
      'N+/-S ${AppUnits.unitText('(ft)')}',
      _project(const _V3(1, 0.5, 1), projection) + const Offset(28, 16),
      0.78,
    );
    _drawRotatedLabel(
      canvas,
      'TVD ${AppUnits.unitText('(ft)')}',
      _project(const _V3(1, 0, 0.5), projection) + const Offset(42, -12),
      -1.57,
    );
    _drawViewTriad(canvas, size);
  }

  double _normalizeEastWest(double value) {
    final normalized =
        (value - _minEastWest) / (_maxEastWest - _minEastWest);
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  double _normalizeNorthSouth(double value) {
    final normalized =
        (value - _minNorthSouth) / (_maxNorthSouth - _minNorthSouth);
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  double _normalizeTvd(double value) {
    return (value / _maxTvd).clamp(0.0, 1.0).toDouble();
  }

  void _draw3DLine(
    Canvas canvas,
    _V3 start,
    _V3 end,
    _Projection projection,
    Paint paint,
  ) {
    canvas.drawLine(
      _project(start, projection),
      _project(end, projection),
      paint,
    );
  }

  void _drawAxisLabels(Canvas canvas, _Projection projection) {
    for (var i = 0; i <= _gridDivisions; i++) {
      final t = i / _gridDivisions;
      final east = _minEastWest + ((_maxEastWest - _minEastWest) * t);
      final north = _minNorthSouth + ((_maxNorthSouth - _minNorthSouth) * t);
      final tvd = _maxTvd * t;

      _drawSmallLabel(
        canvas,
        east.toStringAsFixed(0),
        _project(_V3(t, 0, 1), projection) + const Offset(-20, 8),
      );
      _drawSmallLabel(
        canvas,
        north.toStringAsFixed(0),
        _project(_V3(1, t, 1), projection) + const Offset(6, 6),
      );
      _drawSmallLabel(
        canvas,
        tvd.toStringAsFixed(0),
        _project(_V3(1, 0, t), projection) + const Offset(7, -5),
      );
    }
  }

  _Projection _buildProjection(Size size) {
    final side = math.min(size.width * 0.46, size.height * 0.58) * zoom;
    final xVec = Offset(side * 0.72, side * 0.12);
    final yVec = Offset(-side * 0.46, side * 0.24);
    final zVec = Offset(0, side * 0.78);
    final topCenter = Offset(size.width * 0.50, size.height * 0.28);
    final origin = topCenter - ((xVec + yVec) / 2);
    return _Projection(origin: origin, x: xVec, y: yVec, z: zVec);
  }

  Offset _project(_V3 point, _Projection projection) {
    final yawDelta = (rotationY - 0.75).clamp(-0.6, 0.6).toDouble();
    final pitchDelta = (rotationX + 0.55).clamp(-0.8, 0.8).toDouble();
    final xVec = projection.x + Offset(yawDelta * 34, yawDelta * 5);
    final yVec = projection.y + Offset(yawDelta * 20, yawDelta * 8);
    final zVec = projection.z + Offset(0, pitchDelta * 26);
    return projection.origin +
        (xVec * point.x) +
        (yVec * point.y) +
        (zVec * point.z);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF202020)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawSmallLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, color: Color(0xFF202020)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawViewTriad(Canvas canvas, Size size) {
    final origin = Offset(size.width - 88, 54);
    final paint = Paint()
      ..color = const Color(0xFF202020)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final hintPaint = Paint()
      ..color = const Color(0xFF909090)
      ..strokeWidth = 1;

    canvas.drawLine(origin, origin + const Offset(-28, -2), paint);
    canvas.drawLine(origin, origin + const Offset(8, 4), paint);
    canvas.drawLine(origin, origin + const Offset(0, 30), paint);
    canvas.drawLine(
      origin + const Offset(-10, -10),
      origin + const Offset(22, -10),
      hintPaint,
    );
    canvas.drawCircle(origin + const Offset(0, 30), 2.5, paint);
  }

  void _drawRotatedLabel(
    Canvas canvas,
    String text,
    Offset offset,
    double angle,
  ) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    _drawLabel(canvas, text, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Survey3DPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom;
  }
}

class _V3 {
  const _V3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class _Projection {
  const _Projection({
    required this.origin,
    required this.x,
    required this.y,
    required this.z,
  });

  final Offset origin;
  final Offset x;
  final Offset y;
  final Offset z;
}
