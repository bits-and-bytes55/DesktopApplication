import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';

class EmptyActiveSystemController extends GetxController {
  // Radio selection
  RxBool isDumpSelected = true.obs;

  // Unselected pits from API
  final unselectedPits = <PitModel>[].obs;

  // Table data - starts with 5 rows
  final pitValues = List<String>.generate(5, (_) => "").obs;
  final volValues = List<String>.generate(5, (_) => "").obs;

  String? currentWellId;

  @override
  void onInit() {
    super.onInit();
    currentWellId = Get.arguments?['wellId'] ?? 'UG-0293 ST';
    fetchUnselectedPits();
  }

  bool get isTableEnabled => !isDumpSelected.value;

  // Fetch unselected pits from API
  Future<void> fetchUnselectedPits() async {
    if (currentWellId == null) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getUnselectedPits(currentWellId!);

      if (result['success'] == true) {
        final data = result['data'];
        
        if (data != null && data is List) {
          if (data.isNotEmpty && data.first is PitModel) {
            unselectedPits.value = List<PitModel>.from(data);
          } else {
            unselectedPits.value = data
                .map((item) => PitModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } else {
          unselectedPits.clear();
        }
      }
    } catch (e) {
      print('Error fetching unselected pits: $e');
    }
  }

  // Set pit value and auto-fill capacity
  void setPit(int row, String pitName) {
    pitValues[row] = pitName;
    
    // Find the selected pit and auto-fill capacity
    final selectedPit = unselectedPits.firstWhereOrNull(
      (pit) => pit.pitName == pitName,
    );
    
    if (selectedPit != null) {
      volValues[row] = selectedPit.capacity.value.toStringAsFixed(2);
    }
  }

  // Add new row when last row is filled
  void addNewRow() {
    pitValues.add("");
    volValues.add("");
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