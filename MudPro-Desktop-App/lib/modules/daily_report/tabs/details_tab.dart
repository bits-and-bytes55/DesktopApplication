import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DetailsTabView extends StatelessWidget {
  const DetailsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 1200;
          final isMediumScreen = constraints.maxWidth > 800;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Gradient
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.headerGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Detailed Analysis",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Comprehensive drilling parameters and calculations",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text("Export"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.refresh, color: Colors.white, size: 20),
                            tooltip: 'Refresh Data',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.filter_alt, color: Colors.white, size: 20),
                            tooltip: 'Filter Data',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
               
                
                // Main Content - Always use large layout for solids, bit, and volume tables
                _buildLargeLayout(),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLargeLayout() {
    return Column(
      children: [
        // First Row - Geometry & Circulation
        SizedBox(
          height: 400,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: const GeometryTable(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: const CirculationTable(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Second Row - Annular Hydraulics (Full Width)
        const SizedBox(
          height: 350,
          child: AnnularHydraulicsTable(),
        ),
        
        const SizedBox(height: 16),
        
        // Third Row - Other Tables
        SizedBox(
          height: 350,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: const SolidsAnalysisTable(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: const BitHydraulicsTable(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: const VolumeTable(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMediumLayout() {
    return Column(
      children: [
        // First Row
        SizedBox(
          height: 400,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: const GeometryTable(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: const CirculationTable(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Second Row
        const SizedBox(
          height: 350,
          child: AnnularHydraulicsTable(),
        ),
        
        const SizedBox(height: 16),
        
        // Third Row
        SizedBox(
          height: 350,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: const SolidsAnalysisTable(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: const BitHydraulicsTable(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Fourth Row
        const SizedBox(
          height: 300,
          child: VolumeTable(),
        ),
      ],
    );
  }
  
  Widget _buildSmallLayout() {
    return Column(
      children: [
        const SizedBox(height: 400, child: GeometryTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 350, child: CirculationTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 400, child: AnnularHydraulicsTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 350, child: SolidsAnalysisTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 300, child: BitHydraulicsTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 300, child: VolumeTable()),
      ],
    );
  }
}

// Tab Item Widget
class _TabItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  
  const _TabItem(this.title, this.icon, [this.isActive = false]);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        color: isActive ? AppTheme.primaryColor : Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Common Widgets
Widget _buildEditableCell({
  String value = "", 
  bool center = true,
  bool isHeader = false,
  Color? backgroundColor,
}) {
  return Container(
    height: 36, // Fixed row height
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      color: backgroundColor ?? Colors.white,
    ),
    child: Center(
      child: TextField(
        controller: TextEditingController(text: value),
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? AppTheme.tableHeadColor : AppTheme.textPrimary,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          border: InputBorder.none,
          filled: false,
        ),
      ),
    ),
  );
}

Widget _buildStaticCell({
  required String text,
  bool center = true,
  bool isHeader = false,
  Color? backgroundColor,
  double? width,
}) {
  return Container(
    height: 36, // Fixed row height
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      color: backgroundColor ?? Colors.white,
    ),
    child: Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? AppTheme.tableHeadColor : AppTheme.textPrimary,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

// Card Container Widget with Improved Design
Widget _detailsCard(String title, Widget child, {int flex = 1}) {
  return Expanded(
    flex: flex,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.elevatedCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.9),
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      tooltip: 'Add Row',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, size: 18, color: Colors.white),
                      tooltip: 'Filter',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.white),
                      tooltip: 'More Options',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Table Container with Scroll
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Geometry Table with More Columns
class GeometryTable extends StatelessWidget {
  const GeometryTable({super.key});

  @override
  Widget build(BuildContext context) {
    return _detailsCard(
      "Geometry",
      Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(color: Colors.grey.shade200, width: 1),
        columnWidths: const {
          0: FixedColumnWidth(50),   // #
          1: FixedColumnWidth(200),  // Description
          2: FixedColumnWidth(140),  // OD (in)
          3: FixedColumnWidth(140),  // ID (in)
          4: FixedColumnWidth(140),  // Start (ft)
          5: FixedColumnWidth(140),  // End (ft)
        // Type
        },
        children: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryColor.withOpacity(0.8),
                  AppTheme.secondaryColor.withOpacity(0.6),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            children: [
              _buildStaticCell(text: "#", isHeader: true, backgroundColor: Colors.transparent),
              _buildStaticCell(text: "Description", isHeader: true, center: false, backgroundColor: Colors.transparent),
   
              _buildStaticCell(text: "Start (ft)", isHeader: true, backgroundColor: Colors.transparent),
              _buildStaticCell(text: "End (ft)", isHeader: true, backgroundColor: Colors.transparent),
              _buildStaticCell(text: "Vol (bbl)", isHeader: true, backgroundColor: Colors.transparent),
              _buildStaticCell(text: "Vol (bbl/ft)", isHeader: true, backgroundColor: Colors.transparent),
            ],
          ),
          
          // Data Rows
          ...List.generate(20, (index) {
            final rowColor = index % 2 == 0 ? Colors.white : AppTheme.backgroundColor;
            return TableRow(
              decoration: BoxDecoration(color: rowColor),
              children: [
                _buildStaticCell(text: "${index + 1}"),
                _buildEditableCell(value: _getDescription(index), center: false),
              
                _buildEditableCell(value: _getStartDepth(index)),
                _buildEditableCell(value: _getEndDepth(index)),
                _buildEditableCell(value: _getVolume(index)),
                _buildEditableCell(value: _getVolumePerFt(index)),
              ],
            );
          }),
        ],
      ),
      flex: 2,
    );
  }
  
  String _getDescription(int index) {
    final descriptions = [
      "Surface Casing",
      "Intermediate Casing",
      "Production Casing",
      "Liner",
      "Drill Pipe",
      "Heavy Weight DP",
      "Drill Collar",
      "Bit Sub",
      "Stabilizer",
      "Crossover",
      "Shock Sub",
      "Jar",
      "Motor",
      "MWD",
      "Float Sub",
      "Cement Plug",
      "Open Hole",
      "Rat Hole",
      "Mouse Hole",
      "Riser"
    ];
    return index < descriptions.length ? descriptions[index] : "Item ${index + 1}";
  }
  
  String _getOD(int index) => (4.0 + index * 0.5).toStringAsFixed(1);
  String _getID(int index) => (3.5 + index * 0.4).toStringAsFixed(1);
  String _getStartDepth(int index) => "${index * 500}";
  String _getEndDepth(int index) => "${(index + 1) * 500}";
  String _getLength(int index) => "500";
  String _getVolume(int index) => "${(100 + index * 20).toStringAsFixed(1)}";
  String _getVolumePerFt(int index) => "${(0.2 + index * 0.05).toStringAsFixed(2)}";
  String _getType(int index) => ["CSG", "DP", "DC", "HWDP", "BIT"][index % 5];
}

// Circulation Table with Moderate Columns
class CirculationTable extends StatelessWidget {
  const CirculationTable({super.key});

  @override
  Widget build(BuildContext context) {
    return _detailsCard(
      "Circulation",
      Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(color: Colors.grey.shade200, width: 1),
        columnWidths: const {
          0: FixedColumnWidth(50),   // #
          1: FixedColumnWidth(170),  // Path
          2: FixedColumnWidth(100),  // Minutes
          3: FixedColumnWidth(100),  // Strokes
        
        },
        children: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentColor.withOpacity(0.8),
                  AppTheme.accentColor.withOpacity(0.6),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            children: [
              _buildStaticCell(text: "#", isHeader: true, backgroundColor: Colors.transparent),
              _buildStaticCell(text: "Path", isHeader: true, center: false, backgroundColor: Colors.transparent),
              _buildStaticCell(text: "Minutes", isHeader: true, backgroundColor: Colors.transparent),
              _buildStaticCell(text: "Strokes", isHeader: true, backgroundColor: Colors.transparent),
            
            ],
          ),
          
          // Data Rows
          ...List.generate(15, (index) {
            final rowColor = index % 2 == 0 ? Colors.white : AppTheme.backgroundColor;
            return TableRow(
              decoration: BoxDecoration(color: rowColor),
              children: [
                _buildStaticCell(text: "${index + 1}"),
                _buildEditableCell(value: _getPath(index), center: false),
                _buildEditableCell(value: "${10 + index * 2}"),
                _buildEditableCell(value: "${1000 + index * 150}"),
                
              ],
            );
          }),
        ],
      ),
      flex: 1,
    );
  }
  
  String _getPath(int index) {
    final paths = [
      "DP to Bit",
      "Bit to Annulus",
      "Annulus to Surface",
      "Casing to Annulus",
      "Surface Lines",
      "Mud Pumps",
      "Standpipe",
      "Kelly Hose",
      "Swivel",
      "Top Drive",
      "Drill String",
      "Open Hole",
      "Cased Hole",
      "Riser",
      "Choke Line"
    ];
    return index < paths.length ? paths[index] : "Path ${index + 1}";
  }
}

// Annular Hydraulics Table with Many Columns
class AnnularHydraulicsTable extends StatelessWidget {
  const AnnularHydraulicsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.elevatedCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Annular Hydraulics",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.calculate, size: 18, color: Colors.white),
                      tooltip: 'Calculate',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 18, color: Colors.white),
                      tooltip: 'Export',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Table Container
          Expanded(
            child: Container(
              color: Colors.white,
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        border: TableBorder.all(color: Colors.grey.shade200, width: 1),
                        columnWidths: const {
                          0: FixedColumnWidth(50),   // #
                          1: FixedColumnWidth(150),  // Section
                          2: FixedColumnWidth(80),   // Length
                          3: FixedColumnWidth(80),   // Btm MD
                          4: FixedColumnWidth(90),   // Vel Ann
                          5: FixedColumnWidth(90),   // Vel Crit
                          6: FixedColumnWidth(100),  // Crit Rate
                          7: FixedColumnWidth(80),   // Re Ann
                          8: FixedColumnWidth(80),   // Re Crit
                          9: FixedColumnWidth(90),   // ECD
                          10: FixedColumnWidth(90),  // ΔP
                          11: FixedColumnWidth(90),  // HSI
                           12: FixedColumnWidth(90),  // ΔP
                          13: FixedColumnWidth(90),  // HSI
                            14: FixedColumnWidth(90),  // ΔP
                          15: FixedColumnWidth(90),  
                        },
                        children: [
                          // Main Header
                          TableRow(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.9),
                                  AppTheme.primaryColor.withOpacity(0.7),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            children: [
                              _buildStaticCell(text: "#", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "Section (in)", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "Length", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "Btm MD", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "Vel Ann", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "Vel Crit", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "Crit Rate", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "Re Ann", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "Re Crit", isHeader: true, backgroundColor: Colors.transparent),
                                _buildStaticCell(text: "Eff. Visc(cP)", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "Flow", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "ECD", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "CCi", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "P.Drop(psi)", isHeader: true, backgroundColor: Colors.transparent),
                                _buildStaticCell(text: "Slip Vel.(ft/min)", isHeader: true, backgroundColor: Colors.transparent),
                              _buildStaticCell(text: "CTR(%)", isHeader: true, backgroundColor: Colors.transparent),
                            ],
                          ),
                          
                          // Data Rows
                          ...List.generate(12, (index) {
                            final rowColor = index % 2 == 0 ? Colors.white : AppTheme.backgroundColor;
                            return TableRow(
                              decoration: BoxDecoration(color: rowColor),
                              children: [
                                _buildStaticCell(text: "${index + 1}"),
                                _buildEditableCell(value: _getSection(index), center: false),
                                _buildEditableCell(value: "${500 + index * 100}"),
                                _buildEditableCell(value: "${index * 1000}"),
                                _buildEditableCell(value: "${120 + index * 10}"),
                                _buildEditableCell(value: "${80 + index * 5}"),
                                _buildEditableCell(value: "${300 + index * 20}"),
                                _buildEditableCell(value: "${1500 + index * 200}"),
                                _buildEditableCell(value: "${2000 + index * 300}"),
                                _buildEditableCell(value: "${9.5 + index * 0.1}"),
                                _buildEditableCell(value: "${50 + index * 5}"),
                                _buildEditableCell(value: "${2.5 + index * 0.2}"),
                                _buildEditableCell(value: "${1.2 + index * 0.1}"),
                                _buildEditableCell(value: "${850 + index * 50}"),
                                _buildEditableCell(value: "${15 + index * 2}"),
                                _buildEditableCell(value: "${75 + index * 5}"),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getSection(int index) {
    final sections = [
      "DP in OH",
      "DC in OH",
      "HWDP in OH",
      "DP in CSG",
      "DC in CSG",
      "HWDP in CSG",
      "Bit in OH",
      "Motor in OH",
      "MWD in OH",
      "Stab in OH",
      "Crossover",
      "Riser"
    ];
    return index < sections.length ? sections[index] : "Section ${index + 1}";
  }
}

// Solids Analysis Table
class SolidsAnalysisTable extends StatelessWidget {
  const SolidsAnalysisTable({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth;
        final descriptionWidth = tableWidth * 0.4; // 40% for description
        final sampleWidth = tableWidth * 0.2; // 20% for each sample

        return _detailsCard(
          "Solids Analysis",
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(color: Colors.grey.shade200, width: 1),
            columnWidths: {
              0: FixedColumnWidth(descriptionWidth.clamp(150, double.infinity)),  // Description
              1: FixedColumnWidth(sampleWidth.clamp(80, double.infinity)),  // Sample 1
              2: FixedColumnWidth(sampleWidth.clamp(80, double.infinity)),  // Sample 2
              3: FixedColumnWidth(sampleWidth.clamp(80, double.infinity)),  // Sample 3
            },
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.successColor.withOpacity(0.8),
                      AppTheme.successColor.withOpacity(0.6),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                children: [
                  _buildStaticCell(text: "Description", isHeader: true, center: false, backgroundColor: Colors.transparent),
                  _buildStaticCell(text: "Sample 1", isHeader: true, backgroundColor: Colors.transparent),
                  _buildStaticCell(text: "Sample 2", isHeader: true, backgroundColor: Colors.transparent),
                  _buildStaticCell(text: "Sample 3", isHeader: true, backgroundColor: Colors.transparent),

                ],
              ),

              // Data Rows
              ...List.generate(12, (index) {
                final rowColor = index % 2 == 0 ? Colors.white : AppTheme.backgroundColor;
                return TableRow(
                  decoration: BoxDecoration(color: rowColor),
                  children: [
                    _buildEditableCell(value: _getSolidParameter(index), center: false),
                    _buildEditableCell(value: _getSampleValue(index, 0)),
                    _buildEditableCell(value: _getSampleValue(index, 1)),
                    _buildEditableCell(value: _getSampleValue(index, 2)),

                  ],
                );
              }),
            ],
          ),
          flex: 1,
        );
      },
    );
  }
  
  String _getSolidParameter(int index) {
    final params = [
      "Sand Content",
      "Low Gravity Solids",
      "High Gravity Solids",
      "Bentonite",
      "Barite",
      "Salt",
      "Calcium",
      "Magnesium",
      "Chlorides",
      "pH",
      "MBT",
      "Rheology"
    ];
    return index < params.length ? params[index] : "Param ${index + 1}";
  }
  
  String _getSampleValue(int index, int sample) {
    return (sample * 10 + index * 2 + 1).toStringAsFixed(1);
  }
  
  String _getAverageValue(int index) {
    return (15 + index * 1.5).toStringAsFixed(1);
  }
  
  String _getTargetValue(int index) {
    return [5, 25, 35, 20, 45, 15, 10, 5, 30, 9, 25, 40][index % 12].toString();
  }
}

// Bit Hydraulics Table
class BitHydraulicsTable extends StatelessWidget {
  const BitHydraulicsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return _detailsCard(
      "Bit Hydraulics",
      Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(color: Colors.grey.shade200, width: 1),
        columnWidths: const {
          0: FixedColumnWidth(200),  // Parameter
          1: FixedColumnWidth(140),  // Value
        },
        children: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warningColor.withOpacity(0.8),
                  AppTheme.warningColor.withOpacity(0.6),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            children: [
              _buildStaticCell(text: "Parameter", isHeader: true, center: false, backgroundColor: Colors.transparent),
              _buildStaticCell(text: "Value", isHeader: true, backgroundColor: Colors.transparent),

            ],
          ),
          
          // Data Rows
          ...List.generate(10, (index) {
            final rowColor = index % 2 == 0 ? Colors.white : AppTheme.backgroundColor;
            return TableRow(
              decoration: BoxDecoration(color: rowColor),
              children: [
                _buildStaticCell(text: _getBitHydraulicParameter(index), center: false),
                _buildEditableCell(value: _getBitValue(index)),
              
              ],
            );
          }),
        ],
      ),
      flex: 1,
    );
  }
  
  String _getBitHydraulicParameter(int index) {
    final parameters = [
      "Pressure Loss",
      "Flow Rate",
      "Nozzle Velocity",
      "Jet Impact Force",
      "Hydraulic HP",
      "Specific Energy",
      "Pressure Drop",
      "Flow Velocity",
      "Reynolds Number",
      "Friction Factor"
    ];
    return index < parameters.length ? parameters[index] : "Parameter ${index + 1}";
  }
  
  String _getBitValue(int index) {
    return [1200, 450, 350, 4500, 450, 3.5, 850, 180, 2500, 0.02][index % 10].toString();
  }
  
 
}

// Volume Table
class VolumeTable extends StatelessWidget {
  const VolumeTable({super.key});

  @override
  Widget build(BuildContext context) {
    return _detailsCard(
      "Volume (bbl)",
      Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(color: Colors.grey.shade200, width: 1),
        columnWidths: const {
          0: FixedColumnWidth(200),  // Section
          1: FixedColumnWidth(140),  // Volume
        },
        children: [
          // Header Row
          TableRow(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.infoColor.withOpacity(0.8),
                  AppTheme.infoColor.withOpacity(0.6),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            children: [
              _buildStaticCell(text: "Section", isHeader: true, center: false, backgroundColor: Colors.transparent),
              _buildStaticCell(text: "Volume", isHeader: true, backgroundColor: Colors.transparent),
            
            ],
          ),
          
          // Data Rows
          ...List.generate(10, (index) {
            final rowColor = index % 2 == 0 ? Colors.white : AppTheme.backgroundColor;
            return TableRow(
              decoration: BoxDecoration(color: rowColor),
              children: [
                _buildStaticCell(text: _getVolumeSection(index), center: false),
                _buildEditableCell(value: _getVolumeValue(index)),
              
              ],
            );
          }),
        ],
      ),
      flex: 1,
    );
  }
  
  String _getVolumeSection(int index) {
    final sections = [
      "Surface Volume",
      "Pipe Volume",
      "Annular Volume",
      "Casing Volume",
      "Open Hole Volume",
      "Total System Volume",
      "Mud Pit Volume",
      "Active Volume",
      "Displacement Volume",
      "Excess Volume"
    ];
    return index < sections.length ? sections[index] : "Section ${index + 1}";
  }
  
  String _getVolumeValue(int index) {
    return [850, 450, 1200, 800, 650, 3950, 1200, 2750, 350, 100][index % 10].toString();
  }
  

}