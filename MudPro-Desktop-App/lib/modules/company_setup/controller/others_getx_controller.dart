import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/others_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';

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
  final RxList<TextEditingController> newActivityRows =
      <TextEditingController>[].obs;
  final RxList<TextEditingController> newAdditionRows =
      <TextEditingController>[].obs;
  final RxList<TextEditingController> newLossRows =
      <TextEditingController>[].obs;
  final RxList<TextEditingController> newWaterRows =
      <TextEditingController>[].obs;
  final RxList<TextEditingController> newOilRows =
      <TextEditingController>[].obs;
  final RxList<TextEditingController> newSyntheticRows =
      <TextEditingController>[].obs;

  Future<void> _refreshMudAddRows() async {
    if (Get.isRegistered<MudController>()) {
      await Get.find<MudController>().refreshAvailablePropertiesFromOthers();
    }
  }

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
    while (newActivityRows.length < 5)
      newActivityRows.add(TextEditingController());
    while (newAdditionRows.length < 5)
      newAdditionRows.add(TextEditingController());
    while (newLossRows.length < 5) newLossRows.add(TextEditingController());
    while (newWaterRows.length < 5) newWaterRows.add(TextEditingController());
    while (newOilRows.length < 5) newOilRows.add(TextEditingController());
    while (newSyntheticRows.length < 5)
      newSyntheticRows.add(TextEditingController());
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
        if (ctrl.text.isNotEmpty)
          items.add(ActivityItem(description: ctrl.text));
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
      await _refreshMudAddRows();
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
      await _refreshMudAddRows();
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
      await _refreshMudAddRows();
      Get.snackbar('Success', 'Synthetic saved');
    } finally {
      isSyntheticSaving.value = false;
    }
  }

  // ─── Delete Actions ───────────────────────────────────────────────────────

  Future<void> deleteActivity(String id) async {
    if (await _confirmDelete('activity')) {
      await _apiController.deleteActivity(id);
      await fetchAllData();
    }
  }

  Future<void> deleteAddition(String id) async {
    if (await _confirmDelete('addition')) {
      await _apiController.deleteAddition(id);
      await fetchAllData();
    }
  }

  Future<void> deleteLoss(String id) async {
    if (await _confirmDelete('loss')) {
      await _apiController.deleteLoss(id);
      await fetchAllData();
    }
  }

  Future<void> deleteWaterBased(String id) async {
    if (await _confirmDelete('water-based')) {
      await _apiController.deleteWaterBased(id);
      await fetchAllData();
      await _refreshMudAddRows();
    }
  }

  Future<void> deleteOilBased(String id) async {
    if (await _confirmDelete('oil-based')) {
      await _apiController.deleteOilBased(id);
      await fetchAllData();
      await _refreshMudAddRows();
    }
  }

  Future<void> deleteSynthetic(String id) async {
    if (await _confirmDelete('synthetic')) {
      await _apiController.deleteSynthetic(id);
      await fetchAllData();
      await _refreshMudAddRows();
    }
  }

  Future<bool> _confirmDelete(String type) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Are you sure you want to delete this $type?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ─── Edit Logic ───────────────────────────────────────────────────────────

  void showEditDialog(dynamic item, String type) {
    final ctrl = TextEditingController();
    String currentText = '';
    if (item is ActivityItem)
      currentText = item.description;
    else if (item is AdditionItem)
      currentText = item.name;
    else if (item is LossItem)
      currentText = item.name;
    else if (item is WaterBasedItem)
      currentText = item.name;
    else if (item is OilBasedItem)
      currentText = item.name;
    else if (item is SyntheticItem)
      currentText = item.name;
    ctrl.text = currentText;

    Get.dialog(
      AlertDialog(
        title: Text('Edit $type'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
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
      ),
    );
  }

  Future<void> _updateItem(dynamic item, String newText, String type) async {
    final id = item.id!;
    dynamic result;
    if (item is ActivityItem)
      result = await _apiController.updateActivity(
        id,
        ActivityItem(id: id, description: newText),
      );
    else if (item is AdditionItem)
      result = await _apiController.updateAddition(
        id,
        AdditionItem(id: id, name: newText),
      );
    else if (item is LossItem)
      result = await _apiController.updateLoss(
        id,
        LossItem(id: id, name: newText),
      );
    else if (item is WaterBasedItem)
      result = await _apiController.updateWaterBased(
        id,
        WaterBasedItem(id: id, name: newText),
      );
    else if (item is OilBasedItem)
      result = await _apiController.updateOilBased(
        id,
        OilBasedItem(id: id, name: newText),
      );
    else if (item is SyntheticItem)
      result = await _apiController.updateSynthetic(
        id,
        SyntheticItem(id: id, name: newText),
      );

    if (result['success'] == true) {
      await fetchAllData();
      if (item is WaterBasedItem ||
          item is OilBasedItem ||
          item is SyntheticItem) {
        await _refreshMudAddRows();
      }
      Get.snackbar('Success', 'Item updated');
    } else {
      Get.snackbar('Error', result['message'] ?? 'Update failed');
    }
  }

  // ─── Export/Import ────────────────────────────────────────────────────────

  Map<String, List<List<String>>> getExportData() {
    return {
      'Activities': [
        ['Record ID', 'Description'],
        ...activities.map((e) => [e.id ?? '', e.description]),
      ],
      'Additions': [
        ['Record ID', 'Description'],
        ...additions.map((e) => [e.id ?? '', e.name]),
      ],
      'Losses': [
        ['Record ID', 'Description'],
        ...losses.map((e) => [e.id ?? '', e.name]),
      ],
      'WaterBased': [
        ['Record ID', 'Description'],
        ...waterBased.map((e) => [e.id ?? '', e.name]),
      ],
      'OilBased': [
        ['Record ID', 'Description'],
        ...oilBased.map((e) => [e.id ?? '', e.name]),
      ],
      'Synthetic': [
        ['Record ID', 'Description'],
        ...synthetic.map((e) => [e.id ?? '', e.name]),
      ],
    };
  }

  Future<Map<String, dynamic>> importFromData(List<List<String>> rows) async {
    final importedRows = _parseImportedRows(rows);
    if (importedRows.isEmpty) {
      return {
        'success': false,
        'message': 'No valid other rows found in the selected file',
      };
    }

    int updated = 0;
    int inserted = 0;
    final errors = <String>[];

    final activityContext = _OthersContext<ActivityItem>(
      items: activities,
      idOf: (item) => item.id,
      labelOf: (item) => item.description,
    );
    final additionContext = _OthersContext<AdditionItem>(
      items: additions,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
    );
    final lossContext = _OthersContext<LossItem>(
      items: losses,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
    );
    final waterContext = _OthersContext<WaterBasedItem>(
      items: waterBased,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
    );
    final oilContext = _OthersContext<OilBasedItem>(
      items: oilBased,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
    );
    final syntheticContext = _OthersContext<SyntheticItem>(
      items: synthetic,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
    );

    final newActivities = <ActivityItem>[];
    final newAdditions = <AdditionItem>[];
    final newLosses = <LossItem>[];
    final newWaterBased = <WaterBasedItem>[];
    final newOilBased = <OilBasedItem>[];
    final newSynthetic = <SyntheticItem>[];

    for (final row in importedRows) {
      switch (row.section) {
        case _OthersSection.activity:
          final existing = _matchOtherItem(row, activityContext);
          if (existing?.id != null) {
            if (existing!.description.trim() != row.value.trim()) {
              final result = await _apiController.updateActivity(
                existing.id!,
                ActivityItem(id: existing.id, description: row.value),
              );
              if (result['success'] == true) {
                updated += 1;
              } else {
                errors.add(
                  'Activity ${row.value}: ${result['message'] ?? 'Update failed'}',
                );
              }
            }
          } else {
            newActivities.add(ActivityItem(description: row.value));
          }
          break;
        case _OthersSection.addition:
          final existing = _matchOtherItem(row, additionContext);
          if (existing?.id != null) {
            if (existing!.name.trim() != row.value.trim()) {
              final result = await _apiController.updateAddition(
                existing.id!,
                AdditionItem(id: existing.id, name: row.value),
              );
              if (result['success'] == true) {
                updated += 1;
              } else {
                errors.add(
                  'Addition ${row.value}: ${result['message'] ?? 'Update failed'}',
                );
              }
            }
          } else {
            newAdditions.add(AdditionItem(name: row.value));
          }
          break;
        case _OthersSection.loss:
          final existing = _matchOtherItem(row, lossContext);
          if (existing?.id != null) {
            if (existing!.name.trim() != row.value.trim()) {
              final result = await _apiController.updateLoss(
                existing.id!,
                LossItem(id: existing.id, name: row.value),
              );
              if (result['success'] == true) {
                updated += 1;
              } else {
                errors.add(
                  'Loss ${row.value}: ${result['message'] ?? 'Update failed'}',
                );
              }
            }
          } else {
            newLosses.add(LossItem(name: row.value));
          }
          break;
        case _OthersSection.water:
          final existing = _matchOtherItem(row, waterContext);
          if (existing?.id != null) {
            if (existing!.name.trim() != row.value.trim()) {
              final result = await _apiController.updateWaterBased(
                existing.id!,
                WaterBasedItem(id: existing.id, name: row.value),
              );
              if (result['success'] == true) {
                updated += 1;
              } else {
                errors.add(
                  'Water Based ${row.value}: ${result['message'] ?? 'Update failed'}',
                );
              }
            }
          } else {
            newWaterBased.add(WaterBasedItem(name: row.value));
          }
          break;
        case _OthersSection.oil:
          final existing = _matchOtherItem(row, oilContext);
          if (existing?.id != null) {
            if (existing!.name.trim() != row.value.trim()) {
              final result = await _apiController.updateOilBased(
                existing.id!,
                OilBasedItem(id: existing.id, name: row.value),
              );
              if (result['success'] == true) {
                updated += 1;
              } else {
                errors.add(
                  'Oil Based ${row.value}: ${result['message'] ?? 'Update failed'}',
                );
              }
            }
          } else {
            newOilBased.add(OilBasedItem(name: row.value));
          }
          break;
        case _OthersSection.synthetic:
          final existing = _matchOtherItem(row, syntheticContext);
          if (existing?.id != null) {
            if (existing!.name.trim() != row.value.trim()) {
              final result = await _apiController.updateSynthetic(
                existing.id!,
                SyntheticItem(id: existing.id, name: row.value),
              );
              if (result['success'] == true) {
                updated += 1;
              } else {
                errors.add(
                  'Synthetic ${row.value}: ${result['message'] ?? 'Update failed'}',
                );
              }
            }
          } else {
            newSynthetic.add(SyntheticItem(name: row.value));
          }
          break;
      }
    }

    if (newActivities.isNotEmpty) {
      final result = await _apiController.addActivities(newActivities);
      if (result['success'] == true) {
        inserted += newActivities.length;
      } else {
        errors.add(result['message'] ?? 'Failed to add imported activities');
      }
    }

    if (newAdditions.isNotEmpty) {
      final result = await _apiController.addAdditions(newAdditions);
      if (result['success'] == true) {
        inserted += newAdditions.length;
      } else {
        errors.add(result['message'] ?? 'Failed to add imported additions');
      }
    }

    if (newLosses.isNotEmpty) {
      final result = await _apiController.addLosses(newLosses);
      if (result['success'] == true) {
        inserted += newLosses.length;
      } else {
        errors.add(result['message'] ?? 'Failed to add imported losses');
      }
    }

    if (newWaterBased.isNotEmpty) {
      final result = await _apiController.addWaterBased(newWaterBased);
      if (result['success'] == true) {
        inserted += newWaterBased.length;
      } else {
        errors.add(
          result['message'] ?? 'Failed to add imported water-based rows',
        );
      }
    }

    if (newOilBased.isNotEmpty) {
      final result = await _apiController.addOilBased(newOilBased);
      if (result['success'] == true) {
        inserted += newOilBased.length;
      } else {
        errors.add(
          result['message'] ?? 'Failed to add imported oil-based rows',
        );
      }
    }

    if (newSynthetic.isNotEmpty) {
      final result = await _apiController.addSynthetic(newSynthetic);
      if (result['success'] == true) {
        inserted += newSynthetic.length;
      } else {
        errors.add(
          result['message'] ?? 'Failed to add imported synthetic rows',
        );
      }
    }

    await fetchAllData();

    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message':
            'Others import finished with issues. Updated: $updated, Added: $inserted',
        'updated': updated,
        'inserted': inserted,
        'errors': errors,
      };
    }

    return {
      'success': true,
      'message':
          'Others imported successfully. Updated: $updated, Added: $inserted',
      'updated': updated,
      'inserted': inserted,
    };
  }

  T? _matchOtherItem<T>(_ImportedOtherRow row, _OthersContext<T> context) {
    final recordId = row.recordId.trim();
    if (recordId.isNotEmpty && context.byId.containsKey(recordId)) {
      return context.byId[recordId];
    }

    final labelKey = _normalizeKey(row.value);
    if (labelKey.isNotEmpty && context.byLabel.containsKey(labelKey)) {
      return context.byLabel[labelKey];
    }

    return null;
  }

  List<_ImportedOtherRow> _parseImportedRows(List<List<String>> rows) {
    final parsed = <_ImportedOtherRow>[];
    var section = _OthersSection.activity;

    for (final sourceRow in rows) {
      final row = List<String>.from(sourceRow);
      if (row.isEmpty || row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      final first = row.first.trim().toLowerCase();
      if (first.contains('activity')) {
        section = _OthersSection.activity;
        continue;
      }
      if (first.contains('addition')) {
        section = _OthersSection.addition;
        continue;
      }
      if (first.contains('loss')) {
        section = _OthersSection.loss;
        continue;
      }
      if (first.contains('water')) {
        section = _OthersSection.water;
        continue;
      }
      if (first.contains('oil')) {
        section = _OthersSection.oil;
        continue;
      }
      if (first.contains('synthetic')) {
        section = _OthersSection.synthetic;
        continue;
      }

      final header = row.map((cell) => cell.trim().toLowerCase()).toList();
      final hasRecordId = header.isNotEmpty && header.first == 'record id';
      if (header.contains('description') || header.contains('name')) {
        continue;
      }

      final minimumLength = hasRecordId ? 2 : 1;
      while (row.length < minimumLength) {
        row.add('');
      }

      final value = row[hasRecordId ? 1 : 0].trim();
      if (value.isEmpty) {
        continue;
      }

      parsed.add(
        _ImportedOtherRow(
          section: section,
          recordId: hasRecordId ? row[0].trim() : '',
          value: value,
        ),
      );
    }

    return parsed;
  }

  String _normalizeKey(String value) => value.trim().toLowerCase();

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

enum _OthersSection { activity, addition, loss, water, oil, synthetic }

class _ImportedOtherRow {
  final _OthersSection section;
  final String recordId;
  final String value;

  const _ImportedOtherRow({
    required this.section,
    required this.recordId,
    required this.value,
  });
}

class _OthersContext<T> {
  final Map<String, T> byId = <String, T>{};
  final Map<String, T> byLabel = <String, T>{};

  _OthersContext({
    required Iterable<T> items,
    required String? Function(T item) idOf,
    required String Function(T item) labelOf,
  }) {
    for (final item in items) {
      final id = idOf(item)?.trim();
      if (id != null && id.isNotEmpty) {
        byId[id] = item;
      }

      final label = labelOf(item).trim().toLowerCase();
      if (label.isNotEmpty) {
        byLabel[label] = item;
      }
    }
  }
}
