import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/engineers_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/drill_string_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/nozzle_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/well_general_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/tabular_database.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/cased_hole_controller.dart';

const double _kRowH = 22.0;
const double _kHeaderH = 28.0;
const double _kFooterH = 28.0;

const List<String> _kTimeSlots = [
  '00:00','00:30','01:00','01:30','02:00','02:30','03:00','03:30',
  '04:00','04:30','05:00','05:30','06:00','06:30','07:00','07:30',
  '08:00','08:30','09:00','09:30','10:00','10:30','11:00','11:30',
  '12:00','12:30','13:00','13:30','14:00','14:30','15:00','15:30',
  '16:00','16:30','17:00','17:30','18:00','18:30','19:00','19:30',
  '20:00','20:30','21:00','21:30','22:00','22:30','23:00','23:30',
];

// ─── Date helpers ────────────────────────────────────────────────
DateTime? _parseLongDate(String s) {
  try {
    final clean = s.contains(',') ? s.substring(s.indexOf(',') + 1).trim() : s.trim();
    const months = {
      'january':1,'february':2,'march':3,'april':4,'may':5,'june':6,
      'july':7,'august':8,'september':9,'october':10,'november':11,'december':12
    };
    final parts = clean.replaceAll(',', '').split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final month = months[parts[0].toLowerCase()];
      final day   = int.tryParse(parts[1]);
      final year  = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
  } catch (_) {}
  return null;
}

String _formatDisplay(DateTime d) =>
    '${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}/${d.year}';

