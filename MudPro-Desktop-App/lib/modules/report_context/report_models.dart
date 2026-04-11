class PumpRateAndPressureSummary {
  final double pumpRate;
  final double pumpPressure;
  final double boostPumpRate;
  final double returnRate;
  final double dhToolsPressureLoss;
  final double motorPressureLoss;

  const PumpRateAndPressureSummary({
    this.pumpRate = 0,
    this.pumpPressure = 0,
    this.boostPumpRate = 0,
    this.returnRate = 0,
    this.dhToolsPressureLoss = 0,
    this.motorPressureLoss = 0,
  });

  factory PumpRateAndPressureSummary.fromJson(dynamic json) {
    final map = json is Map<String, dynamic>
        ? json
        : json is Map
        ? Map<String, dynamic>.from(json)
        : const <String, dynamic>{};

    return PumpRateAndPressureSummary(
      pumpRate: _number(map['pumpRate']),
      pumpPressure: _number(map['pumpPressure']),
      boostPumpRate: _number(map['boostPumpRate']),
      returnRate: _number(map['returnRate']),
      dhToolsPressureLoss: _number(map['dhToolsPressureLoss']),
      motorPressureLoss: _number(map['motorPressureLoss']),
    );
  }

  Map<String, dynamic> toJson() => {
    'pumpRate': pumpRate,
    'pumpPressure': pumpPressure,
    'boostPumpRate': boostPumpRate,
    'returnRate': returnRate,
    'dhToolsPressureLoss': dhToolsPressureLoss,
    'motorPressureLoss': motorPressureLoss,
  };
}

class AppReport {
  final String id;
  final String wellId;
  final String reportNo;
  final String userReportNo;
  final String reportDate;
  final String title;
  final String notes;
  final String createdAt;
  final PumpRateAndPressureSummary pumpRateAndPressure;

  const AppReport({
    required this.id,
    required this.wellId,
    required this.reportNo,
    required this.userReportNo,
    required this.reportDate,
    required this.title,
    required this.notes,
    required this.createdAt,
    this.pumpRateAndPressure = const PumpRateAndPressureSummary(),
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
    pumpRateAndPressure: PumpRateAndPressureSummary.fromJson(
      json['pumpRateAndPressure'],
    ),
  );

  String get displayName {
    if (title.isNotEmpty) return title;
    if (userReportNo.isNotEmpty) return 'Report $userReportNo';
    if (reportNo.isNotEmpty) return 'Report $reportNo';
    return id.isEmpty ? 'Untitled Report' : 'Report $id';
  }
}

String _text(dynamic value) => value?.toString().trim() ?? '';

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '') ?? 0;
}
