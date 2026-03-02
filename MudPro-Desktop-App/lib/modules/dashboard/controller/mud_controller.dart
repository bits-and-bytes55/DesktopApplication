import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/mud_properties_controller.dart';

class MudController extends GetxController {
  final samples = ['1', '2', '3', 'Plan-L', 'Plan-H'];

  // LEFT TABLE: MudPropertiesController → selectedmudproperties collection
  final _mudPropsCtrl = MudPropertiesController();

  // DROPDOWN: OthersController → waterbased/oilbased/synthetic collection
  final othersController = OthersController();

  /// Fluid Type
  var selectedFluidType = 'Water-based'.obs;

  /// LEFT TABLE DATA — fetched from selectedmudproperties DB
  final propertyTable = <String, List<RxString>>{}.obs;

  /// DROPDOWN available properties — fetched from OthersController
  final availableProperties = <String>[].obs;

  /// RIGHT TABLE DATA - Rheology
  final rheologyTable = <String, List<RxString>>{}.obs;

  var rheologyModel = 'Bingham'.obs;
  var rheologyCalculation = 'API (RP 13D)'.obs;

  // Checkboxes
  var isCompletionFluid = false.obs;
  var isWeightedMud = false.obs;

  final fluidnameController = TextEditingController();

  // Specific Gravity controllers
  final oilSgController    = TextEditingController(text: '0.80');
  final hgsSgController    = TextEditingController(text: '4.20');
  final lgsSgController    = TextEditingController(text: '2.60');

  // Solids controllers
  final shaleCecController = TextEditingController(text: '15.00');
  final bentCecController  = TextEditingController(text: '65.00');

  // Sample for calculation (1, 2, 3 only)
  var sampleForCalculation = '1'.obs;

  // Loading state
  var isLoading = false.obs;

  @override
  void onInit() {
    _initRheologyTable();
    loadFluidTypeData();
    super.onInit();
  }

  // ─── LOAD DATA ────────────────────────────────────────────

