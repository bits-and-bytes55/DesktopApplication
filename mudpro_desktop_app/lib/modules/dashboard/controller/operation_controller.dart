import 'package:get/get.dart';

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
