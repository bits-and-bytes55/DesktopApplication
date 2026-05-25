import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/tabular_database_editor_controller.dart';

class _MaterialEditorRow {
  _MaterialEditorRow({
    required this.id,
    required this.originalName,
    required this.sortOrder,
    required String name,
    required String density,
    required String elasticModulus,
    required String poissonRatio,
    required String compressibility,
    required String heatCapacity,
    required String thermalConductivity,
  }) : nameController = TextEditingController(text: name),
       densityController = TextEditingController(text: density),
       elasticModulusController = TextEditingController(text: elasticModulus),
       poissonRatioController = TextEditingController(text: poissonRatio),
       compressibilityController = TextEditingController(text: compressibility),
       heatCapacityController = TextEditingController(text: heatCapacity),
       thermalConductivityController = TextEditingController(
         text: thermalConductivity,
       );

  factory _MaterialEditorRow.fromOption(TubularDbOption option) {
    return _MaterialEditorRow(
      id: option.id,
      originalName: option.name,
      sortOrder: option.sortOrder,
      name: option.name,
      density: option.density,
      elasticModulus: option.elasticModulus,
      poissonRatio: option.poissonRatio,
      compressibility: option.compressibility,
      heatCapacity: option.heatCapacity,
      thermalConductivity: option.thermalConductivity,
    );
  }

  factory _MaterialEditorRow.blank(int sortOrder) {
    return _MaterialEditorRow(
      id: '',
      originalName: '',
      sortOrder: sortOrder,
      name: '',
      density: '',
      elasticModulus: '',
      poissonRatio: '',
      compressibility: '',
      heatCapacity: '',
      thermalConductivity: '',
    );
  }

  String id;
  String originalName;
  final int sortOrder;
  final TextEditingController nameController;
  final TextEditingController densityController;
  final TextEditingController elasticModulusController;
  final TextEditingController poissonRatioController;
  final TextEditingController compressibilityController;
  final TextEditingController heatCapacityController;
  final TextEditingController thermalConductivityController;
  bool isSaving = false;
  bool pendingSave = false;
  Future<void>? activeSave;
  VoidCallback? _listener;
  bool _disposed = false;

  String get name => nameController.text.trim();
  bool get hasData =>
      name.isNotEmpty ||
      densityController.text.trim().isNotEmpty ||
      elasticModulusController.text.trim().isNotEmpty ||
      poissonRatioController.text.trim().isNotEmpty ||
      compressibilityController.text.trim().isNotEmpty ||
      heatCapacityController.text.trim().isNotEmpty ||
      thermalConductivityController.text.trim().isNotEmpty;

  List<TextEditingController> get controllers => [
    nameController,
    densityController,
    elasticModulusController,
    poissonRatioController,
    compressibilityController,
    heatCapacityController,
    thermalConductivityController,
  ];

  bool get isDisposed => _disposed;

  void attachListener(VoidCallback listener) {
    detachListener();
    _listener = listener;
    for (final controller in controllers) {
      controller.addListener(listener);
    }
  }

  void detachListener() {
    final listener = _listener;
    if (listener == null || _disposed) return;
    for (final controller in controllers) {
      controller.removeListener(listener);
    }
    _listener = null;
  }

  TubularDbOption toOption(int nextSortOrder) {
    return TubularDbOption(
      id: id,
      name: name,
      sortOrder: nextSortOrder,
      density: densityController.text.trim(),
      elasticModulus: elasticModulusController.text.trim(),
      poissonRatio: poissonRatioController.text.trim(),
      compressibility: compressibilityController.text.trim(),
      heatCapacity: heatCapacityController.text.trim(),
      thermalConductivity: thermalConductivityController.text.trim(),
    );
  }

