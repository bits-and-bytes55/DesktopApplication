import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

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
  RxString displacement; // auto-calculated locally + confirmed by backend
  RxString rate; // calculated by backend (shown on other pump page)
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
  }) : rowNumber = (rowNumber ?? 0).obs,
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

  static String _formatNumber(double value, {int decimals = 4}) {
    if (value == value.truncateToDouble()) {
      return value.truncate().toString();
    }

    return value
        .toStringAsFixed(decimals)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  static String _fromBaseValue(
    dynamic value,
    String fromUnit,
    String toUnit, {
    int decimals = 4,
  }) {
    if (value == null) return '';
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().trim());
    if (parsed == null) return value.toString();

    final converted = AppUnits.convertValue(parsed, fromUnit, toUnit) ?? parsed;
    return _formatNumber(converted, decimals: decimals);
  }

  static double _toBaseValue(String rawValue, String fromUnit, String toUnit) {
    final parsed = double.tryParse(rawValue.trim()) ?? 0;
    return AppUnits.convertValue(parsed, fromUnit, toUnit) ?? parsed;
  }

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
    final diameterValue = double.tryParse(linerId.value) ?? 0;
    final strokeLengthValue = double.tryParse(strokeLength.value) ?? 0;
    final eff = (double.tryParse(efficiency.value) ?? 0) / 100;
    final rodValue = double.tryParse(rodOd.value) ?? 0; // only used for Duplex

    final D =
        AppUnits.convertValue(diameterValue, AppUnits.diameter, '(in)') ??
        diameterValue;
    final L =
        AppUnits.convertValue(strokeLengthValue, AppUnits.length, '(in)') ??
        strokeLengthValue;
    final d =
        AppUnits.convertValue(rodValue, AppUnits.diameter, '(in)') ?? rodValue;

    if (D == 0 || L == 0 || eff == 0) {
      displacement.value = '';
      return;
    }

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
        case 'Triplex':
          constant = 0.000243;
          break;
        case 'Quadplex':
          constant = 0.000324;
          break;
        case 'Quintuplex':
          constant = 0.000405;
          break;
        default:
          constant = 0;
      }
      if (constant == 0) {
        displacement.value = '';
        return;
      }
      result = constant * D * D * L * eff;
    }

    final displayValue =
        AppUnits.convertValue(
          result,
          '(bbl/stk)',
          AppUnits.strokeDisplacement,
        ) ??
        result;
    displacement.value = displayValue.toStringAsFixed(4);
  }

  // From JSON - for GET responses
  factory PumpModel.fromJson(Map<String, dynamic> json) {
    return PumpModel(
      id: json['_id'] ?? json['id'],
      rowNumber: json['rowNumber'] ?? 0,
      type: json['type']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      linerId: _fromBaseValue(json['linerId'], '(in)', AppUnits.diameter),
      rodOd: _fromBaseValue(json['rodOd'], '(in)', AppUnits.diameter),
      strokeLength: _fromBaseValue(
        json['strokeLength'],
        '(in)',
        AppUnits.length,
      ),
      efficiency: json['efficiency']?.toString() ?? '',
      spm: json['spm']?.toString() ?? '',
      displacement: _fromBaseValue(
        json['displacement'],
        '(bbl/stk)',
        AppUnits.strokeDisplacement,
      ),
      rate: _fromBaseValue(json['rate'], '(gpm)', AppUnits.drillingFlowRate),
      maxPumpP: _fromBaseValue(json['maxPumpP'], '(psi)', AppUnits.pressure),
      maxHp: _fromBaseValue(json['maxHp'], '(HP)', AppUnits.power),
      surfaceLen: _fromBaseValue(json['surfaceLen'], '(ft)', AppUnits.length),
      surfaceId: _fromBaseValue(json['surfaceId'], '(in)', AppUnits.diameter),
    );
  }

  // To JSON - for POST/PUT requests
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'rowNumber': rowNumber.value,
      'type': type.value,
      'model': model.value,
      'linerId': _toBaseValue(linerId.value, AppUnits.diameter, '(in)'),
      'rodOd': _toBaseValue(rodOd.value, AppUnits.diameter, '(in)'),
      'strokeLength': _toBaseValue(strokeLength.value, AppUnits.length, '(in)'),
      'efficiency': double.tryParse(efficiency.value) ?? 0,
      'spm': double.tryParse(spm.value) ?? 0,
      'maxPumpP': _toBaseValue(maxPumpP.value, AppUnits.pressure, '(psi)'),
      'maxHp': _toBaseValue(maxHp.value, AppUnits.power, '(HP)'),
      'surfaceLen': _toBaseValue(surfaceLen.value, AppUnits.length, '(ft)'),
      'surfaceId': _toBaseValue(surfaceId.value, AppUnits.diameter, '(in)'),
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

  bool operator [](String other) {
    return false;
  }
}
