import 'package:get/get.dart';

class EmptyActiveSystemController extends GetxController {
  // Radio selection
  RxBool isDumpSelected = true.obs;

  // Selected row for dropdown
  RxInt activeDropdownRow = 0.obs;

  // Pit dropdown list
  final pits = [
    "Intermediate 2 C",
    "Suction 4A",
    "Suction 4B",
    "Reserve 5B",
    "Reserve 6A",
    "Reserve 6B",
  ];

  // Table data
  final pitValues = List<String>.generate(5, (_) => "").obs;
  final volValues = List<String>.generate(5, (_) => "").obs;

  bool get isTableEnabled => !isDumpSelected.value;

  void selectRow(int index) {
    activeDropdownRow.value = index;
  }

  void setPit(int row, String value) {
    pitValues[row] = value;
  }

  // Demo adjust logic
  void adjustVolumes() {
    for (int i = 0; i < volValues.length; i++) {
      if (pitValues[i].isNotEmpty) {
        volValues[i] = "100.00";
      }
    }
  }
}
