import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/controller/dailyreport_option_report_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DailyReportOptionPage extends StatelessWidget {
  DailyReportOptionPage({super.key});

  final controller = Get.put(DailyReportOptionController());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      height: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.settings_outlined,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Daily Report Options',
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
            const SizedBox(height: 24),

            // Main Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Sections
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionCard(
                        title: 'Daily Report Page',
                        icon: Icons.description_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRadioOption('1 Page', controller.pageCount),
                            _buildRadioOption('2 Page', controller.pageCount),
                            _buildRadioOption('3 Page', controller.pageCount),
                            const SizedBox(height: 8),
                            _buildCheckboxOption(
                              'Show Used Only',
                              controller.showUsedOnly,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSectionCard(
                        title: 'Report Page Size',
                        icon: Icons.aspect_ratio_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRadioOption('Legal', controller.pageSize),
                            _buildRadioOption('Letter', controller.pageSize),
                            _buildRadioOption('A4', controller.pageSize),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Right Column - Daily Report Section
                Expanded(
                  child: _buildSectionCard(
                    title: 'Daily Report',
                    icon: Icons.summarize_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCheckboxOption(
                          'Product Price',
                          controller.productPrice,
                        ),
                        _buildCheckboxOption(
                          'Product Cost',
                          controller.productCost,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Total Cost Section
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Total Cost',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRadioOption(
                                'Previous Total Cost',
                                controller.totalCostType,
                              ),
                              _buildRadioOption(
                                'Interval Total Cost',
                                controller.totalCostType,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildCheckboxOption(
                          'CDC Annular Hydraulic Table',
                          controller.cdcAnnularHydraulicTable,
                        ),
                        _buildCheckboxOption(
                          'Detailed Pit Information',
                          controller.detailedPitInformation,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================== SECTION CARD ==================
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Section Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ================== RADIO OPTION ==================
  Widget _buildRadioOption(String text, RxString group) {
    return Obx(() {
      final isSelected = group.value == text;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Transform.scale(
              scale: 1.1,
              child: Radio<String>(
                value: text,
                groupValue: group.value,
                onChanged: (val) => group.value = val!,
                fillColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return AppTheme.primaryColor;
                    }
                    return Colors.grey.shade400;
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ================== CHECKBOX OPTION ==================
  Widget _buildCheckboxOption(String text, RxBool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.1,
            child: Obx(() => Checkbox(
                  value: value.value,
                  onChanged: (val) => value.value = val!,
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
                  side: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.5,
                  ),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}