import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';

class SwitchMudTypeController extends GetxController {
  // Radio selections
  RxInt section1Selected = 0.obs; // 0 = left, 1 = right
  RxInt section2Selected = 0.obs;

  final PitController pitController = Get.isRegistered<PitController>()
      ? Get.find<PitController>()
      : Get.put(PitController());

  final RxList<String> pitList = <String>[].obs;

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
    loadPits();
  }

  Future<void> loadPits() async {
    await pitController.fetchSelectedPits();
    await pitController.fetchUnselectedPits();
    final names = <String>[];
    for (final pit in [
      ...pitController.selectedPits,
      ...pitController.unselectedPits,
    ]) {
      final name = pit.pitName.trim();
      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }
    pitList.assignAll(names);
  }
}
