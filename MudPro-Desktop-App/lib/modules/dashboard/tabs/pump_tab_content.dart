import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/pump_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/sce_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// ─── Local row model for Pump page (independent of UG pump config) ────────────
class _PumpRow {
  final RxString model        = ''.obs;
  final RxString type         = ''.obs;
  final RxString linerId      = ''.obs;
  final RxString rodOd        = ''.obs;
  final RxString strokeLength = ''.obs;
  final RxString efficiency   = ''.obs;
  final RxString displacement = ''.obs;
  final RxString spm          = ''.obs;
  final RxString rate         = ''.obs;

  void clear() {
    model.value        = '';
    type.value         = '';
    linerId.value      = '';
    rodOd.value        = '';
    strokeLength.value = '';
    efficiency.value   = '';
    displacement.value = '';
    spm.value          = '';
    rate.value         = '';
  }

  void recalculateRate() {
    final disp = double.tryParse(displacement.value) ?? 0;
    final s    = double.tryParse(spm.value)          ?? 0;
    if (disp <= 0 || s <= 0) { rate.value = ''; return; }
    // Rate (GPM) = displacement (bbl/stk) × SPM × 42
    // displacement already includes efficiency — do NOT multiply eff again
    rate.value = (disp * s * 42).toStringAsFixed(1);
  }
}

// ─── Local row models for SCE ─────────────────────────────────────────────────
class _ShakerRow {
  final RxString shakerType     = ''.obs;
  final RxString model          = ''.obs;
  final RxString screen1        = ''.obs;
  final RxString screen2        = ''.obs;
  final RxString screen3        = ''.obs;
  final RxString screen4        = ''.obs;
  final RxString screen5        = ''.obs;
  final RxString screen6        = ''.obs;
  final RxString screen7        = ''.obs;
  final RxString screen8        = ''.obs;
  final RxString time           = ''.obs;
  final RxString oocWt          = ''.obs;
  final RxInt    enabledScreens = 0.obs;
}

class _OtherSceRow {
  final RxString type  = ''.obs;
  final RxString model = ''.obs;
  final RxString uf    = ''.obs;
  final RxString of_   = ''.obs;
  final RxString time  = ''.obs;
  final RxString oocWt = ''.obs;
}

// ─── PumpPage ─────────────────────────────────────────────────────────────────
class PumpPage extends StatefulWidget {
  const PumpPage({super.key});

  @override
  State<PumpPage> createState() => _PumpPageState();
}

class _PumpPageState extends State<PumpPage> {

  late final PumpController      pumpController;
  late final SceController       sceController;
  late final DashboardController dashboard;

  final ScrollController shakerScrollController = ScrollController();
  final ScrollController sceScrollController    = ScrollController();

  // ✅ Local rows — independent of UG pump config, empty on init
  late final List<_PumpRow>     _pumpRows;
  late final List<_ShakerRow>   _shakerRows;
  late final List<_OtherSceRow> _sceRows;

  final RxString _screenFillSelected = ''.obs;

  static const List<String> _shakerTypes = ['Shaker', 'Cleaner', 'Dryer'];
  static const List<String> _otherSceTypes = [
    'Degasser', 'Desander', 'Desilter', 'Centrifuge', 'Barite Rec.'
  ];
  static const int           _totalScreenCols    = 8;
  static const List<String>  _screenValueOptions = [
    '270', '230', '200', '170', '140', '120', '100', '80', '60', '40',
  ];

  @override
  void initState() {
    super.initState();
    pumpController = Get.isRegistered<PumpController>()
        ? Get.find<PumpController>()
        : Get.put(PumpController());
    sceController = Get.isRegistered<SceController>()
        ? Get.find<SceController>()
        : Get.put(SceController());
    dashboard = Get.find<DashboardController>();

    // ✅ 4 empty pump rows — no data loaded, user picks model from dropdown
    _pumpRows   = List.generate(4, (_) => _PumpRow());
    _shakerRows = List.generate(4, (_) => _ShakerRow());
    _sceRows    = List.generate(4, (_) => _OtherSceRow());
  }

