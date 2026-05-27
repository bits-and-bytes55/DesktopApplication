import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
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
          border: Border.all(color: const Color(0xFFC9CDD3)),
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
                ],
                controller: _packagesScrollController,
                rows: store.selectedPackages.asMap().entries.map((entry) {
                  return [
                    (entry.key + 1).toString(),
                    entry.value.name,
                    entry.value.code,
                    entry.value.unit,
                    entry.value.price.toString(),
                    entry.value.initial,
                    entry.value.tax,
                  ];
                }).toList(),
                checkboxCols: const [6],
                onChanged: (rowIndex, colIndex, value) {
                  _updatePackageField(store, rowIndex, colIndex, value);
                  store.selectedPackages.refresh();
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
          border: Border.all(color: const Color(0xFFC9CDD3)),
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
                ],
                controller: _engineeringScrollController,
                rows: store.selectedEngineering.asMap().entries.map((entry) {
                  return [
                    (entry.key + 1).toString(),
                    entry.value.name,
                    entry.value.code,
                    entry.value.unit,
                    entry.value.price.toString(),
                    entry.value.tax,
                  ];
                }).toList(),
                checkboxCols: const [5],
                onChanged: (rowIndex, colIndex, value) {
                  _updateEngineeringField(store, rowIndex, colIndex, value);
                  store.selectedEngineering.refresh();
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
          border: Border.all(color: const Color(0xFFC9CDD3)),
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
                ],
                controller: _servicesScrollController,
                rows: store.selectedServices.asMap().entries.map((entry) {
                  return [
                    (entry.key + 1).toString(),
                    entry.value.name,
                    entry.value.code,
                    entry.value.unit,
                    entry.value.price.toString(),
                    entry.value.tax,
                  ];
                }).toList(),
                checkboxCols: const [5],
                onChanged: (rowIndex, colIndex, value) {
                  _updateServiceField(store, rowIndex, colIndex, value);
                  store.selectedServices.refresh();
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
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2F2F2F),
              ),
            ),
          ),
          if (hasHeaderCheckbox)
            Transform.scale(
              scale: 0.72,
              child: Checkbox(
                value: false,
                onChanged: c.isLocked.value ? null : (_) {},
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
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
    void Function(int rowIndex, int colIndex, dynamic value)? onChanged,
  }) {
    final Map<int, TableColumnWidth> columnWidths = headers.length == 7
        ? const {
            0: FixedColumnWidth(35),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FixedColumnWidth(55),
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
          headers.length == 7 ? 640.0 : 520.0,
        );
        return Scrollbar(
          thumbVisibility: true,
          controller: controller,
          child: SingleChildScrollView(
            controller: controller,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: columnWidths,
                children: [
                  _headerRow(headers),
                  ...rows.asMap().entries.map((entry) {
                    final rowIndex = entry.key;
                    final row = entry.value;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: rowIndex.isEven
                            ? Colors.white
                            : const Color(0xFFFBFBFB),
                      ),
                      children: List.generate(row.length, (i) {
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      children: headers
          .map(
            (header) => Container(
              height: 28,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                header,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              )
            : TextFormField(
                key: ValueKey(cellKey ?? value),
                initialValue: value,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
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
  }

  double _parsePrice(dynamic value) {
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }
}
