import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/tabular_database_editor.dart';
import '../controller/tabular_database_controller.dart';
import '../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class TabularDatabaseView extends StatelessWidget {
  TabularDatabaseView({super.key});
  final c = Get.put(TabularDatabaseController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Tubular Database',
          style: AppTheme.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryGradient.colors.first,
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

      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive calculations
          final screenWidth = constraints.maxWidth;
          final isLargeScreen = screenWidth >= 1600;
          final isMediumScreen = screenWidth >= 1200 && screenWidth < 1600;
          final isSmallScreen = screenWidth < 1200;
          
          final leftPanelWidth = isLargeScreen
              ? 950.0
              : isMediumScreen
                  ? 820.0
                  : screenWidth * 0.55;
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// LEFT TABLES PANEL
                _buildLeftPanel(leftPanelWidth),
                
                /// SPACER
                SizedBox(width: isSmallScreen ? 12 : 16),
                
                /// RIGHT MAIN TABLE PANEL
                Expanded(child: _buildRightPanel()),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: _buildFooter(),
    );
  }

  // ---------------- LEFT PANEL ----------------
  Widget _buildLeftPanel(double width) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// TYPE TABLE (SELECTABLE)
          _buildCategoryTable('Type', c.types, selectable: true),
          
          SizedBox(width: 8),
          
          /// CATALOG TABLE (CLICKABLE)
          _buildCategoryTable('Catalog', c.catalogs, clickable: true),
          
          SizedBox(width: 8),
          
          /// OD TABLE (CLICKABLE)
          _buildCategoryTable('OD (in)', c.ods, clickable: true),
          
          SizedBox(width: 8),
          
          /// WEIGHT TABLE (CLICKABLE)
          _buildCategoryTable('Weight', c.weights, clickable: true),
          
          SizedBox(width: 8),
          
          /// GRADE TABLE (CLICKABLE)
          _buildCategoryTable('Grade', c.grades, clickable: true),
        ],
      ),
    );
  }

  Widget _buildCategoryTable(String title, List<String> items, 
      {bool selectable = false, bool clickable = false}) {
    return Expanded(
      child: Container(
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
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  Icon(
                    selectable ? Icons.radio_button_checked : Icons.list,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      items.length.toString(),
                      style: AppTheme.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            /// TABLE BODY (SCROLLABLE)
            Expanded(
              child: Container(
                color: Colors.white,
                child: _buildTableList(items, selectable: selectable, clickable: clickable),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableList(List<String> items, {bool selectable = false, bool clickable = false}) {
    return ListView.builder(
      itemCount: items.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final item = items[index];
        final canClick = selectable || clickable;
        final selectedIndex = c.selectedTypeIndex.value;
        final isSelected = selectable && selectedIndex == index;

        return InkWell(
          onTap: canClick ? () {
            if (selectable) {
              c.selectedTypeIndex.value = index;
            } else if (clickable) {
              print('Clicked on $item');
            }
          } : null,
          hoverColor: AppTheme.primaryColor.withOpacity(0.05),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.15)
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
                if (selectable) ...[
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
                ],
                Expanded(
                  child: Text(
                    item,
                    style: AppTheme.bodySmall.copyWith(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (clickable ? AppTheme.primaryColor.withOpacity(0.8) : AppTheme.textPrimary),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : (clickable ? FontWeight.w500 : FontWeight.w400),
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
    );
  }

  // ---------------- RIGHT PANEL ----------------
  Widget _buildRightPanel() {
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
          /// RIGHT PANEL HEADER
          Container(
            height: 48,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() {
              final selectedType = c.types[c.selectedTypeIndex.value];
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
                      '${c.currentTable.length} rows',
                      style: AppTheme.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              );
            }),
          ),
          
          /// MAIN TABLE
          Expanded(
            child: Obx(() {
              final rows = c.currentTable;
              return _buildMainTable(rows);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTable(List<Map<String, RxString>> rows) {
    // Calculate exact table width based on columns
    const double col1Width = 60;  // #
    const double col2Width = 90;  // Body ID
    const double col3Width = 90;  // Yield
    const double col4Width = 90;  // Conn Type
    const double col5Width = 90;  // Conn OD
    const double col6Width = 90;  // Conn ID
    const double col7Width = 140; // Adjust Wt
    
    const double totalTableWidth = col1Width + col2Width + col3Width + 
                                   col4Width + col5Width + col6Width + col7Width;
    
    return Container(
      margin: EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final needsHorizontalScroll = totalTableWidth > constraints.maxWidth;
          
          return Column(
            children: [
              /// COLUMN HEADERS (FIXED)
              if (needsHorizontalScroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalTableWidth,
                    child: _buildMainTableHeader(
                      col1Width, col2Width, col3Width, col4Width, 
                      col5Width, col6Width, col7Width
                    ),
                  ),
                )
              else
                _buildMainTableHeader(
                  col1Width, col2Width, col3Width, col4Width, 
                  col5Width, col6Width, col7Width
                ),
              
              /// DATA ROWS (SCROLLABLE)
              Expanded(
                child: needsHorizontalScroll
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: totalTableWidth,
                          child: _buildTableRows(
                            rows, col1Width, col2Width, col3Width, 
                            col4Width, col5Width, col6Width, col7Width
                          ),
                        ),
                      )
                    : _buildTableRows(
                        rows, col1Width, col2Width, col3Width, 
                        col4Width, col5Width, col6Width, col7Width
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableRows(
    List<Map<String, RxString>> rows,
    double col1Width, double col2Width, double col3Width,
    double col4Width, double col5Width, double col6Width, double col7Width
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
              _buildDataCell('${index + 1}', col1Width, isEven: isEven, isEditable: false),
              _buildDataCell(row['bodyId']!, col2Width, isEven: isEven),
              _buildDataCell(row['yield']!, col3Width, isEven: isEven),
              _buildDataCell(row['connType']!, col4Width, isEven: isEven),
              _buildDataCell(row['connOd']!, col5Width, isEven: isEven),
              _buildDataCell(row['connId']!, col6Width, isEven: isEven),
              _buildDataCell(row['adjWt']!, col7Width, isEven: isEven),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainTableHeader(
    double col1Width, double col2Width, double col3Width,
    double col4Width, double col5Width, double col6Width, double col7Width
  ) {
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
                _buildHeaderCell('#', col1Width, isMainGroup: true),
                _buildHeaderCell('BODY', col2Width + col3Width, isMainGroup: true),
                _buildHeaderCell('CONNECTION', col4Width + col5Width + col6Width, isMainGroup: true),
                _buildHeaderCell('ASSEMBLY', col7Width, isMainGroup: true),
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
                _buildSubHeaderCell('', col1Width),
                _buildSubHeaderCell('ID (in)', col2Width),
                _buildSubHeaderCell('Yield (psi)', col3Width),
                _buildSubHeaderCell('Type', col4Width),
                _buildSubHeaderCell('OD (in)', col5Width),
                _buildSubHeaderCell('ID (in)', col6Width),
                _buildSubHeaderCell('Adjust Wt (lb/ft)', col7Width),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, {bool isMainGroup = false}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
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

  Widget _buildDataCell(dynamic text, double width, {bool isEven = true, bool isEditable = true}) {
    final dashboardController = Get.find<DashboardController>();

    return Container(
      width: width,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: isEditable ? Obx(() {
        final isLocked = dashboardController.isLocked.value;
        final rxText = text as RxString;
        return isLocked
            ? Text(
                rxText.value,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                  color: Colors.white,
                ),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: TextFormField(
                  initialValue: rxText.value,
                  onChanged: (value) => rxText.value = value,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              );
      }) : Text(
        text.toString(),
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          /// EDITOR BUTTON
          ElevatedButton.icon(
            onPressed: () => Get.to(() => TabularDatabaseEditorView()),
            icon: Icon(Icons.edit, size: 18),
            label: Text('Editor'),
            style: AppTheme.secondaryButtonStyle.copyWith(
              backgroundColor: MaterialStatePropertyAll(AppTheme.secondaryColor),
              foregroundColor: MaterialStatePropertyAll(Colors.white),
            ),
          ),
          
          Spacer(),
          
          /// ACTION BUTTONS
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showConfirmDialog,
                icon: Icon(Icons.check_circle_outline, size: 18),
                label: Text('Accept'),
                style: AppTheme.primaryButtonStyle,
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: Icon(Icons.cancel_outlined, size: 18),
                label: Text('Cancel'),
                style: AppTheme.secondaryButtonStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog() {
    Get.defaultDialog(
      title: 'Confirm Selection',
      titlePadding: EdgeInsets.only(top: 20, bottom: 8),
      titleStyle: AppTheme.titleMedium.copyWith(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w600,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warningColor,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Do you want to replace the current\ncontents in the table?',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      backgroundColor: Colors.white,
      radius: 12,
      actions: [
        ElevatedButton(
          onPressed: () => Get.back(),
          style: AppTheme.secondaryButtonStyle,
          child: Text('No'),
        ),
        SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            Get.back();
            // Add your accept logic here
          },
          style: AppTheme.primaryButtonStyle,
          child: Text('Yes'),
        ),
      ],
    );
  }
}