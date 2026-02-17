import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import '../../controller/operation_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudLossStorageView extends StatefulWidget {
  const MudLossStorageView({super.key});

  @override
  State<MudLossStorageView> createState() => _MudLossStorageViewState();
}

class _MudLossStorageViewState extends State<MudLossStorageView> {
  final OperationController controller = Get.find<OperationController>();
  final DashboardController dashboardController = Get.find<DashboardController>();
  final PitController pitController = Get.find<PitController>();

  // Dynamic rows - starts with 6 empty rows
  final RxList<MudLossStorageRow> rows = <MudLossStorageRow>[
    MudLossStorageRow(),
    MudLossStorageRow(),
    MudLossStorageRow(),
    MudLossStorageRow(),
    MudLossStorageRow(),
    MudLossStorageRow(),
  ].obs;

  @override
  void initState() {
    super.initState();
    // Fetch unselected pits for dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pitController.fetchUnselectedPits();
    });
  }

  @override
  void dispose() {
    // Clean up controllers
    for (var row in rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _checkAndAddNewRow(int index) {
    final row = rows[index];
    // Check if this is the last row and all fields are filled
    if (index == rows.length - 1 &&
        row.storage.value.isNotEmpty &&
        row.dump.value.isNotEmpty &&
        row.evaporation.value.isNotEmpty &&
        row.pitCleaning.value.isNotEmpty) {
      // Add new empty row
      rows.add(MudLossStorageRow());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Text(
            "Mud Loss - Storage",
            style: AppTheme.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // ================= COMPRESSED TABLE WITH FIXED HEIGHT =================
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 576, // Compressed width for 5 columns (40+158+126+126+126)
              height: 320, // Fixed height for scrollable table
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ================= TABLE HEADER (FIXED) =================
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.95),
                          AppTheme.primaryColor,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        // # Column Header
                        Flexible(flex: 40, child: _buildHeaderCell("#", 40, isFirst: true)),
                        // Storage Header
                        Flexible(flex: 158, child: _buildHeaderCell("Storage", 158)),
                        // Dump (bbl) Header
                        Flexible(flex: 126, child: _buildHeaderCell("Dump\n(bbl)", 126)),
                        // Evaporation (bbl) Header
                        Flexible(flex: 126, child: _buildHeaderCell("Evaporation\n(bbl)", 126)),
                        // Pit Cleaning (bbl) Header
                        Flexible(flex: 126, child: _buildHeaderCell("Pit Cleaning\n(bbl)", 126, isLast: true)),
                      ],
                    ),
                  ),

                  // ================= SCROLLABLE TABLE BODY =================
                  Expanded(
                    child: Obx(() => ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return _buildDataRow(index, row);
                          },
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width,
      {bool isFirst = false, bool isLast = false}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border(
            right: isLast
                ? BorderSide.none
                : BorderSide(
                    color: Colors.white.withOpacity(0.3),
                  ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(int index, MudLossStorageRow row) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // # Column
          Flexible(flex: 40, child: _buildNumberCell(index)),
          // Storage Dropdown Column
          Flexible(flex: 158, child: _buildStorageDropdownCell(index, row)),
          // Dump Input Column
          Flexible(flex: 126, child: _buildInputCell(index, row, 'dump', 126)),
          // Evaporation Input Column
          Flexible(flex: 126, child: _buildInputCell(index, row, 'evaporation', 126)),
          // Pit Cleaning Input Column
          Flexible(flex: 126, child: _buildInputCell(index, row, 'pitCleaning', 126, isLast: true)),
        ],
      ),
    );
  }

  Widget _buildNumberCell(int index) {
    return SizedBox(
      width: 40,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: Text(
            "${index + 1}",
            style: AppTheme.bodySmall.copyWith(
              fontSize: 10,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorageDropdownCell(int index, MudLossStorageRow row) {
    return Obx(() {
      final unselectedPits = pitController.unselectedPits;
      final isLocked = dashboardController.isLocked.value;

      return SizedBox(
        width: 158,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: row.storage.value.isEmpty ? null : row.storage.value,
              hint: Text(
                "",
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: isLocked ? Colors.grey.shade400 : AppTheme.primaryColor,
                size: 18,
              ),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              isDense: true,
              menuMaxHeight: 200, // Fixed height for dropdown menu
              items: unselectedPits.map((pit) {
                return DropdownMenuItem<String>(
                  value: pit.pitName,
                  child: Text(
                    pit.pitName,
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: isLocked
                  ? null
                  : (value) {
                      if (value != null) {
                        row.storage.value = value;
                        _checkAndAddNewRow(index);
                      }
                    },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildInputCell(
      int index, MudLossStorageRow row, String field, double width,
      {bool isLast = false}) {
    TextEditingController controller;
    RxString rxValue;

    switch (field) {
      case 'dump':
        controller = row.dumpController;
        rxValue = row.dump;
        break;
      case 'evaporation':
        controller = row.evaporationController;
        rxValue = row.evaporation;
        break;
      case 'pitCleaning':
        controller = row.pitCleaningController;
        rxValue = row.pitCleaning;
        break;
      default:
        controller = TextEditingController();
        rxValue = "".obs;
    }

    return Obx(() {
      final isLocked = dashboardController.isLocked.value;

      return SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              right: isLast
                  ? BorderSide.none
                  : BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: !isLocked,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: "",
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: AppTheme.bodySmall.copyWith(
              fontSize: 10,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              rxValue.value = value;
              _checkAndAddNewRow(index);
            },
          ),
        ),
      );
    });
  }
}

// ================= ROW DATA MODEL =================
class MudLossStorageRow {
  final RxString storage = "".obs;
  final RxString dump = "".obs;
  final RxString evaporation = "".obs;
  final RxString pitCleaning = "".obs;

  final TextEditingController dumpController = TextEditingController();
  final TextEditingController evaporationController = TextEditingController();
  final TextEditingController pitCleaningController = TextEditingController();

  MudLossStorageRow();

  void dispose() {
    dumpController.dispose();
    evaporationController.dispose();
    pitCleaningController.dispose();
  }
}