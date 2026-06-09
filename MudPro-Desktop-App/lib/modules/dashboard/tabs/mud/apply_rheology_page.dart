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
      backgroundColor: const Color(0xFFF6F8FA),
      body: Obx(() {
        _ensureVisibleSample(c);
        return Column(
          children: [
            _topBar(context, c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 520, child: _buildRheologyTable(c)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildGraph(c)),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _ensureVisibleSample(MudController c) {
    if (_sampleIndex >= c.samples.length) _sampleIndex = 0;
    if (_sampleHasReadings(c, _sampleIndex)) return;
    for (var i = 0; i < c.samples.length; i++) {
      if (_sampleHasReadings(c, i)) {
        _sampleIndex = i;
        return;
      }
    }
  }

  bool _sampleHasReadings(MudController c, int sampleIndex) {
    for (final rpm in _ChartPainter._rpmRows) {
      final value = double.tryParse(
        c.rheologyTable['$rpm']?[sampleIndex].value ?? '',
      );
      if (value != null && value > 0) return true;
    }
    return false;
  }

  Widget _topBar(BuildContext context, MudController c) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 18,
            color: Color(0xFF185FA5),
          ),
          const SizedBox(width: 8),
          const Text(
            'Rheology Curve',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 18),
          _sampleSelector(c),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            splashRadius: 18,
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _sampleSelector(MudController c) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(c.samples.length, (index) {
          final active = index == _sampleIndex;
          final hasData = _sampleHasReadings(c, index);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: TextButton(
              onPressed: () => setState(() => _sampleIndex = index),
              style: TextButton.styleFrom(
                minimumSize: const Size(58, 28),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: active ? Colors.white : Colors.transparent,
                foregroundColor: active
                    ? const Color(0xFF185FA5)
                    : const Color(0xFF334155),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                  side: active
                      ? BorderSide(color: Colors.grey.shade300)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasData)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F6E56),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    c.samples[index],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dial readings - ${c.samples[_sampleIndex]}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                c.rheologyModel.value,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(72),
                1: FixedColumnWidth(132),
                2: FlexColumnWidth(),
                3: FixedColumnWidth(86),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade200),
                verticalInside: BorderSide(color: Colors.grey.shade200),
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
                top: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                  children: [
                    _TableHeader('RPM'),
                    _TableHeader('Dial'),
                    _TableHeader('Model'),
                    _TableHeader('Diff'),
                  ],
                ),
                ..._ChartPainter._rpmRows.map((rpm) {
                  final value =
                      c.rheologyTable['$rpm']?[_sampleIndex].value ?? '';
                  final point = fitted?.pointForRpm(rpm);
                  final offCurve =
                      point != null &&
                      point.diff.abs() > _ChartPainter._threshold;
                  return TableRow(
                    decoration: const BoxDecoration(color: Colors.white),
                    children: [
                      _TableText('$rpm'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: _dialCell(c, rpm, value),
                      ),
                      _TableText(
                        point == null ? '-' : point.model.toStringAsFixed(1),
                        alignCenter: true,
                      ),
                      _TableText(
                        point == null ? '-' : _signedOne(point.diff),
                        alignRight: true,
                        color: offCurve
                            ? const Color(0xFFE24B4A)
                            : const Color(0xFF00796B),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryBlock('PV (cP)', pv?.toStringAsFixed(0) ?? '-'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBlock(
                  'YP (lbf/100ft2)',
                  yp?.toStringAsFixed(0) ?? '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Herschel-Bulkley fit',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  't0=${fit == null ? '-' : fit.t0.toStringAsFixed(2)}   '
                  'K=${fit == null ? '-' : fit.k.toStringAsFixed(4)}   '
                  'n=${fit == null ? '-' : fit.n.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: allAligned
                  ? const Color(0xFFEFFAF5)
                  : const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: allAligned
                    ? const Color(0xFFBFE8D4)
                    : const Color(0xFFF3C0C0),
              ),
            ),
            child: Text(
              allAligned
                  ? 'All readings are aligned within 3 units of the model curve.'
                  : 'One or more readings are off-curve. Adjust the red reading.',
              style: TextStyle(
                fontSize: 11,
                color: allAligned
                    ? const Color(0xFF00695C)
                    : const Color(0xFFB42318),
              ),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE6E0A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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
          width: 70,
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Curve - ${c.samples[_sampleIndex]}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              const Text(
                'Auto scaled',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF334155),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TableText extends StatelessWidget {
  const _TableText(
    this.text, {
    this.alignRight = false,
    this.alignCenter = false,
    this.color,
  });

  final String text;
  final bool alignRight;
  final bool alignCenter;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: alignCenter
          ? Alignment.center
          : alignRight
          ? Alignment.centerRight
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? const Color(0xFF0F172A),
          fontWeight: color == null ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  static const double _rateFactor = 1.7034;
  static const double _stressFactor = 1.066;
  static const double _threshold = 3.0;
  static const double _xAxisMax = 1200.0;
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
    const maxX = _xAxisMax;
    final maxY = _chartMaxY(samples);
    final plotRect = Rect.fromLTWH(leftPad, topPad, chartW, chartH);

    // Background
    canvas.drawRect(plotRect, Paint()..color = Colors.white);

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E8F0)
      ..strokeWidth = 0.7;
    for (final v in _ticksByStep(maxX, 200)) {
      final x = leftPad + (v / maxX) * chartW;
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + chartH), gridPaint);
      _drawText(
        canvas,
        _tickLabel(v),
        Offset(x, topPad + chartH + 8),
        9,
        Colors.grey.shade600,
        center: true,
      );
    }
    for (final v in _ticksByStep(maxY, _yTickStep(maxY))) {
      final y = topPad + chartH - (v / maxY) * chartH;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartW, y),
        gridPaint,
      );
      _drawText(
        canvas,
        _tickLabel(v),
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
      plotRect,
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

    canvas.save();
    canvas.clipRect(plotRect);
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
        final px = leftPad + (p.dx / maxX).clamp(0.0, 1.0) * chartW;
        final py = topPad + chartH - (p.dy / maxY).clamp(0.0, 1.0) * chartH;
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, linePaint);

      for (final p in sample.points) {
        final dot = Offset(
          leftPad + (p.rate / maxX).clamp(0.0, 1.0) * chartW,
          topPad + chartH - (p.measured / maxY).clamp(0.0, 1.0) * chartH,
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
    canvas.restore();
  }

  double _chartMaxY(List<_FittedSample> samples) {
    var maxY = 10.0;
    for (final sample in samples) {
      for (final p in sample.points) {
        maxY = math.max(maxY, math.max(p.measured, p.model));
      }
      for (final p in sample.curve) {
        if (p.dx <= _xAxisMax) {
          maxY = math.max(maxY, p.dy);
        }
      }
    }
    return (maxY / 10).ceil() * 10.0;
  }

  double _yTickStep(double maxY) {
    if (maxY <= 100) return 10;
    if (maxY <= 200) return 20;
    return 50;
  }

  List<double> _ticksByStep(double max, double step) {
    final ticks = <double>[];
    for (double v = 0; v <= max + 0.0001; v += step) {
      ticks.add(v);
    }
    if (ticks.isEmpty || ticks.last != max) ticks.add(max);
    return ticks;
  }

  String _tickLabel(double value) {
    if (value >= 1000) return value.toStringAsFixed(0);
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
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
    for (double rate = 0; rate <= _xAxisMax; rate += 15) {
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
