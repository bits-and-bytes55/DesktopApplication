import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'dart:math' as math;

// Controller for managing 3D chart state
class Chart3DController extends GetxController {
  late Object chartObject;
  late Scene scene;
  
  // Chart data points
  final chartData = <ChartPoint>[].obs;
  final selectedChartType = 'Surface'.obs;
  
  // Rotation angles
  final rotationX = (-0.4).obs;
  final rotationY = (0.6).obs;
  
  // Auto rotation
  final isAutoRotating = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    generateDemoData();
    initializeScene();
  }
  
  void generateDemoData() {
    // Demo data points for 3D visualization
    chartData.value = [
      ChartPoint(x: 0, y: 2000, z: 0, label: '-20000'),
      ChartPoint(x: 1, y: 3500, z: 0, label: '-10000'),
      ChartPoint(x: 2, y: 5000, z: 0, label: '0'),
      ChartPoint(x: 3, y: 4000, z: 0, label: '5000'),
      ChartPoint(x: 4, y: 6000, z: 0, label: '10000'),
      ChartPoint(x: 5, y: 8000, z: 0, label: '15000'),
    ];
  }
  
  void initializeScene() {
    scene = Scene();
    chartObject = Object(fileName: "");
    scene.world.add(chartObject);
    scene.camera.position.setValues(0, 5, 10);
    scene.camera.target.setValues(0, 0, 0);
  }
  
  void rotateLeft() {
    rotationY.value -= 0.1;
  }
  
  void rotateRight() {
    rotationY.value += 0.1;
  }
  
  void rotateUp() {
    rotationX.value -= 0.1;
  }
  
  void rotateDown() {
    rotationX.value += 0.1;
  }
  
  void toggleAutoRotation() {
    isAutoRotating.value = !isAutoRotating.value;
  }
  
  void resetRotation() {
    rotationX.value = -0.4;
    rotationY.value = 0.6;
    isAutoRotating.value = false;
  }
  
  void changeChartType(String type) {
    selectedChartType.value = type;
  }
}

class ChartPoint {
  final double x;
  final double y;
  final double z;
  final String label;
  
  ChartPoint({
    required this.x,
    required this.y,
    required this.z,
    required this.label,
  });
}

// Main 3D Chart Page
class Chart3DPage extends StatelessWidget {
  final Chart3DController controller = Get.put(Chart3DController());
  
