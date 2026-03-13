import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/options/model/unit_system_model.dart';

// Debounce: wait this long after last dropdown change before hitting API
const Duration _kDebounce = Duration(milliseconds: 600);

class UnitSystemController extends GetxController {
  // ── Service ─────────────────────────────────────────────────────────────────
  final _api = UnitSystemApiService.instance;

  // ── Tab / radio state (main Options page) ────────────────────────────────────
  final selectedTab = 0.obs;
  final unitSystem  = UnitSystem.us.obs;

  // ── Currently selected custom system (dropdown on main page) ────────────────
  final selectedCustomSystemId = ''.obs;
  final selectedCustomSystem   = 'Pegasus Default 1'.obs;

  // ── Unit systems list (loaded from DB) ───────────────────────────────────────
  final unitSystems     = <UnitSystemModel>[].obs;  // full objects
  final unitSystemNames = <String>[].obs;            // names only, for dropdown

  // ── Parameter units for the currently selected system ────────────────────────
  // Map: paramNumber ("1"…"53") → unit string ("ft", "ppg", …)
  final customUnits = <String, String>{}.obs;

  // ── Loading / error flags ────────────────────────────────────────────────────
  final isLoadingSystems = false.obs;
  final isSavingSystem   = false.obs;
  final errorMessage     = ''.obs;

  // ── All available unit options (for dropdowns in popup) ──────────────────────
  final allUnits = const <String>[
    'ft', 'm', 'in', 'mm', 'in²', 'mm²',
    'bbl', 'm³', 'ft/min', 'm/min', 'psi', 'kPa',
    'ppg', '°F', '°C', 'lb/min', 'kg/min', 'lb/ft', 'kg/m',
    'lb/ft³', 'kg/m³', '°F/100ft', '°C/100m', '°/100ft', '°/100m',
    'lb/bbl', 'gal/bbl', 'L/m³', 'sk', 'bag', 'lb/sk', 'kg/bag',
    'ft³/sk', 'm³/bag', 'gal/sk', 'L/bag', r'$/bbl', r'$/m³', 'mph', 'km/h',
    'Btu/lb/°F', 'J/kg/°C', 'Mpa', 'GPa', 'Btu/hr/ft/°F', 'W/m/K',
    '10⁻⁶/°F', '10⁻⁶/°C', 'gal', 'L', 'sec/qt', 'sec/L', 'rev',
    'US ton/h', 'tonne/h', 'ft/day', 'm/day', '(rpm)', '(lbf)', '(N)',
    '(fbf/ft)', '(N/m)', '(ft-lb)', '(J)', '(psi/ft)', '(kPa/m)',
    '(psi)', '(kPa)',
    '(f1)', '(n1)', '(n2)', '(bbl)', '(bbl./f1)', '(f1/bbl)', '(f13)',
    '(n3)', '(bbl./aik)', '(acf)', '(f1/min)', '(f1/a)', '(f1/hr)',
  ];

  // ── Static parameter list (number + name) — units come from active system ────
  final parameters = const <Map<String, String>>[
    {'number': '1',  'name': 'Length'},
    {'number': '2',  'name': 'Pipe diameter'},
    {'number': '3',  'name': 'Cross section'},
    {'number': '4',  'name': 'Fluid volume'},
    {'number': '5',  'name': 'Velocity'},
    {'number': '6',  'name': 'Pressure'},
    {'number': '7',  'name': 'Mass rate'},
    {'number': '8',  'name': 'Line density'},
    {'number': '9',  'name': 'Density'},
    {'number': '10', 'name': 'Mud weight'},
    {'number': '11', 'name': 'ECD'},
    {'number': '12', 'name': 'Temperature'},
    {'number': '13', 'name': 'Temperature gradient'},
    {'number': '14', 'name': 'Dogleg'},
    {'number': '15', 'name': 'Spacer additive concentration - solid'},
    {'number': '16', 'name': 'Mass - volume ratio'},
    {'number': '17', 'name': 'Volume - volume ratio'},
    {'number': '18', 'name': 'Sack of Cement'},
    {'number': '19', 'name': 'Cement/solid additive Wt/sk'},
    {'number': '20', 'name': 'Spacer additive concentration - liquid'},
    {'number': '21', 'name': 'Cement slurry yield'},
    {'number': '22', 'name': 'Cement liquid additive/water requirement'},
    {'number': '23', 'name': 'Leasing Fee'},
    {'number': '24', 'name': 'Sea current'},
    {'number': '25', 'name': 'Heat Capacity'},
    {'number': '26', 'name': 'Temperature change'},
    {'number': '27', 'name': 'Thermal conductivity'},
    {'number': '28', 'name': 'Thermal expansion'},
    {'number': '29', 'name': 'Elasticity'},
    {'number': '30', 'name': 'Liquid volume'},
    {'number': '31', 'name': 'Funnel viscosity'},
    {'number': '32', 'name': 'Revolution'},
    {'number': '33', 'name': 'ROP'},
    {'number': '34', 'name': 'Cutting transport rate'},
    {'number': '35', 'name': 'Parameter 35'},
    {'number': '36', 'name': 'Parameter 36'},
    {'number': '37', 'name': 'Parameter 37'},
    {'number': '38', 'name': 'Parameter 38'},
    {'number': '39', 'name': 'Parameter 39'},
    {'number': '40', 'name': 'Parameter 40'},
    {'number': '41', 'name': 'Parameter 41'},
    {'number': '42', 'name': 'Parameter 42'},
    {'number': '43', 'name': 'Parameter 43'},
    {'number': '44', 'name': 'Parameter 44'},
    {'number': '45', 'name': 'Parameter 45'},
    {'number': '46', 'name': 'Parameter 46'},
    {'number': '47', 'name': 'Parameter 47'},
    {'number': '48', 'name': 'Parameter 48'},
    {'number': '49', 'name': 'Parameter 49'},
    {'number': '50', 'name': 'Parameter 50'},
    {'number': '51', 'name': 'Parameter 51'},
    {'number': '52', 'name': 'Parameter 52'},
    {'number': '53', 'name': 'Parameter 53'},
  ];

