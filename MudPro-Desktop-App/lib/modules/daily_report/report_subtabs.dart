import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/home_tabs/dailyreport_options/controller/wbm_report_controller.dart';
import 'package:mudpro_desktop_app/modules/daily_report/left_sidebar.dart';
import 'package:mudpro_desktop_app/modules/daily_report/wellbore_dashboard.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/alert/alert_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/concentration_tab/concentration_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/tab_bar/dailycost_tab_view.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/details_tab.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/survey/survey_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/time_distribution/time_distribution_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/total_cost/daily_total_cost.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';


class SubTabContent extends StatefulWidget {
  final int mainTabIndex;
  final int? subTabIndex;
  final int? selectedSideTab;
  final Function(int)? onSideTabSelected;
  final bool? isSidebarVisible;
  final VoidCallback? onToggleSidebar;

  const SubTabContent({
    super.key,
    required this.mainTabIndex,
    this.subTabIndex,
    this.selectedSideTab,
    this.onSideTabSelected,
    this.isSidebarVisible,
    this.onToggleSidebar,
  });

  @override
  State<SubTabContent> createState() => _SubTabContentState();
}

class _SubTabContentState extends State<SubTabContent> {
  bool _wbmLoading = false;

  @override
  void initState() {
    super.initState();
    _triggerWbmIfNeeded(widget.mainTabIndex, widget.subTabIndex);
  }

  @override
  void didUpdateWidget(SubTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger only when WBM tab is freshly selected
    if (widget.mainTabIndex == 1 &&
        widget.subTabIndex == 5 &&
        !(oldWidget.mainTabIndex == 1 && oldWidget.subTabIndex == 5)) {
      _triggerWbmIfNeeded(widget.mainTabIndex, widget.subTabIndex);
    }
  }

  void _triggerWbmIfNeeded(int mainTab, int? subTab) {
    if (mainTab == 1 && subTab == 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _downloadWbmReport();
      });
    }
  }

  Future<void> _downloadWbmReport() async {
    if (_wbmLoading) return;
    setState(() => _wbmLoading = true);

    // Show loading popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(width: 20),
                const Text(
                  'Generating WBM Report...',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ExportController.downloadAndOpenInventoryReport();
      // Close popup on success
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      // Close popup then show error
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _wbmLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedSideTab != null) {
      // Show Home content for all main tabs — UNCHANGED
      return Row(
        children: [
          // Sidebar
          if (widget.isSidebarVisible ?? true)
            DailySidebar(
              selectedTab: widget.selectedSideTab!,
              onTabSelected: widget.onSideTabSelected ?? (int index) {},
              onToggleSidebar: widget.onToggleSidebar ?? () {},
            ),

          // Main content
          Expanded(
            child: _getHomeContent(widget.selectedSideTab!),
          ),
        ],
      );
    } else {
      // Route to correct tab builder
      switch (widget.mainTabIndex) {
        case 0:
          return _buildHomeSubTabContent(widget.subTabIndex ?? 0);
        case 1:
          return _buildReportSubTabContent(widget.subTabIndex ?? 0);
        case 2:
          return _buildUtilitiesSubTabContent(widget.subTabIndex ?? 0);
        case 3:
          return _buildHelpSubTabContent(widget.subTabIndex ?? 0);
        default:
          return const Center(child: Text('Content not available'));
      }
    }
  }

  // ── Home sidebar content — UNCHANGED ──────────────────────────

  Widget _getHomeContent(int selectedSideTab) {
    switch (selectedSideTab) {
      case 0:
        return const WellboreDashboard();
      case 1:
        return const DetailsTabView();
      case 2:
        return const DailyCostTabView();
      case 3:
        return const DailyTotalCostPage();
      case 4:
        return const ConcentrationPage();
      case 5:
        return const TimeDistributionPage();
      case 6:
        return const SurveyPage();
      case 7:
        return const AlertMainTabPage();
      default:
        return const WellboreDashboard();
    }
  }

  // ── Home sub-tab content — UNCHANGED ──────────────────────────

  Widget _buildHomeSubTabContent(int subTab) {
    switch (subTab) {
      case 0: // Export to HYDPRO
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.cloud_upload, size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 20),
              Text(
                'Export to HYDPRO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Export your drilling data to HYDPRO system for further analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload),
                label: const Text('Export Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        );
      // case 2: // Options
      //   return DailyreportOptionsPage();
      default:
        return Container();
    }
  }

  // ── Report sub-tabs — WBM (index 5) added, rest UNCHANGED ─────

  Widget _buildReportSubTabContent(int subTab) {
    if (subTab == 5) {
      // WBM Report: show loading spinner while downloading, blank after done
      return Center(
        child: _wbmLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Generating WBM Report...',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      );
    }

    // All other report sub-tabs — UNCHANGED
    return Center(
      child: Text(
        'Report - Sub Tab ${subTab + 1} Content',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  // ── Utilities & Help — UNCHANGED ──────────────────────────────

  Widget _buildUtilitiesSubTabContent(int subTab) {
    return Center(
      child: Text(
        'Utilities - Sub Tab ${subTab + 1} Content',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildHelpSubTabContent(int subTab) {
    return Center(
      child: Text(
        'Help - Sub Tab ${subTab + 1} Content',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  // ── _getSubTabData — UNCHANGED ─────────────────────────────────

  List<Map<String, dynamic>> _getSubTabData(int mainTab) {
    switch (mainTab) {
      case 1:
        return [
          {'title': 'Daily Report', 'description': 'Create and customize daily reports', 'icon': Icons.description},
          {'title': 'Detail Report', 'description': 'Export reports in PDF format', 'icon': Icons.picture_as_pdf},
          {'title': 'Safety Card', 'description': 'Print reports directly', 'icon': Icons.print},
          {'title': 'Hydraulics Report', 'description': 'Share reports with team', 'icon': Icons.share},
          {'title': 'WITSML Report', 'description': 'Share reports with team', 'icon': Icons.share},
          {'title': 'WBM Report', 'description': 'Share reports with team', 'icon': Icons.generating_tokens},
        ];
      case 2:
        return [
          {'title': 'Calculators', 'description': 'Various drilling calculators', 'icon': Icons.calculate},
          {'title': 'Converters', 'description': 'Unit converters and tools', 'icon': Icons.swap_horiz},
          {'title': 'Templates', 'description': 'Report templates', 'icon': Icons.content_copy},
          {'title': 'Settings', 'description': 'Application settings', 'icon': Icons.settings_applications},
        ];
      case 3:
        return [
          {'title': 'Documentation', 'description': 'User manuals and guides', 'icon': Icons.menu_book},
          {'title': 'Tutorials', 'description': 'Step-by-step tutorials', 'icon': Icons.school},
          {'title': 'Support', 'description': 'Contact support team', 'icon': Icons.support_agent},
          {'title': 'About', 'description': 'About MUDPRO+', 'icon': Icons.info},
        ];
      default:
        return [
          {'title': 'Export to HYDPRO', 'description': 'Export data to HYDPRO system', 'icon': Icons.upload_file},
          {'title': 'Go to Input', 'description': 'Navigate to input section', 'icon': Icons.input},
          {'title': 'Options', 'description': 'Configuration options', 'icon': Icons.settings},
        ];
    }
  }
}