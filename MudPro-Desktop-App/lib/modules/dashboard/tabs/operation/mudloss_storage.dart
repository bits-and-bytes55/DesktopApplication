import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_loss_storage_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mud Loss - Storage",
            style: AppTheme.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 576,
              height: 320,
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
                        Flexible(flex: 40, child: _buildHeaderCell("#", 40)),
                        Flexible(
                          flex: 158,
                          child: _buildHeaderCell("Storage", 158),
                        ),
                        Flexible(
                          flex: 126,
                          child: _buildHeaderCell("Dump\n(bbl)", 126),
                        ),
                        Flexible(
                          flex: 126,
                          child: _buildHeaderCell("Evaporation\n(bbl)", 126),
                        ),
                        Flexible(
                          flex: 126,
                          child: _buildHeaderCell(
                            "Pit Cleaning\n(bbl)",
                            126,
                            isLast: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => controller.isLoading.value
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                                strokeWidth: 2,
                              ),
                            )
                          : ListView.builder(
                              itemCount: controller.rows.length,
                              itemBuilder: (context, index) {
                                final row = controller.rows[index];
                                return _buildDataRow(index, row);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width, {bool isLast = false}) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border(
            right: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        child: Center(
          child: Obx(
            () => Text(
              AppUnits.label(title),
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
      ),
    );
  }

  Widget _buildDataRow(int index, MudLossStorageEntry row) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Flexible(flex: 40, child: _buildNumberCell(index)),
          Flexible(flex: 158, child: _buildStorageCell(row)),
          Flexible(flex: 126, child: _buildInputCell(row, 'dump')),
          Flexible(flex: 126, child: _buildInputCell(row, 'evaporation')),
          Flexible(
            flex: 126,
            child: _buildInputCell(row, 'pitCleaning', isLast: true),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberCell(int index) {
    return SizedBox(
      width: 40,
      child: Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
        ),
        alignment: Alignment.center,
        child: Text(
          "${index + 1}",
          style: AppTheme.bodySmall.copyWith(
            fontSize: 10,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStorageCell(MudLossStorageEntry row) {
    final availableStorageNames = pitController.unselectedPits
        .map((pit) => pit.pitName)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    final selectedValue = row.storage.value.isEmpty
        ? null
        : availableStorageNames.contains(row.storage.value)
        ? row.storage.value
        : null;

    return Obx(
      () => SizedBox(
        width: 158,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedValue,
              hint: Text(
                "",
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: dashboardController.isLocked.value
                    ? Colors.grey.shade400
                    : AppTheme.primaryColor,
                size: 18,
              ),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              isDense: true,
              menuMaxHeight: 200,
              items: availableStorageNames.map((pitName) {
                return DropdownMenuItem<String>(
                  value: pitName,
                  child: Text(
                    pitName,
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  Widget _buildInputCell(
    MudLossStorageEntry row,
    String field, {
    bool isLast = false,
  }) {
    final textController = field == 'dump'
        ? row.dumpController
        : field == 'evaporation'
        ? row.evaporationController
        : row.pitCleaningController;

    final rxValue = field == 'dump'
        ? row.dump
        : field == 'evaporation'
        ? row.evaporation
        : row.pitCleaning;

    return SizedBox(
      width: 126,
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
          controller: textController,
          enabled: !dashboardController.isLocked.value,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          style: AppTheme.bodySmall.copyWith(
            fontSize: 10,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            rxValue.value = value;
            controller.ensureTrailingRow();
          },
        ),
      ),
    );
  }
}
