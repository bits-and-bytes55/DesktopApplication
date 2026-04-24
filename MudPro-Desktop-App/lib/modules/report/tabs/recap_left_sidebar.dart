import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_tab_registry.dart';
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
    final sidebarWidth = _collapsed ? 68.0 : 220.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: sidebarWidth,
        maxWidth: sidebarWidth,
      ),
      child: Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          color: AppTheme.darkPrimaryColor,
          border: Border(
            right: BorderSide(color: Colors.grey.shade800, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 72;
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow || _collapsed ? 8 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkPrimaryColor.withValues(alpha: 0.82),
                      border: Border(
                        bottom: BorderSide(
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
                              'Recap',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        IconButton(
                          tooltip: _collapsed
                              ? 'Expand sidebar'
                              : 'Collapse sidebar',
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                          onPressed: () {
                            setState(() {
                              _collapsed = !_collapsed;
                            });
                          },
                          icon: Icon(
                            _collapsed
                                ? Icons.chevron_right
                                : Icons.chevron_left,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 18,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hide sidebar',
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                          onPressed: widget.onToggleSidebar,
                          icon: Icon(
                            Icons.vertical_split,
                            color: Colors.white.withValues(alpha: 0.72),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: recapTabItems.length,
                itemBuilder: (context, index) {
                  final item = recapTabItems[index];
                  return _SideItem(
                    title: item.title,
                    icon: item.icon,
                    selected: widget.selectedTab == index,
                    collapsed: _collapsed,
                    onTap: () => widget.onTabSelected(index),
                  );
                },
              ),
            ),
            Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: _collapsed ? 8 : 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade800, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: _collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!_collapsed)
                    Flexible(
                      child: Text(
                        '${recapTabItems.length} tabs',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.list_alt_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.28)
                : Colors.transparent,
            border: selected
                ? Border(
                    left: BorderSide(color: AppTheme.accentColor, width: 3),
                  )
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 72;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow || collapsed ? 0 : 16,
                ),
                child: Row(
                  mainAxisAlignment: isNarrow || collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: isNarrow ? 17 : 18,
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.72),
                    ),
                    if (!isNarrow && !collapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
