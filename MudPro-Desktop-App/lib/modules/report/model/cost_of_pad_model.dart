import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';

class PadCostSnapshot {
  final AppPad pad;
  final List<WellCostSummary> wells;
  final List<PadCostReportRow> reports;
  final List<CostBucketSummary> activityBreakdown;
  final List<CostBucketSummary> mudTypeBreakdown;

  const PadCostSnapshot({
    required this.pad,
    required this.wells,
    required this.reports,
    required this.activityBreakdown,
    required this.mudTypeBreakdown,
  });

  int get totalWells => wells.length;

  int get activeWellCount => wells.where((well) => well.reportCount > 0).length;

  int get totalReports => reports.length;

  double get totalDailyCost =>
      reports.fold(0, (sum, report) => sum + report.row.dailyCost);

  double get latestCumulativeCost =>
      wells.fold(0, (sum, well) => sum + well.latestCumulativeCost);

  double get averageDailyCost =>
      reports.isEmpty ? 0 : totalDailyCost / reports.length;

  double get totalBulkSetupFee =>
      wells.fold(0, (sum, well) => sum + well.bulkTankSetupFee);

  double get maxMeasuredDepth => reports.fold<double>(
    0,
    (maxValue, report) => report.row.md > maxValue ? report.row.md : maxValue,
  );

  String get latestReportDate =>
      reports.isEmpty ? '' : reports.first.row.reportDate;

  String get topActivity =>
      activityBreakdown.isEmpty ? '-' : activityBreakdown.first.label;

  String get topMudType =>
      mudTypeBreakdown.isEmpty ? '-' : mudTypeBreakdown.first.label;
}

class WellCostSummary {
  final AppWell well;
  final List<ReportManagerRow> rows;
  final ReportManagerRow? latestRow;
  final double totalDailyCost;
  final double averageDailyCost;
  final double latestDailyCost;
  final double latestCumulativeCost;
  final double maxMeasuredDepth;
  final double bulkTankSetupFee;
  final String latestReportDate;

  const WellCostSummary({
    required this.well,
    required this.rows,
    required this.latestRow,
    required this.totalDailyCost,
    required this.averageDailyCost,
    required this.latestDailyCost,
    required this.latestCumulativeCost,
    required this.maxMeasuredDepth,
    required this.bulkTankSetupFee,
    required this.latestReportDate,
  });

  int get reportCount => rows.length;
}

class PadCostReportRow {
  final AppWell well;
  final ReportManagerRow row;
  final bool isLatestForWell;

  const PadCostReportRow({
    required this.well,
    required this.row,
    required this.isLatestForWell,
  });
}

class CostBucketSummary {
  final String label;
  final double totalDailyCost;
  final double averageDailyCost;
  final int reportCount;
  final int wellCount;

  const CostBucketSummary({
    required this.label,
    required this.totalDailyCost,
    required this.averageDailyCost,
    required this.reportCount,
    required this.wellCount,
  });
}
