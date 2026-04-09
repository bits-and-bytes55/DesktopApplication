import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/UG_controller.dart';
import '../controller/sce_controller.dart';
import '../model/sce_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SceView extends StatefulWidget {
  const SceView({super.key});

  @override
  State<SceView> createState() => _SceViewState();
}

class _SceViewState extends State<SceView> {
  late final UgController ugController;
  late final SceController sceController;
  late final DashboardController dashCtrl;

  static const String WELL_ID = '507f1f77bcf86cd799439011';

  static const rowH = 32.0;
  static const headerH = 36.0;

  // ✅ Static shaker row labels (fixed, read-only) — index = row position
  static const List<String> shakerRowLabels = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
    'Mud Cleaner', 'Dryer',
  ];

  // ✅ Static Other SCE row labels (fixed, read-only)
  static const List<String> otherSceRowLabels = [
    'Degasser',
    'Desander',
    'Desilter',
    'Centrifuge',
    'Barite Rec.',
  ];

  @override
  void initState() {
    super.initState();
    ugController = Get.find<UgController>();
    sceController = Get.isRegistered<SceController>()
        ? Get.find<SceController>()
        : Get.put(SceController());
    dashCtrl = Get.find<DashboardController>();
    // ✅ Load data only once when the page is first shown — NOT on every rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sceController.loadSceData(WELL_ID);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildShakerTable(context)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildOtherSceTable(context)),
        ],
      ),
    );
  }

  // ================= SHAKER TABLE =================
  Widget _buildShakerTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          _shakerHeader(),
          _shakerColumnHeaders(),
          Expanded(child: _shakerTableBody()),
          _shakerFooter(context),
        ],
      ),
    );
  }

  Widget _shakerHeader() {
    return Container(
      height: headerH,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.vibration, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text("Shaker Equipment", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const Spacer(),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text("${sceController.shakerCount} shakers", style: const TextStyle(fontSize: 11, color: Colors.white)),
            ]),
          )),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _shakerColumnHeaders() {
    return Container(
      height: rowH,
      decoration: BoxDecoration(
        color: const Color(0xfff0f9ff),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: _addDividers([
          const _HCell('Shaker', flex: 2),
          const _HCell('Model', flex: 3),
          const _HCell('No. of Screen', flex: 2),
          const _HCell('Plot', flex: 1),
          const _HCell('Actions', flex: 2),
        ]),
      ),
    );
  }

  Widget _shakerTableBody() {
    return Obx(() {
      if (sceController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        itemCount: shakerRowLabels.length,
        itemBuilder: (_, i) {
          final label = shakerRowLabels[i];
          final shaker = i < sceController.shakers.length ? sceController.shakers[i] : null;
          final shakerIndex = i;

          return Container(
            height: rowH,
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xfffafafa),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
            ),
            child: Row(
              children: _addDividers([
                // ✅ Col 1: Static label — read-only, grayed
                _staticLabelCell(label, flex: 2),
                // Col 2: Model — editable
                shaker != null
                    ? _editableCell(shaker.model, flex: 3)
                    : _emptyCell(flex: 3),
                // Col 3: No. of Screen — click-to-show dropdown with 1-8 options
                _screensDropdownCell(shaker, label: label, flex: 2),
                // Col 4: Plot — checkbox
                shaker != null
                    ? _checkboxCell(shaker.plot, flex: 1)
                    : _emptyCell(flex: 1),
                // Col 5: Actions
                shaker != null
                    ? _shakerActionsCell(shakerIndex, shaker, flex: 2)
                    : _emptyCell(flex: 2),
              ]),
            ),
          );
        },
      );
    });
  }

  Widget _shakerFooter(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() => ElevatedButton.icon(
            onPressed: dashCtrl.isLocked.value
                ? () => dashCtrl.showLockedPopup()
                : (sceController.isLoading.value ? null : () => _bulkSaveShakers(context)),
            icon: sceController.isLoading.value
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, size: 16),
            label: Text(sceController.isLoading.value ? 'Saving...' : 'Save All', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: dashCtrl.isLocked.value ? Colors.grey : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          )),
        ],
      ),
    );
  }

  // ================= OTHER SCE TABLE =================
  Widget _buildOtherSceTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          _otherSceHeader(),
          _otherSceColumnHeaders(),
          Expanded(child: _otherSceTableBody()),
          _otherSceFooter(context),
        ],
      ),
    );
  }

  Widget _otherSceHeader() {
    return Container(
      height: headerH,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.build, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text("Other SCE Equipment", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const Spacer(),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text("${sceController.otherSceCount} equipment", style: const TextStyle(fontSize: 11, color: Colors.white)),
            ]),
          )),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _otherSceColumnHeaders() {
    return Container(
      height: rowH,
      decoration: BoxDecoration(
        color: const Color(0xfff0f9ff),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: _addDividers([
          const _HCell('Type', flex: 2),
          const _HCell('Model 1', flex: 2),
          const _HCell('Model 2', flex: 2),
          const _HCell('Model 3', flex: 2),
          const _HCell('Plot', flex: 1),
          const _HCell('Actions', flex: 2),
        ]),
      ),
    );
  }

  Widget _otherSceTableBody() {
    return Obx(() {
      if (sceController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        itemCount: otherSceRowLabels.length,
        itemBuilder: (_, i) {
          final label = otherSceRowLabels[i];
          final sce = i < sceController.otherSce.length ? sceController.otherSce[i] : null;
          final sceIndex = i;

          return Container(
            height: rowH,
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xfffafafa),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
            ),
            child: Row(
              children: _addDividers([
                // ✅ Col 1: Static label — read-only
                _staticLabelCell(label, flex: 2),
                // Col 2,3,4: Model 1,2,3 — editable
                sce != null
                    ? _editableCell(sce.model1, flex: 2)
                    : _emptyCell(flex: 2),
                sce != null
                    ? _editableCell(sce.model2, flex: 2)
                    : _emptyCell(flex: 2),
                sce != null
                    ? _editableCell(sce.model3, flex: 2)
                    : _emptyCell(flex: 2),
                // Col 5: Plot
                sce != null
                    ? _checkboxCell(sce.plot, flex: 1)
                    : _emptyCell(flex: 1),
                // Col 6: Actions
                sce != null
                    ? _otherSceActionsCell(sceIndex, sce, flex: 2)
                    : _emptyCell(flex: 2),
              ]),
            ),
          );
        },
      );
    });
  }

  Widget _otherSceFooter(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() => ElevatedButton.icon(
            onPressed: dashCtrl.isLocked.value
                ? () => dashCtrl.showLockedPopup()
                : (sceController.isLoading.value ? null : () => _bulkSaveOtherSce(context)),
            icon: sceController.isLoading.value
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, size: 16),
            label: Text(sceController.isLoading.value ? 'Saving...' : 'Save All', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: dashCtrl.isLocked.value ? Colors.grey : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          )),
        ],
      ),
    );
  }

  // ================= HELPER =================
  List<Widget> _addDividers(List<Widget> widgets) {
    final List<Widget> result = [];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(Container(width: 1, color: Colors.grey.shade200, height: double.infinity));
      }
    }
    return result;
  }

  // ================= CELLS =================

  // ✅ Static read-only label cell (grayed background)
  Widget _staticLabelCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: const Color(0xfff8f8f8),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }







  Widget _emptyCell({required int flex}) {
    return Expanded(flex: flex, child: const SizedBox.shrink());
  }

  Widget _editableCell(RxString value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Obx(() {
          final isLocked = dashCtrl.isLocked.value;
          if (isLocked) {
            return GestureDetector(
              onTap: () => dashCtrl.showLockedPopup(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(value.value, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: value.value.isEmpty ? Colors.grey.shade400 : AppTheme.textSecondary)),
              ),
            );
          } else {
            return TextField(
              controller: TextEditingController(text: value.value)
                ..selection = TextSelection.fromPosition(TextPosition(offset: value.value.length)),
              onChanged: (v) => value.value = v,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: InputBorder.none,
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _checkboxCell(RxBool value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        child: Obx(() {
          final isLocked = dashCtrl.isLocked.value;
          return GestureDetector(
            onTap: isLocked ? () => dashCtrl.showLockedPopup() : null,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(
              absorbing: isLocked,
              child: Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: value.value,
                  onChanged: isLocked ? null : (x) => value.value = x!,
                  activeColor: AppTheme.successColor,
                  checkColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ✅ FIXED: Screens dropdown with click-to-show-icon behavior
  Widget _screensDropdownCell(ShakerModel? shaker, {required String label, required int flex}) {
    return Expanded(
      flex: flex,
      child: _ScreensDropdownCell(
        shaker: shaker,
        label: label,
        sceController: sceController,
        dashCtrl: dashCtrl,
      ),
    );
  }

  Widget _shakerActionsCell(int index, shaker, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Obx(() {
        final isLocked = dashCtrl.isLocked.value;
        if (isLocked) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.lock, size: 16, color: Colors.grey),
                onPressed: () => dashCtrl.showLockedPopup(),
                tooltip: 'Locked',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (shaker.id != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => shaker.isEditing.value = true,
              ),
            if (shaker.hasData) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => _deleteShaker(index),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _otherSceActionsCell(int index, sce, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Obx(() {
        final isLocked = dashCtrl.isLocked.value;
        if (isLocked) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.lock, size: 16, color: Colors.grey),
                onPressed: () => dashCtrl.showLockedPopup(),
                tooltip: 'Locked',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (sce.id != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => sce.isEditing.value = true,
              ),
            if (sce.hasData) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => _deleteOtherSce(index),
              ),
            ],
          ],
        );
      }),
    );
  }

  // ================= ACTIONS =================
  Future<void> _deleteShaker(int index) async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Delete Shaker'),
      content: const Text('Are you sure you want to delete this shaker?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
        TextButton(onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
      ],
    ));
    if (confirmed == true) await sceController.deleteShaker(index);
  }

  Future<void> _deleteOtherSce(int index) async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Delete SCE'),
      content: const Text('Are you sure you want to delete this SCE equipment?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
        TextButton(onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
      ],
    ));
    if (confirmed == true) await sceController.deleteOtherSce(index);
  }

  Future<void> _bulkSaveShakers(BuildContext context) async {
    // ✅ Save all rows that have model or screens data, using label as shaker name
    try {
      sceController.isLoading.value = true;

      // Build map of existing shakers by label
      final Map<String, dynamic> shakerByLabel = {};
      final Map<String, int> shakerIndexByLabel = {};
      for (int i = 0; i < sceController.shakers.length; i++) {
        final s = sceController.shakers[i];
        if (s.shaker.value.isNotEmpty) {
          shakerByLabel[s.shaker.value] = s;
          shakerIndexByLabel[s.shaker.value] = i;
        }
      }

      bool anySaved = false;
      for (final label in shakerRowLabels) {
        final shaker = shakerByLabel[label];
        if (shaker != null && shaker.hasData) {
          final idx = shakerIndexByLabel[label]!;
          await sceController.saveShaker(idx);
          anySaved = true;
        }
      }

      if (!anySaved) {
        if (context.mounted) _showAlert(context, 'No shakers to save', isSuccess: false);
        return;
      }

      await sceController.loadSceData(WELL_ID);
      if (context.mounted) _showAlert(context, 'All shakers saved successfully', isSuccess: true);
    } catch (e) {
      if (context.mounted) _showAlert(context, 'Failed to save shakers', isSuccess: false);
    } finally {
      sceController.isLoading.value = false;
    }
  }

  Future<void> _bulkSaveOtherSce(BuildContext context) async {
    try {
      sceController.isLoading.value = true;

      // ✅ FIX: Also handle position-based matching for rows with empty type
      final Map<String, dynamic> sceByLabel = {};
      final Map<String, int> sceIndexByLabel = {};
      final Map<int, dynamic> sceByPosition = {};
      final Map<int, int> sceControllerIndexByPosition = {};

      for (int i = 0; i < sceController.otherSce.length; i++) {
        final s = sceController.otherSce[i];
        if (s.type.value.isNotEmpty) {
          sceByLabel[s.type.value] = s;
          sceIndexByLabel[s.type.value] = i;
        } else if (s.hasData && i < otherSceRowLabels.length) {
          sceByPosition[i] = s;
          sceControllerIndexByPosition[i] = i;
        }
      }

      bool anySaved = false;
      for (int i = 0; i < otherSceRowLabels.length; i++) {
        final label = otherSceRowLabels[i];
        
        dynamic sce = sceByLabel[label];
        int? idx = sceIndexByLabel[label];
        
        if (sce == null && sceByPosition.containsKey(i)) {
          sce = sceByPosition[i];
          idx = sceControllerIndexByPosition[i];
          // ✅ FIX: Assign the label to the type field before saving
          if (sce != null) sce.type.value = label;
        }

        if (sce != null && sce.hasData && idx != null) {
          await sceController.saveOtherSce(idx);
          anySaved = true;
        }
      }

      if (!anySaved) {
        if (context.mounted) _showAlert(context, 'No equipment to save', isSuccess: false);
        return;
      }

      await sceController.loadSceData(WELL_ID);
      if (context.mounted) _showAlert(context, 'All equipment saved successfully', isSuccess: true);
    } catch (e) {
      if (context.mounted) _showAlert(context, 'Failed to save equipment', isSuccess: false);
    } finally {
      sceController.isLoading.value = false;
    }
  }

  void _showAlert(BuildContext context, String message, {bool isSuccess = true}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20, right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isSuccess ? Icons.check_circle : Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(message, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }
}

// ✅ Screens dropdown cell — pure StatefulWidget, no GetX in build
class _ScreensDropdownCell extends StatefulWidget {
  final ShakerModel? shaker;
  final String label;
  final SceController sceController;
  final DashboardController dashCtrl;

  const _ScreensDropdownCell({
    required this.shaker,
    required this.label,
    required this.sceController,
    required this.dashCtrl,
  });

  @override
  State<_ScreensDropdownCell> createState() => _ScreensDropdownCellState();
}

class _ScreensDropdownCellState extends State<_ScreensDropdownCell> {
  static const List<String> _opts = ['', '1', '2', '3', '4', '5', '6', '7', '8'];

  String? _localValue;
  bool _isLocked = false;
  bool _showIcon = false; // ✅ Added to track icon visibility on first click

  Worker? _valueWorker;
  Worker? _lockWorker;

  @override
  void initState() {
    super.initState();
    _updateLocalStates();

    // Listen to changes if shaker exists
    if (widget.shaker != null) {
      _valueWorker = ever<String>(widget.shaker!.screens, (val) {
        if (mounted) setState(() => _localValue = val.isEmpty ? null : val);
      });
    }
    _lockWorker = ever<bool>(widget.dashCtrl.isLocked, (val) {
      if (mounted) setState(() => _isLocked = val);
    });
  }

  void _updateLocalStates() {
    _localValue = (widget.shaker?.screens.value.isEmpty ?? true) ? null : widget.shaker?.screens.value;
    _isLocked = widget.dashCtrl.isLocked.value;
  }

  @override
  void didUpdateWidget(covariant _ScreensDropdownCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shaker != widget.shaker) {
      _valueWorker?.dispose();
      if (widget.shaker != null) {
        _valueWorker = ever<String>(widget.shaker!.screens, (val) {
          if (mounted) setState(() => _localValue = val.isEmpty ? null : val);
        });
      }
      _updateLocalStates();
    }
  }

  @override
  void dispose() {
    _valueWorker?.dispose();
    _lockWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return GestureDetector(
        onTap: () => widget.dashCtrl.showLockedPopup(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: Text(
            _localValue ?? '',
            style: TextStyle(
              fontSize: 11,
              color: _localValue == null ? Colors.grey.shade400 : AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!_showIcon) {
            setState(() => _showIcon = true);
          } else {
            _showDropdownMenu(context);
          }
        },
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _localValue ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              // ✅ UI Fix: Icon only shows after first click
              if (_showIcon)
                const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showDropdownMenu(BuildContext context) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      constraints: const BoxConstraints(maxWidth: 80),
      items: _opts.map((v) => PopupMenuItem<String>(
        value: v,
        height: 30, // ✅ Compact height
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: Text(v, style: const TextStyle(fontSize: 11)),
        ),
      )).toList(),
    ).then((val) {
      if (val != null) {
        _handleValueSelected(val);
      }
    });
  }

  void _handleValueSelected(String val) {
    if (widget.shaker != null) {
      widget.shaker!.screens.value = val;
    }
    setState(() => _localValue = val.isEmpty ? null : val);
  }
}


class _HCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ),
    );
  }
}