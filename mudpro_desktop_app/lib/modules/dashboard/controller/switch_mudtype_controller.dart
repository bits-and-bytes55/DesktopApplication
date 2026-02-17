import 'package:get/get.dart';

class SwitchMudTypeController extends GetxController {
  // Radio selections
  RxInt section1Selected = 0.obs; // 0 = left, 1 = right
  RxInt section2Selected = 0.obs;

  // Dropdown values
  final List<String> pitList = [
    "Suction 4A",
    "Suction 4B",
    "Intermediate 2C",
    "Reserve 5B",
    "Reserve 6A",
    "Reserve 6B",
  ];



  RxList<String?> section1Left = <String?>[].obs;
  RxList<String?> section1Right = <String?>[].obs;
  RxList<String?> section2Left = <String?>[].obs;
  RxList<String?> section2Right = <String?>[].obs;
  RxList<String?> section3 = <String?>[].obs;

  @override
  void onInit() {
    super.onInit();
    section1Left.assignAll(List.filled(3, null));
    section1Right.assignAll(List.filled(3, null));
    section2Left.assignAll(List.filled(3, null));
    section2Right.assignAll(List.filled(3, null));
    section3.assignAll(List.filled(3, null));
  }
}
