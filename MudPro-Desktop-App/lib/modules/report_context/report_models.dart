class AppReport {
  final String id;
  final String wellId;
  final String reportNo;
  final String userReportNo;
  final String reportDate;
  final String title;
  final String notes;
  final String recommendedTreatment;
  final String remarks;
  final String recapRemarks;
  final String internalNotes;
  final ReportAttachment? remarksAttachment;
  final List<String> operationSelections;
  final String createdAt;

  const AppReport({
    required this.id,
    required this.wellId,
    required this.reportNo,
    required this.userReportNo,
    required this.reportDate,
    required this.title,
    required this.notes,
    required this.recommendedTreatment,
    required this.remarks,
    required this.recapRemarks,
    required this.internalNotes,
    this.remarksAttachment,
    required this.operationSelections,
    required this.createdAt,
  });

  factory AppReport.fromJson(Map<String, dynamic> json) => AppReport(
    id: _text(json['_id'] ?? json['id']),
    wellId: _text(json['wellId']),
    reportNo: _text(json['reportNo']),
    userReportNo: _text(json['userReportNo']),
    reportDate: _text(json['reportDate']),
    title: _text(json['title']),
    notes: _text(json['notes']),
    recommendedTreatment: _text(json['recommendedTreatment']),
    remarks: _text(json['remarks']),
    recapRemarks: _text(json['recapRemarks']),
    internalNotes: _text(json['internalNotes']),
    remarksAttachment: ReportAttachment.fromJson(json['remarksAttachment']),
    operationSelections: _stringList(json['operationSelections']),
    createdAt: _text(json['createdAt']),
  );

  String get displayName {
    if (title.isNotEmpty) return title;
    if (userReportNo.isNotEmpty) return 'Report $userReportNo';
    if (reportNo.isNotEmpty) return 'Report $reportNo';
    return id.isEmpty ? 'Untitled Report' : 'Report $id';
  }
}

class ReportManagerRow {
  final String reportId;
  final String wellId;
  final String reportNo;
  final String userReportNo;
  final String reportDate;
  final String title;
  final String notes;
  final String recommendedTreatment;
  final String remarks;
  final String recapRemarks;
  final String internalNotes;
  final String activity;
  final String interval;
  final String engineer;
  final String engineer2;
  final String mudType;
  final double md;
  final double mw;
  final double dailyCost;
  final double cumulativeCost;
  final String createdAt;

  const ReportManagerRow({
    required this.reportId,
    required this.wellId,
    required this.reportNo,
    required this.userReportNo,
    required this.reportDate,
    required this.title,
    required this.notes,
    required this.recommendedTreatment,
    required this.remarks,
    required this.recapRemarks,
    required this.internalNotes,
    required this.activity,
    required this.interval,
    required this.engineer,
    required this.engineer2,
    required this.mudType,
    required this.md,
    required this.mw,
    required this.dailyCost,
    required this.cumulativeCost,
    required this.createdAt,
  });

  factory ReportManagerRow.fromJson(Map<String, dynamic> json) =>
      ReportManagerRow(
        reportId: _text(json['reportId'] ?? json['_id'] ?? json['id']),
        wellId: _text(json['wellId']),
        reportNo: _text(json['reportNo']),
        userReportNo: _text(json['userReportNo']),
        reportDate: _text(json['reportDate']),
        title: _text(json['title']),
        notes: _text(json['notes']),
        recommendedTreatment: _text(json['recommendedTreatment']),
        remarks: _text(json['remarks']),
        recapRemarks: _text(json['recapRemarks']),
        internalNotes: _text(json['internalNotes']),
        activity: _text(json['activity']),
        interval: _text(json['interval']),
        engineer: _text(json['engineer']),
        engineer2: _text(json['engineer2']),
        mudType: _text(json['mudType']),
        md: _doubleValue(json['md']),
        mw: _doubleValue(json['mw']),
        dailyCost: _doubleValue(json['dailyCost']),
        cumulativeCost: _doubleValue(json['cumulativeCost']),
        createdAt: _text(json['createdAt']),
      );

  String get reportLabel {
    if (userReportNo.isNotEmpty) return userReportNo;
    if (reportNo.isNotEmpty) return reportNo;
    return '-';
  }
}

class ReportAttachment {
  final String fileName;
  final String mimeType;
  final int size;
  final String data;

  const ReportAttachment({
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.data,
  });

  factory ReportAttachment.fromMap(Map<String, dynamic> json) =>
      ReportAttachment(
        fileName: _text(json['fileName'] ?? json['name']),
        mimeType: _text(json['mimeType'] ?? json['type']),
        size: _intValue(json['size']),
        data: _text(json['data'] ?? json['base64']),
      );

  static ReportAttachment? fromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      final attachment = ReportAttachment.fromMap(value);
      return attachment.fileName.isEmpty && attachment.data.isEmpty
          ? null
          : attachment;
    }
    if (value is Map) {
      final attachment = ReportAttachment.fromMap(
        Map<String, dynamic>.from(value),
      );
      return attachment.fileName.isEmpty && attachment.data.isEmpty
          ? null
          : attachment;
    }
    return null;
  }
}

String _text(dynamic value) => value?.toString().trim() ?? '';

List<String> _stringList(dynamic value) {
  if (value is! List) return const <String>[];
  final items = <String>[];
  final seen = <String>{};
  for (final item in value) {
    final parsed = _text(item);
    if (parsed.isEmpty || !seen.add(parsed)) continue;
    items.add(parsed);
  }
  return items;
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleValue(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}
