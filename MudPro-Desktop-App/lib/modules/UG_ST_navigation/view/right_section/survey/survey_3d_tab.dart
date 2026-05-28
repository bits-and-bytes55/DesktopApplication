import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/survey_model.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class Survey3DTab extends StatelessWidget {
  Survey3DTab({super.key});

  final SurveyController controller = Get.find<SurveyController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return WellPath3DViewer(
        surveyPoints: controller.plotPoints.map(SurveyPoint.fromPlot).toList(),
        rotationX: controller.rotationX.value,
        rotationY: controller.rotationY.value,
        zoom: controller.zoom.value,
        onRotateLeft: controller.rotateLeft,
        onRotateRight: controller.rotateRight,
        onTiltDown: controller.rotateDown,
        onTiltUp: controller.rotateUp,
        onZoomIn: controller.zoomIn,
        onZoomOut: controller.zoomOut,
        onReset: controller.reset3DView,
        onPanUpdate: (details) {
          controller.rotationY.value += details.delta.dx * 0.01;
          controller.rotationX.value =
              (controller.rotationX.value + details.delta.dy * 0.005)
                  .clamp(-0.6, 0.6)
                  .toDouble();
        },
      );
    });
  }
}

class WellPath3DViewer extends StatelessWidget {
  const WellPath3DViewer({
    super.key,
    required this.surveyPoints,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onTiltDown,
    required this.onTiltUp,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onPanUpdate,
  });

  final List<SurveyPoint> surveyPoints;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onTiltDown;
  final VoidCallback onTiltUp;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final GestureDragUpdateCallback onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final bounds = _Survey3DBounds.fromPoints(surveyPoints);

    return Container(
      color: const Color(0xFFE5E5E5),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: onPanUpdate,
              child: CustomPaint(
                painter: WellPath3DPainter(
                  points: surveyPoints,
                  rotationX: rotationX,
                  rotationY: rotationY,
                  zoom: zoom,
                  minEastWest: bounds.minEastWest,
                  maxEastWest: bounds.maxEastWest,
                  eastWestAxisMax: bounds.eastWestAxisMax,
                  minNorthSouth: bounds.minNorthSouth,
                  maxNorthSouth: bounds.maxNorthSouth,
                  northSouthAxisMax: bounds.northSouthAxisMax,
                  maxTvd: bounds.maxTvd,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          _Survey3DTools(
            onRotateLeft: onRotateLeft,
            onRotateRight: onRotateRight,
            onTiltDown: onTiltDown,
            onTiltUp: onTiltUp,
            onZoomIn: onZoomIn,
            onZoomOut: onZoomOut,
            onReset: onReset,
          ),
        ],
      ),
    );
  }
}

class _Survey3DTools extends StatelessWidget {
  const _Survey3DTools({
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onTiltDown,
    required this.onTiltUp,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onTiltDown;
  final VoidCallback onTiltUp;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      margin: const EdgeInsets.only(right: 4),
      color: const Color(0xFFEFEFEF),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _tool(Icons.undo, 'Rotate Left', onRotateLeft),
          _tool(Icons.redo, 'Rotate Right', onRotateRight),
          _tool(Icons.keyboard_double_arrow_down, 'Tilt Down', onTiltDown),
          _tool(Icons.rotate_90_degrees_ccw, 'Tilt Up', onTiltUp),
          const _ToolDivider(),
          _tool(Icons.arrow_upward, 'Tilt Up', onTiltUp),
          _tool(Icons.arrow_downward, 'Tilt Down', onTiltDown),
          _tool(Icons.arrow_back, 'Rotate Left', onRotateLeft),
          _tool(Icons.arrow_forward, 'Rotate Right', onRotateRight),
          const _ToolDivider(),
          _tool(Icons.zoom_in, 'Zoom In', onZoomIn),
          _tool(Icons.zoom_out, 'Zoom Out', onZoomOut),
          const _ToolDivider(),
          _tool(Icons.camera_alt_outlined, 'Camera', onReset),
          _tool(Icons.pan_tool_alt, 'Pan', onReset),
          _tool(Icons.rotate_left, 'Reset View', onReset),
          _tool(Icons.view_in_ar, '3D View', onReset),
          _tool(Icons.swap_vert, 'Depth Axis', onReset),
          _tool(Icons.text_rotation_down, 'Label Axis', onReset),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _tool(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 25,
          child: Icon(icon, size: 19, color: const Color(0xFF2C9FE7)),
        ),
      ),
    );
  }
}

