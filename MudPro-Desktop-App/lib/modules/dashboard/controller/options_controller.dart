import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:mudpro_desktop_app/modules/options/model/unit_system_model.dart';
import 'package:mudpro_desktop_app/modules/options/services/unit_system_api_service.dart';
import 'package:mudpro_desktop_app/modules/options/unit_conversion_service.dart';
import 'package:mudpro_desktop_app/modules/options/unit_definitions.dart';

const Duration _kDebounce = Duration(milliseconds: 600);

class OptionsController extends GetxController {
  final _api = UnitSystemApiService();
  final _conv = UnitConversionService.instance;

  final selectedTab = 0.obs;
  final unitSystem = UnitSystem.us.obs;

  final selectedCustomSystemId = ''.obs;
  final selectedCustomSystem = 'Pegasus Default 1'.obs;

  final unitSystems = <UnitSystemModel>[].obs;
  final unitSystemNames = <String>[].obs;
  final customUnits = <String, String>{}.obs;

  final isLoadingSystems = false.obs;
  final isSavingSystem = false.obs;
  final errorMessage = ''.obs;

  final _debounceTimers = <String, Timer>{};

  static const List<Map<String, String>> parameters =
      UnitDefinitions.parameters;
  static const Map<String, String> _usDefaults = UnitDefinitions.usDefaults;
  static const Map<String, String> _siDefaults = UnitDefinitions.siDefaults;

  @override
  void onInit() {
    super.onInit();
    fetchAllUnitSystems();
  }

