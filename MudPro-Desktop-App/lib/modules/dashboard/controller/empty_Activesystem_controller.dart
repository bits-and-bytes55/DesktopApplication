import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
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
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
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
        selectedPit.capacity.value.toStringAsFixed(2),
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

  double _toBackendBbl(String value) {
    final parsed = _parseVolume(value);
    if (parsed <= 0) return 0;
    if (_fluidVolumeUnit == '(bbl)') return parsed;
    return AppUnits.convertValue(parsed, _fluidVolumeUnit, '(bbl)') ?? parsed;
  }

  void _clearTransferRows() {
    pitValues.assignAll(List<String>.generate(5, (_) => ""));
    volValues.assignAll(List<String>.generate(5, (_) => ""));
    _syncVolumeControllers();
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
        _clearTransferRows();
        return;
      }

      final first = rows.first;
      if (first is! Map) return;
      final actionType = (first['actionType'] ?? '').toString();
      isDumpSelected.value = actionType != 'Transfer to Storage';
      if (isDumpSelected.value) {
        _clearTransferRows();
        return;
      }

      final pits = <String>[];
      final volumes = <String>[];
      for (final row in rows.whereType<Map>()) {
        final pitName = (row['pitName'] ?? '').toString().trim();
        if (pitName.isEmpty) continue;
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
      pitValues.assignAll(pits);
      volValues.assignAll(volumes);
      _syncVolumeControllers();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> saveEmptyActiveSystem() async {
    if (wellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }

    final body = isDumpSelected.value
        ? {
            'actionType': 'Dump',
            'volume': 0,
            'operationInstanceKey': instanceKey,
          }
        : {
            'actionType': 'Transfer to Storage',
            'operationInstanceKey': instanceKey,
            'transfers':
                List.generate(pitValues.length, (index) {
                      return {
                        'pitName': pitValues[index].trim(),
                        'volume': _toBackendBbl(volValues[index]),
                      };
                    })
                    .where(
                      (row) =>
                          (row['pitName'] as String).isNotEmpty &&
                          (row['volume'] as double) > 0,
                    )
                    .toList(),
          };

    if (!isDumpSelected.value && (body['transfers'] as List).isEmpty) {
      return {'success': false, 'message': 'Select storage and volume'};
    }

    final result = await _repository.createEmptyActiveSystem(wellId, body);
    if (result['success'] == true) {
      await load();
    }
    return result;
  }

  void clearLocalState() {
    isDumpSelected.value = true;
    _clearTransferRows();
  }
}
