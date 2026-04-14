import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';

enum PopupUnitSystem { us, si }

// ═══════════════════════════════════════════════════════════════════════════════
// POPUP-SCOPED CONTROLLER  (unchanged logic, just referenced cleanly)
// ═══════════════════════════════════════════════════════════════════════════════
class UnitCustomizationController extends GetxController {
  final selectedRadio     = PopupUnitSystem.us.obs;
  final selectedLeftIndex = 0.obs;
  final isInserting       = false.obs;
  final isDeleting        = false.obs;
  final isSaving          = false.obs;

  final OptionsController mainCtrl;
  UnitCustomizationController(this.mainCtrl);

  @override
  void onInit() {
    super.onInit();
    // Ensure we have a system selected if possible
    if (mainCtrl.selectedCustomSystemId.value.isEmpty && mainCtrl.unitSystems.isNotEmpty) {
      mainCtrl.selectUnitSystem(mainCtrl.unitSystems.first);
    }
    final idx = mainCtrl.selectedSystemIndex;
    selectedLeftIndex.value = idx >= 0 ? idx : 0;
  }

  void selectSystem(int index) {
    selectedLeftIndex.value = index;
    if (index < mainCtrl.unitSystems.length) {
      mainCtrl.selectUnitSystem(mainCtrl.unitSystems[index]);
      selectedRadio.value = mainCtrl.unitSystems[index].baseTemplate == 'si'
          ? PopupUnitSystem.si
          : PopupUnitSystem.us;
    }
  }

  Future<void> insertBefore() async {
    final name = await _askName();
    if (name == null) return;
    isInserting.value = true;
    final tpl = selectedRadio.value == PopupUnitSystem.si ? 'si' : 'us';
    final created = await mainCtrl.createNewUnitSystem(name: name, baseTemplate: tpl);
    isInserting.value = false;
    if (created != null) {
      selectedLeftIndex.value = mainCtrl.unitSystems.length - 1;
      mainCtrl.selectUnitSystem(created);
    }
  }

  Future<void> insertAfter() async {
    final name = await _askName();
    if (name == null) return;
    isInserting.value = true;
    final tpl = selectedRadio.value == PopupUnitSystem.si ? 'si' : 'us';
    final created = await mainCtrl.createNewUnitSystem(name: name, baseTemplate: tpl);
    isInserting.value = false;
    if (created != null) {
      selectedLeftIndex.value = mainCtrl.unitSystems.length - 1;
      mainCtrl.selectUnitSystem(created);
    }
  }

