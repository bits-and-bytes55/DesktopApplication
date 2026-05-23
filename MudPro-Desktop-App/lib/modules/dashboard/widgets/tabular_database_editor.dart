import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/tabular_database_editor_controller.dart';

class TabularDatabaseEditorView extends StatefulWidget {
  const TabularDatabaseEditorView({super.key});

  @override
  State<TabularDatabaseEditorView> createState() =>
      _TabularDatabaseEditorViewState();
}

class _TabularDatabaseEditorViewState extends State<TabularDatabaseEditorView> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: Column(
          children: [
            _titleBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _listPane(
                      title: 'Type',
                      width: 172,
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
                    const SizedBox(width: 8),
                    Expanded(child: _tablePane()),
                  ],
                ),
              ),
            ),
            _footer(),
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
        color: Color(0xFFEFEFEF),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Row(
        children: [
          const Text(
            'Tubular Database Editor',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            splashRadius: 16,
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
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
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: Text(title, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                          height: 25,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          color: isSelected
                              ? const Color(0xFF1D6FCC)
                              : Colors.white,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _smallIconButton(
                icon: Icons.add,
                color: const Color(0xFF1E88E5),
                onPressed: () => _showAddDialog(isType: isType),
              ),
              const SizedBox(width: 4),
              _smallIconButton(
                icon: Icons.close,
                color: const Color(0xFFE53935),
                onPressed: () => _confirmDelete(isType: isType),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tablePane() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBFC5CC)),
      ),
      child: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolbar(),
            Expanded(
              child: Scrollbar(
                controller: _tableHorizontalScroll,
                thumbVisibility: true,
                notificationPredicate: (notification) =>
                    notification.depth == 1,
                child: SingleChildScrollView(
                  controller: _tableHorizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: c.totalTableWidth,
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
                                  _tableRow(c.currentRows[index], index),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _toolbar() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: Text(
                '${c.selectedTypeName} - ${c.selectedCatalogName}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D74C7),
                ),
              ),
            ),
            if (c.isSaving.value)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            const SizedBox(width: 8),
            _plainButton('Add Row', c.addRow),
            const SizedBox(width: 6),
            _plainButton('Delete Row', c.deleteSelectedRow),
            const SizedBox(width: 6),
            _plainButton('Refresh', c.fetchDatabase),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    final bodyWidth = TabularDatabaseEditorController.columns
        .take(TabularDatabaseEditorController.columns.length - 1)
        .fold<double>(0, (sum, column) => sum + column.width);
    final assemblyWidth = TabularDatabaseEditorController.columns.last.width;

    return Container(
      height: 56,
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          SizedBox(
            height: 24,
            child: Row(
              children: [
                _headerCell('', 42),
                _headerCell('Body', bodyWidth),
                _headerCell('Assembly', assemblyWidth),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                _headerCell('', 42),
                for (final column in TabularDatabaseEditorController.columns)
                  _headerCell(column.label, column.width, fontSize: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow(TubularDbRow row, int index) {
    final isSelected = c.selectedRowIndex.value == index;
    return InkWell(
      onTap: () => c.selectRow(index),
      child: Container(
        height: 29,
        color: isSelected ? const Color(0xFFEAF3FF) : Colors.white,
        child: Row(
          children: [
            _numberCell(index + 1, isSelected),
            for (final column in TabularDatabaseEditorController.columns)
              _editCell(row, column, index),
          ],
        ),
      ),
    );
  }

  Widget _numberCell(int number, bool selected) {
    return Container(
      width: 42,
      height: 29,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFD4D8DD)),
          bottom: BorderSide(color: Color(0xFFD4D8DD)),
        ),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 11,
          color: selected ? const Color(0xFF0D47A1) : Colors.black87,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _editCell(TubularDbRow row, TubularDbColumn column, int rowIndex) {
    final controller = row.controllers[column.key]!;
    return Container(
      width: column.width,
      height: 29,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFD4D8DD)),
          bottom: BorderSide(color: Color(0xFFD4D8DD)),
        ),
      ),
      child: TextField(
        controller: controller,
        onTap: () => c.selectRow(rowIndex),
        style: const TextStyle(fontSize: 11),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width, {double fontSize = 11}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFBFC5CC)),
          bottom: BorderSide(color: Color(0xFFBFC5CC)),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, color: Colors.black87),
      ),
    );
  }

  Widget _footer() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        border: Border(top: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Row(
        children: [
          Obx(
            () => Text(
              c.loadError.value.isEmpty ? '' : 'Offline cache shown',
              style: const TextStyle(fontSize: 11, color: Color(0xFFB00020)),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 94,
            child: OutlinedButton(
              onPressed: c.saveAllNow,
              style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('Save'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 94,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 26,
      height: 24,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _plainButton(String label, Future<void> Function() onPressed) {
    return SizedBox(
      height: 25,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Future<void> _showAddDialog({required bool isType}) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isType ? 'Add Type' : 'Add Catalog'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: isType ? 'Type' : 'Catalog'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    if (isType) {
      await c.addType(value);
    } else {
      await c.addCatalog(value);
    }
  }

  Future<void> _confirmDelete({required bool isType}) async {
    final label = isType ? c.selectedTypeName : c.selectedCatalogName;
    if (label.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isType ? 'Delete Type' : 'Delete Catalog'),
        content: Text('Delete "$label"? Related rows will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (isType) {
      await c.deleteSelectedType();
    } else {
      await c.deleteSelectedCatalog();
    }
  }
}
