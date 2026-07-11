import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class EmptyActiveSystemController extends GetxController {
  EmptyActiveSystemController({required this.instanceKey});

  final String instanceKey;
  final AuthRepository _repository = AuthRepository();

  // Radio selection
  RxBool isDumpSelected = true.obs;
  final isLoading = false.obs;

  // Unselected pits from API
  final unselectedPits = <PitModel>[].obs;

  // Table data - starts with 5 rows
  final pitValues = List<String>.generate(5, (_) => "").obs;
  final volValues = List<String>.generate(5, (_) => "").obs;
  final volControllers = <TextEditingController>[].obs;

  String? currentWellId;
  Worker? _wellWorker;
  Worker? _reportWorker;
  final List<Worker> _unitWorkers = [];
  late String _fluidVolumeUnit;
  double _loadedTransferTotalBbl = 0;

  String get wellId => currentBackendWellId.trim();

  @override
  void onInit() {
    super.onInit();
    _fluidVolumeUnit = AppUnits.fluidVolume;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
    currentWellId = Get.arguments?['wellId'] ?? wellId;
    _syncVolumeControllers();
    fetchUnselectedPits();
    load();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      currentWellId = wellId;
      fetchUnselectedPits();
      load();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) => load());
  }

  @override
  void onClose() {
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    for (final controller in volControllers) {
      controller.dispose();
    }
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    _unitWorkers.clear();
    super.onClose();
  }

  void _syncVolumeControllers() {
    while (volControllers.length < volValues.length) {
      final index = volControllers.length;
      volControllers.add(TextEditingController(text: volValues[index]));
    }
    while (volControllers.length > volValues.length) {
      volControllers.removeLast().dispose();
    }
    for (var i = 0; i < volControllers.length; i++) {
      final nextText = volValues[i];
      if (volControllers[i].text != nextText) {
        volControllers[i].text = nextText;
        volControllers[i].selection = TextSelection.collapsed(
          offset: nextText.length,
        );
      }
    }
  }

  void setVolume(int row, String value) {
    if (row < 0 || row >= volValues.length) return;
    volValues[row] = value;
  }

  String _formatConverted(double value) {
    return formatOperationNumber(
      value,
      fallbackDecimals: 4,
      trimFallback: true,
    );
  }

  String _convertText(String value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;
    final parsed = double.tryParse(value.trim().replaceAll(',', ''));
    if (parsed == null) return value;
    final result = AppUnits.convertValue(parsed, fromUnit, toUnit);
    return result == null ? value : _formatConverted(result);
  }

  void _handleUnitChange() {
    final nextFluidVolumeUnit = AppUnits.fluidVolume;
    if (_fluidVolumeUnit == nextFluidVolumeUnit) return;
    volValues.assignAll(
      volValues.map(
        (value) => _convertText(value, _fluidVolumeUnit, nextFluidVolumeUnit),
      ),
    );
    _syncVolumeControllers();
    _fluidVolumeUnit = nextFluidVolumeUnit;
  }

  bool get isTableEnabled => !isDumpSelected.value;

  // Fetch unselected pits from API
  Future<void> fetchUnselectedPits() async {
    if (currentWellId == null) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getUnselectedPits(currentWellId!);

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null && data is List) {
          if (data.isNotEmpty && data.first is PitModel) {
            unselectedPits.value = List<PitModel>.from(data);
          } else {
            unselectedPits.value = data
                .map((item) => PitModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } else {
          unselectedPits.clear();
        }
      }
    } catch (e) {
      print('Error fetching unselected pits: $e');
    }
  }

  // Set pit value and auto-fill capacity
  void setPit(int row, String pitName) {
    pitValues[row] = pitName;

    // Find the selected pit and auto-fill capacity
    final selectedPit = unselectedPits.firstWhereOrNull(
      (pit) => pit.pitName == pitName,
    );

    if (selectedPit != null) {
      volValues[row] = _convertText(
        formatOperationNumber(selectedPit.capacity.value),
        '(bbl)',
        _fluidVolumeUnit,
      );
      _syncVolumeControllers();
    }
  }

  // Add new row when last row is filled
  void addNewRow() {
    pitValues.add("");
    volValues.add("");
    _syncVolumeControllers();
  }

  // Demo adjust logic
  void adjustVolumes() {
    for (int i = 0; i < volValues.length; i++) {
      if (pitValues[i].isNotEmpty) {
        volValues[i] = _convertText("100.00", '(bbl)', _fluidVolumeUnit);
      }
    }
    _syncVolumeControllers();
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map && value['data'] is List) return value['data'] as List;
    return const [];
  }

  double _parseVolume(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          value?.toString().trim().replaceAll(',', '') ?? '',
        ) ??
        0;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  Map<String, dynamic> _volumePayloadFromResponse(dynamic value) {
    final envelope = _map(value);
    final data = _map(envelope['data']);
    if (data.containsKey('volumeName')) return data;
    final nested = _map(data['data']);
    if (nested.containsKey('volumeName')) return nested;
    return envelope.containsKey('volumeName') ? envelope : {};
  }

  double _dumpVolumeFromPayload(Map<String, dynamic> payload) {
    final volumeName = _map(payload['volumeName']);
    final endVol = _number(volumeName['endVol']);
    if (endVol > 0) return endVol;
    final activeSystem = _number(volumeName['activeSystem']);
    if (activeSystem > 0) return activeSystem;
    final activePits = _number(volumeName['activePits']);
    final hole = _number(volumeName['hole']);
    final fallback = activePits + hole;
    return fallback > 0 ? fallback : 0;
  }

  double _endVolFromPayload(Map<String, dynamic> payload) {
    final volumeName = _map(payload['volumeName']);
    return _number(volumeName['endVol']);
  }

  Future<double> _resolveEndVol() async {
    if (Get.isRegistered<PitController>()) {
      final current = Get.find<PitController>().volumeNameData;
      final currentEndVol = _endVolFromPayload(
        Map<String, dynamic>.from(current),
      );
      if (currentEndVol > 0) return currentEndVol;
    }

    final result = await _repository.getVolumeNameCalculation(wellId);
    if (result['success'] != true) return 0;
    return _endVolFromPayload(_volumePayloadFromResponse(result['data']));
  }

  Future<double> _resolveDumpVolume() async {
    if (Get.isRegistered<PitController>()) {
      final current = Get.find<PitController>().volumeNameData;
      final currentVolume = _dumpVolumeFromPayload(
        Map<String, dynamic>.from(current),
      );
      if (currentVolume > 0) return currentVolume;
    }

    final result = await _repository.getVolumeNameCalculation(wellId);
    if (result['success'] != true) return 0;
    return _dumpVolumeFromPayload(_volumePayloadFromResponse(result['data']));
  }

  Future<void> _refreshPitVolumeName() async {
    if (Get.isRegistered<PitController>()) {
      await Get.find<PitController>().fetchVolumeNameData();
    }
  }

  double _toBackendBbl(String value) {
    final parsed = _parseVolume(value);
    if (parsed <= 0) return 0;
    if (_fluidVolumeUnit == '(bbl)') return parsed;
    return AppUnits.convertValue(parsed, _fluidVolumeUnit, '(bbl)') ?? parsed;
  }

  void _clearTransferRows() {
    _loadedTransferTotalBbl = 0;
    pitValues.assignAll(List<String>.generate(5, (_) => ""));
    volValues.assignAll(List<String>.generate(5, (_) => ""));
    _syncVolumeControllers();
  }

  bool transferRowHasData(int index) {
    if (index < 0 || index >= pitValues.length) return false;
    return pitValues[index].trim().isNotEmpty ||
        volValues[index].trim().isNotEmpty;
  }

  void insertTransferRowAfter(int index) {
    final insertAt = (index + 1).clamp(0, pitValues.length).toInt();
    pitValues.insert(insertAt, '');
    volValues.insert(insertAt, '');
    _syncVolumeControllers();
  }

  List<Map<String, dynamic>> _transferPayloads() {
    return List.generate(pitValues.length, (index) {
      return {
        'rowNumber': index + 1,
        'pitName': pitValues[index].trim(),
        'volume': _toBackendBbl(volValues[index]),
      };
    }).where((row) {
      return (row['pitName'] as String).isNotEmpty &&
          (row['volume'] as double) > 0;
    }).toList();
  }

  Future<Map<String, dynamic>> _saveAfterTransferRowEdit() async {
    if (_transferPayloads().isEmpty) {
      final deleteResult = await _repository.deleteOperationData(
        wellId: wellId,
        operationType: 'emptyActiveSystem',
        operationInstanceKey: instanceKey,
      );
      if (deleteResult['success'] == true) {
        isDumpSelected.value = false;
        _clearTransferRows();
        await _refreshPitVolumeName();
      }
      return deleteResult;
    }
    return saveEmptyActiveSystem(allowEmptyTransferClear: true);
  }

  Future<Map<String, dynamic>> clearTransferRow(int index) async {
    if (index < 0 || index >= pitValues.length) {
      return {'success': false, 'message': 'Invalid row'};
    }
    pitValues[index] = '';
    volValues[index] = '';
    _syncVolumeControllers();
    return _saveAfterTransferRowEdit();
  }

  Future<Map<String, dynamic>> deleteTransferRow(int index) async {
    if (index < 0 || index >= pitValues.length) {
      return {'success': false, 'message': 'Invalid row'};
    }
    pitValues.removeAt(index);
    volValues.removeAt(index);
    while (pitValues.length < 5) {
      pitValues.add('');
      volValues.add('');
    }
    _syncVolumeControllers();
    return _saveAfterTransferRowEdit();
  }

  Future<void> load() async {
    if (wellId.isEmpty || isLoading.value) return;
    isLoading.value = true;
    try {
      final result = await _repository.getEmptyActiveSystemList(
        wellId,
        operationInstanceKey: instanceKey,
      );
      if (result['success'] != true) return;
      final rows = _extractList(result['data']);
      if (rows.isEmpty) {
        isDumpSelected.value = true;
        _loadedTransferTotalBbl = 0;
        _clearTransferRows();
        return;
      }

      final first = rows.first;
      if (first is! Map) return;
      final actionType = (first['actionType'] ?? '').toString();
      isDumpSelected.value = actionType != 'Transfer to Storage';
      if (isDumpSelected.value) {
        _loadedTransferTotalBbl = 0;
        _clearTransferRows();
        return;
      }

      final pits = <String>[];
      final volumes = <String>[];
      var loadedTotal = 0.0;
      final sortedRows = rows.whereType<Map>().toList()
        ..sort((a, b) {
          final aRow = _number(a['rowNumber']).toInt();
          final bRow = _number(b['rowNumber']).toInt();
          if (aRow != bRow) return aRow.compareTo(bRow);
          return _number(a['createdAt']).compareTo(_number(b['createdAt']));
        });
      for (final row in sortedRows) {
        final pitName = (row['pitName'] ?? '').toString().trim();
        if (pitName.isEmpty) continue;
        loadedTotal += _number(row['volume']);
        final volume = _convertText(
          (row['volume'] ?? '').toString(),
          '(bbl)',
          _fluidVolumeUnit,
        );
        pits.add(pitName);
        volumes.add(volume);
      }
      while (pits.length < 5) {
        pits.add('');
        volumes.add('');
      }
      _loadedTransferTotalBbl = loadedTotal;
      pitValues.assignAll(pits);
      volValues.assignAll(volumes);
      _syncVolumeControllers();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> saveEmptyActiveSystem({
    bool allowEmptyTransferClear = false,
  }) async {
    if (wellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }

    final dumpVolume = isDumpSelected.value ? await _resolveDumpVolume() : 0.0;
    if (isDumpSelected.value && dumpVolume <= 0) {
      await _refreshPitVolumeName();
      return {'success': true, 'message': 'End Vol already 0'};
    }

    final transfers = _transferPayloads();

    if (!isDumpSelected.value) {
      if (transfers.isEmpty) {
        if (!allowEmptyTransferClear) {
          return {'success': false, 'message': 'Select storage and volume'};
        }
        final deleteResult = await _repository.deleteOperationData(
          wellId: wellId,
          operationType: 'emptyActiveSystem',
          operationInstanceKey: instanceKey,
        );
        if (deleteResult['success'] == true) {
          _loadedTransferTotalBbl = 0;
          await load();
          await _refreshPitVolumeName();
        }
        return deleteResult;
      }

      final endVol = await _resolveEndVol();
      final availableEndVol = endVol + _loadedTransferTotalBbl;
      if (availableEndVol <= 0.005) {
        return {
          'success': false,
          'message': 'End Vol. is 0. Transfer to Storage cannot be executed.',
        };
      }

      final transferTotal = transfers.fold<double>(
        0,
        (sum, row) => sum + (row['volume'] as double),
      );
      if (transferTotal - availableEndVol > 0.005) {
        return {
          'success': false,
          'message':
              'Transfer volume cannot exceed End Vol. ${formatOperationNumber(availableEndVol)} bbl',
        };
      }
    }

    final body = isDumpSelected.value
        ? {
            'actionType': 'Dump',
            'volume': roundOperationNumber(dumpVolume),
            'operationInstanceKey': instanceKey,
          }
        : {
            'actionType': 'Transfer to Storage',
            'operationInstanceKey': instanceKey,
            'transfers': transfers,
          };

    final result = await _repository.createEmptyActiveSystem(wellId, body);
    if (result['success'] == true) {
      await load();
      await _refreshPitVolumeName();
    }
    return result;
  }

  void clearLocalState() {
    isDumpSelected.value = true;
    _clearTransferRows();
  }
}
