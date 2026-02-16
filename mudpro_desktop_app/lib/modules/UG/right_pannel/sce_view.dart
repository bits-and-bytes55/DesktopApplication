import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/UG_controller.dart';
import '../controller/sce_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SceView extends StatelessWidget {
  SceView({super.key});
  
  final ugController = Get.find<UgController>();
  final sceController = Get.put(SceController());

  // Static well ID
  static const String WELL_ID = '507f1f77bcf86cd799439011';

  static const rowH = 32.0;
  static const headerH = 36.0;

  @override
  Widget build(BuildContext context) {
    // Load SCE data once when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sceController.currentWellId != WELL_ID) {
        sceController.loadSceData(WELL_ID);
      }
    });

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildShakerTable(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildOtherSceTable(context),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.vibration, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text(
            "Shaker Equipment",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  "${sceController.shakerCount} shakers",
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ],
            ),
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
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: _addDividers([
          const _HCell('Shaker', flex: 1),
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
        itemCount: sceController.shakers.length,
        itemBuilder: (_, i) {
          final shaker = sceController.shakers[i];

          return Container(
            height: rowH,
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xfffafafa),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Row(
              children: _addDividers([
                _cellText(shaker.shaker.value, flex: 1),
                _editableCell(shaker.model, flex: 3),
                _editableCell(shaker.screens, flex: 2),
                _checkboxCell(shaker.plot, flex: 1),
                _shakerActionsCell(i, shaker, flex: 2),
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
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() => ElevatedButton.icon(
            onPressed: sceController.isLoading.value ? null : () => _bulkSaveShakers(context),
            icon: sceController.isLoading.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, size: 16),
            label: Text(
              sceController.isLoading.value ? 'Saving...' : 'Save All',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.build, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text(
            "Other SCE Equipment",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  "${sceController.otherSceCount} equipment",
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ],
            ),
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
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
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
        itemCount: sceController.otherSce.length,
        itemBuilder: (_, i) {
          final sce = sceController.otherSce[i];

          return Container(
            height: rowH,
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xfffafafa),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Row(
              children: _addDividers([
                _editableCell(sce.type, flex: 2),
                _editableCell(sce.model1, flex: 2),
                _editableCell(sce.model2, flex: 2),
                _editableCell(sce.model3, flex: 2),
                _checkboxCell(sce.plot, flex: 1),
                _otherSceActionsCell(i, sce, flex: 2),
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
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() => ElevatedButton.icon(
            onPressed: sceController.isLoading.value ? null : () => _bulkSaveOtherSce(context),
            icon: sceController.isLoading.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, size: 16),
            label: Text(
              sceController.isLoading.value ? 'Saving...' : 'Save All',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
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
        result.add(
          Container(
            width: 1,
            color: Colors.grey.shade200,
            height: double.infinity,
          ),
        );
      }
    }
    return result;
  }

  // ================= CELLS =================
  Widget _cellText(String t, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          t,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _editableCell(RxString value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Obx(() {
          final isLocked = ugController.isLocked.value;
          
          if (isLocked) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                value.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: value.value.isEmpty 
                      ? Colors.grey.shade400 
                      : AppTheme.textSecondary,
                ),
              ),
            );
          } else {
            return TextField(
              controller: TextEditingController(text: value.value)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: value.value.length),
                ),
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
          final isLocked = ugController.isLocked.value;
          
          return Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: value.value,
              onChanged: isLocked ? null : (x) => value.value = x!,
              activeColor: AppTheme.successColor,
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _shakerActionsCell(int index, shaker, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Obx(() {
        final isLocked = ugController.isLocked.value;
        
        if (isLocked) {
          return const SizedBox.shrink();
        }
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (shaker.id != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => shaker.isEditing.value = true,
                tooltip: 'Edit',
              ),
            if (shaker.hasData) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _deleteShaker(index),
                tooltip: 'Delete',
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
        final isLocked = ugController.isLocked.value;
        
        if (isLocked) {
          return const SizedBox.shrink();
        }
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (sce.id != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => sce.isEditing.value = true,
                tooltip: 'Edit',
              ),
            if (sce.hasData) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _deleteOtherSce(index),
                tooltip: 'Delete',
              ),
            ],
          ],
        );
      }),
    );
  }

  // ================= ACTIONS =================
  
  Future<void> _deleteShaker(int index) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Shaker'),
        content: const Text('Are you sure you want to delete this shaker?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await sceController.deleteShaker(index);
    }
  }

  Future<void> _deleteOtherSce(int index) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete SCE'),
        content: const Text('Are you sure you want to delete this SCE equipment?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await sceController.deleteOtherSce(index);
    }
  }

  Future<void> _bulkSaveShakers(BuildContext context) async {
    final shakersWithData = sceController.shakers.where((s) => s.hasData).toList();

    if (shakersWithData.isEmpty) {
      _showAlert(context, 'No shakers to save', isSuccess: false);
      return;
    }

    try {
      sceController.isLoading.value = true;

      for (int i = 0; i < sceController.shakers.length; i++) {
        final shaker = sceController.shakers[i];
        if (shaker.hasData) {
          await sceController.saveShaker(i);
        }
      }

      await sceController.loadSceData(WELL_ID);

      if (context.mounted) {
        _showAlert(context, 'All shakers saved successfully', isSuccess: true);
      }
    } catch (e) {
      if (context.mounted) {
        _showAlert(context, 'Failed to save shakers', isSuccess: false);
      }
    } finally {
      sceController.isLoading.value = false;
    }
  }

  Future<void> _bulkSaveOtherSce(BuildContext context) async {
    final sceWithData = sceController.otherSce.where((s) => s.hasData).toList();

    if (sceWithData.isEmpty) {
      _showAlert(context, 'No equipment to save', isSuccess: false);
      return;
    }

    try {
      sceController.isLoading.value = true;

      for (int i = 0; i < sceController.otherSce.length; i++) {
        final sce = sceController.otherSce[i];
        if (sce.hasData) {
          await sceController.saveOtherSce(i);
        }
      }

      await sceController.loadSceData(WELL_ID);

      if (context.mounted) {
        _showAlert(context, 'All equipment saved successfully', isSuccess: true);
      }
    } catch (e) {
      if (context.mounted) {
        _showAlert(context, 'Failed to save equipment', isSuccess: false);
      }
    } finally {
      sceController.isLoading.value = false;
    }
  }

  void _showAlert(BuildContext context, String message, {bool isSuccess = true}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
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
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}