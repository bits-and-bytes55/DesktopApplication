import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class LeftReportTree extends StatefulWidget {
  const LeftReportTree({super.key});

  @override
  State<LeftReportTree> createState() => _LeftReportTreeState();
}

class _LeftReportTreeState extends State<LeftReportTree> {
  final DashboardController c = Get.find<DashboardController>();
  final PadWellController padWellC = padWellContext;
  final ReportContextController reportC = reportContext;

  bool _rootExpanded = true;
  final Map<String, bool> _wellExpansion = <String, bool>{};

  Worker? _wellWorker;

  @override
  void initState() {
    super.initState();

    _wellWorker = ever<String>(padWellC.selectedWellId, (wellId) {
      if (!mounted || wellId.trim().isEmpty) return;
      setState(() {
        _rootExpanded = true;
        _wellExpansion[wellId] = true;
      });
    });
  }

  @override
  void dispose() {
    _wellWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        border: Border(
          right: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Obx(_buildBackendPadWellList),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
              color: const Color(0xFFF2F4F7),
            ),
            child: Text(
              '* New report is only for active well.',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackendPadWellList() {
    if (padWellC.isLoading.value) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (padWellC.errorMessage.value.isNotEmpty) {
      return _backendMessage(
        Icons.cloud_off,
        'Backend data load failed',
        padWellC.errorMessage.value,
      );
    }

    if (padWellC.pads.isEmpty) {
      return _backendMessage(
        Icons.folder_off,
        'No backend pads',
        'Create a new pad to start this installation.',
        action: ElevatedButton.icon(
          onPressed: () {
            c.navigate('pads');
          },
          icon: const Icon(Icons.add, size: 14),
          label: const Text('New Pad'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      );
    }

    final wells = padWellC.wells.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      children: [
        _buildRootNode(wells),
      ],
    );
  }

  Widget _buildRootNode(List<AppWell> wells) {
    return Obx(() {
      final selectedRoot =
          padWellC.selectedWellId.value.isNotEmpty ||
          reportC.selectedReportId.value.isNotEmpty ||
          c.selectedNodeId.value == 'pads';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _treeRow(
            selected: selectedRoot,
            indent: 0,
            toggle: _treeToggle(
              expanded: _rootExpanded,
              onTap: () {
                setState(() {
                  _rootExpanded = !_rootExpanded;
                });
              },
            ),
            leading: Icon(
              Icons.account_tree_outlined,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            title: 'New Pad',
            subtitle: null,
            trailing: null,
            onTap: () {
              setState(() {
                _rootExpanded = true;
              });
              c.navigate('pads');
            },
          ),
          if (_rootExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: wells.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 8, 6),
                      child: Text(
                        'No wells linked to this pad',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: wells.map(_buildWellNode).toList(),
                    ),
            ),
        ],
      );
    });
  }

  Widget _buildWellNode(AppWell well) {
    return Obx(() {
      final selectedWell = padWellC.selectedWellId.value == well.id;
      final selected = selectedWell || c.selectedNodeId.value == 'well:${well.id}';
      final expanded = _wellExpansion[well.id] ?? selectedWell;
      final reports = selectedWell
          ? reportC.reports.toList()
          : const <AppReport>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _treeRow(
            selected: selected,
            indent: 0,
            toggle: _treeToggle(
              expanded: expanded,
              onTap: () {
                setState(() {
                  _wellExpansion[well.id] = !expanded;
                });
              },
            ),
            leading: Icon(
              Icons.location_on_outlined,
              size: 14,
              color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            title: well.displayName,
            subtitle: null,
            trailing: null,
            onTap: () {
              setState(() {
                _rootExpanded = true;
                _wellExpansion[well.id] = true;
              });
              padWellC.selectWell(well.id);
              c.navigate('well:${well.id}');
            },
          ),
          if (expanded && selectedWell) _buildReportList(reports),
        ],
      );
    });
  }

  Widget _buildReportList(List<AppReport> reports) {
    if (reportC.isLoading.value) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(34, 4, 8, 6),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading reports...',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (reportC.errorMessage.value.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(34, 4, 8, 6),
        child: Text(
          reportC.errorMessage.value,
          style: TextStyle(fontSize: 10, color: AppTheme.errorColor),
        ),
      );
    }

    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(34, 4, 8, 6),
        child: Text(
          'No reports under this well',
          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 34),
      child: Container(
        margin: const EdgeInsets.only(left: 7),
        padding: const EdgeInsets.only(left: 10, bottom: 2),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.black.withValues(alpha: 0.18)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reports.map(_buildReportRow).toList(),
        ),
      ),
    );
  }

  Widget _buildReportRow(AppReport report) {
    return Obx(() {
      final selected =
          reportC.selectedReportId.value == report.id ||
          c.selectedNodeId.value == 'report:${report.id}';

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            reportC.selectReport(report.id);
            c.navigate('report:${report.id}');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.description_outlined,
                    size: 13,
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _reportTimestamp(report),
                        style: TextStyle(
                          fontSize: 10,
                          color: selected
                              ? AppTheme.textPrimary
                              : AppTheme.textPrimary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _reportSequenceLabel(report),
                        style: TextStyle(
                          fontSize: 10,
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _treeRow({
    required bool selected,
    required double indent,
    required Widget toggle,
    required Widget leading,
    required String title,
    required String? subtitle,
    required Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 2, bottom: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                toggle,
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: leading,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: selected
                              ? AppTheme.textPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle.trim().isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _treeToggle({
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 12,
        height: 12,
        child: Icon(
          expanded ? Icons.indeterminate_check_box : Icons.add_box_outlined,
          size: 12,
          color: const Color(0xFF7A8799),
        ),
      ),
    );
  }

  Widget _backendMessage(
    IconData icon,
    String title,
    String subtitle, {
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 8,
            softWrap: true,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          if (action != null) ...[
            action,
            const SizedBox(height: 8),
          ],
          TextButton.icon(
            onPressed: () async {
              await padWellC.reloadData();
              await reportC.reloadData();
            },
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  String _reportSequenceLabel(AppReport report) {
    final label = report.userReportNo.isNotEmpty
        ? report.userReportNo
        : report.reportNo;
    if (label.isNotEmpty) return '# $label';
    return report.displayName;
  }

  String _reportTimestamp(AppReport report) {
    final created = DateTime.tryParse(report.createdAt)?.toLocal();
    final dateText = report.reportDate.isNotEmpty
        ? report.reportDate
        : (created == null
              ? ''
              : '${created.month}/${created.day}/${created.year}');
    final timeText = created == null
        ? ''
        : '${_twoDigits(created.hour)}:${_twoDigits(created.minute)}';

    if (dateText.isEmpty && timeText.isEmpty) {
      return report.displayName;
    }
    if (dateText.isEmpty) return timeText;
    if (timeText.isEmpty) return dateText;
    return '$dateText $timeText';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
