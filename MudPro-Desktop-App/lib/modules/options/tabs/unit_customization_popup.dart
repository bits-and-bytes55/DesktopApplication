import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/options/controller/unit_system_controller.dart';

/// ═══════════════════════════════════════════════════════════════════
/// POPUP-SCOPED CONTROLLER
/// ═══════════════════════════════════════════════════════════════════
enum PopupUnitSystem { us, si }

class UnitCustomizationController extends GetxController {
  final selectedRadio     = PopupUnitSystem.us.obs;
  final selectedLeftIndex = 0.obs;
  final isInserting       = false.obs;
  final isDeleting        = false.obs;
  final isSaving          = false.obs;

  final UnitSystemController mainCtrl;
  UnitCustomizationController(this.mainCtrl);

  @override
  void onInit() {
    super.onInit();
    // Sync left panel selection to whatever was already selected on main page
    final idx = mainCtrl.selectedSystemIndex;
    selectedLeftIndex.value = idx >= 0 ? idx : 0;
  }

  // ── Select from left panel ────────────────────────────────────────────────
  void selectSystem(int index) {
    selectedLeftIndex.value = index;
    mainCtrl.selectUnitSystem(mainCtrl.unitSystems[index]);
    // Sync radio to that system's baseTemplate
    selectedRadio.value = mainCtrl.unitSystems[index].baseTemplate == 'si'
        ? PopupUnitSystem.si
        : PopupUnitSystem.us;
  }

  // ── Insert Before ─────────────────────────────────────────────────────────
  Future<void> insertBefore() async {
    final name = await _askName();
    if (name == null) return;
    isInserting.value = true;
    final template = selectedRadio.value == PopupUnitSystem.si ? 'si' : 'us';
    final created = await mainCtrl.createNewUnitSystem(name: name, baseTemplate: template);
    isInserting.value = false;
    if (created != null) {
      selectedLeftIndex.value = mainCtrl.unitSystems.length - 1;
      mainCtrl.selectUnitSystem(created);
    }
  }

  // ── Insert After ──────────────────────────────────────────────────────────
  Future<void> insertAfter() async {
    final name = await _askName();
    if (name == null) return;
    isInserting.value = true;
    final template = selectedRadio.value == PopupUnitSystem.si ? 'si' : 'us';
    final created = await mainCtrl.createNewUnitSystem(name: name, baseTemplate: template);
    isInserting.value = false;
    if (created != null) {
      selectedLeftIndex.value = mainCtrl.unitSystems.length - 1;
      mainCtrl.selectUnitSystem(created);
    }
  }

  // ── Delete Selected ───────────────────────────────────────────────────────
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

    // Adjust index after deletion
    if (selectedLeftIndex.value >= mainCtrl.unitSystems.length) {
      selectedLeftIndex.value =
          mainCtrl.unitSystems.isEmpty ? 0 : mainCtrl.unitSystems.length - 1;
    }
    if (mainCtrl.unitSystems.isNotEmpty) {
      mainCtrl.selectUnitSystem(mainCtrl.unitSystems[selectedLeftIndex.value]);
    }
  }

  // ── Save Changes (full PUT) ───────────────────────────────────────────────
  Future<void> saveChanges(BuildContext context) async {
    final systemId = mainCtrl.selectedCustomSystemId.value;
    if (systemId.isEmpty) return;
    isSaving.value = true;
    final ok = await mainCtrl.saveAllChanges(systemId);
    isSaving.value = false;
    if (ok && context.mounted) Navigator.of(context).pop();
  }

  // ── Name input dialog ─────────────────────────────────────────────────────
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
            child: const Text('Cancel'),
          ),
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

/// ═══════════════════════════════════════════════════════════════════
/// POPUP DIALOG  (UI unchanged — only wired to API via controllers)
/// ═══════════════════════════════════════════════════════════════════
class UnitSystemCustomizationPopup extends StatelessWidget {
  UnitSystemCustomizationPopup({super.key});

