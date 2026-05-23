import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class TubularDbOption {
  TubularDbOption({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.material = '',
  });

  final String id;
  final String name;
  final int sortOrder;
  final String material;

  factory TubularDbOption.fromJson(Map<String, dynamic> json) =>
      TubularDbOption(
        id: (json['_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        material: (json['material'] ?? '').toString(),
      );
}

class TubularDbColumn {
  const TubularDbColumn(
    this.key,
    this.label, {
    this.width = 96,
    this.baseUnit = '',
    this.group = 'Body',
  });

  final String key;
  final String label;
  final double width;
  final String baseUnit;
  final String group;
}

class TubularDbRow {
  TubularDbRow({
    this.id,
    required this.type,
    required this.catalog,
    required this.sortOrder,
    Map<String, String>? values,
  }) {
    for (final column in TabularDatabaseEditorController.columns) {
      controllers[column.key] = TextEditingController(
        text: TabularDatabaseEditorController.displayValueFromBase(
          column.key,
          values?[column.key] ?? '',
        ),
      );
    }
  }

  String? id;
  String type;
  String catalog;
  int sortOrder;
  final Map<String, TextEditingController> controllers = {};

  String value(String key) => controllers[key]?.text.trim() ?? '';

  bool get hasContent =>
      controllers.values.any((controller) => controller.text.trim().isNotEmpty);

  Map<String, dynamic> toJson() => {
    'type': type,
    'catalog': catalog,
    'sortOrder': sortOrder,
    for (final column in TabularDatabaseEditorController.columns)
      column.key: TabularDatabaseEditorController.baseValueFromDisplay(
        column.key,
        value(column.key),
      ),
  };

  factory TubularDbRow.fromJson(Map<String, dynamic> json) => TubularDbRow(
    id: (json['_id'] ?? '').toString(),
    type: (json['type'] ?? '').toString(),
    catalog: (json['catalog'] ?? '').toString(),
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    values: {
      for (final column in TabularDatabaseEditorController.columns)
        column.key: (json[column.key] ?? '').toString(),
    },
  );

  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }
}

class TabularDatabaseEditorController extends GetxController {
  static const columns = <TubularDbColumn>[
    TubularDbColumn('od', 'OD\n(in)', width: 76, baseUnit: 'in'),
    TubularDbColumn('id', 'ID\n(in)', width: 76, baseUnit: 'in'),
    TubularDbColumn(
      'nominalWt',
      'Nominal Wt.\n(lb/ft)',
      width: 96,
      baseUnit: 'lb/ft',
    ),
    TubularDbColumn(
      'wallThickness',
      'Wall Thickness\n(in)',
      width: 110,
      baseUnit: 'in',
    ),
    TubularDbColumn('driftId', 'Drift ID\n(in)', width: 86, baseUnit: 'in'),
    TubularDbColumn('grade', 'Grade', width: 110),
    TubularDbColumn('yieldPsi', 'Yield\n(psi)', width: 88, baseUnit: 'psi'),
    TubularDbColumn(
      'fatigueEndurance',
      'Fatigue Endurance\n(psi)',
      width: 126,
      baseUnit: 'psi',
    ),
    TubularDbColumn(
      'ultimateTensile',
      'Ultimate Tensile Str.\n(psi)',
      width: 132,
      baseUnit: 'psi',
    ),
    TubularDbColumn(
      'collapseStr',
      'Collapse Str.\n(psi)',
      width: 104,
      baseUnit: 'psi',
    ),
    TubularDbColumn(
      'burstStr',
      'Burst Str.\n(psi)',
      width: 96,
      baseUnit: 'psi',
    ),
    TubularDbColumn(
      'tensileStr',
      'Tensile Str.\n(lbf)',
      width: 104,
      baseUnit: 'lbf',
    ),
    TubularDbColumn(
      'compressiveStr',
      'Compressive Str.\n(lbf)',
      width: 122,
      baseUnit: 'lbf',
    ),
    TubularDbColumn(
      'torsionalStr',
      'Torsional Str.\n(ft-lb)',
      width: 116,
      baseUnit: 'ft-lb',
    ),
    TubularDbColumn('connectionType', 'Type', width: 110, group: 'Connection'),
    TubularDbColumn(
      'connectionOd',
      'OD\n(in)',
      width: 86,
      baseUnit: 'in',
      group: 'Connection',
    ),
    TubularDbColumn(
      'connectionId',
      'ID\n(in)',
      width: 86,
      baseUnit: 'in',
      group: 'Connection',
    ),
    TubularDbColumn(
      'connectionGrade',
      'Grade',
      width: 110,
      group: 'Connection',
    ),
    TubularDbColumn(
      'connectionYield',
      'Yield\n(psi)',
      width: 88,
      baseUnit: 'psi',
      group: 'Connection',
    ),
    TubularDbColumn(
      'connectionUts',
      'UTS\n(psi)',
      width: 88,
      baseUnit: 'psi',
      group: 'Connection',
    ),
    TubularDbColumn(
      'connectionBurst',
      'Burst Str.\n(psi)',
      width: 96,
      baseUnit: 'psi',
      group: 'Connection',
    ),
    TubularDbColumn(
      'connectionTensile',
      'Tensile Str.\n(lbf)',
      width: 104,
      baseUnit: 'lbf',
      group: 'Connection',
    ),
    TubularDbColumn(
      'connectionCompressive',
      'Compressive Str.\n(lbf)',
      width: 122,
      baseUnit: 'lbf',
      group: 'Connection',
    ),
    TubularDbColumn(
      'connectionTorsional',
      'Torsional Str.\n(ft-lb)',
      width: 116,
      baseUnit: 'ft-lb',
      group: 'Connection',
    ),
    TubularDbColumn(
      'makeupTorque',
      'Make-up Torque\n(ft-lb)',
      width: 116,
      baseUnit: 'ft-lb',
      group: 'Connection',
    ),
    TubularDbColumn(
      'assemblyAdjustWt',
      'Adjust Wt.\n(lb/ft)',
      width: 112,
      baseUnit: 'lb/ft',
      group: 'Assembly',
    ),
  ];

  final selectedTypeIndex = 0.obs;
  final selectedCatalogIndex = 0.obs;
  final selectedRowIndex = 0.obs;
  final types = <TubularDbOption>[].obs;
  final catalogs = <TubularDbOption>[].obs;
  final materials = <TubularDbOption>[].obs;
  final rows = <TubularDbRow>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final loadError = ''.obs;
  final unitSignature = ''.obs;

  final String _baseUrl = ApiEndpoint.baseUrl;
  final Map<String, Timer> _saveTimers = {};
  final List<Worker> _unitWorkers = <Worker>[];
  late Map<String, String> _displayUnitsByBase;
  bool _isApplyingState = false;

  Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

  List<TubularDbRow> get currentRows {
    final typeName = selectedTypeName;
    final catalogName = selectedCatalogName;
    return rows
        .where((row) => row.type == typeName && row.catalog == catalogName)
        .toList()
      ..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        if (bySort != 0) return bySort;
        return (a.id ?? '').compareTo(b.id ?? '');
      });
  }

  int _safeIndex(int value, int length) {
    if (length <= 0) return 0;
    if (value < 0) return 0;
    if (value >= length) return length - 1;
    return value;
  }

  String get selectedTypeName => types.isEmpty
      ? ''
      : types[_safeIndex(selectedTypeIndex.value, types.length)].name;

  String get selectedCatalogName => catalogs.isEmpty
      ? ''
      : catalogs[_safeIndex(selectedCatalogIndex.value, catalogs.length)].name;

  double get totalTableWidth =>
      42 + columns.fold<double>(0, (total, column) => total + column.width);

  static String baseUnitForKey(String key) {
    return columns
        .firstWhere(
          (column) => column.key == key,
          orElse: () => const TubularDbColumn('', ''),
        )
        .baseUnit;
  }

  static String displayUnitForBase(String baseUnit) {
    switch (baseUnit) {
      case 'in':
        return AppUnits.unitText('in');
      case 'lb/ft':
        return AppUnits.unitText('lb/ft');
      case 'psi':
        return AppUnits.unitText('psi');
      case 'lbf':
        return AppUnits.unitText('lbf');
      case 'ft-lb':
        return AppUnits.unitText('ft-lb');
      default:
        return '';
    }
  }

  static String displayValueFromBase(String key, String rawValue) {
    final baseUnit = baseUnitForKey(key);
    if (baseUnit.isEmpty) return rawValue;
    return _convertText(rawValue, baseUnit, displayUnitForBase(baseUnit));
  }

  static String baseValueFromDisplay(String key, String rawValue) {
    final baseUnit = baseUnitForKey(key);
    if (baseUnit.isEmpty) return rawValue;
    return _convertText(rawValue, displayUnitForBase(baseUnit), baseUnit);
  }

  static String _convertText(String rawValue, String fromUnit, String toUnit) {
    final text = rawValue.trim();
    if (text.isEmpty || fromUnit == toUnit) return rawValue;
    final parsed = double.tryParse(text.replaceAll(',', ''));
    if (parsed == null) return rawValue;
    final converted = AppUnits.convertValue(parsed, fromUnit, toUnit) ?? parsed;
    return converted
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Map<String, String> _currentDisplayUnits() => {
    'in': displayUnitForBase('in'),
    'lb/ft': displayUnitForBase('lb/ft'),
    'psi': displayUnitForBase('psi'),
    'lbf': displayUnitForBase('lbf'),
    'ft-lb': displayUnitForBase('ft-lb'),
  };

  String get diameterUnitLabel => AppUnits.strip(displayUnitForBase('in'));
  String get lineDensityUnitLabel =>
      AppUnits.strip(displayUnitForBase('lb/ft'));
  String get pressureUnitLabel => AppUnits.strip(displayUnitForBase('psi'));
  String get forceUnitLabel => AppUnits.strip(displayUnitForBase('lbf'));
  String get torqueUnitLabel => AppUnits.strip(displayUnitForBase('ft-lb'));

  String displayHeader(TubularDbColumn column) {
    final baseUnit = column.baseUnit;
    if (baseUnit.isEmpty) return column.label;
    final label = column.label.split('\n').first;
    return '$label\n(${AppUnits.strip(displayUnitForBase(baseUnit))})';
  }

  String get selectedTypeMaterial {
    if (types.isEmpty) {
      return materials.isEmpty ? 'Steel' : materials.first.name;
    }
    final type = types[_safeIndex(selectedTypeIndex.value, types.length)];
    if (type.material.trim().isNotEmpty) return type.material;
    return materials.isEmpty ? 'Steel' : materials.first.name;
  }

  List<String> distinctValues(String key) {
    final seen = <String>{};
    final values = <String>[];
    for (final row in currentRows) {
      final value = row.value(key);
      if (value.isEmpty || seen.contains(value)) continue;
      seen.add(value);
      values.add(value);
    }
    return values;
  }

  int firstRowIndexForValue(String key, String value) {
    final visibleRows = currentRows;
    return visibleRows.indexWhere((row) => row.value(key) == value);
  }

  String rowBaseValue(TubularDbRow row, String key) =>
      baseValueFromDisplay(key, row.value(key));

  @override
  void onInit() {
    super.onInit();
    unitSignature.value = AppUnits.signature;
    _displayUnitsByBase = _currentDisplayUnits();
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
    fetchDatabase();
  }

  Future<void> fetchDatabase() async {
    isLoading.value = true;
    loadError.value = '';
    _isApplyingState = true;
    _cancelSaveTimers();
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}tubular-database'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load tubular database');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      _replaceOptions(data);
      _replaceRows(data);
      _displayUnitsByBase = _currentDisplayUnits();
      unitSignature.value = AppUnits.signature;
      _clampSelections();
    } catch (error) {
      loadError.value = error.toString();
    } finally {
      _isApplyingState = false;
      isLoading.value = false;
    }
  }

  void _replaceOptions(Map<String, dynamic> data) {
    types.assignAll(
      ((data['types'] as List?) ?? []).whereType<Map>().map(
        (item) => TubularDbOption.fromJson(Map<String, dynamic>.from(item)),
      ),
    );
    catalogs.assignAll(
      ((data['catalogs'] as List?) ?? []).whereType<Map>().map(
        (item) => TubularDbOption.fromJson(Map<String, dynamic>.from(item)),
      ),
    );
    materials.assignAll(
      ((data['materials'] as List?) ?? []).whereType<Map>().map(
        (item) => TubularDbOption.fromJson(Map<String, dynamic>.from(item)),
      ),
    );
  }

  void _replaceRows(Map<String, dynamic> data) {
    for (final row in rows) {
      row.dispose();
    }
    rows.clear();
    final nextRows = ((data['rows'] as List?) ?? [])
        .whereType<Map>()
        .map((item) => TubularDbRow.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    for (final row in nextRows) {
      _attachRowListeners(row);
    }
    rows.assignAll(nextRows);
  }

  void _clampSelections() {
    if (types.isEmpty) {
      selectedTypeIndex.value = 0;
    } else if (selectedTypeIndex.value >= types.length) {
      selectedTypeIndex.value = types.length - 1;
    }

    if (catalogs.isEmpty) {
      selectedCatalogIndex.value = 0;
    } else if (selectedCatalogIndex.value >= catalogs.length) {
      selectedCatalogIndex.value = catalogs.length - 1;
    }

    final rowCount = currentRows.length;
    if (rowCount == 0) {
      selectedRowIndex.value = 0;
    } else if (selectedRowIndex.value >= rowCount) {
      selectedRowIndex.value = rowCount - 1;
    }
  }

  void selectType(int index) {
    if (index < 0 || index >= types.length) return;
    selectedTypeIndex.value = index;
    selectedRowIndex.value = 0;
    rows.refresh();
  }

  void selectCatalog(int index) {
    if (index < 0 || index >= catalogs.length) return;
    selectedCatalogIndex.value = index;
    selectedRowIndex.value = 0;
    rows.refresh();
  }

  void selectRow(int index) {
    if (index < 0 || index >= currentRows.length) return;
    selectedRowIndex.value = index;
  }

  Future<void> addType(String name, {String material = 'Steel'}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final cleanMaterial = material.trim().isEmpty ? 'Steel' : material.trim();
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}tubular-database/types'),
        headers: _headers,
        body: jsonEncode({'name': cleanName, 'material': cleanMaterial}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        types.add(TubularDbOption.fromJson(Map<String, dynamic>.from(data)));
        selectedTypeIndex.value = types.length - 1;
      }
    } catch (_) {
      types.add(
        TubularDbOption(
          id: '',
          name: cleanName,
          material: cleanMaterial,
          sortOrder: types.length,
        ),
      );
      selectedTypeIndex.value = types.length - 1;
    }
  }

  Future<void> addMaterial(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    if (materials.any(
      (item) => item.name.toLowerCase() == cleanName.toLowerCase(),
    )) {
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}tubular-database/materials'),
        headers: _headers,
        body: jsonEncode({'name': cleanName}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        materials.add(
          TubularDbOption.fromJson(Map<String, dynamic>.from(data)),
        );
        return;
      }
    } catch (_) {}
    materials.add(
      TubularDbOption(id: '', name: cleanName, sortOrder: materials.length),
    );
  }

  Future<void> deleteSelectedType() async {
    if (types.isEmpty) return;
    final option = types[_safeIndex(selectedTypeIndex.value, types.length)];
    if (option.id.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('${_baseUrl}tubular-database/types/${option.id}'),
          headers: _headers,
        );
      } catch (_) {}
    }
    for (final row in rows.where((row) => row.type == option.name)) {
      row.dispose();
    }
    rows.removeWhere((row) => row.type == option.name);
    types.removeAt(_safeIndex(selectedTypeIndex.value, types.length));
    _clampSelections();
  }

  Future<void> addCatalog(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}tubular-database/catalogs'),
        headers: _headers,
        body: jsonEncode({'name': cleanName}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        catalogs.add(TubularDbOption.fromJson(Map<String, dynamic>.from(data)));
        selectedCatalogIndex.value = catalogs.length - 1;
      }
    } catch (_) {
      catalogs.add(
        TubularDbOption(id: '', name: cleanName, sortOrder: catalogs.length),
      );
      selectedCatalogIndex.value = catalogs.length - 1;
    }
  }

  Future<void> deleteSelectedCatalog() async {
    if (catalogs.isEmpty) return;
    final option =
        catalogs[_safeIndex(selectedCatalogIndex.value, catalogs.length)];
    if (option.id.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('${_baseUrl}tubular-database/catalogs/${option.id}'),
          headers: _headers,
        );
      } catch (_) {}
    }
    for (final row in rows.where((row) => row.catalog == option.name)) {
      row.dispose();
    }
    rows.removeWhere((row) => row.catalog == option.name);
    catalogs.removeAt(_safeIndex(selectedCatalogIndex.value, catalogs.length));
    _clampSelections();
  }

  Future<void> addRow() async {
    if (selectedTypeName.isEmpty || selectedCatalogName.isEmpty) return;
    final row = TubularDbRow(
      type: selectedTypeName,
      catalog: selectedCatalogName,
      sortOrder: currentRows.length,
    );
    _attachRowListeners(row);
    rows.add(row);
    selectedRowIndex.value = currentRows.length - 1;
    await saveRow(row, immediate: true);
  }

  Future<void> deleteSelectedRow() async {
    final visibleRows = currentRows;
    if (visibleRows.isEmpty) return;
    final row =
        visibleRows[_safeIndex(selectedRowIndex.value, visibleRows.length)];
    final rowId = row.id ?? '';
    _saveTimers.remove(_rowKey(row))?.cancel();
    if (rowId.isNotEmpty) {
      try {
        await http.delete(
          Uri.parse('${_baseUrl}tubular-database/rows/$rowId'),
          headers: _headers,
        );
      } catch (_) {}
    }
    rows.remove(row);
    row.dispose();
    _clampSelections();
  }

  void _attachRowListeners(TubularDbRow row) {
    for (final controller in row.controllers.values) {
      controller.addListener(() => _scheduleRowSave(row));
    }
  }

  void _handleUnitChange() {
    final nextUnits = _currentDisplayUnits();
    if (_sameUnits(_displayUnitsByBase, nextUnits)) return;

    _isApplyingState = true;
    try {
      for (final row in rows) {
        for (final column in columns) {
          final baseUnit = column.baseUnit;
          if (baseUnit.isEmpty) continue;
          final controller = row.controllers[column.key];
          if (controller == null) continue;
          final oldUnit = _displayUnitsByBase[baseUnit] ?? baseUnit;
          final newUnit = nextUnits[baseUnit] ?? baseUnit;
          controller.text = _convertText(controller.text, oldUnit, newUnit);
        }
      }
      _displayUnitsByBase = nextUnits;
      unitSignature.value = AppUnits.signature;
      rows.refresh();
    } finally {
      _isApplyingState = false;
    }
  }

  bool _sameUnits(Map<String, String> oldUnits, Map<String, String> nextUnits) {
    if (oldUnits.length != nextUnits.length) return false;
    for (final entry in nextUnits.entries) {
      if (oldUnits[entry.key] != entry.value) return false;
    }
    return true;
  }

  void _scheduleRowSave(TubularDbRow row) {
    if (_isApplyingState || isLoading.value) return;
    final key = _rowKey(row);
    _saveTimers[key]?.cancel();
    _saveTimers[key] = Timer(const Duration(milliseconds: 700), () {
      saveRow(row);
    });
  }

  String _rowKey(TubularDbRow row) => row.id?.isNotEmpty == true
      ? row.id!
      : '${row.type}_${row.catalog}_${identityHashCode(row)}';

  Future<void> saveRow(TubularDbRow row, {bool immediate = false}) async {
    if (!immediate && !row.hasContent && (row.id ?? '').isEmpty) return;

    isSaving.value = true;
    try {
      final rowId = row.id ?? '';
      final response = rowId.isEmpty
          ? await http.post(
              Uri.parse('${_baseUrl}tubular-database/rows'),
              headers: _headers,
              body: jsonEncode(row.toJson()),
            )
          : await http.put(
              Uri.parse('${_baseUrl}tubular-database/rows/$rowId'),
              headers: _headers,
              body: jsonEncode(row.toJson()),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        final savedId = (data?['_id'] ?? '').toString();
        if (savedId.isNotEmpty) row.id = savedId;
      }
    } catch (error) {
      loadError.value = error.toString();
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveAllNow() async {
    _cancelSaveTimers();
    final pendingRows = rows
        .where((row) => row.hasContent || (row.id ?? '').isNotEmpty)
        .toList();
    for (var i = 0; i < pendingRows.length; i++) {
      pendingRows[i].sortOrder = i;
      await saveRow(pendingRows[i], immediate: true);
    }
    rows.refresh();
  }

  TubularDbRow? selectedVisibleRow() {
    final visibleRows = currentRows;
    if (visibleRows.isEmpty) return null;
    return visibleRows[_safeIndex(selectedRowIndex.value, visibleRows.length)];
  }

  @override
  void onClose() {
    _cancelSaveTimers();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    for (final row in rows) {
      row.dispose();
    }
    super.onClose();
  }

  void _cancelSaveTimers() {
    for (final timer in _saveTimers.values) {
      timer.cancel();
    }
    _saveTimers.clear();
  }
}