  void dispose() {
    if (_disposed) return;
    detachListener();
    _disposed = true;
    nameController.dispose();
    densityController.dispose();
    elasticModulusController.dispose();
    poissonRatioController.dispose();
    compressibilityController.dispose();
    heatCapacityController.dispose();
    thermalConductivityController.dispose();
  }
}

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
        c.unitSignature.value;
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
    final groups = ['Body', 'Connection', 'Assembly'];

    return Container(
      height: 66,
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          SizedBox(
            height: 24,
            child: Row(
              children: [
                _headerCell('', 42),
                for (final group in groups)
                  _headerCell(
                    group,
                    TabularDatabaseEditorController.columns
                        .where((column) => column.group == group)
                        .fold<double>(0, (sum, column) => sum + column.width),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: Row(
              children: [
                _headerCell('', 42),
                for (final column in TabularDatabaseEditorController.columns)
                  _headerCell(
                    c.displayHeader(column),
                    column.width,
                    fontSize: 10,
                  ),
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
              onPressed: () async {
                await c.saveAllNow();
                if (!mounted) return;
                Navigator.of(context).maybePop();
              },
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

  Widget _materialIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Icon(icon, size: 15),
        ),
      ),
    );
  }

  Future<void> _showAddDialog({required bool isType}) async {
    if (isType) {
      await _showNewTypeDialog();
      return;
    }
    await _showNewCatalogDialog();
  }

  Future<void> _showNewCatalogDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SizedBox(
          width: 470,
          height: 175,
          child: Column(
            children: [
              _dialogTitle(context, 'New Catalog'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(74, 22, 78, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Catalog', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 28,
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _dialogButton(
                            'OK',
                            () => Navigator.of(context).pop(controller.text),
                          ),
                          const SizedBox(width: 14),
                          _dialogButton(
                            'Cancel',
                            () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    await c.addCatalog(value);
  }

  Future<void> _showNewTypeDialog() async {
    final typeController = TextEditingController();
    var selectedMaterial = c.materials.isEmpty
        ? 'Steel'
        : c.materials.first.name;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final materialNames = c.materials.isEmpty
              ? <String>['Steel', 'Aluminium']
              : c.materials.map((item) => item.name).toList();
          if (!materialNames.contains(selectedMaterial)) {
            selectedMaterial = materialNames.first;
          }
          return Dialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            child: SizedBox(
              width: 570,
              height: 218,
              child: Column(
                children: [
                  _dialogTitle(context, 'New Type'),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 26, 26, 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 130,
                                child: Text(
                                  'Pipe Type',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 28,
                                  child: TextField(
                                    controller: typeController,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 6,
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const SizedBox(
                                width: 130,
                                child: Text(
                                  'Material',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 30,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedMaterial,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: c.materials.isEmpty
                                        ? materialNames
                                              .map(
                                                (item) => DropdownMenuItem(
                                                  value: item,
                                                  child: Text(item),
                                                ),
                                              )
                                              .toList()
                                        : c.materials
                                              .map(
                                                (item) => DropdownMenuItem(
                                                  value: item.name,
                                                  child: Text(item.name),
                                                ),
                                              )
                                              .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setDialogState(
                                        () => selectedMaterial = value,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _materialIconButton(
                                icon: Icons.add,
                                tooltip: 'Add material',
                                onPressed: () async {
                                  final material =
                                      await _showMaterialDatabaseEditor(
                                        selectedMaterial: selectedMaterial,
                                        addBlankOnOpen: true,
                                      );
                                  if (!context.mounted) return;
                                  if (material == null ||
                                      material.trim().isEmpty) {
                                    return;
                                  }
                                  setDialogState(() {
                                    selectedMaterial = material.trim();
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              _materialIconButton(
                                icon: Icons.edit,
                                tooltip: 'Edit material',
                                onPressed:
                                    c.materials.isEmpty ||
                                        selectedMaterial.trim().isEmpty
                                    ? null
                                    : () async {
                                        final material =
                                            await _showMaterialDatabaseEditor(
                                              selectedMaterial:
                                                  selectedMaterial,
                                            );
                                        if (!context.mounted) return;
                                        if (material == null ||
                                            material.trim().isEmpty) {
                                          return;
                                        }
                                        setDialogState(() {
                                          selectedMaterial = material.trim();
                                        });
                                      },
                              ),
                              const SizedBox(width: 4),
                              _materialIconButton(
                                icon: Icons.delete_outline,
                                tooltip: 'Delete material',
                                onPressed: c.materials.length <= 1
                                    ? null
                                    : () async {
                                        final shouldDelete =
                                            await _confirmMaterialDelete(
                                              selectedMaterial,
                                            );
                                        if (!context.mounted) return;
                                        if (shouldDelete != true) return;
                                        await c.deleteMaterial(
                                          selectedMaterial,
                                        );
                                        setDialogState(() {
                                          final names = c.materials
                                              .map((item) => item.name)
                                              .toList();
                                          selectedMaterial = names.isEmpty
                                              ? 'Steel'
                                              : names.first;
                                        });
                                      },
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _dialogButton(
                                'OK',
                                () => Navigator.of(context).pop({
                                  'name': typeController.text,
                                  'material': selectedMaterial,
                                }),
                              ),
                              const SizedBox(width: 14),
                              _dialogButton(
                                'Cancel',
                                () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    typeController.dispose();
    final name = result?['name']?.trim() ?? '';
    if (name.isEmpty) return;
    await c.addType(name, material: result?['material'] ?? 'Steel');
  }

  Future<String?> _showMaterialDatabaseEditor({
    required String selectedMaterial,
    bool addBlankOnOpen = false,
  }) async {
    final saveTimers = <_MaterialEditorRow, Timer>{};
    final rows = c.materials
        .map((item) => _MaterialEditorRow.fromOption(item))
        .toList();
    final shouldSelectBlank = rows.isEmpty || addBlankOnOpen;
    if (shouldSelectBlank) {
      rows.add(_MaterialEditorRow.blank(rows.length));
    }
    var selectedIndex = shouldSelectBlank
        ? rows.length - 1
        : rows.indexWhere((row) => row.name == selectedMaterial);
    if (selectedIndex < 0) selectedIndex = rows.isEmpty ? 0 : rows.length - 1;
    var isClosing = false;
    final dialogNavigator = Navigator.of(context, rootNavigator: true);

    Future<void> saveRow(_MaterialEditorRow row) async {
      if (row.isDisposed ||
          !row.hasData ||
          row.name.isEmpty ||
          !rows.contains(row)) {
        return;
      }
      if (row.isSaving) {
        row.pendingSave = true;
        await row.activeSave;
        if (!row.pendingSave || row.isDisposed || !rows.contains(row)) return;
        row.pendingSave = false;
        await saveRow(row);
        return;
      }
      row.isSaving = true;
      row.activeSave = () async {
        final saved = await c.saveMaterialOption(
          row.toOption(rows.indexOf(row)),
          oldName: row.originalName,
        );
        if (saved != null && !row.isDisposed && rows.contains(row)) {
          row.id = saved.id;
          row.originalName = saved.name;
        }
      }();
      try {
        await row.activeSave;
      } finally {
        row.isSaving = false;
        row.activeSave = null;
      }
      if (row.pendingSave && !row.isDisposed && rows.contains(row)) {
        row.pendingSave = false;
        await saveRow(row);
      }
    }

    void scheduleSave(_MaterialEditorRow row) {
      if (isClosing || row.isDisposed || !rows.contains(row)) return;
      saveTimers[row]?.cancel();
      saveTimers[row] = Timer(const Duration(milliseconds: 650), () {
        unawaited(saveRow(row));
      });
    }

    void attachRow(_MaterialEditorRow row) {
      row.attachListener(() => scheduleSave(row));
    }

    void disposeRowLater(_MaterialEditorRow row) {
      if (row.isDisposed) return;
      row.detachListener();
      saveTimers.remove(row)?.cancel();
      unawaited(
        () async {
          try {
            await row.activeSave;
          } catch (_) {}
          await Future<void>.delayed(const Duration(seconds: 2));
          row.dispose();
        }(),
      );
    }

    Future<void> flushMaterialSaves() async {
      for (final timer in saveTimers.values) {
        timer.cancel();
      }
      saveTimers.clear();
      for (final row in List<_MaterialEditorRow>.from(rows)) {
        await saveRow(row);
      }
    }

    for (final row in rows) {
      attachRow(row);
    }

    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void addRow() {
            if (isClosing) return;
            setDialogState(() {
              final row = _MaterialEditorRow.blank(rows.length);
              attachRow(row);
              rows.add(row);
              selectedIndex = rows.length - 1;
            });
          }

          void deleteRow() {
            if (isClosing || rows.isEmpty || rows.length <= 1) return;
            setDialogState(() {
              final removed = rows.removeAt(selectedIndex);
              if (removed.originalName.isNotEmpty) {
                unawaited(c.deleteMaterial(removed.originalName));
              }
              saveTimers.remove(removed)?.cancel();
              disposeRowLater(removed);
              if (selectedIndex >= rows.length) selectedIndex = rows.length - 1;
            });
          }

          Future<void> closeDialog() async {
            if (isClosing) return;
            isClosing = true;
            await flushMaterialSaves();
            final selectedName = rows.isEmpty
                ? selectedMaterial
                : rows[selectedIndex].name;
            if (dialogNavigator.mounted && dialogNavigator.canPop()) {
              dialogNavigator.pop(selectedName);
            }
          }

          return Dialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            child: SizedBox(
              width: 920,
              height: 520,
              child: Column(
                children: [
                  _materialEditorTitle(context, onClose: closeDialog),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Column(
                        children: [
                          _materialEditorHeader(),
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFC8CCD1),
                                ),
                              ),
                              child: ListView.builder(
                                itemCount: rows.length,
                                itemBuilder: (context, index) {
                                  return _materialEditorRow(
                                    row: rows[index],
                                    index: index,
                                    selected: selectedIndex == index,
                                    onTap: () {
                                      if (isClosing) return;
                                      setDialogState(() {
                                        selectedIndex = index;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F2F2),
                      border: Border(top: BorderSide(color: Color(0xFFC8CCD1))),
                    ),
                    child: Row(
                      children: [
                        _materialFooterIcon(
                          icon: Icons.add,
                          tooltip: 'Add',
                          onPressed: isClosing ? null : addRow,
                        ),
                        const SizedBox(width: 4),
                        _materialFooterIcon(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete',
                          onPressed:
                              isClosing || rows.length <= 1 ? null : deleteRow,
                        ),
                        const Spacer(),
                        _dialogButton(
                          'Close',
                          () => unawaited(closeDialog()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    for (final timer in saveTimers.values) {
      timer.cancel();
    }
    for (final row in rows) {
      disposeRowLater(row);
    }
    return value;
  }

  Widget _materialEditorTitle(
    BuildContext context, {
    required Future<void> Function() onClose,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFEFEFEF),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Row(
        children: [
          const Text(
            'Casing Material Database Editor',
            style: TextStyle(fontSize: 12),
          ),
          const Spacer(),
          IconButton(
            splashRadius: 14,
            onPressed: () => unawaited(onClose()),
            icon: const Icon(Icons.close, size: 17),
          ),
        ],
      ),
    );
  }

  Widget _materialEditorHeader() {
    const headerStyle = TextStyle(fontSize: 10, color: Colors.black87);
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        border: Border.all(color: const Color(0xFFC8CCD1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 34, child: Center(child: Text(''))),
          SizedBox(
            width: 170,
            child: Center(child: Text('Material', style: headerStyle)),
          ),
          SizedBox(
            width: 110,
            child: Center(
              child: Text(
                c.displayMaterialHeader('Density', 'density'),
                style: headerStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Center(
              child: Text(
                c.displayMaterialHeader('E', 'elasticModulus'),
                style: headerStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(
            width: 92,
            child: Center(
              child: Text(
                'Y\n(-)',
                style: headerStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Center(
              child: Text(
                c.displayMaterialHeader('Comp.', 'compressibility'),
                style: headerStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Center(
              child: Text(
                c.displayMaterialHeader('Heat Cap.', 'heatCapacity'),
                style: headerStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                c.displayMaterialHeader(
                  'Therm. Con. Factor',
                  'thermalConductivity',
                ),
                style: headerStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialEditorRow({
    required _MaterialEditorRow row,
    required int index,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? const Color(0xFFDCE8F7) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        color: color,
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Center(
                child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
              ),
            ),
            _materialCell(row.nameController, width: 170),
            _materialCell(row.densityController, width: 110),
            _materialCell(row.elasticModulusController, width: 110),
            _materialCell(row.poissonRatioController, width: 92),
            _materialCell(row.compressibilityController, width: 130),
            _materialCell(row.heatCapacityController, width: 130),
            Expanded(child: _materialCell(row.thermalConductivityController)),
          ],
        ),
      ),
    );
  }

  Widget _materialCell(TextEditingController controller, {double? width}) {
    final child = Container(
      height: 28,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFFD3D6DA)),
          bottom: BorderSide(color: Color(0xFFD3D6DA)),
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 11),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none,
        ),
      ),
    );
    if (width == null) return child;
    return SizedBox(width: width, child: child);
  }

  Widget _materialFooterIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Icon(icon, size: 15),
        ),
      ),
    );
  }

  Future<bool?> _confirmMaterialDelete(String material) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Delete "$material"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _dialogTitle(BuildContext context, String title) {
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFEFEFEF),
        border: Border(bottom: BorderSide(color: Color(0xFFBFC5CC))),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
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

  Widget _dialogButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 96,
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(label),
      ),
    );
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
