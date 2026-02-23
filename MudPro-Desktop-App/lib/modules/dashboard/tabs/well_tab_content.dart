import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/engineers_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/drill_string_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/well_general_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/tabular_database.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

const double _kRowH = 22.0;

const List<String> _kTimeSlots = [
  '00:00','00:30','01:00','01:30','02:00','02:30','03:00','03:30',
  '04:00','04:30','05:00','05:30','06:00','06:30','07:00','07:30',
  '08:00','08:30','09:00','09:30','10:00','10:30','11:00','11:30',
  '12:00','12:30','13:00','13:30','14:00','14:30','15:00','15:30',
  '16:00','16:30','17:00','17:30','18:00','18:30','19:00','19:30',
  '20:00','20:30','21:00','21:30','22:00','22:30','23:00','23:30',
];

// ═══════════════════════════════════════════════════════════════════
//  ROOT — crossAxisAlignment.stretch so children fill real height
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
      // Desktop: stretch fills available height automatically
      return Container(
        color: AppTheme.backgroundColor,
        child: Padding(
          // bottom padding 8 for breathing room
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

// ═══════════════════════════════════════════════════════════════════
//  LEFT — GeneralSection fills stretch height, scrolls inside
// ═══════════════════════════════════════════════════════════════════
class LeftPortion extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GeneralSection();
}

// ═══════════════════════════════════════════════════════════════════
//  GENERAL SECTION
// ═══════════════════════════════════════════════════════════════════
class GeneralSection extends StatefulWidget {
  @override
  _GeneralSectionState createState() => _GeneralSectionState();
}

class _GeneralSectionState extends State<GeneralSection> {
  final c            = Get.find<DashboardController>();
  final engineerCtrl = Get.put(EngineerController());
  final activityCtrl = Get.put(OthersController());
  final wellGenCtrl  = Get.put(WellGeneralController());

  List<String> activityOptions = [
    'Rig-up/Service','Drilling','Circulating','Tripping','Survey',
    'Logging','Run Casing','Testing','Coring/Reaming','Cementing'
  ];
  bool _isLoadingActivities = true;

  final List<String> intervalOptions = [
    '22° Hole','16° Hole','12 1/4° Hole','8 1/2° Hole','6 1/8° Hole','Completion'
  ];

  late final Map<String, TextEditingController> fc;

  String selectedDate     = 'Tuesday, December 30, 2025';
  String selectedTime     = '23:30';
  String? selectedEngId;
  String? selectedEng2Id;
  String selectedActivity = 'Cementing';
  String selectedInterval = 'Completion';

  @override
  void initState() {
    super.initState();
    fc = {
      'Report #':           TextEditingController(text: '12'),
      'User Report #':      TextEditingController(),
      'Bottom T.':          TextEditingController(text: '180.0'),
      'MD':                 TextEditingController(text: '9575.0'),
      'TVD':                TextEditingController(text: '7683.0'),
      'Inc':                TextEditingController(text: '89.38'),
      'Azi':                TextEditingController(text: '299.50'),
      'WOB':                TextEditingController(),
      'Rot. Wt.':           TextEditingController(),
      'S/O Wt.':            TextEditingController(),
      'P/U Wt.':            TextEditingController(),
      'RPM':                TextEditingController(),
      'ROP':                TextEditingController(),
      'Off-bottom TQ':      TextEditingController(),
      'On-bottom TQ':       TextEditingController(),
      'Suction T.':         TextEditingController(),
      'Additional Footage': TextEditingController(text: '0.0'),
      'NPT Time':           TextEditingController(),
      'NPT Cost':           TextEditingController(),
      'Depth Drilled':      TextEditingController(text: '0.0'),
      'Operator Rep.':      TextEditingController(text: 'Wang'),
      'Contractor Rep.':    TextEditingController(text: 'Jerry'),
      'FIT':                TextEditingController(text: 'Completion'),
      'Formation':          TextEditingController(text: 'MaG'),
    };
    _fetchActivities();
    _loadFromApi();
  }

  Future<void> _fetchActivities() async {
    try {
      final acts = await activityCtrl.getActivities();
      setState(() {
        activityOptions      = acts.map((a) => a.description).toList();
        _isLoadingActivities = false;
        if (!activityOptions.contains(selectedActivity))
          selectedActivity = activityOptions.isNotEmpty ? activityOptions.first : 'Cementing';
      });
    } catch (_) { setState(() => _isLoadingActivities = false); }
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
      if (w.date.value.isNotEmpty)     selectedDate     = w.date.value;
      if (w.time.value.isNotEmpty)     selectedTime     = w.time.value;
      if (w.activity.value.isNotEmpty) selectedActivity = w.activity.value;
      if (w.interval.value.isNotEmpty) selectedInterval = w.interval.value;
    });
  }

  void _syncAndSave() {
    final w = wellGenCtrl;
    w.reportNo.value          = fc['Report #']!.text;
    w.userReportNo.value      = fc['User Report #']!.text;
    w.date.value              = selectedDate;
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
    w.save();
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
        Obx(() => wellGenCtrl.isSaving.value
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
            : InkWell(
                onTap: _syncAndSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(3)),
                  child: const Text('Save', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600))))),
        const SizedBox(width: 4),
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
              _engRow("Engineer",   selectedEngId,  (v) => setState(() => selectedEngId  = v)),
              _engRow("Engineer 2", selectedEng2Id, (v) => setState(() => selectedEng2Id = v)),
              _tfRow("Operator Rep.", "Operator Rep.", ""),
              _tfRow("Contractor Rep.", "Contractor Rep.", ""),
              _ddRow("Activity", selectedActivity, activityOptions, (v) => setState(() => selectedActivity = v!)),
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
              _ddRow("Interval", selectedInterval, intervalOptions, (v) => setState(() => selectedInterval = v!)),
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

  TableRow _tfRow(String label, String key, String unit) {
    final ctrl = fc[key]!;
    return TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
      _lbl(label),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(() => c.isLocked.value
            ? SizedBox(height: _kRowH, child: Align(alignment: Alignment.center, child: Text(ctrl.text, style: TextStyle(fontSize: 10, color: AppTheme.textPrimary), textAlign: TextAlign.center)))
            : SizedBox(height: _kRowH, child: TextField(controller: ctrl, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, fillColor: Colors.white, filled: true)))),
      ),
      _unit(unit),
    ]);
  }

  TableRow _dateRow() => TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
    _lbl("Date"),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Obx(() => c.isLocked.value
          ? SizedBox(height: _kRowH, child: Center(child: Text(selectedDate, style: TextStyle(fontSize: 10, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)))
          : SizedBox(height: _kRowH, child: TextButton(
              onPressed: () async {
                final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (p != null) setState(() => selectedDate = "${_dn(p.weekday)}, ${_mn(p.month)} ${p.day}, ${p.year}");
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
              child: Row(children: [
                Expanded(child: Text(selectedDate, style: const TextStyle(fontSize: 10, color: Colors.black), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                const Icon(Icons.arrow_drop_down, size: 13, color: Colors.grey),
              ])))),
    ),
    _unit(''),
  ]);

  TableRow _timeRow() => TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
    _lbl("Time"),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Obx(() => c.isLocked.value
          ? SizedBox(height: _kRowH, child: Center(child: Text(selectedTime, style: TextStyle(fontSize: 10, color: AppTheme.textPrimary))))
          : SizedBox(height: _kRowH, child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: selectedTime,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 13),
              style: const TextStyle(fontSize: 10, color: Colors.black),
              onChanged: (v) { if (v != null) setState(() => selectedTime = v); },
              items: _kTimeSlots.map((t) => DropdownMenuItem(value: t, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(t, style: const TextStyle(fontSize: 10))))).toList(),
            )))),
    ),
    _unit(''),
  ]);

  TableRow _ddRow(String label, String val, List<String> opts, ValueChanged<String?> onChange) =>
    TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
      _lbl(label),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(() => c.isLocked.value
            ? SizedBox(height: _kRowH, child: Center(child: Text(val, style: TextStyle(fontSize: 10, color: AppTheme.textPrimary))))
            : SizedBox(height: _kRowH, child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: val, isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, size: 13),
                style: const TextStyle(fontSize: 10, color: Colors.black),
                onChanged: onChange,
                items: opts.map((o) => DropdownMenuItem(value: o, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(o, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)))).toList(),
              )))),
      ),
      _unit(''),
    ]);

  TableRow _engRow(String label, String? engId, ValueChanged<String?> onChange) =>
    TableRow(decoration: const BoxDecoration(color: Colors.white), children: [
      _lbl(label),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Obx(() => c.isLocked.value
            ? SizedBox(height: _kRowH, child: Center(child: Text(_engName(engId), style: TextStyle(fontSize: 10, color: AppTheme.textPrimary))))
            : SizedBox(height: _kRowH, child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: engId,
                hint: Text("Select Engineer", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, size: 13),
                style: const TextStyle(fontSize: 10, color: Colors.black),
                onChanged: onChange,
                items: engineerCtrl.engineers.map((Engineer e) => DropdownMenuItem(value: e.id, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text("${e.firstName} ${e.lastName}", style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)))).toList(),
              )))),
      ),
      _unit(''),
    ]);

  Widget _lbl(String t) => Container(height: _kRowH, padding: const EdgeInsets.symmetric(horizontal: 6), alignment: Alignment.centerLeft, child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)));
  Widget _unit(String t) => Container(height: _kRowH, padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text(t, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)));

  String _engName(String? id) {
    if (id == null) return '';
    final e = engineerCtrl.engineers.firstWhere((e) => e.id == id, orElse: () => Engineer(firstName: '', lastName: '', cell: '', office: '', email: ''));
    return e.id != null ? "${e.firstName} ${e.lastName}" : '';
  }
  String _dn(int d) => ['','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][d];
  String _mn(int m) => ['','January','February','March','April','May','June','July','August','September','October','November','December'][m];
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════
Widget _hCell(String t, Color primary) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
  child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: primary), textAlign: TextAlign.center));

