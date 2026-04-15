import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class Survey3DChartPage extends StatefulWidget {
  const Survey3DChartPage({super.key});

  @override
  State<Survey3DChartPage> createState() => _Survey3DChartPageState();
}

class _Survey3DChartPageState extends State<Survey3DChartPage>
    with SingleTickerProviderStateMixin {
  double rotX = 0.0;
  double rotY = 0.0;
  double rotZ = 0.0;
  bool isAutoRotating = false;
  late AnimationController _autoRotateController;

  @override
  void initState() {
    super.initState();
    _autoRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_handleAnimation);
  }

  void _handleAnimation() {
    if (isAutoRotating) {
      setState(() {
        rotY += 0.02;
      });
    }
  }

  void _rotate(double dx, double dy, double dz) {
    setState(() {
      rotX += dx;
      rotY += dy;
      rotZ += dz;
    });
  }

  void _toggleAutoRotate() {
    setState(() {
      isAutoRotating = !isAutoRotating;
    });

    if (isAutoRotating) {
      _autoRotateController.repeat();
    } else {
      _autoRotateController.stop();
    }
  }

  void _resetView() {
    setState(() {
      rotX = 0.0;
      rotY = 0.0;
      rotZ = 0.0;
    });
  }

  @override
  void dispose() {
    _autoRotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.headerGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '3D Survey Visualization',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '9 Data Points',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // MAIN CONTENT
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT PANEL - CONTROLS
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chart Controls',
                          style: AppTheme.titleMedium.copyWith(
                            fontSize: 15,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ROTATION CONTROLS
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ControlButton(
                              icon: Icons.arrow_upward,
                              label: 'X+',
                              onPressed: () => _rotate(0.15, 0, 0),
                              color: AppTheme.primaryColor,
                            ),
                            _ControlButton(
                              icon: Icons.arrow_downward,
                              label: 'X-',
                              onPressed: () => _rotate(-0.15, 0, 0),
                              color: AppTheme.primaryColor,
                            ),
                            _ControlButton(
                              icon: Icons.arrow_back,
                              label: 'Y-',
                              onPressed: () => _rotate(0, -0.15, 0),
                              color: AppTheme.secondaryColor,
                            ),
                            _ControlButton(
                              icon: Icons.arrow_forward,
                              label: 'Y+',
                              onPressed: () => _rotate(0, 0.15, 0),
                              color: AppTheme.secondaryColor,
                            ),
                            _ControlButton(
                              icon: Icons.rotate_right,
                              label: 'Z+',
                              onPressed: () => _rotate(0, 0, 0.15),
                              color: AppTheme.accentColor,
                            ),
                            _ControlButton(
                              icon: Icons.rotate_left,
                              label: 'Z-',
                              onPressed: () => _rotate(0, 0, -0.15),
                              color: AppTheme.accentColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Colors.grey),
                        const SizedBox(height: 16),

                        // ACTION BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon: isAutoRotating
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                label: isAutoRotating
                                    ? 'Stop Auto'
                                    : 'Auto Rotate',
                                onPressed: _toggleAutoRotate,
                                color: isAutoRotating
                                    ? AppTheme.errorColor
                                    : AppTheme.successColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.refresh,
                                label: 'Reset View',
                                onPressed: _resetView,
                                color: AppTheme.infoColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildChartInfo(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // RIGHT PANEL - 3D CHART
                  Expanded(
                    child: Container(
                      decoration: AppTheme.elevatedCardDecoration.copyWith(
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          // CHART HEADER
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '3D Bar Chart Visualization',
                                  style: AppTheme.titleMedium.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Drag to rotate',
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3D CHART AREA
                          Expanded(
                            child: Container(
                              color: Colors.white,
                              child: CustomPaint(
                                painter: _Simple3DChartPainter(
                                  rotX: rotX,
                                  rotY: rotY,
                                  rotZ: rotZ,
                                ),
                                child: SizedBox.expand(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chart Info',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              _InfoItem(
                label: 'Chart Type',
                value: '3D Bar Graph',
                color: AppTheme.primaryColor,
              ),
              _InfoItem(
                label: 'Data Points',
                value: '9 bars',
                color: AppTheme.secondaryColor,
              ),
              _InfoItem(
                label: 'Rotation',
                value: 'Interactive',
                color: AppTheme.accentColor,
              ),
              _InfoItem(
                label: 'Auto Rotate',
                value: isAutoRotating ? 'ON' : 'OFF',
                color: isAutoRotating
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// CONTROL BUTTON WIDGET
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ACTION BUTTON WIDGET
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// INFO ITEM WIDGET
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// SIMPLE 3D CHART PAINTER
class _Simple3DChartPainter extends CustomPainter {
  final double rotX, rotY, rotZ;

  _Simple3DChartPainter({
    required this.rotX,
    required this.rotY,
    required this.rotZ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Move to center
    canvas.translate(size.width / 2, size.height / 2);
    
    // Scale to fit
    final scale = min(size.width, size.height) / 500;
    canvas.scale(scale);

    // Create 3D bars
    final bars = [
      _SimpleBar3D(x: -120, y: 0, z: -120, height: 120, color: AppTheme.primaryColor),
      _SimpleBar3D(x: 0, y: 0, z: -120, height: 200, color: AppTheme.secondaryColor),
      _SimpleBar3D(x: 120, y: 0, z: -120, height: 160, color: AppTheme.accentColor),
      _SimpleBar3D(x: -120, y: 0, z: 0, height: 180, color: AppTheme.successColor),
      _SimpleBar3D(x: 0, y: 0, z: 0, height: 140, color: AppTheme.warningColor),
      _SimpleBar3D(x: 120, y: 0, z: 0, height: 220, color: AppTheme.infoColor),
      _SimpleBar3D(x: -120, y: 0, z: 120, height: 100, color: AppTheme.tableHeadColor),
      _SimpleBar3D(x: 0, y: 0, z: 120, height: 240, color: AppTheme.primaryColor),
      _SimpleBar3D(x: 120, y: 0, z: 120, height: 120, color: AppTheme.secondaryColor),
    ];

    // Draw grid
    _drawGrid(canvas);

    // Draw bars
    for (final bar in bars) {
      bar.draw(canvas, rotX, rotY, rotZ);
    }

    // Draw axes
    _drawAxes(canvas);
  }

  void _drawGrid(Canvas canvas) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;

    // Horizontal lines
    for (int i = -200; i <= 200; i += 50) {
      canvas.drawLine(
        Offset(-200, i.toDouble()),
        Offset(200, i.toDouble()),
        gridPaint,
      );
      // Vertical lines
      canvas.drawLine(
        Offset(i.toDouble(), -200),
        Offset(i.toDouble(), 200),
        gridPaint,
      );
    }
  }

  void _drawAxes(Canvas canvas) {
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    // X axis
    canvas.drawLine(Offset(-250, 0), Offset(250, 0), axisPaint);
    // Y axis
    canvas.drawLine(Offset(0, 200), Offset(0, -250), axisPaint);

    // Axis labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // X label
    textPainter.text = const TextSpan(
      text: 'X',
      style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(240, 10));

    // Y label
    textPainter.text = const TextSpan(
      text: 'Y',
      style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, -240));

    // Z label
    textPainter.text = const TextSpan(
      text: 'Z',
      style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(-20, 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// SIMPLE 3D BAR MODEL
class _SimpleBar3D {
  final double x, y, z;
  final double height;
  final Color color;
  final double width = 30;
  final double depth = 30;

  _SimpleBar3D({
    required this.x,
    required this.y,
    required this.z,
    required this.height,
    required this.color,
  });

  Offset _project(double x, double y, double z, double rx, double ry, double rz) {
    // Rotate Y
    double x1 = x * cos(ry) - z * sin(ry);
    double z1 = x * sin(ry) + z * cos(ry);

    // Rotate X
    double y1 = y * cos(rx) - z1 * sin(rx);
    double z2 = y * sin(rx) + z1 * cos(rx);

    // Rotate Z
    double x2 = x1 * cos(rz) - y1 * sin(rz);
    double y2 = x1 * sin(rz) + y1 * cos(rz);

    return Offset(x2, -y2);
  }

  void draw(Canvas canvas, double rx, double ry, double rz) {
    final basePoints = [
      _project(x, y, z, rx, ry, rz),
      _project(x + width, y, z, rx, ry, rz),
      _project(x + width, y, z + depth, rx, ry, rz),
      _project(x, y, z + depth, rx, ry, rz),
      _project(x, y + height, z, rx, ry, rz),
      _project(x + width, y + height, z, rx, ry, rz),
      _project(x + width, y + height, z + depth, rx, ry, rz),
      _project(x, y + height, z + depth, rx, ry, rz),
    ];

    // Draw front face
    final frontPath = Path()
      ..moveTo(basePoints[0].dx, basePoints[0].dy)
      ..lineTo(basePoints[1].dx, basePoints[1].dy)
      ..lineTo(basePoints[5].dx, basePoints[5].dy)
      ..lineTo(basePoints[4].dx, basePoints[4].dy)
      ..close();

    final frontPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(frontPath, frontPaint);

    // Draw top face
    final topPath = Path()
      ..moveTo(basePoints[4].dx, basePoints[4].dy)
      ..lineTo(basePoints[5].dx, basePoints[5].dy)
      ..lineTo(basePoints[6].dx, basePoints[6].dy)
      ..lineTo(basePoints[7].dx, basePoints[7].dy)
      ..close();

    final topPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawPath(topPath, topPaint);

    // Draw side face
    final sidePath = Path()
      ..moveTo(basePoints[1].dx, basePoints[1].dy)
      ..lineTo(basePoints[2].dx, basePoints[2].dy)
      ..lineTo(basePoints[6].dx, basePoints[6].dy)
      ..lineTo(basePoints[5].dx, basePoints[5].dy)
      ..close();

    final sidePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(sidePath, sidePaint);
  }
}