String _formatStorage(DateTime d) {
  const dn = ['','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  const mn = ['','January','February','March','April','May','June','July','August','September','October','November','December'];
  return '${dn[d.weekday]}, ${mn[d.month]} ${d.day}, ${d.year}';
}

// ═══════════════════════════════════════════════════════════════════
//  ROOT
// ═══════════════════════════════════════════════════════════════════
class WellTabContent extends StatelessWidget {
  final c = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 900) {
        return Container(
          color: AppTheme.backgroundColor,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                SizedBox(height: constraints.maxHeight, child: LeftPortion()),
                const SizedBox(height: 8),
                MiddlePortion(),
                const SizedBox(height: 8),
                RightPortion(),
              ]),
            ),
          ),
        );
      }
      return Container(
        color: AppTheme.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 310, child: LeftPortion()),
              const SizedBox(width: 6),
              Expanded(child: MiddlePortion()),
              const SizedBox(width: 6),
              SizedBox(width: 260, child: RightPortion()),
            ],
          ),
        ),
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
  final c            = Get.find<DashboardController>();
  late final EngineerController engineerCtrl;
  final activityCtrl = Get.isRegistered<OthersController>()
      ? Get.find<OthersController>()
      : Get.put(OthersController());
  final wellGenCtrl  = Get.isRegistered<WellGeneralController>()
      ? Get.find<WellGeneralController>()
      : Get.put(WellGeneralController());

  List<String> activityOptions = [
    'Rig-up/Service','Drilling','Circulating','Tripping','Survey',
    'Logging','Run Casing','Testing','Coring/Reaming','Cementing'
  ];
  bool _isLoadingActivities = true;
  bool _isLoadingEngineers  = true;

  final List<String> intervalOptions = [
    '22° Hole','16° Hole','12 1/4° Hole','8 1/2° Hole','6 1/8° Hole','Completion'
  ];

  late final Map<String, TextEditingController> fc;

  String _storedDate   = '';
  String selectedTime  = '23:30';
  String? selectedEngId;
  String? selectedEng2Id;
  String selectedActivity = '';
  String selectedInterval = '';

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

    fc = {
      'Report #':           TextEditingController(),
      'User Report #':      TextEditingController(),
      'Bottom T.':          TextEditingController(),
      'MD':                 TextEditingController(),
      'TVD':                TextEditingController(),
      'Inc':                TextEditingController(),
      'Azi':                TextEditingController(),
      'WOB':                TextEditingController(),
      'Rot. Wt.':           TextEditingController(),
      'S/O Wt.':            TextEditingController(),
      'P/U Wt.':            TextEditingController(),
      'RPM':                TextEditingController(),
      'ROP':                TextEditingController(),
      'Off-bottom TQ':      TextEditingController(),
      'On-bottom TQ':       TextEditingController(),
      'Suction T.':         TextEditingController(),
      'Additional Footage': TextEditingController(),
      'NPT Time':           TextEditingController(),
      'NPT Cost':           TextEditingController(),
      'Depth Drilled':      TextEditingController(),
      'Operator Rep.':      TextEditingController(),
      'Contractor Rep.':    TextEditingController(),
      'FIT':                TextEditingController(),
      'Formation':          TextEditingController(),
    };
    _fetchActivities();
    _fetchEngineers();
    _loadFromApi();
  }

  Future<void> _fetchActivities() async {
    try {
      final acts = await activityCtrl.getActivities();
      setState(() {
        activityOptions      = acts.map((a) => a.description).toList();
        _isLoadingActivities = false;
        if (selectedActivity.isNotEmpty && !activityOptions.contains(selectedActivity))
          selectedActivity = activityOptions.isNotEmpty ? activityOptions.first : '';
      });
    } catch (_) { setState(() => _isLoadingActivities = false); }
  }

  Future<void> _fetchEngineers() async {
    try { await engineerCtrl.fetchEngineers(); } catch (_) {}
    setState(() => _isLoadingEngineers = false);
  }

  Future<void> _loadFromApi() async {
    await wellGenCtrl.fetchLatest();
    if (wellGenCtrl.savedId.value.isEmpty) return;
    final w = wellGenCtrl;
    setState(() {
      fc['Report #']!.text           = w.reportNo.value;
      fc['User Report #']!.text      = w.userReportNo.value;
      fc['MD']!.text                 = w.md.value;
      fc['TVD']!.text                = w.tvd.value;
      fc['Inc']!.text                = w.inc.value;
      fc['Azi']!.text                = w.azi.value;
      fc['WOB']!.text                = w.wob.value;
      fc['Rot. Wt.']!.text           = w.rotWt.value;
      fc['S/O Wt.']!.text            = w.soWt.value;
      fc['P/U Wt.']!.text            = w.puWt.value;
      fc['RPM']!.text                = w.rpm.value;
      fc['ROP']!.text                = w.rop.value;
      fc['Off-bottom TQ']!.text      = w.offBottomTq.value;
      fc['On-bottom TQ']!.text       = w.onBottomTq.value;
      fc['Suction T.']!.text         = w.suctionT.value;
      fc['Bottom T.']!.text          = w.bottomT.value;
      fc['Additional Footage']!.text = w.additionalFootage.value;
      fc['NPT Time']!.text           = w.nptTime.value;
      fc['NPT Cost']!.text           = w.nptCost.value;
      fc['Depth Drilled']!.text      = w.depthDrilled.value;
      fc['Operator Rep.']!.text      = w.operatorRep.value;
      fc['Contractor Rep.']!.text    = w.contractorRep.value;
      fc['FIT']!.text                = w.fit.value;
      fc['Formation']!.text          = w.formation.value;

      if (w.date.value.isNotEmpty) _storedDate = w.date.value;
      if (w.time.value.isNotEmpty) selectedTime = w.time.value;
      if (w.activity.value.isNotEmpty) selectedActivity = w.activity.value;
      if (w.interval.value.isNotEmpty) selectedInterval = w.interval.value;

      if (w.engineer.value.isNotEmpty) {
        final eng = engineerCtrl.engineers.firstWhere(
          (e) => '${e.firstName} ${e.lastName}' == w.engineer.value,
          orElse: () => Engineer(firstName: '', lastName: '', cell: '', office: '', email: ''),
        );
        if (eng.id != null) selectedEngId = eng.id;
      }
      if (w.engineer2.value.isNotEmpty) {
        final eng2 = engineerCtrl.engineers.firstWhere(
          (e) => '${e.firstName} ${e.lastName}' == w.engineer2.value,
          orElse: () => Engineer(firstName: '', lastName: '', cell: '', office: '', email: ''),
        );
        if (eng2.id != null) selectedEng2Id = eng2.id;
      }
    });
  }

  void _sync() {
    final w = wellGenCtrl;
    w.reportNo.value          = fc['Report #']!.text;
    w.userReportNo.value      = fc['User Report #']!.text;
    w.date.value              = _storedDate;
    w.time.value              = selectedTime;
    w.engineer.value          = _engName(selectedEngId);
    w.engineer2.value         = _engName(selectedEng2Id);
    w.operatorRep.value       = fc['Operator Rep.']!.text;
    w.contractorRep.value     = fc['Contractor Rep.']!.text;
    w.activity.value          = selectedActivity;
    w.md.value                = fc['MD']!.text;
    w.tvd.value               = fc['TVD']!.text;
    w.inc.value               = fc['Inc']!.text;
    w.azi.value               = fc['Azi']!.text;
    w.wob.value               = fc['WOB']!.text;
    w.rotWt.value             = fc['Rot. Wt.']!.text;
    w.soWt.value              = fc['S/O Wt.']!.text;
    w.puWt.value              = fc['P/U Wt.']!.text;
    w.rpm.value               = fc['RPM']!.text;
    w.rop.value               = fc['ROP']!.text;
    w.offBottomTq.value       = fc['Off-bottom TQ']!.text;
    w.onBottomTq.value        = fc['On-bottom TQ']!.text;
    w.suctionT.value          = fc['Suction T.']!.text;
    w.bottomT.value           = fc['Bottom T.']!.text;
    w.interval.value          = selectedInterval;
    w.fit.value               = fc['FIT']!.text;
    w.formation.value         = fc['Formation']!.text;
    w.additionalFootage.value = fc['Additional Footage']!.text;
    w.nptTime.value           = fc['NPT Time']!.text;
    w.nptCost.value           = fc['NPT Cost']!.text;
    w.depthDrilled.value      = fc['Depth Drilled']!.text;
  }

  @override
  void dispose() { fc.values.forEach((c) => c.dispose()); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Text("General", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
        ),
        const Spacer(),
      ]),
      Expanded(
        child: SingleChildScrollView(
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1)},
            children: [
              _tfRow("Report #", "Report #", ""),
              _tfRow("User Report #", "User Report #", ""),
              _dateRow(),
              _timeRow(),
              _engRow("Engineer",   selectedEngId,  (v) { setState(() => selectedEngId  = v); _sync(); }),
              _engRow("Engineer 2", selectedEng2Id, (v) { setState(() => selectedEng2Id = v); _sync(); }),
              _tfRow("Operator Rep.", "Operator Rep.", ""),
              _tfRow("Contractor Rep.", "Contractor Rep.", ""),
              _ddRow("Activity", selectedActivity, activityOptions, (v) { setState(() => selectedActivity = v!); _sync(); }),
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
              _ddRow("Interval", selectedInterval, intervalOptions, (v) { setState(() => selectedInterval = v!); _sync(); }),
              _tfRow("FIT", "FIT", "ppg"),
              _tfRow("Formation", "Formation", ""),
              _tfRow("Additional Footage", "Additional Footage", "ft"),
              _tfRow("NPT Time", "NPT Time", "hr"),
              _tfRow("NPT Cost", "NPT Cost", "\$"),
              _tfRow("Depth Drilled", "Depth Drilled", "ft"),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _lbl(String t) => Container(
    height: _kRowH,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.centerLeft,
    child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
  );

  Widget _unit(String t) => Container(
    height: _kRowH,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: Alignment.center,
    child: Text(t, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
  );

  Widget _lockedText(String text) => SizedBox(
    height: _kRowH,
    child: Align(
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: AppTheme.textPrimary),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );

  TableRow _tfRow(String label, String key, String unit) {
    final ctrl = fc[key]!;
    return TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
      _lbl(label),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(() => c.isLocked.value
            ? _lockedText(ctrl.text)
            : SizedBox(
                height: _kRowH,
                child: TextField(
                  controller: ctrl,
                  onChanged: (val) => _sync(),
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ))),
      ),
      _unit(unit),
    ]);
  }

  TableRow _dateRow() => TableRow(
    decoration: const BoxDecoration(color: Colors.white),
    children: [
      _lbl("Date"),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(() => c.isLocked.value
            ? _lockedText(_displayDate)
            : SizedBox(
                height: _kRowH,
                child: TextButton(
                  onPressed: () async {
                    final initial = _parseLongDate(_storedDate) ?? DateTime.now();
                    final picked  = await showDatePicker(
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
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        _displayDate,
                        style: const TextStyle(fontSize: 10, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 13, color: Colors.grey),
                  ]),
                ))),
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
        child: Obx(() => c.isLocked.value
            ? _lockedText(selectedTime)
            : SizedBox(
                height: _kRowH,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedTime,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 13),
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                    menuMaxHeight: 200,
                    onChanged: (v) { if (v != null) { setState(() => selectedTime = v); _sync(); } },
                    items: _kTimeSlots.map((t) => DropdownMenuItem(
                      value: t,
                      child: Center(child: Text(t, style: const TextStyle(fontSize: 10))),
                    )).toList(),
                  ),
                ))),
      ),
      _unit(''),
    ],
  );

  TableRow _ddRow(String label, String val, List<String> opts, ValueChanged<String?> onChange) =>
    TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
      _lbl(label),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(() => c.isLocked.value
            ? _lockedText(val)
            : SizedBox(
                height: _kRowH,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: opts.contains(val) ? val : null,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 13),
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                    menuMaxHeight: 200,
                    onChanged: onChange,
                    items: opts.map((o) => DropdownMenuItem(
                      value: o,
                      child: Center(
                        child: Text(o, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                      ),
                    )).toList(),
                  ),
                ))),
      ),
      _unit(''),
    ]);

  TableRow _engRow(String label, String? engId, ValueChanged<String?> onChange) =>
    TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
      _lbl(label),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(() {
          if (c.isLocked.value) {
            return _lockedText(_engName(engId));
          }
          final engineers = engineerCtrl.engineers;
          final safeEngId = engineers.any((e) => e.id == engId) ? engId : null;
          return SizedBox(
            height: _kRowH,
            child: _isLoadingEngineers
                ? const Center(child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)))
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: safeEngId,
                      hint: Center(
                        child: Text("Select Engineer", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 13),
                      style: const TextStyle(fontSize: 10, color: Colors.black),
                      menuMaxHeight: 200,
                      onChanged: onChange,
                      items: engineers.map((Engineer e) => DropdownMenuItem(
                        value: e.id,
                        child: Center(
                          child: Text(
                            "${e.firstName} ${e.lastName}",
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
          );
        }),
      ),
      _unit(''),
    ]);

  String _engName(String? id) {
    if (id == null) return '';
    final e = engineerCtrl.engineers.firstWhere(
      (e) => e.id == id,
      orElse: () => Engineer(firstName: '', lastName: '', cell: '', office: '', email: ''),
    );
    return e.id != null ? "${e.firstName} ${e.lastName}" : '';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════
Widget _hCell(String t, Color primary) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
  alignment: Alignment.center,
  child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: primary), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
);

