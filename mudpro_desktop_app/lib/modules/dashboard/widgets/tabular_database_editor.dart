import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/tabular_database_editor_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class TabularDatabaseEditorView extends StatelessWidget {
  TabularDatabaseEditorView({super.key});
  final c = Get.put(TabularDatabaseEditorController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Tubular Database Editor',
          style: AppTheme.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          )
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// LEFT TYPE TABLE
            _buildTypeTable(),
            
            SizedBox(width: 12),
            
            /// MIDDLE CATALOG TABLE
            _buildCatalogTable(),
            
            SizedBox(width: 12),
            
            /// RIGHT MAIN TABLE
            Expanded(child: _buildMainTable()),
          ],
        ),
      ),

      bottomNavigationBar: _buildFooter(),
    );
  }

  // ---------------- TYPE TABLE ----------------
  Widget _buildTypeTable() {
    return Container(
      width: 250, // Slightly wider for buttons
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          /// TABLE HEADER
          Container(
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.tableHeadColor, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.category, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pipe Types',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Obx(() => Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${c.types.length}',
                    style: AppTheme.caption.copyWith(color: Colors.white),
                  ),
                )),
              ],
            ),
          ),
          
          /// TYPE LIST
          Expanded(
            child: Obx(() {
              return Container(
                color: Colors.white,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: c.types.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final isSelected = c.selectedTypeIndex.value == index;
                      final type = c.types[index];
                      
                      return InkWell(
                        onTap: () => c.selectedTypeIndex.value = index,
                        hoverColor: AppTheme.primaryColor.withOpacity(0.05),
                        child: Container(
                          height: 40,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.25)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 10,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  type,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
          
          /// ADD/DELETE BUTTONS FOOTER
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                /// ADD BUTTON (+)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddTypeDialog(),
                    icon: Icon(Icons.add, size: 16),
                    label: Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                
                SizedBox(width: 8),
                
                /// DELETE BUTTON (X)
                Expanded(
                  child: Obx(() => ElevatedButton.icon(
                    onPressed: c.types.isNotEmpty && c.selectedTypeIndex.value < c.types.length
                        ? () => _showDeleteConfirmDialog(
                            'Delete Type',
                            'Are you sure you want to delete "${c.types[c.selectedTypeIndex.value]}"?',
                            c.deleteSelectedType,
                            true)
                        : null,
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CATALOG TABLE ----------------
  Widget _buildCatalogTable() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          /// TABLE HEADER
          Container(
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.tableHeadColor, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Catalog',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Obx(() => Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${c.catalogs.length}',
                    style: AppTheme.caption.copyWith(color: Colors.white),
                  ),
                )),
              ],
            ),
          ),
          
          /// CATALOG LIST
          Expanded(
            child: Obx(() {
              return Container(
                color: Colors.white,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: c.catalogs.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final isSelected = c.selectedCatalogIndex.value == index;
                      final catalog = c.catalogs[index];
                      
                      return InkWell(
                        onTap: () => c.selectedCatalogIndex.value = index,
                        hoverColor: AppTheme.primaryColor.withOpacity(0.05),
                        child: Container(
                          height: 40,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.25)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 10,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: Text(
                                  catalog,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
          
          /// ADD/DELETE BUTTONS FOOTER
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                /// ADD BUTTON (+)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddCatalogDialog(),
                    icon: Icon(Icons.add, size: 16),
                    label: Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                
                SizedBox(width: 8),
                
                /// DELETE BUTTON (X)
                Expanded(
                  child: Obx(() => ElevatedButton.icon(
                    onPressed: c.catalogs.isNotEmpty && c.selectedCatalogIndex.value < c.catalogs.length
                        ? () => _showDeleteConfirmDialog(
                            'Delete Catalog',
                            'Are you sure you want to delete "${c.catalogs[c.selectedCatalogIndex.value]}"?',
                            c.deleteSelectedCatalog,
                            true)
                        : null,
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MAIN TABLE ----------------
  Widget _buildMainTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// TABLE HEADER
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.tableHeadColor, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() {
              final selectedType = c.types.isNotEmpty && c.selectedTypeIndex.value < c.types.length 
                  ? c.types[c.selectedTypeIndex.value]
                  : 'No Type Selected';
              return Row(
                children: [
                  Icon(Icons.grid_on, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tubular Specifications - $selectedType',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${c.currentRows.length} rows',
                      style: AppTheme.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              );
            }),
          ),
          
          /// TABLE CONTENT
          Expanded(
            child: Obx(() {
              final rows = c.currentRows;
              return _buildTableContent(rows);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContent(List<Map<String, RxString>> rows) {
    // Column widths
    const double bodyColWidth = 90.0;
    const double connColWidth = 90.0;
    const double assemblyColWidth = 110.0;

    // Body columns (13)
    final bodyWidth = bodyColWidth * 13;
    // Connection columns (11)
    final connWidth = connColWidth * 11;

    final totalWidth = bodyWidth + connWidth + assemblyColWidth;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needsHorizontalScroll = totalWidth > constraints.maxWidth;

          if (needsHorizontalScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                child: Column(
                  children: [
                    /// COLUMN HEADERS
                    _buildTableHeaders(bodyColWidth, connColWidth, assemblyColWidth),

                    /// DATA ROWS
                    Expanded(
                      child: _buildTableRows(rows, bodyColWidth, connColWidth, assemblyColWidth),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Column(
              children: [
                /// COLUMN HEADERS
                _buildTableHeaders(bodyColWidth, connColWidth, assemblyColWidth),

                /// DATA ROWS
                Expanded(
                  child: _buildTableRows(rows, bodyColWidth, connColWidth, assemblyColWidth),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTableHeaders(double bodyWidth, double connWidth, double assemblyWidth) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: Column(
        children: [
          /// MAIN GROUP HEADERS
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.tableHeadColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildHeaderCell('BODY', bodyWidth * 13, isMainGroup: true),
                _buildHeaderCell('CONNECTION', connWidth * 11, isMainGroup: true),
                _buildHeaderCell('ASSEMBLY', assemblyWidth, isMainGroup: true),
              ],
            ),
          ),
          
          /// SUB-COLUMN HEADERS
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                // Body sub-headers (13 columns)
                ..._buildBodySubHeaders(bodyWidth),
                // Connection sub-headers (11 columns)
                ..._buildConnectionSubHeaders(connWidth),
                // Assembly sub-header
                _buildSubHeaderCell('Adj Wt', assemblyWidth),
              ],
            ),
          ),
        ],
      )
    );
  }

  List<Widget> _buildBodySubHeaders(double width) {
    final headers = [
      'OD', 'ID', 'Nom Wt', 'Wall', 'Drift', 'Grade', 'Yield',
      'Fatigue', 'UTS', 'Collapse', 'Burst', 'Tensile', 'Torsional'
    ];
    
    return headers.map((header) => _buildSubHeaderCell(header, width)).toList();
  }

  List<Widget> _buildConnectionSubHeaders(double width) {
    final headers = [
      'Type', 'OD', 'ID', 'Grade', 'Yield', 'UTS', 'Burst',
      'Tensile', 'Comp', 'Torsional', 'Makeup'
    ];
    
    return headers.map((header) => _buildSubHeaderCell(header, width)).toList();
  }

  Widget _buildTableRows(
    List<Map<String, RxString>> rows,
    double bodyWidth,
    double connWidth,
    double assemblyWidth
  ) {
    return ListView.builder(
      itemCount: rows.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final row = rows[index];
        final isEven = index % 2 == 0;
        
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: isEven ? Colors.white : AppTheme.cardColor.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Body cells (13)
              ..._buildBodyCells(row, bodyWidth, isEven),
              // Connection cells (11)
              ..._buildConnectionCells(row, connWidth, isEven),
              // Assembly cell
              _buildDataCell(row['adjWt']!, assemblyWidth, isEven: isEven),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildBodyCells(Map<String, RxString> row, double width, bool isEven) {
    final keys = ['od', 'id', 'nomWt', 'wall', 'drift', 'grade', 'yield',
      'fatigue', 'uts', 'collapse', 'burst', 'tensile', 'torsional'];

    return keys.map((key) => _buildDataCell(row[key]!, width, isEven: isEven)).toList();
  }

  List<Widget> _buildConnectionCells(Map<String, RxString> row, double width, bool isEven) {
    final keys = ['cType', 'cOd', 'cId', 'cGrade', 'cYield', 'cUts', 'cBurst',
      'cTensile', 'cComp', 'cTorsion', 'makeup'];

    return keys.map((key) => _buildDataCell(row[key]!, width, isEven: isEven)).toList();
  }

  Widget _buildHeaderCell(String text, double width, {bool isMainGroup = false}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          fontSize: isMainGroup ? 13 : 12,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSubHeaderCell(String text, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Text(
        text,
        style: AppTheme.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDataCell(RxString value, double width, {bool isEven = true}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: TextField(
        controller: TextEditingController(text: value.value),
        onChanged: (v) => value.value = v,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }

  // ---------------- FOOTER ----------------
  Widget _buildFooter() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: _showSaveDialog,
            icon: Icon(Icons.save, size: 18),
            label: Text('Save'),
            style: AppTheme.primaryButtonStyle,
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: Icon(Icons.close, size: 18),
            label: Text('Close'),
            style: AppTheme.secondaryButtonStyle,
          ),
        ],
      ),
    );
  }

  // ---------------- DIALOGS ----------------
  void _showAddTypeDialog() {
    final typeController = TextEditingController();
    final materialController = TextEditingController();
    String selectedMaterial = 'Steel';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 400,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add, color: AppTheme.primaryColor, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Add New Pipe Type',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Pipe Type Input
              Text(
                'Pipe Type',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: TextField(
                  controller: typeController,
                  decoration: InputDecoration(
                    hintText: 'Enter pipe type name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: AppTheme.bodyLarge,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Material Dropdown
              Text(
                'Material',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButton<String>(
                    value: selectedMaterial,
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                    items: ['Steel', 'Aluminium', 'Stainless Steel', 'Carbon Steel']
                        .map((material) => DropdownMenuItem(
                              value: material,
                              child: Text(
                                material,
                                style: AppTheme.bodyLarge,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedMaterial = value;
                      }
                    },
                  ),
                ),
              ),
              
              SizedBox(height: 30),
              
              // Dialog Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (typeController.text.isNotEmpty) {
                        c.addType(typeController.text);
                        Get.back();
                        _showSuccessDialog('Type added successfully!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Add Type'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCatalogDialog() {
    final controller = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 350,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add, color: AppTheme.primaryColor, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Add New Catalog',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              Text(
                'Catalog Name',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter catalog name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: AppTheme.bodyLarge,
                ),
              ),
              
              SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        c.addCatalog(controller.text);
                        Get.back();
                        _showSuccessDialog('Catalog added successfully!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Add Catalog'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(String title, String message, VoidCallback onConfirm, bool isSelected) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                message,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Get.back();
                      _showSuccessDialog('Deleted successfully!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.save_rounded,
                color: AppTheme.successColor,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Save Changes',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Are you sure you want to save all changes?',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _showSuccessDialog('Saved successfully!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successColor,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Success!',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                message,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}