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
  final _tableHorizontalScroll = ScrollController();
  final _tableVerticalScroll = ScrollController();

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
    _tableHorizontalScroll.dispose();
    _tableVerticalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(screenSize.width - 40, 1540.0);
    final dialogHeight = math.min(screenSize.height - 40, 690.0);
    final tableWidth = math.max(820.0, dialogWidth - 390);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _titleBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _listPane(
                      title: 'Type',
                      width: 170,
                      controller: _typeScroll,
                      isType: true,
                    ),
                    const SizedBox(width: 8),
                    _listPane(
                      title: 'Catalog',
                      width: 170,
                      controller: _catalogScroll,
                      isType: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _tablePane(tableWidth)),
                  ],
                ),
              ),
            ),
            _footer(context),
          ],
        ),
      ),
    );
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _listPane({
    required String title,
    required double width,
    required ScrollController controller,
    required bool isType,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(title, style: const TextStyle(fontSize: 10)),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBFC5CC)),
              ),
              child: Obx(() {
                final items = isType ? c.types : c.catalogs;
                final selected = isType
                    ? c.selectedTypeIndex.value
                    : c.selectedCatalogIndex.value;
                return Scrollbar(
                  controller: controller,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = selected == index;
                      return InkWell(
                        onTap: () => isType
                            ? c.selectType(index)
                            : c.selectCatalog(index),
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.centerLeft,
                          color: isSelected
                              ? const Color(0xFF1D6FCC)
                              : Colors.white,
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tablePane(double tableWidth) {
    return Obx(() {
      if (c.isLoading.value) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }

      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: tableWidth,
          child: Column(
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
                  '${c.selectedTypeName} - ${c.selectedCatalogName}',
                  style: const TextStyle(
                    fontSize: 10,
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
                  child: Scrollbar(
                    controller: _tableHorizontalScroll,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.depth == 1,
                    child: SingleChildScrollView(
                      controller: _tableHorizontalScroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 840,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _tableHeader() {
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: const [
                SizedBox(width: 42),
                Expanded(child: Center(child: Text('Body'))),
                SizedBox(width: 130, child: Center(child: Text('Assembly'))),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: const [
                SizedBox(width: 42),
                SizedBox(
                  width: 110,
                  child: Center(
                    child: Text(
                      'OD\n(in)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Center(
                    child: Text(
                      'ID\n(in)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(
                      'Nominal Wt.\n(lb/ft)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Center(
                    child: Text('Grade', style: TextStyle(fontSize: 10)),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Center(
                    child: Text(
                      'Yield\n(psi)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(
                  width: 148,
                  child: Center(
                    child: Text(
                      'Tensile Str.\n(lbf)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Center(
                    child: Text(
                      'Adjust Wt.\n(lb/ft)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(TubularDbRow row, int index) {
    final isSelected = c.selectedRowIndex.value == index;
    return InkWell(
      onTap: () => c.selectRow(index),
      child: Container(
        height: 33,
        color: isSelected ? const Color(0xFF1D6FCC) : Colors.white,
        child: Row(
          children: [
            _cell('${index + 1}', 42, isSelected),
            _cell(row.value('od'), 110, isSelected),
            _cell(row.value('id'), 110, isSelected),
            _cell(row.value('nominalWt'), 120, isSelected),
            _cell(row.value('grade'), 150, isSelected),
            _cell(row.value('yieldPsi'), 130, isSelected),
            _cell(row.value('tensileStr'), 148, isSelected),
            _cell(row.value('assemblyAdjustWt'), 130, isSelected),
          ],
        ),
      ),
    );
  }

  Widget _cell(String value, double width, bool selected) {
    return Container(
      width: width,
      height: 33,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFD4D8DD)),
          bottom: BorderSide(color: Color(0xFFD4D8DD)),
        ),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: selected ? Colors.white : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          OutlinedButton(
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
          const Spacer(),
          SizedBox(
            width: 110,
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
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Obx(
              () => FilledButton(
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
          ),
        ],
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

    return {
      'type': c.selectedTypeName,
      'catalog': c.selectedCatalogName,
      'odMm': _inchToMm(row.value('od')),
      'weightLbFt': row.value('nominalWt').isNotEmpty
          ? row.value('nominalWt')
          : row.value('assemblyAdjustWt'),
      'grade': row.value('grade'),
      'idMm': _inchToMm(row.value('id')),
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
