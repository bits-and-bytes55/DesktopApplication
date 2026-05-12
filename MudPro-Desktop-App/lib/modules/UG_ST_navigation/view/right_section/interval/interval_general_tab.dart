import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

const Color _igBorder = Color(0xFFC9CED6);
const Color _igHeader = Color(0xFFF3F3F3);
const Color _igCell = Color(0xFFFFF6C7);

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
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            heading,
            style: const TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
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
              _tableRow('Mud Type', c.mudTypeCtrl, '', ugSt.isLocked.value),
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

  Widget _labelCell(String text) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      color: _igHeader,
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
      ),
    );
  }

  Widget _valueCell(TextEditingController controller, bool locked) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: _igCell,
      child: TextField(
        controller: controller,
        readOnly: locked,
        style: const TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
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
        style: const TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: locked,
              expands: true,
              maxLines: null,
              style: const TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
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
