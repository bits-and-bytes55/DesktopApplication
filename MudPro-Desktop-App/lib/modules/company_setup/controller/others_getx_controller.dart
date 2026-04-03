import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/others_model.dart';

class OthersGetxController extends GetxController {
  final OthersController _apiController = OthersController();

  final RxList<ActivityItem> activities = <ActivityItem>[].obs;
  final RxList<AdditionItem> additions = <AdditionItem>[].obs;
  final RxList<LossItem> losses = <LossItem>[].obs;
  final RxList<WaterBasedItem> waterBased = <WaterBasedItem>[].obs;
  final RxList<OilBasedItem> oilBased = <OilBasedItem>[].obs;
  final RxList<SyntheticItem> synthetic = <SyntheticItem>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isActivitiesSaving = false.obs;
  final RxBool isAdditionsSaving = false.obs;
  final RxBool isLossesSaving = false.obs;
  final RxBool isWaterSaving = false.obs;
  final RxBool isOilSaving = false.obs;
  final RxBool isSyntheticSaving = false.obs;

  // New rows for each table
  final RxList<TextEditingController> newActivityRows = <TextEditingController>[].obs;
  final RxList<TextEditingController> newAdditionRows = <TextEditingController>[].obs;
  final RxList<TextEditingController> newLossRows = <TextEditingController>[].obs;
  final RxList<TextEditingController> newWaterRows = <TextEditingController>[].obs;
  final RxList<TextEditingController> newOilRows = <TextEditingController>[].obs;
  final RxList<TextEditingController> newSyntheticRows = <TextEditingController>[].obs;

  @override
  void onInit() {
    super.onInit();
    _resetNewRows();
    fetchAllData();
  }

  void _resetNewRows() {
    _clearList(newActivityRows);
    _clearList(newAdditionRows);
    _clearList(newLossRows);
    _clearList(newWaterRows);
    _clearList(newOilRows);
    _clearList(newSyntheticRows);
    
    for (int i = 0; i < 5; i++) {
      newActivityRows.add(TextEditingController());
      newAdditionRows.add(TextEditingController());
      newLossRows.add(TextEditingController());
      newWaterRows.add(TextEditingController());
      newOilRows.add(TextEditingController());
      newSyntheticRows.add(TextEditingController());
    }
  }

  void _clearList(RxList<TextEditingController> list) {
    for (var c in list) c.dispose();
    list.clear();
  }

  void _emptyNewRows() {
    _emptyText(newActivityRows);
    _emptyText(newAdditionRows);
    _emptyText(newLossRows);
    _emptyText(newWaterRows);
    _emptyText(newOilRows);
    _emptyText(newSyntheticRows);
    
    // Ensure minimum rows
    while (newActivityRows.length < 5) newActivityRows.add(TextEditingController());
    while (newAdditionRows.length < 5) newAdditionRows.add(TextEditingController());
    while (newLossRows.length < 5) newLossRows.add(TextEditingController());
    while (newWaterRows.length < 5) newWaterRows.add(TextEditingController());
    while (newOilRows.length < 5) newOilRows.add(TextEditingController());
    while (newSyntheticRows.length < 5) newSyntheticRows.add(TextEditingController());
  }

  void _emptyText(RxList<TextEditingController> list) {
    for (var c in list) c.text = '';
  }

