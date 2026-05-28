import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/survey_model.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';

class Survey3DTab extends StatelessWidget {
  Survey3DTab({super.key});

  final SurveyController controller = Get.find<SurveyController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return WellPath3DViewer(
        surveyPoints: controller.plotPoints.map(SurveyPoint.fromPlot).toList(),
        zoom: controller.zoom.value,
      );
    });
  }
}

class WellPath3DViewer extends StatelessWidget {
  const WellPath3DViewer({
    super.key,
    required this.surveyPoints,
    required this.zoom,
  });

  final List<SurveyPoint> surveyPoints;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final bounds = _Survey3DBounds.fromPoints(surveyPoints);

    return Container(
      color: const Color(0xFFE5E5E5),
      child: CustomPaint(
        painter: WellPath3DPainter(
          points: surveyPoints,
          zoom: zoom,
          minEastWest: bounds.minEastWest,
          maxEastWest: bounds.maxEastWest,
          minNorthSouth: bounds.minNorthSouth,
          maxNorthSouth: bounds.maxNorthSouth,
          maxTvd: bounds.maxTvd,
        ),
        child: const SizedBox.expand(),
      ),
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
    required this.zoom,
    required this.minEastWest,
    required this.maxEastWest,
    required this.minNorthSouth,
    required this.maxNorthSouth,
    required this.maxTvd,
  });

  final List<SurveyPoint> points;
  final double zoom;
  final double minEastWest;
  final double maxEastWest;
  final double minNorthSouth;
  final double maxNorthSouth;
  final double maxTvd;

  static const int _gridDivisions = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = _buildProjection(size);

    _drawGrid(canvas, projection);
    _drawBoundingBox(canvas, projection);

    if (points.isNotEmpty) {
      _drawWellPath(canvas, projection);
    }
  }

  _Projection _buildProjection(Size size) {
    final side = math.min(size.width * 0.78, size.height * 0.92) * zoom;
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

    for (var i = 0; i <= _gridDivisions; i++) {
      final t = i / _gridDivisions;

      _draw3DLine(canvas, _V3(0, t, 1), _V3(1, t, 1), projection, gridPaint);
      _draw3DLine(canvas, _V3(t, 0, 1), _V3(t, 1, 1), projection, gridPaint);
      if (i > 0) {
        _draw3DLine(
          canvas,
          _V3(t, 0, 0),
          _V3(t, 0, 1),
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
      }
      if (i != 1) {
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
    _draw3DLine(canvas, _V3(1, 0, 0), _V3(1, 1, 0), projection, boxPaint);
    _draw3DLine(canvas, _V3(1, 1, 0), _V3(0, 1, 0), projection, boxPaint);
    _draw3DLine(canvas, _V3(0, 1, 0), _V3(0, 0, 0), projection, boxPaint);

    _draw3DLine(canvas, _V3(0, 0, 0), _V3(0, 0, 0.58), projection, boxPaint);
    _draw3DLine(canvas, _V3(1, 0, 0), _V3(1, 0, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(1, 1, 0), _V3(1, 1, 1), projection, boxPaint);
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

  Offset _project(_V3 point, _Projection projection) {
    return projection.origin +
        (projection.x * point.x) +
        (projection.y * point.y) +
        (projection.z * point.z);
  }

  @override
  bool shouldRepaint(covariant WellPath3DPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.zoom != zoom ||
        oldDelegate.minEastWest != minEastWest ||
        oldDelegate.maxEastWest != maxEastWest ||
        oldDelegate.minNorthSouth != minNorthSouth ||
        oldDelegate.maxNorthSouth != maxNorthSouth ||
        oldDelegate.maxTvd != maxTvd;
  }
}

class _Survey3DBounds {
  const _Survey3DBounds({
    required this.minEastWest,
    required this.maxEastWest,
    required this.minNorthSouth,
    required this.maxNorthSouth,
    required this.maxTvd,
  });

  factory _Survey3DBounds.fromPoints(List<SurveyPoint> points) {
    if (points.isEmpty) {
      return const _Survey3DBounds(
        minEastWest: -500,
        maxEastWest: 2500,
        minNorthSouth: 0,
        maxNorthSouth: 3000,
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

    final eastWestPadding =
        math.max((maxEastWest - minEastWest).abs() * 0.2, 100.0).toDouble();
    final northSouthPadding =
        math.max((maxNorthSouth - minNorthSouth).abs() * 0.2, 100.0)
            .toDouble();

    return _Survey3DBounds(
      minEastWest: minEastWest - eastWestPadding,
      maxEastWest: maxEastWest + eastWestPadding,
      minNorthSouth: minNorthSouth - northSouthPadding,
      maxNorthSouth: maxNorthSouth + northSouthPadding,
      maxTvd: math.max(maxTvd * 1.1, 12000.0).toDouble(),
    );
  }

  final double minEastWest;
  final double maxEastWest;
  final double minNorthSouth;
  final double maxNorthSouth;
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
