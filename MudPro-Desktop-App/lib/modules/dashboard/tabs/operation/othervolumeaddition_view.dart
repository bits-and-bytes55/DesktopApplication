import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/other_vol_addition_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OtherVolAdditionActiveSystemView extends StatelessWidget {
  OtherVolAdditionActiveSystemView({super.key, required this.instanceKey})
    : controller = Get.put(
        OtherVolAdditionController(instanceKey: instanceKey),
        tag: instanceKey,
      );

  final String instanceKey;
  final OtherVolAdditionController controller;
  final DashboardController dashboardController =
      Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: operationPageBackground,
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 12),
      child: _OtherVolScrollArea(
        child: SizedBox(
          width: 470,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Other Vol. Addition - Active System',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 384,
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return Container(
                          height: 212,
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

                      return Table(
                        border: TableBorder.all(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(230),
                          1: FixedColumnWidth(152),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          _headerRow(),
                          _inputRow(
                            'Formation',
                            controller.formationController,
                          ),
                          _inputRow('Cuttings', controller.cuttingsController),
                          _inputRow(
                            'Volume Not Fluid',
                            controller.volumeNotFluidController,
                          ),
                          _dropdownRow(),
                          _blankRow(),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 76),
                    child: _helpButton(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: const BoxDecoration(color: AppTheme.tableHeaderBlue),
      children: [_headerCell('Addition'), _headerCell('Vol.\n(bbl)')],
    );
  }

  TableRow _inputRow(String label, TextEditingController textController) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: Obx(
            () => TextField(
              controller: textController,
              enabled: !dashboardController.isLocked.value,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w700,
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
                    ? operationLockedEditableColor
                    : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _dropdownRow() {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFC8D8EF)),
      children: [
        SizedBox(
          height: 32,
          child: Obx(
            () => ColoredBox(
              color: dashboardController.isLocked.value
                  ? operationLockedEditableColor
                  : Colors.white,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                value: controller.selectedDropdownAddition.value.isEmpty
                    ? null
                    : controller.selectedDropdownAddition.value,
                isExpanded: true,
                isDense: true,
                hint: const SizedBox.shrink(),
                icon: Container(
                  width: 24,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.tableHeaderBlue,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: dashboardController.isLocked.value
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                  ),
                ),
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
                dropdownColor: Colors.white,
                menuMaxHeight: 180,
                items: OtherVolAdditionController.additionOptions.map((label) {
                  return DropdownMenuItem<String>(
                    value: label,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySmall.copyWith(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: dashboardController.isLocked.value
                    ? null
                    : (value) {
                        if (value != null) {
                          controller.selectedDropdownAddition.value = value;
                        }
                      },
                ),
              ),
            ),
          ),
        ),
        Obx(() {
          final selected = controller.selectedDropdownAddition.value;
          if (selected.isEmpty) {
            return Container(height: 32, color: Colors.grey.shade50);
          }

          return SizedBox(
            height: 32,
            child: TextField(
              key: ValueKey('other-vol-dropdown-$selected'),
              controller: controller.controllerForAddition(selected),
              enabled: !dashboardController.isLocked.value,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w700,
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
                    ? operationLockedEditableColor
                    : Colors.white,
              ),
            ),
          );
        }),
      ],
    );
  }

  TableRow _blankRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
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
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _helpButton(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          side: BorderSide(color: Colors.grey.shade500),
          backgroundColor: AppTheme.tableHeaderBlue,
        ),
        onPressed: dashboardController.isLocked.value
            ? null
            : () => _openCuttingsGainDialog(context),
        child: Icon(
          Icons.question_mark,
          size: 16,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  void _openCuttingsGainDialog(BuildContext context) {
    final initialCuttings = controller.cuttingsController.text.trim();
    final volDrilledController = TextEditingController(text: initialCuttings);
    final efficiencyController = TextEditingController();
    final cuttingsGainController = TextEditingController(
      text: initialCuttings.isEmpty
          ? ''
          : _formatNumber(_parseNumber(volDrilledController.text)),
    );
    var shakerBypass = 'No';

    void recalculate() {
      if (volDrilledController.text.trim().isEmpty &&
          efficiencyController.text.trim().isEmpty) {
        cuttingsGainController.text = '';
        return;
      }
      final volDrilled = _parseNumber(volDrilledController.text);
      final efficiency = _parseNumber(efficiencyController.text);
      final gain = shakerBypass == 'No' && efficiency > 0
          ? volDrilled * (1 - (efficiency / 100))
          : volDrilled;
      cuttingsGainController.text = _formatNumber(gain);
    }

    volDrilledController.addListener(recalculate);
    efficiencyController.addListener(recalculate);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              child: SizedBox(
                width: 570,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppTheme.tableGridBlue),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calculate_outlined,
                            size: 22,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'MUDPRO+ - Cuttings Gain Calculation',
                            style: AppTheme.titleMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Table(
                        border: TableBorder.all(
                          color: AppTheme.tableGridBlue,
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(325),
                          1: FlexColumnWidth(),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          _dialogInputRow(
                            'Vol. Drilled (bbl)',
                            volDrilledController,
                            fillColor: const Color(0xFFFFFFE8),
                          ),
                          _dialogDropdownRow('Shaker Bypass', shakerBypass, (
                            value,
                          ) {
                            setState(() {
                              shakerBypass = value ?? 'No';
                              recalculate();
                            });
                          }),
                          _dialogInputRow(
                            'Shaker Efficiency (%)',
                            efficiencyController,
                          ),
                          _dialogInputRow(
                            'Cuttings Gain (bbl)',
                            cuttingsGainController,
                            readOnly: true,
                            fillColor: const Color(0xFFFFFFE8),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 24, 14, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 112,
                            height: 34,
                            child: OutlinedButton(
                              onPressed: () {
                                controller.cuttingsController.text =
                                    cuttingsGainController.text;
                                Navigator.of(dialogContext).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              child: const Text('Accept'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 112,
                            height: 34,
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      volDrilledController.dispose();
      efficiencyController.dispose();
      cuttingsGainController.dispose();
    });
  }

  TableRow _dialogInputRow(
    String label,
    TextEditingController textController, {
    bool readOnly = false,
    Color? fillColor,
  }) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        _dialogLabelCell(label),
        SizedBox(
          height: 35,
          child: TextField(
            controller: textController,
            readOnly: readOnly,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.bodySmall.copyWith(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 9,
              ),
              filled: true,
              fillColor: fillColor ?? Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  TableRow _dialogDropdownRow(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        _dialogLabelCell(label),
        Container(
          height: 35,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'No', child: Text('No')),
                DropdownMenuItem(value: 'Yes', child: Text('Yes')),
              ],
              onChanged: onChanged,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogLabelCell(String label) {
    return Container(
      height: 35,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 12,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0;
  }

  String _formatNumber(double value) {
    return formatOperationNumber(value);
  }
}

class _OtherVolScrollArea extends StatefulWidget {
  const _OtherVolScrollArea({required this.child});

  final Widget child;

  @override
  State<_OtherVolScrollArea> createState() => _OtherVolScrollAreaState();
}

class _OtherVolScrollAreaState extends State<_OtherVolScrollArea> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      trackVisibility: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.vertical,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
