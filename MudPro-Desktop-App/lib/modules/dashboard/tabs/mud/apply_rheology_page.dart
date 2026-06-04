import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';

class ApplyRheologyPage extends StatefulWidget {
  const ApplyRheologyPage({super.key});

  @override
  State<ApplyRheologyPage> createState() => _ApplyRheologyPageState();
}

class _ApplyRheologyPageState extends State<ApplyRheologyPage> {
  int _sampleIndex = 0;
  int _dialRevision = 0;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MudController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        return Stack(
          children: [
            Row(
              children: [
                SizedBox(width: 590, child: _buildRheologyTable(c)),
                Expanded(child: _buildGraph(c)),
              ],
            ),
            Positioned(
              top: 6,
              right: 8,
              child: SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.black87,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRheologyTable(MudController c) {
    if (_sampleIndex >= c.samples.length) _sampleIndex = 0;
    final fitted = _ChartPainter(
      c: c,
      sampleIndex: _sampleIndex,
    )._buildSample(_sampleIndex);
    final fit = fitted?.fit;
    final pv = _binghamPv(c, _sampleIndex);
    final yp = _binghamYp(c, _sampleIndex);
    final allAligned =
        fitted != null &&
        fitted.points.every((p) => p.diff.abs() <= _ChartPainter._threshold);

    return Container(
      padding: const EdgeInsets.only(left: 4, top: 12, right: 18, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit the dial readings:',
            style: TextStyle(fontSize: 13, color: Colors.black),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              SizedBox(width: 190, child: _PlainHeader('RPM')),
              SizedBox(width: 190, child: _PlainHeader('Dial')),
              SizedBox(width: 115, child: _PlainHeader('Model')),
              SizedBox(width: 70, child: _PlainHeader('Diff')),
            ],
          ),
          const SizedBox(height: 6),
          ..._ChartPainter._rpmRows.map((rpm) {
            final value = c.rheologyTable['$rpm']?[_sampleIndex].value ?? '';
            final point = fitted?.pointForRpm(rpm);
            final offCurve =
                point != null && point.diff.abs() > _ChartPainter._threshold;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 190,
                    child: Text('$rpm', style: const TextStyle(fontSize: 13)),
                  ),
                  SizedBox(
                    width: 190,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _dialCell(c, rpm, value),
                    ),
                  ),
                  SizedBox(
                    width: 115,
                    child: Text(
                      point == null ? '-' : point.model.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      point == null ? '-' : _signedOne(point.diff),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: offCurve
                            ? const Color(0xFFE24B4A)
                            : const Color(0xFF00796B),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 300,
                child: _summaryBlock('PV (cP)', pv?.toStringAsFixed(0) ?? '-'),
              ),
              _summaryBlock('YP (lbf/100ft2)', yp?.toStringAsFixed(0) ?? '-'),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Herschel-Bulkley fit', style: TextStyle(fontSize: 12)),
          Text(
            't0=${fit == null ? '-' : fit.t0.toStringAsFixed(2)} '
            'K=${fit == null ? '-' : fit.k.toStringAsFixed(4)} '
            'n=${fit == null ? '-' : fit.n.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 12),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 20),
            child: Text(
              allAligned
                  ? 'All readings aligned. Every point is within 3 units of the model curve, so the rheology is self-consistent. Try changing a dial value to see a point go off-curve.'
                  : 'One or more readings are off-curve. Adjust the red reading until it falls back on the model curve.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF00695C)),
            ),
          ),
        ],
      ),
    );
  }

  String _signedOne(double value) {
    final text = value.toStringAsFixed(1);
    return value > 0 ? '+$text' : text;
  }

  Widget _summaryBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  double? _binghamPv(MudController c, int sampleIndex) {
    final r600 = double.tryParse(
      c.rheologyTable['600']?[sampleIndex].value ?? '',
    );
    final r300 = double.tryParse(
      c.rheologyTable['300']?[sampleIndex].value ?? '',
    );
    if (r600 == null || r300 == null) return null;
    return r600 - r300;
  }

  double? _binghamYp(MudController c, int sampleIndex) {
    final pv = _binghamPv(c, sampleIndex);
    final r300 = double.tryParse(
      c.rheologyTable['300']?[sampleIndex].value ?? '',
    );
    if (pv == null || r300 == null) return null;
    return r300 - pv;
  }

  Widget _dialCell(MudController c, int rpm, String value) {
    void setDial(double next) {
      final normalized = next < 0 ? 0.0 : next;
      c.rheologyTable['$rpm']?[_sampleIndex].value = _formatDial(normalized);
      c.calculateRheology();
      setState(() => _dialRevision++);
    }

    final currentValue = double.tryParse(value) ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          child: TextFormField(
            key: ValueKey('rheo-dial-$_sampleIndex-$rpm-$_dialRevision'),
            initialValue: value,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13, color: Colors.black),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.grey.shade500),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.grey.shade500),
              ),
            ),
            onChanged: (v) {
              c.rheologyTable['$rpm']?[_sampleIndex].value = v;
              c.calculateRheology();
            },
          ),
        ),
        const SizedBox(width: 3),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialStepButton(
              icon: Icons.keyboard_arrow_up,
              onTap: () => setDial(currentValue + 1),
            ),
            const SizedBox(height: 2),
            _dialStepButton(
              icon: Icons.keyboard_arrow_down,
              onTap: () => setDial(currentValue - 1),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDial(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Widget _dialStepButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 13,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          border: Border.all(color: Colors.grey.shade500),
        ),
        child: Icon(icon, size: 12, color: Colors.black87),
      ),
    );
  }

  Widget _buildGraph(MudController c) {
    return Container(
      padding: const EdgeInsets.only(top: 22, right: 20, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _RheologyChart(c: c, sampleIndex: _sampleIndex),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              _legendDot(const Color(0xFF185FA5), 'Model curve', line: true),
              _legendDot(const Color(0xFF0F6E56), 'On curve'),
              _legendDot(const Color(0xFFE24B4A), 'Off curve'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, {bool line = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: line ? 24 : 10,
          height: line ? 2 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(line ? 1 : 5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _RheologyChart extends StatelessWidget {
  final MudController c;
  final int sampleIndex;

  const _RheologyChart({required this.c, required this.sampleIndex});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ChartPainter(c: c, sampleIndex: sampleIndex),
        );
      },
    );
  }
}

class _PlainHeader extends StatelessWidget {
  const _PlainHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  static const double _rateFactor = 1.7034;
  static const double _stressFactor = 1.066;
  static const double _threshold = 3.0;
  static const List<int> _rpmRows = [600, 300, 200, 100, 6, 3];
  static const Color _curveColor = Color(0xFF185FA5);
  static const Color _okColor = Color(0xFF0F6E56);
  static const Color _badColor = Color(0xFFE24B4A);

  final MudController c;
  final int sampleIndex;

  _ChartPainter({required this.c, required this.sampleIndex});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 58.0, rightPad = 18.0, topPad = 18.0, bottomPad = 46.0;
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;
    if (chartW <= 0 || chartH <= 0) return;

    final samples = _buildSamples();
    const double maxX = 1100;
    const double maxY = 70;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(leftPad, topPad, chartW, chartH),
      Paint()..color = Colors.white,
    );

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E8F0)
      ..strokeWidth = 0.7;
    for (final v in const [0, 200, 400, 600, 800, 1000, 1100]) {
      final x = leftPad + (v / maxX) * chartW;
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + chartH), gridPaint);
      _drawText(
        canvas,
        v.toString(),
        Offset(x, topPad + chartH + 8),
        9,
        Colors.grey.shade600,
        center: true,
      );
    }
    for (int v = 0; v <= maxY; v += 10) {
      final y = topPad + chartH - (v / maxY) * chartH;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartW, y),
        gridPaint,
      );
      _drawText(
        canvas,
        v.toString(),
        Offset(leftPad - 7, y),
        9,
        Colors.grey.shade600,
        rightAlign: true,
      );
    }

    _drawText(
      canvas,
      'Shear rate (1/s)',
      Offset(leftPad + chartW / 2, topPad + chartH + 32),
      10,
      Colors.grey.shade700,
      center: true,
    );
    _drawRotatedText(
      canvas,
      'Shear stress (lbf/100ft2)',
      Offset(16, topPad + chartH / 2),
      10,
      Colors.grey.shade700,
    );

    canvas.drawRect(
      Rect.fromLTWH(leftPad, topPad, chartW, chartH),
      Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    if (samples.isEmpty) {
      _drawText(
        canvas,
        'Enter rheology readings to view the curve',
        Offset(leftPad + chartW / 2, topPad + chartH / 2),
        11,
        Colors.grey.shade500,
        center: true,
      );
      return;
    }

    for (final sample in samples) {
      final linePaint = Paint()
        ..color = samples.length == 1
            ? _curveColor
            : _curveColor.withValues(alpha: 0.58)
        ..strokeWidth = samples.length == 1 ? 3 : 2
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (var i = 0; i < sample.curve.length; i++) {
        final p = sample.curve[i];
        final px = leftPad + (p.dx / maxX) * chartW;
        final py = topPad + chartH - (p.dy / maxY) * chartH;
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, linePaint);

      for (final p in sample.points) {
        final dot = Offset(
          leftPad + (p.rate / maxX) * chartW,
          topPad + chartH - (p.measured / maxY) * chartH,
        );
        final offCurve = p.diff.abs() > _threshold;
        canvas.drawCircle(
          dot,
          offCurve ? 6 : 5,
          Paint()..color = offCurve ? _badColor : _okColor,
        );
        canvas.drawCircle(
          dot,
          offCurve ? 6 : 5,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  List<_FittedSample> _buildSamples() {
    final sample = _buildSample(sampleIndex);
    return sample == null ? <_FittedSample>[] : <_FittedSample>[sample];
  }

  _FittedSample? _buildSample(int sampleIndex) {
    final readings = <_Reading>[];
    for (final rpm in _rpmRows) {
      final dial = double.tryParse(
        c.rheologyTable['$rpm']?[sampleIndex].value ?? '',
      );
      if (dial != null && dial > 0) {
        readings.add(_Reading(rpm: rpm, dial: dial));
      }
    }
    if (readings.length < 3) return null;
    final fit = _fitHb(readings);
    if (fit == null) return null;
    final curve = <Offset>[];
    for (double rate = 0; rate <= 1050; rate += 15) {
      curve.add(Offset(rate, _modelStress(fit, rate)));
    }
    final points = readings.map((r) {
      final rate = r.rpm * _rateFactor;
      final measured = r.dial * _stressFactor;
      final model = _modelStress(fit, rate);
      return _QcPoint(
        rpm: r.rpm,
        rate: rate,
        measured: measured,
        model: model,
        diff: measured - model,
      );
    }).toList();
    return _FittedSample(fit: fit, curve: curve, points: points);
  }

  _HbFit? _fitHb(List<_Reading> readings) {
    final rates = readings.map((r) => r.rpm * _rateFactor).toList();
    final stresses = readings.map((r) => r.dial * _stressFactor).toList();
    _HbFit? best;

    for (double n = 0.2; n <= 1.2001; n += 0.002) {
      final x = rates.map((v) => _pow(v, n)).toList();
      final count = x.length;
      var sx = 0.0, sy = 0.0, sxx = 0.0, sxy = 0.0;
      for (var i = 0; i < count; i++) {
        sx += x[i];
        sy += stresses[i];
        sxx += x[i] * x[i];
        sxy += x[i] * stresses[i];
      }
      final den = count * sxx - sx * sx;
      if (den.abs() < 1e-9) continue;
      final k = (count * sxy - sx * sy) / den;
      final t0 = (sy - k * sx) / count;
      var sse = 0.0;
      for (var j = 0; j < count; j++) {
        final model = t0 + k * x[j];
        final err = stresses[j] - model;
        sse += err * err;
      }
      if (best == null || sse < best.sse) {
        best = _HbFit(t0: t0, k: k, n: n, sse: sse);
      }
    }
    return best;
  }

  double _modelStress(_HbFit fit, double rate) {
    return fit.t0 + fit.k * _pow(rate, fit.n);
  }

  double _pow(double base, double exp) {
    if (base <= 0) return 0;
    return math.pow(base, exp).toDouble();
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    double size,
    Color color, {
    bool center = false,
    bool rightAlign = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    double dx = pos.dx;
    if (center) dx -= tp.width / 2;
    if (rightAlign) dx -= tp.width;
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  void _drawRotatedText(
    Canvas canvas,
    String text,
    Offset pos,
    double size,
    Color color,
  ) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(-1.57079632679);
    _drawText(canvas, text, Offset.zero, size, color, center: true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChartPainter old) => true;
}

class _Reading {
  const _Reading({required this.rpm, required this.dial});

  final int rpm;
  final double dial;
}

class _HbFit {
  const _HbFit({
    required this.t0,
    required this.k,
    required this.n,
    required this.sse,
  });

  final double t0;
  final double k;
  final double n;
  final double sse;
}

class _QcPoint {
  const _QcPoint({
    required this.rpm,
    required this.rate,
    required this.measured,
    required this.model,
    required this.diff,
  });

  final int rpm;
  final double rate;
  final double measured;
  final double model;
  final double diff;
}

class _FittedSample {
  const _FittedSample({
    required this.fit,
    required this.curve,
    required this.points,
  });

  final _HbFit fit;
  final List<Offset> curve;
  final List<_QcPoint> points;

  _QcPoint? pointForRpm(int rpm) {
    for (final point in points) {
      if (point.rpm == rpm) return point;
    }
    return null;
  }
}
