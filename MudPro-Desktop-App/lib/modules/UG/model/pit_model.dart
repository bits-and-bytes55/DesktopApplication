import 'package:get/get.dart';

class PitModel {
  String? id;
  String pitName;
  RxDouble capacity;
  RxBool initialActive;
  bool isLocked;
  String? wellId;
  String? reportId;

  // ── New editable fields ──────────────────────────────────────────────────
  RxDouble? volume;
  RxDouble? density;
  RxString? fluidType;

  PitModel({
    this.id,
    required this.pitName,
    required double capacity,
    bool initialActive = false,
    this.isLocked = false,
    this.wellId,
    this.reportId,
    double volumeVal = 0.0,
    double densityVal = 0.0,
    String fluidTypeVal = '',
  })  : capacity = capacity.obs,
        initialActive = initialActive.obs,
        volume = volumeVal.obs,
        density = densityVal.obs,
        fluidType = fluidTypeVal.obs;

  factory PitModel.fromJson(Map<String, dynamic> json) {
    return PitModel(
      id: json['_id']?.toString(),
      pitName: json['pitName']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
      initialActive: json['initialActive'] == true,
      isLocked: json['isLocked'] == true,
      wellId: json['wellId']?.toString(),
      reportId: json['reportId']?.toString(),
      volumeVal: (json['volume'] as num?)?.toDouble() ?? 0.0,
      densityVal: (json['density'] as num?)?.toDouble() ?? 0.0,
      fluidTypeVal: json['fluidType']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'pitName': pitName,
        'capacity': capacity.value,
        'initialActive': initialActive.value,
        'isLocked': isLocked,
        if (wellId != null) 'wellId': wellId,
        if (reportId != null) 'reportId': reportId,
        'volume': volume?.value ?? 0,
        'density': density?.value ?? 0,
        'fluidType': fluidType?.value ?? '',
      };
}