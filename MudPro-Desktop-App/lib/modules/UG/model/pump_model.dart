import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class PumpModel {
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

  String? id;
  RxInt rowNumber;
  RxString type;
  RxString model;
  RxString linerId;
  RxString rodOd;
  RxString strokeLength;
  RxString efficiency;
  RxString spm;
  RxString displacement;
  RxString rate;
  RxString maxPumpP;
  RxString maxHp;
  RxString surfaceLen;
  RxString surfaceId;

  void recalculateDisplacement() {
    final linerIdBase = AppUnits.parameterToBase(
      double.tryParse(linerId.value) ?? 0,
      paramNumber: '2',
      baseUnit: '(in)',
    );
    final strokeLengthBase = AppUnits.parameterToBase(
      double.tryParse(strokeLength.value) ?? 0,
      paramNumber: '2',
      baseUnit: '(in)',
    );
    final rodOdBase = AppUnits.parameterToBase(
      double.tryParse(rodOd.value) ?? 0,
      paramNumber: '2',
      baseUnit: '(in)',
    );
    final efficiencyFraction = (double.tryParse(efficiency.value) ?? 0) / 100;

    if ((linerIdBase ?? 0) == 0 ||
        (strokeLengthBase ?? 0) == 0 ||
        efficiencyFraction == 0) {
      displacement.value = '';
      return;
    }

    final linerIdInches = linerIdBase!;
    final strokeLengthInches = strokeLengthBase!;
    final rodOdInches = rodOdBase ?? 0;
    double displacementBase = 0;

    if (type.value == 'Duplex') {
      if (rodOdInches > 0) {
        displacementBase =
            0.000162 *
            (2 * linerIdInches * linerIdInches - rodOdInches * rodOdInches) *
            strokeLengthInches *
            efficiencyFraction;
      } else {
        displacementBase =
            0.000324 *
            linerIdInches *
            linerIdInches *
            strokeLengthInches *
            efficiencyFraction;
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
      }

      if (constant == 0) {
        displacement.value = '';
        return;
      }

      displacementBase =
          constant *
          linerIdInches *
          linerIdInches *
          strokeLengthInches *
          efficiencyFraction;
    }

    final displayDisplacement = AppUnits.parameterFromBase(
      displacementBase,
      paramNumber: '11',
      baseUnit: '(bbl/stk)',
    );

    displacement.value = AppUnits.formatNumber(
      displayDisplacement ?? displacementBase,
      precision: 4,
    );
  }

  factory PumpModel.fromJson(Map<String, dynamic> json) {
    return PumpModel(
      id: json['_id'] ?? json['id'],
      rowNumber: json['rowNumber'] ?? 0,
      type: json['type']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      linerId: _fromBaseNumber(
        json['linerId'],
        paramNumber: '2',
        baseUnit: '(in)',
        precision: 4,
      ),
      rodOd: _fromBaseNumber(
        json['rodOd'],
        paramNumber: '2',
        baseUnit: '(in)',
        precision: 4,
      ),
      strokeLength: _fromBaseNumber(
        json['strokeLength'],
        paramNumber: '2',
        baseUnit: '(in)',
        precision: 4,
      ),
      efficiency: _stringValue(json['efficiency']),
      spm: _stringValue(json['spm']),
      displacement: _fromBaseNumber(
        json['displacement'],
        paramNumber: '11',
        baseUnit: '(bbl/stk)',
        precision: 4,
      ),
      rate: _fromBaseNumber(
        json['rate'],
        paramNumber: '17',
        baseUnit: '(gpm)',
        precision: 4,
      ),
      maxPumpP: _fromBaseNumber(
        json['maxPumpP'],
        paramNumber: '22',
        baseUnit: '(psi)',
        precision: 2,
      ),
      maxHp: _fromBaseNumber(
        json['maxHp'],
        paramNumber: '26',
        baseUnit: '(HP)',
        precision: 2,
      ),
      surfaceLen: _fromBaseNumber(
        json['surfaceLen'],
        paramNumber: '1',
        baseUnit: '(m)',
        precision: 4,
      ),
      surfaceId: _fromBaseNumber(
        json['surfaceId'],
        paramNumber: '2',
        baseUnit: '(in)',
        precision: 4,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'rowNumber': rowNumber.value,
      'type': type.value,
      'model': model.value,
      'linerId': _toBaseNumber(linerId.value, paramNumber: '2', baseUnit: '(in)'),
      'rodOd': _toBaseNumber(rodOd.value, paramNumber: '2', baseUnit: '(in)'),
      'strokeLength': _toBaseNumber(
        strokeLength.value,
        paramNumber: '2',
        baseUnit: '(in)',
      ),
      'efficiency': double.tryParse(efficiency.value) ?? 0,
      'spm': double.tryParse(spm.value) ?? 0,
      'maxPumpP': _toBaseNumber(maxPumpP.value, paramNumber: '22', baseUnit: '(psi)'),
      'maxHp': _toBaseNumber(maxHp.value, paramNumber: '26', baseUnit: '(HP)'),
      'surfaceLen': _toBaseNumber(surfaceLen.value, paramNumber: '1', baseUnit: '(m)'),
      'surfaceId': _toBaseNumber(surfaceId.value, paramNumber: '2', baseUnit: '(in)'),
    };

    if (id != null) {
      data['_id'] = id;
    }

    return data;
  }

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

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString();
    if (text == '0' || text == '0.0') {
      return text;
    }
    return text;
  }

  static String _fromBaseNumber(
    dynamic rawValue, {
    required String paramNumber,
    required String baseUnit,
    int precision = 4,
  }) {
    final numericValue = double.tryParse(rawValue?.toString() ?? '');
    if (numericValue == null) {
      return rawValue?.toString() ?? '';
    }

    final displayValue = AppUnits.parameterFromBase(
      numericValue,
      paramNumber: paramNumber,
      baseUnit: baseUnit,
    );

    return AppUnits.formatNumber(displayValue ?? numericValue, precision: precision);
  }

  static double _toBaseNumber(
    String rawValue, {
    required String paramNumber,
    required String baseUnit,
  }) {
    final numericValue = double.tryParse(rawValue) ?? 0;
    final converted = AppUnits.parameterToBase(
      numericValue,
      paramNumber: paramNumber,
      baseUnit: baseUnit,
    );
    return converted ?? numericValue;
  }
}
