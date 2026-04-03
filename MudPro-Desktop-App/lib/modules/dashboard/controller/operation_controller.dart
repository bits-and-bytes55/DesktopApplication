import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';

enum OperationType {
  consumeServices,
  consumeProduct,
  receiveProduct,
  returnProduct,
  transferMud,
  receiveMud,
  returnLostMud,
  addWater,
  switchPit,
  switchMudType,
  emptyActiveSystem,
  otherVolAddition,
  mudLossActiveSystem,
  mudLossStorage,
}

class OperationController extends GetxController {
  RxBool isLocked = true.obs;
  RxInt selectedRowIndex = 0.obs;
  RxString addWaterVolume = "".obs; // Track Add Water locally
  RxDouble totalVolume = 0.0.obs; // Track overall total volume (Products + Water)

  // ── Add Water State ────────────────────────────────────────────────────────
  final RxString addWaterTo = "Active System".obs;
  final RxString addWaterMainVol = "".obs;
  final RxList<String> addWaterExtraRows = <String>["", ""].obs;

  Future<Map<String, dynamic>> saveAddWater() async {
    final authRepo = AuthRepository();
    // Assuming kStaticWellId is available from common context or hardcoded as before
    const String wellId = '67f1a2b3c4d5e6f7890a1111'; 

    int successCount = 0;
    List<String> errors = [];

    // 1. Process Main Row
    if (addWaterMainVol.value.isNotEmpty && double.tryParse(addWaterMainVol.value) != null) {
      final res = await authRepo.createAddWater(wellId, {
        'to': addWaterTo.value,
        'volume': double.parse(addWaterMainVol.value),
      });
      if (res['success'] == true) successCount++;
      else errors.add('Main: ${res['message']}');
    }

    // 2. Process Extra Rows (Note: UI has custom 'To' field in dynamic rows, 
    // but backend only supports 'to' and 'volume'. We'll use the main 'to' for now 
    // or ignore empty labels as requested by 'dont change ui'.)
    for (int i = 0; i < addWaterExtraRows.length; i++) {
      final vol = addWaterExtraRows[i];
      if (vol.isNotEmpty && double.tryParse(vol) != null) {
        final res = await authRepo.createAddWater(wellId, {
          'to': addWaterTo.value,
          'volume': double.parse(vol),
        });
        if (res['success'] == true) successCount++;
        else errors.add('Row ${i + 1}: ${res['message']}');
      }
    }

    if (successCount > 0) {
      // Clear values after successful save
      addWaterMainVol.value = "";
      for (int i = 0; i < addWaterExtraRows.length; i++) {
        addWaterExtraRows[i] = "";
      }
    }

    return {
      'success': errors.isEmpty,
      'message': errors.isEmpty 
          ? 'Add Water saved successfully' 
          : 'Saved $successCount, Errors: ${errors.join(", ")}'
    };
  }

  final List<OperationType> dropdownItems = OperationType.values;

  RxList<OperationType?> dropdownValues = <OperationType?>[].obs;
  RxList<bool> isDropdownOpen = <bool>[].obs;

  final Map<OperationType, String> labels = {
    OperationType.consumeServices: "Consume Services",
    OperationType.consumeProduct: "Consume Product",
    OperationType.receiveProduct: "Receive Product",
    OperationType.returnProduct: "Return Product",
    OperationType.transferMud: "Transfer Mud",
    OperationType.receiveMud: "Receive Mud",
    OperationType.returnLostMud: "Return / Lost Mud",
    OperationType.addWater: "Add Water",
    OperationType.switchPit: "Switch Pit",
    OperationType.switchMudType: "Switch Mud Type",
    OperationType.emptyActiveSystem: "Empty Active System",
    OperationType.otherVolAddition:
        "Other Vol. Addition - Active System",
    OperationType.mudLossActiveSystem:
        "Mud Loss - Active System",
    OperationType.mudLossStorage: "Mud Loss - Storage",
  };

  // ---------- RETURN / LOST MUD ----------
RxBool premixedMud = false.obs;
RxBool leased = false.obs;

final List<String> returnLostLabels = [
  "From",
  "To",
  "Vol. Returned",
  "MW",
  "Mud Type",
  "BOL",
  "Vol. Lost",
  "Cost of Lost (Pre-tax)",
  "",
];

final List<String> returnLostUnits = [
  "",
  "",
  "(bbl)",
  "(ppg)",
  "",
  "",
  "(bbl)",
  "(\$)",
  "",
];

// which row uses dropdown (From & To)
final RxList<bool> returnLostDropdownIndex =
    <bool>[true, true, false, false, false, false, false, false, false].obs;

// dropdown values per row
final RxList<String> returnLostDropdownValue =
    List.generate(9, (_) => "Active System").obs;


  @override
  void onInit() {
    super.onInit();

    dropdownValues.assignAll(
      List.generate(
        labels.length,
        (index) => index < 2 ? dropdownItems[index] : null,
      ),
    );

    isDropdownOpen.assignAll(List.generate(labels.length, (_) => false));
  }
}