Widget _noCell(int rowNo, bool sel, Color primary) => Container(
  height: _kRowH,
  alignment: Alignment.center,
  child: Text(
    rowNo > 0 ? '$rowNo' : '',
    style: TextStyle(fontSize: 8, color: sel ? primary : Colors.grey.shade500),
    textAlign: TextAlign.center,
  ),
);

Widget _eCell(TextEditingController ctrl, DashboardController c, {ValueChanged<String>? onChanged, bool readOnly = false}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
  child: Obx(() => (c.isLocked.value || readOnly)
      ? SizedBox(height: _kRowH, child: Center(child: Text(ctrl.text, style: TextStyle(fontSize: 9, color: AppTheme.textPrimary), textAlign: TextAlign.center)))
      : SizedBox(height: _kRowH, child: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 9),
          textAlign: TextAlign.center,
          readOnly: readOnly,
          onChanged: onChanged,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, fillColor: Colors.white, filled: true)))));

// ═══════════════════════════════════════════════════════════════════
//  MIDDLE PORTION
// ═══════════════════════════════════════════════════════════════════
class MiddlePortion extends StatefulWidget {
  @override _MiddlePortionState createState() => _MiddlePortionState();
}

class _MiddlePortionState extends State<MiddlePortion> {
  final c = Get.find<DashboardController>();
  bool cementPlug = false;
  final _cemCtrl  = TextEditingController();
  final _plugCtrl = TextEditingController();

