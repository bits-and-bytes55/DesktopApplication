import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/controller/detail_report_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DetailReportPage extends StatelessWidget {
  DetailReportPage({super.key});

  final controller = Get.put(DetailReportController());

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
                  Icons.list_alt_outlined,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Detail Report Options',
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
          const SizedBox(height: 20),

          // Main Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCheckbox('Summary', controller.summary),
                        _buildCheckbox('Detail', controller.detail),

                        const SizedBox(height: 12),
                        _buildGroup('Daily Cost', controller.dailyCost, [
                          _buildCheckbox('Product Chart', controller.productChart, indent: 20),
                          _buildCheckbox('Others Chart', controller.othersChart, indent: 20),
                          _buildCheckbox('Table - Usage', controller.tableUsage, indent: 20),
                          _buildCheckbox('Table', controller.table, indent: 20),
                        ]),

                        const SizedBox(height: 12),
                        _buildGroup('Total Cost', controller.totalCost, [
                          _buildCheckbox('Graph', controller.totalCostGraph, indent: 20),
                          _buildCheckbox('Table', controller.totalCostTable, indent: 20),
                        ]),

                        const SizedBox(height: 12),
                        _buildGroup('Concentration', controller.concentration, [
                          _buildCheckbox('Graph', controller.concGraph, indent: 20),
                          _buildCheckbox('Table - Current', controller.tableCurrent, indent: 20),
                          _buildCheckbox('Table - History', controller.tableHistory, indent: 20),
                        ]),

                        const SizedBox(height: 12),
                        _buildGroup('Time Distribution', controller.timeDistribution, [
                          _buildCheckbox('Graph', controller.timeGraph, indent: 20),
                          _buildCheckbox('Table', controller.timeTable, indent: 20),
                        ]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Right Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGroup('Survey', controller.survey, [
                          _buildCheckbox('Graph', controller.surveyGraph, indent: 20),
                          _buildCheckbox('Table - Actual', controller.tableActual, indent: 20),
                          _buildCheckbox('Table - Planned', controller.tablePlanned, indent: 20),
                        ]),

                        const SizedBox(height: 12),
                        _buildGroup('Alert', controller.alert, [
                          _buildCheckbox('Summary', controller.alertSummary, indent: 20),
                          _buildCheckbox('Usage', controller.alertUsage, indent: 20),
                          _buildCheckbox('Inventory', controller.alertInventory, indent: 20),
                          _buildCheckbox('Table', controller.alertTable, indent: 20),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== GROUP ==================
  Widget _buildGroup(String title, RxBool value, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
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
        ...children,
      ],
    );
  }

  // ================== CHECKBOX ==================
  Widget _buildCheckbox(String text, RxBool value, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 4),
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