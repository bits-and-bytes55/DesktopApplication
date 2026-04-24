import 'package:get/get.dart';

class PadModel {
  final String padId;
  final String padName;
  final RxList<ComparisonWellModel> wells;

  PadModel({required this.padId, required this.padName, required this.wells});
}

class ComparisonWellModel {
  final String wellId;
  final String wellName;
  final String operatorName;
  final String fieldBlock;
  final String apiWellNo;
  final String rig;
  final String spudDate;
  final RxList<ReportModel> reports;

  ComparisonWellModel({
    required this.wellId,
    required this.wellName,
    required this.operatorName,
    required this.fieldBlock,
    required this.apiWellNo,
    required this.rig,
    required this.spudDate,
    required this.reports,
  });
}

class ReportModel {
  final String reportId;
  final String reportNo;
  final String userReportNo;
  final String reportDate;
  final String title;
  final String wellId;
  final String wellName;
  final String operatorName;
  final String fieldBlock;
  final String apiWellNo;
  final String rig;
  final String spudDate;
  final String activity;
  final String interval;
  final String mudType;
  final String recommendedTreatment;
  final String remarks;
  final String recapRemarks;
  final String internalNotes;
  final double md;
  final double mw;
  final double dailyCost;
  final double cumulativeCost;
  final RxBool isSelected;

  ReportModel({
    required this.reportId,
    required this.reportNo,
    required this.userReportNo,
    required this.reportDate,
    required this.title,
    required this.wellId,
    required this.wellName,
    required this.operatorName,
    required this.fieldBlock,
    required this.apiWellNo,
    required this.rig,
    required this.spudDate,
    required this.activity,
    required this.interval,
    required this.mudType,
    required this.recommendedTreatment,
    required this.remarks,
    required this.recapRemarks,
    required this.internalNotes,
    required this.md,
    required this.mw,
    required this.dailyCost,
    required this.cumulativeCost,
    RxBool? isSelected,
  }) : isSelected = isSelected ?? false.obs;

  String get reportLabel {
    if (userReportNo.trim().isNotEmpty) return userReportNo.trim();
    if (reportNo.trim().isNotEmpty) return reportNo.trim();
    return '-';
  }

  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    return 'Report $reportLabel';
  }

  String get dateLabel => reportDate.trim().isEmpty ? '-' : reportDate.trim();
}

class ComparisonMetricRow {
  final String section;
  final String label;
  final List<String> values;

  const ComparisonMetricRow({
    required this.section,
    required this.label,
    required this.values,
  });

  bool get hasDifference {
    final normalized = values.map((value) {
      final trimmed = value.trim().toLowerCase();
      return trimmed.isEmpty ? '-' : trimmed;
    }).toSet();
    return normalized.length > 1;
  }
}
