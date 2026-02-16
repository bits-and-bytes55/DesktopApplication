import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/producst_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryServicesView extends StatelessWidget {
  InventoryServicesView({super.key});
  final c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ================= LEFT COLUMN =================
          Expanded(
            flex: 2,
            child: Column(
              children: [

                // -------- PACKAGES --------
               
                const SizedBox(height: 4),
                Expanded(
                  child: _packagesTable(),
                ),

                const SizedBox(height: 8),

                // -------- ENGINEERING --------
                
                const SizedBox(height: 4),
                Expanded(
                  child: _engineeringTable(),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ================= RIGHT COLUMN =================
          Expanded(
            flex: 2,
            child: Column(
              children: [
               
                const SizedBox(height: 4),
                Expanded(
                  child: _servicesTable(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // ================= TABLES ==========================
  // ===================================================

 Widget _packagesTable() {
  final rows = c.packages.map((p) => [
        p.id,
        p.package,
        p.code,
        p.unit,
        p.price,
        p.initial,
        p.tax,
      ]).toList();

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      children: [
        // Table Header
        Container(
          height: 32,
          decoration: BoxDecoration(
            gradient: AppTheme.headerGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.inventory, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Packages',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${rows.length} items',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
                6: FixedColumnWidth(60),
              },
              children: [
                _headerRow(['#', 'Package', 'Code', 'Unit', 'Price (\$)', 'Initial', 'Tax']),

                // DATA ROWS OR EMPTY SPACE
                if (rows.isNotEmpty)
                  ...rows.map((row) => _tableRow(row, onChangedList: [
                    null,
                    (v) => row[1] = v,
                    (v) => row[2] = v,
                    (v) => row[3] = v,
                    (v) => row[4] = v,
                    (v) => row[5] = v,
                  ], onCheckboxChangedList: [
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    (v) => row[6] = v,
                  ]))
                else
                  ..._emptyRows(7, 8), // 👈 empty rows
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _engineeringTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.engineering, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Engineering',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${c.engineering.length} items',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _table(
              headers: ['#', 'Engineering', 'Code', 'Unit', 'Price (\$)', 'Tax'],
              rows: c.engineering.map((e) => [
                e.id,
                e.name,
                e.code,
                e.unit,
                e.price,
                e.tax,
              ]).toList(),
              models: c.engineering,
              checkboxCols: [5],
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.miscellaneous_services, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${c.services.length} items',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _table(
              headers: ['#', 'Services', 'Code', 'Unit', 'Price (\$)', 'Tax'],
              rows: c.services.map((s) => [
                s.id,
                s.service,
                s.code,
                s.unit,
                s.price,
                s.tax,
              ]).toList(),
              models: c.services,
              checkboxCols: [5],
            ),
          ),
        ],
      ),
    );
  }

TableRow _headerRow(List<String> headers) {
  return TableRow(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.05)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    children: headers.map((h) {
      return Container(
        height: 32,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          h,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      );
    }).toList(),
  );
}



TableRow _tableRow(List<dynamic> values, {List<Function(String)?>? onChangedList, List<Function(bool)?>? onCheckboxChangedList}) {
  return TableRow(
    decoration: BoxDecoration(
      color: values.hashCode.isEven ? Colors.white : AppTheme.cardColor,
    ),
    children: List.generate(values.length, (i) {
      if (values[i] is bool) {
        return _checkboxCell(values[i], onChanged: onCheckboxChangedList?[i]);
      }
      return _editableCell(values[i].toString(), onChanged: onChangedList?[i]);
    }),
  );
}




  List<TableRow> _emptyRows(int columns, int count) {
  return List.generate(
    count,
    (index) => TableRow(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : AppTheme.cardColor,
      ),
      children: List.generate(
        columns,
        (colIndex) => Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: colIndex == 0 
            ? Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              )
            : null,
        ),
      ),
    ),
  );
}


  // ===================================================
  // ================= COMMON TABLE ====================
  // ===================================================

  Widget _table({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required List<dynamic> models,
    List<int> checkboxCols = const [],
  }) {
    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
          5: FixedColumnWidth(60),
        },
        children: [
          // HEADER
          _headerRow(headers),

          // ROWS
          ...rows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final row = entry.value;
            final model = models[rowIndex];
            return TableRow(
              decoration: BoxDecoration(
                color: rowIndex.isEven ? Colors.white : AppTheme.cardColor,
              ),
              children: List.generate(row.length, (i) {
                if (checkboxCols.contains(i)) {
                  return _checkboxCell(row[i], onChanged: (v) {
                    if (model is EngineeringModel) {
                      model.tax = v;
                      c.engineering.refresh();
                    } else if (model is ServiceModel) {
                      model.tax = v;
                      c.services.refresh();
                    } else if (model is PackageModel) {
                      model.tax = v;
                      c.packages.refresh();
                    }
                  });
                }
                return _editableCell(row[i].toString(), onChanged: (v) {
                  if (model is EngineeringModel) {
                    if (i == 1) model.name = v;
                    if (i == 2) model.code = v;
                    if (i == 3) model.unit = v;
                    if (i == 4) model.price = v;
                    c.engineering.refresh();
                  } else if (model is ServiceModel) {
                    if (i == 1) model.service = v;
                    if (i == 2) model.code = v;
                    if (i == 3) model.unit = v;
                    if (i == 4) model.price = v;
                    c.services.refresh();
                  } else if (model is PackageModel) {
                    if (i == 1) model.package = v;
                    if (i == 2) model.code = v;
                    if (i == 3) model.unit = v;
                    if (i == 4) model.price = v;
                    if (i == 5) model.initial = v;
                    c.packages.refresh();
                  }
                });
              }),
            );
          }),
        ],
      ),
    );
  }

  // ===================================================
  // ================= CELLS ===========================
  // ===================================================

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _editableCell(String value, {Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Obx(() => c.isLocked.value
          ? Text(
              value,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textPrimary,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextFormField(
                initialValue: value,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  border: InputBorder.none,
                ),
              ),
            )),
    );
  }

  Widget _checkboxCell(bool value, {Function(bool)? onChanged}) {
    return Center(
      child: Obx(() => Container(
            decoration: BoxDecoration(
              color: value ? AppTheme.successColor.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? AppTheme.successColor : Colors.grey.shade400,
              ),
            ),
            margin: const EdgeInsets.all(4),
            child: Checkbox(
              value: value,
              onChanged: c.isLocked.value ? null : (v) => onChanged?.call(v!),
              activeColor: AppTheme.successColor,
              checkColor: Colors.white,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      height: 28,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}