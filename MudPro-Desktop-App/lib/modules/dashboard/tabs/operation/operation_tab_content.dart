import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tabs/dailycost_table_usage.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/operation_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
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
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/tabs/vol_snapshot_page.dart' hide AppTheme;
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/transfer_mud.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OperationPage extends StatelessWidget {
  OperationPage({super.key});
  final controller = Get.find<OperationController>();
  final dashCtrl = Get.find<DashboardController>();
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT SIDEBAR - OPERATION MENU
            _buildLeftPanel(),
            
            /// VERTICAL DIVIDER
            Container(
              width: 1,
              height: double.infinity,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            
            /// RIGHT PANEL - FULL PAGE CONTENT
            Expanded(
              child: _buildRightPanel(),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- LEFT PANEL -----------------

 Widget _buildLeftPanel() {
  return Container(
    width: 280,
    decoration: BoxDecoration(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey.shade200,
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel Header with Icon Buttons
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.list_alt_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "Operations Menu",
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Icon Buttons in Header
              _buildIconButton(
                icon: Icons.inventory_2_outlined,
                tooltip: "Inventory Snapshot",
                onTap: () {
                  // Navigate to Inventory Snapshot page
                  Get.to(() => DailyCostTableUsagePage());
                },
              ),
              const SizedBox(width: 4),
              _buildIconButton(
                icon: Icons.analytics_outlined,
                tooltip: "Vol. Snapshot",
                onTap: () {
                  // Navigate to Volume Snapshot page
                  Get.to(() => VolumeSnapshotPage());
                },
              ),
              const SizedBox(width: 4),
              _buildIconButton(
                icon: Icons.water_drop_outlined,
                tooltip: "Mud Treated",
                onTap: () {
                  // Navigate to Mud Treated page
                  Get.to(() => MudTreatedPage());
                },
              ),
              const SizedBox(width: 4),
              _buildIconButton(
                icon: Icons.rate_review_outlined,
                tooltip: "Pit Review",
                onTap: () {
                  // Navigate to Pit Review page
                  Get.toNamed('/pit-review');
                },
              ),
            ],
          ),
        ),
        
        // Operations List - Dynamic rows
        Expanded(
          child: Scrollbar(
            child: Obx(() {
              // Calculate visible row count - start with 1, add more as selections are made
              int visibleRowCount = 1;
              for (int i = 0; i < controller.dropdownValues.length; i++) {
                if (controller.dropdownValues[i] != null) {
                  visibleRowCount = i + 2; // Show next row after selection
                }
              }
              // Ensure visibleRowCount doesn't exceed the available dropdown values
              visibleRowCount = visibleRowCount.clamp(1, controller.dropdownValues.length);

              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: visibleRowCount,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0xffE2E8F0),
                ),
                itemBuilder: (context, index) {
                  return Obx(() {
                    final isSelected = controller.selectedRowIndex.value == index;

                    return Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected ? Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ) : null,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 0.5),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            // Row number instead of chevron
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              child: Text(
                                "${index + 1}",
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Always show dropdown
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: Obx(() => GestureDetector(
                                      onTap: dashCtrl.isLocked.value
                                          ? () => dashCtrl.showLockedPopup()
                                          : null,
                                      child: AbsorbPointer(
                                        absorbing: dashCtrl.isLocked.value,
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
                                          value: controller.dropdownValues[index],
                                          onChanged: (v) {
                                            controller.dropdownValues[index] = v;
                                            controller.selectedRowIndex.value = index;
                                          },
                                          menuMaxHeight: 200,
                                          itemHeight: null,
                                          hint: Text(
                                            "",
                                            style: AppTheme.bodySmall.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          style: AppTheme.bodySmall.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textPrimary,
                                          ),
                                          items: [
                                            DropdownMenuItem<OperationType?>(
                                              value: null,
                                              child: Text(
                                                "",
                                                style: AppTheme.bodySmall.copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                            ...controller.dropdownItems.map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  controller.labels[e]!,
                                                  style: AppTheme.bodySmall.copyWith(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                              ),
                            ),

                            // Selection Indicator
                            if (isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Select an operation to view details",
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Helper method to build icon buttons with tooltip
Widget _buildIconButton({
  required IconData icon,
  required String tooltip,
  required VoidCallback onTap,
}) {
  return Tooltip(
    message: tooltip,
    preferBelow: true,
    verticalOffset: 6,
    textStyle: const TextStyle(
      fontSize: 11,
      color: Colors.white,
    ),
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(4),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: Colors.white,
        ),
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
          child: selectedOp != null ? _getViewForOperation(selectedOp) : _buildPlaceholderView(),
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






      default:
        return _buildPlaceholderView();
    }
  }

  Widget _buildPlaceholderView() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.secondaryColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.dashboard_customize_rounded,
                size: 40,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Operation View",
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select an operation from the menu to view its details",
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: AppTheme.secondaryButtonStyle,
              child: Text(
                "Coming Soon",
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}