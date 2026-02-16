import 'package:get/get.dart';

class PitController extends GetxController {
  RxBool isLocked = true.obs;

  // ---------------- ACTIVE PITS ----------------
  var activePits = <Map<String, RxString>>[
    {
      "pit": "TRIP TANK".obs,
      "vol": "".obs,
      "mw": "".obs,
      "mud": "".obs,
    },
    {
      "pit": "DESANDER #2A".obs,
      "vol": "100.00".obs,
      "mw": "8.40".obs,
      "mud": "Brackish Water".obs,
    },
    {
      "pit": "DESILTER #2B".obs,
      "vol": "100.00".obs,
      "mw": "8.40".obs,
      "mud": "Brackish Water".obs,
    },
    {
      "pit": "SUCT #4A".obs,
      "vol": "266.79".obs,
      "mw": "8.40".obs,
      "mud": "Brackish Water".obs,
    },
  ].obs;

  // ---------------- STORAGE ----------------
  var storage = <Map<String, RxString>>[
    {
      "pit": "INT #2C".obs,
      "calc": "0.00".obs,
      "meas": "110.00".obs,
      "mw": "".obs,
      "fluid": "Brackish Water".obs,
    },
    {
      "pit": "SUCT #4B".obs,
      "calc": "0.00".obs,
      "meas": "250.00".obs,
      "mw": "".obs,
      "fluid": "Brackish Water".obs,
    },
  ].obs;

  // ---------------- VOLUME SUMMARY ----------------
  var volumeSummary = <Map<String, String>>[
    {"label": "Active Pits", "value": "466.79"},
    {"label": "Active System", "value": "466.79"},
    {"label": "Total Storage", "value": "360.00"},
    {"label": "Total on Location", "value": "826.79"},
  ].obs;

  // ---------------- HAUL OFF ----------------
  var haulOff = <Map<String, RxString>>[
    {"label": "No. of Loads".obs, "value": "".obs},
    {"label": "Oil (%)".obs, "value": "".obs},
    {"label": "Water (%)".obs, "value": "".obs},
    {"label": "Solids (%)".obs, "value": "".obs},
  ].obs;
}
