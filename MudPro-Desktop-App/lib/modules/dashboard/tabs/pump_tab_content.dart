import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/pump_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/sce_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PumpPage extends StatelessWidget {
  PumpPage({super.key});

  // ✅ FIXED: Use `final` fields, NOT getters — getters break Obx reactive tracking
  final PumpController pumpController = Get.isRegistered<PumpController>()
      ? Get.find<PumpController>()
      : Get.put(PumpController());

  final SceController sceController = Get.isRegistered<SceController>()
      ? Get.find<SceController>()
      : Get.put(SceController());

  final DashboardController dashboard = Get.find<DashboardController>();

  final ScrollController shakerScrollController = ScrollController();
  final ScrollController sceScrollController = ScrollController();

  String _calculateRate(String displacement, String spm, String efficiency) {
    final disp = double.tryParse(displacement) ?? 0;
    final s = double.tryParse(spm) ?? 0;
    final eff = (double.tryParse(efficiency) ?? 0) / 100;
    if (disp == 0 || s == 0 || eff == 0) return '';
    return (disp * s * eff * 42).toStringAsFixed(1);
  }

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

  // ========== PUMP TABLE ==========
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
              child: Row(
                children: [
                  _headerCell("Model", 110),
                  _verticalDivider(),
                  _headerCell("Type", 95),
                  _verticalDivider(),
                  _headerCell("Liner ID\n(in)", 80),
                  _verticalDivider(),
                  _headerCell("Rod OD\n(in)", 80),
                  _verticalDivider(),
                  _headerCell("Stk. Length\n(in)", 95),
                  _verticalDivider(),
                  _headerCell("Efficiency\n(%)", 90),
                  _verticalDivider(),
                  _headerCell("Displ.\n(bbl/stk)", 95),
                  _verticalDivider(),
                  _headerCell("Stroke\n(stk/min)", 95),
                  _verticalDivider(),
                  _headerCell("Rate\n(gpm)", 80),
                ],
              ),
            ),
          ),
          Expanded(
            // ✅ Single Obx at the top level for the whole list
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
                      child: Row(
                        children: [
                          // ✅ Model dropdown — NO nested Obx
                          _dataCell(
                            width: 110,
                            child: _pumpModelDropdown(
                              pump: pump,
                              rowIndex: index,
                              models: models,
                              isLocked: isLocked,
                            ),
                          ),
                          _verticalDivider(),
                          // Type — read-only, use Obx only for this field
                          _dataCell(
                            width: 95,
                            child: Obx(() => _plainText(pump.type.value)),
                          ),
                          _verticalDivider(),
                          _dataCell(width: 80, child: _editableText(pump.linerId, isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 80, child: _editableText(pump.rodOd, isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 95, child: _editableText(pump.strokeLength, isLocked)),
                          _verticalDivider(),
                          _dataCell(width: 90, child: _editableText(pump.efficiency, isLocked)),
                          _verticalDivider(),
                          _dataCell(
                            width: 95,
                            child: Obx(() => _plainText(
                                pump.displacement.value.isEmpty ? '-' : pump.displacement.value)),
                          ),
                          _verticalDivider(),
                          _dataCell(
                            width: 95,
                            child: _editableTextWithCallback(
                              pump.spm,
                              isLocked: isLocked,
                              onChanged: (_) => pump.spm.refresh(),
                            ),
                          ),
                          _verticalDivider(),
                          _dataCell(
                            width: 80,
                            child: Obx(() {
                              final rate = _calculateRate(
                                pump.displacement.value,
                                pump.spm.value,
                                pump.efficiency.value,
                              );
                              if (rate.isNotEmpty) pump.rate.value = rate;
                              return _plainText(rate.isEmpty ? '-' : rate);
                            }),
                          ),
                        ],
                      ),
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

  // ✅ FIXED: No Obx inside — receives data as parameters
  Widget _pumpModelDropdown({
    required dynamic pump,
    required int rowIndex,
    required List<String> models,
    required bool isLocked,
  }) {
    return Obx(() {
      final currentValue = (pump.model.value as String).isEmpty ? null : pump.model.value as String;
      // Safety: ensure value exists in items
      final safeValue = models.contains(currentValue) ? currentValue : null;

      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: const Text("Select", style: TextStyle(fontSize: 9, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (selected) async {
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
                  }
                },
          items: models
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: const TextStyle(fontSize: 9)),
                  ))
              .toList(),
        ),
      );
    });
  }

  // ========== SHAKER TABLE ==========
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
              child: Row(
                children: [
                  _headerCell("Shaker", 100),
                  _verticalDivider(),
                  _headerCell("Model", 120),
                  _verticalDivider(),
                  _headerCellWithSubheaders("Screen", [
                    _subHeaderCell("", 55),
                    _subHeaderCell("", 55),
                    _subHeaderCell("", 55),
                    _subHeaderCell("", 55),
                  ]),
                  _verticalDivider(),
                  _headerCell("Time\n(hr)", 70),
                  _verticalDivider(),
                  _headerCell("OOC Wt.\n(%)", 75),
                ],
              ),
            ),
          ),
          Expanded(
            // ✅ Single Obx wrapping entire list
            child: Obx(() {
              final shakerList = sceController.shakers.toList();
              final shakerTypes = sceController.availableShakerTypes.toList();
              final shakerModels = sceController.availableShakerModels.toList();
              final isLocked = dashboard.isLocked.value;

              return Scrollbar(
                controller: shakerScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: shakerScrollController,
                  itemCount: shakerList.length,
                  itemBuilder: (context, index) {
                    final shaker = shakerList[index];
                    final isLast = index == shakerList.length - 1;

                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // ✅ Shaker type dropdown — no nested Obx
                            _dataCell(
                              width: 100,
                              child: _shakerTypeDropdown(
                                shaker: shaker,
                                rowIndex: index,
                                types: shakerTypes,
                                isLocked: isLocked,
                                isLast: isLast,
                              ),
                            ),
                            _verticalDivider(),
                            // ✅ Shaker model dropdown — no nested Obx
                            _dataCell(
                              width: 120,
                              child: _shakerModelDropdown(
                                shaker: shaker,
                                rowIndex: index,
                                models: shakerModels,
                                isLocked: isLocked,
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(width: 55, child: _editableText(shaker.screen1, isLocked)),
                            _verticalDivider(),
                            _dataCell(width: 55, child: _editableText(shaker.screen2, isLocked)),
                            _verticalDivider(),
                            _dataCell(width: 55, child: _editableText(shaker.screen3, isLocked)),
                            _verticalDivider(),
                            _dataCell(width: 55, child: _editableText(shaker.screen4, isLocked)),
                            _verticalDivider(),
                            _dataCell(width: 70, child: _editableText(shaker.time, isLocked)),
                            _verticalDivider(),
                            _dataCell(width: 75, child: _editableText(shaker.oocWt, isLocked)),
                          ],
                        ),
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

  // ✅ FIXED: Receives types as parameter — no nested Obx needed
  Widget _shakerTypeDropdown({
    required dynamic shaker,
    required int rowIndex,
    required List<String> types,
    required bool isLocked,
    required bool isLast,
  }) {
    final effectiveTypes =
        types.isNotEmpty ? types : <String>['Shaker', 'Cleaner', 'Degasser'];

    return Obx(() {
      final currentValue =
          (shaker.shaker.value as String).isEmpty ? null : shaker.shaker.value as String;
      final safeValue = effectiveTypes.contains(currentValue) ? currentValue : null;

      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: const Text("Select", style: TextStyle(fontSize: 9, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (selected) async {
                  if (selected == null) return;
                  final data = await sceController.getShakerDataByType(selected);
                  if (rowIndex < sceController.shakers.length) {
                    final s = sceController.shakers[rowIndex];
                    s.shaker.value = selected;
                    if (data != null) {
                      s.model.value = data['model']?.toString() ?? '';
                      s.screens.value = data['screens']?.toString() ?? '';
                    }
                    if (isLast) {
                      sceController.shakers.add(shaker.clone()
                        ..shaker.value = ''
                        ..model.value = '');
                    }
                  }
                },
          items: effectiveTypes
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: const TextStyle(fontSize: 9)),
                  ))
              .toList(),
        ),
      );
    });
  }

  // ✅ FIXED: Receives models as parameter — no nested Obx needed
  Widget _shakerModelDropdown({
    required dynamic shaker,
    required int rowIndex,
    required List<String> models,
    required bool isLocked,
  }) {
    return Obx(() {
      final currentValue =
          (shaker.model.value as String).isEmpty ? null : shaker.model.value as String;
      final safeValue = models.contains(currentValue) ? currentValue : null;

      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: const Text("Select", style: TextStyle(fontSize: 9, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (selected) async {
                  if (selected == null) return;
                  final data = await sceController.getShakerDataByModel(selected);
                  if (rowIndex < sceController.shakers.length) {
                    final s = sceController.shakers[rowIndex];
                    s.model.value = selected;
                    if (data != null) {
                      s.shaker.value = data['shaker']?.toString() ?? '';
                      s.screens.value = data['screens']?.toString() ?? '';
                    }
                  }
                },
          items: models
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: const TextStyle(fontSize: 9)),
                  ))
              .toList(),
        ),
      );
    });
  }

  // ========== OTHER SCE TABLE ==========
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
              child: Row(
                children: [
                  _headerCell("SCE", 90),
                  _verticalDivider(),
                  _headerCell("Model", 110),
                  _verticalDivider(),
                  _headerCell("U/F\n(ppg)", 70),
                  _verticalDivider(),
                  _headerCell("O/F\n(ppg)", 70),
                  _verticalDivider(),
                  _headerCell("Time\n(hr)", 70),
                  _verticalDivider(),
                  _headerCell("OOC Wt.\n(%)", 75),
                ],
              ),
            ),
          ),
          Expanded(
            // ✅ Single Obx wrapping entire list
            child: Obx(() {
              final sceList = sceController.otherSce.toList();
              final sceTypes = sceController.availableOtherSceTypes.toList();
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
                    final isLast = index == sceList.length - 1;

                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // ✅ SCE type dropdown
                            _dataCell(
                              width: 90,
                              child: _sceTypeDropdown(
                                sce: sce,
                                rowIndex: index,
                                types: sceTypes,
                                isLocked: isLocked,
                                isLast: isLast,
                              ),
                            ),
                            _verticalDivider(),
                            // ✅ SCE model dropdown
                            _dataCell(
                              width: 110,
                              child: _sceModelDropdown(
                                sce: sce,
                                rowIndex: index,
                                models: sceModels,
                                isLocked: isLocked,
                              ),
                            ),
                            _verticalDivider(),
                            _dataCell(width: 70, child: _editableText(sce.uf, isLocked)),
                            _verticalDivider(),
                            _dataCell(width: 70, child: _editableText(sce.of, isLocked)),
                            _verticalDivider(),
                            _dataCell(width: 70, child: _editableText(sce.time, isLocked)),
                            _verticalDivider(),
                            _dataCell(width: 75, child: _editableText(sce.oocWt, isLocked)),
                          ],
                        ),
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

  // ✅ FIXED: No nested Obx
  Widget _sceTypeDropdown({
    required dynamic sce,
    required int rowIndex,
    required List<String> types,
    required bool isLocked,
    required bool isLast,
  }) {
    final effectiveTypes =
        types.isNotEmpty ? types : <String>['Degasser', 'Desander', 'Desilter', 'Centrifuge'];

    return Obx(() {
      final currentValue =
          (sce.type.value as String).isEmpty ? null : sce.type.value as String;
      final safeValue = effectiveTypes.contains(currentValue) ? currentValue : null;

      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: const Text("Select", style: TextStyle(fontSize: 9, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (selected) async {
                  if (selected == null) return;
                  final data = await sceController.getOtherSceDataByType(selected);
                  if (rowIndex < sceController.otherSce.length) {
                    final s = sceController.otherSce[rowIndex];
                    s.type.value = selected;
                    if (data != null) {
                      s.model1.value = data['model1']?.toString() ?? '';
                    }
                    if (isLast) {
                      sceController.otherSce.add(sce.clone()
                        ..type.value = ''
                        ..model1.value = '');
                    }
                  }
                },
          items: effectiveTypes
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: const TextStyle(fontSize: 9)),
                  ))
              .toList(),
        ),
      );
    });
  }

  // ✅ FIXED: No nested Obx
  Widget _sceModelDropdown({
    required dynamic sce,
    required int rowIndex,
    required List<String> models,
    required bool isLocked,
  }) {
    return Obx(() {
      final currentValue =
          (sce.model1.value as String).isEmpty ? null : sce.model1.value as String;
      final safeValue = models.contains(currentValue) ? currentValue : null;

      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          hint: const Text("Select", style: TextStyle(fontSize: 9, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: isLocked
              ? null
              : (selected) async {
                  if (selected == null) return;
                  final data = await sceController.getOtherSceDataByModel(selected);
                  if (rowIndex < sceController.otherSce.length) {
                    final s = sceController.otherSce[rowIndex];
                    s.model1.value = selected;
                    if (data != null) {
                      s.type.value = data['type']?.toString() ?? '';
                    }
                  }
                },
          items: models
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m, style: const TextStyle(fontSize: 9)),
                  ))
              .toList(),
        ),
      );
    });
  }

  // ========== SUMMARY BOX ==========
  Widget _summaryBox() {
    return Container(
      decoration: _boxStyle(),
      child: Column(
        children: [
          _tableHeader("Summary", Icons.summarize),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _summaryItem("Pump Rate", "gpm"),
                  const SizedBox(height: 8),
                  _summaryItem("Pump Pressure", "psi"),
                  const SizedBox(height: 8),
                  _summaryItem("Boost Pump Rate", "gpm"),
                  const SizedBox(height: 8),
                  _summaryItem("Return Rate", "gpm"),
                  const SizedBox(height: 8),
                  _summaryItem("DH Tools P. Loss", "psi"),
                  const SizedBox(height: 8),
                  _summaryItem("Motor P. Loss", "psi"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.black87))),
          SizedBox(
            width: 70,
            height: 24,
            child: Obx(() => TextField(
                  enabled: !dashboard.isLocked.value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 9),
                  decoration: InputDecoration(
                    hintText: "0.0",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 9),
                    suffix: Text(unit, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1)),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  // ========== SHARED HELPERS ==========

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
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black87),
            textAlign: TextAlign.center),
      ),
    );
  }

  Widget _headerCellWithSubheaders(String mainText, List<Widget> subHeaders) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(mainText,
              style: const TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        Row(children: subHeaders),
      ],
    );
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

  Widget _plainText(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 9, color: Colors.black87),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis);
  }

  // ✅ FIXED: isLocked passed as parameter — no Obx needed inside
  Widget _editableText(RxString rxValue, bool isLocked) {
    return Obx(() => TextField(
          enabled: !isLocked,
          controller: TextEditingController(text: rxValue.value)
            ..selection =
                TextSelection.fromPosition(TextPosition(offset: rxValue.value.length)),
          onChanged: (val) => rxValue.value = val,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9),
          decoration: const InputDecoration(
              border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
        ));
  }

  Widget _editableTextWithCallback(
    RxString rxValue, {
    required bool isLocked,
    required Function(String) onChanged,
  }) {
    return Obx(() => TextField(
          enabled: !isLocked,
          controller: TextEditingController(text: rxValue.value)
            ..selection =
                TextSelection.fromPosition(TextPosition(offset: rxValue.value.length)),
          onChanged: (val) {
            rxValue.value = val;
            onChanged(val);
          },
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9),
          decoration: const InputDecoration(
              border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
        ));
  }

  BoxDecoration _boxStyle() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      );
}