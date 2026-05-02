import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class EmptyActiveSystemController extends GetxController {
  // Radio selection
  RxBool isDumpSelected = true.obs;

  // Unselected pits from API
  final unselectedPits = <PitModel>[].obs;

  // Table data - starts with 5 rows
  final pitValues = List<String>.generate(5, (_) => "").obs;
  final volValues = List<String>.generate(5, (_) => "").obs;
  final volControllers = <TextEditingController>[].obs;

  String? currentWellId;
  final List<Worker> _unitWorkers = [];
  late String _fluidVolumeUnit;

  @override
  void onInit() {
    super.onInit();
    _fluidVolumeUnit = AppUnits.fluidVolume;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(AppUnits.controller.selectedCustomSystemId, (_) => _handleUnitChange()),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
    currentWellId = Get.arguments?['wellId'] ?? currentBackendWellId;
    _syncVolumeControllers();
    fetchUnselectedPits();
  }

  @override
  void onClose() {
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    for (final controller in volControllers) {
      controller.dispose();
    }
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
    volValues.value[row] = value;
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
}
