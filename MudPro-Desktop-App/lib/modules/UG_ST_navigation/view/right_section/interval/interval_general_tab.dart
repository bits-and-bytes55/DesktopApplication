import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_setup_ui_pattern.dart';

const Color _igBorder = wellSetupBorder;
const Color _igHeader = wellSetupReadOnlyFill;
const Color _igCell = wellSetupLockedEditable;
const List<String> _mudTypeOptions = <String>[
  'Water-based',
  'Oil-based',
  'Synthetic',
];

class IntervalGeneralTab extends StatelessWidget {
  const IntervalGeneralTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<IntervalController>();
    final ugSt = Get.find<UgStController>();

    return Obx(() {
      if (c.isLoading.value) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }

      final iv = c.selected.value;

      return Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _generalTable(iv?.name ?? '-', c, ugSt),
                  const SizedBox(height: 8),
                  _textArea(
                    'Interval Summary',
                    c.intervalSummaryCtrl,
                    ugSt.isLocked.value,
                  ),
                  const SizedBox(height: 8),
                  _textArea(
                    'Solid Control',
                    c.solidControlCtrl,
                    ugSt.isLocked.value,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  _textArea(
                    'Interval Conclusion and Recommendations',
                    c.intervalConclusionCtrl,
                    ugSt.isLocked.value,
                  ),
                  const SizedBox(height: 8),
                  _textArea('Sweeps', c.sweepsCtrl, ugSt.isLocked.value),
                  const SizedBox(height: 8),
                  _textArea(
                    'Lab Testing',
                    c.labTestingCtrl,
                    ugSt.isLocked.value,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _generalTable(
    String heading,
    IntervalController c,
    UgStController ugSt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          color: wellSetupSectionHeader,
          child: Text(
            heading,
            style: wellSetupSectionText,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _igBorder),
          ),
          child: Table(
            border: const TableBorder(
              horizontalInside: BorderSide(color: _igBorder),
              verticalInside: BorderSide(color: _igBorder),
            ),
            columnWidths: const {
              0: FixedColumnWidth(168),
              1: FlexColumnWidth(),
              2: FixedColumnWidth(78),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _tableRow('Formation', c.formationCtrl, '', ugSt.isLocked.value),
              _tableRow(
                'Bit Size',
                c.bitSizeCtrl,
                AppUnits.unitText('(mm)'),
                ugSt.isLocked.value,
              ),
              _tableRow(
                'Casing',
                c.casingCtrl,
                AppUnits.unitText('(mm)'),
                ugSt.isLocked.value,
              ),
              _tableRow(
                'Interval FIT',
                c.intervalFITCtrl,
                AppUnits.unitText('(ppg)'),
                ugSt.isLocked.value,
              ),
              _tableRow(
                'Mud Discription',
                c.mudDescCtrl,
                '',
                ugSt.isLocked.value,
              ),
              _tableDropdownRow(
                'Mud Type',
                c.mudTypeCtrl,
                '',
                ugSt.isLocked.value,
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _tableRow(
    String label,
    TextEditingController controller,
    String unit,
    bool locked,
  ) {
    return TableRow(
      children: [
        _labelCell(label),
        _valueCell(controller, locked),
        _unitCell(unit),
      ],
    );
  }

  TableRow _tableDropdownRow(
    String label,
    TextEditingController controller,
    String unit,
    bool locked,
  ) {
    return TableRow(
      children: [
        _labelCell(label),
        _dropdownCell(controller, locked),
        _unitCell(unit),
      ],
    );
  }

  Widget _labelCell(String text) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      color: _igHeader,
      child: Text(
        text,
        style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _valueCell(TextEditingController controller, bool locked) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: locked ? _igCell : Colors.white,
      child: TextField(
        controller: controller,
        readOnly: locked,
        style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _dropdownCell(TextEditingController controller, bool locked) {
    final currentValue = _mudTypeOptions.contains(controller.text.trim())
        ? controller.text.trim()
        : null;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: locked ? _igCell : Colors.white,
      alignment: Alignment.centerLeft,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          iconSize: 18,
          style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
          dropdownColor: Colors.white,
          hint: Text(
            '',
            style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
          ),
          items: _mudTypeOptions
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                  ),
                ),
              )
              .toList(),
          onChanged: locked
              ? null
              : (value) {
                  controller.text = value ?? '';
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                },
        ),
      ),
    );
  }

  Widget _unitCell(String text) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      color: _igHeader,
      child: Text(
        text,
        style: AppTheme.wellLikeUnitText.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _textArea(
    String title,
    TextEditingController controller,
    bool locked,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            color: wellSetupSectionHeader,
            child: Text(
              title,
              style: wellSetupSectionText,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: locked,
              expands: true,
              maxLines: null,
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
              decoration: InputDecoration(
                filled: true,
                fillColor: locked ? _igCell : Colors.white,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: _igBorder),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: _igBorder),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: _igBorder),
                ),
                contentPadding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