  @override
  void dispose() { _cemCtrl.dispose(); _plugCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, bc) {
      const double cementRowH = 28.0;
      const double gap        = 2.0;
      const double bottomPad  = 4.0;
      final double totalH     = bc.maxHeight - bottomPad;
      final double flexH      = totalH - cementRowH - gap * 3;

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
    });
  }

  Widget _cementRow() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      Obx(() => Checkbox(
        value: cementPlug,
        onChanged: c.isLocked.value ? null : (v) => setState(() => cementPlug = v ?? false),
        visualDensity: VisualDensity.compact,
        activeColor: AppTheme.primaryColor,
      )),
      const Text("Cement Plug Vol. (bbl)", style: TextStyle(fontSize: 10)),
      const SizedBox(width: 6),
      SizedBox(width: 110, child: _field(_cemCtrl)),
      const SizedBox(width: 8),
      const Text("Plug Top (ft)", style: TextStyle(fontSize: 10)),
      const SizedBox(width: 6),
      SizedBox(width: 110, child: _field(_plugCtrl)),
    ]),
  );

  Widget _field(TextEditingController ctrl) => Container(
    height: 22,
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
    child: Obx(() => c.isLocked.value
        ? Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3), child: Text(ctrl.text, style: const TextStyle(fontSize: 10)))
        : TextField(controller: ctrl, style: const TextStyle(fontSize: 10), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4), border: InputBorder.none))),
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
      : Get.put(CasedHoleUIController());

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

  void _addCasingRow() {
    if (_selectedCasing == null) return;
    uiCtrl.addRowFromCasing(_selectedCasing!);

    // Successfully added, reset selection dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _selectedCasing = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── HEADER (only the dropdown source changed) ─────────────
      SizedBox(
        height: _kHeaderH,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Text("Cased Hole",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor)),
          ),
          const Spacer(),
          const Text("Add New Casing", style: TextStyle(fontSize: 9)),
          const SizedBox(width: 6),

          // ── Dynamic dropdown from API ──────────────────────────
          Obx(() {
            final casings = _casingCtrl.casings;
            final isLoading = _casingCtrl.isLoading.value;

            // Keep _selectedCasing valid if casings list changes
            if (_selectedCasing != null &&
                !casings.any((c) => c.dbId == _selectedCasing!.dbId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedCasing = null);
              });
            }

            return Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5)))
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<CasingRow>(
                        value: _selectedCasing,
                        hint: Text("Select Casing",
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade500)),
                        icon: const Icon(Icons.arrow_drop_down, size: 13),
                        style: const TextStyle(fontSize: 9, color: Colors.black),
                        menuMaxHeight: 200,
                        onChanged: (v) => setState(() => _selectedCasing = v),
                        items: casings
                            .where((csg) =>
                                csg.description.value.isNotEmpty)
                            .map((csg) => DropdownMenuItem<CasingRow>(
                                  value: csg,
                                  child: Text(
                                    csg.description.value,
                                    style: const TextStyle(fontSize: 9),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
            );
          }),

          const SizedBox(width: 6),

          // ── Add button ────────────────────────────────────────
          InkWell(
            onTap: _addCasingRow,
            child: Icon(Icons.add_box, color: AppTheme.primaryColor, size: 16),
          ),
          const SizedBox(width: 4),
        ]),
      ),

      const SizedBox(height: 2),

      // ── TABLE (completely unchanged) ──────────────────────────
      Expanded(child: LayoutBuilder(builder: (ctx, bc) {
        final double avail = bc.maxWidth - 28;
        final double cw = avail / 7;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Obx(() => Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(28),
              1: FixedColumnWidth(cw),
              2: FixedColumnWidth(cw),
              3: FixedColumnWidth(cw),
              4: FixedColumnWidth(cw),
              5: FixedColumnWidth(cw),
              6: FixedColumnWidth(cw),
              7: FixedColumnWidth(cw),
            },
            children: [
              TableRow(
                decoration:
                    BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
                children: [
                  'No.','Description','OD\n(in)','Wt.\n(lb/ft)',
                  'ID\n(in)','Top\n(ft)','Shoe\n(ft)','Len.\n(ft)'
                ].map((h) => _hCell(h, AppTheme.primaryColor)).toList(),
              ),
              ...uiCtrl.entries.asMap().entries.map((entry) {
                  final idx   = entry.key;
                  final e = entry.value;
                  final bool sel = selectedRowIndex == idx;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : (idx % 2 == 0 ? Colors.white : Colors.grey.shade50),
                    ),
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => selectedRowIndex = sel ? null : idx),
                        child: _noCell(idx + 1, sel, AppTheme.primaryColor)),
                      _eCell(e.description, c, onChanged: (v) => uiCtrl.checkAndAddRow(idx)),
                      _eCell(e.od, c, onChanged: (v) => uiCtrl.checkAndAddRow(idx)),
                      _eCell(e.wt, c, onChanged: (v) => uiCtrl.checkAndAddRow(idx)),
                      _eCell(e.idCtrl, c, onChanged: (v) => uiCtrl.checkAndAddRow(idx)),
                      _eCell(e.top, c, onChanged: (v) => uiCtrl.checkAndAddRow(idx)),
                      _eCell(e.shoe, c, onChanged: (v) => uiCtrl.checkAndAddRow(idx)),
                      _eCell(e.length, c, readOnly: true),
                    ],
                  );
                }).toList(),
            ],
          )),
        );
      })),

      SizedBox(
        height: _kFooterH,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.05),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  OPEN HOLE — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class OpenHoleSection extends StatefulWidget {
  @override _OpenHoleSectionState createState() => _OpenHoleSectionState();
}

