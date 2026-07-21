import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({super.key});

  static const String _appName = 'MSR_DMR';
  static const String _company = 'Bits and Bytes IT Solution';
  static const String _email = 'support@bitsandbytesitsolution.com';
  static const String _website = 'https://bitsandbytesitsolution.com';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardColor,
      alignment: Alignment.center,
      child: Container(
        width: 720,
        height: 500,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border.all(color: AppTheme.tableBorderBlue),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _titleBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _brandLogo(),
                        const SizedBox(width: 26),
                        Expanded(child: _headerText()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: 560,
                        child: Column(
                          children: [
                            Text(
                              'Program Disclaimer',
                              textAlign: TextAlign.center,
                              style: AppTheme.titleMedium.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'This application is intended to assist with drilling mud reporting, '
                              'inventory tracking, and related engineering calculations. '
                              'Although $_company works to keep the software dependable and accurate, '
                              'field conditions, entered data, equipment configuration, and operating '
                              'practices can affect final results. Users are responsible for reviewing '
                              'outputs, confirming assumptions, and applying professional judgment '
                              'before using any result for operational decisions. $_company does not '
                              'accept liability for losses or damages arising from use, modification, '
                              'interpretation, or distribution of this software.',
                              textAlign: TextAlign.left,
                              style: AppTheme.bodyLarge.copyWith(
                                fontSize: 14,
                                height: 1.22,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Support: $_email | $_website',
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            _buttonBar(),
          ],
        ),
      ),
    );
  }

  Widget _titleBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: AppTheme.panelHeaderBlue,
      ),
      child: Row(
        children: [
          Text(
            '$_appName - Disclaimer',
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _close,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.close, size: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandLogo() {
    return Container(
      width: 300,
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECEF),
        border: Border.all(color: AppTheme.tableGridBlue),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 96,
            child: CustomPaint(painter: _DropLogoPainter()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'MSR',
                      style: AppTheme.titleLarge.copyWith(
                        color: const Color(0xFF233445),
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: '2',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppTheme.infoColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: '_DMR',
                      style: AppTheme.titleLarge.copyWith(
                        color: Colors.blue.shade700,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'MSR',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: '2',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.infoColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: '_DMR',
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Copyright (C) $_company 2026',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Developed by $_company',
          style: AppTheme.bodyLarge.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buttonBar() {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.tableGridBlue),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 126,
            height: 38,
            child: OutlinedButton(
              onPressed: _close,
              child: Text(
                'I Agree',
                style: AppTheme.bodyLarge.copyWith(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 36),
          SizedBox(
            width: 126,
            height: 38,
            child: OutlinedButton(
              onPressed: _close,
              child: Text(
                'Quit',
                style: AppTheme.bodyLarge.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _close() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().closeOverlay();
    }
  }
}

class _DropLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dropPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF63B2EA), Color(0xFF145AA0)],
      ).createShader(Offset.zero & size);

    final drop = Path()
      ..moveTo(size.width * 0.50, size.height * 0.02)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.36,
        size.width * 0.08,
        size.height * 0.58,
        size.width * 0.12,
        size.height * 0.76,
      )
      ..cubicTo(
        size.width * 0.18,
        size.height * 1.02,
        size.width * 0.82,
        size.height * 1.02,
        size.width * 0.88,
        size.height * 0.76,
      )
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.58,
        size.width * 0.80,
        size.height * 0.36,
        size.width * 0.50,
        size.height * 0.02,
      )
      ..close();

    canvas.drawPath(drop, dropPaint);

    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.18,
        size.width * 0.34,
        size.height * 0.50,
      ),
      3.0,
      0.9,
      false,
      shinePaint,
    );

    final chartPaint = Paint()
      ..color = const Color(0xFFFFC84D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final chart = Path()
      ..moveTo(size.width * 0.28, size.height * 0.66)
      ..lineTo(size.width * 0.44, size.height * 0.48)
      ..lineTo(size.width * 0.58, size.height * 0.60)
      ..lineTo(size.width * 0.76, size.height * 0.38);
    canvas.drawPath(chart, chartPaint);

    final dotPaint = Paint()..color = const Color(0xFFFFC84D);
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.38),
      8,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.38),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
