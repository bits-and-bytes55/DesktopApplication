import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tabs/dailycost_table_usage.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/operation_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/add_water_view.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/consume_product.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/consume_service.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/empty_activesystem_view.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/mud_loss_view.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/mudloss_storage.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/othervolumeaddition_view.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/recieve_mud.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/recieve_product.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/return_lostmud.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/return_product.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/switch_mudtype_view.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/switch_pit_view.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/tabs/mud_treated_page.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/tabs/pit_review_page.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/tabs/vol_snapshot_page.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/transfer_mud.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_desktop_ui.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OperationPage extends StatelessWidget {
  OperationPage({super.key});
  final controller = Get.find<OperationController>();
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT SIDEBAR - OPERATION MENU
            _buildLeftPanel(context),

            /// VERTICAL DIVIDER
            Container(
              width: 1,
              height: double.infinity,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),

            /// RIGHT PANEL - FULL PAGE CONTENT
            Expanded(child: _buildRightPanel()),
          ],
        ),
      ),
    );
  }

  // ----------------- LEFT PANEL -----------------

  Future<void> _deleteOperationRow(BuildContext context, int index) async {
    final operation = index >= 0 && index < controller.dropdownValues.length
        ? controller.dropdownValues[index]
        : null;
    if (operation == null) return;

    final label = controller.labelFor(operation);
    final result = await controller.deleteOperationRow(index);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? '$label deleted'
              : (result['message']?.toString() ?? 'Delete failed'),
        ),
        backgroundColor: result['success'] == true
            ? AppTheme.successColor
            : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Container(
      width: 322,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header with Icon Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "Operation",
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                // Icon Buttons in Header
                _buildIconButton(
                  icon: Icons.inventory_2_outlined,
                  tooltip: "Inventory Snapshot",
                  onTap: () {
                    Get.to(() => const DailyCostTableUsagePage());
                  },
                ),
                const SizedBox(width: 4),
                _buildIconButton(
                  icon: Icons.analytics_outlined,
                  tooltip: "Vol. Snapshot",
                  onTap: _openVolumeSnapshot,
                ),
                const SizedBox(width: 4),
                _buildIconButton(
                  icon: Icons.water_drop_outlined,
                  tooltip: "Mud Treated",
                  onTap: _openMudTreated,
                ),
                const SizedBox(width: 4),
                _buildIconButton(
                  icon: Icons.rate_review_outlined,
                  tooltip: "Pit Review",
                  onTap: _openPitReview,
                ),
              ],
            ),
          ),

          // Operations List - Dynamic rows
          Expanded(
            child: Scrollbar(
              child: Obx(() {
                final visibleRowCount = controller.dropdownValues.length;

                return ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: visibleRowCount,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xffE2E8F0),
                  ),
                  itemBuilder: (context, index) {
                    return Obx(() {
                      final isSelected =
                          controller.selectedRowIndex.value == index;
                      final rowOperation = controller.dropdownValues[index];
                      final isDeleting =
                          controller.deletingOperationRowIndex.value == index;
                      final hasData = rowOperation != null;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => controller.selectedRowIndex.value = index,
                        onSecondaryTapDown: (details) async {
                          controller.selectedRowIndex.value = index;
                          final action = await showOperationRowMenu(
                            context: context,
                            details: details,
                            canEdit: !isDeleting,
                            hasData: hasData,
                            canPaste: false,
                            canInsertRow: false,
                            canDeleteRow: true,
                            canMoveTop: false,
                            canMoveBottom: false,
                          );
                          if (action == 'deleteRow' ||
                              action == 'delete' ||
                              action == 'clear') {
                            await _deleteOperationRow(context, index);
                          }
                        },
                        child: Container(
                          height: 34,
                          color: isSelected
                              ? const Color(0xFFDCEBFA)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  "${index + 1}",
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<OperationType?>(
                                    isExpanded: true,
                                    isDense: true,
                                    icon: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 18,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    dropdownColor: Colors.white,
                                    value: rowOperation,
                                    onChanged: (v) {
                                      controller.dropdownValues[index] = v;
                                      controller.selectedRowIndex.value = index;
                                    },
                                    menuMaxHeight: 220,
                                    itemHeight: null,
                                    hint: const SizedBox.shrink(),
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppTheme.textPrimary,
                                    ),
                                    items: [
                                      const DropdownMenuItem<OperationType?>(
                                        value: null,
                                        child: SizedBox.shrink(),
                                      ),
                                      ...controller.dropdownItems.map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            controller.labelFor(e),
                                            style: AppTheme.bodySmall.copyWith(
                                              fontSize: 11,
                                              color: AppTheme.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isDeleting)
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                );
              }),
            ),
          ),

          // Panel Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              color: Colors.white,
            ),
            child: Obx(
              () => Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      controller.isMenuLoading.value
                          ? "Loading operations from backend..."
                          : controller.menuError.value.isNotEmpty
                          ? "Backend sync failed. Static menu fallback active."
                          : "Operations menu is loaded from backend.",
                      style: AppTheme.caption.copyWith(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build icon buttons with tooltip
  void _openVolumeSnapshot() {
    final snapshotController = Get.isRegistered<VolumeSnapshotController>()
        ? Get.find<VolumeSnapshotController>()
        : Get.put(VolumeSnapshotController());
    snapshotController.load();
    Get.to(() => const VolumeSnapshotPage());
  }

  void _openMudTreated() {
    final mudTreatedController = Get.isRegistered<MudTreatedController>()
        ? Get.find<MudTreatedController>()
        : Get.put(MudTreatedController());
    mudTreatedController.load();
    Get.to(() => const MudTreatedPage());
  }

  void _openPitReview() {
    final pitReviewController = Get.isRegistered<PitReviewController>()
        ? Get.find<PitReviewController>()
        : Get.put(PitReviewController());
    pitReviewController.load();
    Get.to(() => const PitReviewPage());
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: true,
      verticalOffset: 6,
      textStyle: const TextStyle(fontSize: 11, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.grey.shade400, width: 0.8),
          ),
          child: Icon(icon, size: 13, color: const Color(0xFF2563EB)),
        ),
      ),
    );
  }

  // ----------------- RIGHT PANEL -----------------
  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      child: Obx(() {
        final selectedOp =
            controller.dropdownValues[controller.selectedRowIndex.value];

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: selectedOp != null
              ? _getViewForOperation(selectedOp)
              : _buildPlaceholderView(),
        );
      }),
    );
  }

  Widget _getViewForOperation(OperationType operation) {
    switch (operation) {
      case OperationType.consumeServices:
        return ConsumeServicesView(key: UniqueKey());

      case OperationType.consumeProduct:
        return ConsumeProductView(key: UniqueKey());

      case OperationType.mudLossActiveSystem:
        return MudLossActiveSystemView(key: UniqueKey());

      case OperationType.receiveProduct:
        return ReceiveProductView(key: UniqueKey());

      case OperationType.returnProduct:
        return ReturnProductView(key: UniqueKey());

      case OperationType.transferMud:
        return TransferMudView(key: UniqueKey());

      case OperationType.receiveMud:
        return ReceiveMudView();

      case OperationType.addWater:
        return AddWaterView();

      case OperationType.otherVolAddition:
        return OtherVolAdditionActiveSystemView();

      case OperationType.mudLossStorage:
        return MudLossStorageView();

      case OperationType.switchPit:
        return SwitchPitView();

      case OperationType.returnLostMud:
        return ReturnLostMudView();

      case OperationType.switchMudType:
        return SwitchMudTypeView();

      case OperationType.emptyActiveSystem:
        return EmptyActiveSystemView();
    }
  }

  Widget _buildPlaceholderView() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 34,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            Text(
              "Select an operation",
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Choose a row from the left menu to open its details.",
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
