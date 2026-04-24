import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_body.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class RecapHomePage extends StatefulWidget {
  const RecapHomePage({super.key});

  @override
  State<RecapHomePage> createState() => _RecapHomePageState();
}

class _RecapHomePageState extends State<RecapHomePage> {
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
        leading: IconButton(
          icon: Icon(_isSidebarVisible ? Icons.menu_open : Icons.menu),
          onPressed: _toggleSidebar,
        ),
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
              isSidebarVisible: _isSidebarVisible,
              onToggleSidebar: _toggleSidebar,
            ),
          ),
        ],
      ),
    );
  }
}
