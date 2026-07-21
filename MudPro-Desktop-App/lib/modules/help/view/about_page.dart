import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _appName = 'MSR_DMR';
  static const String _tagline = 'Advanced Drilling Mud Reporting';
  static const String _version = 'Version 1.0.0+1';
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
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _brandLogo(),
                        const SizedBox(width: 26),
                        Expanded(child: _brandDetails()),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _aboutText(),
                    const Spacer(),
                    _footer(),
                  ],
                ),
              ),
            ),
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
            'About',
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

  Widget _brandDetails() {
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
        const SizedBox(height: 8),
        Text(
          _tagline,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _version,
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 14,
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

  Widget _aboutText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _paragraph(
          'The software records drilling information, mud properties and inventory data for daily reporting workflows.',
        ),
        const SizedBox(height: 22),
        _paragraph('Copyright (C) $_company 2026'),
        const SizedBox(height: 8),
        _paragraph('$_appName is drilling mud reporting software by $_company.'),
        const SizedBox(height: 16),
        _paragraph('Send your comments or questions to:'),
        const SizedBox(height: 8),
        _paragraph(_company),
        const SizedBox(height: 8),
        _linkLine('Website: ', _website),
        const SizedBox(height: 8),
        _linkLine('E-mail: ', _email),
      ],
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      textAlign: TextAlign.left,
      style: AppTheme.bodyLarge.copyWith(
        fontSize: 14,
        height: 1.22,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _linkLine(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTheme.bodyLarge.copyWith(fontSize: 14),
        ),
        SelectableText(
          value,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 14,
            color: Colors.blue.shade700,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.tableGridBlue),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              'Warning: This computer program is protected by copyright law. Unauthorized reproduction, distribution or modification may result in legal action.',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 12,
                height: 1.18,
              ),
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 118,
            height: 38,
            child: OutlinedButton(
              onPressed: _close,
              child: Text(
                'OK',
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
