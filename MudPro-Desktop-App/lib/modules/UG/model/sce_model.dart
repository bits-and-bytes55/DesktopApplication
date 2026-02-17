import 'package:get/get.dart';

// ================= SHAKER MODEL =================
class ShakerModel {
  String? id;
  RxString shaker; // Shaker number (1, 2, 3...)
  RxString model;
  RxString screens;
  RxBool plot;
  RxString screen1;
  RxString screen2;
  RxString screen3;
  RxString screen4;
  RxString time;
  RxString oocWt;

  // For tracking edit mode
  RxBool isEditing = false.obs;

  ShakerModel({
    this.id,
    String? shaker,
    String? model,
    String? screens,
    bool? plot,
    String? screen1,
    String? screen2,
    String? screen3,
    String? screen4,
    String? time,
    String? oocWt,
  })  : shaker = (shaker ?? '').obs,
        model = (model ?? '').obs,
        screens = (screens ?? '').obs,
        plot = (plot ?? false).obs,
        screen1 = (screen1 ?? '').obs,
        screen2 = (screen2 ?? '').obs,
        screen3 = (screen3 ?? '').obs,
        screen4 = (screen4 ?? '').obs,
        time = (time ?? '').obs,
        oocWt = (oocWt ?? '').obs;

  // From JSON
  factory ShakerModel.fromJson(Map<String, dynamic> json) {
    return ShakerModel(
      id: json['_id'] ?? json['id'],
      shaker: json['shaker']?.toString() ?? '',
      model: json['model'] ?? '',
      screens: json['screens']?.toString() ?? '',
      plot: json['plot'] ?? false,
      screen1: json['screen1'] ?? '',
      screen2: json['screen2'] ?? '',
      screen3: json['screen3'] ?? '',
      screen4: json['screen4'] ?? '',
      time: json['time'] ?? '',
      oocWt: json['oocWt'] ?? '',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'shaker': shaker.value,
      'model': model.value,
      'screens': screens.value,
      'plot': plot.value,
      'screen1': screen1.value,
      'screen2': screen2.value,
      'screen3': screen3.value,
      'screen4': screen4.value,
      'time': time.value,
      'oocWt': oocWt.value,
    };

    if (id != null) {
      data['_id'] = id;
    }

    return data;
  }

  // Check if shaker has any data
  bool get hasData {
    return model.value.isNotEmpty || screens.value.isNotEmpty;
  }

  // Clone shaker
  ShakerModel clone() {
    return ShakerModel(
      id: id,
      shaker: shaker.value,
      model: model.value,
      screens: screens.value,
      plot: plot.value,
      screen1: screen1.value,
      screen2: screen2.value,
      screen3: screen3.value,
      screen4: screen4.value,
      time: time.value,
      oocWt: oocWt.value,
    );
  }
}

// ================= OTHER SCE MODEL =================
class OtherSceModel {
  String? id;
  RxString type;
  RxString model1;
  RxString model2;
  RxString model3;
  RxBool plot;
  RxString uf;
  RxString of;
  RxString time;
  RxString oocWt;
  
  // For tracking edit mode
  RxBool isEditing = false.obs;

  OtherSceModel({
    this.id,
    String? type,
    String? model1,
    String? model2,
    String? model3,
    bool? plot,
    String? uf,
    String? of,
    String? time,
    String? oocWt,
  })  : type = (type ?? '').obs,
        model1 = (model1 ?? '').obs,
        model2 = (model2 ?? '').obs,
        model3 = (model3 ?? '').obs,
        plot = (plot ?? false).obs,
        uf = (uf ?? '').obs,
        of = (of ?? '').obs,
        time = (time ?? '').obs,
        oocWt = (oocWt ?? '').obs;

  // From JSON
  factory OtherSceModel.fromJson(Map<String, dynamic> json) {
    return OtherSceModel(
      id: json['_id'] ?? json['id'],
      type: json['type'] ?? '',
      model1: json['model1'] ?? '',
      model2: json['model2'] ?? '',
      model3: json['model3'] ?? '',
      plot: json['plot'] ?? false,
      uf: json['uf'] ?? '',
      of: json['of'] ?? '',
      time: json['time'] ?? '',
      oocWt: json['oocWt'] ?? '',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type.value,
      'model1': model1.value,
      'model2': model2.value,
      'model3': model3.value,
      'plot': plot.value,
      'uf': uf.value,
      'of': of.value,
      'time': time.value,
      'oocWt': oocWt.value,
    };

    if (id != null) {
      data['_id'] = id;
    }

    return data;
  }

  // Check if SCE has any data
  bool get hasData {
    return type.value.isNotEmpty ||
        model1.value.isNotEmpty ||
        model2.value.isNotEmpty ||
        model3.value.isNotEmpty;
  }

  // Clone SCE
  OtherSceModel clone() {
    return OtherSceModel(
      id: id,
      type: type.value,
      model1: model1.value,
      model2: model2.value,
      model3: model3.value,
      plot: plot.value,
      uf: uf.value,
      of: of.value,
      time: time.value,
      oocWt: oocWt.value,
    );
  }
}