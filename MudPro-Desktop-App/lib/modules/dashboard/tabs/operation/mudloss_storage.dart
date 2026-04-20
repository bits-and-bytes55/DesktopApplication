import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_loss_storage_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudLossStorageView extends StatefulWidget {
  const MudLossStorageView({super.key});

  @override
  State<MudLossStorageView> createState() => _MudLossStorageViewState();
}

class _MudLossStorageViewState extends State<MudLossStorageView> {
  final DashboardController dashboardController =
      Get.find<DashboardController>();
  final PitController pitController = Get.find<PitController>();
  final MudLossStorageController controller = Get.put(
    MudLossStorageController(),
  );

  int selectedRowIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await pitController.fetchUnselectedPits();
      await controller.load(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mud Loss - Storage',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (controller.isLoading.value) {
              return Container(
                width: 690,
                height: 688,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            }

            return SizedBox(
              width: 690,
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.shade400,
                  width: 1,
                ),
                columnWidths: const {
                  0: FixedColumnWidth(24),
                  1: FixedColumnWidth(36),
                  2: FixedColumnWidth(226),
                  3: FixedColumnWidth(150),
                  4: FixedColumnWidth(113),
                  5: FixedColumnWidth(113),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _headerRow(),
                  ...List.generate(controller.rows.length, (index) {
                    return _dataRow(index, controller.rows[index]);
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: [
        _headerCell(''),
        _headerCell(''),
        _headerCell('Storage'),
        _headerCell('Dump\n(bbl)'),
        _headerCell('Evaporation\n(bbl)'),
        _headerCell('Pit Cleaning\n(bbl)'),
      ],
    );
  }

  TableRow _dataRow(int index, MudLossStorageEntry row) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        _selectorCell(index),
        _numberCell(index),
        _storageCell(row),
        _inputCell(row.dumpController, row.dump),
        _inputCell(row.evaporationController, row.evaporation),
        _inputCell(row.pitCleaningController, row.pitCleaning),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _selectorCell(int index) {
    return InkWell(
      onTap: () => setState(() => selectedRowIndex = index),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        child: selectedRowIndex == index
            ? Icon(Icons.arrow_right, size: 17, color: Colors.grey.shade700)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _numberCell(int index) {
    return InkWell(
      onTap: () => setState(() => selectedRowIndex = index),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        child: Text(
          '${index + 1}',
          style: AppTheme.bodySmall.copyWith(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _storageCell(MudLossStorageEntry row) {
    return Obx(() {
      final names = pitController.unselectedPits
          .map((pit) => pit.pitName.trim())
          .where((name) => name.isNotEmpty)
          .toList();
      final current = row.storage.value.trim();
      if (current.isNotEmpty && !names.contains(current)) {
        names.insert(0, current);
      }
      final selectedValue = current.isEmpty || !names.contains(current)
          ? null
          : current;

      return SizedBox(
        height: 32,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            isDense: true,
            hint: const SizedBox.shrink(),
            icon: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: dashboardController.isLocked.value
                    ? Colors.grey.shade400
                    : Colors.grey.shade700,
              ),
            ),
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 220,
            items: names.map((pitName) {
              return DropdownMenuItem<String>(
                value: pitName,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    pitName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(fontSize: 11),
                  ),
                ),
              );
            }).toList(),
            onChanged: dashboardController.isLocked.value
                ? null
                : (value) {
                    if (value == null) return;
                    row.storage.value = value;
                    controller.ensureTrailingRow();
                  },
          ),
        ),
      );
    });
  }

  Widget _inputCell(TextEditingController textController, RxString value) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: textController,
        enabled: !dashboardController.isLocked.value,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          filled: true,
          fillColor: dashboardController.isLocked.value
              ? Colors.grey.shade100
              : Colors.white,
        ),
        onTap: () {
          final index = controller.rows.indexWhere(
            (row) =>
                row.dumpController == textController ||
                row.evaporationController == textController ||
                row.pitCleaningController == textController,
          );
          if (index >= 0) {
            setState(() => selectedRowIndex = index);
          }
        },
        onChanged: (text) {
          value.value = text;
          controller.ensureTrailingRow();
        },
      ),
    );
  }
}
