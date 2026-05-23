import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

class TubularDbOption {
  TubularDbOption({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;

  factory TubularDbOption.fromJson(Map<String, dynamic> json) =>
      TubularDbOption(
        id: (json['_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class TubularDbColumn {
  const TubularDbColumn(this.key, this.label, {this.width = 96});

  final String key;
  final String label;
  final double width;
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
        text: values?[column.key] ?? '',
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
      column.key: value(column.key),
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
    TubularDbColumn('od', 'OD\n(in)', width: 76),
    TubularDbColumn('id', 'ID\n(in)', width: 76),
    TubularDbColumn('nominalWt', 'Nominal Wt.\n(lb/ft)', width: 96),
    TubularDbColumn('wallThickness', 'Wall Thickness\n(in)', width: 110),
    TubularDbColumn('driftId', 'Drift ID\n(in)', width: 86),
    TubularDbColumn('grade', 'Grade', width: 110),
    TubularDbColumn('yieldPsi', 'Yield\n(psi)', width: 88),
    TubularDbColumn('fatigueEndurance', 'Fatigue Endurance\n(psi)', width: 126),
    TubularDbColumn(
      'ultimateTensile',
      'Ultimate Tensile Str.\n(psi)',
      width: 132,
    ),
    TubularDbColumn('collapseStr', 'Collapse Str.\n(psi)', width: 104),
    TubularDbColumn('burstStr', 'Burst Str.\n(psi)', width: 96),
    TubularDbColumn('tensileStr', 'Tensile Str.\n(lbf)', width: 104),
    TubularDbColumn('compressiveStr', 'Compressive Str.\n(lbf)', width: 122),
    TubularDbColumn('torsionalStr', 'Torsional Str.\n(ft-lb)', width: 116),
    TubularDbColumn('makeupTorque', 'Make-up Torque\n(ft-lb)', width: 116),
    TubularDbColumn('assemblyAdjustWt', 'Adjust Wt.\n(lb/ft)', width: 112),
  ];

  final selectedTypeIndex = 0.obs;
  final selectedCatalogIndex = 0.obs;
  final selectedRowIndex = 0.obs;
  final types = <TubularDbOption>[].obs;
  final catalogs = <TubularDbOption>[].obs;
  final rows = <TubularDbRow>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final loadError = ''.obs;

  final String _baseUrl = ApiEndpoint.baseUrl;
  final Map<String, Timer> _saveTimers = {};
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

  @override
  void onInit() {
    super.onInit();
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
      _clampSelections();
    } catch (error) {
      loadError.value = error.toString();
      if (types.isEmpty && catalogs.isEmpty && rows.isEmpty) {
        _applyFallbackData();
      }
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

  void _applyFallbackData() {
    types.assignAll([
      TubularDbOption(id: '', name: 'CWS', sortOrder: 0),
      TubularDbOption(id: '', name: 'CWS w/ FICD', sortOrder: 1),
      TubularDbOption(id: '', name: 'ECL', sortOrder: 2),
      TubularDbOption(id: '', name: 'Drill Pipe Premium', sortOrder: 3),
      TubularDbOption(id: '', name: 'Heavy Weight DP', sortOrder: 4),
      TubularDbOption(id: '', name: 'Drill Collar', sortOrder: 5),
      TubularDbOption(id: '', name: 'Tubing', sortOrder: 6),
      TubularDbOption(id: '', name: 'Casing', sortOrder: 7),
    ]);
    catalogs.assignAll([
      TubularDbOption(id: '', name: 'Weatherford', sortOrder: 0),
    ]);
    final fallbackRows =
        [
          {
            'od': '2.720',
            'id': '1.995',
            'nominalWt': '0.000',
            'grade': 'Super weld',
            'yieldPsi': '33034',
            'tensileStr': '88690',
          },
          {
            'od': '2.730',
            'id': '1.995',
            'nominalWt': '0.000',
            'grade': 'Dura Grip',
            'yieldPsi': '32516',
            'tensileStr': '88690',
          },
          {
            'od': '3.080',
            'id': '1.995',
            'nominalWt': '0.000',
            'grade': 'Excelflo',
            'yieldPsi': '20508',
            'tensileStr': '88690',
          },
          {
            'od': '3.220',
            'id': '2.441',
            'nominalWt': '0.000',
            'grade': 'Super Weld',
            'yieldPsi': '35576',
            'tensileStr': '123220',
          },
        ].asMap().entries.map((entry) {
          final row = TubularDbRow(
            type: 'CWS',
            catalog: 'Weatherford',
            sortOrder: entry.key,
            values: entry.value,
          );
          _attachRowListeners(row);
          return row;
        }).toList();
    rows.assignAll(fallbackRows);
    _clampSelections();
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

  Future<void> addType(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}tubular-database/types'),
        headers: _headers,
        body: jsonEncode({'name': cleanName}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        types.add(TubularDbOption.fromJson(Map<String, dynamic>.from(data)));
        selectedTypeIndex.value = types.length - 1;
      }
    } catch (_) {
      types.add(
        TubularDbOption(id: '', name: cleanName, sortOrder: types.length),
      );
      selectedTypeIndex.value = types.length - 1;
    }
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
