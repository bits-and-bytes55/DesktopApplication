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
        color: Colors.black,
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

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Rect.fromLTWH(76, 44, size.width - 150, size.height - 108);
    final gridPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFE5E5E5)
      ..strokeWidth = 1.2;
    final pathPaint = Paint()
      ..color = const Color(0xFFD6D6D6)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cube = [
      const _V3(-1, -1, 0),
      const _V3(1, -1, 0),
      const _V3(1, 1, 0),
      const _V3(-1, 1, 0),
      const _V3(-1, -1, 1),
      const _V3(1, -1, 1),
      const _V3(1, 1, 1),
      const _V3(-1, 1, 1),
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

    final projectedCube = cube
        .map((point) => _project(point, frame.center, frame.size))
        .toList();

    for (final edge in cubeEdges) {
      canvas.drawLine(
        projectedCube[edge[0]],
        projectedCube[edge[1]],
        gridPaint,
      );
    }

    for (var i = 1; i < 5; i++) {
      final t = i / 5;
      final a = _interpolate(cube[0], cube[1], t);
      final b = _interpolate(cube[3], cube[2], t);
      final c = _interpolate(cube[4], cube[5], t);
      final d = _interpolate(cube[7], cube[6], t);

      canvas.drawLine(
        _project(a, frame.center, frame.size),
        _project(b, frame.center, frame.size),
        gridPaint,
      );
      canvas.drawLine(
        _project(c, frame.center, frame.size),
        _project(d, frame.center, frame.size),
        gridPaint,
      );
    }

    if (points.isNotEmpty) {
      final minE = points.map((e) => e.eastWest as double).reduce(math.min);
      final maxE = points.map((e) => e.eastWest as double).reduce(math.max);
      final minN = points.map((e) => e.northSouth as double).reduce(math.min);
      final maxN = points.map((e) => e.northSouth as double).reduce(math.max);
      final maxT = math.max(
        1.0,
        points.map((e) => e.tvd as double).reduce(math.max),
      );
      final eRange = (maxE - minE).abs() < 0.001 ? 1.0 : (maxE - minE);
      final nRange = (maxN - minN).abs() < 0.001 ? 1.0 : (maxN - minN);

      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        final normalized = _V3(
          ((point.eastWest - minE) / eRange) * 2 - 1,
          ((point.northSouth - minN) / nRange) * 2 - 1,
          (point.tvd / maxT),
        );
        final projected = _project(normalized, frame.center, frame.size);
        if (i == 0) {
          path.moveTo(projected.dx, projected.dy);
        } else {
          path.lineTo(projected.dx, projected.dy);
        }
      }
      canvas.drawPath(path, pathPaint);
    }

    canvas.drawLine(
      _project(const _V3(-1, -1, 0), frame.center, frame.size),
      _project(const _V3(1, -1, 0), frame.center, frame.size),
      axisPaint,
    );
    canvas.drawLine(
      _project(const _V3(-1, -1, 0), frame.center, frame.size),
      _project(const _V3(-1, 1, 0), frame.center, frame.size),
      axisPaint,
    );
    canvas.drawLine(
      _project(const _V3(-1, -1, 0), frame.center, frame.size),
      _project(const _V3(-1, -1, 1), frame.center, frame.size),
      axisPaint,
    );

    _drawLabel(
      canvas,
      'E+/- ${AppUnits.unitText('(ft)')}',
      Offset(frame.left + 36, frame.bottom + 26),
    );
    _drawRotatedLabel(
      canvas,
      'N+/-S ${AppUnits.unitText('(ft)')}',
      Offset(frame.right + 32, frame.center.dy - 20),
      -0.88,
    );
    _drawRotatedLabel(
      canvas,
      'TVD ${AppUnits.unitText('(ft)')}',
      Offset(frame.left - 36, frame.center.dy + 8),
      -1.57,
    );
  }

  _V3 _interpolate(_V3 a, _V3 b, double t) {
    return _V3(
      a.x + ((b.x - a.x) * t),
      a.y + ((b.y - a.y) * t),
      a.z + ((b.z - a.z) * t),
    );
  }

  Offset _project(_V3 point, Offset center, Size size) {
    final rx = rotationX;
    final ry = rotationY;

    final cosY = math.cos(ry);
    final sinY = math.sin(ry);
    final rotatedX = (point.x * cosY) - (point.y * sinY);
    final rotatedY = (point.x * sinY) + (point.y * cosY);

    final cosX = math.cos(rx);
    final sinX = math.sin(rx);
    final finalY = (rotatedY * cosX) - (point.z * sinX);
    final finalZ = (rotatedY * sinX) + (point.z * cosX);

    const perspective = 2.8;
    final scale = (math.min(size.width, size.height) / 3.9) * zoom;
    final depthScale = perspective / (perspective + finalZ + 1.35);

    return Offset(
      center.dx + (rotatedX * scale * depthScale),
      center.dy + (finalY * scale * depthScale),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 13, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
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