// No-col cell (displays row number, not editable)
Widget _noCell(int rowNo, bool sel, Color primary) => Container(
  height: _kRowH,
  alignment: Alignment.center,
  child: Text(
    rowNo > 0 ? '$rowNo' : '',
    style: TextStyle(fontSize: 8, color: sel ? primary : Colors.grey.shade500),
    textAlign: TextAlign.center,
  ),
);

Widget _eCell(TextEditingController ctrl, DashboardController c) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
  child: Obx(() => c.isLocked.value
      ? SizedBox(height: _kRowH, child: Center(child: Text(ctrl.text, style: TextStyle(fontSize: 9, color: AppTheme.textPrimary), textAlign: TextAlign.center)))
      : SizedBox(height: _kRowH, child: TextField(controller: ctrl, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, fillColor: Colors.white, filled: true)))));

// ═══════════════════════════════════════════════════════════════════
//  MIDDLE PORTION
//  Uses LayoutBuilder to get real available height — no overflow
//  Proportions:
//    CasedHole    3/9 of flex space
//    OpenHole     2/9 of flex space
//    cement row   fixed 28px
//    DrillString  4/9 of flex space
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
      const double gap        = 5.0;
      const double bottomPad  = 8.0;
      final double totalH     = bc.maxHeight - bottomPad;
      final double flexH      = totalH - cementRowH - gap * 3;

      return Padding(
        padding: const EdgeInsets.only(bottom: bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: flexH * 3 / 9, child: CasedHoleSection()),
            const SizedBox(height: gap),
            SizedBox(height: flexH * 2 / 9, child: OpenHoleSection()),
            const SizedBox(height: gap),
            SizedBox(height: cementRowH, child: _cementRow()),
            const SizedBox(height: gap),
            SizedBox(height: flexH * 4 / 9, child: DrillStringSection()),
          ],
        ),
      );
    });
  }

  Widget _cementRow() => Row(children: [
    Obx(() => Checkbox(
      value: cementPlug,
      onChanged: c.isLocked.value ? null : (v) => setState(() => cementPlug = v ?? false),
      visualDensity: VisualDensity.compact,
      activeColor: AppTheme.primaryColor,
    )),
    const Text("Cement Plug Vol. (bbl)", style: TextStyle(fontSize: 10)),
    const SizedBox(width: 6),
    SizedBox(width: 130, child: _field(_cemCtrl)),
    const SizedBox(width: 12),
    const Text("Plug Top (ft)", style: TextStyle(fontSize: 10)),
    const SizedBox(width: 6),
    SizedBox(width: 130, child: _field(_plugCtrl)),
  ]);

  Widget _field(TextEditingController ctrl) => Container(
    height: 22,
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
    child: Obx(() => c.isLocked.value
        ? Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3), child: Text(ctrl.text, style: const TextStyle(fontSize: 10)))
        : TextField(controller: ctrl, style: const TextStyle(fontSize: 10), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4), border: InputBorder.none))),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  CASED HOLE — width-filling, with No. column
