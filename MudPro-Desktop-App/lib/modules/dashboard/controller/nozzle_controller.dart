import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/dashboard/model/nozzle_model.dart';

class NozzleController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;

  final entries = <NozzleEntry>[].obs;
  final tfa = 0.0.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  String? _savedId; // ID of currently saved nozzle record
  Timer? _debounceTimer;

  static const int _minRows = 3;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  void onInit() {
    super.onInit();
    _initEmptyRows();
    fetchNozzle();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  void _initEmptyRows() {
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
      if (entry.size32.value > 0) {
        final diameter = entry.size32.value / 32.0;
        final area = (3.141592653589793 * diameter * diameter) / 4.0;
        final totalArea = area * entry.count.value;

        entry.diameterInch.value = double.parse(diameter.toStringAsFixed(4));
        entry.area.value = double.parse(area.toStringAsFixed(4));
        total += totalArea;
      } else {
        entry.diameterInch.value = 0;
        entry.area.value = 0;
      }
    }
    tfa.value = double.parse(total.toStringAsFixed(4));
  }

  // Called on every cell change
  void onCellChanged(int rowIndex) {
    recalculateTfa();
    _ensureExtraRow();
    _scheduleAutoSave();
  }

  void _ensureExtraRow() {
    // Add new row if last row has data
    if (entries.isNotEmpty && entries.last.hasData) {
      entries.add(NozzleEntry());
    }
  }

  // ─── DEBOUNCED AUTO-SAVE (800ms after last change) ──────────────
  void _scheduleAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      await _saveToServer();
    });
  }

  // ─── FETCH ──────────────────────────────────────────────────────
  Future<void> fetchNozzle() async {
    try {
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('${baseUrl}nozzle'),
        headers: _headers,
      );

      print('Nozzle fetch: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        if (data.isNotEmpty) {
          final model = NozzleModel.fromJson(data.first);
          _savedId = model.id;
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
        }
      }
    } catch (e) {
      print('Nozzle fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── SAVE (POST if new, PUT if exists) ──────────────────────────
  Future<void> _saveToServer() async {
    final nozzlesWithData = entries.where((e) => e.hasData).toList();
    if (nozzlesWithData.isEmpty) return;

    try {
      isSaving.value = true;

      final body = jsonEncode({
        'nozzles': nozzlesWithData.map((e) => e.toJson()).toList(),
      });

      http.Response response;

      if (_savedId != null && _savedId!.isNotEmpty) {
        // UPDATE
        response = await http.put(
          Uri.parse('${baseUrl}nozzle/${_savedId}'),
          headers: _headers,
          body: body,
        );
      } else {
        // CREATE
        response = await http.post(
          Uri.parse('${baseUrl}nozzle/well'),
          headers: _headers,
          body: body,
        );
      }

      print('Nozzle save: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final model = NozzleModel.fromJson(json['data']);
        _savedId = model.id;
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