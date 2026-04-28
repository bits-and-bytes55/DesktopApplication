import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/dashboard/model/nozzle_model.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class NozzleController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;

  final entries = <NozzleEntry>[].obs;
  final bitType = ''.obs;
  final bitModel = ''.obs;
  final tfa = 0.0.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  String? _savedId; // ID of currently saved nozzle record
  Timer? _debounceTimer;
  Worker? _wellWorker;
  Worker? _reportWorker;
  int _loadGeneration = 0;

  static const int _minRows = 3;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _buildScopedUri(String path) {
    final queryParameters = <String, String>{};
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();

    if (wellId.isNotEmpty) {
      queryParameters['wellId'] = wellId;
    }
    if (reportId.isNotEmpty) {
      queryParameters['reportId'] = reportId;
    }

    return Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
  }

  Map<String, dynamic> _withScope(Map<String, dynamic> payload) {
    final body = Map<String, dynamic>.from(payload);
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();

    if (wellId.isNotEmpty) {
      body['wellId'] = wellId;
    }
    if (reportId.isNotEmpty) {
      body['reportId'] = reportId;
    }

    return body;
  }

  @override
  void onInit() {
    super.onInit();
    _initEmptyRows();
    _wellWorker = ever<String>(
      padWellContext.selectedWellId,
      (_) => fetchNozzle(resetBeforeLoad: true),
    );
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => fetchNozzle(resetBeforeLoad: true),
    );
    fetchNozzle();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    super.onClose();
  }

  void _initEmptyRows({bool clearSavedId = true}) {
    if (clearSavedId) {
      _savedId = null;
    }
    bitType.value = '';
    bitModel.value = '';
    tfa.value = 0;
    entries.clear();
    for (int i = 0; i < _minRows; i++) {
      entries.add(NozzleEntry());
    }
  }

  // ─── AUTO-CALCULATE TFA LOCALLY (same formula as backend) ───────
  // diameter = size32 / 32
  // area = (π × diameter²) / 4
  // totalArea per row = area × count
  // TFA = sum of all totalAreas
  void recalculateTfa() {
    double total = 0;
    for (final entry in entries) {
      if (entry.size32.value > 0 && entry.count.value > 0) {
        final diameter = entry.size32.value / 32.0;
        final rawArea = (3.141592653589793 * diameter * diameter) / 4.0;
        final area = double.parse(rawArea.toStringAsFixed(3));
        final totalArea = area * entry.count.value;

        entry.diameterInch.value = double.parse(diameter.toStringAsFixed(4));
        entry.area.value = area;
        total += totalArea;
      } else {
        entry.diameterInch.value = 0;
        entry.area.value = 0;
      }
    }
    tfa.value = double.parse(total.toStringAsFixed(3));
  }

  // Called on every cell change
  void onCellChanged(int rowIndex) {
    recalculateTfa();
    _ensureExtraRow();
    _scheduleAutoSave();
  }

  void onBitInfoChanged({String? type, String? model}) {
    if (type != null) {
      bitType.value = type;
    }
    if (model != null) {
      bitModel.value = model;
    }
    _scheduleAutoSave();
  }

  void _ensureExtraRow() {
    // Add new row if last row has data
    if (entries.isNotEmpty && entries.last.hasData) {
      entries.add(NozzleEntry());
    }
  }

  void clearRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= entries.length) return;
    entries[rowIndex].count.value = 0;
    entries[rowIndex].size32.value = 0;
    entries[rowIndex].diameterInch.value = 0;
    entries[rowIndex].area.value = 0;
    recalculateTfa();
    _ensureExtraRow();
    entries.refresh();
    _scheduleAutoSave();
  }

  Future<void> deleteRow(int rowIndex) async {
    if (rowIndex < 0 || rowIndex >= entries.length) return;
    entries.removeAt(rowIndex);
    while (entries.length < _minRows) {
      entries.add(NozzleEntry());
    }
    _ensureExtraRow();
    recalculateTfa();
    entries.refresh();
    await _saveToServer();
  }

  void moveRowToTop(int rowIndex) {
    if (rowIndex <= 0 || rowIndex >= entries.length) return;
    final entry = entries.removeAt(rowIndex);
    entries.insert(0, entry);
    _ensureExtraRow();
    recalculateTfa();
    entries.refresh();
    _scheduleAutoSave();
  }

  void moveRowToBottom(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= entries.length) return;
    final entry = entries.removeAt(rowIndex);
    final targetIndex = entries.isNotEmpty && !entries.last.hasData
        ? entries.length - 1
        : entries.length;
    entries.insert(targetIndex.clamp(0, entries.length), entry);
    _ensureExtraRow();
    recalculateTfa();
    entries.refresh();
    _scheduleAutoSave();
  }

  List<String> copyRow(int rowIndex) {
    final entry = entries[rowIndex];
    return [
      entry.count.value.toString(),
      entry.size32.value == 0 ? '' : entry.size32.value.toString(),
    ];
  }

  void pasteRow(int rowIndex, List<String> values) {
    while (entries.length <= rowIndex) {
      entries.add(NozzleEntry());
    }
    final entry = entries[rowIndex];
    final data = List<String>.from(values);
    while (data.length < 2) {
      data.add('');
    }
    entry.count.value = int.tryParse(data[0]) ?? 0;
    entry.size32.value = int.tryParse(data[1]) ?? 0;
    recalculateTfa();
    _ensureExtraRow();
    entries.refresh();
    _scheduleAutoSave();
  }

  // ─── DEBOUNCED AUTO-SAVE (800ms after last change) ──────────────
  void _scheduleAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      await _saveToServer();
    });
  }

  // ─── FETCH ──────────────────────────────────────────────────────
  Future<void> fetchNozzle({bool resetBeforeLoad = false}) async {
    final generation = ++_loadGeneration;
    if (resetBeforeLoad) {
      _debounceTimer?.cancel();
      _initEmptyRows();
    }

    try {
      isLoading.value = true;
      final response = await http.get(
        _buildScopedUri('nozzle'),
        headers: _headers,
      );

      if (generation != _loadGeneration) return;

      print('Nozzle fetch: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        if (data.isNotEmpty) {
          final model = NozzleModel.fromJson(data.first);
          _savedId = model.id;
          bitType.value = model.bitType;
          bitModel.value = model.bitModel;
          tfa.value = model.tfa;

          entries.clear();
          for (final n in model.nozzles) {
            entries.add(n);
          }
          // Ensure minimum rows
          while (entries.length < _minRows) {
            entries.add(NozzleEntry());
          }
          // Add trailing empty row if last has data
          if (entries.isNotEmpty && entries.last.hasData) {
            entries.add(NozzleEntry());
          }
        } else {
          _initEmptyRows();
        }
      }
    } catch (e) {
      print('Nozzle fetch error: $e');
    } finally {
      if (generation == _loadGeneration) {
        isLoading.value = false;
      }
    }
  }

  // ─── SAVE (POST if new, PUT if exists) ──────────────────────────
  Future<void> _saveToServer() async {
    final nozzlesWithData = entries.where((e) => e.hasData).toList();
    final hasBitInfo =
        bitType.value.trim().isNotEmpty || bitModel.value.trim().isNotEmpty;
    if (nozzlesWithData.isEmpty &&
        !hasBitInfo &&
        (_savedId == null || _savedId!.isEmpty)) {
      tfa.value = 0;
      return;
    }

    try {
      isSaving.value = true;

      final body = jsonEncode(
        _withScope({
          'bitType': bitType.value.trim(),
          'bitModel': bitModel.value.trim(),
          'nozzles': nozzlesWithData.map((e) => e.toJson()).toList(),
        }),
      );

      http.Response response;

      if (_savedId != null && _savedId!.isNotEmpty) {
        // UPDATE
        response = await http.put(
          _buildScopedUri('nozzle/${_savedId}'),
          headers: _headers,
          body: body,
        );
      } else {
        // CREATE
        response = await http.post(
          _buildScopedUri('nozzle/well'),
          headers: _headers,
          body: body,
        );
      }

      print('Nozzle save: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final model = NozzleModel.fromJson(json['data']);
        _savedId = model.id;
        bitType.value = model.bitType;
        bitModel.value = model.bitModel;
        // Update TFA from server response (authoritative)
        tfa.value = model.tfa;
      }
    } catch (e) {
      print('Nozzle save error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // Public method to trigger manual save if needed
  Future<void> saveNow() => _saveToServer();
}
