import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DailyReportTopBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onToggleSidebar;

  const DailyReportTopBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Logo and Tabs
          Row(
            children: [
            

              // Main Tabs
              Row(
                children: [
                  _TopTab(
                    title: "Home",
                    selected: selectedTab == 0,
                    icon: Icons.home_outlined,
                    onTap: () => onTabSelected(0),
                  ),
                  _TopTab(
                    title: "Report",
                    selected: selectedTab == 1,
                    icon: Icons.assessment_outlined,
                    onTap: () => onTabSelected(1),
                  ),
                  _TopTab(
                    title: "Utilities",
                    selected: selectedTab == 2,
                    icon: Icons.build_outlined,
                    onTap: () => onTabSelected(2),
                  ),
                  _TopTab(
                    title: "Help",
                    selected: selectedTab == 3,
                    icon: Icons.help_outline,
                    onTap: () => onTabSelected(3),
                  ),
                ],
              ),
            ],
          ),

          // Center: Page Title
          Flexible(
            child: Text(
              "Daily Report Dashboard",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Right side: Close Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String title;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _TopTab({
    required this.title,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}