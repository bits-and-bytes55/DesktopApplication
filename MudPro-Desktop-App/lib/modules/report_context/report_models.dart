class AppReport {
  final String id;
  final String wellId;
  final String reportNo;
  final String userReportNo;
  final String reportDate;
  final String title;
  final String notes;
  final String createdAt;

  const AppReport({
    required this.id,
    required this.wellId,
    required this.reportNo,
    required this.userReportNo,
    required this.reportDate,
    required this.title,
    required this.notes,
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
    createdAt: _text(json['createdAt']),
  );

  String get displayName {
    if (title.isNotEmpty) return title;
    if (userReportNo.isNotEmpty) return 'Report $userReportNo';
    if (reportNo.isNotEmpty) return 'Report $reportNo';
    return id.isEmpty ? 'Untitled Report' : 'Report $id';
  }
}

String _text(dynamic value) => value?.toString().trim() ?? '';
