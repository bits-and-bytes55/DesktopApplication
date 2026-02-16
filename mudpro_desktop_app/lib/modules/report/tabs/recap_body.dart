import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/wellbore_dashboard.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/alert/alert_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/concentration_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tab_bar/dailycost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/details_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/survey/survey_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/time_distribution/time_distribution_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/total_cost/daily_total_cost.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cost_dist/tab_bar/cost_dist_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cum_cost/tab_bar/recap_cum_cost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/depth_cost/tab_bar/depth_cost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/drilling_data/tab_bar/drilling_data_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/mud_prop/tab_bar/mud_prop_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/recap_daily_cost/tab_bar/recap_dailycost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_left_sidebar.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class RecapBody extends StatefulWidget {
  final int selectedMainTab;
  final bool isSidebarVisible;
  final VoidCallback onToggleSidebar;

  const RecapBody({
    super.key,
    required this.selectedMainTab,
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

  Widget _getHomeContent(int selectedSideTab) {
    switch (selectedSideTab) {
      case 0:
        return const WellboreDashboard();
      case 1:
        return const CostDistTabView();
      case 2:
        return const RecapDailycostTabView();
      case 3:
        return const DepthCostTabView();
      case 4:
        return const RecapCumcostTabView();
      case 5:
        return const DrillingDataTabView();
      case 6:
        return const MudPropTabView();
      // case 7:
      //   return const AlertMainTabPage();
      default:
        return const WellboreDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        if (widget.isSidebarVisible)
          RecapLeftSidebar(
            selectedTab: _selectedSideTab,
            onTabSelected: _onSideTabSelected,
            onToggleSidebar: widget.onToggleSidebar,
          ),

        // Main content
        Expanded(
          child: _getHomeContent(_selectedSideTab),
        ),
      ],
    );
  }
}


