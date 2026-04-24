import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_left_sidebar.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_tab_registry.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class RecapBody extends StatefulWidget {
  final bool isSidebarVisible;
  final VoidCallback onToggleSidebar;

  const RecapBody({
    super.key,
    required this.isSidebarVisible,
    required this.onToggleSidebar,
  });

  @override
  State<RecapBody> createState() => _RecapBodyState();
}

class _RecapBodyState extends State<RecapBody> {
  int _selectedSideTab = 0;

  void _onSideTabSelected(int index) {
    setState(() {
      _selectedSideTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (widget.isSidebarVisible)
          RecapLeftSidebar(
            selectedTab: _selectedSideTab,
            onTabSelected: _onSideTabSelected,
            onToggleSidebar: widget.onToggleSidebar,
          ),
        if (!widget.isSidebarVisible)
          _SidebarRevealRail(onTap: widget.onToggleSidebar),

        Expanded(child: buildRecapTabContent(_selectedSideTab)),
      ],
    );
  }
}

class _SidebarRevealRail extends StatelessWidget {
  final VoidCallback onTap;

  const _SidebarRevealRail({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      color: AppTheme.darkPrimaryColor,
      child: Center(
        child: IconButton(
          tooltip: 'Show recap navigation',
          onPressed: onTap,
          icon: const Icon(Icons.menu_open, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
