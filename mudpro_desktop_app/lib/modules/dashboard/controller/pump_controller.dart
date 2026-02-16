import 'package:get/get.dart';

class PumpController extends GetxController {
  RxBool isLocked = true.obs;

  // ---------------- PUMP TABLE ----------------
  var pumpRows = <Map<String, dynamic>>[
    {
      "model": "BOMCO-F1600 #1",
      "type": "Triplex",
      "liner": 6.0,
      "stroke": 12.0,
      "eff": 97.0,
    },
    {
      "model": "BOMCO-F1600 #2",
      "type": "Triplex",
      "liner": 6.0,
      "stroke": 12.0,
      "eff": 97.0,
    },
  ].obs;

  final pumpModels = [
    "BOMCO-F1600 #1",
    "BOMCO-F1600 #2",
    "BOMCO-F1600 #3",
    "BOMCO-F1600 #4",
  ];

  // ---------------- SHAKER TABLE ----------------
  var shakerRows = <Map<String, String>>[
    {"shaker": "Shaker", "model": "DERRICK #1"},
    {"shaker": "Shaker", "model": "DERRICK #2"},
    {"shaker": "Cleaner", "model": "DERRICK #3"},
  ].obs;

  final shakerTypes = ["Shaker", "Cleaner", "Dryer"];

  // ---------------- OTHER SCE TABLE ----------------
  var sceRows = <Map<String, String>>[
    {"sce": "Degasser", "model": "CHENGDU"},
    {"sce": "Desander", "model": "DERRICK"},
    {"sce": "Desilter", "model": "DERRICK"},
    {"sce": "Centrifuge", "model": "KEMTRON"},
  ].obs;

  final sceTypes = ["Degasser", "Desander", "Desilter", "Centrifuge"];
}
