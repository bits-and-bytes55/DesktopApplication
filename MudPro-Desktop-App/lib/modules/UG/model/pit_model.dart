import 'package:get/get.dart';

class PitModel {
  String? id;
  String pitName;
  RxDouble capacity;
  RxBool initialActive;
  String? wellId;
  String? reportId;
  bool isLocked;
  DateTime? createdAt;
  DateTime? updatedAt;

  PitModel({
    this.id,
    required this.pitName,
    required double capacity,
    required bool initialActive,
    this.wellId,
    this.reportId,
    this.isLocked = false,
    this.createdAt,
    this.updatedAt,
  })  : capacity = capacity.obs,
        initialActive = initialActive.obs;

  // From JSON - FIXED: Handle both int and double for capacity
  factory PitModel.fromJson(Map<String, dynamic> json) {
    return PitModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      pitName: json['pitName']?.toString() ?? '',
      capacity: _toDouble(json['capacity'] ?? 0),
      initialActive: json['initialActive'] == true,
      wellId: json['wellId']?.toString(),
      reportId: json['reportId']?.toString(),
      isLocked: json['isLocked'] == true,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  // Helper to convert int/double to double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'pitName': pitName,
      'capacity': capacity.value,
      'initialActive': initialActive.value,
      if (wellId != null) 'wellId': wellId,
      if (reportId != null) 'reportId': reportId,
      'isLocked': isLocked,
    };
  }

  // For create/update requests
  Map<String, dynamic> toCreateJson() {
    return {
      'pitName': pitName,
      'capacity': capacity.value,
      'initialActive': initialActive.value,
      if (wellId != null) 'wellId': wellId,
      if (reportId != null) 'reportId': reportId,
    };
  }
}