class _OpenHoleSectionState extends State<OpenHoleSection> {
  final c = Get.find<DashboardController>();
  int? selectedRowIndex;

  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: '8.5" Hole'), TextEditingController(text: '8.500'), TextEditingController(text: '9055.0'), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
  ];

  @override
  void dispose() { for (var r in tableData) for (var ctrl in r) ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: _kHeaderH,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.1),
          alignment: Alignment.centerLeft,
          child: Text("Open Hole", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
        ),
      ),
      const SizedBox(height: 2),
      Expanded(child: LayoutBuilder(builder: (ctx, bc) {
        final double avail = bc.maxWidth - 28;
        final double cw = avail / 4;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {0: const FixedColumnWidth(28), 1: FixedColumnWidth(cw), 2: FixedColumnWidth(cw), 3: FixedColumnWidth(cw), 4: FixedColumnWidth(cw)},
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
                children: ['No.','Description','ID\n(in)','MD\n(ft)','Washout\n(%)'].map((h) => _hCell(h, AppTheme.primaryColor)).toList(),
              ),
              ...tableData.asMap().entries.map((entry) {
                final idx = entry.key; final ctrls = entry.value;
                bool sel = selectedRowIndex == idx;
                return TableRow(
                  decoration: BoxDecoration(color: sel ? AppTheme.primaryColor.withOpacity(0.1) : (idx % 2 == 0 ? Colors.white : Colors.grey.shade50)),
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => selectedRowIndex = sel ? null : idx),
                      child: _noCell(idx + 1, sel, AppTheme.primaryColor)),
                    ...ctrls.map((ctrl) => _eCell(ctrl, c)).toList(),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      })),
      SizedBox(
        height: _kFooterH,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.05),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DRILL STRING — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class DrillStringSection extends StatefulWidget {
  @override _DrillStringSectionState createState() => _DrillStringSectionState();
}

