import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_tab_registry.dart';

const Color _recapHeaderBlue = Color(0xFF3F5F8E);
const Color _recapSidebarBackground = Color(0xFFF3F3F3);
const Color _recapSidebarSelected = Color(0xFFC6D7F4);
const Color _recapSidebarBorder = Color(0xFFD8D8D8);
const Color _recapSidebarText = Color(0xFF0F2745);

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
              height: 78,
              color: _recapHeaderBlue,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Hide sidebar',
                visualDensity: VisualDensity.compact,
                splashRadius: 20,
                onPressed: widget.onToggleSidebar,
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                itemCount: recapTabItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
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
          height: 42,
          decoration: BoxDecoration(
            color: selected ? _recapSidebarSelected : Colors.white,
            border: selected
                ? const Border(
                    left: BorderSide(color: Colors.black, width: 4),
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
                Icon(icon, size: 22, color: _recapSidebarText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _recapSidebarText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
