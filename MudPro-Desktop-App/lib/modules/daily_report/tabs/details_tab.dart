import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_bit_hydraulics_controller.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_circulation_hydraulics_controller.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_geometry_controller.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/report_solids_analysis_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/tabs/vol_snapshot_page.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DetailsTabView extends StatelessWidget {
  const DetailsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 1200;
          final isMediumScreen = constraints.maxWidth > 800;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Gradient
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.headerGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Detailed Analysis",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Comprehensive drilling parameters and calculations",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text("Export"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Refresh Data',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.filter_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Filter Data',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content - Always use large layout for solids, bit, and volume tables
                _buildLargeLayout(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLargeLayout() {
    return Column(
      children: [
        // First Row - Geometry & Circulation
        SizedBox(
          height: 400,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: const GeometryTable()),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: const CirculationTable()),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Second Row - Annular Hydraulics (Full Width)
        const SizedBox(height: 350, child: ReportAnnularHydraulicsTable()),

        const SizedBox(height: 16),

        // Third Row - Other Tables
        SizedBox(
          height: 350,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: const SolidsAnalysisTable()),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: const BitHydraulicsTable()),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: const VolumeTable()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediumLayout() {
    return Column(
      children: [
        // First Row
        SizedBox(
          height: 400,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: const GeometryTable()),
              const SizedBox(width: 16),
              Expanded(child: const CirculationTable()),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Second Row
        const SizedBox(height: 350, child: ReportAnnularHydraulicsTable()),

        const SizedBox(height: 16),

        // Third Row
        SizedBox(
          height: 350,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: const SolidsAnalysisTable()),
              const SizedBox(width: 16),
              Expanded(child: const BitHydraulicsTable()),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Fourth Row
        const SizedBox(height: 300, child: VolumeTable()),
      ],
    );
  }

  Widget _buildSmallLayout() {
    return Column(
      children: [
        const SizedBox(height: 400, child: GeometryTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 350, child: CirculationTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 400, child: ReportAnnularHydraulicsTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 350, child: SolidsAnalysisTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 300, child: BitHydraulicsTable()),
        const SizedBox(height: 16),
        const SizedBox(height: 300, child: VolumeTable()),
      ],
    );
  }
}

// Tab Item Widget
class _TabItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;

  const _TabItem(this.title, this.icon, [this.isActive = false]);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        color: isActive ? AppTheme.primaryColor : Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppTheme.textSecondary,
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

// Common Widgets
Widget _buildEditableCell({
  String value = "",
  bool center = true,
  bool isHeader = false,
  Color? backgroundColor,
}) {
  return Container(
    height: 36, // Fixed row height
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      color: backgroundColor ?? Colors.white,
    ),
    child: Center(
      child: TextField(
        controller: TextEditingController(text: value),
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? AppTheme.tableHeadColor : AppTheme.textPrimary,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          border: InputBorder.none,
          filled: false,
        ),
      ),
    ),
  );
}

Widget _buildStaticCell({
  required String text,
  bool center = true,
  bool isHeader = false,
  Color? backgroundColor,
  double? width,
}) {
  return Container(
    height: 36, // Fixed row height
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      color: backgroundColor ?? Colors.white,
    ),
    child: Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? AppTheme.tableHeadColor : AppTheme.textPrimary,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

// Card Container Widget with Improved Design
Widget _detailsCard(String title, Widget child, {int flex = 1}) {
  return Expanded(
    flex: flex,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.elevatedCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.9),
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                      tooltip: 'Add Row',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.filter_list,
                        size: 18,
                        color: Colors.white,
                      ),
                      tooltip: 'Filter',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.white,
                      ),
                      tooltip: 'More Options',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Container with Scroll
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Geometry Table with More Columns
class GeometryTable extends StatelessWidget {
  const GeometryTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportGeometryController>()
        ? Get.find<ReportGeometryController>()
        : Get.put(ReportGeometryController());

    return Obx(() {
      final rows = controller.rows.toList();
      final lengthUnit = AppUnits.unitSuffix(AppUnits.length);
      final volumeUnit = AppUnits.unitSuffix(AppUnits.fluidVolume);

      return _detailsCard(
        "Geometry",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isLoading.value ||
                controller.errorMessage.isNotEmpty)
              _statusBanner(
                isLoading: controller.isLoading.value,
                message: controller.isLoading.value
                    ? 'Loading geometry data...'
                    : controller.errorMessage.value,
              ),
            if (controller.sourceSummary.value.isNotEmpty)
              _sourceBanner(controller.sourceSummary.value),
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: Colors.grey.shade200, width: 1),
              columnWidths: const {
                0: FixedColumnWidth(50),
                1: FixedColumnWidth(220),
                2: FixedColumnWidth(120),
                3: FixedColumnWidth(120),
                4: FixedColumnWidth(120),
                5: FixedColumnWidth(130),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.secondaryColor.withOpacity(0.8),
                        AppTheme.secondaryColor.withOpacity(0.6),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  children: [
                    _buildStaticCell(
                      text: "#",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Description",
                      isHeader: true,
                      center: false,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Start ($lengthUnit)",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "End ($lengthUnit)",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Vol ($volumeUnit)",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "$volumeUnit/$lengthUnit",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
                if (rows.isEmpty)
                  TableRow(
                    children: [
                      _buildStaticCell(text: "-"),
                      _buildStaticCell(
                        text: controller.isLoading.value
                            ? 'Loading geometry rows'
                            : 'No geometry data available',
                        center: false,
                      ),
                      _buildStaticCell(text: "-"),
                      _buildStaticCell(text: "-"),
                      _buildStaticCell(text: "-"),
                      _buildStaticCell(text: "-"),
                    ],
                  ),
                ...rows.asMap().entries.map((entry) {
                  final rowColor = entry.key.isEven
                      ? Colors.white
                      : AppTheme.backgroundColor;
                  return TableRow(
                    decoration: BoxDecoration(color: rowColor),
                    children: [
                      _buildStaticCell(text: '${entry.key + 1}'),
                      _buildStaticCell(
                        text: entry.value.description,
                        center: false,
                      ),
                      _buildStaticCell(
                        text: _formatLength(entry.value.startFt),
                      ),
                      _buildStaticCell(text: _formatLength(entry.value.endFt)),
                      _buildStaticCell(
                        text: _formatVolume(entry.value.volumeBbl),
                      ),
                      _buildStaticCell(
                        text: _formatVolumePerLength(
                          entry.value.volumePerFtBbl,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
        flex: 2,
      );
    });
  }

  Widget _statusBanner({required bool isLoading, required String message}) {
    final backgroundColor = isLoading
        ? const Color(0xffEAF4FF)
        : const Color(0xffFFF4E5);
    final textColor = isLoading
        ? const Color(0xff1F5E9C)
        : const Color(0xff9A5A00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.85)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _sourceBanner(String summary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF4F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffDCE7F2)),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: Color(0xff35516B),
        ),
      ),
    );
  }

  String _formatLength(double? value) {
    if (value == null) {
      return '-';
    }
    final converted = AppUnits.convertValue(value, '(ft)', AppUnits.length);
    return _formatNumber(converted ?? value);
  }

  String _formatVolume(double value) {
    final converted =
        AppUnits.convertValue(value, '(bbl)', AppUnits.fluidVolume) ?? value;
    return _formatNumber(converted);
  }

  String _formatVolumePerLength(double value) {
    final volumeFactor =
        AppUnits.convertValue(1, '(bbl)', AppUnits.fluidVolume) ?? 1;
    final lengthFactor = AppUnits.convertValue(1, '(ft)', AppUnits.length) ?? 1;
    if (lengthFactor == 0) {
      return '-';
    }
    return _formatNumber(value * volumeFactor / lengthFactor, decimals: 3);
  }

  String _formatNumber(double value, {int decimals = 2}) {
    if (!value.isFinite) {
      return '-';
    }
    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

// Circulation Table with Moderate Columns
class CirculationTable extends StatelessWidget {
  const CirculationTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportCirculationHydraulicsController>()
        ? Get.find<ReportCirculationHydraulicsController>()
        : Get.put(ReportCirculationHydraulicsController());

    return Obx(() {
      final rows = controller.circulationRows.toList();
      final volumeUnit = AppUnits.unitSuffix(AppUnits.fluidVolume);

      return _detailsCard(
        "Circulation",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isLoading.value || controller.errorMessage.isNotEmpty)
              _statusBanner(
                isLoading: controller.isLoading.value,
                message: controller.isLoading.value
                    ? 'Loading circulation data...'
                    : controller.errorMessage.value,
              ),
            if (controller.sourceSummary.value.isNotEmpty)
              _sourceBanner(controller.sourceSummary.value),
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: Colors.grey.shade200, width: 1),
              columnWidths: const {
                0: FixedColumnWidth(45),
                1: FixedColumnWidth(165),
                2: FixedColumnWidth(90),
                3: FixedColumnWidth(90),
                4: FixedColumnWidth(90),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentColor.withOpacity(0.8),
                        AppTheme.accentColor.withOpacity(0.6),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  children: [
                    _buildStaticCell(
                      text: "#",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Path",
                      isHeader: true,
                      center: false,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Vol ($volumeUnit)",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Minutes",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Strokes",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
                if (rows.isEmpty)
                  TableRow(
                    children: [
                      _buildStaticCell(text: "-"),
                      _buildStaticCell(
                        text: controller.isLoading.value
                            ? 'Loading circulation rows'
                            : 'No circulation data available',
                        center: false,
                      ),
                      _buildStaticCell(text: "-"),
                      _buildStaticCell(text: "-"),
                      _buildStaticCell(text: "-"),
                    ],
                  ),
                ...rows.asMap().entries.map((entry) {
                  final rowColor = entry.key.isEven
                      ? Colors.white
                      : AppTheme.backgroundColor;
                  return TableRow(
                    decoration: BoxDecoration(color: rowColor),
                    children: [
                      _buildStaticCell(text: "${entry.key + 1}"),
                      _buildStaticCell(text: entry.value.path, center: false),
                      _buildStaticCell(
                        text: _formatVolume(entry.value.volumeBbl),
                      ),
                      _buildStaticCell(text: _formatNumber(entry.value.minutes)),
                      _buildStaticCell(
                        text: _formatNumber(entry.value.strokes, decimals: 0),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
        flex: 1,
      );
    });
  }

  Widget _statusBanner({
    required bool isLoading,
    required String message,
  }) {
    final backgroundColor = isLoading
        ? const Color(0xffEAF4FF)
        : const Color(0xffFFF4E5);
    final textColor = isLoading
        ? const Color(0xff1F5E9C)
        : const Color(0xff9A5A00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.85)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _sourceBanner(String summary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF4F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffDCE7F2)),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: Color(0xff35516B),
        ),
      ),
    );
  }

  String _formatVolume(double value) {
    final converted =
        AppUnits.convertValue(value, '(bbl)', AppUnits.fluidVolume) ?? value;
    return _formatNumber(converted);
  }

  String _formatNumber(double? value, {int decimals = 2}) {
    if (value == null || !value.isFinite) {
      return '-';
    }
    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

// Live report annular hydraulics table.
class ReportAnnularHydraulicsTable extends StatelessWidget {
  const ReportAnnularHydraulicsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportCirculationHydraulicsController>()
        ? Get.find<ReportCirculationHydraulicsController>()
        : Get.put(ReportCirculationHydraulicsController());

    return Obx(() {
      final rows = controller.annularRows.toList();
      final lengthUnit = AppUnits.unitSuffix(AppUnits.length);
      final velocityUnit = AppUnits.unitSuffix(AppUnits.velocity);
      final rateUnit = AppUnits.unitSuffix(AppUnits.drillingFlowRate);
      final mudWeightUnit = AppUnits.unitSuffix(AppUnits.mudWeight);
      final pressureUnit = AppUnits.unitSuffix(AppUnits.pressure);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: AppTheme.elevatedCardDecoration.copyWith(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(controller),
            if (controller.isLoading.value || controller.errorMessage.isNotEmpty)
              _statusBanner(
                isLoading: controller.isLoading.value,
                message: controller.isLoading.value
                    ? 'Loading annular hydraulics...'
                    : controller.errorMessage.value,
              ),
            if (controller.sourceSummary.value.isNotEmpty)
              _sourceBanner(controller.sourceSummary.value),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Scrollbar(
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: TableBorder.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          columnWidths: const {
                            0: FixedColumnWidth(45),
                            1: FixedColumnWidth(180),
                            2: FixedColumnWidth(90),
                            3: FixedColumnWidth(90),
                            4: FixedColumnWidth(100),
                            5: FixedColumnWidth(95),
                            6: FixedColumnWidth(105),
                            7: FixedColumnWidth(85),
                            8: FixedColumnWidth(85),
                            9: FixedColumnWidth(95),
                            10: FixedColumnWidth(80),
                            11: FixedColumnWidth(95),
                            12: FixedColumnWidth(80),
                            13: FixedColumnWidth(100),
                            14: FixedColumnWidth(105),
                            15: FixedColumnWidth(80),
                          },
                          children: [
                            _tableHeader(
                              lengthUnit: lengthUnit,
                              velocityUnit: velocityUnit,
                              rateUnit: rateUnit,
                              mudWeightUnit: mudWeightUnit,
                              pressureUnit: pressureUnit,
                            ),
                            if (rows.isEmpty) _emptyRow(controller),
                            ...rows.asMap().entries.map((entry) {
                              final rowColor = entry.key.isEven
                                  ? Colors.white
                                  : AppTheme.backgroundColor;
                              final row = entry.value;
                              return TableRow(
                                decoration: BoxDecoration(color: rowColor),
                                children: [
                                  _buildStaticCell(text: "${entry.key + 1}"),
                                  _buildStaticCell(
                                    text: row.section,
                                    center: false,
                                  ),
                                  _buildStaticCell(
                                    text: _formatLength(row.lengthFt),
                                  ),
                                  _buildStaticCell(
                                    text: _formatLength(row.bottomMdFt),
                                  ),
                                  _buildStaticCell(
                                    text: _formatVelocity(
                                      row.annularVelocityFtMin,
                                    ),
                                  ),
                                  _buildStaticCell(
                                    text: _formatVelocity(
                                      row.criticalVelocityFtMin,
                                    ),
                                  ),
                                  _buildStaticCell(
                                    text: _formatRate(row.criticalRateGpm),
                                  ),
                                  _buildStaticCell(
                                    text: _formatNumber(
                                      row.reynoldsAnnular,
                                      decimals: 0,
                                    ),
                                  ),
                                  _buildStaticCell(
                                    text: _formatNumber(
                                      row.reynoldsCritical,
                                      decimals: 0,
                                    ),
                                  ),
                                  _buildStaticCell(
                                    text: _formatNumber(
                                      row.effectiveViscosityCp,
                                    ),
                                  ),
                                  _buildStaticCell(text: row.flowRegime),
                                  _buildStaticCell(
                                    text: _formatMudWeight(row.ecdPpg),
                                  ),
                                  _buildStaticCell(
                                    text: _formatNumber(row.cci),
                                  ),
                                  _buildStaticCell(
                                    text: _formatPressure(
                                      row.pressureDropPsi,
                                    ),
                                  ),
                                  _buildStaticCell(
                                    text: _formatVelocity(
                                      row.slipVelocityFtMin,
                                    ),
                                  ),
                                  _buildStaticCell(
                                    text: _formatNumber(row.ctrPercent),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _header(ReportCirculationHydraulicsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Annular Hydraulics",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.calculate, size: 18, color: Colors.white),
            tooltip: 'Calculate',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _tableHeader({
    required String lengthUnit,
    required String velocityUnit,
    required String rateUnit,
    required String mudWeightUnit,
    required String pressureUnit,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      children: [
        _headerCell("#"),
        _headerCell("Section", center: false),
        _headerCell("Length ($lengthUnit)"),
        _headerCell("Btm MD"),
        _headerCell("Vel Ann ($velocityUnit)"),
        _headerCell("Vel Crit"),
        _headerCell("Crit Rate ($rateUnit)"),
        _headerCell("Re Ann"),
        _headerCell("Re Crit"),
        _headerCell("Eff. Visc(cP)"),
        _headerCell("Flow"),
        _headerCell("ECD ($mudWeightUnit)"),
        _headerCell("CCi"),
        _headerCell("P.Drop ($pressureUnit)"),
        _headerCell("Slip Vel. ($velocityUnit)"),
        _headerCell("CTR(%)"),
      ],
    );
  }

  Widget _headerCell(String text, {bool center = true}) {
    return _buildStaticCell(
      text: text,
      isHeader: true,
      center: center,
      backgroundColor: Colors.transparent,
    );
  }

  TableRow _emptyRow(ReportCirculationHydraulicsController controller) {
    return TableRow(
      children: [
        _buildStaticCell(text: "-"),
        _buildStaticCell(
          text: controller.isLoading.value
              ? 'Loading annular rows'
              : 'No annular hydraulics data available',
          center: false,
        ),
        ...List.generate(14, (_) => _buildStaticCell(text: "-")),
      ],
    );
  }

  Widget _statusBanner({
    required bool isLoading,
    required String message,
  }) {
    final backgroundColor = isLoading
        ? const Color(0xffEAF4FF)
        : const Color(0xffFFF4E5);
    final textColor = isLoading
        ? const Color(0xff1F5E9C)
        : const Color(0xff9A5A00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.85)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _sourceBanner(String summary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF4F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffDCE7F2)),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: Color(0xff35516B),
        ),
      ),
    );
  }

  String _formatLength(double? value) {
    if (value == null) return '-';
    final converted = AppUnits.convertValue(value, '(ft)', AppUnits.length);
    return _formatNumber(converted ?? value);
  }

  String _formatVelocity(double? value) {
    if (value == null) return '-';
    final converted = AppUnits.convertValue(value, '(ft/min)', AppUnits.velocity);
    return _formatNumber(converted ?? value);
  }

  String _formatRate(double? value) {
    if (value == null) return '-';
    final converted =
        AppUnits.convertValue(value, '(gpm)', AppUnits.drillingFlowRate);
    return _formatNumber(converted ?? value);
  }

  String _formatMudWeight(double? value) {
    if (value == null) return '-';
    final converted = AppUnits.convertValue(value, '(ppg)', AppUnits.mudWeight);
    return _formatNumber(converted ?? value);
  }

  String _formatPressure(double? value) {
    if (value == null) return '-';
    final converted = AppUnits.convertValue(value, '(psi)', AppUnits.pressure);
    return _formatNumber(converted ?? value);
  }

  String _formatNumber(double? value, {int decimals = 2}) {
    if (value == null || !value.isFinite) {
      return '-';
    }
    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

// Annular Hydraulics Table with Many Columns
class AnnularHydraulicsTable extends StatelessWidget {
  const AnnularHydraulicsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.elevatedCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Annular Hydraulics",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.calculate,
                        size: 18,
                        color: Colors.white,
                      ),
                      tooltip: 'Calculate',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.download,
                        size: 18,
                        color: Colors.white,
                      ),
                      tooltip: 'Export',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Container
          Expanded(
            child: Container(
              color: Colors.white,
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        border: TableBorder.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(50), // #
                          1: FixedColumnWidth(150), // Section
                          2: FixedColumnWidth(80), // Length
                          3: FixedColumnWidth(80), // Btm MD
                          4: FixedColumnWidth(90), // Vel Ann
                          5: FixedColumnWidth(90), // Vel Crit
                          6: FixedColumnWidth(100), // Crit Rate
                          7: FixedColumnWidth(80), // Re Ann
                          8: FixedColumnWidth(80), // Re Crit
                          9: FixedColumnWidth(90), // ECD
                          10: FixedColumnWidth(90), // ΔP
                          11: FixedColumnWidth(90), // HSI
                          12: FixedColumnWidth(90), // ΔP
                          13: FixedColumnWidth(90), // HSI
                          14: FixedColumnWidth(90), // ΔP
                          15: FixedColumnWidth(90),
                        },
                        children: [
                          // Main Header
                          TableRow(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.9),
                                  AppTheme.primaryColor.withOpacity(0.7),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            children: [
                              _buildStaticCell(
                                text: "#",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Section (in)",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Length",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Btm MD",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Vel Ann",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Vel Crit",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Crit Rate",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Re Ann",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Re Crit",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Eff. Visc(cP)",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Flow",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "ECD",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "CCi",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "P.Drop(psi)",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "Slip Vel.(ft/min)",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                              _buildStaticCell(
                                text: "CTR(%)",
                                isHeader: true,
                                backgroundColor: Colors.transparent,
                              ),
                            ],
                          ),

                          // Data Rows
                          ...List.generate(12, (index) {
                            final rowColor = index % 2 == 0
                                ? Colors.white
                                : AppTheme.backgroundColor;
                            return TableRow(
                              decoration: BoxDecoration(color: rowColor),
                              children: [
                                _buildStaticCell(text: "${index + 1}"),
                                _buildEditableCell(
                                  value: _getSection(index),
                                  center: false,
                                ),
                                _buildEditableCell(
                                  value: "${500 + index * 100}",
                                ),
                                _buildEditableCell(value: "${index * 1000}"),
                                _buildEditableCell(
                                  value: "${120 + index * 10}",
                                ),
                                _buildEditableCell(value: "${80 + index * 5}"),
                                _buildEditableCell(
                                  value: "${300 + index * 20}",
                                ),
                                _buildEditableCell(
                                  value: "${1500 + index * 200}",
                                ),
                                _buildEditableCell(
                                  value: "${2000 + index * 300}",
                                ),
                                _buildEditableCell(
                                  value: "${9.5 + index * 0.1}",
                                ),
                                _buildEditableCell(value: "${50 + index * 5}"),
                                _buildEditableCell(
                                  value: "${2.5 + index * 0.2}",
                                ),
                                _buildEditableCell(
                                  value: "${1.2 + index * 0.1}",
                                ),
                                _buildEditableCell(
                                  value: "${850 + index * 50}",
                                ),
                                _buildEditableCell(value: "${15 + index * 2}"),
                                _buildEditableCell(value: "${75 + index * 5}"),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSection(int index) {
    final sections = [
      "DP in OH",
      "DC in OH",
      "HWDP in OH",
      "DP in CSG",
      "DC in CSG",
      "HWDP in CSG",
      "Bit in OH",
      "Motor in OH",
      "MWD in OH",
      "Stab in OH",
      "Crossover",
      "Riser",
    ];
    return index < sections.length ? sections[index] : "Section ${index + 1}";
  }
}

// Solids Analysis Table
class SolidsAnalysisTable extends StatelessWidget {
  const SolidsAnalysisTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportSolidsAnalysisController>()
        ? Get.find<ReportSolidsAnalysisController>()
        : Get.put(ReportSolidsAnalysisController());

    return Obx(() {
      final rows = controller.rows.toList();

      return _detailsCard(
        "Solids Analysis",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isLoading.value ||
                controller.errorMessage.isNotEmpty)
              _statusBanner(
                isLoading: controller.isLoading.value,
                message: controller.isLoading.value
                    ? 'Loading solids analysis...'
                    : controller.errorMessage.value,
              ),
            if (controller.sourceSummary.value.isNotEmpty)
              _sourceBanner(controller.sourceSummary.value),
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: Colors.grey.shade200, width: 1),
              columnWidths: const {
                0: FixedColumnWidth(180),
                1: FixedColumnWidth(110),
                2: FixedColumnWidth(110),
                3: FixedColumnWidth(110),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.successColor.withOpacity(0.8),
                        AppTheme.successColor.withOpacity(0.6),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  children: [
                    _buildStaticCell(
                      text: "Description",
                      isHeader: true,
                      center: false,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Sample 1",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Sample 2",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Sample 3",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
                if (rows.isEmpty)
                  TableRow(
                    children: [
                      _buildStaticCell(
                        text: controller.isLoading.value
                            ? 'Loading solids rows'
                            : 'No solids analysis data available',
                        center: false,
                      ),
                      _buildStaticCell(text: '-'),
                      _buildStaticCell(text: '-'),
                      _buildStaticCell(text: '-'),
                    ],
                  ),
                ...rows.asMap().entries.map((entry) {
                  final row = entry.value;
                  final rowColor = row.highlight
                      ? AppTheme.successColor.withOpacity(0.06)
                      : entry.key.isEven
                          ? Colors.white
                          : AppTheme.backgroundColor;
                  return TableRow(
                    decoration: BoxDecoration(color: rowColor),
                    children: [
                      _buildStaticCell(text: row.label, center: false),
                      _buildStaticCell(text: _valueAt(row.values, 0)),
                      _buildStaticCell(text: _valueAt(row.values, 1)),
                      _buildStaticCell(text: _valueAt(row.values, 2)),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
        flex: 1,
      );
    });
  }

  Widget _statusBanner({
    required bool isLoading,
    required String message,
  }) {
    final backgroundColor = isLoading
        ? const Color(0xffEAF4FF)
        : const Color(0xffFFF4E5);
    final textColor = isLoading
        ? const Color(0xff1F5E9C)
        : const Color(0xff9A5A00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.85)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _sourceBanner(String summary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF4F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffDCE7F2)),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: Color(0xff35516B),
        ),
      ),
    );
  }

  String _valueAt(List<String> values, int index) {
    if (index >= values.length) {
      return '-';
    }
    final value = values[index].trim();
    return value.isEmpty ? '-' : value;
  }
}

// Bit Hydraulics Table
class BitHydraulicsTable extends StatelessWidget {
  const BitHydraulicsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ReportBitHydraulicsController>()
        ? Get.find<ReportBitHydraulicsController>()
        : Get.put(ReportBitHydraulicsController());

    return Obx(() {
      final rows = _buildRows(controller);
      return _detailsCard(
        "Bit Hydraulics",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isLoading.value ||
                controller.errorMessage.isNotEmpty)
              _statusBanner(controller),
            if (_sourceSummary(controller).isNotEmpty)
              _sourceBanner(_sourceSummary(controller)),
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: Colors.grey.shade200, width: 1),
              columnWidths: const {
                0: FixedColumnWidth(200),
                1: FixedColumnWidth(140),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warningColor.withOpacity(0.8),
                        AppTheme.warningColor.withOpacity(0.6),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  children: [
                    _buildStaticCell(
                      text: "Parameter",
                      isHeader: true,
                      center: false,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: "Value",
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
                ...rows.asMap().entries.map((entry) {
                  final rowColor = entry.key.isEven
                      ? Colors.white
                      : AppTheme.backgroundColor;
                  return TableRow(
                    decoration: BoxDecoration(color: rowColor),
                    children: [
                      _buildStaticCell(text: entry.value.$1, center: false),
                      _buildStaticCell(text: entry.value.$2),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
        flex: 1,
      );
    });
  }

  List<(String, String)> _buildRows(ReportBitHydraulicsController controller) {
    final snapshot = controller.snapshot.value;
    return [
      (
        "Pressure Loss",
        _formatConverted(
          snapshot?.bitPressureDropPsi,
          '(psi)',
          AppUnits.pressure,
        ),
      ),
      (
        "Flow Rate",
        _formatConverted(
          controller.flowRateGpm.value,
          '(gpm)',
          AppUnits.drillingFlowRate,
        ),
      ),
      (
        "Nozzle Velocity",
        _formatConverted(
          snapshot?.nozzleVelocityFtPerSec,
          '(ft/s)',
          AppUnits.nozzleVelocity,
        ),
      ),
      (
        "Jet Impact Force",
        _formatConverted(snapshot?.jetImpactForceLbf, '(lbf)', AppUnits.force),
      ),
      (
        "Hydraulic HP",
        _formatConverted(snapshot?.hydraulicHp, '(HP)', AppUnits.power),
      ),
      ("Specific Energy", _formatPowerPerArea(snapshot?.hydraulicHpPerArea)),
      ("Pressure Drop", _formatPercent(snapshot?.pressureDropPercent)),
      (
        "Flow Velocity",
        _formatConverted(
          snapshot?.flowVelocityFtPerSec,
          '(ft/s)',
          AppUnits.nozzleVelocity,
        ),
      ),
      ("Reynolds Number", "-"),
      ("Friction Factor", "-"),
    ];
  }

  Widget _statusBanner(ReportBitHydraulicsController controller) {
    final isLoading = controller.isLoading.value;
    final message = isLoading
        ? 'Loading report hydraulics...'
        : controller.errorMessage.value;
    final backgroundColor = isLoading
        ? const Color(0xffEAF4FF)
        : const Color(0xffFFF4E5);
    final textColor = isLoading
        ? const Color(0xff1F5E9C)
        : const Color(0xff9A5A00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.85)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _sourceBanner(String summary) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF4F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffDCE7F2)),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: Color(0xff35516B),
        ),
      ),
    );
  }

  String _sourceSummary(ReportBitHydraulicsController controller) {
    final parts = <String>[];
    final mw = _formatConverted(
      controller.mudWeightPpg.value,
      '(ppg)',
      AppUnits.mudWeight,
    );
    final bitSize = _formatConverted(
      controller.bitSizeIn.value,
      '(in)',
      AppUnits.diameter,
    );
    final tfa = _formatConverted(
      controller.tfaIn2.value,
      '(in2)',
      AppUnits.crossSection,
    );

    if (mw != '-') {
      parts.add('MW $mw');
    }
    if (bitSize != '-') {
      parts.add('Bit $bitSize');
    }
    if (tfa != '-') {
      parts.add('TFA $tfa');
    }

    return parts.join(' | ');
  }

  String _formatConverted(double? value, String fromUnit, String toUnit) {
    if (value == null) {
      return '-';
    }
    final converted = AppUnits.convertValue(value, fromUnit, toUnit) ?? value;
    return '${_formatNumber(converted)} ${AppUnits.unitSuffix(toUnit)}'.trim();
  }

  String _formatPowerPerArea(double? baseValue) {
    if (baseValue == null) {
      return '-';
    }
    final powerFactor = AppUnits.convertValue(1, '(HP)', AppUnits.power) ?? 1;
    final areaFactor =
        AppUnits.convertValue(1, '(in2)', AppUnits.crossSection) ?? 1;
    if (areaFactor == 0) {
      return '-';
    }
    final converted = baseValue * powerFactor / areaFactor;
    final powerUnit = AppUnits.unitSuffix(AppUnits.power);
    final areaUnit = AppUnits.unitSuffix(AppUnits.crossSection);
    return '${_formatNumber(converted)} $powerUnit/$areaUnit';
  }

  String _formatPercent(double? value) {
    if (value == null) {
      return '-';
    }
    return '${_formatNumber(value)} %';
  }

  String _formatNumber(double value, {int decimals = 2}) {
    if (!value.isFinite) {
      return '-';
    }
    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

// Volume Table
class VolumeTable extends StatelessWidget {
  const VolumeTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VolumeSnapshotController>()
        ? Get.find<VolumeSnapshotController>()
        : Get.put(VolumeSnapshotController());

    return Obx(() {
      final volumeUnit = AppUnits.unitSuffix(AppUnits.fluidVolume);
      final rows = controller.hasData
          ? _buildRows(controller)
          : const <(String, double?)>[];

      return _detailsCard(
        "Volume ($volumeUnit)",
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isLoading.value ||
                controller.errorMessage.isNotEmpty)
              _statusBanner(
                isLoading: controller.isLoading.value,
                message: controller.isLoading.value
                    ? 'Loading volume snapshot...'
                    : controller.errorMessage.value,
              ),
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: Colors.grey.shade200, width: 1),
              columnWidths: const {
                0: FixedColumnWidth(220),
                1: FixedColumnWidth(140),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.infoColor.withOpacity(0.8),
                        AppTheme.infoColor.withOpacity(0.6),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  children: [
                    _buildStaticCell(
                      text: "Section",
                      isHeader: true,
                      center: false,
                      backgroundColor: Colors.transparent,
                    ),
                    _buildStaticCell(
                      text: volumeUnit,
                      isHeader: true,
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
                if (rows.isEmpty)
                  TableRow(
                    children: [
                      _buildStaticCell(
                        text: controller.isLoading.value
                            ? 'Loading volume rows'
                            : 'No volume snapshot available',
                        center: false,
                      ),
                      _buildStaticCell(text: '-'),
                    ],
                  ),
                ...rows.asMap().entries.map((entry) {
                  final rowColor = entry.key.isEven
                      ? Colors.white
                      : AppTheme.backgroundColor;
                  return TableRow(
                    decoration: BoxDecoration(color: rowColor),
                    children: [
                      _buildStaticCell(text: entry.value.$1, center: false),
                      _buildStaticCell(text: _formatVolume(entry.value.$2)),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
        flex: 1,
      );
    });
  }

  List<(String, double?)> _buildRows(VolumeSnapshotController controller) {
    return [
      ('Hole', _volumeName(controller, 'hole')),
      ('Active Pits', _volumeName(controller, 'activePits')),
      ('Active System', _volumeName(controller, 'activeSystem')),
      ('End Volume', _volumeName(controller, 'endVol')),
      (
        'End Vol. - Active System',
        _volumeName(controller, 'endVolMinusActiveSystem'),
      ),
      ('Total Storage', _volumeName(controller, 'totalStorage')),
      ('Total on Location', _volumeName(controller, 'totalOnLocation')),
      ('Start Volume', controller.raw('startVol')),
      ('Addition Total', controller.raw('additionTotal')),
      ('Loss Total', controller.raw('lossTotal')),
      ('Return Volume', controller.raw('returnVol')),
      ('Volume Difference', controller.raw('volumeDifference')),
    ];
  }

  double? _volumeName(VolumeSnapshotController controller, String key) {
    final value = controller.rawVolumeName(key);
    if (!controller.hasData && value == 0) {
      return null;
    }
    return value;
  }

  Widget _statusBanner({required bool isLoading, required String message}) {
    final backgroundColor = isLoading
        ? const Color(0xffEAF4FF)
        : const Color(0xffFFF4E5);
    final textColor = isLoading
        ? const Color(0xff1F5E9C)
        : const Color(0xff9A5A00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.85)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatVolume(double? value) {
    if (value == null) {
      return '-';
    }
    final converted =
        AppUnits.convertValue(value, '(bbl)', AppUnits.fluidVolume) ?? value;
    return converted
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
