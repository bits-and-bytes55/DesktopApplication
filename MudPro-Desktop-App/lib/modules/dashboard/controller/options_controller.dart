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
import 'package:mudpro_desktop_app/modules/options/services/unit_system_api_service.dart';
import 'package:mudpro_desktop_app/modules/options/unit_conversion_service.dart';
import 'package:mudpro_desktop_app/modules/options/unit_label_formatter.dart';

const Duration _kDebounce = Duration(milliseconds: 600);

class OptionsController extends GetxController {
  final _api  = UnitSystemApiService();
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
    {'number': '19', 'name': 'Stroke rate'},
    {'number': '20', 'name': 'Force'},
    {'number': '21', 'name': 'Torque'},
    {'number': '22', 'name': 'Pressure'},
    {'number': '23', 'name': 'Pressure gradient'},
    {'number': '24', 'name': 'Stress'},
    {'number': '25', 'name': 'Yield point'},
    {'number': '26', 'name': 'Power'},
    {'number': '27', 'name': 'Viscosity'},
    {'number': '28', 'name': 'Consistency'},
    {'number': '29', 'name': 'Weight'},
    {'number': '30', 'name': 'Mass rate'},
    {'number': '31', 'name': 'Line density'},
    {'number': '32', 'name': 'Density'},
    {'number': '33', 'name': 'Mud weight'},
    {'number': '34', 'name': 'Temperature'},
    {'number': '35', 'name': 'Temperature gradient'},
    {'number': '36', 'name': 'Schedule time'},
    {'number': '37', 'name': 'Dogleg'},
    {'number': '38', 'name': 'Degree'},
    {'number': '39', 'name': 'Mass - volume ratio'},
    {'number': '40', 'name': 'Volume - volume ratio'},
    {'number': '41', 'name': 'Cement/solid additive Wt/sk'},
    {'number': '42', 'name': 'Cement slurry yield'},
    {'number': '43', 'name': 'Cement liquid additive/water requirement'},
    {'number': '44', 'name': 'Concentration'},
    {'number': '45', 'name': 'Conductivity'},
    {'number': '46', 'name': 'Heat Capacity'},
    {'number': '47', 'name': 'Heat transfer coefficient'},
    {'number': '48', 'name': 'Temperature Drop'},
    {'number': '49', 'name': 'Funnel viscosity'},
  ];

  static const Map<String, String> _usDefaults = {
    '1': '(ft)',  '2': '(in)',  '3': '(in)', '4': '(ft²)',
    '5': '(in²)', '6': '(bbl)', '7': '(bbl/ft)', '8': '(ft/bbl)',
    '9': '(ft³)', '10': '(in³)', '11': '(bbl/stk)', '12': '(scf)',
    '13': '(ft/min)', '14': '(ft/s)', '15': '(ft/hr)', '16': '(rpm)',
    '17': '(gpm)', '18': '(bpm)', '19': '(stk/min)', '20': '(lbf)',
    '21': '(ft-lb)', '22': '(psi)', '23': '(psi/ft)', '24': '(kPa)',
    '25': '(lbf/100ft²)', '26': '(HP)', '27': '(cP)', '28': '(lbf-s^n/100ft²)',
    '29': '(lbm)', '30': '(lbm/min)', '31': '(lb/ft)', '32': '(lb/ft³)',
    '33': '(ppg)', '34': '(°F)', '35': '(°C/100m)', '36': '(min)',
    '37': '(°/100ft)', '38': '(°)', '39': '(lb/bbl)', '40': '(gal/bbl)',
    '41': '(lb/sk)', '42': '(ft³/sk)', '43': '(gal/sk)', '44': '(mg/L)',
    '45': '(Btu/hr/ft/°F)', '46': '(Btu/lbm/°F)', '47': '(Btu/hr/ft²/°F)',
    '48': '(°F)', '49': '(sec/qt)',
  };

  static const Map<String, String> _siDefaults = {
    '1': '(m)',  '2': '(mm)', '3': '(mm)', '4': '(m²)',
    '5': '(mm²)', '6': '(m³)', '7': '(m³/m)', '8': '(m/m³)',
    '9': '(m³)', '10': '(L)', '11': '(m³/stk)', '12': '(m³)',
    '13': '(m/min)', '14': '(m/s)', '15': '(m/hr)', '16': '(rpm)',
    '17': '(m³/min)', '18': '(m³/min)', '19': '(stk/min)', '20': '(N)',
    '21': '(N-m)', '22': '(kPa)', '23': '(kPa/m)', '24': '(kPa)',
    '25': '(Pa)', '26': '(KW)', '27': '(cP)', '28': '(Pa-s^n)',
    '29': '(kg)', '30': '(kg/min)', '31': '(kg/m)', '32': '(kg/m³)',
    '33': '(kg/m³)', '34': '(°C)', '35': '(°C/100m)', '36': '(min)',
    '37': '(°/30m)', '38': '(°)', '39': '(kg/m³)', '40': '(gal/bbl)',
    '41': '(kg/sk)', '42': '(m³/sk)', '43': '(m³/sk)', '44': '(mg/L)',
    '45': '(W/m/K)', '46': '(J/kg/°C)', '47': '(W/m²/K)', '48': '(°C)',
    '49': '(sec/L)',
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
      final normalizedSystems = response.data.map(_normalizeSystem).toList();
      unitSystems.value = normalizedSystems;
      unitSystemNames.value =
          normalizedSystems.map((s) => s.name).toList().cast<String>();

      if (normalizedSystems.isNotEmpty) {
        final preferredSystem = normalizedSystems.firstWhereOrNull(
              (system) => system.id == selectedCustomSystemId.value,
            ) ??
            normalizedSystems.first;
        _selectSystem(preferredSystem);
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
      map[p.number] = _normalizeUnit(p.number, p.unit);
    }
    customUnits.value = map;
  }

  UnitSystemModel _normalizeSystem(UnitSystemModel system) {
    for (final parameter in system.parameters) {
      parameter.unit = _normalizeUnit(parameter.number, parameter.unit);
    }
    return system;
  }

  String _normalizeUnit(String paramNumber, String rawUnit) {
    return UnitLabelFormatter.normalize(
      rawUnit,
      preferredOptions: UnitConversionService.parameterUnits[paramNumber] ?? const [],
    );
  }

  UnitSystemModel? get _activeSystemForView {
    switch (unitSystem.value) {
      case UnitSystem.customized:
        return selectedSystem;
      case UnitSystem.us:
        return _findSystemByAny(['us', 'us oil field', 'usoilfield']);
      case UnitSystem.si:
        return _findSystemByAny(['si', 'metric', 'si metric']);
    }
  }

  List<Map<String, String>> get visibleParameters {
    final system = _activeSystemForView;
    if (system != null && system.parameters.isNotEmpty) {
      return system.parameters
          .map(
            (parameter) => {
              'number': parameter.number,
              'name': parameter.name,
            },
          )
          .toList(growable: false);
    }
    return parameters;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GET UNIT (FIXED)
  // Tries DB first, falls back to built-in defaults — table always shows units.
  // ════════════════════════════════════════════════════════════════════════════

  String getUnit(int index) {
    final rows = visibleParameters;
    if (index < 0 || index >= rows.length) {
      return '-';
    }
    final number = rows[index]['number']!;
    return getUnitForParameter(number);
  }

  String getUnitForParameter(String number) {
    switch (unitSystem.value) {
      case UnitSystem.customized:
        final customUnit = customUnits[number];
        if (customUnit != null && customUnit.isNotEmpty) {
          return customUnit;
        }
        final selectedUnit = _activeSystemForView?.unitFor(number) ?? '';
        return selectedUnit.isEmpty ? '-' : _normalizeUnit(number, selectedUnit);

      case UnitSystem.us:
        final sys = _findSystemByAny(['us', 'us oil field', 'usoilfield']);
        if (sys != null) {
          final u = _normalizeUnit(number, sys.unitFor(number));
          if (u.isNotEmpty) return u;
        }
        return _normalizeUnit(number, _usDefaults[number] ?? '-');

      case UnitSystem.si:
        final sys = _findSystemByAny(['si', 'metric', 'si metric']);
        if (sys != null) {
          final u = _normalizeUnit(number, sys.unitFor(number));
          if (u.isNotEmpty) return u;
        }
        return _normalizeUnit(number, _siDefaults[number] ?? '-');
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

  List<String> getUnitsForParam(String paramNumber) {
    final merged = <String>[];
    final seen = <String>{};

    void addUnits(Iterable<String> units) {
      for (final unit in units) {
        final normalized = _normalizeUnit(paramNumber, unit);
        if (normalized.isEmpty) {
          continue;
        }

        final key = UnitLabelFormatter.canonicalize(normalized);
        if (seen.add(key)) {
          merged.add(normalized);
        }
      }
    }

    addUnits(UnitConversionService.parameterUnits[paramNumber] ?? const []);
    addUnits(
      unitSystems
          .map((system) => system.unitFor(paramNumber))
          .where((unit) => unit.isNotEmpty),
    );

    final currentUnit = customUnits[paramNumber];
    if (currentUnit != null && currentUnit.isNotEmpty) {
      addUnits([currentUnit]);
    }

    return merged;
  }

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
      final created = _normalizeSystem(r.data!);
      unitSystems.add(created);
      unitSystemNames.add(created.name);
      unitSystemNames.refresh();
      return created;
    }
    return null;
  }

  Future<bool> saveAllChanges(String systemId) async {
    isSavingSystem.value = true;
    final sourceParameters = selectedSystem?.parameters ??
        visibleParameters
            .map(
              (row) => ParameterUnit(
                number: row['number']!,
                name: row['name']!,
                unit: getUnitForParameter(row['number']!),
              ),
            )
            .toList(growable: false);

    final params = sourceParameters
        .map(
          (parameter) => {
            'number': parameter.number,
            'name': parameter.name,
            'unit': customUnits[parameter.number] ??
                _normalizeUnit(parameter.number, parameter.unit),
          },
        )
        .toList(growable: false);
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
      if (r.data.isEmpty) {
        await fetchAllUnitSystems();
        return;
      }
      final normalizedSystems = r.data.map(_normalizeSystem).toList();
      unitSystems.value = normalizedSystems;
      unitSystemNames.value =
          normalizedSystems.map((s) => s.name).toList().cast<String>();
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

  String get activeUnitSystemLabel {
    switch (unitSystem.value) {
      case UnitSystem.us:
        return 'US Oil Field';
      case UnitSystem.si:
        return 'SI';
      case UnitSystem.customized:
        return selectedCustomSystem.value.isEmpty
            ? 'Customized'
            : selectedCustomSystem.value;
    }
  }

  Map<String, String> snapshotUnits(Iterable<String> paramNumbers) {
    return {
      for (final paramNumber in paramNumbers)
        paramNumber: getUnitForParameter(paramNumber),
    };
  }

  void setSelectedTab(int index) {
    selectedTab.value = index;
  }
}
