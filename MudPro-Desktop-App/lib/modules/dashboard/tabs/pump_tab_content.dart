import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/pump_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/sce_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PumpPage extends StatelessWidget {
  PumpPage({super.key});

  final PumpController pumpController = Get.put(PumpController());
  final SceController sceController = Get.put(SceController());
  final DashboardController dashboard = Get.find<DashboardController>();

  // Scroll controllers for tables
  final ScrollController shakerScrollController = ScrollController();
  final ScrollController sceScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Pump and Summary Row - Reduced flex
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
            
            // Shaker Table - Increased flex
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

            // Other SCE Table - Increased flex
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
      constraints: const BoxConstraints(maxWidth: 950), // Limit table width
      decoration: _boxStyle(),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 12),
                SizedBox(width: 6),
                Text(
                  "Pump",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Column Headers with Vertical Dividers - Increased widths
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
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
          
          // Scrollable Data Rows
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: pumpController.pumps.length,
                itemBuilder: (context, index) {
                  final pump = pumpController.pumps[index];
                  final isLast = index == pumpController.pumps.length - 1;
                  
                  return Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          _dataCell(
                            child: Obx(() => _buildPumpDropdown(
                              value: pump.model.value,
                              rowIndex: index,
                              onChanged: (val) {
                                pump.model.value = val ?? '';
                                if (isLast && val != null && val.isNotEmpty) {
                                  pumpController.pumps.add(pump
                                    ..model.value = ''
                                    ..type.value = '');
                                }
                              },
                            )),
                            width: 110,
                          ),
                          _verticalDivider(),
                          _dataCell(child: Obx(() => _plainText(pump.type.value)), width: 95),
                          _verticalDivider(),
                          _dataCell(child: Obx(() => _editableText(pump.linerId)), width: 80),
                          _verticalDivider(),
                          _dataCell(child: Obx(() => _editableText(pump.rodOd)), width: 80),
                          _verticalDivider(),
                          _dataCell(child: Obx(() => _editableText(pump.strokeLength)), width: 95),
                          _verticalDivider(),
                          _dataCell(child: Obx(() => _editableText(pump.efficiency)), width: 90),
                          _verticalDivider(),
                          _dataCell(child: Obx(() => _editableText(pump.displacement)), width: 95),
                          _verticalDivider(),
                          _dataCell(child: Obx(() => _plainText(pump.spm.value)), width: 95),
                          _verticalDivider(),
                          _dataCell(child: Obx(() => _editableText(pump.rate)), width: 80),
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

  // ========== OTHER SCE TABLE ==========
  Widget _otherSCETable() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 580), // Increased slightly
      decoration: _boxStyle(),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.build, color: Colors.white, size: 12),
                SizedBox(width: 6),
                Text(
                  "Other SCE",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Column Headers - Increased widths
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
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
          
          // Scrollable Data Rows
          Expanded(
            child: Obx(() {
              return Scrollbar(
                controller: sceScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: sceScrollController,
                  itemCount: sceController.otherSce.length,
                  itemBuilder: (context, index) {
                    final sce = sceController.otherSce[index];
                    final isLast = index == sceController.otherSce.length - 1;
                    final hasSce = sce.type.value.isNotEmpty;
                    
                    return Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _dataCell(
                              child: Obx(() => _buildSceDropdown(
                                value: sce.type.value,
                                rowIndex: index,
                                onChanged: (val) {
                                  sce.type.value = val ?? '';
                                  if (isLast && val != null && val.isNotEmpty) {
                                    sceController.otherSce.add(sce.clone()
                                      ..type.value = ''
                                      ..model1.value = '');
                                  }
                                },
                              )),
                              width: 90,
                            ),
                            _verticalDivider(),
                            _dataCell(
                              child: Obx(() => _editableText(sce.model1)),
                              width: 110,
                            ),
                            _verticalDivider(),
                            _dataCell(
                              child: Obx(() => _editableText(sce.uf)),
                              width: 70,
                            ),
                            _verticalDivider(),
                            _dataCell(
                              child: Obx(() => _editableText(sce.of)),
                              width: 70,
                            ),
                            _verticalDivider(),
                            _dataCell(
                              child: Obx(() => _editableText(sce.time)),
                              width: 70,
                            ),
                            _verticalDivider(),
                            _dataCell(
                              child: Obx(() => _editableText(sce.oocWt)),
                              width: 75,
                            ),
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

  Widget _buildPumpDropdown({
    required String value,
    required Function(String?) onChanged,
    required int rowIndex,
  }) {
    return Obx(() {
      final availableModels = pumpController.availablePumpModels;
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: const Text("Select", style: TextStyle(fontSize: 9, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: dashboard.isLocked.value ? null : (selectedModel) async {
            if (selectedModel != null) {
              final pumpData = await pumpController.getPumpDataByModel(selectedModel);
              if (pumpData != null && rowIndex < pumpController.pumps.length) {
                final pump = pumpController.pumps[rowIndex];
                pump.model.value = selectedModel;
                pump.type.value = pumpData['type']?.toString() ?? '';
                pump.linerId.value = pumpData['linerId']?.toString() ?? '';
                pump.rodOd.value = pumpData['rodOd']?.toString() ?? '';
                pump.strokeLength.value = pumpData['strokeLength']?.toString() ?? '';
                pump.efficiency.value = pumpData['efficiency']?.toString() ?? '';
                pump.displacement.value = pumpData['displacement']?.toString() ?? '';
              }
            }
            onChanged(selectedModel);
          },
          items: availableModels.map((model) => DropdownMenuItem(
            value: model,
            child: Text(model, style: const TextStyle(fontSize: 9)),
          )).toList(),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.filter_alt, color: Colors.white, size: 12),
                SizedBox(width: 6),
                Text(
                  "Shaker",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Column Headers - Increased widths
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
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
          
          // Scrollable Data Rows
          Expanded(
            child: Obx(() {
              return Scrollbar(
                controller: shakerScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: shakerScrollController,
                  itemCount: sceController.shakers.length,
                  itemBuilder: (context, index) {
                  final shaker = sceController.shakers[index];
                  final isLast = index == sceController.shakers.length - 1;
                  final hasShaker = shaker.shaker.value.isNotEmpty;
                  
                  return Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          _dataCell(
                            child: Obx(() => _buildShakerDropdown(
                              value: shaker.shaker.value,
                              rowIndex: index,
                              onChanged: (val) {
                                shaker.shaker.value = val ?? '';
                                if (isLast && val != null && val.isNotEmpty) {
                                  sceController.shakers.add(shaker.clone()
                                    ..shaker.value = ''
                                    ..model.value = '');
                                }
                              },
                            )),
                            width: 100,
                          ),
                          _verticalDivider(),
                          _dataCell(
                            child: Obx(() => _editableText(shaker.model)),
                            width: 120,
                          ),
                          _verticalDivider(),
                          _dataCell(
                            child: Obx(() => _editableText(shaker.screen1)),
                            width: 55,
                          ),
                          _verticalDivider(),
                          _dataCell(
                            child: Obx(() => _editableText(shaker.screen2)),
                            width: 55,
                          ),
                          _verticalDivider(),
                          _dataCell(
                            child: Obx(() => _editableText(shaker.screen3)),
                            width: 55,
                          ),
                          _verticalDivider(),
                          _dataCell(
                            child: Obx(() => _editableText(shaker.screen4)),
                            width: 55,
                          ),
                          _verticalDivider(),
                          _dataCell(
                            child: Obx(() => _editableText(shaker.time)),
                            width: 70,
                          ),
                          _verticalDivider(),
                          _dataCell(
                            child: Obx(() => _editableText(shaker.oocWt)),
                            width: 75,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShakerDropdown({
    required String value,
    required int rowIndex,
    required Function(String?) onChanged,
  }) {
    return Obx(() {
      final availableTypes = sceController.availableShakerTypes.isNotEmpty
          ? sceController.availableShakerTypes
          : ['Shaker', 'Cleaner', 'Degasser'];
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: const Text("Select", style: TextStyle(fontSize: 9, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: dashboard.isLocked.value ? null : (selectedType) async {
            if (selectedType != null) {
              // Fetch data from API for this shaker type
              final shakerData = await sceController.getShakerDataByType(selectedType);
              if (shakerData != null && rowIndex < sceController.shakers.length) {
                final shaker = sceController.shakers[rowIndex];
                shaker.shaker.value = selectedType;
                // Populate model from API response
                shaker.model.value = shakerData['model']?.toString() ?? '';
                // Populate screens from API response
                shaker.screens.value = shakerData['screens']?.toString() ?? '';
                // Populate any other fields available in the API response
                if (shakerData.containsKey('plot')) {
                  // Handle plot field if needed in your model
                }
              } else {
                // If no data found in API, just set the type
                if (rowIndex < sceController.shakers.length) {
                  sceController.shakers[rowIndex].shaker.value = selectedType;
                }
              }
            }
            onChanged(selectedType);
          },
          items: availableTypes.map((type) => DropdownMenuItem(
            value: type,
            child: Text(type, style: const TextStyle(fontSize: 9)),
          )).toList(),
        ),
      );
    });
  }



  Widget _buildSceDropdown({
    required String value,
    required int rowIndex,
    required Function(String?) onChanged,
  }) {
    return Obx(() {
      final availableTypes = sceController.availableOtherSceTypes.isNotEmpty
          ? sceController.availableOtherSceTypes
          : ['Degasser', 'Desander', 'Desilter', 'Centrifuge'];
      return DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: const Text("Select", style: TextStyle(fontSize: 9, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 9, color: Colors.black87),
          onChanged: dashboard.isLocked.value ? null : (selectedType) async {
            if (selectedType != null) {
              // Fetch data from API for this SCE type
              final sceData = await sceController.getOtherSceDataByType(selectedType);
              if (sceData != null && rowIndex < sceController.otherSce.length) {
                final sce = sceController.otherSce[rowIndex];
                sce.type.value = selectedType;
                // Populate model1 from API response
                sce.model1.value = sceData['model1']?.toString() ?? '';
                // Populate model2 if available
                if (sceData.containsKey('model2')) {
                  // Handle model2 field if it exists in your model
                }
                // Populate model3 if available
                if (sceData.containsKey('model3')) {
                  // Handle model3 field if it exists in your model
                }
                // Populate plot field if needed
                if (sceData.containsKey('plot')) {
                  // Handle plot field if needed in your model
                }
              } else {
                // If no data found in API, just set the type
                if (rowIndex < sceController.otherSce.length) {
                  sceController.otherSce[rowIndex].type.value = selectedType;
                }
              }
            }
            onChanged(selectedType);
          },
          items: availableTypes.map((type) => DropdownMenuItem(
            value: type,
            child: Text(type, style: const TextStyle(fontSize: 9)),
          )).toList(),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.summarize, color: Colors.white, size: 12),
                SizedBox(width: 6),
                Text(
                  "Summary",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable Content
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
            child: Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.black87),
            ),
          ),
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
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  // ========== HELPER WIDGETS ==========
  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _headerCellWithSubheaders(String mainText, List<Widget> subHeaders) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            mainText,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Row(children: subHeaders),
      ],
    );
  }

  Widget _subHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontSize: 7, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      color: Colors.grey.shade300,
    );
  }

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
    return Text(
      text,
      style: const TextStyle(fontSize: 9, color: Colors.black87),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _editableText(RxString rxValue) {
    return TextField(
      enabled: !dashboard.isLocked.value,
      controller: TextEditingController(text: rxValue.value)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: rxValue.value.length),
        ),
      onChanged: (val) => rxValue.value = val,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 9),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }

  Widget _editableTextPlain() {
    return TextField(
      enabled: !dashboard.isLocked.value,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 9),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }

  BoxDecoration _boxStyle() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      );
}