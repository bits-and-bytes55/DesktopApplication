import 'package:get/get.dart';

class PitModel {
  final int id;
  final String pit;
  String capacity;
  final RxBool active;

  PitModel({
    required this.id,
    required this.pit,
    required this.capacity,
    required bool active,
  }) : active = active.obs;
}
