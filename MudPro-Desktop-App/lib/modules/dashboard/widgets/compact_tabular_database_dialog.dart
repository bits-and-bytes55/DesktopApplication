import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/tabular_database_editor_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/tabular_database_editor.dart';

class CompactTabularDatabaseDialog extends StatefulWidget {
  const CompactTabularDatabaseDialog({super.key});

  @override
  State<CompactTabularDatabaseDialog> createState() =>
      _CompactTabularDatabaseDialogState();
}

class _CompactTabularDatabaseDialogState
    extends State<CompactTabularDatabaseDialog> {
  late final TabularDatabaseEditorController c;
  final _typeScroll = ScrollController();
  final _catalogScroll = ScrollController();
  final _odScroll = ScrollController();
  final _weightScroll = ScrollController();
  final _gradeScroll = ScrollController();
  final _tableVerticalScroll = ScrollController();
  int _odIndex = 0;
  int _weightIndex = 0;
  int _gradeIndex = 0;

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<TabularDatabaseEditorController>()
        ? Get.find<TabularDatabaseEditorController>()
        : Get.put(TabularDatabaseEditorController(), permanent: true);
  }

  @override
  void dispose() {
    _typeScroll.dispose();
    _catalogScroll.dispose();
    _odScroll.dispose();
    _weightScroll.dispose();
    _gradeScroll.dispose();
    _tableVerticalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(screenSize.width - 8, 1630.0);
    final dialogHeight = math.min(screenSize.height - 8, 720.0);
    const leftWidth = 500.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _titleBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Obx(() {
                  c.unitSignature.value;
                  final ods = c.distinctValues('od');
                  final weights = c.distinctValues('nominalWt');
                  final grades = c.distinctValues('grade');
                  _odIndex = _clamp(_odIndex, ods.length);
                  _weightIndex = _clamp(_weightIndex, weights.length);
                  _gradeIndex = _clamp(_gradeIndex, grades.length);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: leftWidth,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _optionPane(
                              title: 'Type',
                              width: 126,
                              controller: _typeScroll,
                              itemCount: c.types.length,
                              selectedIndex: c.selectedTypeIndex.value,
                              itemLabel: (index) => c.types[index].name,
                              onSelected: (index) {
                                c.selectType(index);
                                _resetDerivedSelections();
                              },
                            ),
                            const SizedBox(width: 6),
                            _optionPane(
                              title: 'Catalog',
                              width: 88,
                              controller: _catalogScroll,
                              itemCount: c.catalogs.length,
                              selectedIndex: c.selectedCatalogIndex.value,
                              itemLabel: (index) => c.catalogs[index].name,
                              onSelected: (index) {
                                c.selectCatalog(index);
                                _resetDerivedSelections();
                              },
                            ),
                            const SizedBox(width: 6),
                            _valuePane(
                              title: 'OD (${c.diameterUnitLabel})',
                              width: 86,
                              controller: _odScroll,
                              values: ods,
                              selectedIndex: _odIndex,
                              onSelected: (index) {
                                _odIndex = index;
                                _selectFirstMatching('od', ods[index]);
                              },
                            ),
                            const SizedBox(width: 6),
                            _valuePane(
                              title: 'Weight (${c.lineDensityUnitLabel})',
                              width: 88,
                              controller: _weightScroll,
                              values: weights,
                              selectedIndex: _weightIndex,
                              onSelected: (index) {
                                _weightIndex = index;
                                _selectFirstMatching(
                                  'nominalWt',
                                  weights[index],
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            _valuePane(
                              title: 'Grade',
                              width: 88,
                              controller: _gradeScroll,
                              values: grades,
                              selectedIndex: _gradeIndex,
                              onSelected: (index) {
                                _gradeIndex = index;
                                _selectFirstMatching('grade', grades[index]);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _tablePane(ods, weights, grades)),
                    ],
                  );
                }),
              ),
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  int _clamp(int index, int length) {
    if (length <= 0) return 0;
    if (index < 0) return 0;
    if (index >= length) return length - 1;
    return index;
  }

  void _resetDerivedSelections() {
    setState(() {
      _odIndex = 0;
      _weightIndex = 0;
      _gradeIndex = 0;
    });
  }

  void _selectFirstMatching(String key, String value) {
    final rowIndex = c.firstRowIndexForValue(key, value);
    if (rowIndex >= 0) {
      c.selectRow(rowIndex);
    }
    setState(() {});
  }

  Widget _titleBar(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Row(
        children: [
          const Text(
            'Tubular Database',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            splashRadius: 12,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _optionPane({
    required String title,
    required double width,
    required ScrollController controller,
    required int itemCount,
    required int selectedIndex,
    required String Function(int index) itemLabel,
    required ValueChanged<int> onSelected,
  }) {
    return _paneFrame(
      title: title,
      width: width,
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: ListView.builder(
          controller: controller,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            return _listItem(
              label: itemLabel(index),
              isSelected: isSelected,
              onTap: () => onSelected(index),
            );
          },
        ),
      ),
    );
  }

  Widget _valuePane({
    required String title,
    required double width,
    required ScrollController controller,
    required List<String> values,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return _paneFrame(
      title: title,
      width: width,
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: ListView.builder(
          controller: controller,
          itemCount: values.length,
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            return _listItem(
              label: values[index],
              isSelected: isSelected,
              onTap: () => onSelected(index),
            );
          },
        ),
      ),
    );
  }

  Widget _paneFrame({
    required String title,
    required double width,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(fontSize: 10)),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFBFC5CC)),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        color: isSelected ? const Color(0xFF1D6FCC) : Colors.white,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _tablePane(
    List<String> ods,
    List<String> weights,
    List<String> grades,
  ) {
    if (c.isLoading.value) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final od = ods.isEmpty ? '' : ods[_clamp(_odIndex, ods.length)];
    final weight = weights.isEmpty
        ? ''
        : weights[_clamp(_weightIndex, weights.length)];
    final grade = grades.isEmpty
        ? ''
        : grades[_clamp(_gradeIndex, grades.length)];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(constraints.maxWidth - 18, 1.0);
        const rowNoW = 42.0;
        final dataW = math.max(tableWidth - rowNoW, 1.0);
        final idW = dataW * 0.17;
        final yieldW = dataW * 0.17;
        final typeW = dataW * 0.18;
        final connOdW = dataW * 0.17;
        final connIdW = dataW * 0.17;
        final adjustW = dataW - idW - yieldW - typeW - connOdW - connIdW;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBFC5CC)),
                color: const Color(0xFFF8F8F8),
              ),
              child: Text(
                '${c.selectedTypeName} - ${c.selectedCatalogName} : $od ${c.diameterUnitLabel}, $weight ${c.lineDensityUnitLabel}, $grade',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D74C7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBFC5CC)),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: tableWidth,
                        child: _tableHeader(
                          rowNoW: rowNoW,
                          idW: idW,
                          yieldW: yieldW,
                          typeW: typeW,
                          connOdW: connOdW,
                          connIdW: connIdW,
                          adjustW: adjustW,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _tableVerticalScroll,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _tableVerticalScroll,
                          itemCount: c.currentRows.length,
                          itemBuilder: (context, index) => Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: tableWidth,
                              child: _dataRow(
                                c.currentRows[index],
                                index,
                                rowNoW: rowNoW,
                                idW: idW,
                                yieldW: yieldW,
                                typeW: typeW,
                                connOdW: connOdW,
                                connIdW: connIdW,
                                adjustW: adjustW,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tableHeader({
    required double rowNoW,
    required double idW,
    required double yieldW,
    required double typeW,
    required double connOdW,
    required double connIdW,
    required double adjustW,
  }) {
    return ClipRect(
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F8F8),
                border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
              ),
              child: Row(
                children: [
                  SizedBox(width: rowNoW),
                  _groupHeader('Body', idW + yieldW, height: 22),
                  _groupHeader(
                    'Connection',
                    typeW + connOdW + connIdW,
                    height: 22,
                  ),
                  _groupHeader('Assembly', adjustW, height: 22),
                ],
              ),
            ),
            Container(
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F8F8),
                border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
              ),
              child: Row(
                children: [
                  SizedBox(width: rowNoW),
                  _headerCell('ID\n(${c.diameterUnitLabel})', idW),
                  _headerCell('Yield\n(${c.pressureUnitLabel})', yieldW),
                  _headerCell('Type', typeW),
                  _headerCell('OD\n(${c.diameterUnitLabel})', connOdW),
                  _headerCell('ID\n(${c.diameterUnitLabel})', connIdW),
                  _headerCell(
                    'Adjust Wt.\n(${c.lineDensityUnitLabel})',
                    adjustW,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(String value, double width, {required double height}) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _headerCell(String value, double width) {
    return Container(
      width: width,
      height: 38,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(fontSize: 9, height: 1.05),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _dataRow(
    TubularDbRow row,
    int index, {
    required double rowNoW,
    required double idW,
    required double yieldW,
    required double typeW,
    required double connOdW,
    required double connIdW,
    required double adjustW,
  }) {
    final isSelected = c.selectedRowIndex.value == index;
    return InkWell(
      onTap: () => c.selectRow(index),
      child: Container(
        height: 22,
        color: isSelected ? const Color(0xFF1D6FCC) : Colors.white,
        child: Row(
          children: [
            _cell('${index + 1}', rowNoW, isSelected, align: TextAlign.center),
            _cell(row.value('id'), idW, isSelected),
            _cell(row.value('yieldPsi'), yieldW, isSelected),
            _cell(row.value('connectionType'), typeW, isSelected),
            _cell(row.value('connectionOd'), connOdW, isSelected),
            _cell(row.value('connectionId'), connIdW, isSelected),
            _cell(row.value('assemblyAdjustWt'), adjustW, isSelected),
          ],
        ),
      ),
    );
  }

  Widget _cell(
    String value,
    double width,
    bool selected, {
    TextAlign align = TextAlign.right,
  }) {
    return Container(
      width: width,
      height: 22,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFD4D8DD)),
          bottom: BorderSide(color: Color(0xFFD4D8DD)),
        ),
      ),
      child: Text(
        value,
        textAlign: align,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          color: selected ? Colors.white : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 7),
      child: Obx(
        () => Row(
          children: [
            Text(
              'Material: ${c.selectedTypeMaterial}',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 96,
              height: 30,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TabularDatabaseEditorView(),
                    ),
                  );
                  setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text('Editor...'),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 96,
              height: 30,
              child: FilledButton(
                onPressed: c.currentRows.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_selectionPayload()),
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              height: 30,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _selectionPayload() {
    final row = c.selectedVisibleRow();
    if (row == null) {
      return {
        'type': c.selectedTypeName,
        'catalog': c.selectedCatalogName,
        'odMm': '',
        'weightLbFt': '',
        'grade': '',
        'idMm': '',
      };
    }

    final weightBase = c.rowBaseValue(row, 'nominalWt').isNotEmpty
        ? c.rowBaseValue(row, 'nominalWt')
        : c.rowBaseValue(row, 'assemblyAdjustWt');

    return {
      'type': c.selectedTypeName,
      'catalog': c.selectedCatalogName,
      'odMm': _inchToMm(c.rowBaseValue(row, 'od')),
      'weightLbFt': weightBase,
      'grade': row.value('grade'),
      'idMm': _inchToMm(c.rowBaseValue(row, 'id')),
    };
  }

  String _inchToMm(String rawValue) {
    final parsed = double.tryParse(rawValue.replaceAll(',', '').trim());
    if (parsed == null) return '';
    final mm = parsed * 25.4;
    return mm
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
