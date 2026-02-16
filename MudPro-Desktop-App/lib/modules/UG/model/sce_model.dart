import 'package:get/get.dart';

class ShakerModel {
  final int id;
  final String shaker;
  final RxString model;
  final RxString screens;
  final RxBool plot;

  ShakerModel({
    required this.id,
    required this.shaker,
    required String model,
    required String screens,
    required bool plot,
  })  : model = model.obs,
        screens = screens.obs,
        plot = plot.obs;
}

class OtherSceModel {
  final String type;
  final RxString model1;
  final RxString model2;
  final RxString model3;
  final RxBool plot;

  OtherSceModel({
    required this.type,
    String model1 = '',
    String model2 = '',
    String model3 = '',
    bool plot = false,
  })  : model1 = model1.obs,
        model2 = model2.obs,
        model3 = model3.obs,
        plot = plot.obs;
}