  Chart3DPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Start auto rotation if enabled
    if (controller.isAutoRotating.value) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (controller.isAutoRotating.value) {
          controller.rotationY.value += 0.02;
        }
      });
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('3D Interactive Chart'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Row(
          children: [
            // Main 3D Chart Area
            Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height - 100,
                color: Colors.black,
                child: Center(
                  child: Obx(() {
                    // Trigger rebuild for auto rotation
                    if (controller.isAutoRotating.value) {
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (controller.isAutoRotating.value && context.mounted) {
                          controller.rotationY.value += 0.02;
                        }
                      });
                    }
                    
                    return Custom3DChart(
                      data: controller.chartData,
                      rotationX: controller.rotationX.value,
                      rotationY: controller.rotationY.value,
                      chartType: controller.selectedChartType.value,
                    );
                  }),
                ),
              ),
            ),
            
            // Right Side Control Panel
            Container(
              width: 80,
              color: Colors.grey[900],
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Rotation Controls
                    _buildControlButton(
                      icon: Icons.arrow_upward,
                      label: 'Up',
                      color: Colors.blue,
                      onTap: () => controller.rotateUp(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSmallButton(
                          icon: Icons.arrow_back,
                          color: Colors.blue,
                          onTap: () => controller.rotateLeft(),
                        ),
                        const SizedBox(width: 4),
                        _buildSmallButton(
                          icon: Icons.arrow_forward,
                          color: Colors.blue,
                          onTap: () => controller.rotateRight(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildControlButton(
                      icon: Icons.arrow_downward,
                      label: 'Down',
                      color: Colors.blue,
                      onTap: () => controller.rotateDown(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Auto Rotation
                    Obx(() => _buildControlButton(
                      icon: controller.isAutoRotating.value 
                          ? Icons.pause 
                          : Icons.play_arrow,
                      label: 'Auto',
                      color: controller.isAutoRotating.value 
                          ? Colors.orange 
                          : Colors.green,
                      onTap: () => controller.toggleAutoRotation(),
                    )),
                    const SizedBox(height: 16),
                    
                    _buildControlButton(
                      icon: Icons.refresh,
                      label: 'Reset',
                      color: Colors.red,
                      onTap: () => controller.resetRotation(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Chart Type Controls
                    _buildControlButton(
                      icon: Icons.grid_3x3,
                      label: 'Pipe',
                      color: Colors.purple,
                      onTap: () => controller.changeChartType('Surface'),
                    ),
                    const SizedBox(height: 16),
                    _buildControlButton(
                      icon: Icons.show_chart,
                      label: 'Line',
                      color: Colors.cyan,
                      onTap: () => controller.changeChartType('Line'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSmallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom 3D Chart Widget
class Custom3DChart extends StatefulWidget {
  final RxList<ChartPoint> data;
  final double rotationX;
  final double rotationY;
  final String chartType;
  
  const Custom3DChart({
    Key? key,
    required this.data,
    required this.rotationX,
    required this.rotationY,
    required this.chartType,
  }) : super(key: key);
  
  @override
  State<Custom3DChart> createState() => _Custom3DChartState();
}

class _Custom3DChartState extends State<Custom3DChart> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: Chart3DPainter(
        data: widget.data,
        rotationX: widget.rotationX,
        rotationY: widget.rotationY,
        chartType: widget.chartType,
      ),
      size: Size.infinite,
    );
  }
}

// Custom Painter for 3D Chart
class Chart3DPainter extends CustomPainter {
  final RxList<ChartPoint> data;
  final double rotationX;
  final double rotationY;
  final String chartType;
  
  Chart3DPainter({
    required this.data,
    required this.rotationX,
    required this.rotationY,
    required this.chartType,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = math.min(size.width, size.height) / 18; // Smaller scale
    
    // Draw 3D grid walls (like in image)
    _draw3DGridWalls(canvas, centerX, centerY, scale);
    
    // Draw axes
    _draw3DAxes(canvas, centerX, centerY, scale);
    
    // Always draw the pipe/cylinder graph (main dynamic graph)
    _drawPipeGraph(canvas, centerX, centerY, scale);
    
    // Draw chart based on type (additional visualization)
    if (chartType == 'Line') {
      _draw3DLine(canvas, centerX, centerY, scale);
    }
    
    // Draw labels
    _drawLabels(canvas, centerX, centerY, scale);
  }
  
  Offset project3D(double x, double y, double z, double cx, double cy, double scale) {
    // Apply rotation
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    
    // Rotate around Y axis
    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;
    
    // Rotate around X axis
    final y1 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;
    
    // Project to 2D with perspective
    final perspective = 1 / (1 + z2 * 0.05);
    final projX = cx + x1 * scale * perspective;
    final projY = cy - y1 * scale * perspective;
    
    return Offset(projX, projY);
  }
  
  void _draw3DGridWalls(Canvas canvas, double cx, double cy, double scale) {
    final wallPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    // Back wall (X-Y plane at z=5)
    final backWall = Path();
    backWall.moveTo(
      project3D(-5, -3, 5, cx, cy, scale).dx,
      project3D(-5, -3, 5, cx, cy, scale).dy,
    );
    backWall.lineTo(
      project3D(5, -3, 5, cx, cy, scale).dx,
      project3D(5, -3, 5, cx, cy, scale).dy,
    );
    backWall.lineTo(
      project3D(5, 5, 5, cx, cy, scale).dx,
      project3D(5, 5, 5, cx, cy, scale).dy,
    );
    backWall.lineTo(
      project3D(-5, 5, 5, cx, cy, scale).dx,
      project3D(-5, 5, 5, cx, cy, scale).dy,
    );
    backWall.close();
    canvas.drawPath(backWall, wallPaint);
    
    // Draw grid lines on back wall
    for (int i = -4; i <= 4; i++) {
      // Vertical lines
      canvas.drawLine(
        project3D(i.toDouble(), -3, 5, cx, cy, scale),
        project3D(i.toDouble(), 5, 5, cx, cy, scale),
        gridPaint,
      );
      // Horizontal lines
      canvas.drawLine(
        project3D(-5, i.toDouble(), 5, cx, cy, scale),
        project3D(5, i.toDouble(), 5, cx, cy, scale),
        gridPaint,
      );
    }
    
    // Right wall (Y-Z plane at x=5)
    final rightWall = Path();
    rightWall.moveTo(
      project3D(5, -3, -5, cx, cy, scale).dx,
      project3D(5, -3, -5, cx, cy, scale).dy,
    );
    rightWall.lineTo(
      project3D(5, -3, 5, cx, cy, scale).dx,
      project3D(5, -3, 5, cx, cy, scale).dy,
    );
    rightWall.lineTo(
      project3D(5, 5, 5, cx, cy, scale).dx,
      project3D(5, 5, 5, cx, cy, scale).dy,
    );
    rightWall.lineTo(
      project3D(5, 5, -5, cx, cy, scale).dx,
      project3D(5, 5, -5, cx, cy, scale).dy,
    );
    rightWall.close();
    canvas.drawPath(rightWall, wallPaint);
    
    // Draw grid lines on right wall
    for (int i = -4; i <= 4; i++) {
      // Vertical lines
      canvas.drawLine(
        project3D(5, -3, i.toDouble(), cx, cy, scale),
        project3D(5, 5, i.toDouble(), cx, cy, scale),
        gridPaint,
      );
      // Horizontal lines
      canvas.drawLine(
        project3D(5, i.toDouble(), -5, cx, cy, scale),
        project3D(5, i.toDouble(), 5, cx, cy, scale),
        gridPaint,
      );
    }
    
    // Floor (X-Z plane at y=-3)
    final floor = Path();
    floor.moveTo(
      project3D(-5, -3, -5, cx, cy, scale).dx,
      project3D(-5, -3, -5, cx, cy, scale).dy,
    );
    floor.lineTo(
      project3D(5, -3, -5, cx, cy, scale).dx,
      project3D(5, -3, -5, cx, cy, scale).dy,
    );
    floor.lineTo(
      project3D(5, -3, 5, cx, cy, scale).dx,
      project3D(5, -3, 5, cx, cy, scale).dy,
    );
    floor.lineTo(
      project3D(-5, -3, 5, cx, cy, scale).dx,
      project3D(-5, -3, 5, cx, cy, scale).dy,
    );
    floor.close();
    canvas.drawPath(floor, wallPaint);
    
    // Draw grid lines on floor
    for (int i = -4; i <= 4; i++) {
      canvas.drawLine(
        project3D(i.toDouble(), -3, -5, cx, cy, scale),
        project3D(i.toDouble(), -3, 5, cx, cy, scale),
        gridPaint,
      );
      canvas.drawLine(
        project3D(-5, -3, i.toDouble(), cx, cy, scale),
        project3D(5, -3, i.toDouble(), cx, cy, scale),
        gridPaint,
      );
    }
  }
  
  void _draw3DAxes(Canvas canvas, double cx, double cy, double scale) {
    final axisPaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // X axis - Red
    axisPaint.color = Colors.red;
    canvas.drawLine(
      project3D(-5, -3, 0, cx, cy, scale),
      project3D(5, -3, 0, cx, cy, scale),
      axisPaint,
    );
    
    // Y axis - Green (vertical cylinder in image)
    axisPaint.color = Colors.green;
    canvas.drawLine(
      project3D(0, -3, 0, cx, cy, scale),
      project3D(0, 5, 0, cx, cy, scale),
      axisPaint,
    );
    
    // Draw cylinder for Y axis
    _drawCylinder(canvas, cx, cy, scale);
    
    // Z axis - Blue
    axisPaint.color = Colors.blue;
    canvas.drawLine(
      project3D(0, -3, -5, cx, cy, scale),
      project3D(0, -3, 5, cx, cy, scale),
      axisPaint,
    );
  }
  
  void _drawCylinder(Canvas canvas, double cx, double cy, double scale) {
    final cylinderPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    final edgePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Draw cylinder segments
    final segments = 16;
    for (int i = 0; i < segments; i++) {
      final angle1 = (i / segments) * 2 * math.pi;
      final angle2 = ((i + 1) / segments) * 2 * math.pi;
      
      final r = 0.15;
      
      // Bottom circle
      final x1 = r * math.cos(angle1);
      final z1 = r * math.sin(angle1);
      final x2 = r * math.cos(angle2);
      final z2 = r * math.sin(angle2);
      
      // Draw side face
      final path = Path();
      path.moveTo(
        project3D(x1, -3, z1, cx, cy, scale).dx,
        project3D(x1, -3, z1, cx, cy, scale).dy,
      );
      path.lineTo(
        project3D(x2, -3, z2, cx, cy, scale).dx,
        project3D(x2, -3, z2, cx, cy, scale).dy,
      );
      path.lineTo(
        project3D(x2, 5, z2, cx, cy, scale).dx,
        project3D(x2, 5, z2, cx, cy, scale).dy,
      );
      path.lineTo(
        project3D(x1, 5, z1, cx, cy, scale).dx,
        project3D(x1, 5, z1, cx, cy, scale).dy,
      );
      path.close();
      
      canvas.drawPath(path, cylinderPaint);
      canvas.drawPath(path, edgePaint);
    }
  }
  
  void _drawPipeGraph(Canvas canvas, double cx, double cy, double scale) {
    // This is the main dynamic pipe/cylinder graph like in the image
    final pipePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final edgePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Draw connecting pipes between data points
    for (int i = 0; i < data.length - 1; i++) {
      final p1 = data[i];
      final p2 = data[i + 1];
      
      final x1 = p1.x - 2.5;
      final y1 = -3 + (p1.y / 1000) * 0.6; // Smaller height scale
      final x2 = p2.x - 2.5;
      final y2 = -3 + (p2.y / 1000) * 0.6;
      
      final z = 0.0;
      
      // Draw pipe segment connecting two points
      _drawPipeSegment(canvas, cx, cy, scale, x1, y1, z, x2, y2, z, pipePaint, edgePaint);
    }
    
    // Draw spheres at data points
    final spherePaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;
    
    for (var point in data) {
      final x = point.x - 2.5;
      final y = -3 + (point.y / 1000) * 0.6;
      final z = 0.0;
      
      final projected = project3D(x, y, z, cx, cy, scale);
      
      // Draw 3D sphere at junction
      for (int r = 8; r > 0; r--) {
        final alpha = (1 - r / 8) * 0.8;
        canvas.drawCircle(
          projected,
          r.toDouble(),
          Paint()
            ..color = Colors.cyanAccent.withOpacity(alpha)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }
  
  void _drawPipeSegment(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double x1,
    double y1,
    double z1,
    double x2,
    double y2,
    double z2,
    Paint fillPaint,
    Paint edgePaint,
  ) {
    final segments = 12;
    final radius = 0.1; // Pipe radius
    
    // Calculate direction vector
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dz = z2 - z1;
    final length = math.sqrt(dx * dx + dy * dy + dz * dz);
    
    if (length < 0.01) return;
    
    // Draw pipe as a series of quads around the line
    for (int i = 0; i < segments; i++) {
      final angle1 = (i / segments) * 2 * math.pi;
      final angle2 = ((i + 1) / segments) * 2 * math.pi;
      
      // Calculate perpendicular offsets
      final ox1 = radius * math.cos(angle1);
      final oz1 = radius * math.sin(angle1);
      final ox2 = radius * math.cos(angle2);
      final oz2 = radius * math.sin(angle2);
      
      // Create quad face
      final path = Path();
      path.moveTo(
        project3D(x1 + ox1, y1, z1 + oz1, cx, cy, scale).dx,
        project3D(x1 + ox1, y1, z1 + oz1, cx, cy, scale).dy,
      );
      path.lineTo(
        project3D(x1 + ox2, y1, z1 + oz2, cx, cy, scale).dx,
        project3D(x1 + ox2, y1, z1 + oz2, cx, cy, scale).dy,
      );
      path.lineTo(
        project3D(x2 + ox2, y2, z2 + oz2, cx, cy, scale).dx,
        project3D(x2 + ox2, y2, z2 + oz2, cx, cy, scale).dy,
      );
      path.lineTo(
        project3D(x2 + ox1, y2, z2 + oz1, cx, cy, scale).dx,
        project3D(x2 + ox1, y2, z2 + oz1, cx, cy, scale).dy,
      );
      path.close();
      
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, edgePaint);
    }
  }
  
  void _draw3DLine(Canvas canvas, double cx, double cy, double scale) {
    final linePaint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final pointPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    
    // Draw line graph overlay
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = point.x - 2.5;
      final y = -3 + (point.y / 1000) * 0.6;
      final z = 0.5; // Offset to be visible alongside pipe
      
      final projected = project3D(x, y, z, cx, cy, scale);
      
      if (i == 0) {
        path.moveTo(projected.dx, projected.dy);
      } else {
        path.lineTo(projected.dx, projected.dy);
      }
      
      // Draw point marker
      canvas.drawCircle(projected, 4, pointPaint);
      canvas.drawCircle(projected, 4, Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
    
    canvas.drawPath(path, linePaint);
  }
  
  void _drawLabels(Canvas canvas, double cx, double cy, double scale) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    // Draw Y-axis labels (left side)
    for (int i = 0; i <= 8; i += 2) {
      final y = -3 + (i / 10) * 6; // Adjusted for smaller scale
      final pos = project3D(-5.5, y, 0, cx, cy, scale);
      
      textPainter.text = TextSpan(
        text: '${i * 1000}',
        style: const TextStyle(color: Colors.white70, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - 25, pos.dy - 5));
    }
    
    // Draw X-axis labels (bottom)
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = point.x - 2.5;
      final pos = project3D(x, -3.5, 0, cx, cy, scale);
      
      textPainter.text = TextSpan(
        text: point.label,
        style: const TextStyle(color: Colors.white70, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - 20, pos.dy + 5));
    }
    
    // Draw Z-axis labels
    final zLabels = ['0', '5000', '10000', '15000'];
    for (int i = 0; i < 4; i++) {
      final z = -3 + i * 2.0;
      final pos = project3D(0, -3.5, z, cx, cy, scale);
      
      textPainter.text = TextSpan(
        text: zLabels[i],
        style: const TextStyle(color: Colors.white70, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - 15, pos.dy + 5));
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

