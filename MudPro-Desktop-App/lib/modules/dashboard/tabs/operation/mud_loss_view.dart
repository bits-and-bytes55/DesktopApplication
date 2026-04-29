import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_loss_active_system_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_desktop_ui.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudLossActiveSystemView extends StatelessWidget {
  MudLossActiveSystemView({super.key});

  final MudLossActiveSystemController controller = Get.put(
    MudLossActiveSystemController(),
  );
  final DashboardController dashboardController =
      Get.find<DashboardController>();

  final List<Map<String, String>> fixedRows = const [
    {'label': 'Cuttings/Retention', 'key': 'cuttingsRetention'},
    {'label': 'Seepage', 'key': 'seepage'},
    {'label': 'Dump', 'key': 'dump'},
    {'label': 'Shakers', 'key': 'shakers'},
    {'label': 'Centrifuge', 'key': 'centrifuge'},
    {'label': 'Evaporation', 'key': 'evaporation'},
    {'label': 'Pit Cleaning', 'key': 'pitCleaning'},
    {'label': 'Formation', 'key': 'formation'},
    {'label': 'Abandon in Hole', 'key': 'abandonInHole'},
    {'label': 'Left behind Casing', 'key': 'leftBehindCasing'},
    {'label': 'Tripping', 'key': 'tripping'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mud Loss - Active System',
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
                width: 438,
                height: 452,
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

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 438,
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                    columnWidths: const {
                      0: FixedColumnWidth(60),
                      1: FixedColumnWidth(224),
                      2: FixedColumnWidth(152),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _headerRow(),
                      ...fixedRows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;
                        return _fixedRow(index + 1, row['label']!, row['key']!);
                      }),
                      _extraLossRow(),
                      _blankRow(13),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _sideActions(context),
              ],
            );
          }),
        ],
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: [_headerCell(''), _headerCell('Loss'), _volumeHeaderCell()],
    );
  }

  TableRow _fixedRow(int number, String label, String fieldKey) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [_numberCell(number), _labelCell(label), _volumeCell(fieldKey)],
    );
  }

  TableRow _extraLossRow() {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFC8D8EF)),
      children: [
        _numberCell(12, editable: true),
        _extraDropdownCell(),
        _extraVolumeCell(),
      ],
    );
  }

  TableRow _blankRow(int number) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        _numberCell(number),
        const SizedBox(height: 32),
        Container(height: 32, color: Colors.grey.shade50),
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
        ),
      ),
    );
  }

  Widget _volumeHeaderCell() {
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Text(
        'Vol.\n(bbl)',
        textAlign: TextAlign.center,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _numberCell(int number, {bool editable = false}) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (editable) ...[
            Icon(Icons.edit_outlined, size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 5),
          ],
          Text(
            '$number',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelCell(String label) {
    return Container(
      height: 32,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        label,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _volumeCell(String fieldKey) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller.fields[fieldKey],
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
      ),
    );
  }

  Widget _extraDropdownCell() {
    return SizedBox(
      height: 32,
      child: Obx(
        () => DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedExtraLoss.value.isEmpty
                ? null
                : controller.selectedExtraLoss.value,
            isExpanded: true,
            isDense: true,
            hint: const SizedBox.shrink(),
            icon: Container(
              width: 25,
              height: 31,
              alignment: Alignment.center,
              color: Colors.grey.shade300,
              child: Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: dashboardController.isLocked.value
                    ? Colors.grey.shade500
                    : Colors.grey.shade800,
              ),
            ),
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 190,
            items: MudLossActiveSystemController.extraLossOptions.map((label) {
              return DropdownMenuItem<String>(
                value: label,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(fontSize: 11),
                  ),
                ),
              );
            }).toList(),
            onChanged: dashboardController.isLocked.value
                ? null
                : (value) {
                    if (value != null) {
                      controller.selectedExtraLoss.value = value;
                    }
                  },
          ),
        ),
      ),
    );
  }

  Widget _extraVolumeCell() {
    return Obx(() {
      final hasSelection = controller.selectedExtraLoss.value.isNotEmpty;
      if (!hasSelection) {
        return Container(height: 32, color: Colors.grey.shade50);
      }

      return SizedBox(
        height: 32,
        child: TextField(
          controller: controller.extraLossVolumeController,
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
        ),
      );
    });
  }

  Widget _sideActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 49),
      child: Column(
        children: [
          _sideButton(
            icon: Icons.question_mark,
            color: AppTheme.primaryColor,
            onPressed: dashboardController.isLocked.value
                ? () {}
                : () => showCuttingsRetentionDialog(
                    context: context,
                    initialValue:
                        controller.fields['cuttingsRetention']?.text ?? '',
                    onAccepted: (value) {
                      controller.fields['cuttingsRetention']?.text = value;
                    },
                  ),
          ),
          const SizedBox(height: 124),
          _sideButton(
            icon: Icons.question_mark,
            color: AppTheme.primaryColor,
            onPressed: dashboardController.isLocked.value
                ? () {}
                : () => showEvaporationDialog(
                    context: context,
                    initialValue: controller.fields['evaporation']?.text ?? '',
                    onAccepted: (value) {
                      controller.fields['evaporation']?.text = value;
                    },
                  ),
          ),
          const SizedBox(height: 34),
          _sideButton(
            icon: Icons.flash_on,
            color: Colors.deepOrange,
            onPressed: dashboardController.isLocked.value
                ? () {}
                : () {
                    controller.fields['formation']?.text = '0.00';
                  },
          ),
        ],
      ),
    );
  }

  Widget _sideButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          side: BorderSide(color: Colors.grey.shade500),
          backgroundColor: Colors.grey.shade100,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
