import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/daily_report_body.dart';
import 'package:mudpro_desktop_app/modules/daily_report/report_topbar.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DailyReportPage extends StatefulWidget {
  const DailyReportPage({super.key});

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  int _selectedMainTab = 0; // 0: Home, 1: Report, 2: Utilities, 3: Help
  bool _isSidebarVisible = true;

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Top Bar with toggle button
          DailyReportTopBar(
            selectedTab: _selectedMainTab,
            onTabSelected: (index) {
              setState(() {
                _selectedMainTab = index;
              });
            },
            onToggleSidebar: _toggleSidebar,
          ),
          // Main Content
          Expanded(
            child: DailyReportBody(
              selectedMainTab: _selectedMainTab,
              isSidebarVisible: _isSidebarVisible,
              onToggleSidebar: _toggleSidebar,
            ),
          ),
        ],
      ),
    );
  }
}