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
    final dialogWidth = math.min(screenSize.width - 28, 1630.0);
    final dialogHeight = math.min(screenSize.height - 28, 720.0);
    const leftWidth = 732.0;
    final tableWidth = math.max(820.0, dialogWidth - leftWidth - 34);

    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _titleBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
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
                              width: 188,
                              controller: _typeScroll,
                              itemCount: c.types.length,
                              selectedIndex: c.selectedTypeIndex.value,
                              itemLabel: (index) => c.types[index].name,
                              onSelected: (index) {
                                c.selectType(index);
                                _resetDerivedSelections();
                              },
                            ),
                            const SizedBox(width: 8),
                            _optionPane(
                              title: 'Catalog',
                              width: 130,
                              controller: _catalogScroll,
                              itemCount: c.catalogs.length,
                              selectedIndex: c.selectedCatalogIndex.value,
                              itemLabel: (index) => c.catalogs[index].name,
                              onSelected: (index) {
                                c.selectCatalog(index);
                                _resetDerivedSelections();
                              },
                            ),
                            const SizedBox(width: 8),
                            _valuePane(
                              title: 'OD (${c.diameterUnitLabel})',
                              width: 126,
                              controller: _odScroll,
                              values: ods,
                              selectedIndex: _odIndex,
                              onSelected: (index) {
                                _odIndex = index;
                                _selectFirstMatching('od', ods[index]);
                              },
                            ),
                            const SizedBox(width: 8),
                            _valuePane(
                              title: 'Weight (${c.lineDensityUnitLabel})',
                              width: 126,
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
                            const SizedBox(width: 8),
                            _valuePane(
                              title: 'Grade',
                              width: 128,
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: _tablePane(tableWidth, ods, weights, grades),
                      ),
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
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Row(
        children: [
          const Text(
            'Tubular Database',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            splashRadius: 14,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18),
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
            height: 24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(fontSize: 11)),
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
        height: 29,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        color: isSelected ? const Color(0xFF1D6FCC) : Colors.white,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _tablePane(
    double tableWidth,
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

    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: tableWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBFC5CC)),
                color: const Color(0xFFF8F8F8),
              ),
              child: Text(
                '${c.selectedTypeName} - ${c.selectedCatalogName} : $od ${c.diameterUnitLabel}, $weight ${c.lineDensityUnitLabel}, $grade',
                style: const TextStyle(
                  fontSize: 12,
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
                    _tableHeader(),
                    Expanded(
                      child: Scrollbar(
                        controller: _tableVerticalScroll,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _tableVerticalScroll,
                          itemCount: c.currentRows.length,
                          itemBuilder: (context, index) =>
                              _dataRow(c.currentRows[index], index),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: const [
                SizedBox(width: 52),
                SizedBox(width: 260, child: Center(child: Text('Body'))),
                SizedBox(width: 390, child: Center(child: Text('Connection'))),
                SizedBox(width: 132, child: Center(child: Text('Assembly'))),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 52),
                _headerCell('ID\n(${c.diameterUnitLabel})', 130),
                _headerCell('Yield\n(${c.pressureUnitLabel})', 130),
                _headerCell('Type', 130),
                _headerCell('OD\n(${c.diameterUnitLabel})', 130),
                _headerCell('ID\n(${c.diameterUnitLabel})', 130),
                _headerCell('Adjust Wt.\n(${c.lineDensityUnitLabel})', 132),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String value, double width) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _dataRow(TubularDbRow row, int index) {
    final isSelected = c.selectedRowIndex.value == index;
    return InkWell(
      onTap: () => c.selectRow(index),
      child: Container(
        height: 31,
        color: isSelected ? const Color(0xFF1D6FCC) : Colors.white,
        child: Row(
          children: [
            _cell('${index + 1}', 52, isSelected, align: TextAlign.center),
            _cell(row.value('id'), 130, isSelected),
            _cell(row.value('yieldPsi'), 130, isSelected),
            _cell(row.value('connectionType'), 130, isSelected),
            _cell(row.value('connectionOd'), 130, isSelected),
            _cell(row.value('connectionId'), 130, isSelected),
            _cell(row.value('assemblyAdjustWt'), 132, isSelected),
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
      height: 31,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
          fontSize: 12,
          color: selected ? Colors.white : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Obx(
        () => Row(
          children: [
            Text(
              'Material: ${c.selectedTypeMaterial}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 110,
              height: 36,
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
              width: 110,
              height: 36,
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
              width: 110,
              height: 36,
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
