import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/dailyreport_options_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/left_sidebar.dart';
import 'package:mudpro_desktop_app/modules/daily_report/report_subtabs.dart';
import 'package:mudpro_desktop_app/modules/daily_report/wellbore_dashboard.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/alert/alert_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/concentration_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tab_bar/dailycost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/details_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/daily_cost_productview.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/survey/survey_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/time_distribution/time_distribution_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/total_cost/daily_total_cost.dart';
import 'package:mudpro_desktop_app/modules/options/options_page.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DailyReportBody extends StatefulWidget {
  final int selectedMainTab;
  final bool isSidebarVisible;
  final VoidCallback onToggleSidebar;

  const DailyReportBody({
    super.key,
    required this.selectedMainTab,
    required this.isSidebarVisible,
    required this.onToggleSidebar,
  });

  @override
  State<DailyReportBody> createState() => _DailyReportBodyState();
}

class _DailyReportBodyState extends State<DailyReportBody> {
  int _selectedSideTab = 0;
  int _selectedSubTab = 0; // For sub-tabs under main tabs

  // Sub-tabs configuration for each main tab
  final Map<int, List<Map<String, dynamic>>> _mainTabSubTabs = {
    0: [ // Home
      {'title': 'Export to HYDPRO', 'icon': Icons.upload_file},
      {'title': 'Go to Input', 'icon': Icons.input},
      {'title': 'Options', 'icon': Icons.settings},
    ],
    1: [ // Report
      {'title': 'Generate Report', 'icon': Icons.description},
      {'title': 'Export PDF', 'icon': Icons.picture_as_pdf},
      {'title': 'Print', 'icon': Icons.print},
      {'title': 'Share', 'icon': Icons.share},
    ],
    2: [ // Utilities
      {'title': 'Calculators', 'icon': Icons.calculate},
      {'title': 'Converters', 'icon': Icons.swap_horiz},
      {'title': 'Templates', 'icon': Icons.content_copy},
      {'title': 'Settings', 'icon': Icons.settings_applications},
    ],
    3: [ // Help
      {'title': 'Documentation', 'icon': Icons.menu_book},
      {'title': 'Tutorials', 'icon': Icons.school},
      {'title': 'Support', 'icon': Icons.support_agent},
      {'title': 'About', 'icon': Icons.info},
    ],
  };

  void _onSideTabSelected(int index) {
    setState(() {
      _selectedSideTab = index;
    });
  }

  void _onSubTabSelected(int index) {
    if (widget.selectedMainTab == 0 && index == 2) { // Options sub-tab in Home tab
      _navigateToOptions(context);
    } else {
      setState(() {
        _selectedSubTab = index;
      });
    }
  }

  void _navigateToOptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DailyreportOptionsPage()),
    );
  }

  Widget _getSelectedTabContent() {
    if (widget.selectedMainTab == 0) {
      return SubTabContent(
        mainTabIndex: widget.selectedMainTab,
        subTabIndex: _selectedSubTab,
        selectedSideTab: _selectedSideTab,
        onSideTabSelected: _onSideTabSelected,
        isSidebarVisible: widget.isSidebarVisible,
        onToggleSidebar: widget.onToggleSidebar,
      );
    } else {
      return SubTabContent(
        mainTabIndex: widget.selectedMainTab,
        subTabIndex: _selectedSubTab,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tabs bar for all main tabs
        Container(
          height: 48,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (int i = 0; i < _mainTabSubTabs[widget.selectedMainTab]!.length; i++)
                _SubTab(
                  title: _mainTabSubTabs[widget.selectedMainTab]![i]['title'] as String,
                  icon: _mainTabSubTabs[widget.selectedMainTab]![i]['icon'] as IconData,
                  selected: _selectedSubTab == i,
                  onTap: () => _onSubTabSelected(i),
                ),
            ],
          ),
        ),

        // Main content area (always Home content)
        Expanded(
          child: _getSelectedTabContent(),
        ),
      ],
    );
  }
}

class _SubTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SubTab({
    required this.title,
    required this.icon,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppTheme.primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppTheme.primaryColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}