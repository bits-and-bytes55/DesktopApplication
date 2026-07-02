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

    newPackageRows.add(_genRow(4));
    newServiceRows.add(_genRow(4));
    newEngineeringRows.add(_genRow(4));
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

    if (newPackageRows.isEmpty) newPackageRows.add(_genRow(4));
    if (newServiceRows.isEmpty) newServiceRows.add(_genRow(4));
    if (newEngineeringRows.isEmpty) newEngineeringRows.add(_genRow(4));
  }

  void _emptyText(RxList<List<TextEditingController>> list, int cols) {
    for (var row in list) {
      for (var ctrl in row) ctrl.text = '';
    }
  }

  void updateNewRows(
    RxList<List<TextEditingController>> rows,
    int rowIndex,
  ) {
    if (rowIndex < 0 || rowIndex >= rows.length) return;

    final isLastRow = rowIndex == rows.length - 1;
    final hasAnyValue = rows[rowIndex].any((ctrl) => ctrl.text.trim().isNotEmpty);

    if (isLastRow && hasAnyValue) {
      rows.add(_genRow(4));
      rows.refresh();
      return;
    }

    // Keep only one trailing empty row.
    for (int i = rows.length - 2; i >= 0; i--) {
      final isEmpty = rows[i].every((ctrl) => ctrl.text.trim().isEmpty);
      final nextIsEmpty = rows[i + 1].every((ctrl) => ctrl.text.trim().isEmpty);
      if (isEmpty && nextIsEmpty) {
        final removed = rows.removeAt(i + 1);
        for (final ctrl in removed) {
          ctrl.dispose();
        }
      }
    }
    rows.refresh();
  }

  Future<void> loadAllData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _apiController.getPackages(),
        _apiController.getServices(),
        _apiController.getEngineering(),
      ]);
      final packageItems = List<PackageItem>.from(results[0] as List<PackageItem>)
        ..sort((a, b) => _naturalCompare(a.name, b.name));
      final serviceItems = List<ServiceItem>.from(results[1] as List<ServiceItem>)
        ..sort((a, b) => _naturalCompare(a.name, b.name));
      final engineeringItems =
          List<EngineeringItem>.from(results[2] as List<EngineeringItem>)
            ..sort((a, b) => _naturalCompare(a.name, b.name));

      packages.assignAll(packageItems);
      services.assignAll(serviceItems);
      engineering.assignAll(engineeringItems);
    } finally {
      isLoading.value = false;
    }
  }

  int _naturalCompare(String a, String b) {
    final left = a.trim();
    final right = b.trim();

    final leftMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(left);
    final rightMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(right);

    if (leftMatch != null && rightMatch != null) {
      final leftPrefix = leftMatch.group(1)!.trim().toLowerCase();
      final rightPrefix = rightMatch.group(1)!.trim().toLowerCase();
      final prefixCompare = leftPrefix.compareTo(rightPrefix);
      if (prefixCompare != 0) return prefixCompare;

      final leftNumber = int.tryParse(leftMatch.group(2)!) ?? 0;
      final rightNumber = int.tryParse(rightMatch.group(2)!) ?? 0;
      final numberCompare = leftNumber.compareTo(rightNumber);
      if (numberCompare != 0) return numberCompare;
    }

    return left.toLowerCase().compareTo(right.toLowerCase());
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> savePackages() async {
    isPackagesSaving.value = true;
    try {
      final didSaveEdit = await _persistPackageEditIfNeeded();
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
      if (items.isEmpty) {
        if (didSaveEdit) {
          await loadAllData();
          Get.snackbar('Success', 'Package updated successfully');
        }
        return;
      }
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
      final didSaveEdit = await _persistServiceEditIfNeeded();
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
      if (items.isEmpty) {
        if (didSaveEdit) {
          await loadAllData();
          Get.snackbar('Success', 'Service updated successfully');
        }
        return;
      }
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
      final didSaveEdit = await _persistEngineeringEditIfNeeded();
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
      if (items.isEmpty) {
        if (didSaveEdit) {
          await loadAllData();
          Get.snackbar('Success', 'Engineering item updated successfully');
        }
        return;
      }
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

  Future<bool> _persistPackageEditIfNeeded() async {
    final id = editingPackageId.value?.trim();
    if (id == null || id.isEmpty) return false;
    final updated = PackageItem(
      id: id,
      name: inlineName.text,
      code: inlineCode.text,
      unit: inlineUnit.text,
      price: double.tryParse(inlinePrice.text) ?? 0.0,
    );
    await _apiController.updatePackage(id, updated);
    editingPackageId.value = null;
    packages.refresh();
    return true;
  }

  Future<bool> _persistServiceEditIfNeeded() async {
    final id = editingServiceId.value?.trim();
    if (id == null || id.isEmpty) return false;
    final updated = ServiceItem(
      id: id,
      name: inlineName.text,
      code: inlineCode.text,
      unit: inlineUnit.text,
      price: double.tryParse(inlinePrice.text) ?? 0.0,
    );
    await _apiController.updateService(id, updated);
    editingServiceId.value = null;
    services.refresh();
    return true;
  }

  Future<bool> _persistEngineeringEditIfNeeded() async {
    final id = editingEngineeringId.value?.trim();
    if (id == null || id.isEmpty) return false;
    final updated = EngineeringItem(
      id: id,
      name: inlineName.text,
      code: inlineCode.text,
      unit: inlineUnit.text,
      price: double.tryParse(inlinePrice.text) ?? 0.0,
    );
    await _apiController.updateEngineering(id, updated);
    editingEngineeringId.value = null;
    engineering.refresh();
    return true;
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
    editingServiceId.value = null;
    editingEngineeringId.value = null;
    editingPackageId.value = item.id;
    inlineName.text = item.name;
    inlineCode.text = item.code;
    inlineUnit.text = item.unit;
    inlinePrice.text = item.price.toString();
    packages.refresh();
    services.refresh();
    engineering.refresh();
  }
  void cancelEditingPackage() {
    editingPackageId.value = null;
    packages.refresh();
  }
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
    packages.refresh();
  }

  void startEditingService(ServiceItem item) {
    editingPackageId.value = null;
    editingEngineeringId.value = null;
    editingServiceId.value = item.id;
    inlineName.text = item.name;
    inlineCode.text = item.code;
    inlineUnit.text = item.unit;
    inlinePrice.text = item.price.toString();
    packages.refresh();
    services.refresh();
    engineering.refresh();
  }
  void cancelEditingService() {
    editingServiceId.value = null;
    services.refresh();
  }
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
    services.refresh();
  }

  void startEditingEngineering(EngineeringItem item) {
    editingPackageId.value = null;
    editingServiceId.value = null;
    editingEngineeringId.value = item.id;
    inlineName.text = item.name;
    inlineCode.text = item.code;
    inlineUnit.text = item.unit;
    inlinePrice.text = item.price.toString();
    packages.refresh();
    services.refresh();
    engineering.refresh();
  }
  void cancelEditingEngineering() {
    editingEngineeringId.value = null;
    engineering.refresh();
  }
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
    engineering.refresh();
  }

  // ─── Export/Import ────────────────────────────────────────────────────────

  Map<String, List<List<String>>> getExportData() {
    return {
      'Packages': [
        ['Record ID', 'Name', 'Code', 'Unit', 'Price'],
        ...packages.map((e) => [
              e.id ?? '',
              e.name,
              e.code,
              e.unit,
              e.price.toString(),
            ])
      ],
      'Services': [
        ['Record ID', 'Name', 'Code', 'Unit', 'Price'],
        ...services.map((e) => [
              e.id ?? '',
              e.name,
              e.code,
              e.unit,
              e.price.toString(),
            ])
      ],
      'Engineering': [
        ['Record ID', 'Name', 'Code', 'Unit', 'Price'],
        ...engineering.map((e) => [
              e.id ?? '',
              e.name,
              e.code,
              e.unit,
              e.price.toString(),
            ])
      ],
    };
  }

  Future<Map<String, dynamic>> importFromData(List<List<String>> rows) async {
    final importedRows = _parseImportedRows(rows);
    if (importedRows.isEmpty) {
      return {
        'success': false,
        'message': 'No valid service rows found in the selected file',
      };
    }

    int updated = 0;
    int inserted = 0;
    final errors = <String>[];

    final packageContext = _ServiceSectionContext<PackageItem>(
      items: packages,
      idOf: (item) => item.id,
      codeOf: (item) => item.code,
      nameOf: (item) => item.name,
    );
    final serviceContext = _ServiceSectionContext<ServiceItem>(
      items: services,
      idOf: (item) => item.id,
      codeOf: (item) => item.code,
      nameOf: (item) => item.name,
    );
    final engineeringContext = _ServiceSectionContext<EngineeringItem>(
      items: engineering,
      idOf: (item) => item.id,
      codeOf: (item) => item.code,
      nameOf: (item) => item.name,
    );

    final newPackages = <PackageItem>[];
    final newServices = <ServiceItem>[];
    final newEngineeringItems = <EngineeringItem>[];

    for (final row in importedRows) {
      switch (row.section) {
        case _ServiceSection.package:
          final existing = _matchServiceItem(row, packageContext);
          final imported = PackageItem(
            id: existing?.id,
            name: row.name,
            code: row.code,
            unit: row.unit,
            price: row.price,
          );
          if (existing?.id != null) {
            if (!_sameServiceFields(
              name: existing!.name,
              code: existing.code,
              unit: existing.unit,
              price: existing.price,
              imported: row,
            )) {
              final result =
                  await _apiController.updatePackage(existing.id!, imported);
              if (result['success'] == true) {
                updated += 1;
              } else {
                errors.add(
                  'Package ${row.code.isEmpty ? row.name : row.code}: ${result['message'] ?? 'Update failed'}',
                );
              }
            }
          } else {
            newPackages.add(imported);
          }
          break;
        case _ServiceSection.service:
          final existing = _matchServiceItem(row, serviceContext);
          final imported = ServiceItem(
            id: existing?.id,
            name: row.name,
            code: row.code,
            unit: row.unit,
            price: row.price,
          );
          if (existing?.id != null) {
            if (!_sameServiceFields(
              name: existing!.name,
              code: existing.code,
              unit: existing.unit,
              price: existing.price,
              imported: row,
            )) {
              final result =
                  await _apiController.updateService(existing.id!, imported);
              if (result['success'] == true) {
                updated += 1;
              } else {
                errors.add(
                  'Service ${row.code.isEmpty ? row.name : row.code}: ${result['message'] ?? 'Update failed'}',
                );
              }
            }
          } else {
            newServices.add(imported);
          }
          break;
        case _ServiceSection.engineering:
          final existing = _matchServiceItem(row, engineeringContext);
          final imported = EngineeringItem(
            id: existing?.id,
            name: row.name,
            code: row.code,
            unit: row.unit,
            price: row.price,
          );
          if (existing?.id != null) {
            if (!_sameServiceFields(
              name: existing!.name,
              code: existing.code,
              unit: existing.unit,
              price: existing.price,
              imported: row,
            )) {
              final result = await _apiController.updateEngineering(
                existing.id!,
                imported,
              );
              if (result['success'] == true) {
                updated += 1;
              } else {
                errors.add(
                  'Engineering ${row.code.isEmpty ? row.name : row.code}: ${result['message'] ?? 'Update failed'}',
                );
              }
            }
          } else {
            newEngineeringItems.add(imported);
          }
          break;
      }
    }

    if (newPackages.isNotEmpty) {
      final result = await _apiController.addPackages(newPackages);
      if (result['success'] == true) {
        inserted += newPackages.length;
      } else {
        errors.add(result['message'] ?? 'Failed to add imported packages');
      }
    }

    if (newServices.isNotEmpty) {
      final result = await _apiController.addServices(newServices);
      if (result['success'] == true) {
        inserted += newServices.length;
      } else {
        errors.add(result['message'] ?? 'Failed to add imported services');
      }
    }

    if (newEngineeringItems.isNotEmpty) {
      final result = await _apiController.addEngineering(newEngineeringItems);
      if (result['success'] == true) {
        inserted += newEngineeringItems.length;
      } else {
        errors.add(
          result['message'] ?? 'Failed to add imported engineering items',
        );
      }
    }

    await loadAllData();

    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message':
            'Services import finished with issues. Updated: $updated, Added: $inserted',
        'updated': updated,
        'inserted': inserted,
        'errors': errors,
      };
    }

    return {
      'success': true,
      'message': 'Services imported successfully. Updated: $updated, Added: $inserted',
      'updated': updated,
      'inserted': inserted,
    };
  }

  T? _matchServiceItem<T>(
    _ImportedServiceRow row,
    _ServiceSectionContext<T> context,
  ) {
    final recordId = row.recordId.trim();
    if (recordId.isNotEmpty && context.byId.containsKey(recordId)) {
      return context.byId[recordId];
    }

    final codeKey = _normalizeKey(row.code);
    if (codeKey.isNotEmpty && context.byCode.containsKey(codeKey)) {
      return context.byCode[codeKey];
    }

    final nameKey = _normalizeKey(row.name);
    if (nameKey.isNotEmpty && context.byName.containsKey(nameKey)) {
      return context.byName[nameKey];
    }

    return null;
  }

  bool _sameServiceFields({
    required String name,
    required String code,
    required String unit,
    required double price,
    required _ImportedServiceRow imported,
  }) {
    return name.trim() == imported.name.trim() &&
        code.trim() == imported.code.trim() &&
        unit.trim() == imported.unit.trim() &&
        price == imported.price;
  }

  List<_ImportedServiceRow> _parseImportedRows(List<List<String>> rows) {
    final parsed = <_ImportedServiceRow>[];
    var section = _ServiceSection.package;

    for (final sourceRow in rows) {
      final row = List<String>.from(sourceRow);
      if (row.isEmpty || row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      final first = row.first.trim().toLowerCase();
      if (first.contains('package')) {
        section = _ServiceSection.package;
        continue;
      }
      if (first.contains('service')) {
        section = _ServiceSection.service;
        continue;
      }
      if (first.contains('engineering')) {
        section = _ServiceSection.engineering;
        continue;
      }

      final header = row.map((cell) => cell.trim().toLowerCase()).toList();
      final hasRecordId = header.isNotEmpty && header.first == 'record id';
      if (header.contains('name') && header.contains('code')) {
        continue;
      }

      final minimumLength = hasRecordId ? 5 : 4;
      while (row.length < minimumLength) {
        row.add('');
      }

      final offset = hasRecordId ? 1 : 0;
      final name = row[offset].trim();
      final code = row[offset + 1].trim();
      final unit = row[offset + 2].trim();
      final priceText = row[offset + 3].trim();
      if ([name, code, unit, priceText].every((value) => value.isEmpty)) {
        continue;
      }

      parsed.add(
        _ImportedServiceRow(
          section: section,
          recordId: hasRecordId ? row[0].trim() : '',
          name: name,
          code: code,
          unit: unit,
          price: double.tryParse(priceText) ?? 0,
        ),
      );
    }

    return parsed;
  }

  String _normalizeKey(String value) => value.trim().toLowerCase();

  @override
  void onClose() {
    _clearList(newPackageRows);
    _clearList(newServiceRows);
    _clearList(newEngineeringRows);
    super.onClose();
  }
}

enum _ServiceSection { package, service, engineering }

class _ImportedServiceRow {
  final _ServiceSection section;
  final String recordId;
  final String name;
  final String code;
  final String unit;
  final double price;

  const _ImportedServiceRow({
    required this.section,
    required this.recordId,
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
  });
}

class _ServiceSectionContext<T> {
  final Map<String, T> byId = <String, T>{};
  final Map<String, T> byCode = <String, T>{};
  final Map<String, T> byName = <String, T>{};

  _ServiceSectionContext({
    required Iterable<T> items,
    required String? Function(T item) idOf,
    required String Function(T item) codeOf,
    required String Function(T item) nameOf,
  }) {
    for (final item in items) {
      final id = idOf(item)?.trim();
      if (id != null && id.isNotEmpty) {
        byId[id] = item;
      }

      final code = codeOf(item).trim().toLowerCase();
      if (code.isNotEmpty) {
        byCode[code] = item;
      }

      final name = nameOf(item).trim().toLowerCase();
      if (name.isNotEmpty) {
        byName[name] = item;
      }
    }
  }
}
