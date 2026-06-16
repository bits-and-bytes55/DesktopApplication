import 'package:get/get.dart';

String _blankZero(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '';
  final number = double.tryParse(text.replaceAll(',', ''));
  if (number != null && number == 0) return '';
  return text;
}

// ================= SHAKER MODEL =================
class ShakerModel {
  String? id;
  RxString shaker; // Shaker type (Shaker/Cleaner/Dryer)
  RxString model;
  RxString screens;
  RxBool plot;
  RxString screen1;
  RxString screen2;
  RxString screen3;
  RxString screen4;
  RxString screen5; // ✅ Added
  RxString screen6; // ✅ Added
  RxString screen7; // ✅ Added
  RxString screen8; // ✅ Added
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
    String? screen5,
    String? screen6,
    String? screen7,
    String? screen8,
    String? time,
    String? oocWt,
  }) : shaker = (shaker ?? '').obs,
       model = (model ?? '').obs,
       screens = (screens ?? '').obs,
       plot = (plot ?? false).obs,
       screen1 = (screen1 ?? '').obs,
       screen2 = (screen2 ?? '').obs,
       screen3 = (screen3 ?? '').obs,
       screen4 = (screen4 ?? '').obs,
       screen5 = (screen5 ?? '').obs,
       screen6 = (screen6 ?? '').obs,
       screen7 = (screen7 ?? '').obs,
       screen8 = (screen8 ?? '').obs,
       time = (time ?? '').obs,
       oocWt = (oocWt ?? '').obs;

  // From JSON
  factory ShakerModel.fromJson(Map<String, dynamic> json) {
    return ShakerModel(
      id: json['_id'] ?? json['id'],
      shaker: _blankZero(json['shaker']),
      model: _blankZero(json['model']),
      screens: _blankZero(json['screens']),
      plot: json['plot'] ?? false,
      screen1: _blankZero(json['screen1']),
      screen2: _blankZero(json['screen2']),
      screen3: _blankZero(json['screen3']),
      screen4: _blankZero(json['screen4']),
      screen5: _blankZero(json['screen5']),
      screen6: _blankZero(json['screen6']),
      screen7: _blankZero(json['screen7']),
      screen8: _blankZero(json['screen8']),
      time: _blankZero(json['time']),
      oocWt: _blankZero(json['oocWt']),
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
      'screen5': screen5.value,
      'screen6': screen6.value,
      'screen7': screen7.value,
      'screen8': screen8.value,
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
    return model.value.isNotEmpty ||
        screens.value.isNotEmpty ||
        plot.value ||
        screen1.value.isNotEmpty ||
        screen2.value.isNotEmpty ||
        screen3.value.isNotEmpty ||
        screen4.value.isNotEmpty ||
        screen5.value.isNotEmpty ||
        screen6.value.isNotEmpty ||
        screen7.value.isNotEmpty ||
        screen8.value.isNotEmpty ||
        time.value.isNotEmpty ||
        oocWt.value.isNotEmpty;
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
      screen5: screen5.value,
      screen6: screen6.value,
      screen7: screen7.value,
      screen8: screen8.value,
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
  }) : type = (type ?? '').obs,
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
      type: _blankZero(json['type']),
      model1: _blankZero(json['model1']),
      model2: _blankZero(json['model2']),
      model3: _blankZero(json['model3']),
      plot: json['plot'] ?? false,
      uf: _blankZero(json['uf']),
      of: _blankZero(json['of']),
      time: _blankZero(json['time']),
      oocWt: _blankZero(json['oocWt']),
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
    return model1.value.isNotEmpty ||
        model2.value.isNotEmpty ||
        model3.value.isNotEmpty ||
        plot.value ||
        uf.value.isNotEmpty ||
        of.value.isNotEmpty ||
        time.value.isNotEmpty ||
        oocWt.value.isNotEmpty;
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