  @override
  void dispose() {
    shakerScrollController.dispose();
    sceScrollController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Flexible(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _pumpTable()),
                  const SizedBox(width: 12),
                  SizedBox(width: 220, child: _summaryBox()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _screenAutoFillBar(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: _shakerTable(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: _otherSCETable(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PUMP TABLE
  // ═══════════════════════════════════════════════════════════

  Widget _pumpTable() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 950),
      decoration: _boxStyle(),
      child: Column(
        children: [
          _tableHeader("Pump", Icons.settings),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1)),
            ),
            child: IntrinsicHeight(
              child: Row(children: [
                _headerCell("Model",           110), _verticalDivider(),
                _headerCell("Type",             95), _verticalDivider(),
                _headerCell("Liner ID\n(in)",   80), _verticalDivider(),
                _headerCell("Rod OD\n(in)",     80), _verticalDivider(),
                _headerCell("Stk. Length\n(in)",95), _verticalDivider(),
                _headerCell("Efficiency\n(%)",  90), _verticalDivider(),
                _headerCell("Displ.\n(bbl/stk)",95), _verticalDivider(),
                _headerCell("Stroke\n(stk/min)",95), _verticalDivider(),
                _headerCell("Rate\n(gpm)",      80),
              ]),
            ),
          ),
          Expanded(
            child: Obx(() {
              final isLocked = dashboard.isLocked.value;
              // ✅ availablePumpModels comes from already-loaded UG pump config
              final models   = pumpController.availablePumpModels.toList();
              return ListView.builder(
                itemCount: _pumpRows.length,
                itemBuilder: (context, index) {
                  final row = _pumpRows[index];
                  return Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(children: [
                        // Model dropdown — selecting this fills the entire row
                        _dataCell(width: 110, child: _pumpModelDropdown(row: row, models: models, isLocked: isLocked)),
                        _verticalDivider(),
                        // All other fields are READ-ONLY — filled by model selection
                        _dataCell(width: 95,  child: Obx(() => _readOnlyCell(row.type.value))),
                        _verticalDivider(),
                        _dataCell(width: 80,  child: Obx(() => _readOnlyCell(row.linerId.value))),
                        _verticalDivider(),
                        _dataCell(width: 80,  child: Obx(() => _readOnlyCell(row.rodOd.value))),
                        _verticalDivider(),
                        _dataCell(width: 95,  child: Obx(() => _readOnlyCell(row.strokeLength.value))),
                        _verticalDivider(),
                        _dataCell(width: 90,  child: Obx(() => _readOnlyCell(row.efficiency.value))),
                        _verticalDivider(),
                        // Displacement — read-only, auto-filled from model
                        _dataCell(width: 95,  child: Obx(() => _readOnlyCell(
                          row.displacement.value.isEmpty ? '-' : row.displacement.value,
                        ))),
                        _verticalDivider(),
                        // SPM — only editable field, triggers rate calculation
                        _dataCell(width: 95,  child: _spmField(row: row, isLocked: isLocked)),
                        _verticalDivider(),
                        // Rate — read-only, auto-calculated from disp × SPM × 42
                        _dataCell(width: 80,  child: Obx(() => _readOnlyCell(
                          row.rate.value.isEmpty ? '-' : row.rate.value,
                        ))),
                      ]),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// SPM field — only editable input; auto-calculates rate on change
  Widget _spmField({required _PumpRow row, required bool isLocked}) {
    return Obx(() {
      final ctrl = TextEditingController(text: row.spm.value)
        ..selection = TextSelection.collapsed(offset: row.spm.value.length);
      return TextField(
        enabled: !isLocked,
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (val) {
          row.spm.value = val;
          row.recalculateRate(); // ✅ auto-calculate rate immediately
        },
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          color: isLocked ? Colors.grey.shade400 : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          filled: isLocked,
          fillColor: isLocked ? Colors.grey.shade50 : null,
        ),
      );
    });
  }

  /// Model dropdown — selecting a model fills all row fields from memory (no API call)
  Widget _pumpModelDropdown({
    required _PumpRow row,
    required List<String> models,
    required bool isLocked,
  }) {
    return Obx(() {
      final current = row.model.value.isEmpty ? null : row.model.value;
      final safeVal = models.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeVal,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (selected) {
            if (selected == null || selected.isEmpty) {
              // ✅ Clear entire row when empty option selected
              row.clear();
              return;
            }

            // ✅ Find pump data from already-loaded pumps in memory — NO API call, instant
            final source = pumpController.pumps.firstWhereOrNull(
              (p) => p.model.value == selected && p.hasData,
            );

            if (source != null) {
              row.model.value        = selected;
              row.type.value         = source.type.value;
              row.linerId.value      = source.linerId.value;

              // ✅ rodOd: only show if it's a real value (non-zero)
              // Backend stores 0 for non-Duplex or when not entered
              final rodVal = double.tryParse(source.rodOd.value) ?? 0;
              row.rodOd.value = rodVal > 0 ? source.rodOd.value : '';

              row.strokeLength.value = source.strokeLength.value;
              row.efficiency.value   = source.efficiency.value;
              row.displacement.value = source.displacement.value;
              row.spm.value          = ''; // SPM is entered fresh by user
              row.rate.value         = ''; // rate recalculates when SPM is entered
            }
          },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('', style: TextStyle(fontSize: 9)),
            ),
            ...models.map((m) => DropdownMenuItem<String?>(
              value: m,
              child: Text(m, style: const TextStyle(fontSize: 9)),
            )),
          ],
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  SHAKER TABLE
  // ═══════════════════════════════════════════════════════════

  Widget _shakerTable() {
    return Container(
      decoration: _boxStyle(),
      child: Column(
        children: [
          _tableHeader("Shaker", Icons.filter_alt),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1)),
            ),
            child: IntrinsicHeight(
              child: Row(children: [
                _headerCell("Shaker", 100), _verticalDivider(),
                _headerCell("Model",  120), _verticalDivider(),
                _headerCellWithSubheaders("Screen",
                    List.generate(_totalScreenCols, (i) => _subHeaderCell("${i + 1}", 48))),
                _verticalDivider(),
                _headerCell("Time\n(hr)",    70), _verticalDivider(),
                _headerCell("OOC Wt.\n(%)", 75),
              ]),
            ),
          ),
          Expanded(
            child: Obx(() {
              final isLocked     = dashboard.isLocked.value;
              final shakerModels = sceController.availableShakerModels.toList();
              return Scrollbar(
                controller: shakerScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: shakerScrollController,
                  itemCount: _shakerRows.length,
                  itemBuilder: (ctx, index) {
                    final row = _shakerRows[index];
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(children: [
                          _dataCell(width: 100, child: _shakerTypeDropdown(row: row, isLocked: isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 120, child: _shakerModelDropdown(row: row, models: shakerModels, isLocked: isLocked)),
                          _verticalDivider(),
                          ..._buildScreenCols(row, isLocked),
                          _verticalDivider(),
                          _dataCell(width: 70, child: _rxTextField(row.time,  isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 75, child: _rxTextField(row.oocWt, isLocked)),
                        ]),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _shakerTypeDropdown({required _ShakerRow row, required bool isLocked}) {
    return Obx(() {
      final current = row.shakerType.value.isEmpty ? null : row.shakerType.value;
      final safe    = _shakerTypes.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe, isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (sel) => row.shakerType.value = sel ?? '',
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('', style: TextStyle(fontSize: 9))),
            ..._shakerTypes.map((t) => DropdownMenuItem<String?>(
              value: t,
              child: Text(t, style: const TextStyle(fontSize: 9)),
            )),
          ],
        ),
      );
    });
  }

  Widget _shakerModelDropdown({required _ShakerRow row, required List<String> models, required bool isLocked}) {
    return Obx(() {
      final current = row.model.value.isEmpty ? null : row.model.value;
      final safe    = models.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe, isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (sel) async {
            row.model.value = sel ?? '';
            if (sel != null && sel.isNotEmpty) {
              final data = await sceController.getShakerDataByModel(sel);
              if (data != null) {
                final apiType = data['shaker']?.toString() ?? '';
                if (row.shakerType.value.isEmpty && apiType.isNotEmpty) {
                  row.shakerType.value = apiType;
                }
                final n = int.tryParse(data['screens']?.toString() ?? '0') ?? 0;
                row.enabledScreens.value = n;
              }
            } else {
              row.enabledScreens.value = 0;
              row.screen1.value = ''; row.screen2.value = '';
              row.screen3.value = ''; row.screen4.value = '';
              row.screen5.value = ''; row.screen6.value = '';
              row.screen7.value = ''; row.screen8.value = '';
            }
          },
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('', style: TextStyle(fontSize: 9))),
            ...models.map((m) => DropdownMenuItem<String?>(value: m, child: Text(m, style: const TextStyle(fontSize: 9)))),
          ],
        ),
      );
    });
  }

  List<Widget> _buildScreenCols(_ShakerRow row, bool isLocked) {
    final fields = [
      row.screen1, row.screen2, row.screen3, row.screen4,
      row.screen5, row.screen6, row.screen7, row.screen8,
    ];
    final List<Widget> cols = [];
    for (int i = 0; i < _totalScreenCols; i++) {
      final idx = i;
      cols.add(_dataCell(
        width: 48,
        child: Obx(() {
          final isEnabled = !isLocked && idx < row.enabledScreens.value;
          return TextField(
            enabled: isEnabled,
            controller: TextEditingController(text: fields[idx].value)
              ..selection = TextSelection.collapsed(offset: fields[idx].value.length),
            onChanged: (v) => fields[idx].value = v,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: isEnabled ? Colors.black87 : Colors.grey.shade400),
            decoration: InputDecoration(
              border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true,
              filled: !isEnabled, fillColor: isEnabled ? null : Colors.grey.shade100,
            ),
          );
        }),
      ));
      if (i < _totalScreenCols - 1) cols.add(_verticalDivider());
    }
    return cols;
  }

  // ═══════════════════════════════════════════════════════════
  //  SCREEN AUTO-FILL BAR
  // ═══════════════════════════════════════════════════════════

  Widget _screenAutoFillBar() {
    return Obx(() {
      final isLocked = dashboard.isLocked.value;
      return IntrinsicWidth(
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80, height: 22,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.shade50 : Colors.white,
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: DropdownButton<String>(
                      value: _screenFillSelected.value.isEmpty ? null : _screenFillSelected.value,
                      isExpanded: true, isDense: true,
                      hint: Text('Value', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                      icon: const Icon(Icons.arrow_drop_down, size: 13),
                      style: const TextStyle(fontSize: 9, color: Colors.black87),
                      menuMaxHeight: 200,
                      onChanged: isLocked ? null : (sel) {
                        if (sel != null) _screenFillSelected.value = sel;
                      },
                      items: _screenValueOptions.map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(v, style: const TextStyle(fontSize: 9)),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                height: 22,
                child: ElevatedButton(
                  onPressed: isLocked ? null : _autoFillScreenValues,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                  child: const Text('Fill', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _autoFillScreenValues() {
    final fillVal = _screenFillSelected.value.trim();
    if (fillVal.isEmpty) return;
    for (final row in _shakerRows) {
      if (row.model.value.isEmpty) continue;
      final fields = [row.screen1, row.screen2, row.screen3, row.screen4,
                      row.screen5, row.screen6, row.screen7, row.screen8];
      for (int i = 0; i < row.enabledScreens.value && i < _totalScreenCols; i++) {
        fields[i].value = fillVal;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  OTHER SCE TABLE
  // ═══════════════════════════════════════════════════════════

  Widget _otherSCETable() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      decoration: _boxStyle(),
      child: Column(
        children: [
          _tableHeader("Other SCE", Icons.build),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1)),
            ),
            child: IntrinsicHeight(
              child: Row(children: [
                _headerCell("SCE",          90), _verticalDivider(),
                _headerCell("Model",       110), _verticalDivider(),
                _headerCell("U/F\n(ppg)",   70), _verticalDivider(),
                _headerCell("O/F\n(ppg)",   70), _verticalDivider(),
                _headerCell("Time\n(hr)",   70), _verticalDivider(),
                _headerCell("OOC Wt.\n(%)", 75),
              ]),
            ),
          ),
          Expanded(
            child: Obx(() {
              final isLocked  = dashboard.isLocked.value;
              final sceModels = sceController.availableOtherSceModels.toList();
              return Scrollbar(
                controller: sceScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: sceScrollController,
                  itemCount: _sceRows.length,
                  itemBuilder: (ctx, index) {
                    final row = _sceRows[index];
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(children: [
                          _dataCell(width: 90,  child: _sceTypeDropdown(row: row, isLocked: isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 110, child: _sceModelDropdown(row: row, models: sceModels, isLocked: isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 70,  child: _rxTextField(row.uf,    isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 70,  child: _rxTextField(row.of_,   isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 70,  child: _rxTextField(row.time,  isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 75,  child: _rxTextField(row.oocWt, isLocked)),
                        ]),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _sceTypeDropdown({required _OtherSceRow row, required bool isLocked}) {
    return Obx(() {
      final current = row.type.value.isEmpty ? null : row.type.value;
      final safe    = _otherSceTypes.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe, isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (sel) {
            row.type.value = sel ?? '';
            if (sel == null) row.model.value = '';
          },
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('', style: TextStyle(fontSize: 9))),
            ..._otherSceTypes.map((t) => DropdownMenuItem<String?>(
              value: t,
              child: Text(t, style: const TextStyle(fontSize: 9)),
            )),
          ],
        ),
      );
    });
  }

  Widget _sceModelDropdown({required _OtherSceRow row, required List<String> models, required bool isLocked}) {
    return Obx(() {
      final current = row.model.value.isEmpty ? null : row.model.value;
      final safe    = models.contains(current) ? current : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safe, isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (sel) {
            row.model.value = sel ?? '';
          },
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('', style: TextStyle(fontSize: 9, color: Colors.grey))),
            ...models.map((m) => DropdownMenuItem<String?>(value: m, child: Text(m, style: const TextStyle(fontSize: 9)))),
          ],
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  SUMMARY BOX
  // ═══════════════════════════════════════════════════════════

  Widget _summaryBox() {
    return Container(
      decoration: _boxStyle(),
      child: Column(
        children: [
          _tableHeader("Summary", Icons.summarize),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(children: [
                _summaryItem("Pump Rate",        "gpm"), const SizedBox(height: 8),
                _summaryItem("Pump Pressure",    "psi"), const SizedBox(height: 8),
                _summaryItem("Boost Pump Rate",  "gpm"), const SizedBox(height: 8),
                _summaryItem("Return Rate",      "gpm"), const SizedBox(height: 8),
                _summaryItem("DH Tools P. Loss", "psi"), const SizedBox(height: 8),
                _summaryItem("Motor P. Loss",    "psi"),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.black87))),
        SizedBox(
          width: 70, height: 24,
          child: Obx(() => TextField(
            enabled: !dashboard.isLocked.value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 9),
            decoration: InputDecoration(
              hintText: "0.0",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 9),
              suffix: Text(unit, style: const TextStyle(fontSize: 8, color: Colors.grey)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: AppTheme.primaryColor, width: 1)),
            ),
          )),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _tableHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(text,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black87),
            textAlign: TextAlign.center),
      ),
    );
  }

  Widget _headerCellWithSubheaders(String mainText, List<Widget> subHeaders) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(mainText, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
      Row(children: subHeaders),
    ]);
  }

  Widget _subHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(text,
          style: const TextStyle(fontSize: 7, color: Colors.black54),
          textAlign: TextAlign.center),
    );
  }

  Widget _verticalDivider() => Container(width: 1, color: Colors.grey.shade300);

  Widget _dataCell({required Widget child, required double width}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: child,
      ),
    );
  }

  Widget _readOnlyCell(String text) {
    return Text(
      text.isEmpty ? '-' : text,
      style: TextStyle(
        fontSize: 9,
        color: text.isEmpty || text == '-' ? Colors.grey.shade400 : Colors.black54,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _rxTextField(RxString rxValue, bool isLocked) {
    return Obx(() => TextField(
      enabled: !isLocked,
      controller: TextEditingController(text: rxValue.value)
        ..selection = TextSelection.fromPosition(
            TextPosition(offset: rxValue.value.length)),
      onChanged: (v) => rxValue.value = v,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 9),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    ));
  }

  BoxDecoration _boxStyle() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(4),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 3, offset: const Offset(0, 1))],
    border: Border.all(color: Colors.grey.shade300, width: 0.5),
  );
}