class _DrillStringSectionState extends State<DrillStringSection> {
  final c  = Get.find<DashboardController>();
  final ds = Get.isRegistered<DrillStringController>()
      ? Get.find<DrillStringController>()
      : Get.put(DrillStringController());
  int? selectedRowIndex;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: _kHeaderH,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Text("Drill String", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
          ),
          const Spacer(),
          Tooltip(onTriggered: () => Get.to(() => TabularDatabaseView()), message: 'Tabular Database',
            child: Icon(Icons.table_chart, color: AppTheme.primaryColor, size: 16)),
          const SizedBox(width: 4),
          const Tooltip(message: 'Adjust length', child: Icon(Icons.tune, color: Colors.blue, size: 16)),
          const SizedBox(width: 4),
          Obx(() => ds.isLoading.value
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
              : InkWell(onTap: ds.fetchDrillStrings, child: Icon(Icons.refresh, color: AppTheme.primaryColor, size: 16))),
          const SizedBox(width: 6),
          Obx(() => ds.isSaving.value
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
              : InkWell(
                  onTap: ds.saveAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(3)),
                    child: const Text('Save All', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600))))),
          const SizedBox(width: 4),
        ]),
      ),
      const SizedBox(height: 3),
      Expanded(child: Obx(() {
        if (ds.isLoading.value) return const Center(child: CircularProgressIndicator());
        return LayoutBuilder(builder: (ctx, bc) {
          final double avail = bc.maxWidth - 28;
          final double cw = avail / 6;
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Obx(() => Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: const FixedColumnWidth(28),
                1: FixedColumnWidth(cw),
                2: FixedColumnWidth(cw),
                3: FixedColumnWidth(cw),
                4: FixedColumnWidth(cw),
                5: FixedColumnWidth(cw),
                6: FixedColumnWidth(cw),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
                  children: ['No.','Description','OD\n(in)','Wt.\n(lb/ft)','ID\n(in)','Grade','Len.\n(ft)']
                      .map((h) => _hCell(h, AppTheme.primaryColor)).toList(),
                ),
                ...ds.entries.asMap().entries.map((e) => _dsRow(e.key, e.value)).toList(),
              ],
            )),
          );
        });
      })),
      Obx(() => SizedBox(
        height: _kFooterH,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.05),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Total String Length < Well Depth", style: TextStyle(fontSize: 9, color: Colors.black54)),
            Row(children: [
              const Text("Total Length (ft)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Container(
                width: 70, height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.white),
                child: Text(ds.totalLength.value.toStringAsFixed(1), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600))),
            ]),
          ]),
        ),
      )),
    ]);
  }

  TableRow _dsRow(int rowIdx, DrillStringEntry entry) {
    bool sel = selectedRowIndex == rowIdx;
    return TableRow(
      decoration: BoxDecoration(color: sel ? AppTheme.primaryColor.withOpacity(0.1) : (rowIdx % 2 == 0 ? Colors.white : Colors.grey.shade50)),
      children: [
        GestureDetector(
          onTap: () => setState(() => selectedRowIndex = sel ? null : rowIdx),
          child: _noCell(rowIdx + 1, sel, AppTheme.primaryColor)),
        _dsCell(entry.description, rowIdx),
        _dsCell(entry.od, rowIdx),
        _dsCell(entry.weightPpf, rowIdx),
        _dsCell(entry.idCtrl, rowIdx),
        _dsCell(entry.grade, rowIdx),
        _dsCell(entry.length, rowIdx),
      ],
    );
  }

  Widget _dsCell(TextEditingController ctrl, int rowIdx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
    child: Obx(() => c.isLocked.value
        ? SizedBox(height: _kRowH, child: Center(child: Text(ctrl.text, style: TextStyle(fontSize: 9, color: AppTheme.textPrimary), textAlign: TextAlign.center)))
        : SizedBox(height: _kRowH, child: TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 9),
            textAlign: TextAlign.center,
            onChanged: (_) => ds.onCellChanged(rowIdx),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, fillColor: Colors.white, filled: true)))));
}

