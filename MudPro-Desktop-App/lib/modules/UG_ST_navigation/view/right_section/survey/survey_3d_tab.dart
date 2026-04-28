import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';

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
                padding: const EdgeInsets.all(10),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Color(0xFFC8CED6))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _tool(Icons.arrow_back, controller.rotateLeft),
                  _tool(Icons.arrow_forward, controller.rotateRight),
                  _tool(Icons.arrow_upward, controller.rotateUp),
                  _tool(Icons.arrow_downward, controller.rotateDown),
                  _tool(Icons.zoom_in, controller.zoomIn),
                  _tool(Icons.zoom_out, controller.zoomOut),
                  _tool(Icons.refresh, controller.reset3DView),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tool(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: onTap,
        child: Icon(icon, size: 18, color: const Color(0xFF2780E3)),
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
    final frame = Rect.fromLTWH(42, 12, size.width - 70, size.height - 24);
    final gridPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1;
    final pathPaint = Paint()
      ..color = const Color(0xFFD8D8D8)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final axisPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1.2;

    final cube = [
      _V3(-1, -1, 0),
      _V3(1, -1, 0),
      _V3(1, 1, 0),
      _V3(-1, 1, 0),
      _V3(-1, -1, 1),
      _V3(1, -1, 1),
      _V3(1, 1, 1),
      _V3(-1, 1, 1),
    ];

    final projectedCube = cube
        .map((point) => _project(point, frame.center, frame.size))
        .toList();
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
        1,
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
    final scale = (math.min(size.width, size.height) / 3.8) * zoom;
    final depthScale = perspective / (perspective + finalZ + 1.3);

    return Offset(
      center.dx + (rotatedX * scale * depthScale),
      center.dy + (finalY * scale * depthScale),
    );
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