class _ToolDivider extends StatelessWidget {
  const _ToolDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFD4D4D4),
    );
  }
}

class SurveyPoint {
  const SurveyPoint({
    required this.md,
    required this.inclination,
    required this.azimuth,
    required this.tvd,
    required this.northing,
    required this.easting,
  });

  factory SurveyPoint.fromPlot(SurveyPlotPoint point) {
    return SurveyPoint(
      md: point.md,
      inclination: point.inc,
      azimuth: point.azi,
      tvd: point.tvd,
      northing: point.northSouth,
      easting: point.eastWest,
    );
  }

  final double md;
  final double inclination;
  final double azimuth;
  final double tvd;
  final double northing;
  final double easting;
}

class WellPath3DPainter extends CustomPainter {
  WellPath3DPainter({
    required this.points,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.minEastWest,
    required this.maxEastWest,
    required this.eastWestAxisMax,
    required this.minNorthSouth,
    required this.maxNorthSouth,
    required this.northSouthAxisMax,
    required this.maxTvd,
  });

  final List<SurveyPoint> points;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final double minEastWest;
  final double maxEastWest;
  final double eastWestAxisMax;
  final double minNorthSouth;
  final double maxNorthSouth;
  final double northSouthAxisMax;
  final double maxTvd;

  static const int _gridDivisions = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = _buildProjection(size);

    _drawGrid(canvas, projection);
    _drawBoundingBox(canvas, projection);