// ═══════════════════════════════════════════════════════════════════
//  RIGHT PORTION — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class RightPortion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ac = Get.isRegistered<OthersController>()
        ? Get.find<OthersController>()
        : Get.put(OthersController());
    return LayoutBuilder(builder: (ctx, bc) {
      const double cementRowH = 28.0;
      const double gap        = 2.0;
      const double bottomPad  = 4.0;
      final double totalH     = bc.maxHeight - bottomPad;
      final double flexH      = totalH - cementRowH - gap * 3;

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
            SizedBox(height: flexH * 4.0 / 10, child: TimeDistributionSection(activityController: ac)),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BIT SECTION — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class BitSection extends StatefulWidget {
  @override _BitSectionState createState() => _BitSectionState();
}

class _BitSectionState extends State<BitSection> {
  final c = Get.find<DashboardController>();
  final Map<String, TextEditingController> bc = {
    'Mft':        TextEditingController(text: 'VAREL'),
    'Type':       TextEditingController(text: 'MT-TCI'),
    'No. of Bits':TextEditingController(text: '1'),
    'Size':       TextEditingController(text: '6.125'),
    'Depth-in':   TextEditingController(),
    'Depth':      TextEditingController(text: '8982.0'),
  };

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: _kHeaderH,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.1),
          alignment: Alignment.centerLeft,
          child: Text("Bit", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
        ),
      ),
      const SizedBox(height: 3),
      Expanded(
        child: SingleChildScrollView(
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1)},
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
        height: _kFooterH,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.05),
        ),
      ),
    ]);
  }

  TableRow _bRow(String label, String key, String unit) {
    final ctrl = bc[key]!;
    return TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
      Container(height: _kRowH, padding: const EdgeInsets.symmetric(horizontal: 6), alignment: Alignment.centerLeft,
        child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(() => c.isLocked.value
            ? SizedBox(height: _kRowH, child: Center(child: Text(ctrl.text, style: TextStyle(fontSize: 9, color: AppTheme.textPrimary), textAlign: TextAlign.center)))
            : SizedBox(height: _kRowH, child: TextField(controller: ctrl, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, fillColor: Colors.white, filled: true))))),
      Container(height: _kRowH, padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center,
        child: Text(unit, style: TextStyle(fontSize: 9, color: AppTheme.textSecondary))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NOZZLE SECTION — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class NozzleSection extends StatefulWidget {
  @override _NozzleSectionState createState() => _NozzleSectionState();
}

class _NozzleSectionState extends State<NozzleSection> {
  final c  = Get.find<DashboardController>();
  final nc = Get.isRegistered<NozzleController>()
      ? Get.find<NozzleController>()
      : Get.put(NozzleController());

  int? selectedRowIndex;

  final Map<int, TextEditingController> _countCtrls = {};
  final Map<int, TextEditingController> _sizeCtrls  = {};

  TextEditingController _countCtrl(int idx) {
    _countCtrls[idx] ??= TextEditingController(
        text: nc.entries[idx].count.value.toString());
    return _countCtrls[idx]!;
  }

  TextEditingController _sizeCtrl(int idx) {
    _sizeCtrls[idx] ??= TextEditingController(
        text: nc.entries[idx].size32.value == 0
            ? ''
            : nc.entries[idx].size32.value.toString());
    return _sizeCtrls[idx]!;
  }

  @override
  void dispose() {
    for (final c in _countCtrls.values) c.dispose();
    for (final c in _sizeCtrls.values)  c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: _kHeaderH,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.1),
          alignment: Alignment.centerLeft,
          child: Text("Nozzle (1/32in)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
        ),
      ),
      const SizedBox(height: 2),
      Expanded(
        child: Obx(() {
          final entries = nc.entries;
          for (int i = 0; i < entries.length; i++) {
            if (!_countCtrls.containsKey(i)) {
              _countCtrls[i] = TextEditingController(
                  text: entries[i].count.value.toString());
            }
            if (!_sizeCtrls.containsKey(i)) {
              _sizeCtrls[i] = TextEditingController(
                  text: entries[i].size32.value == 0
                      ? ''
                      : entries[i].size32.value.toString());
            }
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(28),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
                  children: ['No.', 'No.', 'Size\n(1/32in)']
                      .map((h) => _hCell(h, AppTheme.primaryColor)).toList(),
                ),
                ...entries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final nozzle = entry.value;
                  final bool sel = selectedRowIndex == idx;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : (idx % 2 == 0 ? Colors.white : Colors.grey.shade50),
                    ),
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => selectedRowIndex = sel ? null : idx),
                        child: _noCell(idx + 1, sel, AppTheme.primaryColor),
                      ),
                      _nzEditCell(_countCtrl(idx), (val) {
                        nozzle.count.value = int.tryParse(val) ?? 1;
                        nc.onCellChanged(idx);
                      }),
                      _nzEditCell(_sizeCtrl(idx), (val) {
                        nozzle.size32.value = int.tryParse(val) ?? 0;
                        nc.onCellChanged(idx);
                      }),
                    ],
                  );
                }).toList(),
              ],
            ),
          );
        }),
      ),
      Obx(() => SizedBox(
        height: _kFooterH,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.05),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Text("TFA (in²)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              if (nc.isSaving.value)
                const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)),
            ]),
            Container(
              width: 60, height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), color: Colors.white),
              child: Text(
                nc.tfa.value.toStringAsFixed(4),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      )),
    ]);
  }

  Widget _nzEditCell(TextEditingController ctrl, Function(String) onChanged) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Obx(() => c.isLocked.value
          ? SizedBox(height: _kRowH, child: Center(child: Text(ctrl.text, style: TextStyle(fontSize: 9, color: AppTheme.textPrimary), textAlign: TextAlign.center)))
          : SizedBox(height: _kRowH, child: TextField(
              controller: ctrl,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.white,
                filled: true,
              ),
            )),
      ),
    );
}