// ═══════════════════════════════════════════════════════════════════
class CasedHoleSection extends StatefulWidget {
  @override _CasedHoleSectionState createState() => _CasedHoleSectionState();
}

class _CasedHoleSectionState extends State<CasedHoleSection> {
  final c = Get.find<DashboardController>();
  final List<String> casingTypes = ['30° CSG','18 5/8° CSG','13 3/8° CSG','9 5/8° CSG','7° LINER'];
  String selectedCasingType = '30° CSG';
  int? selectedRowIndex;

  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: '30" CSG'),      TextEditingController(text: '30.000'), TextEditingController(),              TextEditingController(text: '28.500'), TextEditingController(text: '0.0'),    TextEditingController(),              TextEditingController()],
    [TextEditingController(text: '18 5/8" CSG'),  TextEditingController(text: '18.625'), TextEditingController(),              TextEditingController(text: '17.755'), TextEditingController(text: '0.0'),    TextEditingController(),              TextEditingController()],
    [TextEditingController(text: '13 3/8" CSG'),  TextEditingController(text: '13.375'), TextEditingController(),              TextEditingController(text: '12.415'), TextEditingController(text: '0.0'),    TextEditingController(text: '6000.0'),TextEditingController(text: '6000.0')],
    [TextEditingController(text: '9 5/8" CSG'),   TextEditingController(text: '9.625'),  TextEditingController(text: '47.000'),TextEditingController(text: '8.755'),  TextEditingController(text: '0.0'),    TextEditingController(text: '7095.0'),TextEditingController(text: '7095.0')],
    [TextEditingController(text: '7" Liner'),      TextEditingController(text: '7.000'),  TextEditingController(text: '26.000'),TextEditingController(text: '6.276'),  TextEditingController(text: '6872.0'), TextEditingController(text: '8080.0'),TextEditingController(text: '1208.0')],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
  ];

  @override
  void dispose() { for (var r in tableData) for (var ctrl in r) ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: AppTheme.primaryColor.withOpacity(0.1),
          child: Text("Cased Hole", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor))),
        const Spacer(),
        const Text("Add New Casing", style: TextStyle(fontSize: 9)),
        const SizedBox(width: 6),
        Container(
          height: 22, padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: selectedCasingType,
            icon: const Icon(Icons.arrow_drop_down, size: 13),
            style: const TextStyle(fontSize: 9, color: Colors.black),
            onChanged: (v) { if (v != null) setState(() => selectedCasingType = v); },
            items: casingTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 9)))).toList(),
          )),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => setState(() {
            tableData.add(List.generate(7, (_) => TextEditingController()));
            tableData.last[0].text = selectedCasingType;
          }),
          child: Icon(Icons.add_box, color: AppTheme.primaryColor, size: 16)),
        const SizedBox(width: 4),
      ]),
      const SizedBox(height: 3),
      Expanded(child: LayoutBuilder(builder: (ctx, bc) {
        // col0=No(28), col1..7 share rest equally
        final double avail = bc.maxWidth - 28;
        final double cw = avail / 7;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
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
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
                children: ['No.','Description','OD\n(in)','Wt.\n(lb/ft)','ID\n(in)','Top\n(ft)','Shoe\n(ft)','Len.\n(ft)']
                    .map((h) => _hCell(h, AppTheme.primaryColor)).toList(),
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
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  OPEN HOLE — with No. column
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
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: AppTheme.primaryColor.withOpacity(0.1),
        child: Text("Open Hole", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor))),
      const SizedBox(height: 3),
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
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DRILL STRING — No. column, white rows, Save All, live total
// ═══════════════════════════════════════════════════════════════════
class DrillStringSection extends StatefulWidget {
  @override _DrillStringSectionState createState() => _DrillStringSectionState();
}

class _DrillStringSectionState extends State<DrillStringSection> {
  final c  = Get.find<DashboardController>();
  final ds = Get.put(DrillStringController());
  int? selectedRowIndex;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: AppTheme.primaryColor.withOpacity(0.1),
          child: Text("Drill String", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor))),
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
      const SizedBox(height: 3),
      Expanded(child: Obx(() {
        if (ds.isLoading.value) return const Center(child: CircularProgressIndicator());
        return LayoutBuilder(builder: (ctx, bc) {
          // col0=No(28), 6 data cols share rest
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
      // Total length footer
      Obx(() => Container(
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
//  RIGHT PORTION — mirror exact pixel heights from MiddlePortion
// ═══════════════════════════════════════════════════════════════════
class RightPortion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ac = Get.put(OthersController());
    return LayoutBuilder(builder: (ctx, bc) {
      const double cementRowH = 28.0;
      const double gap        = 5.0;
      const double bottomPad  = 8.0;
      final double totalH     = bc.maxHeight - bottomPad;
      final double flexH      = totalH - cementRowH - gap * 3;

      return Padding(
        padding: const EdgeInsets.only(bottom: bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: flexH * 3 / 9, child: BitSection()),
            const SizedBox(height: gap),
            SizedBox(height: flexH * 2 / 9, child: NozzleSection()),
            const SizedBox(height: gap),
            const SizedBox(height: cementRowH),   // spacer matches cement row
            const SizedBox(height: gap),
            SizedBox(height: flexH * 4 / 9, child: TimeDistributionSection(activityController: ac)),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BIT SECTION
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
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: AppTheme.primaryColor.withOpacity(0.1),
        child: Text("Bit", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor))),
      Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1)},
        children: [
          _bRow("Mft","Mft",""), _bRow("Type","Type",""), _bRow("No. of Bits","No. of Bits",""),
          _bRow("Size","Size","(in)"), _bRow("Depth-in","Depth-in","(ft)"), _bRow("Depth","Depth","(ft)"),
        ],
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
//  NOZZLE SECTION — with No. column
// ═══════════════════════════════════════════════════════════════════
class NozzleSection extends StatefulWidget {
  @override _NozzleSectionState createState() => _NozzleSectionState();
}

class _NozzleSectionState extends State<NozzleSection> {
  final c = Get.find<DashboardController>();
  int? selectedRowIndex;
  List<List<TextEditingController>> tableData = [
    [TextEditingController(text:'1'), TextEditingController(text:'3'), TextEditingController(text:'14')],
    [TextEditingController(text:'2'), TextEditingController(), TextEditingController()],
    [TextEditingController(text:'3'), TextEditingController(), TextEditingController()],
  ];
  final TextEditingController tfaCtrl = TextEditingController(text: '0.518');

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: AppTheme.primaryColor.withOpacity(0.1),
        child: Text("Nozzle (1/32in)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor))),
      Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        // No(28) | No.(flex) | Size(flex)
        columnWidths: const {0: FixedColumnWidth(28), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
        children: [
          TableRow(decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
            children: ['No.','No.','Size\n(1/32in)'].map((h) => _hCell(h, AppTheme.primaryColor)).toList()),
          ...tableData.asMap().entries.map((entry) {
            final idx = entry.key; final ctrls = entry.value;
            bool sel = selectedRowIndex == idx;
            return TableRow(
              decoration: BoxDecoration(color: sel ? AppTheme.primaryColor.withOpacity(0.1) : (idx % 2 == 0 ? Colors.white : Colors.grey.shade50)),
              children: [
                GestureDetector(
                  onTap: () => setState(() => selectedRowIndex = sel ? null : idx),
                  child: _noCell(idx + 1, sel, AppTheme.primaryColor)),
                _nzCell(ctrls[1]),
                _nzCell(ctrls[2]),
              ],
            );
          }).toList(),
        ],
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: AppTheme.primaryColor.withOpacity(0.05),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("TFA (in²)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
          Container(width: 60, height: 20, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
            child: Obx(() => c.isLocked.value
                ? Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3), child: Text(tfaCtrl.text, style: const TextStyle(fontSize: 9)))
                : TextField(controller: tfaCtrl, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3), border: InputBorder.none)))),
        ]),
      ),
    ]);
  }

  Widget _nzCell(TextEditingController ctrl) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
    child: Obx(() => c.isLocked.value
        ? SizedBox(height: _kRowH, child: Center(child: Text(ctrl.text, style: TextStyle(fontSize: 9, color: AppTheme.textPrimary), textAlign: TextAlign.center)))
        : SizedBox(height: _kRowH, child: TextField(controller: ctrl, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, fillColor: Colors.white, filled: true)))));
}

