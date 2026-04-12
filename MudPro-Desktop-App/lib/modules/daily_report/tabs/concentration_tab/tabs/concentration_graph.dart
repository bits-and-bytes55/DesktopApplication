import 'package:flutter/material.dart';

class ConcentrationGraphTab extends StatelessWidget {
  const ConcentrationGraphTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xffF8F9FA),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xffE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Graph Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xffE2E8F0), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.show_chart, color: Color(0xff6C9BCF), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Concentration Graph - Active System',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff2D3748),
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xffF8F9FA),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Color(0xffE2E8F0), width: 1),
                      ),
                      child: Text(
                        'Depth (ft) vs Concentration (lb/bbl)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff718096),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Graph Area
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: CustomPaint(
                    painter: _GraphPainter(),
                    size: Size(MediaQuery.of(context).size.width - 80, 400),
                  ),
                ),
              ),
              
              // Legend
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xffE2E8F0), width: 1),
                  ),
                ),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    _legendItem('Weight Material', Color(0xff6C9BCF)),
                    _legendItem('Viscosifier', Color(0xffA8D5BA)),
                    _legendItem('Common Chemical', Color(0xffFFB6C1)),
                    _legendItem('LCM', Color(0xff38B2AC)),
                    _legendItem('Defoamer', Color(0xffED8936)),
                    _legendItem('Filtration Control', Color(0xff4299E1)),
                    _legendItem('Others', Color(0xff9F7AEA)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xff718096),
          ),
        ),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw background
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw grid lines
    paint.color = Color(0xffE2E8F0);
    paint.strokeWidth = 0.5;
    
    // Vertical grid lines
    for (double x = 60; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 20), Offset(x, size.height - 40), paint);
    }
    
    // Horizontal grid lines
    for (double y = 20; y < size.height - 40; y += 40) {
      canvas.drawLine(Offset(60, y), Offset(size.width - 20, y), paint);
    }
    
    // Draw axes
    paint.color = Color(0xff2D3748);
    paint.strokeWidth = 1.5;
    
    // Y axis
    canvas.drawLine(
      Offset(60, 20),
      Offset(60, size.height - 40),
      paint,
    );
    
    // X axis
    canvas.drawLine(
      Offset(60, size.height - 40),
      Offset(size.width - 20, size.height - 40),
      paint,
    );
    
    // Draw sample data lines with theme colors
    final colors = [
      Color(0xff6C9BCF),    // Weight Material
      Color(0xffA8D5BA),    // Viscosifier
      Color(0xffFFB6C1),    // Common Chemical
      Color(0xff38B2AC),    // LCM
      Color(0xffED8936),    // Defoamer
      Color(0xff4299E1),    // Filtration Control
    ];
    
    for (int lineIndex = 0; lineIndex < colors.length; lineIndex++) {
      paint.color = colors[lineIndex];
      paint.strokeWidth = 2.0;
      paint.style = PaintingStyle.stroke;
      
      final path = Path();
      final startY = size.height - 40 - (100 * (lineIndex + 1) / 20) * (size.height - 60) / 1000;
      path.moveTo(60, startY);
      
      for (int i = 1; i <= 6; i++) {
        final x = 60 + (i * (size.width - 80) / 6);
        final yVariation = (lineIndex + 1) * 20 * (i % 3 == 0 ? 1 : -1);
        final y = startY - (yVariation / 1000) * (size.height - 60);
        path.lineTo(x, y);
        
        // Draw data points
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 4, paint);
        paint.style = PaintingStyle.stroke;
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}