  Future<void> deleteSelected(BuildContext context) async {
    if (mainCtrl.unitSystems.isEmpty) return;
    final system = mainCtrl.unitSystems[selectedLeftIndex.value];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Unit System', style: TextStyle(fontSize: 14)),
        content: Text('Delete "${system.name}"? This cannot be undone.',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    isDeleting.value = true;
    await mainCtrl.deleteUnitSystem(system.id);
    isDeleting.value = false;
    if (selectedLeftIndex.value >= mainCtrl.unitSystems.length) {
      selectedLeftIndex.value =
          mainCtrl.unitSystems.isEmpty ? 0 : mainCtrl.unitSystems.length - 1;
    }
    if (mainCtrl.unitSystems.isNotEmpty) {
      mainCtrl.selectUnitSystem(mainCtrl.unitSystems[selectedLeftIndex.value]);
    }
  }

  Future<void> seedDefaults() async {
    isInserting.value = true;
    await mainCtrl.seedDefaults();
    isInserting.value = false;
    if (mainCtrl.unitSystems.isNotEmpty) {
      selectedLeftIndex.value = 0;
      mainCtrl.selectUnitSystem(mainCtrl.unitSystems.first);
    }
  }

  Future<void> saveChanges(BuildContext context) async {
    final systemId = mainCtrl.selectedCustomSystemId.value;
    if (systemId.isEmpty) return;
    isSaving.value = true;
    final ok = await mainCtrl.saveAllChanges(systemId);
    isSaving.value = false;
    if (ok && context.mounted) Navigator.of(context).pop();
  }

  Future<String?> _askName() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: Get.context!,
      builder: (_) => AlertDialog(
        title: const Text('New Unit System', style: TextStyle(fontSize: 14)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'System name',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(Get.context!),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) Navigator.pop(Get.context!, name);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// POPUP  —  StatefulWidget so ScrollControllers are properly owned
// ═══════════════════════════════════════════════════════════════════════════════
class UnitSystemCustomizationPopup extends StatefulWidget {
  const UnitSystemCustomizationPopup({super.key});

  @override
  State<UnitSystemCustomizationPopup> createState() =>
      _UnitSystemCustomizationPopupState();
}

class _UnitSystemCustomizationPopupState
    extends State<UnitSystemCustomizationPopup> {
  // Controllers owned by this State — guaranteed alive for the widget's lifetime
  late final OptionsController mainController;
  late final UnitCustomizationController controller;

  // FIX: ScrollControllers declared here so Scrollbar always has an attached position
  final ScrollController _leftScroll  = ScrollController();
  final ScrollController _rightScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    mainController = Get.isRegistered<OptionsController>() 
        ? Get.find<OptionsController>() 
        : Get.put(OptionsController());
    controller = Get.put(
      UnitCustomizationController(mainController),
      tag: 'unit_popup',
    );
  }

  @override
  void dispose() {
    _leftScroll.dispose();
    _rightScroll.dispose();
    // Remove scoped controller when popup closes
    if (Get.isRegistered<UnitCustomizationController>(tag: 'unit_popup')) {
      Get.delete<UnitCustomizationController>(tag: 'unit_popup');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100, maxHeight: 700, minWidth: 800, minHeight: 500,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: [
              _header(),
              _radioRow(),
              Divider(height: 1, color: Colors.grey.shade300),
              // FIX: Expanded must wrap the row/body so Column child has bounded height
              Expanded(child: _body()),
              _footer(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    return Row(children: [
      // ─── Left Panel: List of Systems ──────────────────────────────────
      Expanded(
        flex: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Column(
            children: [
              _leftPanelHeader(),
              Expanded(
                child: Obx(() {
                  if (mainController.unitSystems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No unit systems',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: controller.seedDefaults,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Seed Defaults',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }
                  return Container(
                    color: AppTheme.backgroundColor,
                    child: Scrollbar(
                      controller: _leftScroll,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _leftScroll,
                        padding: const EdgeInsets.all(8),
                        itemCount: mainController.unitSystems.length,
                        itemBuilder: (_, index) {
                          final system = mainController.unitSystems[index];
                          return Obx(() => _buildSystemTile(system, index));
                        },
                      ),
                    ),
                  );
                }),
              ),
              _leftPanelFooter(),
            ],
          ),
        ),
      ),

      // ─── Right Panel: Parameters of selected system ─────────────────
      Expanded(
        flex: 3,
        child: Obx(() {
          final hasSelection = mainController.selectedCustomSystemId.value.isNotEmpty;
          if (!hasSelection) {
            return const Center(
              child: Text(
                'Please select or create a unit system\nto begin customization',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            );
          }
          return Column(
            children: [
              _rightPanelHeader(),
              Expanded(child: _parameterTable()),
            ],
          );
        }),
      ),
    ]);
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
          child: const Icon(Icons.tune, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Text('Unit System Customization',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2)),
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }

  Widget _radioRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardColor,
      child: Obx(() {
        final selected = controller.selectedRadio.value;
        return Wrap(
          spacing: 20, runSpacing: 8,
          children: [
            _radioBtn(selected, PopupUnitSystem.us, 'US Oil Field'),
            _radioBtn(selected, PopupUnitSystem.si, 'SI'),
          ],
        );
      }),
    );
  }

  Widget _radioBtn(PopupUnitSystem selected, PopupUnitSystem value, String label) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () => controller.selectedRadio.value = value,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                width: isSelected ? 6 : 2,
              ),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              )),
        ]),
      ),
    );
  }

  // ── Left Panel Helpers ────────────────────────────────────────────────────────
  Widget _leftPanelHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor.withOpacity(0.1),
          AppTheme.secondaryColor.withOpacity(0.1),
        ]),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(children: [
        Icon(Icons.list, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text('Unit Systems',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const Spacer(),
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12)),
          child: Text('${mainController.unitSystems.length}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        )),
      ]),
    );
  }

  Widget _buildSystemTile(dynamic system, int index) {
    final isSelected = controller.selectedLeftIndex.value == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => controller.selectSystem(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white
                    : AppTheme.secondaryColor.withOpacity(0.2),
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(system.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  size: 16, color: Colors.white),
          ]),
        ),
      ),
    );
  }

  Widget _leftPanelFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Obx(() => _leftBtn(
              'Insert Before', Icons.add,
              controller.isInserting.value ? null : controller.insertBefore,
            )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => _leftBtn(
              'Insert After', Icons.add,
              controller.isInserting.value ? null : controller.insertAfter,
            )),
          ),
        ]),
        const SizedBox(height: 8),
        Obx(() => _leftBtn(
          'Delete Selected', Icons.delete_outline,
          controller.isDeleting.value
              ? null
              : () => controller.deleteSelected(context),
          isDanger: true,
        )),
      ]),
    );
  }

  Widget _leftBtn(String text, IconData icon, VoidCallback? onTap,
      {bool isDanger = false}) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDanger ? AppTheme.errorColor : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: Icon(icon, size: 16),
        label: Text(text,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _rightPanelHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: const Row(children: [
        SizedBox(
          width: 60,
          child: Text('#',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ),
        Expanded(
          child: Text('Parameters',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ),
        SizedBox(
          width: 180,
          child: Text('Unit',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ),
      ]),
    );
  }

  Widget _parameterTable() {
    final paramCount = OptionsController.parameters.length;
    return Container(
      color: Colors.white,
      child: Scrollbar(
        controller: _rightScroll,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _rightScroll,
          itemCount: paramCount,
          itemBuilder: (_, index) {
            final param = OptionsController.parameters[index];
            final number = param['number']!;

            return Obx(() {
              final currentUnit = mainController.customUnits[number] ?? '';
              final unitOptions = mainController.getUnitsForParam(number);

              final safeValue = unitOptions.contains(currentUnit)
                  ? currentUnit
                  : (unitOptions.isNotEmpty ? unitOptions.first : null);

              return Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : AppTheme.cardColor,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                  ),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 60,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(number,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        param['name']!,
                        style: AppTheme.bodyLarge.copyWith(
                            fontSize: 13, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: unitOptions.isEmpty
                        ? Container(
                            height: 36,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(currentUnit.isEmpty ? '-' : currentUnit,
                                style: const TextStyle(fontSize: 13)),
                          )
                        : Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: safeValue,
                                  icon: Icon(Icons.arrow_drop_down,
                                      color: AppTheme.primaryColor, size: 20),
                                  menuMaxHeight: 300,
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  onChanged: (newUnit) {
                                    if (newUnit == null) return;
                                    mainController.onUnitChanged(
                                      systemId: mainController
                                          .selectedCustomSystemId.value,
                                      paramNumber: number,
                                      newUnit: newUnit,
                                    );
                                  },
                                  items: unitOptions
                                      .map((u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(u,
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ]),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.info_outline, size: 16, color: AppTheme.infoColor),
            const SizedBox(width: 8),
            Text(
              '${OptionsController.parameters.length} parameters configured',
              style: AppTheme.bodySmall
                  .copyWith(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ]),
          Row(children: [
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: AppTheme.secondaryButtonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(Colors.white),
                  foregroundColor: MaterialStateProperty.all(AppTheme.textPrimary),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              // Valid Obx: reads isSaving observable
              child: Obx(() => ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () => controller.saveChanges(context),
                style: AppTheme.primaryButtonStyle,
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
              )),
            ),
          ]),
        ],
      ),
    );
  }
}