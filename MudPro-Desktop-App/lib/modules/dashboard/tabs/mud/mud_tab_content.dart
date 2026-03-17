import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/mud/apply_rheology_page.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/mud/solid_analysis_page.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudView extends StatefulWidget {
  const MudView({super.key});

  @override
  State<MudView> createState() => _MudViewState();
}

class _MudViewState extends State<MudView> {
  late MudController c;
  late DashboardController dashboard;

  final _propertyScrollCtrl = ScrollController();
  final _rheologyScrollCtrl = ScrollController();

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
    if (k.contains('oil') && k.contains('water') && k.contains('ratio')) return true;
    // Total Solids OUTPUT row only — NOT "*Solids (% vol)" retort input (user types it)
    if ((k == 'total solids' || k.contains('total solids')) &&
        !k.contains('corr') && !k.contains('drill')) return true;
    // Corrected Solids
    if (k.contains('corrected solids') || k.contains('corr. solids')) return true;
    // Excess Lime — auto-calc = Whole Mud Alkalinity (POM) × 1.295
    if (k.contains('excess lime')) return true;
    // CaCl2 Concentration (mg/l) — auto-calc = 1.565 × Whole Mud Chlorides
    if (k.contains('cacl2 concentration') || k.contains('cacl2 conc') ||
        (k.startsWith('cacl2') && k.contains('mg'))) return true;
    // CaCl2 (% wt) — auto-calc from Whole Mud Chlorides + Water
    if (k.startsWith('cacl2') && (k.contains('wt') || k.contains('%'))) return true;
    // Water Phase Salinity — cascades from CaCl2 Concentration
    if (k.contains('water phase salinity') || k.contains('water phase sal')) return true;
    // ── WBM-only auto-calc fields ────────────────────────────────────────────
    if (k == 'sand content' || k.contains('sand content')) return true;
    if (k.contains('filtrate alkalinity') && (k.contains('mf') || k.contains('(mf)'))) return true;
    if (k == 'calcium' || (k.startsWith('calcium') && !k.contains('chloride'))) return true;
    if ((k.contains('mud chloride') || k == 'mud chlorides') && !k.contains('whole')) return true;
    if (k == 'kcl' || k.startsWith('kcl')) return true;
    // Whole Mud Alkalinity (POM) — EDITABLE user input, drives Excess Lime
    // Whole Mud Chlorides — EDITABLE user input, drives CaCl2 chain
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmallScreen = constraints.maxWidth < 1024;
      return Column(children: [
        _topControls(),
        Divider(height: 1, color: Colors.grey.shade300),
        Expanded(
          child: isSmallScreen ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ]);
    });
  }

  Widget _buildDesktopLayout() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 550, child: _leftPanel()),
      VerticalDivider(width: 1, color: Colors.grey.shade300),
      Expanded(child: _rightPanel()),
    ]);
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          _leftPanel(),
          const SizedBox(height: 16),
          _rightPanel(),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP CONTROLS
  // ═══════════════════════════════════════════════════════════════════════════
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
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 11)),
        const SizedBox(width: 10),
        Container(
          width: 200,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: c.fluidnameController,
            style: AppTheme.caption
                .copyWith(color: AppTheme.textPrimary, fontSize: 11),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Text('Fluid Type',
            style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 11)),
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
                    DropdownMenuItem(
                        value: 'Water-based',
                        child: Text('Water-based',
                            style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(
                        value: 'Oil-based',
                        child: Text('Oil-based',
                            style: TextStyle(fontSize: 11))),
                    DropdownMenuItem(
                        value: 'Synthetic',
                        child: Text('Synthetic',
                            style: TextStyle(fontSize: 11))),
                  ],
                  onChanged: dashboard.isLocked.value
                      ? null
                      : (v) => c.changeFluidType(v!),
                  style: AppTheme.caption
                      .copyWith(color: AppTheme.textPrimary, fontSize: 11),
                  isDense: true,
                ),
              ),
            )),
        const SizedBox(width: 20),
        Obx(() => Row(children: [
              Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: c.isCompletionFluid.value,
                    onChanged: dashboard.isLocked.value
                        ? null
                        : (v) => c.isCompletionFluid.value = v ?? false,
                    activeColor: AppTheme.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )),
              Text('Completion Fluid',
                  style: AppTheme.caption
                      .copyWith(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
        const SizedBox(width: 12),
        Obx(() => Row(children: [
              Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: c.isWeightedMud.value,
                    onChanged: dashboard.isLocked.value
                        ? null
                        : (v) => c.isWeightedMud.value = v ?? false,
                    activeColor: AppTheme.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )),
              Text('Weighted Mud',
                  style: AppTheme.caption
                      .copyWith(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEFT PANEL
  // ═══════════════════════════════════════════════════════════════════════════
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
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 10),

        // Table
        Expanded(
          child: Obx(() {
            if (c.isLoading.value) {
              return Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryColor, strokeWidth: 2));
            }
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(children: [
                _tableHeader(),
                Expanded(
                  child: Scrollbar(
                    controller: _propertyScrollCtrl,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _propertyScrollCtrl,
                      child: Column(children: [
                        ...c.propertyTable.entries.map((entry) {
                          final name = entry.key;
                          final values = entry.value;
                          final isLast =
                              entry.key == c.propertyTable.keys.last;
                          return _propertyRow(name, values, isLast);
                        }),
                        _DynamicAddRows(c: c),
                      ]),
                    ),
                  ),
                ),
              ]),
            );
          }),
        ),

        const SizedBox(height: 8),

        // Footer
        Row(children: [
          Tooltip(
            message: 'Solid Analysis',
            child: InkWell(
              onTap: () => showDialog(
                context: context,
                builder: (_) => const SolidAnalysisDialog(),
              ),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Icon(Icons.camera_alt_outlined,
                    size: 15, color: AppTheme.primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('*Required',
              style: AppTheme.caption
                  .copyWith(color: Colors.red.shade400, fontSize: 10)),
          const SizedBox(width: 10),
          Text('Sample for Calculation',
              style: AppTheme.caption
                  .copyWith(color: AppTheme.textSecondary, fontSize: 10)),
          const SizedBox(width: 8),
          Obx(() => Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: c.sampleForCalculation.value,
                    items: ['1', '2', '3']
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: const TextStyle(fontSize: 10))))
                        .toList(),
                    onChanged: (v) => c.sampleForCalculation.value = v!,
                    isDense: true,
                    style: AppTheme.caption
                        .copyWith(color: AppTheme.textPrimary, fontSize: 10),
                  ),
                ),
              )),
        ]),
      ]),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4), topRight: Radius.circular(4)),
      ),
      child: Row(children: [
        _headerCell('Property', width: 150),
        ...c.samples.map((s) => Expanded(child: _headerCell(s, center: true))),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPERTY ROW — KEY CHANGE
  // Auto-calc fields → yellow read-only display (like rheology calculated rows)
  // PV / YP and all other fields → editable TextField (unchanged)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _propertyRow(String name, List<RxString> values, bool isLast) {
    final isAutoCalc = _isAutoCalcField(name);

    return Container(
      height: 30,
      decoration: BoxDecoration(
        // Grey tint for auto-calculated rows, white for editable
        color: isAutoCalc ? Colors.grey.shade100 : Colors.white,
        border: Border(
            bottom: BorderSide(
                color: isLast ? Colors.transparent : Colors.grey.shade100)),
      ),
      child: Row(children: [
        // ── Property name column ───────────────────────────────────────────
        Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              border: Border(
                  right: BorderSide(color: Colors.grey.shade200))),
          child: Obx(() {
            final unit = c.propertyUnits[name] ?? '';
            final displayName = unit.isNotEmpty ? '$name ($unit)' : name;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Small indicator icon for calculated fields
                if (isAutoCalc)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(Icons.functions,
                        size: 10, color: Colors.grey.shade500),
                  ),
              ],
            );
          }),
        ),

        // ── Sample value columns ───────────────────────────────────────────
        ...values.asMap().entries.map((cell) {
          final isLastCol = cell.key == values.length - 1;

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          color: isLastCol
                              ? Colors.transparent
                              : Colors.grey.shade200))),
              child: isAutoCalc
                  // ── READ-ONLY: auto-calculated value ──────────────────
                  ? Obx(() => Center(
                        child: Text(
                          cell.value.value.isEmpty ? '-' : cell.value.value,
                          style: AppTheme.caption.copyWith(
                            color: cell.value.value.isEmpty
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ))
                  // ── EDITABLE: normal TextField ─────────────────────────
                  : Obx(() => TextField(
                        key: ValueKey('${name}_${cell.key}'),
                        controller: TextEditingController(
                            text: cell.value.value)
                          ..selection = TextSelection.collapsed(
                              offset: cell.value.value.length),
                        onChanged: (v) => cell.value.value = v,
                        style: AppTheme.caption.copyWith(
                            color: AppTheme.textPrimary, fontSize: 10),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                        ),
                        textAlign: TextAlign.center,
                      )),
            ),
          );
        }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIGHT PANEL — unchanged from original
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _rightPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Rheology model selector
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
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 11)),
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
                        DropdownMenuItem(
                            value: 'Bingham',
                            child: Text('Bingham',
                                style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(
                            value: 'Power Law',
                            child: Text('Power Law',
                                style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(
                            value: 'HB',
                            child:
                                Text('HB', style: TextStyle(fontSize: 11))),
                      ],
                      onChanged: dashboard.isLocked.value
                          ? null
                          : (v) => c.changeModel(v!),
                      style: AppTheme.caption
                          .copyWith(color: AppTheme.textPrimary, fontSize: 11),
                      isDense: true,
                    ),
                  ),
                )),
          ]),
        ),
        const SizedBox(height: 10),

        // Rheology table — COMPLETELY UNCHANGED from original
        Expanded(
          flex: 3,
          child: Obx(() => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(children: [
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border:
                          Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4)),
                    ),
                    child: Row(children: [
                      _headerCell('RPM', width: 120),
                      ...c.samples
                          .map((s) => Expanded(child: _headerCell(s, center: true))),
                    ]),
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
                              height: 30,
                              decoration: BoxDecoration(
                                color: isCalc
                                    ? const Color(0xFFFFFDE7)
                                    : Colors.white,
                                border: Border(
                                    bottom: BorderSide(
                                        color: isLast
                                            ? Colors.transparent
                                            : Colors.grey.shade100)),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 120,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          right: BorderSide(
                                              color: Colors.grey.shade200))),
                                  child: Text(entry.key,
                                      style: AppTheme.caption.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 10),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                ...entry.value.asMap().entries.map((cell) {
                                  final isLastCol =
                                      cell.key == entry.value.length - 1;
                                  return Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      decoration: BoxDecoration(
                                          border: Border(
                                              right: BorderSide(
                                                  color: isLastCol
                                                      ? Colors.transparent
                                                      : Colors.grey.shade200))),
                                      child: isCalc
                                          ? Obx(() => Center(
                                                child: Text(
                                                  cell.value.value.isEmpty
                                                      ? '-'
                                                      : cell.value.value,
                                                  style: AppTheme.caption.copyWith(
                                                      color: cell.value.value
                                                              .isEmpty
                                                          ? Colors.grey.shade400
                                                          : AppTheme.textPrimary,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ))
                                          : Obx(() => TextField(
                                                key: ValueKey(
                                                    'rheo_${entry.key}_${cell.key}'),
                                                controller:
                                                    TextEditingController(
                                                        text: cell.value.value)
                                                      ..selection = TextSelection
                                                          .collapsed(
                                                              offset: cell
                                                                  .value
                                                                  .value
                                                                  .length),
                                                onChanged: (v) =>
                                                    cell.value.value = v,
                                                style: AppTheme.caption.copyWith(
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 10),
                                                decoration:
                                                    const InputDecoration(
                                                  isDense: true,
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                          vertical: 6),
                                                ),
                                                textAlign: TextAlign.center,
                                                keyboardType:
                                                    TextInputType.number,
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
                  ),
                ]),
              )),
        ),

        const SizedBox(height: 10),

        // Radio + action buttons — unchanged
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            Obx(() => Row(children: [
                  Transform.scale(
                      scale: 0.8,
                      child: Radio<String>(
                        value: 'API (RP 13D)',
                        groupValue: c.rheologyCalculation.value,
                        onChanged: dashboard.isLocked.value
                            ? null
                            : (v) => c.rheologyCalculation.value = v!,
                        activeColor: AppTheme.primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                  Text('API (RP 13D)',
                      style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ])),
            const SizedBox(width: 16),
            Obx(() => Row(children: [
                  Transform.scale(
                      scale: 0.8,
                      child: Radio<String>(
                        value: 'Use All Readings',
                        groupValue: c.rheologyCalculation.value,
                        onChanged: dashboard.isLocked.value
                            ? null
                            : (v) => c.rheologyCalculation.value = v!,
                        activeColor: AppTheme.primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                  Text('Use All Readings',
                      style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ])),
            const Spacer(),
            _iconBtn(
              icon: Icons.calculate_outlined,
              color: AppTheme.primaryColor,
              tooltip: 'Calculate',
              onTap: () => c.calculateRheology(),
            ),
            const SizedBox(width: 6),
            _iconBtn(
              icon: Icons.show_chart,
              color: Colors.orange,
              tooltip: 'Apply Rheology to Samples',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ApplyRheologyPage())),
            ),
            const SizedBox(width: 6),
            _iconBtn(
              icon: Icons.arrow_back,
              color: Colors.green,
              tooltip: 'Transfer Rheology to Property Table',
              onTap: () => c.transferRheologyToPropertyTable(),
            ),
          ]),
        ),

        const SizedBox(height: 10),

        // Bottom small tables — unchanged
        Expanded(
          flex: 2,
          child: Row(children: [
            Expanded(
                child: _smallTable('Specific Gravity', isSpecificGravity: true)),
            const SizedBox(width: 10),
            Expanded(child: _smallTable('Solids', isSolids: true)),
          ]),
        ),
      ]),
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
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SMALL TABLES — unchanged
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _smallTable(String title,
      {bool isSpecificGravity = false, bool isSolids = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border:
                    Border(bottom: BorderSide(color: Colors.grey.shade300)),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4)),
              ),
              child: Text(title,
                  style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 10)),
            ),
            if (isSpecificGravity) ...[
              _sgRow('Oil (SG)', c.oilSgController),
              _sgRow('HGS (SG)', c.hgsSgController),
              _sgRow('LGS (SG)', c.lgsSgController),
            ] else if (isSolids) ...[
              _sgRow('Shale CEC (meq/100g)', c.shaleCecController),
              _sgRow('Bent CEC (meq/100g)', c.bentCecController),
            ],
          ]),
    );
  }

  Widget _sgRow(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: AppTheme.caption
                    .copyWith(color: AppTheme.textSecondary, fontSize: 10))),
        Obx(() {
          if (dashboard.isLocked.value) {
            return Text(controller.text.isEmpty ? '-' : controller.text,
                style: AppTheme.caption
                    .copyWith(color: AppTheme.textPrimary, fontSize: 10));
          }
          return Container(
            width: 70,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              ),
              style: AppTheme.caption
                  .copyWith(color: AppTheme.textPrimary, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          );
        }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _headerCell(String text, {double? width, bool center = false}) {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade200))),
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(text,
            style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 10),
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
        decoration: BoxDecoration(
            border:
                Border(right: BorderSide(color: Colors.grey.shade300))),
        child: Text(text,
            style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 10),
            overflow: TextOverflow.ellipsis),
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
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
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
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
              items: widget.allOptions
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p,
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _value = null);
                widget.onPicked(v);
              },
              isDense: true,
              icon: Icon(Icons.arrow_drop_down,
                  size: 14, color: Colors.grey.shade400),
              style:
                  TextStyle(color: AppTheme.textPrimary, fontSize: 10),
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
                          color: isLast
                              ? Colors.transparent
                              : Colors.grey.shade200))),
            ),
          );
        }),
      ]),
    );
  }
}