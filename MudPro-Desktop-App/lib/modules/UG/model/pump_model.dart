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
  RxString displacement;   // auto-calculated locally + confirmed by backend
  RxString rate;           // calculated by backend (shown on other pump page)
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



// AFTER (correct — matches backend & original software)
// void recalculateDisplacement() {
//   final D = double.tryParse(linerId.value) ?? 0;
//   final L = double.tryParse(strokeLength.value) ?? 0;
//   final eff = (double.tryParse(efficiency.value) ?? 0) / 100;

//   double constant = 0;
//   switch (type.value) {
//     case 'Duplex':     constant = 0.000324; break; // double-acting
//     case 'Triplex':    constant = 0.000243; break;
//     case 'Quadplex':   constant = 0.000324; break;
//     case 'Quintuplex': constant = 0.000405; break;
//     default:           constant = 0;
//   }

//   if (D == 0 || L == 0 || eff == 0 || constant == 0) {
//     displacement.value = '';
//     return;
//   }

//   final result = constant * D * D * L * eff;
//   displacement.value = result.toStringAsFixed(4);
// }

// AFTER — Duplex uses rod formula when rodOd is provided
void recalculateDisplacement() {
  final D = double.tryParse(linerId.value) ?? 0;
  final L = double.tryParse(strokeLength.value) ?? 0;
  final eff = (double.tryParse(efficiency.value) ?? 0) / 100;
  final d = double.tryParse(rodOd.value) ?? 0; // only used for Duplex

  if (D == 0 || L == 0 || eff == 0) { displacement.value = ''; return; }

  double result = 0;

  if (type.value == 'Duplex') {
    if (d > 0) {
      // With rod: 0.000162 × (2D² - d²) × L × Efficiency
      result = 0.000162 * (2 * D * D - d * d) * L * eff;
    } else {
      // Without rod (approximation)
      result = 0.000324 * D * D * L * eff;
    }
  } else {
    double constant = 0;
    switch (type.value) {
      case 'Triplex':    constant = 0.000243; break;
      case 'Quadplex':   constant = 0.000324; break;
      case 'Quintuplex': constant = 0.000405; break;
      default:           constant = 0;
    }
    if (constant == 0) { displacement.value = ''; return; }
    result = constant * D * D * L * eff;
  }

  displacement.value = result.toStringAsFixed(4);
}


  // From JSON - for GET responses
  factory PumpModel.fromJson(Map<String, dynamic> json) {
    return PumpModel(
      id: json['_id'] ?? json['id'],
      rowNumber: json['rowNumber'] ?? 0,
      type: json['type']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      linerId: json['linerId']?.toString() ?? '',
      rodOd: json['rodOd']?.toString() ?? '',
      strokeLength: json['strokeLength']?.toString() ?? '',
      efficiency: json['efficiency']?.toString() ?? '',
      spm: json['spm']?.toString() ?? '',
      displacement: json['displacement']?.toString() ?? '',
      rate: json['rate']?.toString() ?? '',
      maxPumpP: json['maxPumpP']?.toString() ?? '',
      maxHp: json['maxHp']?.toString() ?? '',
      surfaceLen: json['surfaceLen']?.toString() ?? '',
      surfaceId: json['surfaceId']?.toString() ?? '',
    );
  }

  // To JSON - for POST/PUT requests
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
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
      // displacement and rate are calculated by backend
    };

    if (id != null) {
      data['_id'] = id;
    }

    return data;
  }

  // Check if pump has any data (for save button visibility)
  bool get hasData {
    return type.value.isNotEmpty ||
        model.value.isNotEmpty ||
        linerId.value.isNotEmpty ||
        rodOd.value.isNotEmpty ||
        strokeLength.value.isNotEmpty ||
        efficiency.value.isNotEmpty ||
        spm.value.isNotEmpty ||
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
      spm: spm.value,
      displacement: displacement.value,
      rate: rate.value,
      maxPumpP: maxPumpP.value,
      maxHp: maxHp.value,
      surfaceLen: surfaceLen.value,
      surfaceId: surfaceId.value,
    );
  }
}