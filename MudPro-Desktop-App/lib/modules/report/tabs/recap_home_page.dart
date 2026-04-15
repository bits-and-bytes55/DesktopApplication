import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/daily_report_body.dart';
import 'package:mudpro_desktop_app/modules/daily_report/report_topbar.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_body.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class RecapHomePage extends StatefulWidget {
  const RecapHomePage({super.key});

  @override
  State<RecapHomePage> createState() => _RecapHomePageState();
}

class _RecapHomePageState extends State<RecapHomePage> {
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
      appBar: AppBar(
        backgroundColor: AppTheme.darkPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [

          // Main Content
          Expanded(
            child: RecapBody(
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