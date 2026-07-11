import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/model/ug_inventory_product_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/ug_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryServicesView extends StatefulWidget {
  const InventoryServicesView({super.key});

  @override
  State<InventoryServicesView> createState() => _InventoryServicesViewState();
}

class _InventoryServicesViewState extends State<InventoryServicesView> {
  final isLocked = false.obs;
  final ScrollController _packagesScrollController = ScrollController();
  final ScrollController _engineeringScrollController = ScrollController();
  final ScrollController _servicesScrollController = ScrollController();
  final c = Get.find<UgController>();

  bool _isLoading = false;

  void _showToast(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    try {
      final store = Get.find<InventoryServicesStore>();
      store.selectedPackages.refresh();
      store.selectedServices.refresh();
      store.selectedEngineering.refresh();
      print('Data refreshed on page enter');
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  Future<void> _loadData() async {
    final store = Get.find<InventoryServicesStore>();
    final activeWellId = c.wellId.trim();

    if (activeWellId.isEmpty) {
      _refreshData();
      return;
    }

    final shouldFetchPackages = store.selectedPackages.isEmpty;
    final shouldFetchServices = store.selectedServices.isEmpty;
    final shouldFetchEngineering = store.selectedEngineering.isEmpty;

    if (!shouldFetchPackages &&
        !shouldFetchServices &&
        !shouldFetchEngineering) {
      _refreshData();
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<PackageItem>? packages;
      List<ServiceItem>? services;
      List<EngineeringItem>? engineering;

      if (shouldFetchPackages) {
        packages = await InventoryProductsService.fetchPackages(activeWellId);
      }
      if (shouldFetchServices) {
        services = await InventoryProductsService.fetchServices(activeWellId);
      }
      if (shouldFetchEngineering) {
        engineering = await InventoryProductsService.fetchEngineering(
          activeWellId,
        );
      }

      store.setSelectedServices(
        packages: packages,
        services: services,
        engineering: engineering,
      );
    } catch (e) {
      print('Error loading inventory services snapshot: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _refreshData();
    }
  }

  @override
  void dispose() {
    _packagesScrollController.dispose();
    _engineeringScrollController.dispose();
    _servicesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<InventoryServicesStore>();

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading inventory services...'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _packagesTable(store)),
                const SizedBox(height: 6),
                Expanded(child: _engineeringTable(store)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _servicesTable(store)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _packagesTable(InventoryServicesStore store) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.tableBorderBlue),
        ),
        child: Column(
          children: [
            _sectionTitle('Package', hasHeaderCheckbox: true),
            Expanded(
              child: _table(
                headers: const [
                  'No',
                  'Package',
                  'Code',
                  'Unit',
                  'Price\n(Kwd)',
                  'Initial',
                  'Tax',
                  '',
                ],
                controller: _packagesScrollController,
                rows: store.selectedPackages.asMap().entries.map((entry) {
                  return [
                    (entry.key + 1).toString(),
                    entry.value.name,
                    entry.value.code,
                    entry.value.unit,
                    _formatInventoryServiceNumber(entry.value.price),
                    _formatInventoryServiceText(entry.value.initial),
                    entry.value.tax,
                    entry.value,
                  ];
                }).toList(),
                checkboxCols: const [6],
                actionCol: 7,
                onChanged: (rowIndex, colIndex, value) {
                  _updatePackageField(store, rowIndex, colIndex, value);
                  store.selectedPackages.refresh();
                },
                onActionSelected: (rowIndex, rowValue, action) async {
                  final item = rowValue as PackageItem;
                  if (action == _InventoryRowAction.edit) {
                    await _showPackageEditDialog(store, rowIndex, item);
                  } else {
                    await _removePackageFromInventory(store, item);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _engineeringTable(InventoryServicesStore store) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.tableBorderBlue),
        ),
        child: Column(
          children: [
            _sectionTitle('Engineering', hasHeaderCheckbox: true),
            Expanded(
              child: _table(
                headers: const [
                  'No',
                  'Engineering',
                  'Code',
                  'Unit',
                  'Price\n(Kwd)',
                  'Tax',
                  '',
                ],
                controller: _engineeringScrollController,
                rows: store.selectedEngineering.asMap().entries.map((entry) {
                  return [
                    (entry.key + 1).toString(),
                    entry.value.name,
                    entry.value.code,
                    entry.value.unit,
                    _formatInventoryServiceNumber(entry.value.price),
                    entry.value.tax,
                    entry.value,
                  ];
                }).toList(),
                checkboxCols: const [5],
                actionCol: 6,
                onChanged: (rowIndex, colIndex, value) {
                  _updateEngineeringField(store, rowIndex, colIndex, value);
                  store.selectedEngineering.refresh();
                },
                onActionSelected: (rowIndex, rowValue, action) async {
                  final item = rowValue as EngineeringItem;
                  if (action == _InventoryRowAction.edit) {
                    await _showEngineeringEditDialog(store, rowIndex, item);
                  } else {
                    await _removeEngineeringFromInventory(store, item);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicesTable(InventoryServicesStore store) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.tableBorderBlue),
        ),
        child: Column(
          children: [
            _sectionTitle('Services', hasHeaderCheckbox: true),
            Expanded(
              child: _table(
                headers: const [
                  'No',
                  'Services',
                  'Code',
                  'Unit',
                  'Price\n(Kwd)',
                  'Tax',
                  '',
                ],
                controller: _servicesScrollController,
                rows: store.selectedServices.asMap().entries.map((entry) {
                  return [
                    (entry.key + 1).toString(),
                    entry.value.name,
                    entry.value.code,
                    entry.value.unit,
                    _formatInventoryServiceNumber(entry.value.price),
                    entry.value.tax,
                    entry.value,
                  ];
                }).toList(),
                checkboxCols: const [5],
                actionCol: 6,
                onChanged: (rowIndex, colIndex, value) {
                  _updateServiceField(store, rowIndex, colIndex, value);
                  store.selectedServices.refresh();
                },
                onActionSelected: (rowIndex, rowValue, action) async {
                  final item = rowValue as ServiceItem;
                  if (action == _InventoryRowAction.edit) {
                    await _showServiceEditDialog(store, rowIndex, item);
                  } else {
                    await _removeServiceFromInventory(store, item);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {bool hasHeaderCheckbox = false}) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: AppTheme.primaryColor,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
	          if (hasHeaderCheckbox)
	            Obx(() {
	              final locked = c.isLocked.value;
	              return Transform.scale(
	                scale: 0.72,
	                child: Checkbox(
	                  value: false,
	                  onChanged: locked ? null : (_) {},
	                  visualDensity: VisualDensity.compact,
	                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
	                ),
	              );
	            }),
        ],
      ),
    );
  }

  Widget _tableHeader(String title, IconData icon, int count) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count items',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _table({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required ScrollController controller,
    List<int> checkboxCols = const [],
    int? actionCol,
    void Function(int rowIndex, int colIndex, dynamic value)? onChanged,
    Future<void> Function(
      int rowIndex,
      dynamic rowValue,
      _InventoryRowAction action,
    )?
    onActionSelected,
  }) {
    final Map<int, TableColumnWidth> columnWidths = headers.length == 8
        ? const {
            0: FixedColumnWidth(35),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FixedColumnWidth(55),
            7: FixedColumnWidth(42),
          }
        : headers.length == 7
        ? const {
            0: FixedColumnWidth(35),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FixedColumnWidth(55),
            6: FixedColumnWidth(42),
          }
        : const {
            0: FixedColumnWidth(35),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FixedColumnWidth(55),
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(
          constraints.maxWidth,
          headers.length == 8
              ? 680.0
              : headers.length == 7
              ? 560.0
              : 520.0,
        );
        return Scrollbar(
          thumbVisibility: true,
          controller: controller,
          child: SingleChildScrollView(
            controller: controller,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                border: TableBorder.all(color: AppTheme.tableGridBlue, width: 1),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: columnWidths,
                children: [
                  _headerRow(headers),
                  ...rows.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final row = entry.value;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      children: List.generate(row.length, (i) {
                        if (actionCol != null && i == actionCol) {
                          return _actionCell(
                            onSelected: (action) async {
                              await onActionSelected?.call(
                                rowIndex,
                                row[i],
                                action,
                              );
                            },
                          );
                        }
                        if (checkboxCols.contains(i)) {
                          return _checkboxCell(
                            row[i],
                            onChanged: (v) => onChanged?.call(rowIndex, i, v),
                          );
                        }
                        return _editableCell(
                          row[i].toString(),
                          cellKey: 'r${rowIndex}_c$i',
                          onChanged: (v) => onChanged?.call(rowIndex, i, v),
                        );
                      }),
                    );
                  }),
                  ...List.generate(
                    math.max(0, 8 - rows.length),
                    (_) => TableRow(
                      children: List.generate(
                        headers.length,
                        (_) => const SizedBox(height: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TableRow _headerRow(List<String> headers) {
    return TableRow(
      decoration: const BoxDecoration(color: ugColumnHeader),
      children: headers
          .map(
            (header) => Container(
              height: 28,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                header,
                style: const TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _editableCell(
    String value, {
    Function(String)? onChanged,
    String? cellKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Obx(
        () => isLocked.value
            ? Text(
                value,
                style: AppTheme.wellLikeBodyText,
              )
            : TextFormField(
                key: ValueKey(cellKey ?? value),
                initialValue: value,
                onChanged: onChanged,
                style: AppTheme.wellLikeBodyText,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
      ),
    );
  }

  Widget _checkboxCell(bool value, {Function(bool)? onChanged}) {
    return Center(
      child: Obx(
        () => Transform.scale(
          scale: 0.75,
          child: Checkbox(
            value: value,
            onChanged: isLocked.value ? null : (v) => onChanged?.call(v!),
            activeColor: AppTheme.successColor,
            checkColor: Colors.white,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _actionCell({
    required Future<void> Function(_InventoryRowAction action)? onSelected,
  }) {
    return Center(
      child: PopupMenuButton<_InventoryRowAction>(
        padding: EdgeInsets.zero,
        tooltip: 'Actions',
        onSelected: (action) async {
          await onSelected?.call(action);
        },
        itemBuilder: (context) => const [
          PopupMenuItem<_InventoryRowAction>(
            value: _InventoryRowAction.edit,
            child: Text('Edit', style: TextStyle(fontSize: 11)),
          ),
          PopupMenuItem<_InventoryRowAction>(
            value: _InventoryRowAction.delete,
            child: Text('Delete', style: TextStyle(fontSize: 11)),
          ),
        ],
        child: const Icon(Icons.more_vert, size: 16, color: Color(0xFF4A4A4A)),
      ),
    );
  }

  Future<void> _showPackageEditDialog(
    InventoryServicesStore store,
    int rowIndex,
    PackageItem item,
  ) async {
    final updated = await _showServiceItemDialog(
      title: 'Edit Package',
      name: item.name,
      code: item.code,
      unit: item.unit,
      price: item.price,
      initial: item.initial,
      tax: item.tax,
      showInitial: true,
    );
    if (updated == null) return;
    store.selectedPackages[rowIndex] = PackageItem(
      id: item.id,
      name: updated.name,
      code: updated.code,
      unit: updated.unit,
      price: updated.price,
      initial: updated.initial,
      tax: updated.tax,
    );
    _sortPackages(store);
    store.selectedPackages.refresh();
  }

  Future<void> _showEngineeringEditDialog(
    InventoryServicesStore store,
    int rowIndex,
    EngineeringItem item,
  ) async {
    final updated = await _showServiceItemDialog(
      title: 'Edit Engineering',
      name: item.name,
      code: item.code,
      unit: item.unit,
      price: item.price,
      initial: item.initial,
      tax: item.tax,
    );
    if (updated == null) return;
    store.selectedEngineering[rowIndex] = EngineeringItem(
      id: item.id,
      name: updated.name,
      code: updated.code,
      unit: updated.unit,
      price: updated.price,
      initial: updated.initial,
      tax: updated.tax,
    );
    _sortEngineering(store);
    store.selectedEngineering.refresh();
  }

  Future<void> _showServiceEditDialog(
    InventoryServicesStore store,
    int rowIndex,
    ServiceItem item,
  ) async {
    final updated = await _showServiceItemDialog(
      title: 'Edit Service',
      name: item.name,
      code: item.code,
      unit: item.unit,
      price: item.price,
      initial: item.initial,
      tax: item.tax,
    );
    if (updated == null) return;
    store.selectedServices[rowIndex] = ServiceItem(
      id: item.id,
      name: updated.name,
      code: updated.code,
      unit: updated.unit,
      price: updated.price,
      initial: updated.initial,
      tax: updated.tax,
    );
    _sortServices(store);
    store.selectedServices.refresh();
  }

  Future<_ServiceItemDraft?> _showServiceItemDialog({
    required String title,
    required String name,
    required String code,
    required String unit,
    required double price,
    required String initial,
    required bool tax,
    bool showInitial = false,
  }) async {
    final nameController = TextEditingController(text: name);
    final codeController = TextEditingController(text: code);
    final unitController = TextEditingController(text: unit);
    final priceController = TextEditingController(
      text: price == 0 ? '' : _formatInventoryServiceNumber(price),
    );
    final initialController =
        TextEditingController(text: _formatInventoryServiceText(initial));
    var draftTax = tax;

    return showDialog<_ServiceItemDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField('Name', nameController),
                    const SizedBox(height: 10),
                    _dialogField('Code', codeController),
                    const SizedBox(height: 10),
                    _dialogField('Unit', unitController),
                    const SizedBox(height: 10),
                    _dialogField('Price', priceController),
                    if (showInitial) ...[
                      const SizedBox(height: 10),
                      _dialogField('Initial', initialController),
                    ],
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: draftTax,
                      onChanged: (value) {
                        setDialogState(() => draftTax = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Tax'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      _ServiceItemDraft(
                        name: nameController.text.trim(),
                        code: codeController.text.trim(),
                        unit: unitController.text.trim(),
                        price:
                            double.tryParse(priceController.text.trim()) ?? 0.0,
                        initial: initialController.text.trim(),
                        tax: draftTax,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Future<void> _removePackageFromInventory(
    InventoryServicesStore store,
    PackageItem item,
  ) async {
    if (await _isPackageUsedInAnyReport(item)) {
      _showToast(
        'This package has already been used in a report and cannot be deleted.',
        isError: true,
      );
      return;
    }
    final confirmed = await _showDeleteConfirmation('Package');
    if (!confirmed) return;
    final index = _findPackageIndex(store, item);
    if (index == -1) return;
    store.selectedPackages.removeAt(index);
    store.selectedPackages.refresh();
    await _saveServicesInventorySnapshot(store);
    _showToast('Package removed from inventory');
  }

  Future<void> _removeServiceFromInventory(
    InventoryServicesStore store,
    ServiceItem item,
  ) async {
    if (await _isServiceUsedInAnyReport(item)) {
      _showToast(
        'This service has already been used in a report and cannot be deleted.',
        isError: true,
      );
      return;
    }
    final confirmed = await _showDeleteConfirmation('Service');
    if (!confirmed) return;
    final index = _findServiceIndex(store, item);
    if (index == -1) return;
    store.selectedServices.removeAt(index);
    store.selectedServices.refresh();
    await _saveServicesInventorySnapshot(store);
    _showToast('Service removed from inventory');
  }

  Future<void> _removeEngineeringFromInventory(
    InventoryServicesStore store,
    EngineeringItem item,
  ) async {
    if (await _isEngineeringUsedInAnyReport(item)) {
      _showToast(
        'This engineering item has already been used in a report and cannot be deleted.',
        isError: true,
      );
      return;
    }
    final confirmed = await _showDeleteConfirmation('Engineering');
    if (!confirmed) return;
    final index = _findEngineeringIndex(store, item);
    if (index == -1) return;
    store.selectedEngineering.removeAt(index);
    store.selectedEngineering.refresh();
    await _saveServicesInventorySnapshot(store);
    _showToast('Engineering removed from inventory');
  }

  Future<bool> _showDeleteConfirmation(String itemType) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete $itemType'),
            content: Text('Are you sure you want to delete this $itemType?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _saveServicesInventorySnapshot(InventoryServicesStore store) async {
    final productsStore = Get.find<InventoryProductsStore>();
    final products = productsStore.selectedProducts.map((p) {
      return ProductInventoryModel(
        id: p.id,
        product: p.product,
        code: p.code,
        sg: p.sg,
        unit: p.formattedUnit,
        price: p.price,
        initial: p.initial,
        group: p.group,
        volAdd: p.volAdd,
        calculate: p.calculate,
        plot: p.plot,
        tax: p.tax,
      );
    }).toList();

    await InventoryProductsService.applyInventoryData(
      wellId: c.wellId,
      products: products,
      premixed: c.premixed.toList(),
      obm: c.obm.toList(),
      packages: store.selectedPackages.toList(),
      services: store.selectedServices.toList(),
      engineering: store.selectedEngineering.toList(),
      bulkTankSetupFee: c.bulkTankSetupFee.value,
      taxRate: c.taxRate.value,
      applyPricesOption: c.applyChangedPricesOption.value,
      fromDate: c.fromDate.value,
    );
  }

  Future<bool> _isPackageUsedInAnyReport(PackageItem item) {
    return _isInventoryItemUsedInAnyReport(
      endpoint: 'cs/package',
      usedField: 'used',
      nameField: 'packageName',
      itemId: item.id,
      itemName: item.name,
      itemCode: item.code,
    );
  }

  Future<bool> _isServiceUsedInAnyReport(ServiceItem item) {
    return _isInventoryItemUsedInAnyReport(
      endpoint: 'cs/service',
      usedField: 'usage',
      nameField: 'serviceName',
      itemId: item.id,
      itemName: item.name,
      itemCode: item.code,
    );
  }

  Future<bool> _isEngineeringUsedInAnyReport(EngineeringItem item) {
    return _isInventoryItemUsedInAnyReport(
      endpoint: 'cs/engineering',
      usedField: 'usage',
      nameField: 'engineeringName',
      itemId: item.id,
      itemName: item.name,
      itemCode: item.code,
    );
  }

  Future<bool> _isInventoryItemUsedInAnyReport({
    required String endpoint,
    required String usedField,
    required String nameField,
    required String? itemId,
    required String itemName,
    required String itemCode,
  }) async {
    final currentWellId = c.wellId.trim();
    if (currentWellId.isEmpty) return false;

    try {
      final reports = reportContext.reports.toList(growable: false);
      final reportIds = reports
          .map((report) => report.id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final allItems = <Map<String, dynamic>>[];

      if (reportIds.isEmpty) {
        final fallbackUri = Uri.parse('${ApiEndpoint.baseUrl}$endpoint').replace(
          queryParameters: {'wellId': currentWellId},
        );
        final fallbackResponse = await http.get(
          fallbackUri,
          headers: ApiEndpoint.jsonHeaders,
        );
        if (fallbackResponse.statusCode == 200 ||
            fallbackResponse.statusCode == 201) {
          final decoded = jsonDecode(fallbackResponse.body);
          final List items = decoded is Map ? decoded['data'] ?? const [] : const [];
          for (final raw in items) {
            if (raw is Map) {
              allItems.add(Map<String, dynamic>.from(raw));
            }
          }
        }
      } else {
        for (final reportId in reportIds) {
          final uri = Uri.parse('${ApiEndpoint.baseUrl}$endpoint').replace(
            queryParameters: {'wellId': currentWellId, 'reportId': reportId},
          );
          final response = await http.get(uri, headers: ApiEndpoint.jsonHeaders);
          if (response.statusCode != 200 && response.statusCode != 201) {
            continue;
          }
          final decoded = jsonDecode(response.body);
          final List items = decoded is Map ? decoded['data'] ?? const [] : const [];
          for (final raw in items) {
            if (raw is Map) {
              allItems.add(Map<String, dynamic>.from(raw));
            }
          }
        }
      }

      final cleanItemId = itemId?.trim() ?? '';
      final cleanItemName = itemName.trim().toLowerCase();
      final cleanItemCode = itemCode.trim().toLowerCase();

      for (final entry in allItems) {
        final entryWellId = entry['wellId']?.toString().trim() ?? '';
        if (entryWellId.isNotEmpty && entryWellId != currentWellId) continue;

        final used = double.tryParse(entry[usedField]?.toString() ?? '') ?? 0;
        if (used <= 0) continue;

        final entryName = entry[nameField]?.toString().trim().toLowerCase() ?? '';
        final entryCode = entry['code']?.toString().trim().toLowerCase() ?? '';
        final entryId =
            entry['itemId']?.toString().trim() ??
            entry['_id']?.toString().trim() ??
            '';
        final sameId = cleanItemId.isNotEmpty && entryId == cleanItemId;
        final sameName = cleanItemName.isNotEmpty && entryName == cleanItemName;
        final sameCode = cleanItemCode.isNotEmpty && entryCode == cleanItemCode;
        if (sameId || sameName || sameCode) return true;
      }
    } catch (e) {
      debugPrint('Inventory usage check failed: $e');
    }

    return false;
  }

  int _findPackageIndex(InventoryServicesStore store, PackageItem item) {
    return store.selectedPackages.indexWhere((entry) {
      return _sameInventoryItem(entry.id, entry.name, entry.code, item.id, item.name, item.code);
    });
  }

  int _findServiceIndex(InventoryServicesStore store, ServiceItem item) {
    return store.selectedServices.indexWhere((entry) {
      return _sameInventoryItem(entry.id, entry.name, entry.code, item.id, item.name, item.code);
    });
  }

  int _findEngineeringIndex(InventoryServicesStore store, EngineeringItem item) {
    return store.selectedEngineering.indexWhere((entry) {
      return _sameInventoryItem(entry.id, entry.name, entry.code, item.id, item.name, item.code);
    });
  }

  bool _sameInventoryItem(
    String? leftId,
    String leftName,
    String leftCode,
    String? rightId,
    String rightName,
    String rightCode,
  ) {
    final cleanLeftId = leftId?.trim() ?? '';
    final cleanRightId = rightId?.trim() ?? '';
    if (cleanLeftId.isNotEmpty &&
        cleanRightId.isNotEmpty &&
        cleanLeftId == cleanRightId) {
      return true;
    }
    return leftName.trim().toLowerCase() == rightName.trim().toLowerCase() &&
        leftCode.trim().toLowerCase() == rightCode.trim().toLowerCase();
  }

  void _updatePackageField(
    InventoryServicesStore store,
    int rowIndex,
    int colIndex,
    dynamic value,
  ) {
    final item = store.selectedPackages[rowIndex];
    switch (colIndex) {
      case 1:
        store.selectedPackages[rowIndex] = PackageItem(
          id: item.id,
          name: value.toString(),
          code: item.code,
          unit: item.unit,
          price: item.price,
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 2:
        store.selectedPackages[rowIndex] = PackageItem(
          id: item.id,
          name: item.name,
          code: value.toString(),
          unit: item.unit,
          price: item.price,
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 3:
        store.selectedPackages[rowIndex] = PackageItem(
          id: item.id,
          name: item.name,
          code: item.code,
          unit: value.toString(),
          price: item.price,
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 4:
        store.selectedPackages[rowIndex] = PackageItem(
          id: item.id,
          name: item.name,
          code: item.code,
          unit: item.unit,
          price: _parsePrice(value),
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 5:
        item.initial = value.toString();
        break;
      case 6:
        item.tax = value as bool;
        break;
    }
    _sortPackages(store);
  }

  void _updateEngineeringField(
    InventoryServicesStore store,
    int rowIndex,
    int colIndex,
    dynamic value,
  ) {
    final item = store.selectedEngineering[rowIndex];
    switch (colIndex) {
      case 1:
        store.selectedEngineering[rowIndex] = EngineeringItem(
          id: item.id,
          name: value.toString(),
          code: item.code,
          unit: item.unit,
          price: item.price,
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 2:
        store.selectedEngineering[rowIndex] = EngineeringItem(
          id: item.id,
          name: item.name,
          code: value.toString(),
          unit: item.unit,
          price: item.price,
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 3:
        store.selectedEngineering[rowIndex] = EngineeringItem(
          id: item.id,
          name: item.name,
          code: item.code,
          unit: value.toString(),
          price: item.price,
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 4:
        store.selectedEngineering[rowIndex] = EngineeringItem(
          id: item.id,
          name: item.name,
          code: item.code,
          unit: item.unit,
          price: _parsePrice(value),
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 5:
        item.tax = value as bool;
        break;
    }
    _sortEngineering(store);
  }

  void _updateServiceField(
    InventoryServicesStore store,
    int rowIndex,
    int colIndex,
    dynamic value,
  ) {
    final item = store.selectedServices[rowIndex];
    switch (colIndex) {
      case 1:
        store.selectedServices[rowIndex] = ServiceItem(
          id: item.id,
          name: value.toString(),
          code: item.code,
          unit: item.unit,
          price: item.price,
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 2:
        store.selectedServices[rowIndex] = ServiceItem(
          id: item.id,
          name: item.name,
          code: value.toString(),
          unit: item.unit,
          price: item.price,
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 3:
        store.selectedServices[rowIndex] = ServiceItem(
          id: item.id,
          name: item.name,
          code: item.code,
          unit: value.toString(),
          price: item.price,
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 4:
        store.selectedServices[rowIndex] = ServiceItem(
          id: item.id,
          name: item.name,
          code: item.code,
          unit: item.unit,
          price: _parsePrice(value),
          initial: item.initial,
          tax: item.tax,
        );
        break;
      case 5:
        item.tax = value as bool;
        break;
    }
    _sortServices(store);
  }

  double _parsePrice(dynamic value) {
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  String _formatInventoryServiceNumber(double value) {
    return formatOperationNumber(
      value,
      fallbackDecimals: 3,
      trimFallback: true,
    );
  }

  String _formatInventoryServiceText(String value) {
    return formatOperationInputText(
      value,
      fallbackDecimals: 3,
      trimFallback: true,
    );
  }

  void _sortPackages(InventoryServicesStore store) {
    store.selectedPackages.sort(
      (a, b) => _naturalSortKey(a.name, a.code, a.id).compareTo(
        _naturalSortKey(b.name, b.code, b.id),
      ),
    );
  }

  void _sortServices(InventoryServicesStore store) {
    store.selectedServices.sort(
      (a, b) => _naturalSortKey(a.name, a.code, a.id).compareTo(
        _naturalSortKey(b.name, b.code, b.id),
      ),
    );
  }

  void _sortEngineering(InventoryServicesStore store) {
    store.selectedEngineering.sort(
      (a, b) => _naturalSortKey(a.name, a.code, a.id).compareTo(
        _naturalSortKey(b.name, b.code, b.id),
      ),
    );
  }

  String _naturalSortKey(String name, String code, String? id) {
    final base = name.trim().isNotEmpty
        ? name.trim().toLowerCase()
        : code.trim().isNotEmpty
        ? code.trim().toLowerCase()
        : (id?.trim().toLowerCase() ?? '');
    return base.replaceAllMapped(RegExp(r'\d+'), (match) {
      return (match.group(0) ?? '').padLeft(12, '0');
    });
  }
}

enum _InventoryRowAction { edit, delete }

class _ServiceItemDraft {
  const _ServiceItemDraft({
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
    required this.initial,
    required this.tax,
  });

  final String name;
  final String code;
  final String unit;
  final double price;
  final String initial;
  final bool tax;
}
