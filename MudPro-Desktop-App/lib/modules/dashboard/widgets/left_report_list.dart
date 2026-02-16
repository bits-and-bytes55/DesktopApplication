import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';

class LeftReportTree extends StatelessWidget {
  LeftReportTree({super.key});

  final c = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffF8FAFC), Color(0xffF1F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          right: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(1, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              border: Border(
                bottom: BorderSide(color: Colors.black.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_special, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Reports Explorer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // ───── UG HEADER ─────
          _clickableHeader(
            icon: Icons.account_tree,
            text: 'UG',
            id: 'UG',
          ),

          _clickableHeader(
            icon: Icons.location_on,
            text: 'UG-0293 ST',
            id: 'UG-0293-ST',
            indent: 24,
          ),

          // Divider with gradient
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ───── TREE REPORTS ─────
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 4),
              child: Obx(() => ListView.builder(
                    padding: EdgeInsets.only(bottom: 16),
                    itemCount: c.reportsTree.length,
                    itemBuilder: (context, index) {
                      return _buildDateNode(c.reportsTree[index]);
                    },
                  )),
            ),
          ),

          // ───── FOOTER NOTE ─────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black.withOpacity(0.08)),
              ),
              gradient: LinearGradient(
                colors: [Color(0xffF8F9FA), Color(0xffE9ECEF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  WidgetSpan(
                    child: Icon(Icons.info, size: 10, color: AppTheme.primaryColor),
                  ),
                  TextSpan(text: ' '),
                  TextSpan(
                    text: "New report is only for active well.",
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _clickableHeader({
    required IconData icon,
    required String text,
    required String id,
    double indent = 0,
  }) {
    return Obx(() {
      final selected = c.selectedNodeId.value == id;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => c.navigate(id),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: EdgeInsets.fromLTRB(12 + indent, 10, 12, 10),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.9),
                        AppTheme.primaryColor.withOpacity(0.7),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: selected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : Colors.transparent,
                width: 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? Colors.white : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ================= DATE NODE =================
  Widget _buildDateNode(ReportDate dateNode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => c.navigate(dateNode.date),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: dateNode.expanded
                      ? AppTheme.cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: dateNode.expanded
                        ? Colors.black.withOpacity(0.05)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: dateNode.expanded ? 0.25 : 0,
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateNode.date,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dateNode.items.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Items List
          if (dateNode.expanded)
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(left: 24, top: 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: dateNode.items.map(
                  (item) {
                    final id = '${dateNode.date}-$item';
                    return Obx(() {
                      final selected = c.selectedNodeId.value == id;

                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => c.navigate(id),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            margin: EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                              border: selected
                                  ? Border.all(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  width: selected ? 8 : 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: selected
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimary,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.arrow_right,
                                    size: 14,
                                    color: AppTheme.primaryColor,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }
}