  // ── Debounce timers: key = "systemId_paramNumber" ────────────────────────────
  final _debounceTimers = <String, Timer>{};

  @override
  void onInit() {
    super.onInit();
    fetchAllUnitSystems();
  }

  @override
  void onClose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _debounceTimers.clear();
    super.onClose();
  }

  Future<void> fetchAllUnitSystems() async {
    isLoadingSystems.value = true;
    errorMessage.value = '';

    final response = await _api.fetchAll();

    isLoadingSystems.value = false;

    if (response.success) {
      unitSystems.value     = response.data;
      unitSystemNames.value = response.data.map((s) => s.name).toList();

      // Auto-select first system on first load
      if (selectedCustomSystemId.isEmpty && response.data.isNotEmpty) {
        _selectSystem(response.data.first);
      }
    } else {
      errorMessage.value = response.message ?? 'Failed to load unit systems';
      debugPrint('[OptionsController] fetchAllUnitSystems: ${response.message}');
    }
  }

  void selectUnitSystem(UnitSystemModel system) => _selectSystem(system);

  void selectUnitSystemByName(String name) {
    final found = unitSystems.firstWhereOrNull((s) => s.name == name);
    if (found != null) _selectSystem(found);
  }

  void _selectSystem(UnitSystemModel system) {
    selectedCustomSystemId.value = system.id;
    selectedCustomSystem.value   = system.name;
    _loadUnitsFromSystem(system);
  }

  void _loadUnitsFromSystem(UnitSystemModel system) {
    final map = <String, String>{};
    for (final p in system.parameters) {
      map[p.number] = p.unit;
    }
    customUnits.value = map;
  }

  String getUnit(int index) {
    final number = parameters[index]['number']!;

    switch (unitSystem.value) {
      case UnitSystem.customized:
        return customUnits[number] ?? '-';

      case UnitSystem.us:
      case UnitSystem.si:
        final targetName = unitSystem.value == UnitSystem.us ? 'US' : 'SI';
        final system = unitSystems.firstWhereOrNull(
          (s) => s.name.toUpperCase() == targetName,
        );
        if (system != null) {
          final unit = system.unitFor(number);
          if (unit.isNotEmpty) return unit;
        }
        return customUnits[number] ?? '-';
    }
  }

  void onUnitChanged({
    required String systemId,
    required String paramNumber,
    required String newUnit,
  }) {
    if (systemId.isEmpty) return;
    customUnits[paramNumber] = newUnit;
    customUnits.refresh();

    final system = unitSystems.firstWhereOrNull((s) => s.id == systemId);
    if (system != null) {
      final param = system.parameters.firstWhereOrNull(
        (p) => p.number == paramNumber,
      );
      if (param != null) param.unit = newUnit;
    }

    final key = '${systemId}_$paramNumber';
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(_kDebounce, () {
      _api.patchParameterUnit(
        systemId:    systemId,
        paramNumber: paramNumber,
        unit:        newUnit,
      );
    });
  }

  Future<UnitSystemModel?> createNewUnitSystem({
    required String name,
    required String baseTemplate, // "us" | "si"
  }) async {
    final response = await _api.create(name: name, baseTemplate: baseTemplate);

    if (response.success && response.data != null) {
      final newSystem = response.data!;
      unitSystems.add(newSystem);
      unitSystemNames.add(newSystem.name);
      return newSystem;
    }

    debugPrint('[OptionsController] createNewUnitSystem failed: ${response.message}');
    return null;
  }

  Future<bool> saveAllChanges(String systemId) async {
    isSavingSystem.value = true;

    final params = parameters.map((p) {
      return {
        'number': p['number']!,
        'name':   p['name']!,
        'unit':   customUnits[p['number']!] ?? '',
      };
    }).toList();

    final response = await _api.updateAll(
      id:         systemId,
      parameters: params,
    );

    isSavingSystem.value = false;

    if (!response.success) {
      debugPrint('[OptionsController] saveAllChanges failed: ${response.message}');
    }
    return response.success;
  }

  Future<bool> deleteUnitSystem(String systemId) async {
    final ok = await _api.delete(systemId);

    if (ok) {
      unitSystems.removeWhere((s) => s.id == systemId);
      unitSystemNames.value = unitSystems.map((s) => s.name).toList();

      if (selectedCustomSystemId.value == systemId) {
        if (unitSystems.isNotEmpty) {
          _selectSystem(unitSystems.first);
        } else {
          selectedCustomSystemId.value = '';
          selectedCustomSystem.value   = '';
          customUnits.clear();
        }
      }
    } else {
      debugPrint('[OptionsController] deleteUnitSystem failed for $systemId');
    }
    return ok;
  }

  UnitSystemModel? get selectedSystem =>
      unitSystems.firstWhereOrNull((s) => s.id == selectedCustomSystemId.value);

  int get selectedSystemIndex =>
      unitSystems.indexWhere((s) => s.id == selectedCustomSystemId.value);

  String getUnitNumber(int index) {
    return parameters[index]['number']!;
  }

  String getUnitName(int index) {
    return parameters[index]['name']!;
  }
}
