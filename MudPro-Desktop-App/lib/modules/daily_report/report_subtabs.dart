import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/left_sidebar.dart';
import 'package:mudpro_desktop_app/modules/daily_report/wellbore_dashboard.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/alert/alert_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/concentration_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tab_bar/dailycost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/details_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/survey/survey_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/time_distribution/time_distribution_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/total_cost/daily_total_cost.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SubTabContent extends StatelessWidget {
  final int mainTabIndex;
  final int? subTabIndex;
  final int? selectedSideTab;
  final Function(int)? onSideTabSelected;
  final bool? isSidebarVisible;
  final VoidCallback? onToggleSidebar;

  const SubTabContent({
    super.key,
    required this.mainTabIndex,
    this.subTabIndex,
    this.selectedSideTab,
    this.onSideTabSelected,
    this.isSidebarVisible,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedSideTab != null) {
      // Show Home content for all main tabs
      return Row(
        children: [
          // Sidebar
          if (isSidebarVisible ?? true)
            DailySidebar(
              selectedTab: selectedSideTab!,
              onTabSelected: onSideTabSelected ?? (int index) {},
              onToggleSidebar: onToggleSidebar ?? () {},
            ),

          // Main content
          Expanded(
            child: _getHomeContent(selectedSideTab!),
          ),
        ],
      );
    } else {
      // Fallback for when selectedSideTab is null
      return const Center(
        child: Text(
          'Select a sub-tab to view content',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getSubTabData(int mainTab) {
    switch (mainTab) {
      case 1: // Report
        return [
          {
            'title': 'Generate Report',
            'description': 'Create and customize daily reports',
            'icon': Icons.description,
          },
          {
            'title': 'Export PDF',
            'description': 'Export reports in PDF format',
            'icon': Icons.picture_as_pdf,
          },
          {
            'title': 'Print',
            'description': 'Print reports directly',
            'icon': Icons.print,
          },
          {
            'title': 'Share',
            'description': 'Share reports with team',
            'icon': Icons.share,
          },
        ];
      case 2: // Utilities
        return [
          {
            'title': 'Calculators',
            'description': 'Various drilling calculators',
            'icon': Icons.calculate,
          },
          {
            'title': 'Converters',
            'description': 'Unit converters and tools',
            'icon': Icons.swap_horiz,
          },
          {
            'title': 'Templates',
            'description': 'Report templates',
            'icon': Icons.content_copy,
          },
          {
            'title': 'Settings',
            'description': 'Application settings',
            'icon': Icons.settings_applications,
          },
        ];
      case 3: // Help
        return [
          {
            'title': 'Documentation',
            'description': 'User manuals and guides',
            'icon': Icons.menu_book,
          },
          {
            'title': 'Tutorials',
            'description': 'Step-by-step tutorials',
            'icon': Icons.school,
          },
          {
            'title': 'Support',
            'description': 'Contact support team',
            'icon': Icons.support_agent,
          },
          {
            'title': 'About',
            'description': 'About MUDPRO+',
            'icon': Icons.info,
          },
        ];
      default: // Home
        return [
          {
            'title': 'Export to HYDPRO',
            'description': 'Export data to HYDPRO system',
            'icon': Icons.upload_file,
          },
          {
            'title': 'Go to Input',
            'description': 'Navigate to input section',
            'icon': Icons.input,
          },
          {
            'title': 'Options',
            'description': 'Configuration options',
            'icon': Icons.settings,
          },
        ];
    }
  }

  Widget _getTabContent(int mainTab, int subTab) {
    switch (mainTab) {
      case 0: // Home
        return _buildHomeSubTabContent(subTab);
      case 1: // Report
        return _buildReportSubTabContent(subTab);
      case 2: // Utilities
        return _buildUtilitiesSubTabContent(subTab);
      case 3: // Help
        return _buildHelpSubTabContent(subTab);
      default:
        return const Center(child: Text('Content not available'));
    }
  }

  Widget _getHomeContent(int selectedSideTab) {
    switch (selectedSideTab) {
      case 0:
        return const WellboreDashboard();
      case 1:
        return const DetailsTabView();
      case 2:
        return const DailyCostTabView();
      case 3:
        return const DailyTotalCostPage();
      case 4:
        return const ConcentrationPage();
      case 5:
        return const TimeDistributionPage();
      case 6:
        return const SurveyPage();
      case 7:
        return const AlertMainTabPage();
      default:
        return const WellboreDashboard();
    }
  }

  Widget _buildHomeSubTabContent(int subTab) {
    switch (subTab) {
      case 0: // Export to HYDPRO
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.cloud_upload, size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 20),
              Text(
                'Export to HYDPRO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Export your drilling data to HYDPRO system for further analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload),
                label: const Text('Export Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        );
      // case 2: // Options
      //   return DailyreportOptionsPage();
      default:
        return Container();
    }
  }

  Widget _buildReportSubTabContent(int subTab) {
    // Similar implementation for Report sub-tabs
    return Center(
      child: Text(
        'Report - Sub Tab ${subTab + 1} Content',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildUtilitiesSubTabContent(int subTab) {
    // Similar implementation for Utilities sub-tabs
    return Center(
      child: Text(
        'Utilities - Sub Tab ${subTab + 1} Content',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildHelpSubTabContent(int subTab) {
    // Similar implementation for Help sub-tabs
    return Center(
      child: Text(
        'Help - Sub Tab ${subTab + 1} Content',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}