
import 'package:get/get.dart';

class PumpModel {
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

  PumpModel({
    required this.type,
    required this.model,
    required this.linerId,
    required this.rodOd,
    required this.strokeLength,
    required this.efficiency,
    required this.displacement,
    required this.maxPumpP,
    required this.maxHp,
    required this.surfaceLen,
    required this.surfaceId,
  });
}
