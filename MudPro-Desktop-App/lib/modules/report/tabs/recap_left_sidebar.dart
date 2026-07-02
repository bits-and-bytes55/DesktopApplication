import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_tab_registry.dart';

const Color _recapHeaderBlue = Color(0xFF6C9BCF);
const Color _recapSidebarBackground = Color(0xFFF4F6FA);
const Color _recapSidebarSelected = Color(0xFF6C9BCF);
const Color _recapSidebarBorder = Color(0xFFB8D0EA);
const Color _recapSidebarText = Colors.black;

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
  @override
  Widget build(BuildContext context) {
    const sidebarWidth = 212.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: sidebarWidth,
        maxWidth: sidebarWidth,
      ),
      child: Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          color: _recapSidebarBackground,
          border: Border(
            right: const BorderSide(color: _recapSidebarBorder, width: 1),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 36,
              color: _recapHeaderBlue,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Hide sidebar',
                visualDensity: VisualDensity.compact,
                splashRadius: 20,
                onPressed: widget.onToggleSidebar,
                icon: const Icon(Icons.menu, color: Colors.white, size: 18),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
                itemCount: recapTabItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = recapTabItems[index];
                  return _SideItem(
                    title: item.title,
                    icon: item.icon,
                    selected: widget.selectedTab == index,
                    onTap: () => widget.onTabSelected(index),
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
  final VoidCallback onTap;

  const _SideItem({
    required this.title,
    required this.icon,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: _recapSidebarSelected.withValues(alpha: 0.35),
        highlightColor: _recapSidebarSelected.withValues(alpha: 0.18),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: selected
                ? _recapSidebarSelected
                : const Color(0xFFEAF3FC),
            border: selected
                ? const Border(
                    left: BorderSide(color: _recapSidebarSelected, width: 1),
                    top: BorderSide(color: _recapSidebarBorder, width: 1),
                    right: BorderSide(color: _recapSidebarBorder, width: 1),
                    bottom: BorderSide(color: _recapSidebarBorder, width: 1),
                  )
                : Border.all(color: _recapSidebarBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : _recapSidebarText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      color: selected ? Colors.white : _recapSidebarText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