  Future<void> loadFluidTypeData() async {
    isLoading.value = true;
    try {
      propertyTable.clear();
      availableProperties.clear();

      // Run both in parallel
      await Future.wait([
        _loadLeftTableFromMudProperties(),
        _loadDropdownFromOthers(),
      ]);
    } catch (e) {
      debugPrint('[MudController] loadFluidTypeData error: $e');
      Get.snackbar(
        'Error', 'Failed to load data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─── LEFT TABLE: MudPropertiesController (selectedmudproperties) ──

  Future<void> _loadLeftTableFromMudProperties() async {
    try {
      debugPrint('[MudController] Fetching selected mud properties...');

      final selected = await _mudPropsCtrl.getSelectedMudProperties();

      debugPrint('[MudController] Selected waterBased: ${selected.waterBased}');
      debugPrint('[MudController] Selected oilBased: ${selected.oilBased}');
      debugPrint('[MudController] Selected synthetic: ${selected.synthetic}');

      List<String> props = [];
      switch (selectedFluidType.value) {
        case 'Water-based':
          props = selected.waterBased;
          break;
        case 'Oil-based':
          props = selected.oilBased;
          break;
        case 'Synthetic':
          props = selected.synthetic;
          break;
      }

      debugPrint('[MudController] Props for ${selectedFluidType.value}: $props');

      // Always add common fields first
      _addCommonFields();

      // Add selected properties as table rows
      for (final name in props) {
        if (name.isNotEmpty) {
          propertyTable[name] = List.generate(samples.length, (_) => ''.obs);
        }
      }

      debugPrint('[MudController] propertyTable keys: ${propertyTable.keys.toList()}');
    } catch (e) {
      debugPrint('[MudController] Left table fetch ERROR: $e');
      // Show common fields at minimum even if API fails
      _addCommonFields();
    }
  }

  // ─── DROPDOWN: OthersController ───────────────────────────

  Future<void> _loadDropdownFromOthers() async {
    try {
      debugPrint('[MudController] Fetching dropdown data from OthersController...');
      List<dynamic> data = [];

      switch (selectedFluidType.value) {
        case 'Water-based':
          data = await othersController.getWaterBased();
          break;
        case 'Oil-based':
          data = await othersController.getOilBased();
          break;
        case 'Synthetic':
          data = await othersController.getSynthetic();
          break;
      }

      final props = data
          .where((item) => item.name != null && (item.name as String).isNotEmpty)
          .map<String>((item) => item.name as String)
          .toList();

      debugPrint('[MudController] Dropdown options (${props.length}): $props');
      availableProperties.value = props;
    } catch (e) {
      debugPrint('[MudController] Dropdown fetch ERROR: $e');
      availableProperties.value = [];
    }
  }

  // ─── COMMON FIELDS ────────────────────────────────────────

  void _addCommonFields() {
    final commonFields = [
      'Description',
      'Sample from',
      'Time Sample Taken (hh:mm)',
    ];
    for (final field in commonFields) {
      propertyTable[field] = List.generate(samples.length, (_) => ''.obs);
    }
  }

  /// Add a property row from dropdown selection
  void addPropertyRow(String propertyName) {
    if (propertyName.isEmpty) return;
    if (propertyTable.containsKey(propertyName)) return;
    propertyTable[propertyName] = List.generate(samples.length, (_) => ''.obs);
    debugPrint('[MudController] Added property row: $propertyName');
  }

  /// Remove a previously added (via dropdown) property row
  void removeAddedPropertyRow(String propertyName) {
    if (propertyName.isEmpty) return;
    propertyTable.remove(propertyName);
    debugPrint('[MudController] Removed property row: $propertyName');
  }

  void changeFluidType(String type) {
    selectedFluidType.value = type;
    loadFluidTypeData();
  }

  // ─── RHEOLOGY TABLE ───────────────────────────────────────

  void _initRheologyTable() {
    _updateRheologyRows();
  }

  void changeModel(String model) {
    rheologyModel.value = model;
    _updateRheologyRows();
  }

  void _updateRheologyRows() {
    final rows = rheologyModel.value == 'Bingham'
        ? ['600', '300', '200', '100', '6', '3', 'PV (cP)', 'YP (lbf/100ft2)']
        : rheologyModel.value == 'Power Law'
            ? ['600', '300', '200', '100', '6', '3', 'n', 'K (lbf-s^n/100ft2)']
            : ['600', '300', '200', '100', '6', '3',
               'Yield Stress (lbf/100ft2)', 'n', 'K (lbf-s^n/100ft2)'];

    rheologyTable.clear();
    for (var r in rows) {
      rheologyTable[r] = List.generate(samples.length, (_) => ''.obs);
    }
  }

  // ─── CALCULATE RHEOLOGY ───────────────────────────────────

  void calculateRheology() {
    for (int i = 0; i < samples.length; i++) {
      final r600 = double.tryParse(rheologyTable['600']?[i].value ?? '') ?? 0;
      final r300 = double.tryParse(rheologyTable['300']?[i].value ?? '') ?? 0;
      final r3   = double.tryParse(rheologyTable['3']?[i].value   ?? '') ?? 0;
      final r6   = double.tryParse(rheologyTable['6']?[i].value   ?? '') ?? 0;

      switch (rheologyModel.value) {
        case 'Bingham':
          if (r600 > 0 || r300 > 0) {
            final pv = r600 - r300;
            final yp = r300 - pv;
            rheologyTable['PV (cP)']?[i].value         = pv.toStringAsFixed(1);
            rheologyTable['YP (lbf/100ft2)']?[i].value = yp.toStringAsFixed(1);
          }
          break;
        case 'Power Law':
          if (r600 > 0 && r300 > 0) {
            final n = 3.32 * _log10(r600 / r300);
            final k = 510 * r300 / _pow(511, n);
            rheologyTable['n']?[i].value                   = n.toStringAsFixed(3);
            rheologyTable['K (lbf-s^n/100ft2)']?[i].value = k.toStringAsFixed(3);
          }
          break;
        case 'HB':
          if (r3 > 0 || r6 > 0) {
            final ys = (2 * r3 - r6).clamp(0.0, double.infinity);
            rheologyTable['Yield Stress (lbf/100ft2)']?[i].value = ys.toStringAsFixed(2);
          }
          if (r600 > 0 && r300 > 0) {
            final n = 3.32 * _log10(r600 / r300);
            final k = 510 * r300 / _pow(511, n);
            rheologyTable['n']?[i].value                   = n.toStringAsFixed(3);
            rheologyTable['K (lbf-s^n/100ft2)']?[i].value = k.toStringAsFixed(3);
          }
          break;
      }
    }
    rheologyTable.refresh();
  }

  // ─── TRANSFER RHEOLOGY → PROPERTY TABLE ──────────────────

  void transferRheologyToPropertyTable() {
    bool transferred = false;
    for (final entry in rheologyTable.entries) {
      if (double.tryParse(entry.key) != null) continue;
      for (final propKey in propertyTable.keys) {
        if (_rowMatches(propKey, entry.key)) {
          final propList = propertyTable[propKey]!;
          for (int j = 0; j < entry.value.length && j < propList.length; j++) {
            final val = entry.value[j].value;
            if (val.isNotEmpty) {
              propList[j].value = val;
              transferred = true;
            }
          }
        }
      }
    }
    propertyTable.refresh();

    Get.snackbar(
      transferred ? 'Done' : 'No Match',
      transferred
          ? 'Rheology values applied to property table'
          : 'No matching fields found in property table',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: (transferred ? Colors.green : Colors.orange).withOpacity(0.1),
      colorText: transferred ? Colors.green.shade700 : Colors.orange.shade700,
      duration: const Duration(seconds: 2),
    );
  }

  bool _rowMatches(String rowName, String rheologyKey) {
    final rn = rowName.toLowerCase().replaceAll('*', '').trim();
    final rk = rheologyKey.toLowerCase().trim();
    if (rk.contains('pv')           && rn.contains('pv'))    return true;
    if (rk.contains('yp')           && rn.contains('yp'))    return true;
    if (rk == 'n'                   && rn == 'n')             return true;
    if (rk.contains('yield stress') && rn.contains('yield')) return true;
    if (rk.contains('k (')          && rn.contains('k ('))   return true;
    return false;
  }

  // ─── MATH ─────────────────────────────────────────────────

  double _log10(double x) => x > 0 ? 0.4342944819 * _ln(x) : 0;

  double _ln(double x) {
    if (x <= 0) return 0;
    double r = 0, y = (x - 1) / (x + 1), y2 = y * y, t = y;
    for (int i = 0; i < 50; i++) { r += t / (2 * i + 1); t *= y2; }
    return 2 * r;
  }

  double _pow(double base, double exp) =>
      base <= 0 ? 0 : _expM(exp * _ln(base));

  double _expM(double x) {
    double r = 1, t = 1;
    for (int i = 1; i <= 50; i++) { t *= x / i; r += t; }
    return r;
  }

  // ─── DISPOSE ──────────────────────────────────────────────

  @override
  void onClose() {
    fluidnameController.dispose();
    oilSgController.dispose();
    hgsSgController.dispose();
    lgsSgController.dispose();
    shaleCecController.dispose();
    bentCecController.dispose();
    super.onClose();
  }
}