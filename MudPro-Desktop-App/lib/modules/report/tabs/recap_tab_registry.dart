import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/sce_view.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_view.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/remarks_tab_content.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/tabs/option_detail_report.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/tabs/option_report_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/concentration_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tabs/dailycost_table_usage.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/details_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/survey/survey_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/time_distribution/time_distribution_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/wellbore_dashboard.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cost_dist/tab_bar/cost_dist_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cum_cost/tab_bar/recap_cum_cost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/depth_cost/tab_bar/depth_cost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/drilling_data/tab_bar/drilling_data_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/mud_prop/tab_bar/mud_prop_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/recap_daily_cost/tab_bar/recap_dailycost_tab_view.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class RecapTabItem {
  final String title;
  final IconData icon;
  final Widget Function() builder;

  const RecapTabItem({
    required this.title,
    required this.icon,
    required this.builder,
  });
}

final List<RecapTabItem> recapTabItems = [
  RecapTabItem(
    title: 'Summary',
    icon: Icons.dashboard_outlined,
    builder: () => const WellboreDashboard(),
  ),
  RecapTabItem(
    title: 'Cost Distribution',
    icon: Icons.pie_chart_outline,
    builder: () => const CostDistTabView(),
  ),
  RecapTabItem(
    title: 'Daily Cost',
    icon: Icons.receipt_long_outlined,
    builder: () => const RecapDailycostTabView(),
  ),
  RecapTabItem(
    title: 'Depth Cost',
    icon: Icons.stacked_line_chart_outlined,
    builder: () => const DepthCostTabView(),
  ),
  RecapTabItem(
    title: 'Cum. Cost',
    icon: Icons.show_chart_outlined,
    builder: () => const RecapCumcostTabView(),
  ),
  RecapTabItem(
    title: 'Drilling Data',
    icon: Icons.engineering_outlined,
    builder: () => const DrillingDataTabView(),
  ),
  RecapTabItem(
    title: 'Mud Prop.',
    icon: Icons.opacity_outlined,
    builder: () => const MudPropTabView(),
  ),
  RecapTabItem(
    title: 'Hydraulics',
    icon: Icons.water_drop_outlined,
    builder: () => const _RecapHydraulicsView(),
  ),
  RecapTabItem(
    title: 'Solids',
    icon: Icons.scatter_plot_outlined,
    builder: () => const _RecapSolidsView(),
  ),
  RecapTabItem(
    title: 'Volume',
    icon: Icons.local_shipping_outlined,
    builder: () => const _RecapVolumeView(),
  ),
  RecapTabItem(
    title: 'Usage',
    icon: Icons.inventory_2_outlined,
    builder: () => const DailyCostTableUsagePage(),
  ),
  RecapTabItem(
    title: 'Concentration',
    icon: Icons.science_outlined,
    builder: () => const ConcentrationPage(),
  ),
  RecapTabItem(
    title: 'Time Distribution',
    icon: Icons.schedule_outlined,
    builder: () => const TimeDistributionPage(),
  ),
  RecapTabItem(
    title: 'SCE',
    icon: Icons.precision_manufacturing_outlined,
    builder: () => const SceView(),
  ),
  RecapTabItem(
    title: 'Bit',
    icon: Icons.construction_outlined,
    builder: () => const _RecapBitView(),
  ),
  RecapTabItem(
    title: 'Remarks',
    icon: Icons.sticky_note_2_outlined,
    builder: () => const RemarksView(),
  ),
  RecapTabItem(
    title: 'Interval',
    icon: Icons.timeline_outlined,
    builder: () => const IntervalView(),
  ),
  RecapTabItem(
    title: 'Survey',
    icon: Icons.explore_outlined,
    builder: () => const SurveyPage(),
  ),
  RecapTabItem(
    title: 'Customized',
    icon: Icons.tune_outlined,
    builder: () => const _RecapCustomizedView(),
  ),
];

Widget buildRecapTabContent(int index) {
  if (index < 0 || index >= recapTabItems.length) {
    return recapTabItems.first.builder();
  }
  return recapTabItems[index].builder();
}

class _RecapHydraulicsView extends StatelessWidget {
  const _RecapHydraulicsView();

  @override
  Widget build(BuildContext context) {
    return const _RecapSectionShell(
      title: 'Hydraulics',
      subtitle:
          'Annular hydraulics recap is available here without touching the existing daily report workflow.',
      child: SizedBox(height: 380, child: AnnularHydraulicsTable()),
    );
  }
}

class _RecapSolidsView extends StatelessWidget {
  const _RecapSolidsView();

  @override
  Widget build(BuildContext context) {
    return const _RecapSectionShell(
      title: 'Solids',
      subtitle:
          'Solids analysis is surfaced as a dedicated recap tab so it can be reviewed independently.',
      child: SizedBox(
        height: 520,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SolidsAnalysisTable()],
        ),
      ),
    );
  }
}

class _RecapVolumeView extends StatelessWidget {
  const _RecapVolumeView();

  @override
  Widget build(BuildContext context) {
    return const _RecapSectionShell(
      title: 'Volume',
      subtitle:
          'Volume recap mirrors the current details-tab volume breakdown and stays isolated from operation screens.',
      child: SizedBox(
        height: 420,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [VolumeTable()],
        ),
      ),
    );
  }
}

class _RecapBitView extends StatelessWidget {
  const _RecapBitView();

  @override
  Widget build(BuildContext context) {
    return const _RecapSectionShell(
      title: 'Bit',
      subtitle:
          'Bit hydraulics are exposed as a separate recap view for the same focused review pattern as the old app.',
      child: SizedBox(
        height: 420,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [BitHydraulicsTable()],
        ),
      ),
    );
  }
}

class _RecapCustomizedView extends StatelessWidget {
  const _RecapCustomizedView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        color: AppTheme.backgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customized',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report customization options are grouped here so recap output settings stay in one place.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TabBar(
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: const [
                        Tab(text: 'Daily Report'),
                        Tab(text: 'Detail Report'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [DailyReportOptionPage(), DetailReportPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapSectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _RecapSectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
