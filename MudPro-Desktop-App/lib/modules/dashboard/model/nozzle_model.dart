import 'package:get/get.dart';

class NozzleEntry {
  RxInt count;
  RxInt size32;
  RxDouble diameterInch;
  RxDouble area;

  NozzleEntry({
    int count = 0,
    int size32 = 0,
    double diameterInch = 0,
    double area = 0,
  }) : count = count.obs,
       size32 = size32.obs,
       diameterInch = diameterInch.obs,
       area = area.obs;

  factory NozzleEntry.fromJson(Map<String, dynamic> json) => NozzleEntry(
    count: ((json['count'] ?? 0) as num).toInt(),
    size32: ((json['size32'] ?? 0) as num).toInt(),
    diameterInch: ((json['diameterInch'] ?? 0) as num).toDouble(),
    area: ((json['area'] ?? 0) as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'count': count.value,
    'size32': size32.value,
  };

  bool get hasData => size32.value > 0;
}

class NozzleModel {
  String? id;
  String bitType;
  String bitModel;
  List<NozzleEntry> nozzles;
  double tfa;

  NozzleModel({
    this.id,
    this.bitType = '',
    this.bitModel = '',
    required this.nozzles,
    this.tfa = 0,
  });

  factory NozzleModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> nozzleList = json['nozzles'] ?? [];
    return NozzleModel(
      id: json['_id']?.toString(),
      bitType: json['bitType']?.toString() ?? '',
      bitModel: json['bitModel']?.toString() ?? '',
      nozzles: nozzleList.map((n) => NozzleEntry.fromJson(n)).toList(),
      tfa: ((json['tfa'] ?? 0) as num).toDouble(),
    );
  }
}
