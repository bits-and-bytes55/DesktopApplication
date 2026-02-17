import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/dailyreport_options_left_pannel.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/tabs/option_detail_report.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/tabs/summary_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/tabs/option_report_tab.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/options_left_pannel.dart';
import 'package:mudpro_desktop_app/modules/options/tabs/language_tab.dart';
import 'package:mudpro_desktop_app/modules/options/tabs/option_report_page.dart';
import 'package:mudpro_desktop_app/modules/options/tabs/unit_tab.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DailyreportOptionsPage extends StatelessWidget {
  DailyreportOptionsPage({super.key});

  final OptionsController controller = Get.put(OptionsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header with Back Button
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
          ),
          
          // Main Content
          Expanded(
            child: Row(
              children: [
                // Left Panel
                Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: const DailyreportOptionsLeftPannel(),
                ),
                
                // Right Panel
                Expanded(
                  child: Obx(() {
                    final selectedTab = controller.selectedTab.value;
                    switch (selectedTab) {
                      case 0:
                        return ReportOptionSummaryPage();
                      case 1:
                        return DailyReportOptionPage();
                      case 2:
                        return DetailReportPage();
                      default:
                        return  ReportOptionSummaryPage();
                    }
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}