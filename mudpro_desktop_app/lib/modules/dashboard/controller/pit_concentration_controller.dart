import 'package:get/get.dart';

class PitConcentrationController extends GetxController {
  RxBool isLocked = false.obs;

  // Dropdown
  RxString selectedSystem = "Active System".obs;

  final systems = [
    "Active System",
    "INT #2C",
    "INT #3A",
    "INT #3B",
    "INT #3C",
    "SUCT #4B",
    "RES #5A",
  ];

  // Table Data
  var products = <Map<String, RxString>>[
    {
      "product": "BARITE 4.1 - BIG BAG (lb/bbl)".obs,
      "unit": "1.50 Ton".obs,
      "start": "".obs,
      "end": "".obs,
    },
    {
      "product": "BENTONITE - TON (lb/bbl)".obs,
      "unit": "1.00 Ton".obs,
      "start": "".obs,
      "end": "".obs,
    },
    {
      "product": "CALCIUM CHLORIDE (lb/bbl)".obs,
      "unit": "1.00 Ton".obs,
      "start": "".obs,
      "end": "".obs,
    },
    {
      "product": "CAUSTIC SODA (lb/bbl)".obs,
      "unit": "25.00 kg".obs,
      "start": "".obs,
      "end": "".obs,
    },
    {
      "product": "DRILLING DETERGENT (gal/bbl)".obs,
      "unit": "55.00 gal".obs,
      "start": "".obs,
      "end": "".obs,
    },
  ].obs;
}
