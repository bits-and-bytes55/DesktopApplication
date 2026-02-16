import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/pit_snapshot_Controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PitSnapshotPage extends StatelessWidget {
  const PitSnapshotPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PitSnapshotController());
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Pit Snapshot', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            color: const Color(0xFFF5F5F5),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Legend
                    _buildHeader(controller),
                    const SizedBox(height: 16),
                    
                    // Main Content
                    constraints.maxWidth > 1000 
                        ? _buildWideLayout(controller) 
                        : _buildNarrowLayout(controller),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(PitSnapshotController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '*UG-0293 ST, Daily Report 1',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E4A5F)),
          ),
          Row(
            children: [
              Container(
                width: 24,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFD07845),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Active Pits', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 20),
              Container(
                width: 24,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8AA6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Storage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(PitSnapshotController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Chart Section - Increased Width
        Expanded(
          flex: 3,
          child: _buildChartSection(controller),
        ),
        const SizedBox(width: 16),
        // Right Data Section - Decreased Width
        Expanded(
          flex: 2,
          child: _buildDataSection(controller),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(PitSnapshotController controller) {
    return Column(
      children: [
        _buildChartSection(controller),
        const SizedBox(height: 16),
        _buildDataSection(controller),
      ],
    );
  }

  Widget _buildChartSection(PitSnapshotController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MD/TVD (m)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    const Text('0.00 ≈ 0.00', style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Shoe (m)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    const Text('0.00', style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          
          // Chart Area
          Obx(() => SizedBox(
            height: 650,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Left vertical scale with depth markers
                  SizedBox(
                    width: 110,
                    child: CustomPaint(
                      painter: DepthScalePainter(),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Well diagram with 2 pipes
                  Expanded(
                    flex: 2,
                    child: CustomPaint(
                      painter: WellDiagramPainter(),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Pit list containers - equal size
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...controller.activePits.map((pit) => _buildPitItem(pit, true)),
                          const SizedBox(height: 4),
                          ...controller.storagePits.map((pit) => _buildPitItem(pit, false)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
          
          // Bottom depth labels
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('2386.5', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 80),
                const Text('2759.3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitItem(Map<String, dynamic> pit, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      height: 50, // Fixed equal height
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFD07845) : const Color(0xFF5B8AA6),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          pit['name'],
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDataSection(PitSnapshotController controller) {
    return Column(
      children: [
        _buildVolumeSummaryTable(controller),
        const SizedBox(height: 16),
        _buildPitConcentrationTable(controller),
      ],
    );
  }

  Widget _buildVolumeSummaryTable(PitSnapshotController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.summarize, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Volume Summary',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showHoleVolumeDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Hole Volume',
                        style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () => _showCkbVolumeDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'CKB Volume',
                        style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Obx(() => Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1)),
                children: [
                  _buildTableHeaderCell('Vol. Name', TextAlign.left),
                  _buildTableHeaderCell('Vol. (bbl)', TextAlign.right),
                ],
              ),
              ...controller.volumeSummaryData.asMap().entries.map((entry) {
                bool isNegative = entry.value['volume'].toString().contains('-');
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        entry.value['name'],
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          hintText: entry.value['volume'],
                          hintStyle: TextStyle(fontSize: 11),
                          isDense: true,
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: isNegative ? Colors.red : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                        onChanged: (value) => controller.updateVolumeSummary(entry.key, value),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildPitConcentrationTable(PitSnapshotController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.science, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Pit Concentration',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: controller.selectedSystem.value,
                    underline: const SizedBox(),
                    isDense: true,
                    style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    items: controller.systemOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) controller.changeSystem(value);
                    },
                  ),
                )),
              ],
            ),
          ),
          SizedBox(
            height: 450,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                  headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
                  columnSpacing: 10,
                  horizontalMargin: 10,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 36,
                  headingRowHeight: 38,
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width: 25,
                        child: Text(
                          '',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 180,
                        child: Text(
                          'Product',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 70,
                        child: Text(
                          'Unit',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 80,
                        child: Text(
                          'Start Conc.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 80,
                        child: Text(
                          'End Conc.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  ],
                  rows: controller.pitConcentrationData.asMap().entries.map((entry) {
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 25,
                            child: Text(
                              '${entry.value['id']}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(
                              entry.value['product'],
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 70,
                            child: Text(
                              entry.value['unit'],
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 80,
                            height: 30,
                            child: TextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                              onChanged: (value) => controller.updatePitConcentration(entry.key, 'startConc', value),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 80,
                            height: 30,
                            child: TextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                              onChanged: (value) => controller.updatePitConcentration(entry.key, 'endConc', value),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, TextAlign align) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
        textAlign: align,
      ),
    );
  }

  void _showHoleVolumeDialog() {
    final controller = Get.find<PitSnapshotController>();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hole Volume (bbl)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() => Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1)),
                      children: [
                        _buildTableHeaderCell('Description', TextAlign.left),
                        _buildTableHeaderCell('Volume', TextAlign.right),
                      ],
                    ),
                    ...controller.holeVolumeData.asMap().entries.map((entry) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              entry.value['name'],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: TextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 11),
                              textAlign: TextAlign.right,
                              onChanged: (value) => controller.updateHoleVolume(entry.key, value),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCkbVolumeDialog() {
    final controller = Get.find<PitSnapshotController>();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CKB Volume (bbl)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() => Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1)),
                      children: [
                        _buildTableHeaderCell('Line Type', TextAlign.left),
                        _buildTableHeaderCell('Volume', TextAlign.right),
                      ],
                    ),
                    ...controller.ckbVolumeData.asMap().entries.map((entry) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              entry.value['name'],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: TextField(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 11),
                              textAlign: TextAlign.right,
                              onChanged: (value) => controller.updateCkbVolume(entry.key, value),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= DEPTH SCALE PAINTER =============
class DepthScalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // Draw main vertical line in center
    final centerX = size.width / 2;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      linePaint,
    );

    // Draw horizontal tick marks and depth labels
    final depths = [
      {'value': '0.00', 'position': 0.0},
      {'value': '500.00', 'position': 0.16},
      {'value': '1000.00', 'position': 0.33},
      {'value': '1500.00', 'position': 0.50},
      {'value': '2000.00', 'position': 0.67},
      {'value': '2500.00', 'position': 0.83},
      {'value': '2759.36', 'position': 1.0},
    ];

    for (var depth in depths) {
      final y = size.height * (depth['position'] as double);
      
      // Draw horizontal tick mark across the vertical line (1cm total)
      canvas.drawLine(
        Offset(centerX - 15, y),
        Offset(centerX + 15, y),
        linePaint,
      );

      // Draw left side depth text
      textPainter.text = TextSpan(
        text: depth['value'] as String,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, y - textPainter.height / 2),
      );

      // Draw right side depth text
      textPainter.text = TextSpan(
        text: depth['value'] as String,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width - textPainter.width, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============= WELL DIAGRAM PAINTER =============
class WellDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pipePaint = Paint()
      ..color = const Color(0xFF696969)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Left pipe (goes from top to 90%)
    final leftPipePath = Path();
    leftPipePath.moveTo(size.width * 0.35, 0);
    leftPipePath.lineTo(size.width * 0.42, 0);
    leftPipePath.lineTo(size.width * 0.42, size.height * 0.90);
    leftPipePath.lineTo(size.width * 0.35, size.height * 0.90);
    leftPipePath.close();
    canvas.drawPath(leftPipePath, pipePaint);
    canvas.drawPath(leftPipePath, strokePaint);

    // Right pipe (goes from top to 90%)
    final rightPipePath = Path();
    rightPipePath.moveTo(size.width * 0.58, 0);
    rightPipePath.lineTo(size.width * 0.65, 0);
    rightPipePath.lineTo(size.width * 0.65, size.height * 0.90);
    rightPipePath.lineTo(size.width * 0.58, size.height * 0.90);
    rightPipePath.close();
    canvas.drawPath(rightPipePath, pipePaint);
    canvas.drawPath(rightPipePath, strokePaint);

    // Bottom shoe section (horizontal bar connecting both pipes)
    final shoePath = Path();
    shoePath.moveTo(size.width * 0.30, size.height * 0.85);
    shoePath.lineTo(size.width * 0.70, size.height * 0.85);
    shoePath.lineTo(size.width * 0.70, size.height * 0.90);
    shoePath.lineTo(size.width * 0.30, size.height * 0.90);
    shoePath.close();
    canvas.drawPath(shoePath, pipePaint);
    canvas.drawPath(shoePath, strokePaint);

    // Draw bit at bottom (triangle shape between pipes)
    final bitPath = Path();
    bitPath.moveTo(size.width * 0.42, size.height * 0.90);
    bitPath.lineTo(size.width * 0.50, size.height * 0.96);
    bitPath.lineTo(size.width * 0.58, size.height * 0.90);
    bitPath.close();
    canvas.drawPath(bitPath, pipePaint);
    canvas.drawPath(bitPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}