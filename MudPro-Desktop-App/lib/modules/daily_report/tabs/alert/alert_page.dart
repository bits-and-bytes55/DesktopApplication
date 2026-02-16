import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/alert/tabs/alert_product_inventory_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/alert/tabs/alert_summary_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/alert/tabs/alert_table.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/alert/tabs/alert_usage_tab.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertMainTabPage extends StatefulWidget {
  const AlertMainTabPage({super.key});

  @override
  State<AlertMainTabPage> createState() => _AlertMainTabPageState();
}

class _AlertMainTabPageState extends State<AlertMainTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _tab(String text, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // ================= COMPACT TAB BAR =================
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // TITLE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, 
                          size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Alert Analysis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                
                // TABS
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 2,
                    labelPadding: EdgeInsets.zero,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.textSecondary,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: [
                      _tab('Summary', Icons.summarize),
                      _tab('Usage', Icons.show_chart),
                      _tab('Inventory', Icons.inventory),
                      _tab('Table', Icons.table_chart),
                    ],
                  ),
                ),
                
                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '4 Tabs',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= TAB CONTENT =================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundColor.withOpacity(0.3),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: const [
                  AlertSummaryPage(),
                  AlertUsagePage(),
                  AlertProductInventoryPage(),
                  AlertUsagePredictionPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}