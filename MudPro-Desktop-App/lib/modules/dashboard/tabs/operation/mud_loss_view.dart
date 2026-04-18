import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_loss_active_system_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudLossActiveSystemView extends StatelessWidget {
  MudLossActiveSystemView({super.key});

  final MudLossActiveSystemController controller =
      Get.put(MudLossActiveSystemController());
  final DashboardController dashboardController = Get.find<DashboardController>();

  final List<Map<String, String>> fixedRows = const [
    {'label': 'Cuttings/Retention', 'key': 'cuttingsRetention'},
    {'label': 'Seepage', 'key': 'seepage'},
    {'label': 'Dump', 'key': 'dump'},
    {'label': 'Shakers', 'key': 'shakers'},
    {'label': 'Centrifuge', 'key': 'centrifuge'},
    {'label': 'Evaporation', 'key': 'evaporation'},
    {'label': 'Pit Cleaning', 'key': 'pitCleaning'},
    {'label': 'Formation', 'key': 'formation'},
    {'label': 'Abandon in Hole', 'key': 'abandonInHole'},
    {'label': 'Left behind Casing', 'key': 'leftBehindCasing'},
    {'label': 'Tripping', 'key': 'tripping'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mud Loss - Active System",
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
              width: 350,
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
                            _headerCell("#", width: 40),
                            _headerCell("Loss", flex: 2),
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
                        ...fixedRows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final row = entry.value;
                          return _buildFixedRow(index, row['label']!, row['key']!);
                        }),
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

  Widget _headerCell(String title, {double? width, int? flex, bool isLast = false}) {
    final cell = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          right: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            title == "#" ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (title != "#")
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          Flexible(
            child: Text(
              AppUnits.label(title),
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex ?? 1, child: cell);
  }

  Widget _buildFixedRow(int index, String label, String fieldKey) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey.shade50 : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              alignment: Alignment.center,
              child: Text(
                "${index + 1}",
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: controller.fields[fieldKey],
                enabled: !dashboardController.isLocked.value,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                ),
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
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