// ═══════════════════════════════════════════════════════════════════
//  TIME DISTRIBUTION — with No. column, scrollable inside height
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

  List<List<dynamic>> tableData = [
    ['1','MUD BOP','2.00'], ['2','Install Wellhead','2.30'], ['3','N/Up BOP','3.00'],
    ['4','Pressure Test','3.00'], ['5','Others','2.00'], ['6','Circulation','1.30'],
    ['7','Tripping','4.00'], ['8','Drilling Cement','6.90'],
  ];

  @override
  void initState() { super.initState(); _fetchActivities(); }

  Future<void> _fetchActivities() async {
    try {
      final acts = await widget.activityController.getActivities();
      setState(() { activityOptions = acts.map((a) => a.description).toList(); _isLoadingActivities = false; });
    } catch (_) { setState(() => _isLoadingActivities = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: AppTheme.primaryColor.withOpacity(0.1),
        child: Text("Time Distribution", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor))),
      Expanded(child: SingleChildScrollView(
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          // No(28) | Activity(flex) | Time(50)
          columnWidths: const {0: FixedColumnWidth(28), 1: FlexColumnWidth(3), 2: FixedColumnWidth(50)},
          children: [
            TableRow(
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
              children: ['No.','Activity','Time\n(hr)'].map((h) => _hCell(h, AppTheme.primaryColor)).toList()),
            ...tableData.asMap().entries.map((entry) {
              final idx = entry.key; final row = entry.value;
              final timeCtrl = TextEditingController(text: row[2]);
              bool sel = selectedRowIndex == idx;
              return TableRow(
                decoration: BoxDecoration(color: sel ? AppTheme.primaryColor.withOpacity(0.1) : (idx % 2 == 0 ? Colors.white : Colors.grey.shade50)),
                children: [
                  GestureDetector(
                    onTap: () => setState(() => selectedRowIndex = sel ? null : idx),
                    child: _noCell(idx + 1, sel, AppTheme.primaryColor)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: Obx(() => c.isLocked.value
                        ? SizedBox(height: _kRowH, child: Align(alignment: Alignment.centerLeft, child: Text(row[1], style: TextStyle(fontSize: 9, color: AppTheme.textPrimary))))
                        : SizedBox(height: _kRowH, child: _isLoadingActivities
                            ? const Center(child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)))
                            : DropdownButtonHideUnderline(child: DropdownButton<String>(
                                value: activityOptions.contains(row[1]) ? row[1] : (activityOptions.isNotEmpty ? activityOptions.first : null),
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, size: 12),
                                style: const TextStyle(fontSize: 9, color: Colors.black),
                                onChanged: (v) { if (v != null) setState(() => tableData[idx][1] = v); },
                                items: activityOptions.map((o) => DropdownMenuItem(value: o, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(o, style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis)))).toList(),
                              ))))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: Obx(() => c.isLocked.value
                        ? SizedBox(height: _kRowH, child: Center(child: Text(timeCtrl.text, style: TextStyle(fontSize: 9, color: AppTheme.textPrimary), textAlign: TextAlign.center)))
                        : SizedBox(height: _kRowH, child: TextField(controller: timeCtrl, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, onChanged: (v) => tableData[idx][2] = v, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2), border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, fillColor: Colors.white, filled: true))))),
                ],
              );
            }).toList(),
          ],
        ),
      )),
    ]);
  }
}