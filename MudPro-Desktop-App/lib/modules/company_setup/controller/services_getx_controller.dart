import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:flutter/material.dart';

class ServicesGetxController extends GetxController {
  final ServiceController _apiController = ServiceController();
  
  final RxList<PackageItem> packages = <PackageItem>[].obs;
  final RxList<ServiceItem> services = <ServiceItem>[].obs;
  final RxList<EngineeringItem> engineering = <EngineeringItem>[].obs;
  
  final RxBool isLoading = false.obs;
  final RxBool isPackagesSaving = false.obs;
  final RxBool isServicesSaving = false.obs;
  final RxBool isEngineeringSaving = false.obs;

  // New rows for each table
  final RxList<List<TextEditingController>> newPackageRows = <List<TextEditingController>>[].obs;
  final RxList<List<TextEditingController>> newServiceRows = <List<TextEditingController>>[].obs;
  final RxList<List<TextEditingController>> newEngineeringRows = <List<TextEditingController>>[].obs;

  final RxnString editingPackageId = RxnString();
  final RxnString editingServiceId = RxnString();
  final RxnString editingEngineeringId = RxnString();

  // Inline edit controllers (for editing existing rows)
  final TextEditingController inlineName = TextEditingController();
  final TextEditingController inlineCode = TextEditingController();
  final TextEditingController inlineUnit = TextEditingController();
  final TextEditingController inlinePrice = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _resetNewRows();
    loadAllData();
  }

  void _resetNewRows() {
    _clearList(newPackageRows);
    _clearList(newServiceRows);
    _clearList(newEngineeringRows);
    
    for (int i = 0; i < 5; i++) {
      newPackageRows.add(_genRow(4));
      newServiceRows.add(_genRow(4));
      newEngineeringRows.add(_genRow(4));
    }
  }

  List<TextEditingController> _genRow(int count) {
    final row = List.generate(count, (_) => TextEditingController());
    for (var ctrl in row) {
      ctrl.addListener(() => _onFieldChanged());
    }
    return row;
  }

  void _onFieldChanged() {
    // Auto-add row logic if needed
  }

  void _clearList(RxList<List<TextEditingController>> list) {
    for (var row in list) {
      for (var ctrl in row) ctrl.dispose();
    }
    list.clear();
  }

  void _emptyNewRows() {
    _emptyText(newPackageRows, 4);
    _emptyText(newServiceRows, 4);
    _emptyText(newEngineeringRows, 4);
    
    while (newPackageRows.length < 5) newPackageRows.add(_genRow(4));
    while (newServiceRows.length < 5) newServiceRows.add(_genRow(4));
    while (newEngineeringRows.length < 5) newEngineeringRows.add(_genRow(4));
  }

  void _emptyText(RxList<List<TextEditingController>> list, int cols) {
    for (var row in list) {
      for (var ctrl in row) ctrl.text = '';
    }
  }

  Future<void> loadAllData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _apiController.getPackages(),
        _apiController.getServices(),
        _apiController.getEngineering(),
      ]);
      packages.assignAll(results[0] as List<PackageItem>);
      services.assignAll(results[1] as List<ServiceItem>);
      engineering.assignAll(results[2] as List<EngineeringItem>);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> savePackages() async {
    isPackagesSaving.value = true;
    try {
      final List<PackageItem> items = [];
      for (var row in newPackageRows) {
        if (row[0].text.isNotEmpty) {
          items.add(PackageItem(
            name: row[0].text,
            code: row[1].text,
            unit: row[2].text,
            price: double.tryParse(row[3].text) ?? 0.0,
          ));
        }
      }
      if (items.isEmpty) return;
      await _apiController.addPackages(items);
      _resetNewRows(); // or just clear the filled ones
      await loadAllData();
      Get.snackbar('Success', 'Packages saved successfully');
    } finally {
      isPackagesSaving.value = false;
    }
  }

  Future<void> saveServices() async {
    isServicesSaving.value = true;
    try {
      final List<ServiceItem> items = [];
      for (var row in newServiceRows) {
        if (row[0].text.isNotEmpty) {
          items.add(ServiceItem(
            name: row[0].text,
            code: row[1].text,
            unit: row[2].text,
            price: double.tryParse(row[3].text) ?? 0.0,
          ));
        }
      }
      if (items.isEmpty) return;
      await _apiController.addServices(items);
      _resetNewRows();
      await loadAllData();
      Get.snackbar('Success', 'Services saved successfully');
    } finally {
      isServicesSaving.value = false;
    }
  }

  Future<void> saveEngineering() async {
    isEngineeringSaving.value = true;
    try {
      final List<EngineeringItem> items = [];
      for (var row in newEngineeringRows) {
        if (row[0].text.isNotEmpty) {
          items.add(EngineeringItem(
            name: row[0].text,
            code: row[1].text,
            unit: row[2].text,
            price: double.tryParse(row[3].text) ?? 0.0,
          ));
        }
      }
      if (items.isEmpty) return;
      await _apiController.addEngineering(items);
      _resetNewRows();
      await loadAllData();
      Get.snackbar('Success', 'Engineering items saved successfully');
    } finally {
      isEngineeringSaving.value = false;
    }
  }

  Future<void> deletePackage(String id) async {
    if (await _confirmDelete('package')) {
      await _apiController.deletePackage(id);
      await loadAllData();
    }
  }

  Future<void> deleteService(String id) async {
    if (await _confirmDelete('service')) {
      await _apiController.deleteService(id);
      await loadAllData();
    }
  }

  Future<void> deleteEngineering(String id) async {
    if (await _confirmDelete('engineering item')) {
      await _apiController.deleteEngineering(id);
      await loadAllData();
    }
  }

  Future<bool> _confirmDelete(String type) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this $type?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      )
    ) ?? false;
  }

  // Edit logic — uses shared inline controllers
  void startEditingPackage(PackageItem item) {
    editingPackageId.value = item.id;
    inlineName.text = item.name;
    inlineCode.text = item.code;
    inlineUnit.text = item.unit;
    inlinePrice.text = item.price.toString();
  }
  void cancelEditingPackage() => editingPackageId.value = null;
  Future<void> savePackageEdit() async {
    final id = editingPackageId.value;
    if (id == null) return;
    final updated = PackageItem(
      id: id,
      name: inlineName.text,
      code: inlineCode.text,
      unit: inlineUnit.text,
      price: double.tryParse(inlinePrice.text) ?? 0.0,
    );
    await _apiController.updatePackage(id, updated);
    editingPackageId.value = null;
    await loadAllData();
  }

  void startEditingService(ServiceItem item) {
    editingServiceId.value = item.id;
    inlineName.text = item.name;
    inlineCode.text = item.code;
    inlineUnit.text = item.unit;
    inlinePrice.text = item.price.toString();
  }
  void cancelEditingService() => editingServiceId.value = null;
  Future<void> saveServiceEdit() async {
    final id = editingServiceId.value;
    if (id == null) return;
    final updated = ServiceItem(
      id: id,
      name: inlineName.text,
      code: inlineCode.text,
      unit: inlineUnit.text,
      price: double.tryParse(inlinePrice.text) ?? 0.0,
    );
    await _apiController.updateService(id, updated);
    editingServiceId.value = null;
    await loadAllData();
  }

  void startEditingEngineering(EngineeringItem item) {
    editingEngineeringId.value = item.id;
    inlineName.text = item.name;
    inlineCode.text = item.code;
    inlineUnit.text = item.unit;
    inlinePrice.text = item.price.toString();
  }
  void cancelEditingEngineering() => editingEngineeringId.value = null;
  Future<void> saveEngineeringEdit() async {
    final id = editingEngineeringId.value;
    if (id == null) return;
    final updated = EngineeringItem(
      id: id,
      name: inlineName.text,
      code: inlineCode.text,
      unit: inlineUnit.text,
      price: double.tryParse(inlinePrice.text) ?? 0.0,
    );
    await _apiController.updateEngineering(id, updated);
    editingEngineeringId.value = null;
    await loadAllData();
  }

  // ─── Export/Import ────────────────────────────────────────────────────────

  Map<String, List<List<String>>> getExportData() {
    return {
      'Packages': [
        ['Name', 'Code', 'Unit', 'Price'],
        ...packages.map((e) => [e.name, e.code, e.unit, e.price.toString()])
      ],
      'Services': [
        ['Name', 'Code', 'Unit', 'Price'],
        ...services.map((e) => [e.name, e.code, e.unit, e.price.toString()])
      ],
      'Engineering': [
        ['Name', 'Code', 'Unit', 'Price'],
        ...engineering.map((e) => [e.name, e.code, e.unit, e.price.toString()])
      ],
    };
  }

  void importFromData(List<List<String>> rows) {
    _emptyNewRows();
    int targetTable = 0; // 0: Package, 1: Service, 2: Engineering
    for (var row in rows) {
      if (row.isEmpty) continue;
      String firstCell = row[0].toLowerCase();
      if (firstCell.contains('package')) { targetTable = 0; continue; }
      if (firstCell.contains('service')) { targetTable = 1; continue; }
      if (firstCell.contains('engineering')) { targetTable = 2; continue; }
      if (firstCell.contains('name')) continue;

      RxList<List<TextEditingController>> currentTable;
      if (targetTable == 0) currentTable = newPackageRows;
      else if (targetTable == 1) currentTable = newServiceRows;
      else currentTable = newEngineeringRows;

      int emptyRowIdx = currentTable.indexWhere((r) => r[0].text.isEmpty);
      if (emptyRowIdx != -1) {
        for (int i = 0; i < row.length && i < 4; i++) {
          currentTable[emptyRowIdx][i].text = row[i];
        }
      } else {
        final newRow = _genRow(4);
        for (int i = 0; i < row.length && i < 4; i++) {
          newRow[i].text = row[i];
        }
        currentTable.add(newRow);
      }
    }
  }

  @override
  void onClose() {
    _clearList(newPackageRows);
    _clearList(newServiceRows);
    _clearList(newEngineeringRows);
    super.onClose();
  }
}
