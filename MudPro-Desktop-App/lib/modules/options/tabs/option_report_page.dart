import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/options/controller/option_report_controller.dart';

class OptionsReportPage extends StatelessWidget {
  OptionsReportPage({super.key});

  final controller = Get.put(OptionsReportController());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            Text(
              'Report Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carry-over Section
                    _buildSection(
                      title: 'Carry-over',
                      icon: Icons.compare_arrows_outlined,
                      children: [
                        _buildOptionTile(
                          title: 'Mud Properties',
                          rxIsChecked: controller.mudProperties,
                          onChanged: (val) =>
                              controller.mudProperties.value = val!,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Operation Section
                    _buildSection(
                      title: 'Operation',
                      icon: Icons.engineering_outlined,
                      children: [
                        _buildOptionTile(
                          title: 'All',
                          rxIsChecked: controller.operationEnabled,
                          onChanged: (val) =>
                              controller.operationEnabled.value = val!,
                        ),
                        Obx(() {
                          final enabled = controller.operationEnabled.value;
                          final type = controller.operationType.value;
                          return Padding(
                            padding: const EdgeInsets.only(left: 36),
                            child: Column(
                              children: [
                                _buildRadioOption(
                                  title: 'All',
                                  enabled: enabled,
                                  value: 'All',
                                  groupValue: type,
                                  onChanged: enabled
                                      ? (val) => controller.operationType
                                          .value = val!
                                      : (_) {},
                                ),
                                const SizedBox(height: 12),
                                _buildRadioOption(
                                  title: 'Consume Service Only',
                                  enabled: enabled,
                                  value: 'Consume Service Only',
                                  groupValue: type,
                                  onChanged: enabled
                                      ? (val) => controller.operationType
                                          .value = val!
                                      : (_) {},
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Solids Analysis Section
                    _buildSection(
                      title: 'Solids Analysis',
                      icon: Icons.analytics_outlined,
                      children: [
                        _buildOptionTile(
                          title: 'Show Negative Values',
                          rxIsChecked: controller.showNegativeValues,
                          onChanged: (val) =>
                              controller.showNegativeValues.value = val!,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Mud Vol. Section
                    _buildSection(
                      title: 'Mud Vol.',
                      icon: Icons.water_drop_outlined,
                      children: [
                        _buildOptionTile(
                          title: 'Check Mud Vol.',
                          rxIsChecked: controller.checkMudVol,
                          onChanged: (val) =>
                              controller.checkMudVol.value = val!,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Inventory Section
                    _buildSection(
                      title: 'Inventory',
                      icon: Icons.inventory_2_outlined,
                      children: [
                        _buildOptionTile(
                          title: 'Negative Inventory Warning',
                          rxIsChecked: controller.negativeInventoryWarning,
                          onChanged: (val) =>
                              controller.negativeInventoryWarning.value =
                                  val!,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Multiple Daily Reports Section
                    _buildSection(
                      title: 'Multiple Daily Reports',
                      icon: Icons.receipt_long_outlined,
                      children: [
                        _buildOptionTile(
                          title: 'Multiple Daily Reports',
                          rxIsChecked: controller.multipleDailyReports,
                          onChanged: (val) =>
                              controller.multipleDailyReports.value = val!,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    side: BorderSide(
                        color: AppTheme.primaryColor
                            .withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: controller.onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required RxBool rxIsChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Obx(() => Checkbox(
                  value: rxIsChecked.value,
                  onChanged: onChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  fillColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppTheme.primaryColor;
                      }
                      return Colors.grey.shade300;
                    },
                  ),
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required bool enabled,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: enabled ? onChanged : null,
              fillColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (!enabled) return Colors.grey.shade300;
                  if (states.contains(MaterialState.selected)) {
                    return AppTheme.primaryColor;
                  }
                  return Colors.grey.shade400;
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: enabled ? AppTheme.textPrimary : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}