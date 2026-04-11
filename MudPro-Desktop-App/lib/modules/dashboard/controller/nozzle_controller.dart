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
  final tfa = 0.0.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  String? _savedId;
  Timer? _debounceTimer;
  Worker? _wellWorker;
  Worker? _reportWorker;

  static const int _minRows = 3;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String get _currentWellId => padWellContext.selectedWellId.value.trim();

  String? get _currentReportId {
    final reportId = reportContext.selectedReportId.value.trim();
    return reportId.isEmpty ? null : reportId;
  }

  String? get _currentReportNo {
    final reportNo = reportContext.selectedReportNumber.trim();
    return reportNo.isEmpty ? null : reportNo;
  }

  @override
  void onInit() {
    super.onInit();
    _resetState();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      fetchNozzle(forceReset: true);
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      fetchNozzle(forceReset: true);
    });
    fetchNozzle();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    super.onClose();
  }

  void _resetState() {
    entries.clear();
    for (int i = 0; i < _minRows; i++) {
      entries.add(NozzleEntry());
    }
    _savedId = null;
    tfa.value = 0;
  }

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

  void onCellChanged(int rowIndex) {
    recalculateTfa();
    _ensureExtraRow();
    _scheduleAutoSave();
  }

  void _ensureExtraRow() {
    if (entries.isNotEmpty && entries.last.hasData) {
      entries.add(NozzleEntry());
    }
  }

  void _scheduleAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      await _saveToServer();
    });
  }

  Future<void> fetchNozzle({bool forceReset = false}) async {
    if (_currentWellId.isEmpty) {
      _resetState();
      return;
    }

    try {
      isLoading.value = true;
      if (forceReset) {
        _savedId = null;
      }

      final uri = Uri.parse('${baseUrl}nozzle').replace(
        queryParameters: {
          'wellId': _currentWellId,
          if (_currentReportId != null) 'reportId': _currentReportId!,
          if (_currentReportNo != null) 'reportNo': _currentReportNo!,
        },
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        if (data.isEmpty) {
          _resetState();
          return;
        }

        final raw = data.first;
        final model = NozzleModel.fromJson(
          raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw as Map),
        );
        _savedId = model.id;
        tfa.value = model.tfa;

        entries.clear();
        entries.addAll(model.nozzles);
        while (entries.length < _minRows) {
          entries.add(NozzleEntry());
        }
        if (entries.isNotEmpty && entries.last.hasData) {
          entries.add(NozzleEntry());
        }
        return;
      }

      _resetState();
    } catch (e) {
      print('Nozzle fetch error: $e');
      _resetState();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveToServer() async {
    final nozzlesWithData = entries.where((e) => e.hasData).toList();
    if (nozzlesWithData.isEmpty || _currentWellId.isEmpty) return;

    try {
      isSaving.value = true;

      final body = jsonEncode({
        'wellId': _currentWellId,
        if (_currentReportId != null) 'reportId': _currentReportId,
        if (_currentReportNo != null) 'reportNo': _currentReportNo,
        'nozzles': nozzlesWithData.map((e) => e.toJson()).toList(),
      });

      final response = _savedId != null && _savedId!.isNotEmpty
          ? await http.put(
              Uri.parse('${baseUrl}nozzle/${_savedId!}'),
              headers: _headers,
              body: body,
            )
          : await http.post(
              Uri.parse('${baseUrl}nozzle/well'),
              headers: _headers,
              body: body,
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final model = NozzleModel.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
        _savedId = model.id;
        tfa.value = model.tfa;
      }
    } catch (e) {
      print('Nozzle save error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> saveNow() => _saveToServer();
}
