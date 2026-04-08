import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';

class LeftReportTree extends StatelessWidget {
  LeftReportTree({super.key});

  final c = Get.find<DashboardController>();
  final padWellC = padWellContext;
  final reportC = reportContext;

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
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     gradient: AppTheme.primaryGradient,
          //     border: Border(
          //       bottom: BorderSide(color: Colors.black.withOpacity(0.1)),
          //     ),
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(Icons.folder_special, color: Colors.white, size: 18),
          //       SizedBox(width: 8),
          //       Text(
          //         'Reports Explorer',
          //         style: TextStyle(
          //           color: Colors.white,
          //           fontSize: 14,
          //           fontWeight: FontWeight.w600,
          //           letterSpacing: 0.5,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // SizedBox(height: 8),

          // ───── UG HEADER ─────
          _clickableHeader(
            icon: Icons.account_tree,
            text: 'Pads & Wells',
            id: 'pads',
          ),

          Obx(() {
            final wellId = padWellC.selectedWellId.value;
            final wellName = padWellC.selectedWellName;
            if (wellId.isEmpty || wellName.isEmpty)
              return const SizedBox.shrink();
            return _clickableHeader(
              icon: Icons.location_on,
              text: wellName,
              id: 'well:$wellId',
              indent: 24,
            );
          }),

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
              child: Obx(_buildBackendPadWellList),
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
                    child: Icon(
                      Icons.info,
                      size: 10,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  TextSpan(text: ' '),
                  TextSpan(
                    text: "Pad/well/report list is loaded from backend.",
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
        'Create pads/wells in backend first, then refresh.',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16),
      itemCount: padWellC.pads.length,
      itemBuilder: (context, index) =>
          _buildBackendPadTile(padWellC.pads[index]),
    );
  }

  Widget _buildBackendPadTile(AppPad pad) {
    final wells = padWellC.wellsForPad(pad.id);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: ExpansionTile(
        initiallyExpanded: wells.any(
          (well) => well.id == padWellC.selectedWellId.value,
        ),
        tilePadding: EdgeInsets.symmetric(horizontal: 10),
        childrenPadding: EdgeInsets.fromLTRB(8, 0, 8, 8),
        leading: Icon(Icons.folder, size: 15, color: AppTheme.primaryColor),
        title: Text(
          pad.displayName,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          '${wells.length} ${wells.length == 1 ? 'well' : 'wells'}',
          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
        onExpansionChanged: (expanded) {
          if (expanded) {
            padWellC.selectPad(pad.id);
            c.navigate('pad:${pad.id}');
          }
        },
        children: wells.isEmpty
            ? [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'No wells linked to this pad',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ]
            : wells.map(_buildBackendWellRow).toList(),
      ),
    );
  }

  Widget _buildBackendWellRow(AppWell well) {
    final id = 'well:${well.id}';
    return Obx(() {
      final selectedWell = padWellC.selectedWellId.value == well.id;
      final selected = selectedWell || c.selectedNodeId.value == id;
      final reports = selectedWell
          ? reportC.reports.toList()
          : const <AppReport>[];

      return Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                padWellC.selectWell(well.id);
                c.navigate(id);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                margin: EdgeInsets.only(top: 4),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor.withOpacity(0.12)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primaryColor.withOpacity(0.35)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 13,
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        well.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (selectedWell)
                      Text(
                        '${reports.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (selectedWell) _buildReportList(reports),
        ],
      );
    });
  }

  Widget _buildReportList(List<AppReport> reports) {
    if (reportC.isLoading.value) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 24, right: 8),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
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
        padding: const EdgeInsets.only(top: 6, left: 24, right: 8),
        child: Text(
          reportC.errorMessage.value,
          style: TextStyle(fontSize: 10, color: AppTheme.errorColor),
        ),
      );
    }

    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 24, right: 8),
        child: Text(
          'No reports under this well yet',
          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 18),
      child: Column(children: reports.map(_buildReportRow).toList()),
    );
  }

  Widget _buildReportRow(AppReport report) {
    final id = 'report:${report.id}';
    return Obx(() {
      final selected =
          reportC.selectedReportId.value == report.id ||
          c.selectedNodeId.value == id;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            reportC.selectReport(report.id);
            c.navigate(id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(top: 4, right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.accentColor.withOpacity(0.18)
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected
                    ? AppTheme.accentColor.withOpacity(0.45)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 13,
                  color: selected
                      ? AppTheme.accentColor
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppTheme.textPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (report.reportDate.isNotEmpty)
                        Text(
                          report.reportDate,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (report.reportNo.isNotEmpty)
                  Text(
                    '#${report.reportNo}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.accentColor
                          : AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _backendMessage(IconData icon, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Colors.grey.shade400),
          SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 8,
            softWrap: true,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 12),
          TextButton.icon(
            onPressed: padWellC.reloadData,
            icon: Icon(Icons.refresh, size: 14),
            label: Text('Refresh'),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => c.navigate(dateNode.date),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                children: dateNode.items.map((item) {
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
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.3,
                                    ),
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
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