  @override
  void onClose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    super.onClose();
  }

  Future<void> fetchAllUnitSystems() async {
    isLoadingSystems.value = true;
    errorMessage.value = '';

    final response = await _api.fetchAll();
    isLoadingSystems.value = false;

    if (!response.success) {
      errorMessage.value = response.message ?? 'Failed to load unit systems';
      debugPrint('[OptionsCtrl] fetchAll error: ${response.message}');
      return;
    }

    final normalizedSystems = _normalizeSystems(response.data);
    unitSystems.value = normalizedSystems;
    unitSystemNames.value = normalizedSystems
        .map((system) => system.name)
        .toList()
        .cast<String>();

    if (selectedCustomSystemId.isEmpty && normalizedSystems.isNotEmpty) {
      _selectSystem(normalizedSystems.first);
    }
  }

  void selectUnitSystem(UnitSystemModel system) => _selectSystem(system);

  void selectUnitSystemByName(String name) {
    final lower = name.trim().toLowerCase();
    final found = unitSystems.firstWhereOrNull(
      (system) => system.name.trim().toLowerCase() == lower,
    );
    if (found != null) {
      _selectSystem(found);
    }
  }

  void _selectSystem(UnitSystemModel system) {
    selectedCustomSystemId.value = system.id;
    selectedCustomSystem.value = system.name;
    _loadUnitsFromSystem(system);
  }

  void _loadUnitsFromSystem(UnitSystemModel system) {
    final map = <String, String>{};
    for (final parameter in parameters) {
      final number = parameter['number']!;
      final existing = system.parameters.firstWhereOrNull(
        (entry) => entry.number == number,
      );
      map[number] = _validatedUnitForSystem(
        system,
        number,
        existing?.unit ?? '',
      );
    }
    customUnits.value = map;
  }

  List<UnitSystemModel> _normalizeSystems(List<UnitSystemModel> systems) {
    return systems.map(_normalizeSystem).toList();
  }

  UnitSystemModel _normalizeSystem(UnitSystemModel system) {
    final rawUnits = <String, String>{};
    for (final parameter in system.parameters) {
      rawUnits[parameter.number] = parameter.unit;
    }

    final normalizedParameters = parameters
        .map(
          (parameter) => ParameterUnit(
            number: parameter['number']!,
            name: parameter['name']!,
            unit: _validatedUnitForSystem(
              system,
              parameter['number']!,
              rawUnits[parameter['number']!] ?? '',
            ),
          ),
        )
        .toList();

    return UnitSystemModel(
      id: system.id,
      name: system.name,
      baseTemplate: system.baseTemplate,
      parameters: normalizedParameters,
      sortOrder: system.sortOrder,
    );
  }

  String _validatedUnitForSystem(
    UnitSystemModel system,
    String paramNumber,
    String rawUnit,
  ) {
    final knownDefaults = UnitDefinitions.templateDefaultsForName(system.name);
    if (knownDefaults != null) {
      return knownDefaults[paramNumber] ??
          UnitDefinitions.defaultUnitFor(
            paramNumber,
            baseTemplate: system.baseTemplate,
            systemName: system.name,
          );
    }

    final canonical = UnitDefinitions.canonicalizeDisplayUnit(rawUnit);
    if (UnitDefinitions.isAllowedUnit(paramNumber, canonical)) {
      return canonical;
    }

    return UnitDefinitions.defaultUnitFor(
      paramNumber,
      baseTemplate: system.baseTemplate,
      systemName: system.name,
    );
  }

  String getUnit(int index) {
    final number = parameters[index]['number']!;

    switch (unitSystem.value) {
      case UnitSystem.customized:
        return customUnits[number] ??
            UnitDefinitions.defaultUnitFor(
              number,
              systemName: selectedCustomSystem.value,
            );

      case UnitSystem.us:
        final system = _findSystemByAny([
          'us',
          'us oil field',
          'pegasus default',
        ]);
        final unit = system?.unitFor(number) ?? '';
        return unit.isNotEmpty ? unit : (_usDefaults[number] ?? '-');

      case UnitSystem.si:
        final system = _findSystemByAny(['si', 'metric', 'si metric']);
        final unit = system?.unitFor(number) ?? '';
        return unit.isNotEmpty ? unit : (_siDefaults[number] ?? '-');
    }
  }

  String unitForNumber(String paramNumber) {
    final index = parameters.indexWhere(
      (item) => item['number'] == paramNumber,
    );
    if (index == -1) {
      return '-';
    }
    return getUnit(index);
  }

  String get activeUnitSystemLabel {
    switch (unitSystem.value) {
      case UnitSystem.us:
        return 'US';
      case UnitSystem.si:
        return 'SI';
      case UnitSystem.customized:
        return selectedCustomSystem.value.isEmpty
            ? 'Customized'
            : selectedCustomSystem.value;
    }
  }

  String get activeUnitSignature {
    final entries = customUnits.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final serialized = entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join('|');
    return '${unitSystem.value.name}|${selectedCustomSystemId.value}|$serialized';
  }

  UnitSystemModel? _findSystemByAny(List<String> lowerNames) {
    for (final system in unitSystems) {
      final name = system.name.trim().toLowerCase();
      if (lowerNames.contains(name)) {
        return system;
      }
    }
    return null;
  }

  List<String> getUnitsForParam(String paramNumber) =>
      UnitDefinitions.parameterUnits[paramNumber] ?? [];

  String convertValue({
    required String rawValue,
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) {
      return rawValue;
    }
    final value = double.tryParse(rawValue);
    if (value == null) {
      return rawValue;
    }

    final result = _conv.convertValue(value, fromUnit, toUnit);
    if (result == null) {
      return rawValue;
    }
    return _fmt(result);
  }

  String _fmt(double value) {
    if (value == value.truncate()) {
      return value.truncate().toString();
    }
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void onUnitChanged({
    required String systemId,
    required String paramNumber,
    required String newUnit,
  }) {
    if (systemId.isEmpty) {
      debugPrint(
        '[OptionsCtrl] onUnitChanged: systemId is empty, skipping API call',
      );
      return;
    }

    final canonicalUnit = UnitDefinitions.canonicalizeDisplayUnit(newUnit);
    customUnits[paramNumber] = canonicalUnit;
    customUnits.refresh();

    final system = unitSystems.firstWhereOrNull((item) => item.id == systemId);
    if (system != null) {
      final parameter = system.parameters.firstWhereOrNull(
        (item) => item.number == paramNumber,
      );
      if (parameter != null) {
        parameter.unit = canonicalUnit;
      }
    }

    final key = '${systemId}_$paramNumber';
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(_kDebounce, () {
      _api.patchParameterUnit(
        systemId: systemId,
        paramNumber: paramNumber,
        unit: canonicalUnit,
      );
    });
  }

  Future<UnitSystemModel?> createNewUnitSystem({
    required String name,
    required String baseTemplate,
  }) async {
    final response = await _api.create(name: name, baseTemplate: baseTemplate);
    if (!response.success || response.data == null) {
      return null;
    }

    final normalized = _normalizeSystem(response.data!);
    unitSystems.add(normalized);
    unitSystemNames.add(normalized.name);
    unitSystemNames.refresh();
    return normalized;
  }

  Future<bool> saveAllChanges(String systemId) async {
    isSavingSystem.value = true;
    final payload = parameters
        .map(
          (parameter) => {
            'number': parameter['number']!,
            'name': parameter['name']!,
            'unit':
                customUnits[parameter['number']!] ??
                UnitDefinitions.defaultUnitFor(
                  parameter['number']!,
                  systemName: selectedCustomSystem.value,
                ),
          },
        )
        .toList();
    final response = await _api.updateAll(id: systemId, parameters: payload);
    isSavingSystem.value = false;
    return response.success;
  }

  Future<bool> deleteUnitSystem(String systemId) async {
    final ok = await _api.delete(systemId);
    if (!ok) {
      return false;
    }

    unitSystems.removeWhere((system) => system.id == systemId);
    unitSystemNames.value = unitSystems
        .map((system) => system.name)
        .toList()
        .cast<String>();

    if (selectedCustomSystemId.value == systemId) {
      if (unitSystems.isNotEmpty) {
        _selectSystem(unitSystems.first);
      } else {
        selectedCustomSystemId.value = '';
        selectedCustomSystem.value = '';
        customUnits.clear();
      }
    }

    return true;
  }

  Future<void> seedDefaults() async {
    isLoadingSystems.value = true;
    final response = await _api.seedDefaultSystems();
    isLoadingSystems.value = false;

    if (!response.success) {
      errorMessage.value = response.message ?? 'Failed to seed defaults';
      return;
    }

    final normalizedSystems = _normalizeSystems(response.data);
    unitSystems.value = normalizedSystems;
    unitSystemNames.value = normalizedSystems
        .map((system) => system.name)
        .toList()
        .cast<String>();
    if (normalizedSystems.isNotEmpty) {
      _selectSystem(normalizedSystems.first);
    }
  }

  UnitSystemModel? get selectedSystem => unitSystems.firstWhereOrNull(
    (system) => system.id == selectedCustomSystemId.value,
  );

  int get selectedSystemIndex => unitSystems.indexWhere(
    (system) => system.id == selectedCustomSystemId.value,
  );
}
