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
  final isLocked = false.obs;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    try {
      final store = Get.find<InventoryServicesStore>();
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
                const SizedBox(height: 4),
                Expanded(child: _packagesTable(store)),
                const SizedBox(height: 8),
                const SizedBox(height: 4),
                Expanded(child: _engineeringTable(store)),
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
                Expanded(child: _servicesTable(store)),
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
          _tableHeader('Packages', Icons.inventory, store.selectedPackages.length),
          Expanded(
            child: _table(
              // ✅ FIX: 'Initial' col added (index 5), Tax moves to index 6
              headers: ['No', 'Package', 'Code', 'Unit', 'Price (\$)', 'Initial', 'Tax'],
              rows: store.selectedPackages.asMap().entries.map((entry) => [
                (entry.key + 1).toString(),
                entry.value.name,
                entry.value.code,
                entry.value.unit,
                entry.value.price.toString(),
                entry.value.initial, // ✅ initial value
                entry.value.tax,
              ]).toList(),
              checkboxCols: [6],
              onChanged: (rowIndex, colIndex, value) {
                if (colIndex == 5) {
                  // ✅ initial field update
                  store.selectedPackages[rowIndex].initial = value.toString();
                } else if (colIndex == 6) {
                  store.selectedPackages[rowIndex].tax = value as bool;
                }
                store.selectedPackages.refresh();
              },
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
          _tableHeader('Engineering', Icons.engineering, store.selectedEngineering.length),
          Expanded(
            child: _table(
              headers: ['No', 'Engineering', 'Code', 'Unit', 'Price (\$)', 'Tax'],
              rows: store.selectedEngineering.asMap().entries.map((entry) => [
                (entry.key + 1).toString(),
                entry.value.name,
                entry.value.code,
                entry.value.unit,
                entry.value.price.toString(),
                entry.value.tax,
              ]).toList(),
              checkboxCols: [5],
              onChanged: (rowIndex, colIndex, value) {
                if (colIndex == 5) {
                  store.selectedEngineering[rowIndex].tax = value as bool;
                  store.selectedEngineering.refresh();
                }
              },
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
          _tableHeader('Services', Icons.miscellaneous_services, store.selectedServices.length),
          Expanded(
            child: _table(
              headers: ['No', 'Services', 'Code', 'Unit', 'Price (\$)', 'Tax'],
              rows: store.selectedServices.asMap().entries.map((entry) => [
                (entry.key + 1).toString(),
                entry.value.name,
                entry.value.code,
                entry.value.unit,
                entry.value.price.toString(),
                entry.value.tax,
              ]).toList(),
              checkboxCols: [5],
              onChanged: (rowIndex, colIndex, value) {
                if (colIndex == 5) {
                  store.selectedServices[rowIndex].tax = value as bool;
                  store.selectedServices.refresh();
                }
              },
            ),
          ),
        ],
      ),
    ));
  }

  // ===================================================
  // ================= COMMON HEADER ===================
  // ===================================================

  Widget _tableHeader(String title, IconData icon, int count) {
    return Container(
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
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
          )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('$count items', style: const TextStyle(
              fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600,
            )),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // ================= COMMON TABLE ====================
  // ===================================================

  Widget _table({
    required List<String> headers,
    required List<List<dynamic>> rows,
    List<int> checkboxCols = const [],
    void Function(int rowIndex, int colIndex, dynamic value)? onChanged,
  }) {
    // ✅ FIX: Package table has 7 cols (with Initial), others have 6
    final Map<int, TableColumnWidth> columnWidths = headers.length == 7
        ? const {
            0: FixedColumnWidth(35),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),   // Initial col
            6: FixedColumnWidth(55), // Tax
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
          // ✅ FIX: no TableBorder — extra cell borders remove
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: columnWidths,
          children: [
            _headerRow(headers),
            ...rows.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final row = entry.value;
              return TableRow(
                decoration: BoxDecoration(
                  color: rowIndex.isEven ? Colors.white : AppTheme.cardColor,
                ),
                children: List.generate(row.length, (i) {
                  if (checkboxCols.contains(i)) {
                    return _checkboxCell(row[i],
                        onChanged: (v) => onChanged?.call(rowIndex, i, v));
                  }
                  return _editableCell(
                    row[i].toString(),
                    // ✅ Stable key: rowIndex + colIndex so it doesn't reset on refresh
                    cellKey: 'r${rowIndex}_c$i',
                    onChanged: (v) => onChanged?.call(rowIndex, i, v),
                  );
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

  TableRow _headerRow(List<String> headers) {
    return TableRow(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      children: headers.map((h) => Container(
        height: 28,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(h, style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
      )).toList(),
    );
  }

  Widget _editableCell(String value, {Function(String)? onChanged, String? cellKey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Obx(() => isLocked.value
          ? Text(value, style: TextStyle(fontSize: 8.5, color: AppTheme.textPrimary))
          // ✅ FIX: no border Container — just TextFormField directly
          : TextFormField(
              key: ValueKey(cellKey ?? value),
              initialValue: value,
              onChanged: onChanged,
              style: TextStyle(fontSize: 8.5, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                border: InputBorder.none,        // ✅ no border
                enabledBorder: InputBorder.none, // ✅ no border
                focusedBorder: InputBorder.none, // ✅ no border
              ),
            )),
    );
  }

  Widget _checkboxCell(bool value, {Function(bool)? onChanged}) {
    return Center(
      child: Obx(() => Transform.scale(
        scale: 0.75,
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