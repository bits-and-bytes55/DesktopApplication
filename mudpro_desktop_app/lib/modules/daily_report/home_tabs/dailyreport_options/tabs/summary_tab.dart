import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/controller/option_report_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReportOptionSummaryPage extends StatelessWidget {
  ReportOptionSummaryPage({super.key});

  final controller = Get.put(ReportOptionSummaryController());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.dashboard_outlined,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Report Options - Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: controller.resetDefault,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  icon: const Icon(Icons.restart_alt_outlined, size: 16),
                  label: const Text(
                    'Reset to Default',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Section
                Expanded(
                  child: _buildSectionBox(
                    title: 'Dashboard (Up to 3)',
                    child: _buildDashboardSection(),
                  ),
                ),
                const SizedBox(width: 16),

                // Cost Distribution Section
                Expanded(
                  child: _buildSectionBox(
                    title: 'Cost Distribution (Up to 2)',
                    child: _buildCostDistributionSection(),
                  ),
                ),
                const SizedBox(width: 16),

                // Progress Section
                Expanded(
                  child: _buildSectionBox(
                    title: 'Progress (Up to 3)',
                    child: _buildProgressSection(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== SECTION BOX ==================
  Widget _buildSectionBox({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Obx(() {
                    int selectedCount = 0;
                    String counterText = '';
                    
                    if (title.contains('Dashboard')) {
                      selectedCount = controller.dashboardSelected.length;
                      counterText = '$selectedCount/3';
                    } else if (title.contains('Cost')) {
                      // Count selected cost options
                      final costOptions = [
                        controller.top10Product.value,
                        controller.product.value,
                        controller.package.value,
                        controller.service.value,
                        controller.premixedMud.value,
                        controller.engineering.value,
                        controller.allCategories.value,
                      ];
                      selectedCount = costOptions.where((e) => e).length;
                      counterText = '$selectedCount/7';
                    } else if (title.contains('Progress')) {
                      selectedCount = controller.progressSelected.length;
                      counterText = '$selectedCount/3';
                    }
                    
                    return Text(
                      counterText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Section Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // ================== DASHBOARD SECTION ==================
  Widget _buildDashboardSection() {
    return Obx(() {
      final selectedCount = controller.dashboardSelected.length;
      final maxCount = 3;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning if max reached
          if (selectedCount >= maxCount)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Maximum $maxCount items allowed',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Options List
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: controller.dashboardItems.map((item) {
                final isSelected = controller.dashboardSelected.contains(item);
                final isDisabled = !isSelected && selectedCount >= maxCount;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.2)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(right: 8, left: 4),
                      title: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          color: isDisabled
                              ? Colors.grey.shade400
                              : AppTheme.textPrimary,
                        ),
                      ),
                      value: isSelected,
                      onChanged: isDisabled ? null : (val) {
                        if (val!) {
                          if (selectedCount < maxCount) {
                            controller.dashboardSelected.add(item);
                          }
                        } else {
                          controller.dashboardSelected.remove(item);
                        }
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  // ================== COST DISTRIBUTION SECTION ==================
  Widget _buildCostDistributionSection() {
    return Obx(() {
      return ListView(
        shrinkWrap: true,
        children: [
          // Simple Checkboxes
          _buildSimpleCheckbox('Top 10 Product', controller.top10Product.value,
              (v) => controller.top10Product.value = v!),
          _buildSimpleCheckbox('Product', controller.product.value,
              (v) => controller.product.value = v!),

          // Group Dropdowns
          ...List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    child: Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: false,
                        onChanged: null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Group',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: DropdownButtonFormField<String>(
                        value: controller.groupDropdownValues[index],
                        items: controller.groupList
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.groupDropdownValues[index] = val;
                          }
                        },
                        isDense: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                        dropdownColor: Colors.white,
                        menuMaxHeight: 200,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Remaining Checkboxes
          _buildSimpleCheckbox('Package', controller.package.value,
              (v) => controller.package.value = v!),
          _buildSimpleCheckbox('Service', controller.service.value,
              (v) => controller.service.value = v!),
          _buildSimpleCheckbox('Premixed Mud', controller.premixedMud.value,
              (v) => controller.premixedMud.value = v!),
          _buildSimpleCheckbox('Engineering', controller.engineering.value,
              (v) => controller.engineering.value = v!),
          _buildSimpleCheckbox('All Categories', controller.allCategories.value,
              (v) => controller.allCategories.value = v!),
        ],
      );
    });
  }

  // ================== PROGRESS SECTION ==================
  Widget _buildProgressSection() {
    return Obx(() {
      final selectedCount = controller.progressSelected.length;
      final maxCount = 3;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning if max reached
          if (selectedCount >= maxCount)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Maximum $maxCount items allowed',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Options List
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: controller.progressItems.map((item) {
                final isSelected = controller.progressSelected.contains(item);
                final isDisabled = !isSelected && selectedCount >= maxCount;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.2)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(right: 8, left: 4),
                      title: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          color: isDisabled
                              ? Colors.grey.shade400
                              : AppTheme.textPrimary,
                        ),
                      ),
                      value: isSelected,
                      onChanged: isDisabled ? null : (val) {
                        if (val!) {
                          if (selectedCount < maxCount) {
                            controller.progressSelected.add(item);
                          }
                        } else {
                          controller.progressSelected.remove(item);
                        }
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  // ================== HELPER METHODS ==================
  Widget _buildSimpleCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: value ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value
              ? AppTheme.primaryColor.withOpacity(0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: CheckboxListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(right: 8, left: 4),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: value ? FontWeight.w500 : FontWeight.normal,
            color: AppTheme.textPrimary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}