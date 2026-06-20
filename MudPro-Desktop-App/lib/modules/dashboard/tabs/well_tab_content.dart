import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/engineers_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/drill_string_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/nozzle_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/well_general_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/compact_tabular_database_dialog.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/cased_hole_controller.dart';

const double _kRowH = 20.0;
const double _kHeaderH = 22.0;
const double _kTableHeaderH = 36.0;
const double _kFooterH = 18.0;
const double _kSectionGap = 3.0;
const Color _kWellPanelBorder = Color(0xFFC8CCD1);
const Color _kGridHeaderColor = Color(0xFFF1F1F1);
const Color _kEditableCellColor = Color(0xFFFFF7CC);
const Color _kSelectedRowColor = Color(0xFFDCE8F7);
const Color _kAltRowColor = Color(0xFFFBFBFB);
const TextStyle _kWellHeaderTextStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Colors.black,
);
const TextStyle _kWellInputTextStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w700,
  color: Colors.black,
);
const TextStyle _kWellSmallInputTextStyle = TextStyle(
  fontSize: 9,
  fontWeight: FontWeight.w700,
  color: Colors.black,
);

Color _cellFillColor({
  required bool isLocked,
  required bool editableWhenUnlocked,
}) => isLocked || !editableWhenUnlocked ? _kEditableCellColor : Colors.white;

int? _wellDecimalPlacesFromText(String value) {
  final text = value.trim().replaceAll(',', '');
  final decimalIndex = text.indexOf('.');
  if (decimalIndex < 0) return null;
  return (text.length - decimalIndex - 1).clamp(0, 12).toInt();
}

String _formatWellConvertedNumber(double value, {String? sourceText}) {
  final sourceDecimals =
      sourceText == null ? null : _wellDecimalPlacesFromText(sourceText);
  if (sourceDecimals != null) {
    return value.toStringAsFixed(sourceDecimals);
  }
  return value
      .toStringAsFixed(4)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

String _displayCurrencyLabel(String rawCurrency) {
  final trimmed = rawCurrency.trim();
  return trimmed.isEmpty ? '\$' : trimmed;
}

enum _WellRowMenuAction { cut, copy, paste, delete, clear, toTop, toBottom }

class _WellRowClipboard {
  static String? _section;
  static List<String>? _values;

  static bool canPaste(String section) =>
      _section == section && _values != null && _values!.isNotEmpty;

  static Future<void> copy(String section, List<String> values) async {
    _section = section;
    _values = List<String>.from(values);
    await Clipboard.setData(ClipboardData(text: values.join('\t')));
  }

  static Future<List<String>?> paste(String section) async {
    if (!canPaste(section)) return null;
    return List<String>.from(_values!);
  }
}

Widget _wellPanel({required Widget child}) => Container(
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _kWellPanelBorder),
  ),
  child: child,
);

Widget _sectionTitle(String title) => Container(
  height: _kHeaderH,
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 6),
  alignment: Alignment.centerLeft,
  color: AppTheme.primaryColor,
  child: Text(title, style: _kWellHeaderTextStyle),
);

Widget _toolButton({
  required Widget child,
  VoidCallback? onTap,
  String? tooltip,
  double size = 22,
}) {
  Widget button = SizedBox(
    width: size,
    height: size,
    child: Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kWellPanelBorder),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    ),
  );

  if (tooltip != null && tooltip.isNotEmpty) {
    button = Tooltip(message: tooltip, child: button);
  }

  return button;
}

Widget _rowMenuTarget({
  required Widget child,
  required ValueChanged<TapDownDetails> onSecondaryTapDown,
}) => GestureDetector(
  behavior: HitTestBehavior.opaque,
  onSecondaryTapDown: onSecondaryTapDown,
  child: child,
);

Future<_WellRowMenuAction?> _showWellRowMenu(
  BuildContext context,
  TapDownDetails details, {
  required bool canPaste,
  bool canDelete = true,
  bool canMove = true,
}) {
  return showMenu<_WellRowMenuAction>(
    context: context,
    position: RelativeRect.fromLTRB(
      details.globalPosition.dx,
      details.globalPosition.dy,
      details.globalPosition.dx,
      details.globalPosition.dy,
    ),
    items: [
      const PopupMenuItem(
        value: _WellRowMenuAction.cut,
        child: Text('Cut', style: TextStyle(fontSize: 11)),
      ),
      const PopupMenuItem(
        value: _WellRowMenuAction.copy,
        child: Text('Copy', style: TextStyle(fontSize: 11)),
      ),
      PopupMenuItem(
        value: _WellRowMenuAction.paste,
        enabled: canPaste,
        child: const Text('Paste', style: TextStyle(fontSize: 11)),
      ),
      PopupMenuItem(
        value: _WellRowMenuAction.delete,
        enabled: canDelete,
        child: const Text('Delete', style: TextStyle(fontSize: 11)),
      ),
      const PopupMenuItem(
        value: _WellRowMenuAction.clear,
        child: Text('Clear', style: TextStyle(fontSize: 11)),
      ),
      PopupMenuItem(
        value: _WellRowMenuAction.toTop,
        enabled: canMove,
        child: const Text('To the Top', style: TextStyle(fontSize: 11)),
      ),
      PopupMenuItem(
        value: _WellRowMenuAction.toBottom,
        enabled: canMove,
        child: const Text('To the Bottom', style: TextStyle(fontSize: 11)),
      ),
    ],
  );
}

const List<String> _kTimeSlots = [
  '00:00',
  '00:30',
  '01:00',
  '01:30',
  '02:00',
  '02:30',
  '03:00',
  '03:30',
  '04:00',
  '04:30',
  '05:00',
  '05:30',
  '06:00',
  '06:30',
  '07:00',
  '07:30',
  '08:00',
  '08:30',
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '12:00',
  '12:30',
  '13:00',
  '13:30',
  '14:00',
  '14:30',
  '15:00',
  '15:30',
  '16:00',
  '16:30',
  '17:00',
  '17:30',
  '18:00',
  '18:30',
  '19:00',
  '19:30',
  '20:00',
  '20:30',
  '21:00',
  '21:30',
  '22:00',
  '22:30',
  '23:00',
  '23:30',
];

// ─── Date helpers ────────────────────────────────────────────────
DateTime? _parseLongDate(String s) {
  try {
    final clean = s.contains(',')
        ? s.substring(s.indexOf(',') + 1).trim()
        : s.trim();
    const months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    final parts = clean.replaceAll(',', '').split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final month = months[parts[0].toLowerCase()];
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
  } catch (_) {}
  return null;
}

String _formatDisplay(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

String _formatStorage(DateTime d) {
  const dn = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const mn = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${dn[d.weekday]}, ${mn[d.month]} ${d.day}, ${d.year}';
}

// ═══════════════════════════════════════════════════════════════════
//  ROOT
// ═══════════════════════════════════════════════════════════════════
class WellTabContent extends StatelessWidget {
  final c = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AppUnits.signature;
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Container(
              color: AppTheme.backgroundColor,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: LeftPortion(),
                      ),
                      const SizedBox(height: _kSectionGap),
                      MiddlePortion(),
                      const SizedBox(height: _kSectionGap),
                      RightPortion(),
                    ],
                  ),
                ),
              ),
            );
          }
          final double usableWidth =
              constraints.maxWidth - (_kSectionGap * 2) - 6;
          final double leftWidth = (usableWidth * 0.228).clamp(296.0, 352.0);
          final double rightWidth = (usableWidth * 0.238).clamp(304.0, 362.0);
          return Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(1, 1, 1, 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: leftWidth, child: LeftPortion()),
                  const SizedBox(width: _kSectionGap),
                  Expanded(child: MiddlePortion()),
                  const SizedBox(width: _kSectionGap),
                  SizedBox(width: rightWidth, child: RightPortion()),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class LeftPortion extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GeneralSection();
}

// ═══════════════════════════════════════════════════════════════════
//  GENERAL SECTION  — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class GeneralSection extends StatefulWidget {
  @override
  _GeneralSectionState createState() => _GeneralSectionState();
}

class _GeneralSectionState extends State<GeneralSection> {
  final c = Get.find<DashboardController>();
  final companyCtrl = Get.isRegistered<CompanyController>()
      ? Get.find<CompanyController>()
      : Get.put(CompanyController(), permanent: true);
  late final EngineerController engineerCtrl;
  final activityCtrl = Get.isRegistered<OthersController>()
      ? Get.find<OthersController>()
      : Get.put(OthersController(), permanent: true);
  final wellGenCtrl = Get.isRegistered<WellGeneralController>()
      ? Get.find<WellGeneralController>()
      : Get.put(WellGeneralController(), permanent: true);
  final intervalCtrl = Get.isRegistered<IntervalController>()
      ? Get.find<IntervalController>()
      : Get.put(IntervalController(), permanent: true);
  Worker? _wellWorker;
  Worker? _reportWorker;
  Worker? _intervalWorker;
  Worker? _mdWorker;
  Worker? _depthDrilledWorker;
  final List<Worker> _unitWorkers = <Worker>[];
  late String _lengthUnit;
  late String _forceUnit;
  late String _torqueUnit;
  late String _tempUnit;
  late String _mudWeightUnit;
  late String _ropUnit;

  List<String> activityOptions = [
    'Rig-up/Service',
    'Drilling',
    'Circulating',
    'Tripping',
    'Survey',
    'Logging',
    'Run Casing',
    'Testing',
    'Coring/Reaming',
    'Cementing',
  ];
  bool _isLoadingActivities = true;
  bool _isLoadingEngineers = true;

  late final Map<String, TextEditingController> fc;

  String _storedDate = '';
  String selectedTime = '23:30';
  String? selectedEngId;
  String? selectedEng2Id;
  String selectedActivity = '';
  String selectedInterval = '';

