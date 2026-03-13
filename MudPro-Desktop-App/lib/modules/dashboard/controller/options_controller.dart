// ─────────────────────────────────────────────────────────────────────────────
// options_controller.dart  (FIXED)
// – getUnit() now properly matches "US" / "SI" with built-in fallbacks
// – per-parameter unit lists exposed via getUnitsForParam()
// – convertValue() wired through UnitConversionService
// – parameters list updated to match original software (53 params)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:mudpro_desktop_app/modules/options/model/unit_system_model.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/options/unit_conversion_service.dart';

const Duration _kDebounce = Duration(milliseconds: 600);

class OptionsController extends GetxController {
  final _api  = UnitSystemApiService.instance;
  final _conv = UnitConversionService.instance;

  // ── Main page radio ──────────────────────────────────────────────────────
  final selectedTab = 0.obs;
  final unitSystem  = UnitSystem.us.obs;

  // ── Selected custom system ───────────────────────────────────────────────
  final selectedCustomSystemId = ''.obs;
  final selectedCustomSystem   = 'Pegasus Default 1'.obs;

  // ── Systems list ─────────────────────────────────────────────────────────
  final unitSystems     = <UnitSystemModel>[].obs;
  final unitSystemNames = <String>[].obs;

  // ── Active units map: paramNumber → unit string ──────────────────────────
  final customUnits = <String, String>{}.obs;

  // ── Flags ─────────────────────────────────────────────────────────────────
  final isLoadingSystems = false.obs;
  final isSavingSystem   = false.obs;
  final errorMessage     = ''.obs;

  // ── Debounce timers ───────────────────────────────────────────────────────
  final _debounceTimers = <String, Timer>{};

  // ════════════════════════════════════════════════════════════════════════════
  // PARAMETER LIST — matches original software (screenshots 6–13)
  // ════════════════════════════════════════════════════════════════════════════
  static const List<Map<String, String>> parameters = [
    {'number': '1',  'name': 'Length'},
    {'number': '2',  'name': 'Pipe diameter'},
    {'number': '3',  'name': 'Nozzle diameter'},
    {'number': '4',  'name': 'Surface area'},
    {'number': '5',  'name': 'Cross section'},
    {'number': '6',  'name': 'Fluid volume'},
    {'number': '7',  'name': 'Pipe capacity (volume/length)'},
    {'number': '8',  'name': 'Pipe capacity (length/volume)'},
    {'number': '9',  'name': 'Solid volume'},
    {'number': '10', 'name': 'Small volume'},
    {'number': '11', 'name': 'Stroke displacement'},
    {'number': '12', 'name': 'Gas volume'},
    {'number': '13', 'name': 'Velocity'},
    {'number': '14', 'name': 'Nozzle velocity'},
    {'number': '15', 'name': 'ROP'},
    {'number': '16', 'name': 'Rotation'},
    {'number': '17', 'name': 'Liquid flow rate for drilling'},
    {'number': '18', 'name': 'Liquid flow rate for cementing'},
    {'number': '19', 'name': 'Pressure'},
    {'number': '20', 'name': 'Mud weight'},
    {'number': '21', 'name': 'ECD'},
    {'number': '22', 'name': 'Temperature'},
    {'number': '23', 'name': 'Temperature gradient'},
    {'number': '24', 'name': 'Dogleg'},
    {'number': '25', 'name': 'Spacer additive concentration - solid'},
    {'number': '26', 'name': 'Mass - volume ratio'},
    {'number': '27', 'name': 'Volume - volume ratio'},
    {'number': '28', 'name': 'Sack of Cement'},
    {'number': '29', 'name': 'Cement/solid additive Wt/sk'},
    {'number': '30', 'name': 'Spacer additive concentration - liquid'},
    {'number': '31', 'name': 'Cement slurry yield'},
    {'number': '32', 'name': 'Cement liquid additive/water requirement'},
    {'number': '33', 'name': 'Leasing Fee'},
    {'number': '34', 'name': 'Sea current'},
    {'number': '35', 'name': 'Heat Capacity'},
    {'number': '36', 'name': 'Temperature change'},
    {'number': '37', 'name': 'Thermal conductivity'},
    {'number': '38', 'name': 'Thermal expansion'},
    {'number': '39', 'name': 'Elasticity'},
    {'number': '40', 'name': 'Liquid volume'},
    {'number': '41', 'name': 'Funnel viscosity'},
    {'number': '42', 'name': 'Revolution'},
    {'number': '43', 'name': 'Cutting transport - ROP'},
    {'number': '44', 'name': 'Cutting transport rate'},
    {'number': '45', 'name': 'Rotation (parameter)'},
    {'number': '46', 'name': 'Hook load'},
    {'number': '47', 'name': 'Force'},
    {'number': '48', 'name': 'Spring constant (imperial)'},
    {'number': '49', 'name': 'Spring constant (SI)'},
    {'number': '50', 'name': 'Torque (imperial)'},
    {'number': '51', 'name': 'Energy'},
    {'number': '52', 'name': 'Pressure (alt)'},
    {'number': '53', 'name': 'Pressure gradient'},
  ];