    if (points.isNotEmpty) {
      _drawWellPath(canvas, projection);
    }
    _drawTvdLabels(canvas, projection);
    _drawNorthSouthLabels(canvas, projection);
    _drawEastWestLabels(canvas, projection);
  }

  _Projection _buildProjection(Size size) {
    final side = math.min(size.width * 0.64, size.height * 0.76) * zoom;
    final xVec = Offset(-side * 0.47, side * 0.09);
    final yVec = Offset(side * 0.47, side * 0.09);
    final zVec = Offset(0, side * 0.50);
    final origin = Offset(size.width * 0.50, size.height * 0.11);
    return _Projection(origin: origin, x: xVec, y: yVec, z: zVec);
  }

  void _drawGrid(Canvas canvas, _Projection projection) {
    final gridPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final eastWestStepCount = _eastWestStepCount();
    final tvdStepCount = _tvdStepCount();
    final northSouthStepCount = _northSouthStepCount();

    for (var i = 0; i <= eastWestStepCount; i++) {
      final t = i / eastWestStepCount;

      _draw3DLine(canvas, _V3(t, 0, 1), _V3(t, 1, 1), projection, gridPaint);
      if (i > 0) {
        _draw3DLine(
          canvas,
          _V3(t, 0, 0),
          _V3(t, 0, 1),
          projection,
          gridPaint,
        );
      }
    }

    for (var i = 0; i <= northSouthStepCount; i++) {
      final t = i / northSouthStepCount;

      _draw3DLine(canvas, _V3(0, t, 1), _V3(1, t, 1), projection, gridPaint);
      if (i > 0) {
        _draw3DLine(
          canvas,
          _V3(0, t, 0),
          _V3(0, t, 1),
          projection,
          gridPaint,
        );
      }
    }

    for (var i = 0; i <= tvdStepCount; i++) {
      final t = i / tvdStepCount;
      _draw3DLine(
        canvas,
        _V3(0, 0, t),
        _V3(1, 0, t),
        projection,
        gridPaint,
      );
      _draw3DLine(
        canvas,
        _V3(0, 0, t),
        _V3(0, 1, t),
        projection,
        gridPaint,
      );
    }
  }

  void _drawBoundingBox(Canvas canvas, _Projection projection) {
    final boxPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    _draw3DLine(canvas, _V3(0, 0, 1), _V3(1, 0, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(1, 0, 1), _V3(1, 1, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(1, 1, 1), _V3(0, 1, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(0, 1, 1), _V3(0, 0, 1), projection, boxPaint);

    _draw3DLine(canvas, _V3(0, 0, 0), _V3(1, 0, 0), projection, boxPaint);
    _draw3DLine(canvas, _V3(0, 1, 0), _V3(0, 0, 0), projection, boxPaint);

    _draw3DLine(canvas, _V3(0, 0, 0), _V3(0, 0, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(1, 0, 0), _V3(1, 0, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(0, 1, 0), _V3(0, 1, 1), projection, boxPaint);
  }

  void _drawWellPath(Canvas canvas, _Projection projection) {
    final pathPaint = Paint()
      ..color = const Color(0xFF4D4D4D)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final shadowPaint = Paint()
      ..color = const Color(0xFF777777)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final shadowPath = Path();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final projected = _project(_normalPoint(point), projection);

      if (i == 0) {
        path.moveTo(projected.dx, projected.dy);
        shadowPath.moveTo(projected.dx, projected.dy);
      } else {
        path.lineTo(projected.dx, projected.dy);
        shadowPath.lineTo(projected.dx, projected.dy);
      }
    }

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(path, pathPaint);
  }

  void _drawNorthSouthLabels(Canvas canvas, _Projection projection) {
    final labelStyle = const TextStyle(
      color: Colors.black,
      fontSize: 10,
    );
    final titleStyle = const TextStyle(
      color: Colors.black,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
    final eastWestStepCount = _eastWestStepCount();
    final stepCount = _northSouthStepCount();
    final rowY = (stepCount - 0.5) / stepCount;
    final valueSpacing = 1 / eastWestStepCount;
    final firstValueX = 0.5 / eastWestStepCount;
    final axisStart = _project(_V3(firstValueX, rowY, 1), projection);
    final axisEnd = _project(
      _V3(firstValueX + ((stepCount - 1) * valueSpacing), rowY, 1),
      projection,
    );
    var axisAngle = math.atan2(
      axisEnd.dy - axisStart.dy,
      axisEnd.dx - axisStart.dx,
    );
    if (math.cos(axisAngle) < 0) {
      axisAngle += math.pi;
    }
    if (axisAngle > math.pi) {
      axisAngle -= math.pi * 2;
    }
    final valueAngle = axisAngle + 0.40;

    for (var i = 1; i <= stepCount; i++) {
      final value = i * 2000;
      final valueX = firstValueX + ((i - 1) * valueSpacing);
      final position = _project(
        _V3(valueX, rowY, 1),
        projection,
      );
      final offset = _frontOutsideOffset(
        position,
        _project(_V3(valueX, 0, 1), projection),
        24,
      );
      _drawRotatedCenteredText(
        canvas,
        _formatAxisValue(value),
        position + offset,
        value == 2000 ? valueAngle - 0.12 : valueAngle,
        labelStyle,
      );
    }

    final firstTitleX = firstValueX;
    final lastTitleX = firstValueX + ((stepCount - 1) * valueSpacing);
    final titleStart = _project(_V3(firstTitleX, rowY, 1), projection);
    final titleEnd = _project(_V3(lastTitleX, rowY, 1), projection);
    final titleCenterStart = _project(_V3(firstTitleX, 0, 1), projection);
    final titleCenterEnd = _project(_V3(lastTitleX, 0, 1), projection);
    final titleBase = (titleStart + titleEnd) / 2;
    final titleCenterBase = (titleCenterStart + titleCenterEnd) / 2;
    final titlePosition =
        titleBase + _frontOutsideOffset(titleBase, titleCenterBase, 75);
    _drawRotatedCenteredText(
      canvas,
      'N+/S ${AppUnits.unitText('(ft)')}',
      titlePosition,
      axisAngle,
      titleStyle,
    );
  }

  void _drawEastWestLabels(Canvas canvas, _Projection projection) {
    final labelStyle = const TextStyle(
      color: Colors.black,
      fontSize: 10,
    );
    final titleStyle = const TextStyle(
      color: Colors.black,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
    final eastWestStepCount = _eastWestStepCount();
    final northSouthStepCount = _northSouthStepCount();
    final labelX = (eastWestStepCount - 0.5) / eastWestStepCount;
    final axisStart = _project(
      _V3(labelX, 0.20 / northSouthStepCount, 1),
      projection,
    );
    final axisEnd = _project(
      _V3(labelX, (northSouthStepCount - 0.5) / northSouthStepCount, 1),
      projection,
    );
    final axisAngle = math.atan2(
      axisEnd.dy - axisStart.dy,
      axisEnd.dx - axisStart.dx,
    );

    for (var i = 0; i < northSouthStepCount; i++) {
      final value = -(i * 2000);
      final y = (i + 0.5) / northSouthStepCount;
      final edgePosition = _project(_V3(labelX, y, 1), projection);
      final labelOffset = _frontOutsideOffset(
        edgePosition,
        _project(_V3(0, y, 1), projection),
        24,
      );
      _drawRotatedCenteredText(
        canvas,
        _formatAxisValue(value),
        edgePosition + labelOffset,
        axisAngle - 0.50,
        labelStyle,
      );
    }

    final firstTitleY = 0.5 / northSouthStepCount;
    final lastTitleY = (northSouthStepCount - 0.5) / northSouthStepCount;
    final titleStart = _project(_V3(labelX, firstTitleY, 1), projection);
    final titleEnd = _project(_V3(labelX, lastTitleY, 1), projection);
    final titleCenterStart = _project(_V3(0, firstTitleY, 1), projection);
    final titleCenterEnd = _project(_V3(0, lastTitleY, 1), projection);
    final titleBase = (titleStart + titleEnd) / 2;
    final titleCenterBase = (titleCenterStart + titleCenterEnd) / 2;
    final titlePosition =
        titleBase + _frontOutsideOffset(titleBase, titleCenterBase, 75);
    _drawRotatedCenteredText(
      canvas,
      'E+/W ${AppUnits.unitText('(ft)')}',
      titlePosition,
      axisAngle,
      titleStyle,
    );
  }

  void _drawTvdLabels(Canvas canvas, _Projection projection) {
    final edge = _rightMostVerticalEdge(projection);
    final labelStyle = const TextStyle(
      color: Colors.black,
      fontSize: 10,
    );
    final titleStyle = const TextStyle(
      color: Colors.black,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );
    final stepCount = _tvdStepCount();

    for (var i = 0; i <= stepCount; i++) {
      final value = i * 2000;
      final t = value / maxTvd;
      final position = _project(_V3(edge.x, edge.y, t), projection);
      _drawText(
        canvas,
        _formatAxisValue(value),
        position + const Offset(10, -6),
        labelStyle,
      );
    }

    final titlePosition = _project(_V3(edge.x, edge.y, 0.5), projection);
    _drawRotatedCenteredText(
      canvas,
      'TVD ${AppUnits.unitText('(ft)')}',
      titlePosition + const Offset(58, 0),
      -math.pi / 2,
      titleStyle,
    );
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

  _V3 _normalPoint(SurveyPoint point) {
    return _V3(
      _normalize(point.easting, minEastWest, maxEastWest),
      _normalize(point.northing, minNorthSouth, maxNorthSouth),
      _normalize(point.tvd, 0, maxTvd),
    );
  }

  double _normalize(double value, double min, double max) {
    if ((max - min).abs() < 0.0001) return 0.5;
    return ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
  }

  int _tvdStepCount() {
    return math.max(1, (maxTvd / 2000).round());
  }

  int _northSouthStepCount() {
    return math.max(1, (northSouthAxisMax / 2000).round());
  }

  int _eastWestStepCount() {
    return math.max(1, (eastWestAxisMax / 2000).round());
  }

  Offset _project(_V3 point, _Projection projection) {
    final yaw = rotationY - 0.75;
    final pitch = rotationX - 0.55;
    final centeredX = point.x - 0.5;
    final centeredY = point.y - 0.5;
    final cosYaw = math.cos(yaw);
    final sinYaw = math.sin(yaw);
    final rotatedX = (centeredX * cosYaw) - (centeredY * sinYaw) + 0.5;
    final rotatedY = (centeredX * sinYaw) + (centeredY * cosYaw) + 0.5;
    final zVec = projection.z + Offset(0, pitch * 24);

    return projection.origin +
        (projection.x * rotatedX) +
        (projection.y * rotatedY) +
        (zVec * point.z);
  }

  _V3 _rightMostVerticalEdge(_Projection projection) {
    const edges = [
      _V3(0, 0, 0),
      _V3(1, 0, 0),
      _V3(0, 1, 0),
      _V3(1, 1, 0),
    ];
    var selected = edges.first;
    var selectedX = _project(const _V3(0, 0, 0.5), projection).dx;

    for (final edge in edges) {
      final x = _project(_V3(edge.x, edge.y, 0.5), projection).dx;
      if (x > selectedX) {
        selected = edge;
        selectedX = x;
      }
    }
    return selected;
  }

  Offset _outsideFromCenterOffset(Offset edge, Offset center, double distance) {
    final delta = edge - center;
    if (delta.distance < 0.001) return Offset(0, distance);
    return Offset(
      (delta.dx / delta.distance) * distance,
      (delta.dy / delta.distance) * distance,
    );
  }

  Offset _frontOutsideOffset(Offset edge, Offset center, double distance) {
    var offset = _outsideFromCenterOffset(edge, center, distance);
    if (offset.dy < 0) {
      offset = -offset;
    }
    return offset + const Offset(0, 10);
  }

  String _formatAxisValue(int value) {
    final prefix = value < 0 ? '-' : '';
    final absolute = value.abs();
    if (absolute < 10000) return '$prefix$absolute';
    final text = absolute.toString();
    return '$prefix${text.substring(0, text.length - 3)},${text.substring(text.length - 3)}';
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawRotatedCenteredText(
    Canvas canvas,
    String text,
    Offset offset,
    double angle,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    painter.paint(
      canvas,
      Offset(-(painter.width / 2), -(painter.height / 2)),
    );
    canvas.restore();
  }

  void _drawRotatedText(
    Canvas canvas,
    String text,
    Offset offset,
    double angle,
    TextStyle style,
  ) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    _drawText(canvas, text, Offset.zero, style);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WellPath3DPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.minEastWest != minEastWest ||
        oldDelegate.maxEastWest != maxEastWest ||
        oldDelegate.eastWestAxisMax != eastWestAxisMax ||
        oldDelegate.minNorthSouth != minNorthSouth ||
        oldDelegate.maxNorthSouth != maxNorthSouth ||
        oldDelegate.northSouthAxisMax != northSouthAxisMax ||
        oldDelegate.maxTvd != maxTvd;
  }
}

class _Survey3DBounds {
  const _Survey3DBounds({
    required this.minEastWest,
    required this.maxEastWest,
    required this.eastWestAxisMax,
    required this.minNorthSouth,
    required this.maxNorthSouth,
    required this.northSouthAxisMax,
    required this.maxTvd,
  });

  factory _Survey3DBounds.fromPoints(List<SurveyPoint> points) {
    if (points.isEmpty) {
      return const _Survey3DBounds(
        minEastWest: -12000,
        maxEastWest: 0,
        eastWestAxisMax: 12000,
        minNorthSouth: 0,
        maxNorthSouth: 3000,
        northSouthAxisMax: 12000,
        maxTvd: 12000,
      );
    }

    var minEastWest = 0.0;
    var maxEastWest = 0.0;
    var minNorthSouth = 0.0;
    var maxNorthSouth = 0.0;
    var maxTvd = 0.0;

    for (final point in points) {
      minEastWest = math.min(minEastWest, point.easting);
      maxEastWest = math.max(maxEastWest, point.easting);
      minNorthSouth = math.min(minNorthSouth, point.northing);
      maxNorthSouth = math.max(maxNorthSouth, point.northing);
      maxTvd = math.max(maxTvd, point.tvd);
    }

    final northSouthPadding =
        math.max((maxNorthSouth - minNorthSouth).abs() * 0.2, 100.0)
            .toDouble();
    final northSouthAxisMax = _roundedAxisMax(
      math.max(maxNorthSouth.abs(), minNorthSouth.abs()).toDouble(),
    );
    final eastWestAxisMax = _roundedAxisMax(
      math.max(maxEastWest.abs(), minEastWest.abs()).toDouble(),
    );

    return _Survey3DBounds(
      minEastWest: -eastWestAxisMax,
      maxEastWest: 0,
      eastWestAxisMax: eastWestAxisMax,
      minNorthSouth:
          minNorthSouth < 0 ? minNorthSouth - northSouthPadding : 0,
      maxNorthSouth: northSouthAxisMax,
      northSouthAxisMax: northSouthAxisMax,
      maxTvd: _roundedAxisMax(maxTvd),
    );
  }

  static double _roundedAxisMax(double value) {
    if (value <= 0) return 12000;
    return (value / 2000).ceil() * 2000.0;
  }

  final double minEastWest;
  final double maxEastWest;
  final double eastWestAxisMax;
  final double minNorthSouth;
  final double maxNorthSouth;
  final double northSouthAxisMax;
  final double maxTvd;
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
