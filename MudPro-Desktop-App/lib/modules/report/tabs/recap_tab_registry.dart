import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/bit/tab_bar/recap_bit_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/concentration/tab_bar/recap_concentration_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cost_dist/tab_bar/cost_dist_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/cum_cost/tab_bar/recap_cum_cost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/customized/tab_bar/recap_customized_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/depth_cost/tab_bar/depth_cost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/drilling_data/tab_bar/drilling_data_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/engineer/tab_bar/recap_engineer_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/hydraulics/tab_bar/recap_hydraulics_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/interval/tab_bar/recap_interval_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/mud_prop/tab_bar/mud_prop_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/recap_daily_cost/tab_bar/recap_dailycost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/remarks/tab_bar/recap_remarks_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/sce/tab_bar/recap_sce_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/solids/tab_bar/recap_solids_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/survey/tab_bar/recap_survey_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/time_distribution/tab_bar/recap_time_distribution_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/usage/tab_bar/recap_usage_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/volume/tab_bar/recap_volume_tab_view.dart';
import 'package:mudpro_desktop_app/modules/report/tabs/recap_summary_page.dart';

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
    icon: Icons.grid_view_rounded,
    builder: () => RecapSummaryPage(),
  ),
  RecapTabItem(
    title: 'Cost Distribution',
    icon: Icons.pie_chart_outline_rounded,
    builder: () => const CostDistTabView(),
  ),
  RecapTabItem(
    title: 'Daily Cost',
    icon: Icons.receipt_long_outlined,
    builder: () => const RecapDailycostTabView(),
  ),
  RecapTabItem(
    title: 'Depth Cost',
    icon: Icons.show_chart_rounded,
    builder: () => const DepthCostTabView(),
  ),
  RecapTabItem(
    title: 'Cum. Cost',
    icon: Icons.timeline_rounded,
    builder: () => const RecapCumcostTabView(),
  ),
  RecapTabItem(
    title: 'Drilling Data',
    icon: Icons.manage_accounts_outlined,
    builder: () => const DrillingDataTabView(),
  ),
  RecapTabItem(
    title: 'Mud Prop.',
    icon: Icons.water_drop_outlined,
    builder: () => const MudPropTabView(),
  ),
  RecapTabItem(
    title: 'Hydraulics',
    icon: Icons.opacity_outlined,
    builder: () => const RecapHydraulicsTabView(),
  ),
  RecapTabItem(
    title: 'Solids',
    icon: Icons.bubble_chart_outlined,
    builder: () => const RecapSolidsTabView(),
  ),
  RecapTabItem(
    title: 'Volume',
    icon: Icons.local_shipping_outlined,
    builder: () => const RecapVolumeTabView(),
  ),
  RecapTabItem(
    title: 'Usage',
    icon: Icons.inventory_2_outlined,
    builder: () => const RecapUsageTabView(),
  ),
  RecapTabItem(
    title: 'Concentration',
    icon: Icons.science_outlined,
    builder: () => const RecapConcentrationTabView(),
  ),
  RecapTabItem(
    title: 'Time Distribution',
    icon: Icons.access_time_rounded,
    builder: () => const RecapTimeDistributionTabView(),
  ),
  RecapTabItem(
    title: 'SCE',
    icon: Icons.precision_manufacturing_outlined,
    builder: () => const RecapSceTabView(),
  ),
  RecapTabItem(
    title: 'Bit',
    icon: Icons.handyman_outlined,
    builder: () => const RecapBitTabView(),
  ),
  RecapTabItem(
    title: 'Remarks',
    icon: Icons.note_alt_outlined,
    builder: () => const RecapRemarksTabView(),
  ),
  RecapTabItem(
    title: 'Interval',
    icon: Icons.multiline_chart_outlined,
    builder: () => const RecapIntervalTabView(),
  ),
  RecapTabItem(
    title: 'Survey',
    icon: Icons.explore_outlined,
    builder: () => const RecapSurveyTabView(),
  ),
  RecapTabItem(
    title: 'Customized',
    icon: Icons.tune_outlined,
    builder: () => const RecapCustomizedTabView(),
  ),
  RecapTabItem(
    title: 'Engineer',
    icon: Icons.engineering_outlined,
    builder: () => const RecapEngineerTabView(),
  ),
];

Widget buildRecapTabContent(int index) {
  if (index < 0 || index >= recapTabItems.length) {
    return recapTabItems.first.builder();
  }
  return recapTabItems[index].builder();
}