  List<IntervalItem> _sortedIntervals() {
    final items = intervalCtrl.intervals.toList();
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  List<String> get dynamicIntervalOptions => _intervalNames();

  List<String> _intervalNames() {
    final rawNames = _sortedIntervals()
        .map((interval) => interval.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final counts = <String, int>{};
    for (final name in rawNames) {
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final output = <String>[];
    for (var i = 0; i < rawNames.length; i++) {
      final name = rawNames[i];
      output.add((counts[name] ?? 0) > 1 ? '${i + 1}. $name' : name);
    }
    return output;
  }

  String? _displayLabelForIntervalId(
    String? intervalId, {
    List<IntervalItem>? sorted,
  }) {
    if (intervalId == null || intervalId.trim().isEmpty) return null;
    final items = sorted ?? _sortedIntervals();
    final names = items.map((interval) => interval.name.trim()).toList();
    final counts = <String, int>{};
    for (final name in names) {
      counts[name] = (counts[name] ?? 0) + 1;
    }
    for (var i = 0; i < items.length; i++) {
      if (items[i].id != intervalId) continue;
      final name = items[i].name.trim();
      if (name.isEmpty) return null;
      return (counts[name] ?? 0) > 1 ? '${i + 1}. $name' : name;
    }
    return null;
  }

  String _resolveIntervalSelection(String value) {
    final names = _intervalNames();
    if (names.isEmpty) return value.trim();
    final cleanValue = value.trim();
    if (names.contains(cleanValue)) return cleanValue;

    final sorted = _sortedIntervals();
    for (final interval in sorted) {
      if (interval.name.trim() == cleanValue && cleanValue.isNotEmpty) {
        return _displayLabelForIntervalId(interval.id, sorted: sorted) ??
            cleanValue;
      }
    }

    final selectedLabel = _displayLabelForIntervalId(
      intervalCtrl.selected.value?.id,
      sorted: sorted,
    );
    return selectedLabel ?? names.first;
  }

  void _handleIntervalListChange() {
    final nextInterval = _resolveIntervalSelection(selectedInterval);
    if (nextInterval != selectedInterval) {
      setState(() => selectedInterval = nextInterval);
      _sync();
    } else {
      setState(() {});
    }
  }

  String get _displayDate {
    if (_storedDate.isEmpty) return '';
    final dt = _parseLongDate(_storedDate);
    return dt != null ? _formatDisplay(dt) : _storedDate;
  }

  @override
  void initState() {
    super.initState();
    engineerCtrl = Get.isRegistered<EngineerController>()
        ? Get.find<EngineerController>()
        : Get.put(EngineerController());
    _lengthUnit = AppUnits.length;
    _forceUnit = AppUnits.force;
    _torqueUnit = AppUnits.torque;
    _tempUnit = AppUnits.temperature;
    _mudWeightUnit = AppUnits.mudWeight;
    _ropUnit = AppUnits.rop;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
    _intervalWorker = ever(intervalCtrl.intervals, (_) {
      if (mounted) _handleIntervalListChange();
    });

    fc = {
      'Report #': TextEditingController(),
      'User Report #': TextEditingController(),
      'Bottom T.': TextEditingController(),
      'MD': TextEditingController(),
      'TVD': TextEditingController(),
      'Inc': TextEditingController(),
      'Azi': TextEditingController(),
      'WOB': TextEditingController(),
      'Rot. Wt.': TextEditingController(),
      'S/O Wt.': TextEditingController(),
      'P/U Wt.': TextEditingController(),
      'RPM': TextEditingController(),
      'ROP': TextEditingController(),
      'Off-bottom TQ': TextEditingController(),
      'On-bottom TQ': TextEditingController(),
      'Suction T.': TextEditingController(),
      'Additional Footage': TextEditingController(),
      'NPT Time': TextEditingController(),
      'NPT Cost': TextEditingController(),
      'Depth Drilled': TextEditingController(),
      'Operator Rep.': TextEditingController(),
      'Contractor Rep.': TextEditingController(),
      'FIT': TextEditingController(),
      'Formation': TextEditingController(),
    };
    _fetchActivities();
    _fetchEngineers();
    _loadIntervals();
    _loadFromApi();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      _loadIntervals();
      _loadFromApi();
    });
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => _loadFromApi(),
    );
    _mdWorker = ever<String>(wellGenCtrl.md, (value) {
      final controller = fc['MD'];
      if (controller == null || controller.text == value) return;
      controller.text = value;
      if (mounted) {
        setState(() {});
      }
    });
    _depthDrilledWorker = ever<String>(wellGenCtrl.depthDrilled, (value) {
      final controller = fc['Depth Drilled'];
      if (controller == null || controller.text == value) return;
      controller.text = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadIntervals() async {
    final wellId = padWellContext.selectedWellId.value.trim();
    if (wellId.isEmpty) {
      intervalCtrl.intervals.clear();
      intervalCtrl.groups.clear();
      intervalCtrl.selected.value = null;
      return;
    }
    intervalCtrl.wellId.value = wellId;
    await intervalCtrl.fetchAll();
    if (!mounted) return;
    final nextInterval = _resolveIntervalSelection(selectedInterval);
    if (nextInterval != selectedInterval) {
      setState(() => selectedInterval = nextInterval);
      _sync();
    } else {
      setState(() {});
    }
  }

  void _handleUnitChange() {
    final nextLengthUnit = AppUnits.length;
    final nextForceUnit = AppUnits.force;
    final nextTorqueUnit = AppUnits.torque;
    final nextTempUnit = AppUnits.temperature;
    final nextMudWeightUnit = AppUnits.mudWeight;
    final nextRopUnit = AppUnits.rop;
    if (_lengthUnit == nextLengthUnit &&
        _forceUnit == nextForceUnit &&
        _torqueUnit == nextTorqueUnit &&
        _tempUnit == nextTempUnit &&
        _mudWeightUnit == nextMudWeightUnit &&
        _ropUnit == nextRopUnit) {
      return;
    }

    _convertField('MD', _lengthUnit, nextLengthUnit);
    _convertField('TVD', _lengthUnit, nextLengthUnit);
    _convertField('Additional Footage', _lengthUnit, nextLengthUnit);
    _convertField('Depth Drilled', _lengthUnit, nextLengthUnit);

    _convertField('WOB', _forceUnit, nextForceUnit);
    _convertField('Rot. Wt.', _forceUnit, nextForceUnit);
    _convertField('S/O Wt.', _forceUnit, nextForceUnit);
    _convertField('P/U Wt.', _forceUnit, nextForceUnit);

    _convertField('Off-bottom TQ', _torqueUnit, nextTorqueUnit);
    _convertField('On-bottom TQ', _torqueUnit, nextTorqueUnit);

    _convertField('Suction T.', _tempUnit, nextTempUnit);
    _convertField('Bottom T.', _tempUnit, nextTempUnit);

    _convertField('FIT', _mudWeightUnit, nextMudWeightUnit);
    _convertField('ROP', _ropUnit, nextRopUnit);

    _lengthUnit = nextLengthUnit;
    _forceUnit = nextForceUnit;
    _torqueUnit = nextTorqueUnit;
    _tempUnit = nextTempUnit;
    _mudWeightUnit = nextMudWeightUnit;
    _ropUnit = nextRopUnit;
    _sync();
  }

  void _convertField(String key, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return;
    final controller = fc[key];
    if (controller == null) return;
    final raw = controller.text.trim();
    if (raw.isEmpty) return;
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) return;
    final converted = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (converted == null) return;
    controller.text = _formatWellConvertedNumber(converted, sourceText: raw);
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _fetchActivities() async {
    try {
      final acts = await activityCtrl.getActivities();
      setState(() {
        activityOptions = acts.map((a) => a.description).toList();
        _isLoadingActivities = false;
        if (selectedActivity.isNotEmpty &&
            !activityOptions.contains(selectedActivity))
          selectedActivity = activityOptions.isNotEmpty
              ? activityOptions.first
              : '';
      });
    } catch (_) {
      setState(() => _isLoadingActivities = false);
    }
  }

  Future<void> _fetchEngineers() async {
    try {
      await engineerCtrl.fetchEngineers();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isLoadingEngineers = false);
    await _loadFromApi();
  }

  Future<void> _loadFromApi() async {
    await wellGenCtrl.fetchLatest();
    final w = wellGenCtrl;
    if (!mounted) return;
    setState(() {
      fc['Report #']!.text = w.reportNo.value;
      fc['User Report #']!.text = w.userReportNo.value;
      fc['MD']!.text = w.md.value;
      fc['TVD']!.text = w.tvd.value;
      fc['Inc']!.text = w.inc.value;
      fc['Azi']!.text = w.azi.value;
      fc['WOB']!.text = w.wob.value;
      fc['Rot. Wt.']!.text = w.rotWt.value;
      fc['S/O Wt.']!.text = w.soWt.value;
      fc['P/U Wt.']!.text = w.puWt.value;
      fc['RPM']!.text = w.rpm.value;
      fc['ROP']!.text = w.rop.value;
      fc['Off-bottom TQ']!.text = w.offBottomTq.value;
      fc['On-bottom TQ']!.text = w.onBottomTq.value;
      fc['Suction T.']!.text = w.suctionT.value;
      fc['Bottom T.']!.text = w.bottomT.value;
      fc['Additional Footage']!.text = w.additionalFootage.value;
      fc['NPT Time']!.text = w.nptTime.value;
      fc['NPT Cost']!.text = w.nptCost.value;
      fc['Depth Drilled']!.text = w.depthDrilled.value;
      fc['Operator Rep.']!.text = w.operatorRep.value;
      fc['Contractor Rep.']!.text = w.contractorRep.value;
      fc['FIT']!.text = w.fit.value;
      fc['Formation']!.text = w.formation.value;

      _storedDate = w.date.value;
      selectedTime = w.time.value.isNotEmpty ? w.time.value : '23:30';
      selectedActivity = w.activity.value;
      selectedInterval = intervalCtrl.intervals.isEmpty
          ? w.interval.value
          : _resolveIntervalSelection(w.interval.value);
      selectedEngId = null;
      selectedEng2Id = null;

      if (w.engineer.value.isNotEmpty) {
        final eng = engineerCtrl.engineers.firstWhere(
          (e) => '${e.firstName} ${e.lastName}' == w.engineer.value,
          orElse: () => Engineer(
            firstName: '',
            lastName: '',
            cell: '',
            office: '',
            email: '',
          ),
        );
        if (eng.id != null) selectedEngId = eng.id;
      }
      if (w.engineer2.value.isNotEmpty) {
        final eng2 = engineerCtrl.engineers.firstWhere(
          (e) => '${e.firstName} ${e.lastName}' == w.engineer2.value,
          orElse: () => Engineer(
            firstName: '',
            lastName: '',
            cell: '',
            office: '',
            email: '',
          ),
        );
        if (eng2.id != null) selectedEng2Id = eng2.id;
      }
    });
  }

  void _sync() {
    final w = wellGenCtrl;
    w.reportNo.value = fc['Report #']!.text;
    w.userReportNo.value = fc['User Report #']!.text;
    w.date.value = _storedDate;
    w.time.value = selectedTime;
    w.engineer.value = _engName(selectedEngId);
    w.engineer2.value = _engName(selectedEng2Id);
    w.operatorRep.value = fc['Operator Rep.']!.text;
    w.contractorRep.value = fc['Contractor Rep.']!.text;
    w.activity.value = selectedActivity;
    w.md.value = fc['MD']!.text;
    w.tvd.value = fc['TVD']!.text;
    w.inc.value = fc['Inc']!.text;
    w.azi.value = fc['Azi']!.text;
    w.wob.value = fc['WOB']!.text;
    w.rotWt.value = fc['Rot. Wt.']!.text;
    w.soWt.value = fc['S/O Wt.']!.text;
    w.puWt.value = fc['P/U Wt.']!.text;
    w.rpm.value = fc['RPM']!.text;
    w.rop.value = fc['ROP']!.text;
    w.offBottomTq.value = fc['Off-bottom TQ']!.text;
    w.onBottomTq.value = fc['On-bottom TQ']!.text;
    w.suctionT.value = fc['Suction T.']!.text;
    w.bottomT.value = fc['Bottom T.']!.text;
    w.interval.value = selectedInterval;
    w.fit.value = fc['FIT']!.text;
    w.formation.value = fc['Formation']!.text;
    w.additionalFootage.value = fc['Additional Footage']!.text;
    w.nptTime.value = fc['NPT Time']!.text;
    w.nptCost.value = fc['NPT Cost']!.text;
    w.depthDrilled.value = fc['Depth Drilled']!.text;
  }

  @override
  void dispose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    _intervalWorker?.dispose();
    _mdWorker?.dispose();
    _depthDrilledWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    fc.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _wellPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("General"),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: _kWellPanelBorder, width: 1),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(1.34),
                  1: FlexColumnWidth(1.32),
                  2: FlexColumnWidth(0.48),
                },
                children: [
                  _tfRow("Report #", "Report #", ""),
                  _tfRow("User Report #", "User Report #", ""),
                  _dateRow(),
                  _timeRow(),
                  _engRow("Engineer", selectedEngId, (v) {
                    setState(() => selectedEngId = v);
                    _sync();
                  }),
                  _engRow("Engineer 2", selectedEng2Id, (v) {
                    setState(() => selectedEng2Id = v);
                    _sync();
                  }),
                  _tfRow("Operator Rep.", "Operator Rep.", ""),
                  _tfRow("Contractor Rep.", "Contractor Rep.", ""),
                  _ddRow("Activity", selectedActivity, activityOptions, (v) {
                    setState(() => selectedActivity = v!);
                    _sync();
                  }),
                  _tfRow("MD", "MD", "ft"),
                  _tfRow("TVD", "TVD", "ft"),
                  _tfRow("Inc", "Inc", "°"),
                  _tfRow("Azi", "Azi", "°"),
                  _tfRow("WOB", "WOB", "lbf"),
                  _tfRow("Rot. Wt.", "Rot. Wt.", "lbf"),
                  _tfRow("S/O Wt.", "S/O Wt.", "lbf"),
                  _tfRow("P/U Wt.", "P/U Wt.", "lbf"),
                  _tfRow("RPM", "RPM", "rpm"),
                  _tfRow("ROP", "ROP", "ft/hr"),
                  _tfRow("Off-bottom TQ", "Off-bottom TQ", "ft-lb"),
                  _tfRow("On-bottom TQ", "On-bottom TQ", "ft-lb"),
                  _tfRow("Suction T.", "Suction T.", "°F"),
                  _tfRow("Bottom T.", "Bottom T.", "°F"),
                  _ddRow("Interval", selectedInterval, dynamicIntervalOptions, (
                    v,
                  ) {
                    setState(() => selectedInterval = v!);
                    _sync();
                  }),
                  _tfRow("FIT", "FIT", "ppg"),
                  _tfRow("Formation", "Formation", ""),
                  _tfRow("Additional Footage", "Additional Footage", "ft"),
                  _tfRow("NPT Time", "NPT Time", "hr"),
                  _currencyTfRow("NPT Cost", "NPT Cost"),
                  _tfRow("Depth Drilled", "Depth Drilled", "ft"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lbl(String t) => Container(
    height: _kRowH,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    alignment: Alignment.centerLeft,
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
      ),
    ),
  );

  Widget _unit(String t) => Container(
    height: _kRowH,
    padding: const EdgeInsets.symmetric(horizontal: 2),
    alignment: Alignment.center,
    child: Text(
      AppUnits.unitText(t),
      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
    ),
  );

  Widget _lockedText(String text) => SizedBox(
    height: _kRowH,
    child: Container(
      color: _cellFillColor(isLocked: true, editableWhenUnlocked: false),
      alignment: Alignment.center,
      child: Text(
        text,
        style: _kWellInputTextStyle,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );

  TableRow _tfRow(String label, String key, String unit) {
    final ctrl = fc[key]!;
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _lbl(label),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Obx(() {
            if (c.isLocked.value) {
              return _lockedText(ctrl.text);
            }
            return Container(
              color: _cellFillColor(
                isLocked: false,
                editableWhenUnlocked: true,
              ),
              child: SizedBox(
                height: _kRowH,
                child: TextField(
                  controller: ctrl,
                  onChanged: (val) => _sync(),
                  style: _kWellInputTextStyle,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            );
          }),
        ),
        _unit(unit),
      ],
    );
  }

  TableRow _currencyTfRow(String label, String key) {
    final ctrl = fc[key]!;
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _lbl(label),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Obx(() {
            if (c.isLocked.value) {
              return _lockedText(ctrl.text);
            }
            return Container(
              color: _cellFillColor(
                isLocked: false,
                editableWhenUnlocked: true,
              ),
              child: SizedBox(
                height: _kRowH,
                child: TextField(
                  controller: ctrl,
                  onChanged: (val) => _sync(),
                  style: _kWellInputTextStyle,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            );
          }),
        ),
        Obx(
          () => _unit(_displayCurrencyLabel(companyCtrl.currencySymbol.value)),
        ),
      ],
    );
  }

  TableRow _dateRow() => TableRow(
    decoration: const BoxDecoration(color: Colors.white),
    children: [
      _lbl("Date"),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(
          () => c.isLocked.value
              ? _lockedText(_displayDate)
              : Container(
                  color: _cellFillColor(
                    isLocked: false,
                    editableWhenUnlocked: true,
                  ),
                  child: SizedBox(
                    height: _kRowH,
                    child: TextButton(
                      onPressed: () async {
                        final initial =
                            _parseLongDate(_storedDate) ?? DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _storedDate = _formatStorage(picked));
                          _sync();
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _displayDate,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 13,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
      _unit(''),
    ],
  );

  TableRow _timeRow() => TableRow(
    decoration: const BoxDecoration(color: Colors.white),
    children: [
      _lbl("Time"),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(
          () => c.isLocked.value
              ? _lockedText(selectedTime)
              : Container(
                  color: _cellFillColor(
                    isLocked: false,
                    editableWhenUnlocked: true,
                  ),
                  child: SizedBox(
                    height: _kRowH,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedTime,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 13),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        menuMaxHeight: 200,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => selectedTime = v);
                            _sync();
                          }
                        },
                        items: _kTimeSlots
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Center(
                                  child: Text(t, style: _kWellInputTextStyle),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ),
      _unit(''),
    ],
  );

  TableRow _ddRow(
    String label,
    String val,
    List<String> opts,
    ValueChanged<String?> onChange,
  ) => TableRow(
    decoration: const BoxDecoration(color: Colors.white),
    children: [
      _lbl(label),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(
          () => c.isLocked.value
              ? _lockedText(val)
              : Container(
                  color: _cellFillColor(
                    isLocked: false,
                    editableWhenUnlocked: true,
                  ),
                  child: SizedBox(
                    height: _kRowH,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: opts.contains(val) ? val : null,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 13),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        menuMaxHeight: 200,
                        onChanged: onChange,
                        items: opts
                            .map(
                              (o) => DropdownMenuItem(
                                value: o,
                                child: Center(
                                  child: Text(
                                    o,
                                    style: _kWellInputTextStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ),
      _unit(''),
    ],
  );

  TableRow _engRow(
    String label,
    String? engId,
    ValueChanged<String?> onChange,
  ) => TableRow(
    decoration: const BoxDecoration(color: Colors.white),
    children: [
      _lbl(label),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(() {
          if (c.isLocked.value) {
            return _lockedText(_engName(engId));
          }
          final engineers = engineerCtrl.engineers;
          final safeEngId = engineers.any((e) => e.id == engId) ? engId : null;
          return Container(
            color: _cellFillColor(isLocked: false, editableWhenUnlocked: true),
            child: SizedBox(
              height: _kRowH,
              child: _isLoadingEngineers
                  ? const Center(
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: safeEngId,
                        hint: const SizedBox.shrink(),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 13),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        menuMaxHeight: 200,
                        onChanged: onChange,
                        items: engineers
                            .map(
                              (Engineer e) => DropdownMenuItem(
                                value: e.id,
                                child: Center(
                                  child: Text(
                                    "${e.firstName} ${e.lastName}",
                                    style: _kWellInputTextStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
          );
        }),
      ),
      _unit(''),
    ],
  );

  String _engName(String? id) {
    if (id == null) return '';
    final e = engineerCtrl.engineers.firstWhere(
      (e) => e.id == id,
      orElse: () => Engineer(
        firstName: '',
        lastName: '',
        cell: '',
        office: '',
        email: '',
      ),
    );
    return e.id != null ? "${e.firstName} ${e.lastName}" : '';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════
Widget _hCell(String t, Color primary) => Container(
  height: _kTableHeaderH,
  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
  alignment: Alignment.center,
  color: _kGridHeaderColor,
  child: Text(
    AppUnits.label(t),
    style: const TextStyle(
      fontSize: 8.5,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
      height: 1.05,
    ),
    maxLines: 2,
    textAlign: TextAlign.center,
    overflow: TextOverflow.ellipsis,
  ),
);

Widget _noCell(int rowNo, bool sel, Color primary) => Container(
  height: _kRowH,
  alignment: Alignment.center,
  child: Text(
    rowNo > 0 ? '$rowNo' : '',
    style: TextStyle(
      fontSize: 9,
      color: sel ? Colors.black87 : Colors.grey.shade600,
    ),
    textAlign: TextAlign.center,
  ),
);

TableBorder _headerTableBorder() => const TableBorder(
  left: BorderSide(color: _kWellPanelBorder),
  top: BorderSide(color: _kWellPanelBorder),
  right: BorderSide(color: _kWellPanelBorder),
  bottom: BorderSide(color: _kWellPanelBorder),
  verticalInside: BorderSide(color: _kWellPanelBorder),
);

TableBorder _bodyTableBorder() => const TableBorder(
  left: BorderSide(color: _kWellPanelBorder),
  right: BorderSide(color: _kWellPanelBorder),
  bottom: BorderSide(color: _kWellPanelBorder),
  horizontalInside: BorderSide(color: _kWellPanelBorder),
  verticalInside: BorderSide(color: _kWellPanelBorder),
);

Widget _eCell(
  TextEditingController ctrl,
  DashboardController c, {
  ValueChanged<String>? onChanged,
  bool readOnly = false,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
  child: Obx(
    () => (c.isLocked.value || readOnly)
        ? Container(
            color: _cellFillColor(
              isLocked: true,
              editableWhenUnlocked: !readOnly,
            ),
            child: SizedBox(
              height: _kRowH,
              child: Center(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: ctrl,
                  builder: (context, value, _) => Text(
                    value.text,
                    style: _kWellSmallInputTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        : Container(
            color: _cellFillColor(
              isLocked: false,
              editableWhenUnlocked: !readOnly,
            ),
            child: SizedBox(
              height: _kRowH,
              child: TextField(
                controller: ctrl,
                style: _kWellSmallInputTextStyle,
                textAlign: TextAlign.center,
                readOnly: readOnly,
                onChanged: onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: _cellFillColor(
                    isLocked: false,
                    editableWhenUnlocked: !readOnly,
                  ),
                  filled: true,
                ),
              ),
            ),
          ),
  ),
);

// ═══════════════════════════════════════════════════════════════════
//  MIDDLE PORTION
// ═══════════════════════════════════════════════════════════════════
class MiddlePortion extends StatefulWidget {
  @override
  _MiddlePortionState createState() => _MiddlePortionState();
}

class _MiddlePortionState extends State<MiddlePortion> {
  final c = Get.find<DashboardController>();
  final wellGenCtrl = Get.isRegistered<WellGeneralController>()
      ? Get.find<WellGeneralController>()
      : Get.put(WellGeneralController(), permanent: true);
  bool cementPlug = false;
  final _cemCtrl = TextEditingController();
  final _plugCtrl = TextEditingController();
  final List<Worker> _unitWorkers = <Worker>[];
  final List<Worker> _wellWorkers = <Worker>[];
  late String _lengthUnit;
  late String _volumeUnit;
  bool _isApplyingCementState = false;

  @override
  void initState() {
    super.initState();
    _lengthUnit = AppUnits.length;
    _volumeUnit = AppUnits.fluidVolume;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
    _cemCtrl.addListener(() {
      if (_isApplyingCementState) return;
      wellGenCtrl.cementPlugVolume.value = _cemCtrl.text;
    });
    _plugCtrl.addListener(() {
      if (_isApplyingCementState) return;
      wellGenCtrl.cementPlugTop.value = _plugCtrl.text;
    });
    _wellWorkers.addAll([
      ever<bool>(wellGenCtrl.cementPlugEnabled, (_) => _loadCementState()),
      ever<String>(wellGenCtrl.cementPlugVolume, (_) => _loadCementState()),
      ever<String>(wellGenCtrl.cementPlugTop, (_) => _loadCementState()),
    ]);
    _loadCementState();
  }

  @override
  void dispose() {
    _cemCtrl.dispose();
    _plugCtrl.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    for (final worker in _wellWorkers) {
      worker.dispose();
    }
    super.dispose();
  }

  void _loadCementState() {
    _isApplyingCementState = true;
    cementPlug = wellGenCtrl.cementPlugEnabled.value;
    if (_cemCtrl.text != wellGenCtrl.cementPlugVolume.value) {
      _cemCtrl.text = wellGenCtrl.cementPlugVolume.value;
    }
    if (_plugCtrl.text != wellGenCtrl.cementPlugTop.value) {
      _plugCtrl.text = wellGenCtrl.cementPlugTop.value;
    }
    _isApplyingCementState = false;
    if (mounted) setState(() {});
  }

  void _handleUnitChange() {
    final nextLengthUnit = AppUnits.length;
    final nextVolumeUnit = AppUnits.fluidVolume;
    if (_lengthUnit == nextLengthUnit && _volumeUnit == nextVolumeUnit) {
      return;
    }

    _cemCtrl.text = _convertText(_cemCtrl.text, _volumeUnit, nextVolumeUnit);
    _plugCtrl.text = _convertText(_plugCtrl.text, _lengthUnit, nextLengthUnit);

    _lengthUnit = nextLengthUnit;
    _volumeUnit = nextVolumeUnit;
    if (mounted) setState(() {});
  }

  String _convertText(String rawValue, String fromUnit, String toUnit) {
    if (rawValue.trim().isEmpty || fromUnit == toUnit) {
      return rawValue;
    }
    final parsed = double.tryParse(rawValue.replaceAll(',', ''));
    if (parsed == null) {
      return rawValue;
    }
    final result = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (result == null) {
      return rawValue;
    }
    return _formatWellConvertedNumber(result, sourceText: rawValue);
  }

  double? _parseNumber(String rawValue) {
    return double.tryParse(rawValue.replaceAll(',', '').trim());
  }

  String _formatNumber(double value, {int decimals = 2}) {
    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  double? _resolveHoleDiameterInches() {
    final openHoleRows = wellGenCtrl.openHoleRowsForUi;
    for (final row in openHoleRows) {
      final rawId = row['id']?.trim() ?? '';
      final parsed = _parseNumber(rawId);
      if (parsed == null || parsed <= 0) continue;
      return (AppUnits.convertValue(parsed, AppUnits.diameter, 'in') ?? parsed)
          .toDouble();
    }

    final rawBitSize = wellGenCtrl.bitSize.value.trim();
    final bitParsed = _parseNumber(rawBitSize);
    if (bitParsed != null && bitParsed > 0) {
      return bitParsed;
    }
    return null;
  }

  void _calculateTopPlug() {
    final volume = _parseNumber(_cemCtrl.text);
    final md = _parseNumber(wellGenCtrl.md.value);
    final holeDiameterIn = _resolveHoleDiameterInches();

    if (volume == null ||
        volume <= 0 ||
        md == null ||
        md <= 0 ||
        holeDiameterIn == null ||
        holeDiameterIn <= 0) {
      return;
    }

    final volumeBbl =
        (AppUnits.convertValue(volume, _volumeUnit, 'bbl') ?? volume)
            .toDouble();
    final mdFt = (AppUnits.convertValue(md, _lengthUnit, 'ft') ?? md)
        .toDouble();
    final capacityBblPerFt = 0.0009714 * holeDiameterIn * holeDiameterIn;
    if (capacityBblPerFt <= 0) return;

    final plugTopFt = math.max(mdFt - (volumeBbl / capacityBblPerFt), 0.0);
    final plugTopDisplay =
        (AppUnits.convertValue(plugTopFt, 'ft', _lengthUnit) ?? plugTopFt)
            .toDouble();
    final formatted = _formatNumber(plugTopDisplay, decimals: 2);
    _plugCtrl.text = formatted;
    wellGenCtrl.cementPlugTop.value = formatted;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, bc) {
        const double cementRowH = 28.0;
        const double gap = _kSectionGap;
        const double bottomPad = 4.0;
        final double availableHeight = bc.maxHeight.isFinite
            ? bc.maxHeight
            : 520.0;
        final double totalH = availableHeight > bottomPad
            ? availableHeight - bottomPad
            : 0.0;
        final double reserved = cementRowH + gap * 3;
        final double flexH = totalH > reserved ? totalH - reserved : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(height: flexH * 3.2 / 10, child: CasedHoleSection()),
              const SizedBox(height: gap),
              SizedBox(height: flexH * 2.8 / 10, child: OpenHoleSection()),
              const SizedBox(height: gap),
              SizedBox(height: cementRowH, child: _cementRow()),
              const SizedBox(height: gap),
              SizedBox(height: flexH * 4.0 / 10, child: DrillStringSection()),
            ],
          ),
        );
      },
    );
  }

  Widget _cementRow() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 620;
      final checkboxWidth = compact ? 28.0 : 34.0;
      final fieldWidth = compact ? 88.0 : 110.0;
      final gap = compact ? 4.0 : 6.0;
      final largeGap = compact ? 6.0 : 8.0;

      return Row(
        children: [
          Obx(
            () => SizedBox(
              width: checkboxWidth,
              child: Checkbox(
                value: cementPlug,
                onChanged: c.isLocked.value
                    ? null
                    : (v) {
                        setState(() => cementPlug = v ?? false);
                        wellGenCtrl.cementPlugEnabled.value = cementPlug;
                      },
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              AppUnits.label("Cement Plug Vol. (bbl)"),
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: gap),
          SizedBox(width: fieldWidth, child: _field(_cemCtrl)),
          SizedBox(width: largeGap),
          Obx(
            () => _toolButton(
              tooltip: 'Calculate Top Plug',
              onTap: c.isLocked.value ? null : _calculateTopPlug,
              child: Icon(
                Icons.calculate_outlined,
                size: 14,
                color: c.isLocked.value ? Colors.grey.shade400 : Colors.blue,
              ),
            ),
          ),
          SizedBox(width: gap),
          Flexible(
            child: Text(
              AppUnits.label("Plug Top (ft)"),
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: gap),
          SizedBox(width: fieldWidth, child: _field(_plugCtrl)),
        ],
      );
    },
  );

  Widget _field(TextEditingController ctrl) => Obx(
    () => Container(
      height: 22,
      decoration: BoxDecoration(
        border: Border.all(color: _kWellPanelBorder),
        color: _cellFillColor(
          isLocked: c.isLocked.value,
          editableWhenUnlocked: true,
        ),
      ),
      child: c.isLocked.value
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Text(ctrl.text, style: _kWellInputTextStyle),
            )
          : TextField(
              controller: ctrl,
              style: _kWellInputTextStyle,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  CASED HOLE  ← ONLY THIS SECTION IS CHANGED
// ═══════════════════════════════════════════════════════════════════
class CasedHoleSection extends StatefulWidget {
  @override
  _CasedHoleSectionState createState() => _CasedHoleSectionState();
}

class _CasedHoleSectionState extends State<CasedHoleSection> {
  final c = Get.find<DashboardController>();

  // ── Casing controller to fetch from API ─────────────────────────
  late final UgStController _casingCtrl;
  final CasedHoleUIController uiCtrl = Get.isRegistered<CasedHoleUIController>()
      ? Get.find<CasedHoleUIController>()
      : Get.put(CasedHoleUIController(), permanent: true);

  // Currently selected casing from dropdown (null = nothing selected)
  CasingRow? _selectedCasing;

  int? selectedRowIndex;

  @override
  void initState() {
    super.initState();
    // Get or put the UgStController — it also fetches casings on init
    _casingCtrl = Get.isRegistered<UgStController>()
        ? Get.find<UgStController>()
        : Get.put(UgStController());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleRowMenu(int rowIndex, TapDownDetails details) async {
    setState(() => selectedRowIndex = rowIndex);
    final action = await _showWellRowMenu(
      context,
      details,
      canPaste: _WellRowClipboard.canPaste('cased-hole'),
    );
    if (action == null) return;

    switch (action) {
      case _WellRowMenuAction.cut:
        await _WellRowClipboard.copy('cased-hole', uiCtrl.copyRow(rowIndex));
        await uiCtrl.deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.copy:
        await _WellRowClipboard.copy('cased-hole', uiCtrl.copyRow(rowIndex));
        break;
      case _WellRowMenuAction.paste:
        final values = await _WellRowClipboard.paste('cased-hole');
        if (values != null) {
          uiCtrl.pasteRow(rowIndex, values);
        }
        break;
      case _WellRowMenuAction.delete:
        await uiCtrl.deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.clear:
        uiCtrl.clearRow(rowIndex);
        break;
      case _WellRowMenuAction.toTop:
        uiCtrl.moveRowToTop(rowIndex);
        break;
      case _WellRowMenuAction.toBottom:
        uiCtrl.moveRowToBottom(rowIndex);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _wellPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER (only the dropdown source changed) ─────────────
          Container(
            height: _kHeaderH,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: AppTheme.primaryColor,
            child: Row(
              children: [
                const Text("Cased Hole", style: _kWellHeaderTextStyle),
                Expanded(
                  child: Center(
                    child: Text(
                      "Add New Casing",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                // ── Dynamic dropdown from API ──────────────────────────
                Obx(() {
                  final casings = _casingCtrl.casings;
                  final isLoading = _casingCtrl.isLoading.value;

                  // Keep _selectedCasing synced with the latest casing objects.
                  if (_selectedCasing != null) {
                    final matchingCasing = casings
                        .cast<CasingRow?>()
                        .firstWhere(
                          (c) => c?.dbId == _selectedCasing!.dbId,
                          orElse: () => null,
                        );
                    if (matchingCasing == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedCasing = null);
                      });
                    } else if (!identical(matchingCasing, _selectedCasing)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted)
                          setState(() => _selectedCasing = matchingCasing);
                      });
                    }
                  }

                  return Container(
                    width: 150,
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _kWellPanelBorder),
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<CasingRow>(
                              value: _selectedCasing,
                              hint: const SizedBox.shrink(),
                              icon: const Icon(Icons.arrow_drop_down, size: 13),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              menuMaxHeight: 200,
                              onChanged: c.isLocked.value
                                  ? null
                                  : (value) {
                                      setState(() => _selectedCasing = value);
                                    },
                              items: casings
                                  .where(
                                    (csg) =>
                                        csg.description.value
                                            .trim()
                                            .isNotEmpty &&
                                        csg.toc.value.trim() !=
                                            kCasedHoleTocMarker,
                                  )
                                  .map(
                                    (csg) => DropdownMenuItem<CasingRow>(
                                      value: csg,
                                      child: Text(
                                        csg.description.value,
                                        style: _kWellSmallInputTextStyle,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  );
                }),

                const SizedBox(width: 6),

                Obx(
                  () => _toolButton(
                    tooltip: 'Add casing',
                    onTap: c.isLocked.value || _selectedCasing == null
                        ? null
                        : () {
                            uiCtrl.addRowFromCasing(_selectedCasing!);
                            setState(() => _selectedCasing = null);
                          },
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: c.isLocked.value || _selectedCasing == null
                          ? Colors.grey.shade400
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── TABLE (completely unchanged) ──────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, bc) {
                final double avail = bc.maxWidth - 28;
                final double cw = avail / 7;
                final columnWidths = <int, TableColumnWidth>{
                  0: const FixedColumnWidth(28),
                  1: FixedColumnWidth(cw),
                  2: FixedColumnWidth(cw),
                  3: FixedColumnWidth(cw),
                  4: FixedColumnWidth(cw),
                  5: FixedColumnWidth(cw),
                  6: FixedColumnWidth(cw),
                  7: FixedColumnWidth(cw),
                };
                return Column(
                  children: [
                    Obx(() {
                      final unitSignature = AppUnits.signature;
                      return Table(
                        key: ValueKey(unitSignature),
                        border: _headerTableBorder(),
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        columnWidths: columnWidths,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: _kGridHeaderColor),
                            children:
                                [
                                      'No.',
                                      'Description',
                                      'OD\n${AppUnits.unitText('in')}',
                                      'Wt.\n${AppUnits.unitText('lb/ft')}',
                                      'ID\n${AppUnits.unitText('in')}',
                                      'Top\n${AppUnits.unitText('ft')}',
                                      'Shoe\n${AppUnits.unitText('ft')}',
                                      'Len.\n${AppUnits.unitText('ft')}',
                                    ]
                                    .map(
                                      (h) => _hCell(h, AppTheme.primaryColor),
                                    )
                                    .toList(),
                          ),
                        ],
                      );
                    }),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Obx(
                          () => Table(
                            border: _bodyTableBorder(),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: columnWidths,
                            children: uiCtrl.entries.asMap().entries.map((
                              entry,
                            ) {
                              final idx = entry.key;
                              final e = entry.value;
                              final bool sel = selectedRowIndex == idx;
                              final rowChildren = <Widget>[
                                GestureDetector(
                                  onTap: () => setState(
                                    () => selectedRowIndex = sel ? null : idx,
                                  ),
                                  child: _noCell(
                                    idx + 1,
                                    sel,
                                    AppTheme.primaryColor,
                                  ),
                                ),
                                _eCell(
                                  e.description,
                                  c,
                                  readOnly: true,
                                  onChanged: (v) => uiCtrl.checkAndAddRow(idx),
                                ),
                                _eCell(
                                  e.od,
                                  c,
                                  readOnly: true,
                                  onChanged: (v) => uiCtrl.checkAndAddRow(idx),
                                ),
                                _eCell(
                                  e.wt,
                                  c,
                                  readOnly: true,
                                  onChanged: (v) => uiCtrl.checkAndAddRow(idx),
                                ),
                                _eCell(
                                  e.idCtrl,
                                  c,
                                  readOnly: true,
                                  onChanged: (v) => uiCtrl.checkAndAddRow(idx),
                                ),
                                _eCell(
                                  e.top,
                                  c,
                                  onChanged: (v) => uiCtrl.checkAndAddRow(idx),
                                ),
                                _eCell(
                                  e.shoe,
                                  c,
                                  onChanged: (v) => uiCtrl.checkAndAddRow(idx),
                                ),
                                _eCell(e.length, c, readOnly: true),
                              ];
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: sel
                                      ? _kSelectedRowColor
                                      : (idx % 2 == 0
                                            ? Colors.white
                                            : _kAltRowColor),
                                ),
                                children: rowChildren
                                    .map(
                                      (child) => _rowMenuTarget(
                                        onSecondaryTapDown: (details) =>
                                            _handleRowMenu(idx, details),
                                        child: child,
                                      ),
                                    )
                                    .toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          SizedBox(
            height: _kFooterH,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  OPEN HOLE — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class OpenHoleSection extends StatefulWidget {
  @override
  _OpenHoleSectionState createState() => _OpenHoleSectionState();
}

class _OpenHoleSectionState extends State<OpenHoleSection> {
  final c = Get.find<DashboardController>();
  final wellGenCtrl = Get.isRegistered<WellGeneralController>()
      ? Get.find<WellGeneralController>()
      : Get.put(WellGeneralController(), permanent: true);
  int? selectedRowIndex;
  late final List<List<TextEditingController>> _cellControllers;
  late final List<List<FocusNode>> _cellFocusNodes;
  List<String> _lastAutoFirstRow = const ['', '', '', ''];
  final List<Worker> _unitWorkers = <Worker>[];
  Worker? _openHoleWorker;
  late String _lengthUnit;
  late String _diameterUnit;

  @override
  void initState() {
    super.initState();
    _cellControllers = List<List<TextEditingController>>.generate(
      3,
      (_) => List<TextEditingController>.generate(
        4,
        (_) => TextEditingController(),
      ),
    );
    _cellFocusNodes = List<List<FocusNode>>.generate(
      3,
      (_) => List<FocusNode>.generate(4, (_) => FocusNode()),
    );
    _lengthUnit = AppUnits.length;
    _diameterUnit = AppUnits.diameter;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
    _openHoleWorker = ever<int>(wellGenCtrl.openHoleRevision, (_) {
      if (!mounted) return;
      if (_hasOpenHoleCellFocus) return;
      _loadRowsFromController();
      setState(() {});
    });
    _loadRowsFromController(force: true);
    _syncAutoValues();
  }

  @override
  void dispose() {
    for (final row in _cellControllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final row in _cellFocusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    _openHoleWorker?.dispose();
    super.dispose();
  }

  bool get _hasOpenHoleCellFocus =>
      _cellFocusNodes.any((row) => row.any((node) => node.hasFocus));

  void _handleUnitChange() {
    final nextLengthUnit = AppUnits.length;
    final nextDiameterUnit = AppUnits.diameter;
    if (_lengthUnit == nextLengthUnit && _diameterUnit == nextDiameterUnit) {
      return;
    }

    for (final row in _cellControllers) {
      if (row.length >= 3) {
        row[1].text = _convertText(
          row[1].text,
          _diameterUnit,
          nextDiameterUnit,
        );
        row[2].text = _convertText(row[2].text, _lengthUnit, nextLengthUnit);
      }
    }

    _lengthUnit = nextLengthUnit;
    _diameterUnit = nextDiameterUnit;
    _lastAutoFirstRow = const ['', '', '', ''];
    _syncAutoValues(force: true);
    _commitRows();
    if (mounted) setState(() {});
  }

  String _convertText(String rawValue, String fromUnit, String toUnit) {
    if (rawValue.trim().isEmpty || fromUnit == toUnit) {
      return rawValue;
    }
    final parsed = double.tryParse(rawValue.replaceAll(',', ''));
    if (parsed == null) {
      return rawValue;
    }
    final result = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (result == null) {
      return rawValue;
    }
    return _formatWellConvertedNumber(result, sourceText: rawValue);
  }

  List<String> _autoFirstRow() {
    final currentMd = wellGenCtrl.md.value.trim();
    final mdText = currentMd.isEmpty ? '' : currentMd;
    return ['', '', mdText, ''];
  }

  void _syncAutoValues({bool force = false}) {
    final autoRow = _autoFirstRow();
    final firstRow = _cellControllers.first;

    for (var i = 0; i < firstRow.length; i++) {
      if (force ||
          firstRow[i].text.isEmpty ||
          firstRow[i].text == _lastAutoFirstRow[i]) {
        firstRow[i].text = autoRow[i];
      }
    }

    _lastAutoFirstRow = autoRow;
  }

  String _formatNumber(double value, {int decimals = 2}) {
    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  double? _parseNumber(String rawValue) {
    return double.tryParse(rawValue.replaceAll(',', '').trim());
  }

  void _quickFillOpenHole() {
    final bitSizeIn = _parseNumber(wellGenCtrl.bitSize.value);
    final mdValue = wellGenCtrl.md.value.trim();
    if (bitSizeIn == null || bitSizeIn <= 0) return;

    final displaySize =
        (AppUnits.convertValue(bitSizeIn, 'in', _diameterUnit) ?? bitSizeIn)
            .toDouble();
    final sizeText = _formatNumber(displaySize, decimals: 2);

    _cellControllers[0][0].text = sizeText;
    _cellControllers[0][1].text = sizeText;
    if (mdValue.isNotEmpty) {
      _cellControllers[0][2].text = mdValue;
    }
    if (_cellControllers[0][3].text.trim().isEmpty) {
      _cellControllers[0][3].text = '0';
    }

    _commitRows();
    _syncAutoValues(force: true);
    setState(() {});
  }

  void _setControllerText(
    TextEditingController controller,
    String value, {
    bool force = false,
  }) {
    if (force || controller.text != value) {
      controller.text = value;
    }
  }

  void _loadRowsFromController({bool force = false}) {
    final rows = wellGenCtrl.openHoleRowsForUi;
    for (var rowIndex = 0; rowIndex < _cellControllers.length; rowIndex++) {
      final row = rowIndex < rows.length
          ? rows[rowIndex]
          : const <String, String>{};
      _setControllerText(
        _cellControllers[rowIndex][0],
        row['description'] ?? '',
        force: force,
      );
      _setControllerText(
        _cellControllers[rowIndex][1],
        row['id'] ?? '',
        force: force,
      );
      _setControllerText(
        _cellControllers[rowIndex][2],
        row['md'] ?? '',
        force: force,
      );
      _setControllerText(
        _cellControllers[rowIndex][3],
        row['washout'] ?? '',
        force: force,
      );
    }
  }

  List<Map<String, String>> _rowsForController() => _cellControllers
      .map(
        (row) => {
          'description': row[0].text.trim(),
          'id': row[1].text.trim(),
          'md': row[2].text.trim(),
          'washout': row[3].text.trim(),
        },
      )
      .toList();

  List<String> _copyableRowValues(int rowIndex) =>
      _cellControllers[rowIndex].map((controller) => controller.text).toList();

  void _commitRows() {
    wellGenCtrl.hydrateOpenHoleRows(_rowsForController());
  }

  void _syncRowToController(int rowIndex) {
    final row = _cellControllers[rowIndex];
    wellGenCtrl.updateOpenHoleRow(
      rowIndex,
      description: row[0].text,
      id: row[1].text,
      md: row[2].text,
      washout: row[3].text,
    );
  }

  void _clearRow(int rowIndex) {
    for (final controller in _cellControllers[rowIndex]) {
      controller.clear();
    }
    _commitRows();
    _syncAutoValues(force: true);
    setState(() {});
  }

  void _deleteRow(int rowIndex) {
    final rows = _rowsForController();
    rows.removeAt(rowIndex);
    while (rows.length < 3) {
      rows.add({'description': '', 'id': '', 'md': '', 'washout': ''});
    }
    wellGenCtrl.hydrateOpenHoleRows(rows);
    _syncAutoValues(force: true);
  }

  void _moveRowToTop(int rowIndex) {
    if (rowIndex <= 0) return;
    final rows = _rowsForController();
    final row = rows.removeAt(rowIndex);
    rows.insert(0, row);
    wellGenCtrl.hydrateOpenHoleRows(rows);
  }

  void _moveRowToBottom(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= _cellControllers.length) return;
    final rows = _rowsForController();
    final row = rows.removeAt(rowIndex);
    rows.add(row);
    wellGenCtrl.hydrateOpenHoleRows(rows);
  }

  void _pasteRow(int rowIndex, List<String> values) {
    final data = List<String>.from(values);
    while (data.length < 4) {
      data.add('');
    }
    for (var i = 0; i < 4; i++) {
      _cellControllers[rowIndex][i].text = data[i];
    }
    _commitRows();
    _syncAutoValues(force: true);
    setState(() {});
  }

  Future<void> _handleRowMenu(int rowIndex, TapDownDetails details) async {
    setState(() => selectedRowIndex = rowIndex);
    final action = await _showWellRowMenu(
      context,
      details,
      canPaste: _WellRowClipboard.canPaste('open-hole'),
    );
    if (action == null) return;

    switch (action) {
      case _WellRowMenuAction.cut:
        await _WellRowClipboard.copy('open-hole', _copyableRowValues(rowIndex));
        _deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.copy:
        await _WellRowClipboard.copy('open-hole', _copyableRowValues(rowIndex));
        break;
      case _WellRowMenuAction.paste:
        final values = await _WellRowClipboard.paste('open-hole');
        if (values != null) {
          _pasteRow(rowIndex, values);
        }
        break;
      case _WellRowMenuAction.delete:
        _deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.clear:
        _clearRow(rowIndex);
        break;
      case _WellRowMenuAction.toTop:
        _moveRowToTop(rowIndex);
        break;
      case _WellRowMenuAction.toBottom:
        _moveRowToBottom(rowIndex);
        break;
    }
  }

  Widget _editableOpenHoleCell(
    TextEditingController controller, {
    required bool enabled,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      color: _cellFillColor(isLocked: !enabled, editableWhenUnlocked: true),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: SizedBox(
        height: _kRowH,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          selectAllOnFocus: false,
          textAlign: TextAlign.center,
          onChanged: onChanged,
          onTap: () => _collapseFullSelectionToEnd(controller),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 2,
            ),
            filled: true,
            fillColor: _cellFillColor(
              isLocked: !enabled,
              editableWhenUnlocked: true,
            ),
          ),
          onSubmitted: (_) {
            onChanged?.call(controller.text);
            _collapseSelectionToEnd(controller);
          },
          onEditingComplete: () {
            onChanged?.call(controller.text);
            _collapseSelectionToEnd(controller);
          },
          style: _kWellSmallInputTextStyle,
        ),
      ),
    );
  }

  void _collapseSelectionToEnd(TextEditingController controller) {
    Future.microtask(() {
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  void _collapseFullSelectionToEnd(TextEditingController controller) {
    final selection = controller.selection;
    final isFullSelection =
        selection.start == 0 && selection.end == controller.text.length;
    if (controller.text.isNotEmpty && isFullSelection) {
      _collapseSelectionToEnd(controller);
    }
  }

  List<Widget> _buildRowCells(
    List<TextEditingController> controllers, {
    required bool enabled,
    required int rowIndex,
  }) {
    return [
      _editableOpenHoleCell(
        controllers[0],
        enabled: enabled,
        focusNode: _cellFocusNodes[rowIndex][0],
        onChanged: (_) => _syncRowToController(rowIndex),
      ),
      _editableOpenHoleCell(
        controllers[1],
        enabled: enabled,
        focusNode: _cellFocusNodes[rowIndex][1],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => _syncRowToController(rowIndex),
      ),
      _editableOpenHoleCell(
        controllers[2],
        enabled: enabled,
        focusNode: _cellFocusNodes[rowIndex][2],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => _syncRowToController(rowIndex),
      ),
      _editableOpenHoleCell(
        controllers[3],
        enabled: enabled,
        focusNode: _cellFocusNodes[rowIndex][3],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => _syncRowToController(rowIndex),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _syncAutoValues();
      final isLocked = c.isLocked.value;

      return _wellPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: _kHeaderH,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              color: AppTheme.primaryColor,
              child: Row(
                children: [
                  const Text("Open Hole", style: _kWellHeaderTextStyle),
                  const Spacer(),
                  Obx(
                    () => _toolButton(
                      tooltip: 'Open Hole Quickfill',
                      onTap: c.isLocked.value ? null : _quickFillOpenHole,
                      child: Icon(
                        Icons.flash_on,
                        size: 14,
                        color: c.isLocked.value
                            ? Colors.grey.shade400
                            : Colors.deepOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, bc) {
                  final double avail = bc.maxWidth - 28;
                  final double cw = avail / 4;
                  final columnWidths = <int, TableColumnWidth>{
                    0: const FixedColumnWidth(28),
                    1: FixedColumnWidth(cw),
                    2: FixedColumnWidth(cw),
                    3: FixedColumnWidth(cw),
                    4: FixedColumnWidth(cw),
                  };
                  return Column(
                    children: [
                      Table(
                        border: _headerTableBorder(),
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        columnWidths: columnWidths,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: _kGridHeaderColor),
                            children:
                                [
                                      'No.',
                                      'Description',
                                      'ID\n${AppUnits.unitText('in')}',
                                      'MD\n${AppUnits.unitText('ft')}',
                                      'Washout\n(%)',
                                    ]
                                    .map(
                                      (h) => _hCell(h, AppTheme.primaryColor),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Table(
                            border: _bodyTableBorder(),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: columnWidths,
                            children: _cellControllers.asMap().entries.map((
                              entry,
                            ) {
                              final idx = entry.key;
                              final rowControllers = entry.value;
                              final sel = selectedRowIndex == idx;
                              final rowChildren = <Widget>[
                                GestureDetector(
                                  onTap: () => setState(
                                    () => selectedRowIndex = sel ? null : idx,
                                  ),
                                  child: _noCell(
                                    idx + 1,
                                    sel,
                                    AppTheme.primaryColor,
                                  ),
                                ),
                                ..._buildRowCells(
                                  rowControllers,
                                  enabled: !isLocked,
                                  rowIndex: idx,
                                ),
                              ];
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: sel
                                      ? _kSelectedRowColor
                                      : (idx % 2 == 0
                                            ? Colors.white
                                            : _kAltRowColor),
                                ),
                                children: rowChildren
                                    .map(
                                      (child) => _rowMenuTarget(
                                        onSecondaryTapDown: (details) =>
                                            _handleRowMenu(idx, details),
                                        child: child,
                                      ),
                                    )
                                    .toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(height: _kFooterH, color: Colors.white),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DRILL STRING — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class DrillStringSection extends StatefulWidget {
  @override
  _DrillStringSectionState createState() => _DrillStringSectionState();
}

class _DrillStringSectionState extends State<DrillStringSection> {
  final c = Get.find<DashboardController>();
  final ds = Get.isRegistered<DrillStringController>()
      ? Get.find<DrillStringController>()
      : Get.put(DrillStringController());
  final wellGenCtrl = Get.isRegistered<WellGeneralController>()
      ? Get.find<WellGeneralController>()
      : Get.put(WellGeneralController(), permanent: true);
  int? selectedRowIndex;

  void _selectDrillStringRow(int rowIndex) {
    if (selectedRowIndex == rowIndex) return;
    setState(() => selectedRowIndex = rowIndex);
  }

  Future<void> _handleRowMenu(int rowIndex, TapDownDetails details) async {
    _selectDrillStringRow(rowIndex);
    final action = await _showWellRowMenu(
      context,
      details,
      canPaste: _WellRowClipboard.canPaste('drill-string'),
    );
    if (action == null) return;

    switch (action) {
      case _WellRowMenuAction.cut:
        await _WellRowClipboard.copy('drill-string', ds.copyRow(rowIndex));
        await ds.deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.copy:
        await _WellRowClipboard.copy('drill-string', ds.copyRow(rowIndex));
        break;
      case _WellRowMenuAction.paste:
        final values = await _WellRowClipboard.paste('drill-string');
        if (values != null) {
          ds.pasteRow(rowIndex, values);
        }
        break;
      case _WellRowMenuAction.delete:
        await ds.deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.clear:
        ds.clearRow(rowIndex);
        break;
      case _WellRowMenuAction.toTop:
        ds.moveRowToTop(rowIndex);
        break;
      case _WellRowMenuAction.toBottom:
        ds.moveRowToBottom(rowIndex);
        break;
    }
  }

  double? _parseNumber(String rawValue) {
    return double.tryParse(rawValue.replaceAll(',', '').trim());
  }

  String _formatNumber(double value, {int decimals = 2}) {
    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  int _targetRowIndex() {
    if (selectedRowIndex != null &&
        selectedRowIndex! >= 0 &&
        selectedRowIndex! < ds.entries.length) {
      return selectedRowIndex!;
    }
    final firstEmpty = ds.entries.indexWhere((entry) => !entry.hasContent);
    return firstEmpty >= 0 ? firstEmpty : 0;
  }

  void _calculateIds() {
    final indices = selectedRowIndex != null
        ? <int>[selectedRowIndex!]
        : ds.entries
              .asMap()
              .entries
              .where((entry) => entry.value.hasContent)
              .map((entry) => entry.key)
              .toList();

    for (final index in indices) {
      if (index < 0 || index >= ds.entries.length) continue;
      final entry = ds.entries[index];
      final odValue = _parseNumber(entry.od.text);
      final wtValue = _parseNumber(entry.weightPpf.text);
      if (odValue == null || odValue <= 0 || wtValue == null || wtValue <= 0) {
        continue;
      }

      final odIn =
          AppUnits.convertValue(odValue, AppUnits.diameter, 'in') ?? odValue;
      final wtLbFt =
          AppUnits.convertValue(wtValue, AppUnits.lineDensity, 'lb/ft') ??
          wtValue;
      final inside = (odIn * odIn) - (wtLbFt / 2.672);
      if (inside <= 0) continue;

      final idIn = math.sqrt(inside);
      final displayId =
          (AppUnits.convertValue(idIn, 'in', AppUnits.diameter) ?? idIn)
              .toDouble();
      entry.idCtrl.text = _formatNumber(displayId, decimals: 2);
      ds.onCellChanged(index);
    }
    ds.entries.refresh();
    if (mounted) setState(() {});
  }

  void _adjustLength() {
    if (ds.entries.isEmpty) return;
    if (selectedRowIndex == null) return;
    final targetIndex = selectedRowIndex!;
    if (targetIndex < 0 || targetIndex >= ds.entries.length) return;

    final mdValue = _parseNumber(wellGenCtrl.md.value);
    if (mdValue == null || mdValue <= 0) return;
    final wellDepthFt =
        (AppUnits.convertValue(mdValue, AppUnits.length, 'ft') ?? mdValue)
            .toDouble();

    double otherLengthFt = 0;
    for (var i = 0; i < ds.entries.length; i++) {
      if (i == targetIndex) continue;
      final rawLength = _parseNumber(ds.entries[i].length.text);
      if (rawLength == null || rawLength <= 0) continue;
      otherLengthFt +=
          (AppUnits.convertValue(rawLength, AppUnits.length, 'ft') ?? rawLength)
              .toDouble();
    }

    final adjustedFt = math.max(wellDepthFt - otherLengthFt, 0.0);
    final adjustedDisplay =
        (AppUnits.convertValue(adjustedFt, 'ft', AppUnits.length) ?? adjustedFt)
            .toDouble();
    ds.entries[targetIndex].length.text = _formatNumber(
      adjustedDisplay,
      decimals: 1,
    );
    ds.onCellChanged(targetIndex);
    ds.entries.refresh();
    if (mounted) setState(() {});
  }

  Future<void> _openTabularDatabase() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CompactTabularDatabaseDialog(),
    );

    if (result == null) return;
    final rowIndex = _targetRowIndex();
    while (ds.entries.length <= rowIndex) {
      ds.addEmptyRow();
    }

    final entry = ds.entries[rowIndex];
    final odMm = _parseNumber(result['odMm'] ?? '');
    final idMm = _parseNumber(result['idMm'] ?? '');
    final wtLbFt = _parseNumber(result['weightLbFt'] ?? '');

    final odDisplay = odMm == null
        ? ''
        : _formatNumber(
            (AppUnits.convertValue(odMm, 'mm', AppUnits.diameter) ?? odMm)
                .toDouble(),
            decimals: 2,
          );
    final idDisplay = idMm == null
        ? ''
        : _formatNumber(
            (AppUnits.convertValue(idMm, 'mm', AppUnits.diameter) ?? idMm)
                .toDouble(),
            decimals: 2,
          );
    final wtDisplay = wtLbFt == null
        ? ''
        : _formatNumber(
            ((AppUnits.convertValue(wtLbFt, 'lb/ft', AppUnits.lineDensity) ??
                    wtLbFt))
                .toDouble(),
            decimals: 3,
          );

    entry.description.text = result['type'] ?? entry.description.text;
    entry.od.text = odDisplay;
    entry.weightPpf.text = wtDisplay;
    entry.idCtrl.text = idDisplay;
    entry.grade.text = result['grade'] ?? entry.grade.text;
    selectedRowIndex = rowIndex;
    ds.onCellChanged(rowIndex);
    ds.entries.refresh();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _wellPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: _kHeaderH,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: AppTheme.primaryColor,
            child: Row(
              children: [
                const Text("Drill String", style: _kWellHeaderTextStyle),
                const Spacer(),
                Obx(
                  () => _toolButton(
                    tooltip: 'Calculate ID',
                    onTap: c.isLocked.value ? null : _calculateIds,
                    child: Text(
                      '-ID',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: c.isLocked.value
                            ? Colors.grey.shade400
                            : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Obx(
                  () => _toolButton(
                    tooltip: 'Adjust Length',
                    onTap: c.isLocked.value ? null : _adjustLength,
                    child: Icon(
                      Icons.straighten,
                      size: 14,
                      color: c.isLocked.value
                          ? Colors.grey.shade400
                          : Colors.deepOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Obx(
                  () => _toolButton(
                    tooltip: 'Tabular Database',
                    onTap: c.isLocked.value ? null : _openTabularDatabase,
                    child: Icon(
                      Icons.table_chart_outlined,
                      size: 14,
                      color: c.isLocked.value
                          ? Colors.grey.shade400
                          : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Obx(
                  () => ds.isLoading.value || ds.isSaving.value
                      ? const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (ds.isLoading.value)
                return const Center(child: CircularProgressIndicator());
              return LayoutBuilder(
                builder: (ctx, bc) {
                  final double avail = bc.maxWidth - 28;
                  final double cw = avail / 6;
                  final columnWidths = <int, TableColumnWidth>{
                    0: const FixedColumnWidth(28),
                    1: FixedColumnWidth(cw),
                    2: FixedColumnWidth(cw),
                    3: FixedColumnWidth(cw),
                    4: FixedColumnWidth(cw),
                    5: FixedColumnWidth(cw),
                    6: FixedColumnWidth(cw),
                  };
                  return Column(
                    children: [
                      Table(
                        border: _headerTableBorder(),
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        columnWidths: columnWidths,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: _kGridHeaderColor),
                            children:
                                [
                                      'No.',
                                      'Description',
                                      'OD\n${AppUnits.unitText('in')}',
                                      'Wt.\n${AppUnits.unitText('lb/ft')}',
                                      'ID\n${AppUnits.unitText('in')}',
                                      'Grade',
                                      'Len.\n${AppUnits.unitText('ft')}',
                                    ]
                                    .map(
                                      (h) => _hCell(h, AppTheme.primaryColor),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Obx(
                            () => Table(
                              border: _bodyTableBorder(),
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              columnWidths: columnWidths,
                              children: ds.entries
                                  .asMap()
                                  .entries
                                  .map((e) => _dsRow(e.key, e.value))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
          Obx(
            () => SizedBox(
              height: _kFooterH + 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(1, 0, 1, 0),
                color: Colors.white,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Total String Length < Well Depth",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppUnits.label("Total Length (ft)"),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 126,
                        height: 24,
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          border: Border.all(color: _kWellPanelBorder),
                          color: _kEditableCellColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            ds.totalLength.value.toStringAsFixed(1),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _dsRow(int rowIdx, DrillStringEntry entry) {
    bool sel = selectedRowIndex == rowIdx;
    final rowChildren = <Widget>[
      GestureDetector(
        onTap: () => _selectDrillStringRow(rowIdx),
        child: _noCell(rowIdx + 1, sel, AppTheme.primaryColor),
      ),
      _dsCell(entry.description, rowIdx),
      _dsCell(entry.od, rowIdx),
      _dsCell(entry.weightPpf, rowIdx),
      _dsCell(entry.idCtrl, rowIdx),
      _dsCell(entry.grade, rowIdx),
      _dsCell(entry.length, rowIdx),
    ];
    return TableRow(
      decoration: BoxDecoration(
        color: sel
            ? _kSelectedRowColor
            : (rowIdx % 2 == 0 ? Colors.white : _kAltRowColor),
      ),
      children: rowChildren
          .map(
            (child) => _rowMenuTarget(
              onSecondaryTapDown: (details) => _handleRowMenu(rowIdx, details),
              child: child,
            ),
          )
          .toList(),
    );
  }

  Widget _dsCell(TextEditingController ctrl, int rowIdx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
    child: Obx(
      () => c.isLocked.value
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectDrillStringRow(rowIdx),
              child: Container(
                color: _cellFillColor(
                  isLocked: true,
                  editableWhenUnlocked: true,
                ),
                child: SizedBox(
                  height: _kRowH,
                  child: Center(
                    child: Text(
                      ctrl.text,
                      style: _kWellInputTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            )
          : Container(
              color: Colors.white,
              child: SizedBox(
                height: _kRowH,
                child: TextField(
                  controller: ctrl,
                  style: _kWellSmallInputTextStyle,
                  textAlign: TextAlign.center,
                  onTap: () => _selectDrillStringRow(rowIdx),
                  onChanged: (_) {
                    _selectDrillStringRow(rowIdx);
                    ds.onCellChanged(rowIdx);
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  RIGHT PORTION — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class RightPortion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ac = Get.isRegistered<OthersController>()
        ? Get.find<OthersController>()
        : Get.put(OthersController(), permanent: true);
    return LayoutBuilder(
      builder: (ctx, bc) {
        const double cementRowH = 28.0;
        const double gap = 2.0;
        const double bottomPad = 4.0;
        final double availableHeight = bc.maxHeight.isFinite
            ? bc.maxHeight
            : 520.0;
        final double totalH = availableHeight > bottomPad
            ? availableHeight - bottomPad
            : 0.0;
        final double reserved = cementRowH + gap * 3;
        final double flexH = totalH > reserved ? totalH - reserved : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(height: flexH * 3.2 / 10, child: BitSection()),
              const SizedBox(height: gap),
              SizedBox(height: flexH * 2.8 / 10, child: NozzleSection()),
              const SizedBox(height: gap),
              const SizedBox(height: cementRowH),
              const SizedBox(height: gap),
              SizedBox(
                height: flexH * 4.0 / 10,
                child: TimeDistributionSection(activityController: ac),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BIT SECTION — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class BitSection extends StatefulWidget {
  @override
  _BitSectionState createState() => _BitSectionState();
}

class _BitSectionState extends State<BitSection> {
  final c = Get.find<DashboardController>();
  final wellGenCtrl = Get.isRegistered<WellGeneralController>()
      ? Get.find<WellGeneralController>()
      : Get.put(WellGeneralController(), permanent: true);
  final Map<String, TextEditingController> bc = {
    'Mft': TextEditingController(),
    'Type': TextEditingController(),
    'No. of Bits': TextEditingController(),
    'Size': TextEditingController(),
    'Depth-in': TextEditingController(),
    'Depth': TextEditingController(),
  };
  final List<Worker> _unitWorkers = <Worker>[];
  final List<Worker> _bitWorkers = <Worker>[];
  late String _lengthUnit;
  late String _diameterUnit;

  @override
  void initState() {
    super.initState();
    _lengthUnit = AppUnits.length;
    _diameterUnit = AppUnits.diameter;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
    _bitWorkers.addAll([
      ever<String>(wellGenCtrl.bitMft, (_) => _loadBitFieldsFromController()),
      ever<String>(wellGenCtrl.bitType, (_) => _loadBitFieldsFromController()),
      ever<String>(wellGenCtrl.bitSize, (_) => _loadBitFieldsFromController()),
      ever<String>(wellGenCtrl.bitCount, (_) => _loadBitFieldsFromController()),
      ever<String>(
        wellGenCtrl.bitDepthIn,
        (_) => _loadBitFieldsFromController(),
      ),
      ever<String>(wellGenCtrl.bitDepth, (_) => _loadBitFieldsFromController()),
    ]);
    _loadBitFieldsFromController();
  }

  @override
  void dispose() {
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    for (final worker in _bitWorkers) {
      worker.dispose();
    }
    for (final controller in bc.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadBitFieldsFromController() {
    _setTextIfChanged('Mft', wellGenCtrl.bitMft.value);
    _setTextIfChanged('Type', wellGenCtrl.bitType.value);
    _setTextIfChanged('No. of Bits', wellGenCtrl.bitCount.value);
    _setTextIfChanged('Size', _displayBitSize(wellGenCtrl.bitSize.value));
    _setTextIfChanged('Depth-in', wellGenCtrl.bitDepthIn.value);
    _setTextIfChanged('Depth', wellGenCtrl.bitDepth.value);
  }

  void _setTextIfChanged(String key, String value) {
    final controller = bc[key];
    if (controller == null) return;
    if (controller.text == value) return;
    controller.text = value;
  }

  void _syncBitField(String key, String value) {
    switch (key) {
      case 'Mft':
        wellGenCtrl.bitMft.value = value;
        break;
      case 'Type':
        wellGenCtrl.bitType.value = value;
        break;
      case 'No. of Bits':
        wellGenCtrl.bitCount.value = value;
        break;
      case 'Size':
        wellGenCtrl.bitSize.value = _storeBitSize(value);
        break;
      case 'Depth-in':
        wellGenCtrl.bitDepthIn.value = value;
        break;
      case 'Depth':
        wellGenCtrl.bitDepth.value = value;
        break;
    }
  }

  String _displayBitSize(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return '';
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) return raw;
    final converted = AppUnits.convertValue(parsed, 'in', _diameterUnit);
    final value = converted ?? parsed;
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _storeBitSize(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return '';
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) return raw;
    final converted = AppUnits.convertValue(parsed, _diameterUnit, 'in');
    final value = converted ?? parsed;
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _handleUnitChange() {
    final nextLengthUnit = AppUnits.length;
    final nextDiameterUnit = AppUnits.diameter;
    if (_lengthUnit == nextLengthUnit && _diameterUnit == nextDiameterUnit) {
      return;
    }

    bc['Size']!.text = _convertText(
      bc['Size']!.text,
      _diameterUnit,
      nextDiameterUnit,
    );
    bc['Depth-in']!.text = _convertText(
      bc['Depth-in']!.text,
      _lengthUnit,
      nextLengthUnit,
    );
    bc['Depth']!.text = _convertText(
      bc['Depth']!.text,
      _lengthUnit,
      nextLengthUnit,
    );

    _lengthUnit = nextLengthUnit;
    _diameterUnit = nextDiameterUnit;
    _syncBitField('Size', bc['Size']!.text);
    _syncBitField('Depth-in', bc['Depth-in']!.text);
    _syncBitField('Depth', bc['Depth']!.text);
    if (mounted) setState(() {});
  }

  String _convertText(String rawValue, String fromUnit, String toUnit) {
    if (rawValue.trim().isEmpty || fromUnit == toUnit) {
      return rawValue;
    }
    final parsed = double.tryParse(rawValue.replaceAll(',', ''));
    if (parsed == null) {
      return rawValue;
    }
    final result = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (result == null) {
      return rawValue;
    }
    return result
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _applyDefaultBitDepth() {
    final mdText = wellGenCtrl.md.value.trim();
    if (mdText.isEmpty) return;
    bc['Depth-in']!.text = mdText;
    bc['Depth']!.text = mdText;
    _syncBitField('Depth-in', mdText);
    _syncBitField('Depth', mdText);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _wellPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Bit"),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: _kWellPanelBorder, width: 1),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1),
                },
                children: [
                  _bRow("Mft", "Mft", ""),
                  _bRow("Type", "Type", ""),
                  _bRow("No. of Bits", "No. of Bits", ""),
                  _bRow("Size", "Size", "(in)"),
                  _bRow("Depth-in", "Depth-in", "(ft)"),
                  _bRow("Depth", "Depth", "(ft)"),
                ],
              ),
            ),
          ),
          SizedBox(
            height: _kFooterH + 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Obx(
                  () => _toolButton(
                    tooltip: 'Default Value for Bit Depth',
                    onTap: c.isLocked.value ? null : _applyDefaultBitDepth,
                    child: Icon(
                      Icons.flash_on,
                      size: 14,
                      color: c.isLocked.value
                          ? Colors.grey.shade400
                          : Colors.deepOrange,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _bRow(String label, String key, String unit) {
    final ctrl = bc[key]!;
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        Container(
          height: _kRowH,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Obx(() {
            if (c.isLocked.value) {
              return SizedBox(
                height: _kRowH,
                child: Container(
                  color: _cellFillColor(
                    isLocked: true,
                    editableWhenUnlocked: true,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ctrl.text,
                    style: _kWellSmallInputTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Container(
              color: Colors.white,
              child: SizedBox(
                height: _kRowH,
                child: TextField(
                  controller: ctrl,
                  style: _kWellSmallInputTextStyle,
                  textAlign: TextAlign.center,
                  onChanged: (value) => _syncBitField(key, value),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            );
          }),
        ),
        Container(
          height: _kRowH,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          child: Text(
            AppUnits.unitText(unit),
            style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NOZZLE SECTION — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class NozzleSection extends StatefulWidget {
  @override
  _NozzleSectionState createState() => _NozzleSectionState();
}

class _NozzleSectionState extends State<NozzleSection> {
  final c = Get.find<DashboardController>();
  final nc = Get.isRegistered<NozzleController>()
      ? Get.find<NozzleController>()
      : Get.put(NozzleController());

  int? selectedRowIndex;

  final Map<int, TextEditingController> _countCtrls = {};
  final Map<int, TextEditingController> _sizeCtrls = {};
  final Map<int, FocusNode> _countFocusNodes = {};
  final Map<int, FocusNode> _sizeFocusNodes = {};

  TextEditingController _countCtrl(int idx) {
    _countCtrls[idx] ??= TextEditingController(
      text: nc.entries[idx].count.value <= 0
          ? ''
          : nc.entries[idx].count.value.toString(),
    );
    return _countCtrls[idx]!;
  }

  TextEditingController _sizeCtrl(int idx) {
    _sizeCtrls[idx] ??= TextEditingController(
      text: nc.entries[idx].size32.value == 0
          ? ''
          : nc.entries[idx].size32.value.toString(),
    );
    return _sizeCtrls[idx]!;
  }

  FocusNode _countFocusNode(int idx) {
    _countFocusNodes[idx] ??= FocusNode();
    return _countFocusNodes[idx]!;
  }

  FocusNode _sizeFocusNode(int idx) {
    _sizeFocusNodes[idx] ??= FocusNode();
    return _sizeFocusNodes[idx]!;
  }

  void _syncCtrl(TextEditingController ctrl, FocusNode focusNode, String text) {
    if (focusNode.hasFocus || ctrl.text == text) return;
    ctrl.text = text;
  }

  Future<void> _handleRowMenu(int rowIndex, TapDownDetails details) async {
    setState(() => selectedRowIndex = rowIndex);
    final action = await _showWellRowMenu(
      context,
      details,
      canPaste: _WellRowClipboard.canPaste('nozzle'),
    );
    if (action == null) return;

    switch (action) {
      case _WellRowMenuAction.cut:
        await _WellRowClipboard.copy('nozzle', nc.copyRow(rowIndex));
        await nc.deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.copy:
        await _WellRowClipboard.copy('nozzle', nc.copyRow(rowIndex));
        break;
      case _WellRowMenuAction.paste:
        final values = await _WellRowClipboard.paste('nozzle');
        if (values != null) {
          nc.pasteRow(rowIndex, values);
        }
        break;
      case _WellRowMenuAction.delete:
        await nc.deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.clear:
        nc.clearRow(rowIndex);
        break;
      case _WellRowMenuAction.toTop:
        nc.moveRowToTop(rowIndex);
        break;
      case _WellRowMenuAction.toBottom:
        nc.moveRowToBottom(rowIndex);
        break;
    }
  }

  @override
  void dispose() {
    for (final c in _countCtrls.values) c.dispose();
    for (final c in _sizeCtrls.values) c.dispose();
    for (final n in _countFocusNodes.values) n.dispose();
    for (final n in _sizeFocusNodes.values) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _wellPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Nozzle (1/32in)"),
          Expanded(
            child: Obx(() {
              final entries = nc.entries;
              for (int i = 0; i < entries.length; i++) {
                final countText = entries[i].count.value <= 0
                    ? ''
                    : entries[i].count.value.toString();
                final sizeText = entries[i].size32.value == 0
                    ? ''
                    : entries[i].size32.value.toString();

                if (!_countCtrls.containsKey(i)) {
                  _countCtrls[i] = TextEditingController(text: countText);
                } else {
                  _syncCtrl(_countCtrls[i]!, _countFocusNode(i), countText);
                }
                if (!_sizeCtrls.containsKey(i)) {
                  _sizeCtrls[i] = TextEditingController(text: sizeText);
                } else {
                  _syncCtrl(_sizeCtrls[i]!, _sizeFocusNode(i), sizeText);
                }
              }

              const columnWidths = <int, TableColumnWidth>{
                0: FixedColumnWidth(36),
                1: FixedColumnWidth(72),
                2: FlexColumnWidth(1),
              };
              return Column(
                children: [
                  Table(
                    border: _headerTableBorder(),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: columnWidths,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: _kGridHeaderColor),
                        children: [
                          'No.',
                          'No.',
                          'Size\n(1/32in)',
                        ].map((h) => _hCell(h, AppTheme.primaryColor)).toList(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Table(
                        border: _bodyTableBorder(),
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        columnWidths: columnWidths,
                        children: entries.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final nozzle = entry.value;
                          final bool sel = selectedRowIndex == idx;
                          final rowChildren = <Widget>[
                            GestureDetector(
                              onTap: () => setState(
                                () => selectedRowIndex = sel ? null : idx,
                              ),
                              child: _noCell(
                                idx + 1,
                                sel,
                                AppTheme.primaryColor,
                              ),
                            ),
                            _nzEditCell(_countCtrl(idx), _countFocusNode(idx), (
                              val,
                            ) {
                              nozzle.count.value = int.tryParse(val) ?? 0;
                              nc.onCellChanged(idx);
                            }),
                            _nzEditCell(_sizeCtrl(idx), _sizeFocusNode(idx), (
                              val,
                            ) {
                              nozzle.size32.value = int.tryParse(val) ?? 0;
                              nc.onCellChanged(idx);
                            }),
                          ];
                          return TableRow(
                            decoration: BoxDecoration(
                              color: sel
                                  ? _kSelectedRowColor
                                  : (idx % 2 == 0
                                        ? Colors.white
                                        : _kAltRowColor),
                            ),
                            children: rowChildren
                                .map(
                                  (child) => _rowMenuTarget(
                                    onSecondaryTapDown: (details) =>
                                        _handleRowMenu(idx, details),
                                    child: child,
                                  ),
                                )
                                .toList(),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          Obx(
            () => SizedBox(
              height: _kFooterH + 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(1, 0, 1, 0),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Text(
                            "TFA (in²)",
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (nc.isSaving.value)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 126,
                      height: 24,
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        border: Border.all(color: _kWellPanelBorder),
                        color: _kEditableCellColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          nc.tfa.value == 0
                              ? ''
                              : nc.tfa.value.toStringAsFixed(3),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nzEditCell(
    TextEditingController ctrl,
    FocusNode focusNode,
    Function(String) onChanged,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
    child: Obx(
      () => c.isLocked.value
          ? Container(
              color: _cellFillColor(isLocked: true, editableWhenUnlocked: true),
              child: SizedBox(
                height: _kRowH,
                child: Center(
                  child: Text(
                    ctrl.text,
                    style: _kWellSmallInputTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : Container(
              color: Colors.white,
              child: SizedBox(
                height: _kRowH,
                child: TextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  style: _kWellInputTextStyle,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 2,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  TIME DISTRIBUTION — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class TimeDistributionSection extends StatefulWidget {
  final OthersController activityController;
  const TimeDistributionSection({required this.activityController});
  @override
  _TimeDistributionSectionState createState() =>
      _TimeDistributionSectionState();
}

class _TimeDistributionSectionState extends State<TimeDistributionSection> {
  final c = Get.find<DashboardController>();
  late final WellGeneralController wellGenCtrl;
  int? selectedRowIndex;
  List<String> activityOptions = [];
  bool _isLoadingActivities = true;
  Worker? _timeDistributionWorker;
  List<Map<String, dynamic>> tableData = [];

  @override
  void initState() {
    super.initState();
    wellGenCtrl = Get.isRegistered<WellGeneralController>()
        ? Get.find<WellGeneralController>()
        : Get.put(WellGeneralController(), permanent: true);
    _replaceTableData(wellGenCtrl.timeDistributionRowsForUi);
    _timeDistributionWorker = ever<int>(wellGenCtrl.timeDistributionRevision, (
      _,
    ) {
      if (!mounted) return;
      setState(() {
        _replaceTableData(wellGenCtrl.timeDistributionRowsForUi);
      });
    });
    _fetchActivities();
  }

  @override
  void dispose() {
    _timeDistributionWorker?.dispose();
    _disposeTableControllers(tableData);
    super.dispose();
  }

  List<Map<String, dynamic>> _buildTableData(
    List<Map<String, String>> sourceRows,
  ) {
    return sourceRows
        .map(
          (row) => {
            'activity': row['activity'] ?? '',
            'time': TextEditingController(text: row['time'] ?? ''),
          },
        )
        .toList();
  }

  void _disposeTableControllers(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      (row['time'] as TextEditingController).dispose();
    }
  }

  void _replaceTableData(List<Map<String, String>> sourceRows) {
    final previousRows = tableData;
    tableData = _buildTableData(sourceRows);
    _disposeTableControllers(previousRows);
    if (selectedRowIndex != null && selectedRowIndex! >= tableData.length) {
      selectedRowIndex = null;
    }
  }

  void _syncRowToController(int idx) {
    if (idx < 0 || idx >= tableData.length) return;
    final row = tableData[idx];
    final timeCtrl = row['time'] as TextEditingController;
    wellGenCtrl.updateTimeDistributionRow(
      idx,
      activity: (row['activity'] ?? '').toString(),
      time: timeCtrl.text,
      notify: false,
    );
  }

  List<String> _copyableRowValues(int idx) {
    final row = tableData[idx];
    final timeCtrl = row['time'] as TextEditingController;
    return [(row['activity'] ?? '').toString(), timeCtrl.text];
  }

  void _commitRows(List<Map<String, String>> rows) {
    wellGenCtrl.hydrateTimeDistributionRows(rows);
  }

  List<String> _activityOptionsFor(String currentActivity) {
    final values = <String>[];
    for (final option in activityOptions) {
      final text = option.trim();
      if (text.isNotEmpty && !values.contains(text)) {
        values.add(text);
      }
    }

    final selected = currentActivity.trim();
    if (selected.isNotEmpty && !values.contains(selected)) {
      values.insert(0, selected);
    }
    return values;
  }

  List<Map<String, String>> _rowsForController() => tableData
      .map(
        (row) => {
          'activity': (row['activity'] ?? '').toString(),
          'time': (row['time'] as TextEditingController).text,
        },
      )
      .toList();

  void _clearRow(int idx) {
    if (idx < 0 || idx >= tableData.length) return;
    final timeCtrl = tableData[idx]['time'] as TextEditingController;
    setState(() {
      tableData[idx]['activity'] = '';
      timeCtrl.clear();
    });
    _syncRowToController(idx);
  }

  void _deleteRow(int idx) {
    if (idx < 0 || idx >= tableData.length) return;
    final rows = _rowsForController();
    rows.removeAt(idx);
    _commitRows(rows);
  }

  void _moveRowToTop(int idx) {
    if (idx <= 0 || idx >= tableData.length) return;
    final rows = _rowsForController();
    final row = rows.removeAt(idx);
    rows.insert(0, row);
    _commitRows(rows);
  }

  void _moveRowToBottom(int idx) {
    if (idx < 0 || idx >= tableData.length) return;
    final rows = _rowsForController();
    final row = rows.removeAt(idx);
    rows.add(row);
    _commitRows(rows);
  }

  void _pasteRow(int idx, List<String> values) {
    final data = List<String>.from(values);
    while (data.length < 2) {
      data.add('');
    }
    if (idx >= tableData.length) return;
    final timeCtrl = tableData[idx]['time'] as TextEditingController;
    setState(() {
      tableData[idx]['activity'] = data[0];
      timeCtrl.text = data[1];
    });
    _syncRowToController(idx);
    _checkAndAddRow(idx);
  }

  Future<void> _handleRowMenu(int rowIndex, TapDownDetails details) async {
    setState(() => selectedRowIndex = rowIndex);
    final action = await _showWellRowMenu(
      context,
      details,
      canPaste: _WellRowClipboard.canPaste('time-distribution'),
    );
    if (action == null) return;

    switch (action) {
      case _WellRowMenuAction.cut:
        await _WellRowClipboard.copy(
          'time-distribution',
          _copyableRowValues(rowIndex),
        );
        _deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.copy:
        await _WellRowClipboard.copy(
          'time-distribution',
          _copyableRowValues(rowIndex),
        );
        break;
      case _WellRowMenuAction.paste:
        final values = await _WellRowClipboard.paste('time-distribution');
        if (values != null) {
          _pasteRow(rowIndex, values);
        }
        break;
      case _WellRowMenuAction.delete:
        _deleteRow(rowIndex);
        break;
      case _WellRowMenuAction.clear:
        _clearRow(rowIndex);
        break;
      case _WellRowMenuAction.toTop:
        _moveRowToTop(rowIndex);
        break;
      case _WellRowMenuAction.toBottom:
        _moveRowToBottom(rowIndex);
        break;
    }
  }

  Future<void> _fetchActivities() async {
    try {
      final acts = await widget.activityController.getActivities();
      if (!mounted) return;
      setState(() {
        activityOptions = acts.map((a) => a.description).toList();
        _isLoadingActivities = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingActivities = false);
    }
  }

  void _checkAndAddRow(int idx) {
    if (idx == tableData.length - 1 &&
        (tableData[idx]['activity'] as String).isNotEmpty) {
      setState(() {
        tableData.add({'activity': '', 'time': TextEditingController()});
      });
    }
  }

  void _validateTotalTime(int idx) {
    double total = 0;
    for (final row in tableData) {
      final ctrl = row['time'] as TextEditingController;
      total += double.tryParse(ctrl.text) ?? 0;
    }
    if (total > 24.0) {
      tableData[idx]['time'].clear();
      _syncRowToController(idx);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            "Validation Error",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Total time cannot exceed 24 hours.",
            style: TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "OK",
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _wellPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Time Distribution"),
          Expanded(
            child: Column(
              children: [
                Table(
                  border: _headerTableBorder(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(28),
                    1: FlexColumnWidth(3),
                    2: FixedColumnWidth(50),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: _kGridHeaderColor),
                      children: [
                        'No.',
                        'Activity',
                        'Time\n(hr)',
                      ].map((h) => _hCell(h, AppTheme.primaryColor)).toList(),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Table(
                      border: _bodyTableBorder(),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(28),
                        1: FlexColumnWidth(3),
                        2: FixedColumnWidth(50),
                      },
                      children: [
                        ...tableData.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final row = entry.value;
                          final timeCtrl = row['time'] as TextEditingController;
                          final currentActivity = row['activity'] as String;
                          final selectedActivity = currentActivity.trim();
                          final activityItems = _activityOptionsFor(
                            currentActivity,
                          );
                          final bool sel = selectedRowIndex == idx;
                          final rowChildren = <Widget>[
                            GestureDetector(
                              onTap: () => setState(
                                () => selectedRowIndex = sel ? null : idx,
                              ),
                              child: _noCell(
                                idx + 1,
                                sel,
                                AppTheme.primaryColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 1,
                              ),
                              child: Obx(
                                () => c.isLocked.value
                                    ? SizedBox(
                                        height: _kRowH,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            currentActivity,
                                            style: _kWellSmallInputTextStyle,
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        height: _kRowH,
                                        child: _isLoadingActivities
                                            ? const Center(
                                                child: SizedBox(
                                                  width: 10,
                                                  height: 10,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                      ),
                                                ),
                                              )
                                            : DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value:
                                                      activityItems.contains(
                                                        selectedActivity,
                                                      )
                                                      ? selectedActivity
                                                      : null,
                                                  hint:
                                                      const SizedBox.shrink(),
                                                  isExpanded: true,
                                                  icon: const Icon(
                                                    Icons.arrow_drop_down,
                                                    size: 12,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black,
                                                  ),
                                                  menuMaxHeight: 200,
                                                  onChanged: (v) {
                                                    if (v != null) {
                                                      setState(
                                                        () =>
                                                            tableData[idx]['activity'] =
                                                                v,
                                                      );
                                                      _checkAndAddRow(idx);
                                                      _syncRowToController(idx);
                                                    }
                                                  },
                                                  items: activityItems
                                                      .map(
                                                        (o) => DropdownMenuItem(
                                                          value: o,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 4,
                                                                ),
                                                            child: Text(
                                                              o,
                                                              style:
                                                                  _kWellSmallInputTextStyle,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ),
                                       ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 1,
                              ),
                              child: Obx(
                                () => c.isLocked.value
                                    ? SizedBox(
                                        height: _kRowH,
                                        child: Center(
                                          child: Text(
                                            timeCtrl.text,
                                            style: _kWellSmallInputTextStyle,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.white,
                                        child: SizedBox(
                                          height: _kRowH,
                                          child: TextField(
                                            controller: timeCtrl,
                                            style: _kWellSmallInputTextStyle,
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            onChanged: (v) {
                                              _validateTotalTime(idx);
                                              _syncRowToController(idx);
                                            },
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                    vertical: 2,
                                                  ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              fillColor: Colors.white,
                                              filled: true,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ];

                          return TableRow(
                            decoration: BoxDecoration(
                              color: sel
                                  ? _kSelectedRowColor
                                  : (idx % 2 == 0
                                        ? Colors.white
                                        : _kAltRowColor),
                            ),
                            children: rowChildren
                                .map(
                                  (child) => _rowMenuTarget(
                                    onSecondaryTapDown: (details) =>
                                        _handleRowMenu(idx, details),
                                    child: child,
                                  ),
                                )
                                .toList(),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: _kFooterH, color: Colors.white),
        ],
      ),
    );
  }
}
