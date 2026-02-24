import 'package:get/get.dart';

class PumpModel {
  String? id;

  RxInt rowNumber;
  RxString type;
  RxString model;
  RxString linerId;
  RxString rodOd;
  RxString strokeLength;
  RxString efficiency;
  RxString spm;
  RxString displacement;   // calculated from backend
  RxString rate;           // calculated from backend
  RxString maxPumpP;
  RxString maxHp;
  RxString surfaceLen;
  RxString surfaceId;

  PumpModel({
    this.id,
    int? rowNumber,
    String? type,
    String? model,
    String? linerId,
    String? rodOd,
    String? strokeLength,
    String? efficiency,
    String? spm,
    String? displacement,
    String? rate,
    String? maxPumpP,
    String? maxHp,
    String? surfaceLen,
    String? surfaceId,
  })  : rowNumber = (rowNumber ?? 0).obs,
        type = (type ?? '').obs,
        model = (model ?? '').obs,
        linerId = (linerId ?? '').obs,
        rodOd = (rodOd ?? '').obs,
        strokeLength = (strokeLength ?? '').obs,
        efficiency = (efficiency ?? '').obs,
        spm = (spm ?? '').obs,
        displacement = (displacement ?? '').obs,
        rate = (rate ?? '').obs,
        maxPumpP = (maxPumpP ?? '').obs,
        maxHp = (maxHp ?? '').obs,
        surfaceLen = (surfaceLen ?? '').obs,
        surfaceId = (surfaceId ?? '').obs;

  factory PumpModel.fromJson(Map<String, dynamic> json) {
    return PumpModel(
      id: json['_id'],
      rowNumber: json['rowNumber'],
      type: json['type']?.toString(),
      model: json['model']?.toString(),
      linerId: json['linerId']?.toString(),
      rodOd: json['rodOd']?.toString(),
      strokeLength: json['strokeLength']?.toString(),
      efficiency: json['efficiency']?.toString(),
      spm: json['spm']?.toString(),
      displacement: json['displacement']?.toString(),
      rate: json['rate']?.toString(),
      maxPumpP: json['maxPumpP']?.toString(),
      maxHp: json['maxHp']?.toString(),
      surfaceLen: json['surfaceLen']?.toString(),
      surfaceId: json['surfaceId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rowNumber': rowNumber.value,
      'type': type.value,
      'model': model.value,
      'linerId': double.tryParse(linerId.value) ?? 0,
      'rodOd': double.tryParse(rodOd.value) ?? 0,
      'strokeLength': double.tryParse(strokeLength.value) ?? 0,
      'efficiency': double.tryParse(efficiency.value) ?? 0,
      'spm': double.tryParse(spm.value) ?? 0,
      'maxPumpP': double.tryParse(maxPumpP.value) ?? 0,
      'maxHp': double.tryParse(maxHp.value) ?? 0,
      'surfaceLen': double.tryParse(surfaceLen.value) ?? 0,
      'surfaceId': double.tryParse(surfaceId.value) ?? 0,
    };
  }

  bool get hasData {
    return type.value.isNotEmpty ||
        model.value.isNotEmpty ||
        linerId.value.isNotEmpty ||
        strokeLength.value.isNotEmpty;
  }
}