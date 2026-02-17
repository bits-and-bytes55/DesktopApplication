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
  RxString displacement;
  RxString maxPumpP;
  RxString maxHp;
  RxString surfaceLen;
  RxString surfaceId;
  RxString stroke;
  RxString rate;

  PumpModel({
    this.id,
    int? rowNumber,
    String? type,
    String? model,
    String? linerId,
    String? rodOd,
    String? strokeLength,
    String? efficiency,
    String? displacement,
    String? maxPumpP,
    String? maxHp,
    String? surfaceLen,
    String? surfaceId,
    String? stroke,
    String? rate,
  })  : rowNumber = (rowNumber ?? 0).obs,
        type = (type ?? '').obs,
        model = (model ?? '').obs,
        linerId = (linerId ?? '').obs,
        rodOd = (rodOd ?? '').obs,
        strokeLength = (strokeLength ?? '').obs,
        efficiency = (efficiency ?? '').obs,
        displacement = (displacement ?? '').obs,
        maxPumpP = (maxPumpP ?? '').obs,
        maxHp = (maxHp ?? '').obs,
        surfaceLen = (surfaceLen ?? '').obs,
        surfaceId = (surfaceId ?? '').obs,
        stroke = (stroke ?? '').obs,
        rate = (rate ?? '').obs;

  // From JSON
  factory PumpModel.fromJson(Map<String, dynamic> json) {
    return PumpModel(
      id: json['_id'] ?? json['id'],
      rowNumber: json['rowNumber'] ?? 0,
      type: json['type'] ?? '',
      model: json['model'] ?? '',
      linerId: json['linerId'] ?? '',
      rodOd: json['rodOd'] ?? '',
      strokeLength: json['strokeLength'] ?? '',
      efficiency: json['efficiency'] ?? '',
      displacement: json['displacement'] ?? '',
      maxPumpP: json['maxPumpP'] ?? '',
      maxHp: json['maxHp'] ?? '',
      surfaceLen: json['surfaceLen'] ?? '',
      surfaceId: json['surfaceId'] ?? '',
      stroke: json['stroke'] ?? '',
      rate: json['rate'] ?? '',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'rowNumber': rowNumber.value,
      'type': type.value,
      'model': model.value,
      'linerId': linerId.value,
      'rodOd': rodOd.value,
      'strokeLength': strokeLength.value,
      'efficiency': efficiency.value,
      'displacement': displacement.value,
      'maxPumpP': maxPumpP.value,
      'maxHp': maxHp.value,
      'surfaceLen': surfaceLen.value,
      'surfaceId': surfaceId.value,
      'stroke': stroke.value,
      'rate': rate.value,
    };

    if (id != null) {
      data['_id'] = id;
    }

    return data;
  }

  // Check if pump has any data
  bool get hasData {
    return type.value.isNotEmpty ||
        model.value.isNotEmpty ||
        linerId.value.isNotEmpty ||
        rodOd.value.isNotEmpty ||
        strokeLength.value.isNotEmpty ||
        efficiency.value.isNotEmpty ||
        displacement.value.isNotEmpty ||
        maxPumpP.value.isNotEmpty ||
        maxHp.value.isNotEmpty ||
        surfaceLen.value.isNotEmpty ||
        surfaceId.value.isNotEmpty;
  }

  // Clone pump
  PumpModel clone() {
    return PumpModel(
      id: id,
      rowNumber: rowNumber.value,
      type: type.value,
      model: model.value,
      linerId: linerId.value,
      rodOd: rodOd.value,
      strokeLength: strokeLength.value,
      efficiency: efficiency.value,
      displacement: displacement.value,
      maxPumpP: maxPumpP.value,
      maxHp: maxHp.value,
      surfaceLen: surfaceLen.value,
      surfaceId: surfaceId.value,
      stroke: stroke.value,
      rate: rate.value,
    );
  }
}