  // ════════════════════════════════════════════════════════════════════════════
  // BUILT-IN DEFAULTS — always show units even if DB is empty / unreachable
  // ════════════════════════════════════════════════════════════════════════════
  static const Map<String, String> _usDefaults = {
    '1': '(ft)',  '2': '(in)',  '3': '(1/32in)', '4': '(ft2)',
    '5': '(in2)', '6': '(bbl)', '7': '(bbl/ft)', '8': '(ft/bbl)',
    '9': '(ft3)', '10': '(in3)', '11': '(bbl/stk)', '12': '(scf)',
    '13': '(ft/min)', '14': '(ft/s)', '15': '(ft/hr)', '16': '(rpm)',
    '17': '(gpm)', '18': '(bpm)', '19': '(psi)', '20': '(ppg)',
    '21': '(ppg)', '22': '(°F)', '23': '(°F/100ft)', '24': '(°/100ft)',
    '25': '(lb/bbl)', '26': '(lb/bbl)', '27': '(gal/bbl)', '28': '(sk)',
    '29': '(lb/sk)', '30': '(gal/sk)', '31': '(ft3/sk)', '32': '(gal/sk)',
    '33': r'($/bbl)', '34': '(mph)', '35': '(Btu/lb/°F)', '36': '(°F)',
    '37': '(Btu/hr/ft/°F)', '38': '(10-6/°F)', '39': '(MPa)', '40': '(gal)',
    '41': '(sec/qt)', '42': '(rev)', '43': '(ft/hr)', '44': '(US ton/h)',
    '45': '(rpm)', '46': '(lbf)', '47': '(N)', '48': '(fbf/ft)',
    '49': '(N/m)', '50': '(ft-lb)', '51': '(J)', '52': '(psi)', '53': '(psi/ft)',
  };

  static const Map<String, String> _siDefaults = {
    '1': '(m)',  '2': '(mm)', '3': '(mm)', '4': '(m2)',
    '5': '(mm2)', '6': '(m3)', '7': '(m3/m)', '8': '(m/m3)',
    '9': '(m3)', '10': '(m3)', '11': '(m3/stk)', '12': '(m3)',
    '13': '(m/min)', '14': '(m/s)', '15': '(m/hr)', '16': '(rpm)',
    '17': '(m3/min)', '18': '(m3/min)', '19': '(kPa)', '20': '(kg/m3)',
    '21': '(kg/m3)', '22': '(°C)', '23': '(°C/100m)', '24': '(°/100m)',
    '25': '(kg/m3)', '26': '(kg/m3)', '27': '(L/m3)', '28': '(bag)',
    '29': '(kg/bag)', '30': '(L/bag)', '31': '(m3/bag)', '32': '(L/bag)',
    '33': r'($/m3)', '34': '(km/h)', '35': '(J/kg/°C)', '36': '(°C)',
    '37': '(W/m/K)', '38': '(10-6/°C)', '39': '(GPa)', '40': '(L)',
    '41': '(sec/L)', '42': '(rev)', '43': '(m/hr)', '44': '(tonne/h)',
    '45': '(rpm)', '46': '(N)', '47': '(N)', '48': '(N/m)',
    '49': '(N/m)', '50': '(J)', '51': '(J)', '52': '(kPa)', '53': '(kPa/m)',
  };

