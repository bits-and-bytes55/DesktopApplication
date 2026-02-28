import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/pump_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/sce_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PumpPage extends StatelessWidget {
  PumpPage({super.key});

  final PumpController pumpController = Get.isRegistered<PumpController>()
      ? Get.find<PumpController>()
      : Get.put(PumpController());

  final SceController sceController = Get.isRegistered<SceController>()
      ? Get.find<SceController>()
      : Get.put(SceController());

  final DashboardController dashboard = Get.find<DashboardController>();

  final ScrollController shakerScrollController = ScrollController();
  final ScrollController sceScrollController = ScrollController();

  // Static shaker types for dropdown (3 options + empty)
  static const List<String> _shakerTypes = ['Shaker', 'Cleaner', 'Dryer'];

  // Static other SCE types
  static const List<String> _otherSceTypes = [
    'Degasser', 'Desander', 'Desilter', 'Centrifuge', 'Barite Rec.'
  ];

  // Always 8 screen cols total
  static const int _totalScreenCols = 8;

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
            Flexible(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: _shakerTable(context),
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
  //  Rules:
  //   - Model dropdown: selectable (auto-fills other fields from API)
  //   - Type, Liner ID, Rod OD, Stk.Length, Efficiency, Displacement → VIEW ONLY (fetched from API)
  //   - Stroke (SPM) → EDITABLE (user input triggers backend rate calculation)
  //   - Rate → VIEW ONLY (calculated by backend after SPM change)
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
                _headerCell("Model", 110), _verticalDivider(),
                _headerCell("Type", 95), _verticalDivider(),
                _headerCell("Liner ID\n(in)", 80), _verticalDivider(),
                _headerCell("Rod OD\n(in)", 80), _verticalDivider(),
                _headerCell("Stk. Length\n(in)", 95), _verticalDivider(),
                _headerCell("Efficiency\n(%)", 90), _verticalDivider(),
                _headerCell("Displ.\n(bbl/stk)", 95), _verticalDivider(),
                _headerCell("Stroke\n(stk/min)", 95), _verticalDivider(),
                _headerCell("Rate\n(gpm)", 80),
              ]),
            ),
          ),
          Expanded(
            child: Obx(() {
              final pumps = pumpController.pumps;
              final isLocked = dashboard.isLocked.value;
              final models = pumpController.availablePumpModels.toList();
              return ListView.builder(
                itemCount: pumps.length,
                itemBuilder: (context, index) {
                  final pump = pumps[index];
                  return Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(children: [
                        // Model — dropdown (auto-fills other fields)
                        _dataCell(width: 110, child: _pumpModelDropdown(pump: pump, rowIndex: index, models: models, isLocked: isLocked)),
                        _verticalDivider(),
                        // Type — VIEW ONLY
                        _dataCell(width: 95, child: Obx(() => _readOnlyCell(pump.type.value))),
                        _verticalDivider(),
                        // Liner ID — VIEW ONLY
                        _dataCell(width: 80, child: Obx(() => _readOnlyCell(pump.linerId.value))),
                        _verticalDivider(),
                        // Rod OD — VIEW ONLY
                        _dataCell(width: 80, child: Obx(() => _readOnlyCell(pump.rodOd.value))),
                        _verticalDivider(),
                        // Stroke Length — VIEW ONLY
                        _dataCell(width: 95, child: Obx(() => _readOnlyCell(pump.strokeLength.value))),
                        _verticalDivider(),
                        // Efficiency — VIEW ONLY
                        _dataCell(width: 90, child: Obx(() => _readOnlyCell(pump.efficiency.value))),
                        _verticalDivider(),
                        // Displacement — VIEW ONLY (backend calculated)
                        _dataCell(width: 95, child: Obx(() => _readOnlyCell(pump.displacement.value.isEmpty ? '-' : pump.displacement.value))),
                        _verticalDivider(),
                        // SPM (Stroke) — EDITABLE → triggers backend rate recalc
                        _dataCell(width: 95, child: _spmField(pump: pump, rowIndex: index, isLocked: isLocked)),
                        _verticalDivider(),
                        // Rate — VIEW ONLY (backend calculated)
                        _dataCell(width: 80, child: Obx(() => _readOnlyCell(pump.rate.value.isEmpty ? '-' : pump.rate.value))),
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

  /// Same formula as backend:
  /// Rate (GPM) = Displacement (bbl/stk) × SPM × (Efficiency / 100) × 42
  void _recalculateRate(dynamic pump) {
    final disp = double.tryParse(pump.displacement.value) ?? 0;
    final spm = double.tryParse(pump.spm.value) ?? 0;
    final eff = (double.tryParse(pump.efficiency.value) ?? 0) / 100;
    if (disp <= 0 || spm <= 0 || eff <= 0) {
      pump.rate.value = '';
      return;
    }
    pump.rate.value = (disp * spm * eff * 42).toStringAsFixed(1);
  }

  /// SPM field: editable — calculates rate locally on every keystroke,
  /// AND triggers debounced backend save if pump is already persisted.
  Widget _spmField({required dynamic pump, required int rowIndex, required bool isLocked}) {
    return Obx(() {
      final controller = TextEditingController(text: pump.spm.value)
        ..selection = TextSelection.collapsed(offset: (pump.spm.value as String).length);
      return TextField(
        enabled: !isLocked,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (val) {
          pump.spm.value = val;
          // ✅ Instantly recalculate rate locally using same formula as backend
          _recalculateRate(pump);
          // Also persist to backend (debounced 800ms) if pump already saved
          if (pump.id != null) {
            pumpController.onFieldChanged(rowIndex);
          }
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

  Widget _pumpModelDropdown({required dynamic pump, required int rowIndex, required List<String> models, required bool isLocked}) {
    return Obx(() {
      final currentValue = (pump.model.value as String).isEmpty ? null : pump.model.value as String;
      final safeValue = models.contains(currentValue) ? currentValue : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue, isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (selected) async {
            if (selected == null) return;
            final data = await pumpController.getPumpDataByModel(selected);
            if (data != null && rowIndex < pumpController.pumps.length) {
              final p = pumpController.pumps[rowIndex];
              p.model.value = selected;
              p.type.value = data['type']?.toString() ?? '';
              p.linerId.value = data['linerId']?.toString() ?? '';
              p.rodOd.value = data['rodOd']?.toString() ?? '';
              p.strokeLength.value = data['strokeLength']?.toString() ?? '';
              p.efficiency.value = data['efficiency']?.toString() ?? '';
              p.displacement.value = data['displacement']?.toString() ?? '';
              // ✅ Recalculate rate locally with current spm value
              _recalculateRate(p);
              // Also persist to backend if pump already saved
              if (p.id != null) {
                pumpController.onFieldChanged(rowIndex);
              }
            }
          },
          items: models.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 9)))).toList(),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  SHAKER TABLE
  // ═══════════════════════════════════════════════════════════

  Widget _shakerTable(BuildContext context) {
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
                _headerCell("Model", 120), _verticalDivider(),
                _headerCellWithSubheaders("Screen",
                  List.generate(_totalScreenCols, (i) => _subHeaderCell("${i + 1}", 48))),
                _verticalDivider(),
                _headerCell("Time\n(hr)", 70), _verticalDivider(),
                _headerCell("OOC Wt.\n(%)", 75),
              ]),
            ),
          ),
          Expanded(
            child: Obx(() {
              final shakerList = sceController.shakers.toList();
              final shakerModels = sceController.availableShakerModels.toList();
              final isLocked = dashboard.isLocked.value;
              final enabledScreenCols = sceController.maxScreenCols;

              return Scrollbar(
                controller: shakerScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: shakerScrollController,
                  itemCount: shakerList.length,
                  itemBuilder: (context, index) {
                    final shaker = shakerList[index];
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(children: [
                          _dataCell(width: 100, child: _shakerTypeDropdown(shaker: shaker, rowIndex: index, isLocked: isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 120, child: _shakerModelDropdown(shaker: shaker, rowIndex: index, models: shakerModels, isLocked: isLocked)),
                          _verticalDivider(),
                          ..._buildScreenCols(shaker, isLocked, enabledScreenCols),
                          _verticalDivider(),
                          _dataCell(width: 70, child: _timeField(shaker.time, isLocked, context)),
                          _verticalDivider(),
                          _dataCell(width: 75, child: _editableText(shaker.oocWt, isLocked)),
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

  List<Widget> _buildScreenCols(dynamic shaker, bool isLocked, int enabledCount) {
    final screenFields = [
      shaker.screen1, shaker.screen2, shaker.screen3, shaker.screen4,
      shaker.screen5, shaker.screen6, shaker.screen7, shaker.screen8,
    ];
    final List<Widget> cols = [];
    for (int i = 0; i < _totalScreenCols; i++) {
      final isEnabled = !isLocked && i < enabledCount;
      cols.add(_dataCell(
        width: 48,
        child: Obx(() => TextField(
          enabled: isEnabled,
          controller: TextEditingController(text: screenFields[i].value)
            ..selection = TextSelection.collapsed(offset: (screenFields[i].value as String).length),
          onChanged: (v) => screenFields[i].value = v,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, color: isEnabled ? Colors.black87 : Colors.grey.shade400),
          decoration: InputDecoration(
            border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true,
            filled: !isEnabled, fillColor: isEnabled ? null : Colors.grey.shade100,
          ),
        )),
      ));
      if (i < _totalScreenCols - 1) cols.add(_verticalDivider());
    }
    return cols;
  }

  Widget _shakerTypeDropdown({required dynamic shaker, required int rowIndex, required bool isLocked}) {
    return Obx(() {
      final currentValue = (shaker.shaker.value as String).isEmpty ? null : shaker.shaker.value as String;
      final safeValue = _shakerTypes.contains(currentValue) ? currentValue : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeValue, isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (selected) {
            if (rowIndex < sceController.shakers.length) {
              sceController.shakers[rowIndex].shaker.value = selected ?? '';
              if (selected == null) sceController.shakers[rowIndex].model.value = '';
            }
          },
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('—', style: TextStyle(fontSize: 9, color: Colors.grey))),
            ..._shakerTypes.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t, style: const TextStyle(fontSize: 9)))),
          ],
        ),
      );
    });
  }

  Widget _shakerModelDropdown({required dynamic shaker, required int rowIndex, required List<String> models, required bool isLocked}) {
    return Obx(() {
      final currentValue = (shaker.model.value as String).isEmpty ? null : shaker.model.value as String;
      final safeValue = models.contains(currentValue) ? currentValue : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeValue, isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (selected) async {
            if (rowIndex < sceController.shakers.length) {
              sceController.shakers[rowIndex].model.value = selected ?? '';
              if (selected != null && selected.isNotEmpty) {
                final data = await sceController.getShakerDataByModel(selected);
                if (data != null) {
                  sceController.shakers[rowIndex].shaker.value = data['shaker']?.toString() ?? '';
                  sceController.shakers[rowIndex].screens.value = data['screens']?.toString() ?? '';
                }
              }
            }
          },
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('—', style: TextStyle(fontSize: 9, color: Colors.grey))),
            ...models.map((m) => DropdownMenuItem<String?>(value: m, child: Text(m, style: const TextStyle(fontSize: 9)))),
          ],
        ),
      );
    });
  }

  Widget _timeField(RxString rxValue, bool isLocked, BuildContext context) {
    return Obx(() {
      final hrs = double.tryParse(rxValue.value) ?? 0;
      final isOver = hrs > 24;
      return TextField(
        enabled: !isLocked,
        controller: TextEditingController(text: rxValue.value)
          ..selection = TextSelection.collapsed(offset: rxValue.value.length),
        onChanged: (val) {
          rxValue.value = val;
          final h = double.tryParse(val) ?? 0;
          if (h > 24) _showTimeAlert(context);
        },
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 9, color: isOver ? Colors.red : Colors.black87),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
      );
    });
  }

  void _showTimeAlert(BuildContext context) {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(AlertDialog(
      title: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        const Text('Time Exceeded', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
      content: const Text('Time value cannot exceed 24 hours.', style: TextStyle(fontSize: 13)),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('OK'))],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
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
                _headerCell("SCE", 90), _verticalDivider(),
                _headerCell("Model", 110), _verticalDivider(),
                _headerCell("U/F\n(ppg)", 70), _verticalDivider(),
                _headerCell("O/F\n(ppg)", 70), _verticalDivider(),
                _headerCell("Time\n(hr)", 70), _verticalDivider(),
                _headerCell("OOC Wt.\n(%)", 75),
              ]),
            ),
          ),
          Expanded(
            child: Obx(() {
              final sceList = sceController.otherSce.toList();
              final sceModels = sceController.availableOtherSceModels.toList();
              final isLocked = dashboard.isLocked.value;
              return Scrollbar(
                controller: sceScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: sceScrollController,
                  itemCount: sceList.length,
                  itemBuilder: (context, index) {
                    final sce = sceList[index];
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(children: [
                          _dataCell(width: 90, child: _sceTypeDropdown(sce: sce, rowIndex: index, isLocked: isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 110, child: _sceModelDropdown(sce: sce, rowIndex: index, models: sceModels, isLocked: isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 70, child: _editableText(sce.uf, isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 70, child: _editableText(sce.of, isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 70, child: _editableText(sce.time, isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 75, child: _editableText(sce.oocWt, isLocked)),
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

  Widget _sceTypeDropdown({required dynamic sce, required int rowIndex, required bool isLocked}) {
    return Obx(() {
      final currentValue = (sce.type.value as String).isEmpty ? null : sce.type.value as String;
      final safeValue = _otherSceTypes.contains(currentValue) ? currentValue : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeValue, isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (selected) {
            if (rowIndex < sceController.otherSce.length) {
              sceController.otherSce[rowIndex].type.value = selected ?? '';
              if (selected == null) sceController.otherSce[rowIndex].model1.value = '';
            }
          },
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('—', style: TextStyle(fontSize: 9, color: Colors.grey))),
            ..._otherSceTypes.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t, style: const TextStyle(fontSize: 9)))),
          ],
        ),
      );
    });
  }

  Widget _sceModelDropdown({required dynamic sce, required int rowIndex, required List<String> models, required bool isLocked}) {
    return Obx(() {
      final currentValue = (sce.model1.value as String).isEmpty ? null : sce.model1.value as String;
      final safeValue = models.contains(currentValue) ? currentValue : null;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeValue, isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked ? null : (selected) async {
            if (rowIndex < sceController.otherSce.length) {
              sceController.otherSce[rowIndex].model1.value = selected ?? '';
              if (selected != null && selected.isNotEmpty) {
                final data = await sceController.getOtherSceDataByModel(selected);
                if (data != null) {
                  sceController.otherSce[rowIndex].type.value = data['type']?.toString() ?? '';
                }
              }
            }
          },
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('—', style: TextStyle(fontSize: 9, color: Colors.grey))),
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
                _summaryItem("Pump Rate", "gpm"), const SizedBox(height: 8),
                _summaryItem("Pump Pressure", "psi"), const SizedBox(height: 8),
                _summaryItem("Boost Pump Rate", "gpm"), const SizedBox(height: 8),
                _summaryItem("Return Rate", "gpm"), const SizedBox(height: 8),
                _summaryItem("DH Tools P. Loss", "psi"), const SizedBox(height: 8),
                _summaryItem("Motor P. Loss", "psi"),
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
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
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
        child: Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.center),
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
      child: Text(text, style: const TextStyle(fontSize: 7, color: Colors.black54), textAlign: TextAlign.center),
    );
  }

  Widget _verticalDivider() => Container(width: 1, color: Colors.grey.shade300);

  Widget _dataCell({required Widget child, required double width}) {
    return SizedBox(width: width, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2), child: child));
  }

  /// Read-only display cell — grey text, no interaction
  Widget _readOnlyCell(String text) {
    return Text(
      text.isEmpty ? '-' : text,
      style: TextStyle(fontSize: 9, color: text.isEmpty ? Colors.grey.shade400 : Colors.black54),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _plainText(String text) {
    return Text(text, style: const TextStyle(fontSize: 9, color: Colors.black87), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis);
  }

  Widget _editableText(RxString rxValue, bool isLocked) {
    return Obx(() => TextField(
      enabled: !isLocked,
      controller: TextEditingController(text: rxValue.value)
        ..selection = TextSelection.fromPosition(TextPosition(offset: rxValue.value.length)),
      onChanged: (val) => rxValue.value = val,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 9),
      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
    ));
  }

  BoxDecoration _boxStyle() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(4),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 3, offset: const Offset(0, 1))],
    border: Border.all(color: Colors.grey.shade300, width: 0.5),
  );
}