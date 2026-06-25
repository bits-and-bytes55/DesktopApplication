import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/well_general_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/mud/apply_rheology_page.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/mud/solid_analysis_page.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/mud/titration_dialog.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

enum _MudPropertyMenuAction { cut, copy, paste, delete, top, bottom }

class MudView extends StatefulWidget {
  const MudView({super.key});

  @override
  State<MudView> createState() => _MudViewState();
}

class _MudViewState extends State<MudView> {
  static const double _kMudPropertyWidth = 190;
  static const double _kMudHeaderHeight = 28;
  static const double _kMudRowHeight = 28;

  late MudController c;
  late DashboardController dashboard;
  late WellGeneralController wellGeneral;
  late IntervalController intervalCtrl;

  final _propertyScrollCtrl = ScrollController();
  final _rheologyScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<MudController>()
        ? Get.find<MudController>()
        : Get.put(MudController());
    dashboard = Get.find<DashboardController>();
    wellGeneral = Get.isRegistered<WellGeneralController>()
        ? Get.find<WellGeneralController>()
        : Get.put(WellGeneralController(), permanent: true);
    intervalCtrl = Get.isRegistered<IntervalController>()
        ? Get.find<IntervalController>()
        : Get.put(IntervalController(), permanent: true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await c.useMudStateScope('');
      await c.refreshMudPropertyUnitsFromSetup();
    });
  }

  Future<String?> _selectedReportIntervalId() async {
    final wellId = currentBackendWellId.trim();
    if (wellId.isNotEmpty && intervalCtrl.wellId.value != wellId) {
      intervalCtrl.wellId.value = wellId;
    }
    if (wellGeneral.interval.value.trim().isEmpty &&
        !wellGeneral.isLoading.value) {
      await wellGeneral.fetchLatest();
    }
    if (intervalCtrl.intervals.isEmpty &&
        wellId.isNotEmpty &&
        !intervalCtrl.isLoading.value) {
      await intervalCtrl.fetchAll();
    }

    final selected = wellGeneral.interval.value.trim();
    final items = intervalCtrl.intervals.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    if (selected.isEmpty) {
      final current = intervalCtrl.selected.value?.id.trim() ?? '';
      return current.isEmpty ? null : current;
    }

    final counts = <String, int>{};
    for (final item in items) {
      final name = item.name.trim();
      if (name.isNotEmpty) counts[name] = (counts[name] ?? 0) + 1;
    }

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final name = item.name.trim();
      final duplicateLabel = (counts[name] ?? 0) > 1 ? '${i + 1}. $name' : name;
      if (selected == item.id ||
          selected == name ||
          selected == duplicateLabel) {
        return item.id;
      }
    }
    return null;
  }

  Future<void> _importSelectedIntervalMudPlan() async {
    if (dashboard.isLocked.value) return;
    final intervalId = await _selectedReportIntervalId();
    if (intervalId == null || intervalId.trim().isEmpty) {
      Get.snackbar(
        'Mud Properties',
        'Select an interval in Well > General first.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    await c.useMudStateScope('');
    final imported = await c.importMudPlanPropertiesFromInterval(intervalId);
    if (!imported) {
      Get.snackbar(
        'Mud Properties',
        'No Mud Plan data found for the selected interval.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _importSelectedIntervalMudPlanRheology() async {
    if (dashboard.isLocked.value) return;
    final intervalId = await _selectedReportIntervalId();
    if (intervalId == null || intervalId.trim().isEmpty) {
      Get.snackbar(
        'Rheology',
        'Select an interval in Well > General first.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    await c.useMudStateScope('');
    final imported = await c.importMudPlanRheologyFromInterval(intervalId);
    if (!imported) {
      Get.snackbar(
        'Rheology',
        'No Mud Plan rheology data found for the selected interval.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    _propertyScrollCtrl.dispose();
    _rheologyScrollCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTO-CALC DETECTION (VIEW-LEVEL)
  // PV and YP intentionally excluded — they stay editable (filled via
  // rheology Transfer button or manual entry).
  // All other computed fields get yellow read-only treatment.
  // ═══════════════════════════════════════════════════════════════════════════
  bool _isAutoCalcField(String name) {
    final k = name.toLowerCase().replaceAll('*', '').trim();
    // LSRYP
    if (k == 'lsryp' || k.contains('lsryp')) return true;
    // Oil/Water Ratio
    if (k.contains('oil') && k.contains('water') && k.contains('ratio'))
      return true;
    // Solids (% vol) and Total Solids — auto-calculated as 100-(Oil+Water)
    if ((k == 'solids' ||
            k.startsWith('solids') ||
            k == 'total solids' ||
            k.contains('total solids')) &&
        !k.contains('corr') &&
        !k.contains('drill') &&
        !k.contains('adj') &&
        !k.contains('salt'))
      return true;
    // Corrected Solids / Solids Adjusted for Salt
    if (k.contains('corrected solids') ||
        k.contains('corr. solids') ||
        k.contains('solids adjusted') ||
        k.contains('adjusted for salt'))
      return true;
    // Excess Lime - auto-calc = 0.26 * (Pm + Pf - Mf)
    if (k.contains('excess lime')) return true;
    // CaCl2 Concentration (mg/l) — auto-calc = 1.565 × Whole Mud Chlorides
    if (k.contains('cacl2 concentration') ||
        k.contains('cacl2 conc') ||
        (k.startsWith('cacl2') && k.contains('mg')))
      return true;
    // CaCl2 (% wt) — auto-calc from Whole Mud Chlorides + Water
    if (k.startsWith('cacl2') && (k.contains('wt') || k.contains('%')))
      return true;
    // Water Phase Salinity — cascades from CaCl2 Concentration
    if (k.contains('water phase salinity') || k.contains('water phase sal'))
      return true;
    // Whole Mud Alkalinity (POM) — EDITABLE user input, drives Excess Lime
    // Whole Mud Chlorides — EDITABLE user input, drives CaCl2 chain
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 1024;
        return Column(
          children: [
            _topControls(),
            Divider(height: 1, color: Colors.grey.shade300),
            Expanded(
              child: isSmallScreen
                  ? _buildMobileLayout()
                  : _buildDesktopLayout(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 570, child: _leftPanel()),
        VerticalDivider(width: 1, color: Colors.grey.shade300),
        Expanded(child: _rightPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [_leftPanel(), const SizedBox(height: 12), _rightPanel()],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP CONTROLS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _topControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text(
            'Fluid Name',
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 172,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapDown: (details) => _showValueMenu(
                details,
                currentValue: c.fluidnameController.text,
                onValueChanged: (value) =>
                    _setControllerValue(c.fluidnameController, value),
              ),
              child: TextField(
                controller: c.fluidnameController,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Fluid Type',
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: c.selectedFluidType.value,
                  items: const [
                    DropdownMenuItem(
                      value: 'Water-based',
                      child: Text(
                        'Water-based',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Oil-based',
                      child: Text('Oil-based', style: TextStyle(fontSize: 11)),
                    ),
                    DropdownMenuItem(
                      value: 'Synthetic',
                      child: Text('Synthetic', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  onChanged: dashboard.isLocked.value
                      ? null
                      : (v) => c.changeFluidType(v!),
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => Row(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: c.isCompletionFluid.value,
                    onChanged: dashboard.isLocked.value
                        ? null
                        : (v) => c.isCompletionFluid.value = v ?? false,
                    activeColor: AppTheme.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Text(
                  'Completion Fluid',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () =>
                c.selectedFluidType.value == 'Oil-based' ||
                    c.selectedFluidType.value == 'Synthetic'
                ? Row(
                    children: [
                      const SizedBox(width: 12),
                      Text(
                        'Salt Type',
                        style: AppTheme.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: c.selectedSaltType.value,
                            items: const [
                              DropdownMenuItem(
                                value: 'CaCl2',
                                child: Text(
                                  'CaCl2',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'NaCl',
                                child: Text(
                                  'NaCl',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'NaCl + CaCl2',
                                child: Text(
                                  'NaCl + CaCl2',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Sodium Formate',
                                child: Text(
                                  'Sodium Formate',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                            onChanged: dashboard.isLocked.value
                                ? null
                                : (v) {
                                    if (v != null) {
                                      c.changeSaltType(v);
                                    }
                                  },
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textPrimary,
                              fontSize: 11,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () =>
                c.selectedFluidType.value == 'Oil-based' ||
                    c.selectedFluidType.value == 'Synthetic'
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      const SizedBox(width: 12),
                      Transform.scale(
                        scale: 0.8,
                        child: Checkbox(
                          value: c.isWeightedMud.value,
                          onChanged: dashboard.isLocked.value
                              ? null
                              : (v) {
                                  c.isWeightedMud.value = v ?? false;
                                  c.fetchSolidAnalysis();
                                },
                          activeColor: AppTheme.primaryColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Text(
                        'Weighted Mud',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEFT PANEL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _leftPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                const Icon(Icons.science, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Mud Properties',
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Load selected interval Mud Plan',
                  child: InkWell(
                    onTap: _importSelectedIntervalMudPlan,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: Icon(
                        Icons.file_download_outlined,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Table
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.tableBorderBlue),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  children: [
                    _tableHeader(),
                    Expanded(
                      child: Scrollbar(
                        controller: _propertyScrollCtrl,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _propertyScrollCtrl,
                          child: Column(
                            children: [
                              ...c.propertyTable.entries.map((entry) {
                                final name = entry.key;
                                final values = entry.value;
                                final isLast =
                                    entry.key == c.propertyTable.keys.last;
                                return _propertyRow(name, values, isLast);
                              }),
                              _DynamicAddRows(c: c),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 6),

          // Footer
          Row(
            children: [
              Tooltip(
                message: 'Solid Analysis',
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const SolidAnalysisDialog(),
                  ),
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Titration',
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const TitrationDialog(),
                  ),
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '*Required',
                style: AppTheme.caption.copyWith(
                  color: Colors.red.shade400,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Sample for Calculation',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: c.sampleForCalculation.value,
                      items: ['1', '2', '3']
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => c.sampleForCalculation.value = v!,
                      isDense: true,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: _kMudHeaderHeight,
      decoration: BoxDecoration(
        color: AppTheme.tableHeaderBlue,
        border: const Border(
          bottom: BorderSide(color: AppTheme.tableBorderBlue),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        ),
      ),
      child: Row(
        children: [
          _headerCell('Property', width: _kMudPropertyWidth),
          ...c.samples.map(
            (s) => Expanded(child: _headerCell(s, center: true)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPERTY ROW — KEY CHANGE
  // Auto-calc fields → yellow read-only display (like rheology calculated rows)
  // PV / YP and all other fields → editable TextField (unchanged)
  // ═══════════════════════════════════════════════════════════════════════════
  String _mudPropertyLabel(String name, String storedUnit) {
    final unit = _dynamicMudUnit(name, storedUnit);
    return unit.isEmpty ? name : '$name ($unit)';
  }

  String _dynamicMudUnit(String name, String storedUnit) {
    final raw = storedUnit.trim();
    if (raw.isEmpty || raw == '-') return '';
    return AppUnits.strip(raw);
  }

  void _convertMudValuesForActiveUnits() {
    if (!mounted || c.isLoading.value || c.propertyTable.isEmpty) return;

    var changed = false;
    for (final entry in c.propertyTable.entries.toList()) {
      final name = entry.key;
      final sourceUnit = (c.propertyUnits[name] ?? '').trim();
      final targetUnit = _dynamicMudUnit(name, sourceUnit).trim();
      if (targetUnit.isEmpty) continue;

      if (sourceUnit.isEmpty) {
        c.propertyUnits[name] = targetUnit;
        changed = true;
        continue;
      }

      if (_sameMudUnit(sourceUnit, targetUnit)) {
        if (sourceUnit != targetUnit) {
          c.propertyUnits[name] = targetUnit;
          changed = true;
        }
        continue;
      }

      var conversionFailed = false;
      for (final cell in entry.value) {
        final current = cell.value.trim();
        if (current.isEmpty) continue;

        final converted = _convertMudCellValue(current, sourceUnit, targetUnit);
        if (converted == null) {
          conversionFailed = true;
          continue;
        }
        if (converted != cell.value) {
          cell.value = converted;
          changed = true;
        }
      }

      if (!conversionFailed) {
        c.propertyUnits[name] = targetUnit;
        changed = true;
      }
    }

    if (changed) {
      c.propertyUnits.refresh();
      c.saveMudReportState(force: true);
    }
  }

  String? _convertMudCellValue(String raw, String fromUnit, String toUnit) {
    final value = double.tryParse(raw.replaceAll(',', ''));
    if (value == null) return null;

    final converted = _convertMudNumber(value, fromUnit, toUnit);
    if (converted == null) return null;
    return _formatMudConverted(converted);
  }

  double? _convertMudNumber(double value, String fromUnit, String toUnit) {
    final from = _normalizeMudUnitForConversion(fromUnit);
    final to = _normalizeMudUnitForConversion(toUnit);
    if (_sameMudUnit(from, to)) return value;

    final fromTemp = _temperatureUnitKey(from);
    final toTemp = _temperatureUnitKey(to);
    if (fromTemp != null && toTemp != null) {
      return _convertTemperature(value, fromTemp, toTemp);
    }

    final fromRate = _splitRateUnit(from);
    final toRate = _splitRateUnit(to);
    if (fromRate != null && toRate != null && fromRate[1] == toRate[1]) {
      return AppUnits.convertValue(value, fromRate[0], toRate[0]);
    }

    final fromKey = _unitCompareKey(from);
    final toKey = _unitCompareKey(to);
    if ((fromKey == 'mg/l' || fromKey == 'ppm') &&
        (toKey == 'mg/l' || toKey == 'ppm')) {
      return value;
    }

    return AppUnits.convertValue(value, from, to);
  }

  String _normalizeMudUnitForConversion(String unit) {
    return AppUnits.strip(unit)
        .replaceAll('Ã‚', '')
        .replaceAll('Â', '')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .trim();
  }

  bool _sameMudUnit(String a, String b) =>
      _unitCompareKey(a) == _unitCompareKey(b);

  String _unitCompareKey(String unit) {
    final normalized = AppUnits.normalizedText(unit)
        .replaceAll('Ã‚', '')
        .replaceAll('Â', '')
        .replaceAll('²', '2')
        .replaceAll('³', '3')
        .replaceAll('\u00B0', 'deg')
        .replaceAll(RegExp(r'[()\s]'), '')
        .toLowerCase();
    if (normalized == 'f') return 'degf';
    if (normalized == 'c') return 'degc';
    return normalized;
  }

  String? _temperatureUnitKey(String unit) {
    final key = _unitCompareKey(unit);
    if (key == 'degf') return 'f';
    if (key == 'degc') return 'c';
    if (key == 'k') return 'k';
    return null;
  }

  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;
    final celsius = switch (from) {
      'f' => (value - 32) * 5 / 9,
      'k' => value - 273.15,
      _ => value,
    };
    return switch (to) {
      'f' => celsius * 9 / 5 + 32,
      'k' => celsius + 273.15,
      _ => celsius,
    };
  }

  List<String>? _splitRateUnit(String unit) {
    final compact = unit.replaceAll(' ', '');
    final lower = compact.toLowerCase();
    const suffix = '/30min';
    if (!lower.endsWith(suffix)) return null;
    return [compact.substring(0, compact.length - suffix.length), suffix];
  }

  String _formatMudConverted(double value) {
    final normalized = value.abs() < 0.0000001 ? 0.0 : value;
    if (normalized == normalized.truncateToDouble()) {
      return normalized.toInt().toString();
    }
    return normalized
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Widget _menuLabel(String label, String shortcut) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 10.5,
            ),
          ),
        ),
        Text(
          shortcut,
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _setControllerValue(TextEditingController controller, String value) {
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _showValueMenu(
    TapDownDetails details, {
    required String currentValue,
    required ValueChanged<String> onValueChanged,
    bool canEdit = true,
  }) async {
    final selected = await showMenu<_MudPropertyMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.cut,
          enabled: canEdit && currentValue.isNotEmpty,
          child: _menuLabel('Cut', 'Ctrl+X'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.copy,
          enabled: currentValue.isNotEmpty,
          child: _menuLabel('Copy', 'Ctrl+C'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.paste,
          enabled: canEdit,
          child: _menuLabel('Paste', 'Ctrl+V'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.delete,
          enabled: canEdit && currentValue.isNotEmpty,
          child: _menuLabel('Delete', 'Delete'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.top,
          enabled: false,
          child: _menuLabel('To the Top', 'Ctrl+Up'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.bottom,
          enabled: false,
          child: _menuLabel('To the Bottom', 'Ctrl+Down'),
        ),
      ],
    );

    if (!mounted || selected == null) return;

    switch (selected) {
      case _MudPropertyMenuAction.cut:
        await Clipboard.setData(ClipboardData(text: currentValue));
        onValueChanged('');
        break;
      case _MudPropertyMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: currentValue));
        break;
      case _MudPropertyMenuAction.paste:
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text != null) onValueChanged(data!.text!);
        break;
      case _MudPropertyMenuAction.delete:
        onValueChanged('');
        break;
      case _MudPropertyMenuAction.top:
      case _MudPropertyMenuAction.bottom:
        break;
    }
  }

  Future<void> _showPropertyRowMenu(TapDownDetails details, String name) async {
    final isRemovable = c.isPropertyRemovable(name);
    final selected = await showMenu<_MudPropertyMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.cut,
          enabled: false,
          child: _menuLabel('Cut', 'Ctrl+X'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.copy,
          enabled: false,
          child: _menuLabel('Copy', 'Ctrl+C'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.paste,
          enabled: false,
          child: _menuLabel('Paste', 'Ctrl+V'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.delete,
          enabled: isRemovable,
          child: _menuLabel('Delete', 'Delete'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.top,
          enabled: false,
          child: _menuLabel('To the Top', 'Ctrl+Up'),
        ),
        PopupMenuItem<_MudPropertyMenuAction>(
          value: _MudPropertyMenuAction.bottom,
          enabled: false,
          child: _menuLabel('To the Bottom', 'Ctrl+Down'),
        ),
      ],
    );

    if (!mounted || selected == null) return;
    if (selected == _MudPropertyMenuAction.delete && isRemovable) {
      c.removeAddedPropertyRow(name);
    }
  }

  Widget _propertyRow(String name, List<RxString> values, bool isLast) {
    final isAutoCalc = _isAutoCalcField(name);
    final isRemovable = c.isPropertyRemovable(name);
    final greyPlanCells =
        name == 'Description' ||
        name == 'Sample from' ||
        name == 'Time Sample Taken (hh:mm)';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: isRemovable
          ? (details) => _showPropertyRowMenu(details, name)
          : null,
      child: Container(
        height: _kMudRowHeight,
        decoration: BoxDecoration(
          // Grey tint for auto-calculated rows, white for editable
          color: isAutoCalc ? AppTheme.readOnlyCell : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : AppTheme.tableGridBlue,
            ),
          ),
        ),
        child: Row(
          children: [
            // ── Property name column ───────────────────────────────────────────
            Container(
              width: _kMudPropertyWidth,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppTheme.readOnlyCell,
                border: const Border(
                  right: BorderSide(color: AppTheme.tableGridBlue),
                ),
              ),
              child: Obx(() {
                final unit = c.propertyUnits[name] ?? '';
                final displayName = _mudPropertyLabel(name, unit);
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Small indicator icon for calculated fields
                    if (isAutoCalc)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Icon(
                          Icons.functions,
                          size: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                );
              }),
            ),

            // ── Sample value columns ───────────────────────────────────────────
            ...values.asMap().entries.map((cell) {
              if (greyPlanCells && cell.key == 4) {
                return const SizedBox.shrink();
              }
              final mergePlanCells = greyPlanCells && cell.key == 3;
              final isLastCol = cell.key == values.length - 1 || mergePlanCells;
              final isGreyReadOnly = isAutoCalc;

              return Expanded(
                flex: mergePlanCells ? 2 : 1,
                child: Container(
                  height: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isGreyReadOnly ? AppTheme.readOnlyCell : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isLastCol
                            ? Colors.transparent
                            : AppTheme.tableGridBlue,
                      ),
                    ),
                  ),
                  child: isGreyReadOnly
                      // ── READ-ONLY: auto-calculated value ──────────────────
                      ? Obx(
                          () => Center(
                            child: Text(
                              cell.value.value.isEmpty ? '-' : cell.value.value,
                              style: AppTheme.caption.copyWith(
                                color: cell.value.value.isEmpty
                                    ? Colors.grey.shade400
                                    : AppTheme.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      // ── EDITABLE: normal TextField ─────────────────────────
                      : Obx(
                          () => GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onSecondaryTapDown: (details) => _showValueMenu(
                              details,
                              currentValue: cell.value.value,
                              onValueChanged: (value) =>
                                  cell.value.value = value,
                            ),
                            child: TextField(
                              key: ValueKey('${name}_${cell.key}'),
                              controller:
                                  TextEditingController(text: cell.value.value)
                                    ..selection = TextSelection.collapsed(
                                      offset: cell.value.value.length,
                                    ),
                              onChanged: (v) => cell.value.value = v,
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textPrimary,
                                fontSize: 12.5,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 5,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIGHT PANEL — unchanged from original
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _rightPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rheology model selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Container(
                  height: 26,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'Rheology Model',
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFFB8D0EA)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: c.rheologyModel.value,
                        items: const [
                          DropdownMenuItem(
                            value: 'Bingham',
                            child: Text(
                              'Bingham',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Power Law',
                            child: Text(
                              'Power Law',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'HB',
                            child: Text(
                              'HB',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        onChanged: dashboard.isLocked.value
                            ? null
                            : (v) => c.changeModel(v!),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Load selected interval Mud Plan rheology',
                  child: InkWell(
                    onTap: _importSelectedIntervalMudPlanRheology,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: const Color(0xFFB8D0EA)),
                      ),
                      child: const Icon(
                        Icons.file_download_outlined,
                        size: 15,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Rheology table — COMPLETELY UNCHANGED from original
          Expanded(
            flex: 3,
            child: Obx(
              () => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.tableBorderBlue),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  children: [
                    Container(
                      height: _kMudHeaderHeight,
                      decoration: BoxDecoration(
                        color: AppTheme.tableHeaderBlue,
                        border: const Border(
                          bottom: BorderSide(color: AppTheme.tableBorderBlue),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                      child: Row(
                        children: [
                          _headerCell('RPM', width: 104),
                          ...c.samples.map(
                            (s) =>
                                Expanded(child: _headerCell(s, center: true)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _rheologyScrollCtrl,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _rheologyScrollCtrl,
                          child: Column(
                            children: c.rheologyTable.entries.map((entry) {
                              final isCalc = double.tryParse(entry.key) == null;
                              final isLast =
                                  entry.key == c.rheologyTable.keys.last;
                              return Container(
                                height: _kMudRowHeight,
                                decoration: BoxDecoration(
                                  color: isCalc
                                      ? AppTheme.calculatedCell
                                      : Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isLast
                                          ? Colors.transparent
                                          : AppTheme.tableGridBlue,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 104,
                                      height: double.infinity,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.readOnlyCell,
                                        border: Border(
                                          right: BorderSide(
                                            color: AppTheme.tableGridBlue,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        entry.key,
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    ...entry.value.asMap().entries.map((cell) {
                                      final isLastCol =
                                          cell.key == entry.value.length - 1;
                                      return Expanded(
                                        child: Container(
                                          height: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: isLastCol
                                                    ? Colors.transparent
                                                    : AppTheme.tableGridBlue,
                                              ),
                                            ),
                                          ),
                                          child: isCalc
                                              ? Obx(
                                                  () => Center(
                                                    child: Text(
                                                      cell.value.value.isEmpty
                                                          ? '-'
                                                          : cell.value.value,
                                                      style: AppTheme.caption
                                                          .copyWith(
                                                            color:
                                                                cell
                                                                    .value
                                                                    .value
                                                                    .isEmpty
                                                                ? Colors
                                                                      .grey
                                                                      .shade400
                                                                : AppTheme
                                                                      .textPrimary,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                )
                                              : Obx(
                                                  () => GestureDetector(
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    onSecondaryTapDown:
                                                        (
                                                          details,
                                                        ) => _showValueMenu(
                                                          details,
                                                          currentValue:
                                                              cell.value.value,
                                                          onValueChanged: (value) {
                                                            cell.value.value =
                                                                value;
                                                            c.handleRheologyInputChanged(
                                                              cell.key,
                                                            );
                                                          },
                                                        ),
                                                    child: TextField(
                                                      key: ValueKey(
                                                        'rheo_${entry.key}_${cell.key}',
                                                      ),
                                                      controller:
                                                          TextEditingController(
                                                              text: cell
                                                                  .value
                                                                  .value,
                                                            )
                                                            ..selection =
                                                                TextSelection.collapsed(
                                                                  offset: cell
                                                                      .value
                                                                      .value
                                                                      .length,
                                                                ),
                                                      onChanged: (v) {
                                                        cell.value.value = v;
                                                        c.handleRheologyInputChanged(
                                                          cell.key,
                                                        );
                                                      },
                                                      style: AppTheme.caption
                                                          .copyWith(
                                                            color: AppTheme
                                                                .textPrimary,
                                                            fontSize: 12,
                                                          ),
                                                      decoration:
                                                          const InputDecoration(
                                                            isDense: true,
                                                            border: InputBorder
                                                                .none,
                                                            contentPadding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 5,
                                                                ),
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          TextInputType.number,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Radio + action buttons — unchanged
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFB8D0EA)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Obx(
                  () => Row(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Radio<String>(
                          value: 'API (RP 13D)',
                          groupValue: c.rheologyCalculation.value,
                          onChanged: dashboard.isLocked.value
                              ? null
                              : (v) => c.rheologyCalculation.value = v!,
                          activeColor: AppTheme.primaryColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Text(
                        'API (RP 13D)',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Obx(
                  () => Row(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Radio<String>(
                          value: 'Use All Readings',
                          groupValue: c.rheologyCalculation.value,
                          onChanged: dashboard.isLocked.value
                              ? null
                              : (v) => c.rheologyCalculation.value = v!,
                          activeColor: AppTheme.primaryColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Text(
                        'Use All Readings',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _iconBtn(
                  icon: Icons.calculate_outlined,
                  color: AppTheme.primaryColor,
                  tooltip: 'Calculate',
                  onTap: () => c.calculateRheology(),
                ),
                const SizedBox(width: 4),
                _iconBtn(
                  icon: Icons.show_chart,
                  color: Colors.orange,
                  tooltip: 'Apply Rheology to Samples',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ApplyRheologyPage(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _iconBtn(
                  icon: Icons.arrow_back,
                  color: Colors.green,
                  tooltip: 'Transfer Rheology to Property Table',
                  onTap: () => c.transferRheologyToPropertyTable(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Bottom small tables — unchanged
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: _smallTable(
                    'Specific Gravity',
                    isSpecificGravity: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _smallTable('Solids', isSolids: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SMALL TABLES — unchanged
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _smallTable(
    String title, {
    bool isSpecificGravity = false,
    bool isSolids = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFB8D0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FC),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFB8D0EA)),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            child: Text(
              title,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          if (isSpecificGravity) ...[
            _sgRow('Oil (SG)', c.oilSgController),
            _sgRow('HGS (SG)', c.hgsSgController),
            _sgRow('LGS (SG)', c.lgsSgController),
          ] else if (isSolids) ...[
            _sgRow('Shale CEC (meq/100g)', c.shaleCecController),
            _sgRow('Bent CEC (meq/100g)', c.bentCecController),
          ],
        ],
      ),
    );
  }

  Widget _sgRow(String label, TextEditingController controller) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: Color(0xFFCFE0F2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: double.infinity,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              color: Colors.grey.shade100,
              child: Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Obx(() {
              if (dashboard.isLocked.value) {
                return Text(
                  controller.text.isEmpty ? '-' : controller.text,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                );
              }
              return Container(
                width: 70,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: const Color(0xFFB8D0EA)),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onSecondaryTapDown: (details) => _showValueMenu(
                    details,
                    currentValue: controller.text,
                    onValueChanged: (value) =>
                        _setControllerValue(controller, value),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                    ),
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _headerCell(String text, {double? width, bool center = false}) {
    Widget child = Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFCFE0F2))),
      ),
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(
          text,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return child;
  }

  Widget _snapHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFB8D0EA))),
        ),
        child: Text(
          text,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DYNAMIC ADD ROW — unchanged from original
// ═══════════════════════════════════════════════════════════════════════════
class _DynamicAddRows extends StatefulWidget {
  final MudController c;
  const _DynamicAddRows({required this.c});

  @override
  State<_DynamicAddRows> createState() => _DynamicAddRowsState();
}

class _DynamicAddRowsState extends State<_DynamicAddRows> {
  String? _currentPick;

  void _onPicked(String? value) {
    if (value == null) return;
    widget.c.addPropertyRow(value);
    setState(() => _currentPick = null);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allOptions = widget.c.availableProperties.toList();
      if (allOptions.isEmpty) return const SizedBox.shrink();
      return _SingleDropdownRow(
        allOptions: allOptions,
        samples: widget.c.samples,
        onPicked: _onPicked,
      );
    });
  }
}

class _SingleDropdownRow extends StatefulWidget {
  final List<String> allOptions;
  final List<String> samples;
  final ValueChanged<String?> onPicked;

  const _SingleDropdownRow({
    required this.allOptions,
    required this.samples,
    required this.onPicked,
  });

  @override
  State<_SingleDropdownRow> createState() => _SingleDropdownRowState();
}

class _SingleDropdownRowState extends State<_SingleDropdownRow> {
  String? _value;

  @override
  void didUpdateWidget(_SingleDropdownRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _MudViewState._kMudRowHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            width: _MudViewState._kMudPropertyWidth,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _value,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Add property',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                items: widget.allOptions
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _value = null);
                  widget.onPicked(v);
                },
                isDense: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 10),
              ),
            ),
          ),
          ...widget.samples.asMap().entries.map((e) {
            final isLast = e.key == widget.samples.length - 1;
            return Expanded(
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: isLast ? Colors.transparent : Colors.grey.shade200,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