// ═══════════════════════════════════════════════════════════════════
//  TIME DISTRIBUTION — UNCHANGED
// ═══════════════════════════════════════════════════════════════════
class TimeDistributionSection extends StatefulWidget {
  final OthersController activityController;
  const TimeDistributionSection({required this.activityController});
  @override _TimeDistributionSectionState createState() => _TimeDistributionSectionState();
}

class _TimeDistributionSectionState extends State<TimeDistributionSection> {
  final c = Get.find<DashboardController>();
  int? selectedRowIndex;
  List<String> activityOptions = [];
  bool _isLoadingActivities = true;

  late List<Map<String, dynamic>> tableData;

  @override
  void initState() {
    super.initState();
    tableData = List.generate(6, (_) => {'activity': '', 'time': TextEditingController()});
    _fetchActivities();
  }

  @override
  void dispose() {
    for (final row in tableData) {
      (row['time'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    try {
      final acts = await widget.activityController.getActivities();
      setState(() {
        activityOptions = acts.map((a) => a.description).toList();
        _isLoadingActivities = false;
      });
    } catch (_) {
      setState(() => _isLoadingActivities = false);
    }
  }

  void _checkAndAddRow(int idx) {
    if (idx == tableData.length - 1 && (tableData[idx]['activity'] as String).isNotEmpty) {
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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Validation Error", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: const Text("Total time cannot exceed 24 hours.", style: TextStyle(fontSize: 12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: _kHeaderH,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.1),
          alignment: Alignment.centerLeft,
          child: Text("Time Distribution", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
        ),
      ),
      const SizedBox(height: 2),
      Expanded(child: SingleChildScrollView(
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {0: FixedColumnWidth(28), 1: FlexColumnWidth(3), 2: FixedColumnWidth(50)},
          children: [
            TableRow(
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
              children: ['No.', 'Activity', 'Time\n(hr)']
                  .map((h) => _hCell(h, AppTheme.primaryColor)).toList(),
            ),
            ...tableData.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              final timeCtrl = row['time'] as TextEditingController;
              final currentActivity = row['activity'] as String;
              final bool sel = selectedRowIndex == idx;

              return TableRow(
                decoration: BoxDecoration(
                  color: sel
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : (idx % 2 == 0 ? Colors.white : Colors.grey.shade50),
                ),
                children: [
                  GestureDetector(
                    onTap: () => setState(() => selectedRowIndex = sel ? null : idx),
                    child: _noCell(idx + 1, sel, AppTheme.primaryColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: Obx(() => c.isLocked.value
                        ? SizedBox(height: _kRowH, child: Align(alignment: Alignment.centerLeft,
                            child: Text(currentActivity, style: TextStyle(fontSize: 9, color: AppTheme.textPrimary))))
                        : SizedBox(
                            height: _kRowH,
                            child: _isLoadingActivities
                                ? const Center(child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)))
                                : DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: activityOptions.contains(currentActivity) ? currentActivity : null,
                                      hint: Text("Select", style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, size: 12),
                                      style: const TextStyle(fontSize: 9, color: Colors.black),
                                      menuMaxHeight: 200,
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => tableData[idx]['activity'] = v);
                                          _checkAndAddRow(idx);
                                        }
                                      },
                                      items: activityOptions.map((o) => DropdownMenuItem(
                                        value: o,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(o, style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis)),
                                      )).toList(),
                                    ),
                                  ),
                          )),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: Obx(() => c.isLocked.value
                        ? SizedBox(height: _kRowH, child: Center(child: Text(timeCtrl.text, style: TextStyle(fontSize: 9, color: AppTheme.textPrimary), textAlign: TextAlign.center)))
                        : SizedBox(height: _kRowH, child: TextField(
                            controller: timeCtrl,
                            style: const TextStyle(fontSize: 9),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _validateTotalTime(idx),
                            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, fillColor: Colors.white, filled: true)))),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      )),
      SizedBox(
        height: _kFooterH,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.primaryColor.withOpacity(0.05),
        ),
      ),
    ]);
  }
}