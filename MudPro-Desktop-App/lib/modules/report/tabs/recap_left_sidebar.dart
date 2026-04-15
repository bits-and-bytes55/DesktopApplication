import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class RecapLeftSidebar extends StatefulWidget {
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onToggleSidebar;

  const RecapLeftSidebar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onToggleSidebar,
  });

  @override
  State<RecapLeftSidebar> createState() => _RecapLeftSidebarState();
}

class _RecapLeftSidebarState extends State<RecapLeftSidebar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: _collapsed ? 60 : 200,
        maxWidth: _collapsed ? 60 : 200,
      ),
      child: Container(
        width: _collapsed ? 60 : 200,
        decoration: BoxDecoration(
          color: AppTheme.darkPrimaryColor,
          border: Border(
            right: BorderSide(
              color: Colors.grey.shade800,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(2, 0),
            ),
          ],
        ),
      child: Column(
        children: [
          // Sidebar Header with Toggle Button
          SizedBox(
            height: 48,
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isNarrow = constraints.maxWidth < 60;
                return Container(
                  padding: isNarrow ? EdgeInsets.zero : (_collapsed ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12)),
                  decoration: BoxDecoration(
                    color: AppTheme.darkPrimaryColor.withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade800,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isNarrow && !_collapsed)
                        Flexible(
                          child: Text(
                            "Navigation",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _collapsed = !_collapsed;
                          });
                        },
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: Icon(
                            _collapsed ? Icons.chevron_right : Icons.chevron_left,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Sidebar Items
          Expanded(
            child: ListView(
              children: [
                _SideItem(
                  title: "Summary",
                  icon: Icons.dashboard_outlined,
                  selected: widget.selectedTab == 0,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(0),
                ),
                _SideItem(
                  title: "Cost Distribution",
                  icon: Icons.list_alt_outlined,
                  selected: widget.selectedTab == 1,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(1),
                ),
                _SideItem(
                  title: "Daily Cost",
                  icon: Icons.attach_money_outlined,
                  selected: widget.selectedTab == 2,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(2),
                ),
                _SideItem(
                  title: "Depth Cost",
                  icon: Icons.account_balance_wallet_outlined,
                  selected: widget.selectedTab == 3,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(3),
                ),
                _SideItem(
                  title: "Cum. Cost",
                  icon: Icons.pie_chart_outline,
                  selected: widget.selectedTab == 4,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(4),
                ),
                _SideItem(
                  title: "Drilling Data",
                  icon: Icons.access_time_outlined,
                  selected: widget.selectedTab == 5,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(5),
                ),
                _SideItem(
                  title: "Mud Prop.",
                  icon: Icons.map_outlined,
                  selected: widget.selectedTab == 6,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(6),
                ),
                _SideItem(
                  title: "Hydraulics",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Solids",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Volume",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Usage",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Concentration",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Time Distribution",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "SCE",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Bit",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Remarks",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Interval",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Survey",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
                _SideItem(
                  title: "Customized",
                  icon: Icons.notifications_active_outlined,
                  selected: widget.selectedTab == 7,
                  collapsed: _collapsed,
                  onTap: () => widget.onTabSelected(7),
                ),
              ],
            ),
          ),
          
          // Sidebar Footer
          Container(
            height: 48,
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isNarrow = constraints.maxWidth < 60;
                return Container(
                  padding: isNarrow ? EdgeInsets.zero : (_collapsed ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12)),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade800,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!isNarrow && !_collapsed)
                        Expanded(
                          child: Text(
                            "Version 2.1.0",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {},
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: Icon(
                            Icons.help_outline,
                            size: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _SideItem({
    required this.title,
    required this.icon,
    this.selected = false,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.3) : Colors.transparent,
          border: selected
              ? Border(
                  left: BorderSide(
                    color: AppTheme.accentColor,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isNarrow = constraints.maxWidth < 60;
            return Container(
              padding: isNarrow ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: collapsed ? 0 : 16),
              alignment: Alignment.centerLeft,
              child: ClipRect(
                child: Row(
                  mainAxisAlignment: isNarrow ? MainAxisAlignment.center : (collapsed ? MainAxisAlignment.center : MainAxisAlignment.start),
                  children: [
                    Icon(
                      icon,
                      size: isNarrow ? 16 : 18,
                      color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                    ),
                    if (!isNarrow && !collapsed) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
