import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/mud/apply_rheology_page.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class IntervalMudPlanTab extends StatefulWidget {
  const IntervalMudPlanTab({super.key});

  @override
  State<IntervalMudPlanTab> createState() => _IntervalMudPlanTabState();
}

class _IntervalMudPlanTabState extends State<IntervalMudPlanTab> {
  late MudController c;
  late DashboardController dashboard;

  final _propertyScrollCtrl = ScrollController();
  final _rheologyScrollCtrl = ScrollController();

  // Only show Plan-L (index 3) and Plan-H (index 4) columns
  static const _planSamples = ['Plan-L', 'Plan-H'];
  static const _planIndices = [3, 4];

  @override
  void initState() {
    super.initState();
    c = Get.put(MudController());
    dashboard = Get.find<DashboardController>();
  }

  @override
  void dispose() {
    _propertyScrollCtrl.dispose();
    _rheologyScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _topControls(),
      Divider(height: 1, color: Colors.grey.shade300),
      Expanded(
        child: _buildDesktopLayout(),
      ),
    ]);
  }

  Widget _buildDesktopLayout() {
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: 380, child: _leftPanel()),
      VerticalDivider(width: 1, color: Colors.grey.shade300),
      Expanded(child: _rightPanel()),
    ]);
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          SizedBox(height: 500, child: _leftPanel()),
          const SizedBox(height: 16),
          SizedBox(height: 450, child: _rightPanel()),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TOP CONTROLS
  // ═══════════════════════════════════════════════════════════
  Widget _topControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(children: [
        Text('Fluid Name',
            style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 11)),
        const SizedBox(width: 10),
        Container(
          width: 200, height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: c.fluidnameController,
            style: AppTheme.caption.copyWith(color: AppTheme.textPrimary, fontSize: 11),
            decoration: const InputDecoration(
              isDense: true, border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Text('Fluid Type',
            style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 11)),
        const SizedBox(width: 10),
        Obx(() => Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: c.selectedFluidType.value,
                  items: const [
                    DropdownMenuItem(value: 'Water-based', child: Text('Water-based', style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(value: 'Oil-based',   child: Text('Oil-based',   style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(value: 'Synthetic',   child: Text('Synthetic',   style: TextStyle(fontSize: 11))),
                  ],
                  onChanged: dashboard.isLocked.value ? null : (v) => c.changeFluidType(v!),
                  style: AppTheme.caption.copyWith(color: AppTheme.textPrimary, fontSize: 11),
                  isDense: true,
                ),
              ),
            )),
        const SizedBox(width: 20),
        Obx(() => Row(children: [
              Transform.scale(scale: 0.8,
                child: Checkbox(
                  value: c.isCompletionFluid.value,
                  onChanged: dashboard.isLocked.value ? null : (v) => c.isCompletionFluid.value = v ?? false,
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )),
              Text('Completion Fluid',
                  style: AppTheme.caption.copyWith(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
        const SizedBox(width: 12),
        Obx(() => Row(children: [
              Transform.scale(scale: 0.8,
                child: Checkbox(
                  value: c.isWeightedMud.value,
                  onChanged: dashboard.isLocked.value ? null : (v) => c.isWeightedMud.value = v ?? false,
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )),
              Text('Weighted Mud',
                  style: AppTheme.caption.copyWith(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LEFT PANEL
  // ═══════════════════════════════════════════════════════════
  Widget _leftPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            const Icon(Icons.science, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text('Mud Properties',
                style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600, color: Colors.white, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 10),

        // Table
        Expanded(
          child: Obx(() {
            if (c.isLoading.value) {
              return Center(child: CircularProgressIndicator(
                  color: AppTheme.primaryColor, strokeWidth: 2));
            }
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(children: [
                // Header row
                _tableHeader(),
                // Data rows + add row
                Expanded(
                  child: SingleChildScrollView(
                    controller: _propertyScrollCtrl,
                      child: Column(children: [
                        // Existing rows from propertyTable map
                        ...c.propertyTable.entries.map((entry) {
                          final name   = entry.key;
                          final values = entry.value;
                          final isLast = entry.key == c.propertyTable.keys.last;
                          return _propertyRow(name, values, isLast);
                        }),
                        // Dynamic add-property row (dropdown)
                        _DynamicAddRows(c: c),
                      ]),
                  ),
                ),
              ]),
            );
          }),
        ),

      
      ]),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4), topRight: Radius.circular(4)),
      ),
      child: Row(children: [
        _headerCell('Property', width: 130),
        ..._planSamples.map((s) => Expanded(child: _headerCell(s, center: true))),
      ]),
    );
  }

  Widget _propertyRow(String name, List<RxString> values, bool isLast) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: isLast ? Colors.transparent : Colors.grey.shade100)),
      ),
      child: Row(children: [
        // Property name
        Container(
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade200))),
          child: Text(name,
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary, fontSize: 9),
              overflow: TextOverflow.ellipsis),
        ),
        // Only Plan-L and Plan-H cells
        ..._planIndices.asMap().entries.map((e) {
          final colIdx = e.key;
          final dataIdx = e.value;
          final isLastCol = colIdx == _planIndices.length - 1;
          final cell = values[dataIdx];
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(
                  color: isLastCol ? Colors.transparent : Colors.grey.shade200))),
              child: Obx(() => TextField(
                    key: ValueKey('${name}_$dataIdx'),
                    controller: TextEditingController(text: cell.value)
                      ..selection = TextSelection.collapsed(
                          offset: cell.value.length),
                    onChanged: (v) => cell.value = v,
                    style: AppTheme.caption.copyWith(color: AppTheme.textPrimary, fontSize: 9),
                    decoration: const InputDecoration(
                      isDense: true, border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    ),
                    textAlign: TextAlign.center,
                  )),
            ),
          );
        }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RIGHT PANEL
  // ═══════════════════════════════════════════════════════════
  Widget _rightPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Rheology model row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            Text('Rheology Model',
                style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 11)),
            const SizedBox(width: 10),
            Obx(() => Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: c.rheologyModel.value,
                      items: const [
                        DropdownMenuItem(value: 'Bingham',   child: Text('Bingham',   style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'Power Law', child: Text('Power Law', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'HB',        child: Text('HB',        style: TextStyle(fontSize: 11))),
                      ],
                      onChanged: dashboard.isLocked.value ? null : (v) => c.changeModel(v!),
                      style: AppTheme.caption.copyWith(color: AppTheme.textPrimary, fontSize: 11),
                      isDense: true,
                    ),
                  ),
                )),
          ]),
        ),
        const SizedBox(height: 10),

        // Rheology table
        Expanded(
          flex: 3,
          child: Obx(() => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(children: [
                  // Header
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                    child: Row(children: [
                      _headerCell('RPM', width: 110),
                      ..._planSamples.map((s) => Expanded(child: _headerCell(s, center: true))),
                    ]),
                  ),
                  // Rows — only Plan-L and Plan-H columns
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _rheologyScrollCtrl,
                      child: Column(
                        children: c.rheologyTable.entries.map((entry) {
                          final isCalc = double.tryParse(entry.key) == null;
                          final isLast = entry.key == c.rheologyTable.keys.last;
                          return Container(
                            height: 26,
                            decoration: BoxDecoration(
                              color: isCalc ? const Color(0xFFFFFDE7) : Colors.white,
                              border: Border(bottom: BorderSide(
                                color: isLast ? Colors.transparent : Colors.grey.shade100)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 110,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.grey.shade200))),
                                child: Text(entry.key,
                                    style: AppTheme.caption.copyWith(
                                        color: AppTheme.textSecondary, fontSize: 9),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              // Only Plan-L (index 3) and Plan-H (index 4)
                              ..._planIndices.asMap().entries.map((e) {
                                final colIdx = e.key;
                                final dataIdx = e.value;
                                final isLastCol = colIdx == _planIndices.length - 1;
                                final cell = entry.value[dataIdx];
                                return Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      border: Border(right: BorderSide(
                                        color: isLastCol ? Colors.transparent : Colors.grey.shade200))),
                                    child: isCalc
                                        ? Obx(() => Center(
                                              child: Text(
                                                cell.value.isEmpty ? '-' : cell.value,
                                                style: AppTheme.caption.copyWith(
                                                    color: cell.value.isEmpty
                                                        ? Colors.grey.shade400
                                                        : AppTheme.textPrimary,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600),
                                                textAlign: TextAlign.center,
                                              ),
                                            ))
                                        : Obx(() => TextField(
                                              key: ValueKey('rheo_${entry.key}_$dataIdx'),
                                              controller: TextEditingController(
                                                  text: cell.value)
                                                ..selection = TextSelection.collapsed(
                                                    offset: cell.value.length),
                                              onChanged: (v) => cell.value = v,
                                              style: AppTheme.caption.copyWith(
                                                  color: AppTheme.textPrimary, fontSize: 9),
                                              decoration: const InputDecoration(
                                                isDense: true, border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 4, vertical: 5),
                                              ),
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                            )),
                                  ),
                                );
                              }),
                            ]),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ]),
              )),
        ),

       
      ]),
    );
  }

 

  Widget _sgRow(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(children: [
        Expanded(child: Text(label,
            style: AppTheme.caption.copyWith(color: AppTheme.textSecondary, fontSize: 10))),
        Obx(() {
          if (dashboard.isLocked.value) {
            return Text(controller.text.isEmpty ? '-' : controller.text,
                style: AppTheme.caption.copyWith(color: AppTheme.textPrimary, fontSize: 10));
          }
          return Container(
            width: 70, height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                isDense: true, border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              ),
              style: AppTheme.caption.copyWith(color: AppTheme.textPrimary, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          );
        }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  Widget _headerCell(String text, {double? width, bool center = false}) {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(text,
            style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 10),
            overflow: TextOverflow.ellipsis),
      ),
    );
    if (width != null) return SizedBox(width: width, child: child);
    return child;
  }

  Widget _snapHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
        child: Text(text,
            style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 10),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DYNAMIC ADD ROW
// - Single dropdown row always visible at bottom of table
// - Select karo → propertyTable mein add, dropdown reset to null (ready for next)
// - All items always shown in dropdown (no filtering of selected ones)
// - Auto next row on every select
// ═══════════════════════════════════════════════════════════════════
class _DynamicAddRows extends StatefulWidget {
  final MudController c;
  const _DynamicAddRows({required this.c});

  @override
  State<_DynamicAddRows> createState() => _DynamicAddRowsState();
}

class _DynamicAddRowsState extends State<_DynamicAddRows> {
  // Single null value — always shows empty dropdown
  // No slot tracking needed — propertyTable handles which items are added
  String? _currentPick;

  void _onPicked(String? value) {
    if (value == null) return;
    // Add to property table only if not already there
    widget.c.addPropertyRow(value);
    // Reset dropdown to null — ready for next pick
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
  String? _value; // always null after each pick (reset)

  @override
  void didUpdateWidget(_SingleDropdownRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset on widget update (after parent setState resets _currentPick)
    _value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
        // Property column — dropdown
        Container(
          width: 150,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade200))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _value,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  Icon(Icons.add, size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('Add property',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
              items: widget.allOptions.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p,
                        style: TextStyle(fontSize: 10, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  )).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _value = null); // reset immediately
                widget.onPicked(v);
              },
              isDense: true,
              icon: Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade400),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 10),
            ),
          ),
        ),
        // Sample columns — empty cells matching table row style
        ...widget.samples.asMap().entries.map((e) {
          final isLast = e.key == widget.samples.length - 1;
          return Expanded(
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(
                  color: isLast ? Colors.transparent : Colors.grey.shade200))),
            ),
          );
        }),
      ]),
    );
  }
}