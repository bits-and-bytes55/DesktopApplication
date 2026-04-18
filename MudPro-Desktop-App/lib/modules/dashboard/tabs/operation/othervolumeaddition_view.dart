import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/other_vol_addition_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OtherVolAdditionActiveSystemView extends StatelessWidget {
  OtherVolAdditionActiveSystemView({super.key});

  final OtherVolAdditionController controller =
      Get.put(OtherVolAdditionController());
  final DashboardController dashboardController = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Other Vol. Addition - Active System",
            style: AppTheme.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 400,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.95),
                              AppTheme.primaryColor,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            _headerCell("Addition", flex: 2),
                            _headerCell("Vol. (bbl)", flex: 1, isLast: true),
                          ],
                        ),
                      ),
                      if (controller.isLoading.value)
                        Container(
                          height: 96,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      else ...[
                        _fixedRow(
                          0,
                          'Formation',
                          controller.formationController,
                        ),
                        _fixedRow(
                          1,
                          'Cuttings',
                          controller.cuttingsController,
                        ),
                        _fixedRow(
                          2,
                          'Volume Not Fluid',
                          controller.volumeNotFluidController,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            right: isLast
                ? BorderSide.none
                : BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              AppUnits.label(text),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fixedRow(
    int index,
    String label,
    TextEditingController textController,
  ) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: textController,
                enabled: !dashboardController.isLocked.value,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