  final mainController = Get.find<UnitSystemController>();
  late final controller = Get.put(
    UnitCustomizationController(mainController),
    tag: 'unit_popup',
  );

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
              _header(context),
              _radioRow(),
              Divider(height: 1, color: Colors.grey.shade300),
              Expanded(
                child: LayoutBuilder(builder: (ctx, constraints) {
                  return constraints.maxWidth < 900
                      ? _mobileLayout(context)
                      : _desktopLayout(context);
                }),
              ),
              _footer(context),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context) => Row(children: [
    _leftPanel(context),
    Container(width: 1, color: Colors.grey.shade300),
    Expanded(child: _rightPanel()),
  ]);

  Widget _mobileLayout(BuildContext context) => SingleChildScrollView(
    child: Column(children: [
      _leftPanel(context),
      Container(height: 1, color: Colors.grey.shade300, width: double.infinity),
      SizedBox(height: 400, child: _rightPanel()),
    ]),
  );

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
          child: const Icon(Icons.tune, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Text('Unit System Customization',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }

  // ── Radio Row ──────────────────────────────────────────────────────────────
  Widget _radioRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardColor,
      child: Obx(() => Wrap(
        spacing: 20, runSpacing: 8,
        children: [
          _radioBtn(PopupUnitSystem.us, 'US Oil Field'),
          _radioBtn(PopupUnitSystem.si, 'SI'),
        ],
      )),
    );
  }

  Widget _radioBtn(PopupUnitSystem value, String label) {
    final isSelected = controller.selectedRadio.value == value;
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

  // ── Left Panel ─────────────────────────────────────────────────────────────
  Widget _leftPanel(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280, minWidth: 200),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.secondaryColor.withOpacity(0.1),
                ],
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(children: [
              Icon(Icons.list, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text('Unit Systems',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const Spacer(),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(12)),
                child: Text('${mainController.unitSystems.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              )),
            ]),
          ),

          // List
          Expanded(
            child: Obx(() {
              if (mainController.isLoadingSystems.value) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              return Container(
                color: AppTheme.backgroundColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: mainController.unitSystems.length,
                  itemBuilder: (_, index) {
                    return Obx(() {
                      final isSelected = controller.selectedLeftIndex.value == index;
                      final system = mainController.unitSystems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => controller.selectSystem(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppTheme.primaryGradient : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.white : AppTheme.secondaryColor.withOpacity(0.2),
                                ),
                                child: Center(
                                  child: Text('${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600,
                                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                      )),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(system.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, size: 16, color: Colors.white),
                            ]),
                          ),
                        ),
                      );
                    });
                  },
                ),
              );
            }),
          ),

          // Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(children: [
              Row(children: [
                Expanded(child: Obx(() => _leftBtn(
                  'Insert Before', Icons.add,
                  controller.isInserting.value ? null : () => controller.insertBefore(),
                ))),
                const SizedBox(width: 8),
                Expanded(child: Obx(() => _leftBtn(
                  'Insert After', Icons.add,
                  controller.isInserting.value ? null : () => controller.insertAfter(),
                ))),
              ]),
              const SizedBox(height: 8),
              Obx(() => _leftBtn(
                'Delete Selected', Icons.delete_outline,
                controller.isDeleting.value ? null : () => controller.deleteSelected(context),
                isDanger: true,
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _leftBtn(String text, IconData icon, VoidCallback? onTap, {bool isDanger = false}) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDanger ? AppTheme.errorColor : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: Icon(icon, size: 16),
        label: Text(text, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
      ),
    );
  }

  // ── Right Panel ────────────────────────────────────────────────────────────
  Widget _rightPanel() {
    return Column(children: [
      // Header
      Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(gradient: AppTheme.tableHeaderDecoration.gradient),
        child: const Row(children: [
          SizedBox(width: 60, child: Text('#', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
          Expanded(child: Text('Parameters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
          SizedBox(width: 180, child: Text('Unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
        ]),
      ),

      // Table
      Expanded(
        child: Obx(() {
          if (mainController.isLoadingSystems.value) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          return Container(
            color: Colors.white,
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                itemCount: mainController.parameters.length,
                itemBuilder: (_, index) {
                  final param = mainController.parameters[index];
                  final number = param['number']!;
                  return Obx(() {
                    final currentUnit = mainController.customUnits[number] ?? '';
                    return Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : AppTheme.cardColor,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                      ),
                      child: Row(children: [
                        // Number badge
                        SizedBox(
                          width: 60,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.2), shape: BoxShape.circle),
                            child: Center(
                              child: Text(number,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            ),
                          ),
                        ),

                        // Parameter name
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(param['name']!,
                                style: AppTheme.bodyLarge.copyWith(fontSize: 13, color: AppTheme.textPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),

                        // Unit dropdown — auto-saves on change
                        SizedBox(
                          width: 180,
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: currentUnit.isEmpty ? null : currentUnit,
                                  icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor, size: 20),
                                  menuMaxHeight: 300,
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  onChanged: (newUnit) {
                                    if (newUnit == null) return;
                                    mainController.onUnitChanged(
                                      systemId:    mainController.selectedCustomSystemId.value,
                                      paramNumber: number,
                                      newUnit:     newUnit,
                                    );
                                  },
                                  items: mainController.allUnits.map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Row(children: [
                                      Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                        ),
                                        child: Center(
                                          child: Text(u.substring(0, 1),
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(u, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                                    ]),
                                  )).toList(),
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
        }),
      ),
    ]);
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.info_outline, size: 16, color: AppTheme.infoColor),
          const SizedBox(width: 8),
          Obx(() => Text(
            '${mainController.parameters.length} parameters configured',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontSize: 12),
          )),
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
            child: Obx(() => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () => controller.saveChanges(context),
              style: AppTheme.primaryButtonStyle,
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes'),
            )),
          ),
        ]),
      ]),
    );
  }
}