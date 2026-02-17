import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/company_setup/tabs/operatos_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/daily_cost_productview.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tabs/daily_cost_others_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tabs/dailycost_percentagetable.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tabs/dailycost_table_usage.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cost_dist/cost_dist_productview.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cost_dist/tabs/cost_dist_others_tab.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cost_dist/tabs/cost_dist_table.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cost_dist/tabs/recap_summary_table.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class CostDistTabView extends StatefulWidget {
  const CostDistTabView({super.key});

  @override
  State<CostDistTabView> createState() => _CostDistTabViewState();
}

class _CostDistTabViewState extends State<CostDistTabView> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundColor,
            AppTheme.backgroundColor.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cost Distribution Report",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Real-time cost tracking and distribution analysis",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                "Dec 30, 2024",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.download, size: 16, color: Colors.white),
                          label: Text(
                            "Export Report",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Tab Bar - Left Aligned
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicator: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                      labelColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      unselectedLabelColor: AppTheme.textSecondary,
                      unselectedLabelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory, size: 16),
                              SizedBox(width: 6),
                              Text("Products"),
                            ],
                          ),
                        ),
                        Tab(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.category, size: 16),
                              SizedBox(width: 6),
                              Text("Others"),
                            ],
                          ),
                        ),
                        Tab(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.table_chart, size: 16),
                              SizedBox(width: 6),
                              Text("Summary"),
                            ],
                          ),
                        ),
                        Tab(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                             
                              SizedBox(width: 6),
                              Text("Table"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:  [
                /// ✅ PRODUCTS TAB
                CostDistProductview(),

                /// CATEGORIES TAB
                 CostDistOtherTab(),

                /// USAGE TABLE TAB
                CostSummaryRecapPage(),

                /// PERCENTAGE TAB
                ReportRecapTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder for other tabs
class CategoriesTabView extends StatelessWidget {
  const CategoriesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: AppTheme.primaryColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "Categories Analysis",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Coming soon...",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class UsageTableTabView extends StatelessWidget {
  const UsageTableTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_chart_outlined, size: 64, color: AppTheme.primaryColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "Usage Table",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Detailed table view under development",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class PercentageTabView extends StatelessWidget {
  const PercentageTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: AppTheme.primaryColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "Percentage Analysis",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Percentage breakdown coming soon",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}