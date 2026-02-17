import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/model/producst_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryServicesView extends StatefulWidget {
  const InventoryServicesView({super.key});

  @override
  State<InventoryServicesView> createState() => _InventoryServicesViewState();
}

class _InventoryServicesViewState extends State<InventoryServicesView> {
  final isLocked = true.obs;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto refresh when page is entered - using addPostFrameCallback for instant update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    try {
      final store = Get.find<InventoryServicesStore>();
      // Refresh the observable lists to trigger UI update
      store.selectedPackages.refresh();
      store.selectedServices.refresh();
      store.selectedEngineering.refresh();
      print('✅ Data refreshed on page enter');
    } catch (e) {
      print('❌ Error refreshing data: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<InventoryServicesStore>();

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
                  child: _packagesTable(store),
                ),

                const SizedBox(height: 8),

                // -------- ENGINEERING --------
                const SizedBox(height: 4),
                Expanded(
                  child: _engineeringTable(store),
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
                  child: _servicesTable(store),
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

  Widget _packagesTable(InventoryServicesStore store) {
    return Obx(() => Container(
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
                    '${store.selectedPackages.length} items',
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
              headers: ['No', 'Package', 'Code', 'Unit', 'Price (\$)', 'Initial', 'Tax'],
              rows: store.selectedPackages.asMap().entries.map((entry) => [
                (entry.key + 1).toString(),
                entry.value.name,
                entry.value.code,
                entry.value.unit,
                entry.value.price.toString(),
                '', // initial
                false, // tax
              ]).toList(),
              checkboxCols: [6],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _engineeringTable(InventoryServicesStore store) {
    return Obx(() => Container(
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
                    '${store.selectedEngineering.length} items',
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
              headers: ['No', 'Engineering', 'Code', 'Unit', 'Price (\$)', 'Tax'],
              rows: store.selectedEngineering.asMap().entries.map((entry) => [
                (entry.key + 1).toString(),
                entry.value.name,
                entry.value.code,
                entry.value.unit,
                entry.value.price.toString(),
                false, // tax
              ]).toList(),
              checkboxCols: [5],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _servicesTable(InventoryServicesStore store) {
    return Obx(() => Container(
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
                    '${store.selectedServices.length} items',
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
              headers: ['No', 'Services', 'Code', 'Unit', 'Price (\$)', 'Tax'],
              rows: store.selectedServices.asMap().entries.map((entry) => [
                (entry.key + 1).toString(),
                entry.value.name,
                entry.value.code,
                entry.value.unit,
                entry.value.price.toString(),
                false, // tax
              ]).toList(),
              checkboxCols: [5],
            ),
          ),
        ],
      ),
    ));
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
          height: 28, // Reduced from 32
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            h,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===================================================
  // ================= COMMON TABLE ====================
  // ===================================================

  Widget _table({
    required List<String> headers,
    required List<List<dynamic>> rows,
    List<int> checkboxCols = const [],
  }) {
    final columnWidths = headers.length == 7
        ? const {
            0: FixedColumnWidth(35),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FixedColumnWidth(55),
          }
        : const {
            0: FixedColumnWidth(35),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FixedColumnWidth(55),
          };

    return Scrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Table(
          border: TableBorder.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: columnWidths,
          children: [
            // HEADER
            _headerRow(headers),

            // ROWS
            ...rows.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final row = entry.value;
              return TableRow(
                decoration: BoxDecoration(
                  color: rowIndex.isEven ? Colors.white : AppTheme.cardColor,
                ),
                children: List.generate(row.length, (i) {
                  if (checkboxCols.contains(i)) {
                    return _checkboxCell(row[i]);
                  }
                  return _editableCell(row[i].toString());
                }),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // ================= CELLS ===========================
  // ===================================================

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9, // Reduced font size
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _editableCell(String value, {Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced padding
      child: Obx(() => isLocked.value
          ? Text(
              value,
              style: TextStyle(
                fontSize: 8.5, // Reduced font size
                color: AppTheme.textPrimary,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextFormField(
                initialValue: value,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: 8.5, // Reduced font size
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced padding
                  border: InputBorder.none,
                ),
              ),
            )),
    );
  }

  Widget _checkboxCell(bool value, {Function(bool)? onChanged}) {
    return Center(
      child: Obx(() => Transform.scale(
        scale: 0.75, // Reduced checkbox size
        child: Checkbox(
          value: value,
          onChanged: isLocked.value ? null : (v) => onChanged?.call(v!),
          activeColor: AppTheme.successColor,
          checkColor: Colors.white,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      )),
    );
  }
}