  Future<void> fetchAllData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _apiController.getActivities(),
        _apiController.getAdditions(),
        _apiController.getLosses(),
        _apiController.getWaterBased(),
        _apiController.getOilBased(),
        _apiController.getSynthetic(),
      ]);

      activities.assignAll(results[0] as List<ActivityItem>);
      additions.assignAll(results[1] as List<AdditionItem>);
      losses.assignAll(results[2] as List<LossItem>);
      waterBased.assignAll(results[3] as List<WaterBasedItem>);
      oilBased.assignAll(results[4] as List<OilBasedItem>);
      synthetic.assignAll(results[5] as List<SyntheticItem>);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Save Actions ─────────────────────────────────────────────────────────

  Future<void> saveActivities() async {
    isActivitiesSaving.value = true;
    try {
      final List<ActivityItem> items = [];
      for (var ctrl in newActivityRows) {
        if (ctrl.text.isNotEmpty) items.add(ActivityItem(description: ctrl.text));
      }
      if (items.isEmpty) return;
      await _apiController.addActivities(items);
      _resetNewRows();
      await fetchAllData();
      Get.snackbar('Success', 'Activities saved');
    } finally {
      isActivitiesSaving.value = false;
    }
  }

  Future<void> saveAdditions() async {
    isAdditionsSaving.value = true;
    try {
      final List<AdditionItem> items = [];
      for (var ctrl in newAdditionRows) {
        if (ctrl.text.isNotEmpty) items.add(AdditionItem(name: ctrl.text));
      }
      if (items.isEmpty) return;
      await _apiController.addAdditions(items);
      _resetNewRows();
      await fetchAllData();
      Get.snackbar('Success', 'Additions saved');
    } finally {
      isAdditionsSaving.value = false;
    }
  }

  Future<void> saveLosses() async {
    isLossesSaving.value = true;
    try {
      final List<LossItem> items = [];
      for (var ctrl in newLossRows) {
        if (ctrl.text.isNotEmpty) items.add(LossItem(name: ctrl.text));
      }
      if (items.isEmpty) return;
      await _apiController.addLosses(items);
      _resetNewRows();
      await fetchAllData();
      Get.snackbar('Success', 'Losses saved');
    } finally {
      isLossesSaving.value = false;
    }
  }

  Future<void> saveWaterBased() async {
    isWaterSaving.value = true;
    try {
      final List<WaterBasedItem> items = [];
      for (var ctrl in newWaterRows) {
        if (ctrl.text.isNotEmpty) items.add(WaterBasedItem(name: ctrl.text));
      }
      if (items.isEmpty) return;
      await _apiController.addWaterBased(items);
      _resetNewRows();
      await fetchAllData();
      Get.snackbar('Success', 'Water-based saved');
    } finally {
      isWaterSaving.value = false;
    }
  }

  Future<void> saveOilBased() async {
    isOilSaving.value = true;
    try {
      final List<OilBasedItem> items = [];
      for (var ctrl in newOilRows) {
        if (ctrl.text.isNotEmpty) items.add(OilBasedItem(name: ctrl.text));
      }
      if (items.isEmpty) return;
      await _apiController.addOilBased(items);
      _resetNewRows();
      await fetchAllData();
      Get.snackbar('Success', 'Oil-based saved');
    } finally {
      isOilSaving.value = false;
    }
  }

  Future<void> saveSynthetic() async {
    isSyntheticSaving.value = true;
    try {
      final List<SyntheticItem> items = [];
      for (var ctrl in newSyntheticRows) {
        if (ctrl.text.isNotEmpty) items.add(SyntheticItem(name: ctrl.text));
      }
      if (items.isEmpty) return;
      await _apiController.addSynthetic(items);
      _resetNewRows();
      await fetchAllData();
      Get.snackbar('Success', 'Synthetic saved');
    } finally {
      isSyntheticSaving.value = false;
    }
  }

  // ─── Delete Actions ───────────────────────────────────────────────────────

  Future<void> deleteActivity(String id) async { if (await _confirmDelete('activity')) { await _apiController.deleteActivity(id); await fetchAllData(); } }
  Future<void> deleteAddition(String id) async { if (await _confirmDelete('addition')) { await _apiController.deleteAddition(id); await fetchAllData(); } }
  Future<void> deleteLoss(String id) async { if (await _confirmDelete('loss')) { await _apiController.deleteLoss(id); await fetchAllData(); } }
  Future<void> deleteWaterBased(String id) async { if (await _confirmDelete('water-based')) { await _apiController.deleteWaterBased(id); await fetchAllData(); } }
  Future<void> deleteOilBased(String id) async { if (await _confirmDelete('oil-based')) { await _apiController.deleteOilBased(id); await fetchAllData(); } }
  Future<void> deleteSynthetic(String id) async { if (await _confirmDelete('synthetic')) { await _apiController.deleteSynthetic(id); await fetchAllData(); } }

  Future<bool> _confirmDelete(String type) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this $type?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Get.back(result: true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      )
    ) ?? false;
  }

  // ─── Edit Logic ───────────────────────────────────────────────────────────

  void showEditDialog(dynamic item, String type) {
    final ctrl = TextEditingController();
    String currentText = '';
    if (item is ActivityItem) currentText = item.description;
    else if (item is AdditionItem) currentText = item.name;
    else if (item is LossItem) currentText = item.name;
    else if (item is WaterBasedItem) currentText = item.name;
    else if (item is OilBasedItem) currentText = item.name;
    else if (item is SyntheticItem) currentText = item.name;
    ctrl.text = currentText;

    Get.dialog(
      AlertDialog(
        title: Text('Edit $type'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Description')),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _updateItem(item, ctrl.text, type);
            },
            child: const Text('Save'),
          ),
        ],
      )
    );
  }

  Future<void> _updateItem(dynamic item, String newText, String type) async {
    final id = item.id!;
    dynamic result;
    if (item is ActivityItem) result = await _apiController.updateActivity(id, ActivityItem(id: id, description: newText));
    else if (item is AdditionItem) result = await _apiController.updateAddition(id, AdditionItem(id: id, name: newText));
    else if (item is LossItem) result = await _apiController.updateLoss(id, LossItem(id: id, name: newText));
    else if (item is WaterBasedItem) result = await _apiController.updateWaterBased(id, WaterBasedItem(id: id, name: newText));
    else if (item is OilBasedItem) result = await _apiController.updateOilBased(id, OilBasedItem(id: id, name: newText));
    else if (item is SyntheticItem) result = await _apiController.updateSynthetic(id, SyntheticItem(id: id, name: newText));

    if (result['success'] == true) {
      await fetchAllData();
      Get.snackbar('Success', 'Item updated');
    } else {
      Get.snackbar('Error', result['message'] ?? 'Update failed');
    }
  }

  // ─── Export/Import ────────────────────────────────────────────────────────

  Map<String, List<List<String>>> getExportData() {
    return {
      'Activities': [['Description'], ...activities.map((e) => [e.description])],
      'Additions': [['Description'], ...additions.map((e) => [e.name])],
      'Losses': [['Description'], ...losses.map((e) => [e.name])],
      'WaterBased': [['Description'], ...waterBased.map((e) => [e.name])],
      'OilBased': [['Description'], ...oilBased.map((e) => [e.name])],
      'Synthetic': [['Description'], ...synthetic.map((e) => [e.name])],
    };
  }

  void importFromData(List<List<String>> rows) {
    _emptyNewRows();
    int targetTable = 0; // 0:Activity, 1:Addition, 2:Loss, 3:Water, 4:Oil, 5:Synthetic
    for (var row in rows) {
      if (row.isEmpty) continue;
      String first = row[0].toLowerCase();
      if (first.contains('activity')) { targetTable = 0; continue; }
      if (first.contains('addition')) { targetTable = 1; continue; }
      if (first.contains('loss')) { targetTable = 2; continue; }
      if (first.contains('water')) { targetTable = 3; continue; }
      if (first.contains('oil')) { targetTable = 4; continue; }
      if (first.contains('synthetic')) { targetTable = 5; continue; }
      if (first.contains('description') || first.contains('name')) continue;

      RxList<TextEditingController> currentList;
      switch(targetTable) {
        case 0: currentList = newActivityRows; break;
        case 1: currentList = newAdditionRows; break;
        case 2: currentList = newLossRows; break;
        case 3: currentList = newWaterRows; break;
        case 4: currentList = newOilRows; break;
        default: currentList = newSyntheticRows; break;
      }

      int emptyIdx = currentList.indexWhere((c) => c.text.isEmpty);
      if (emptyIdx != -1) {
        currentList[emptyIdx].text = row[0];
      } else {
        currentList.add(TextEditingController(text: row[0]));
      }
    }
  }

  @override
  void onClose() {
    _clearList(newActivityRows);
    _clearList(newAdditionRows);
    _clearList(newLossRows);
    _clearList(newWaterRows);
    _clearList(newOilRows);
    _clearList(newSyntheticRows);
    super.onClose();
  }
}