  // ════════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    fetchAllUnitSystems();
  }

  @override
  void onClose() {
    for (final t in _debounceTimers.values) { t.cancel(); }
    _debounceTimers.clear();
    super.onClose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FETCH
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> fetchAllUnitSystems() async {
    isLoadingSystems.value = true;
    errorMessage.value = '';

    final response = await _api.fetchAll();
    isLoadingSystems.value = false;

    if (response.success) {
      unitSystems.value     = response.data;
      unitSystemNames.value = response.data.map((s) => s.name).toList().cast<String>();

      if (selectedCustomSystemId.isEmpty && response.data.isNotEmpty) {
        _selectSystem(response.data.first);
      }
    } else {
      errorMessage.value = response.message ?? 'Failed to load unit systems';
      debugPrint('[OptionsCtrl] fetchAll error: ${response.message}');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SELECT
  // ════════════════════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════════════════════
  // GET UNIT (FIXED)
  // Tries DB first, falls back to built-in defaults — table always shows units.
  // ════════════════════════════════════════════════════════════════════════════

  String getUnit(int index) {
    final number = parameters[index]['number']!;

    switch (unitSystem.value) {
      case UnitSystem.customized:
        return customUnits[number] ?? '-';

      case UnitSystem.us:
        // Try DB system named "US" (case-insensitive, multiple aliases)
        final sys = _findSystemByAny(['us', 'us oil field', 'usoilfield']);
        if (sys != null) {
          final u = sys.unitFor(number);
          if (u.isNotEmpty) return u;
        }
        // Always fall back to built-in so table is never empty
        return _usDefaults[number] ?? '-';

      case UnitSystem.si:
        final sys = _findSystemByAny(['si', 'metric', 'si metric']);
        if (sys != null) {
          final u = sys.unitFor(number);
          if (u.isNotEmpty) return u;
        }
        return _siDefaults[number] ?? '-';
    }
  }

  UnitSystemModel? _findSystemByAny(List<String> lowerNames) {
    for (final s in unitSystems) {
      if (lowerNames.contains(s.name.toLowerCase())) return s;
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PER-PARAMETER UNIT OPTIONS (for popup dropdowns)
  // ════════════════════════════════════════════════════════════════════════════

  List<String> getUnitsForParam(String paramNumber) =>
      UnitConversionService.parameterUnits[paramNumber] ?? [];

  // ════════════════════════════════════════════════════════════════════════════
  // CONVERT VALUE when unit changes
  // ════════════════════════════════════════════════════════════════════════════

  String convertValue({
    required String rawValue,
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) return rawValue;
    final val = double.tryParse(rawValue);
    if (val == null) return rawValue;

    final result = _conv.convertValue(val, fromUnit, toUnit);
    if (result == null) return rawValue;
    return _fmt(result);
  }

  String _fmt(double v) {
    if (v == v.truncate()) return v.truncate().toString();
    return v.toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ON UNIT CHANGED — optimistic + debounced PATCH
  // ════════════════════════════════════════════════════════════════════════════

  void onUnitChanged({
    required String systemId,
    required String paramNumber,
    required String newUnit,
  }) {
    if (systemId.isEmpty) {
      debugPrint('[OptionsCtrl] onUnitChanged: systemId is empty, skipping API call');
      return;
    }
    customUnits[paramNumber] = newUnit;
    customUnits.refresh();

    final system = unitSystems.firstWhereOrNull((s) => s.id == systemId);
    if (system != null) {
      final param = system.parameters.firstWhereOrNull((p) => p.number == paramNumber);
      if (param != null) param.unit = newUnit;
    }

    final key = '${systemId}_$paramNumber';
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(_kDebounce, () {
      _api.patchParameterUnit(systemId: systemId, paramNumber: paramNumber, unit: newUnit);
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CREATE / SAVE / DELETE
  // ════════════════════════════════════════════════════════════════════════════

  Future<UnitSystemModel?> createNewUnitSystem({
    required String name,
    required String baseTemplate,
  }) async {
    final r = await _api.create(name: name, baseTemplate: baseTemplate);
    if (r.success && r.data != null) {
      unitSystems.add(r.data!);
      unitSystemNames.add(r.data!.name);
      unitSystemNames.refresh();
      return r.data;
    }
    return null;
  }

  Future<bool> saveAllChanges(String systemId) async {
    isSavingSystem.value = true;
    final params = parameters.map((p) => {
      'number': p['number']!,
      'name':   p['name']!,
      'unit':   customUnits[p['number']!] ?? '',
    }).toList();
    final r = await _api.updateAll(id: systemId, parameters: params);
    isSavingSystem.value = false;
    return r.success;
  }

  Future<bool> deleteUnitSystem(String systemId) async {
    final ok = await _api.delete(systemId);
    if (ok) {
      unitSystems.removeWhere((s) => s.id == systemId);
      unitSystemNames.value = unitSystems.map((s) => s.name).toList().cast<String>();
      if (selectedCustomSystemId.value == systemId) {
        if (unitSystems.isNotEmpty) {
          _selectSystem(unitSystems.first);
        } else {
          selectedCustomSystemId.value = '';
          selectedCustomSystem.value   = '';
          customUnits.clear();
        }
      }
    }
    return ok;
  }

  Future<void> seedDefaults() async {
    isLoadingSystems.value = true;
    final r = await _api.seedDefaultSystems();
    isLoadingSystems.value = false;

    if (r.success) {
      unitSystems.value = r.data;
      unitSystemNames.value = r.data.map((s) => s.name).toList().cast<String>();
      if (unitSystems.isNotEmpty) {
        _selectSystem(unitSystems.first);
      }
    } else {
      errorMessage.value = r.message ?? 'Failed to seed defaults';
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  UnitSystemModel? get selectedSystem =>
      unitSystems.firstWhereOrNull((s) => s.id == selectedCustomSystemId.value);

  int get selectedSystemIndex =>
      unitSystems.indexWhere((s) => s.id == selectedCustomSystemId.value);
}