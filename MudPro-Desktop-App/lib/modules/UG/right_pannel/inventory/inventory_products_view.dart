import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_pickup/inventory_pickup_tabs.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/model/ug_inventory_product_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class InventoryProductsView extends StatefulWidget {
  const InventoryProductsView({super.key});

  @override
  State<InventoryProductsView> createState() => _InventoryProductsViewState();
}

class _InventoryProductsViewState extends State<InventoryProductsView> {
  final c = Get.find<UgController>();
  final MudController? mudController = Get.isRegistered<MudController>()
      ? Get.find<MudController>()
      : null;
  final _repository = AuthRepository();
  final padWellC = padWellContext;
  static const int _minDisplayRows = 5;

  String get wellId {
    final selectedWellId = padWellC.selectedWellId.value.trim();
    if (selectedWellId.isNotEmpty) return selectedWellId;
    return c.wellId.trim();
  }

  bool _isLoading = false;
  bool _isObmPickupOpening = false;
  String _selectedPremixDescription = '';
  bool _productsInventorySaveInFlight = false;
  bool _productsInventorySaveQueued = false;
  Timer? _productsInventorySaveTimer;
  Timer? _premixedCreateTimer;
  Timer? _obmCreateTimer;
  final Map<String, Timer> _premixedUpdateTimers = {};
  final Map<String, Timer> _obmUpdateTimers = {};

  // Controllers for empty rows
  final Map<String, TextEditingController> _premixedControllers = {};
  final Map<String, TextEditingController> _obmControllers = {};

  // Scroll Controllers
  final _mainVerticalScroll = ScrollController();
  final _mainHorizontalScroll = ScrollController();
  final _premixedVerticalScroll = ScrollController();
  final _premixedHorizontalScroll = ScrollController();
  final _obmVerticalScroll = ScrollController();
  final _obmHorizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeEmptyRowControllers();
  }

  @override
  void dispose() {
    _productsInventorySaveTimer?.cancel();
    _premixedCreateTimer?.cancel();
    _obmCreateTimer?.cancel();
    for (final timer in _premixedUpdateTimers.values) {
      timer.cancel();
    }
    for (final timer in _obmUpdateTimers.values) {
      timer.cancel();
    }
    _mainVerticalScroll.dispose();
    _mainHorizontalScroll.dispose();
    _premixedVerticalScroll.dispose();
    _premixedHorizontalScroll.dispose();
    _obmVerticalScroll.dispose();
    _obmHorizontalScroll.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _initializeEmptyRowControllers() {
    // Premixed controllers
    _premixedControllers['description'] = TextEditingController();
    _premixedControllers['mw'] = TextEditingController();
    _premixedControllers['leasingFee'] = TextEditingController();
    _premixedControllers['mudType'] = TextEditingController();

    // Spare controllers for other uses if needed
    // OBM controllers moved to UgController
  }

  void _disposeControllers() {
    _premixedControllers.values.forEach((controller) => controller.dispose());
    _obmControllers.values.forEach((controller) => controller.dispose());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    if (wellId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final store = Get.find<InventoryProductsStore>();

      if (store.selectedProducts.isEmpty) {
        final savedProducts = await InventoryProductsService.fetchProducts(
          wellId,
        );
        if (savedProducts.isNotEmpty) {
          store.setSelectedProducts(
            savedProducts.map(_toProductModel).toList(),
          );
        }
      }

      // Load Premixed
      final premixedList = await _repository.getPremixed(wellId);
      c.premixed.value = premixedList;

      // Load OBM
      final res = await _repository.getObm(wellId);
	      if (res['success'] == true && res['data'] is List) {
	        c.obm.value = res['data'] as List<ObmModel>;
	      } else {
	        c.obm.value = [];
	      }
	      try {
	        final inventorySnapshot =
	            await InventoryProductsService.getInventoryData(wellId);
	        final snapshotObm = inventorySnapshot['obm'];
	        if (snapshotObm is List && snapshotObm.isNotEmpty) {
	          c.obm.value = snapshotObm
	              .map(
	                (item) => ObmModel.fromJson(Map<String, dynamic>.from(item)),
	              )
	              .toList();
	        }
	      } catch (_) {}
	      _syncObmHeaderWithPremix();
        _normalizeObmPremixLinks();

      print('✅ Data loaded successfully');
      print('Premixed count: ${premixedList.length}');
      print('OBM count: ${c.obm.length}');
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        _showToast('Failed to load data', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ProductModel _toProductModel(dynamic product) {
    final unitParts = _splitInventoryUnit(product.unit);
    return ProductModel(
      id: product.id,
      product: product.product,
      code: product.code,
      sg: product.sg,
      unitNum: unitParts['num'] ?? '',
      unitClass: unitParts['class'] ?? '',
      group: product.group,
      a: product.price,
      price: product.price,
      initial: product.initial,
      volAdd: product.volAdd,
      calculate: product.calculate,
      plot: product.plot ?? false,
      tax: product.tax,
    );
  }

  void _showToast(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.red.shade600 : Colors.green.shade600,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  bool get _hasPremixedDraftData {
    return c.premixedDescController.text.trim().isNotEmpty &&
        (c.premixedMwController.text.trim().isNotEmpty ||
            c.premixedLeasingFeeController.text.trim().isNotEmpty ||
            c.premixedMudTypeController.text.trim().isNotEmpty ||
            c.premixedTaxNew.value);
  }

  bool get _hasAnyPremixedDraftData {
    return c.premixedDescController.text.trim().isNotEmpty ||
        c.premixedMwController.text.trim().isNotEmpty ||
        c.premixedLeasingFeeController.text.trim().isNotEmpty ||
        c.premixedMudTypeController.text.trim().isNotEmpty ||
        c.premixedTaxNew.value;
  }

  bool get _hasObmDraftData {
    return c.obmProductController.text.trim().isNotEmpty &&
        (c.obmCodeController.text.trim().isNotEmpty ||
            c.obmSgController.text.trim().isNotEmpty ||
            c.obmConcController.text.trim().isNotEmpty ||
            c.obmUnitController.text.trim().isNotEmpty);
  }

  List<ObmModel> _selectedPremixObmItems(List<ObmModel> obmItems) {
    final selected = _selectedPremixDescription.trim().toLowerCase();
    if (selected.isEmpty) return const <ObmModel>[];
    return obmItems.where((item) {
      return item.premixDescription.trim().toLowerCase() == selected;
    }).toList();
  }

  String _unitForObmItem(ObmModel item) {
    final directUnit = item.unit.trim();
    if (directUnit.isNotEmpty) return directUnit;
    if (!Get.isRegistered<InventoryProductsStore>()) return '';

    final store = Get.find<InventoryProductsStore>();
    final itemCode = item.code.trim().toLowerCase();
    final itemName = item.product.trim().toLowerCase();
    for (final product in store.selectedProducts) {
      final codeMatches =
          itemCode.isNotEmpty && product.code.trim().toLowerCase() == itemCode;
      final nameMatches =
          itemName.isNotEmpty &&
          product.product.trim().toLowerCase() == itemName;
      if (codeMatches || nameMatches) {
        return product.formattedUnit;
      }
    }
    return '';
  }

  void _schedulePremixedDraftSave() {
    if (c.isLocked.value) return;
    _premixedCreateTimer?.cancel();
    _premixedCreateTimer = Timer(const Duration(milliseconds: 900), () async {
      if (!_hasPremixedDraftData) return;
      await _addPremixedFromDraft(silent: true);
    });
  }

  void _scheduleObmDraftSave() {
    if (c.isLocked.value) return;
    _obmCreateTimer?.cancel();
    _obmCreateTimer = Timer(const Duration(milliseconds: 900), () async {
      if (!_hasObmDraftData) return;
      await _addObmFromDraft(silent: true);
    });
  }

  void _schedulePremixedUpdate(PremixModel premixed) {
    final id = premixed.id?.trim() ?? '';
    if (id.isEmpty || c.isLocked.value) return;
    _premixedUpdateTimers[id]?.cancel();
    _premixedUpdateTimers[id] = Timer(
      const Duration(milliseconds: 800),
      () async {
        try {
          final updated = await _repository.updatePremixed(id, premixed);
          final index = c.premixed.indexWhere((item) => item.id == id);
          if (index != -1) {
            c.premixed[index] = updated;
            c.premixed.refresh();
          }
        } catch (e) {
          if (mounted) {
            _showToast('Failed to update premixed', isError: true);
          }
        }
      },
    );
  }

  void _scheduleObmUpdate(ObmModel obm) {
    final id = obm.id?.trim() ?? '';
    if (c.isLocked.value) return;
    _scheduleProductsInventorySave();
    if (id.isEmpty) return;
    _obmUpdateTimers[id]?.cancel();
    _obmUpdateTimers[id] = Timer(const Duration(milliseconds: 800), () async {
      try {
        final updated = await _repository.updateObm(id, obm);
        final index = c.obm.indexWhere((item) => item.id == id);
        if (index != -1) {
          c.obm[index] = updated.copyWith(
            premixDescription: obm.premixDescription,
            unit: obm.unit,
          );
          c.obm.refresh();
          await _saveProductsInventorySnapshot();
        }
      } catch (e) {
        if (mounted) {
          _showToast('Failed to update OBM', isError: true);
        }
      }
    });
  }

  void _scheduleProductsInventorySave() {
    if (c.isLocked.value) return;
    _productsInventorySaveTimer?.cancel();
    _productsInventorySaveTimer = Timer(
      const Duration(milliseconds: 800),
      _saveProductsInventorySnapshot,
    );
  }

  Future<void> _saveProductsInventorySnapshot() async {
    if (!mounted || c.isLocked.value) return;

    final activeWellId = wellId.isNotEmpty ? wellId : c.wellId;
    if (activeWellId.trim().isEmpty) {
      _showToast('No well selected', isError: true);
      return;
    }

    if (_productsInventorySaveInFlight) {
      _productsInventorySaveQueued = true;
      return;
    }

    _productsInventorySaveInFlight = true;
    try {
      final store = Get.find<InventoryProductsStore>();
      final servicesStore = Get.isRegistered<InventoryServicesStore>()
          ? Get.find<InventoryServicesStore>()
          : Get.put(InventoryServicesStore());

      if (servicesStore.selectedPackages.isEmpty &&
          servicesStore.selectedEngineering.isEmpty &&
          servicesStore.selectedServices.isEmpty) {
        final fetchedPackages = await InventoryProductsService.fetchPackages(
          activeWellId,
        );
        final fetchedEngineering =
            await InventoryProductsService.fetchEngineering(activeWellId);
        final fetchedServices = await InventoryProductsService.fetchServices(
          activeWellId,
        );
        servicesStore.setSelectedServices(
          packages: fetchedPackages,
          engineering: fetchedEngineering,
          services: fetchedServices,
        );
      }

      await InventoryProductsService.applyInventoryData(
        wellId: activeWellId,
        products: store.selectedProducts.map(_toInventoryProductModel).toList(),
        premixed: c.premixed.toList(),
        obm: c.obm.toList(),
        packages: servicesStore.selectedPackages.toList(),
        engineering: servicesStore.selectedEngineering.toList(),
        services: servicesStore.selectedServices.toList(),
        bulkTankSetupFee: c.bulkTankSetupFee.value,
        taxRate: c.taxRate.value,
        applyPricesOption: c.applyChangedPricesOption.value,
        fromDate: c.fromDate.value,
      );
    } catch (e) {
      if (mounted) {
        _showToast('Failed to auto save products', isError: true);
      }
    } finally {
      _productsInventorySaveInFlight = false;
      if (_productsInventorySaveQueued) {
        _productsInventorySaveQueued = false;
        _scheduleProductsInventorySave();
      }
    }
  }

  ProductInventoryModel _toInventoryProductModel(ProductModel p) {
    return ProductInventoryModel(
      id: p.id,
      product: p.product,
      code: p.code,
      sg: p.sg,
      unit: p.formattedUnit,
      price: p.price.isNotEmpty ? p.price : p.a,
      initial: p.initial,
      group: p.group,
      volAdd: p.volAdd,
      calculate: p.calculate,
      plot: p.plot,
      tax: p.tax,
    );
  }

  Widget _withRowMenu({
    required Widget child,
    Future<void> Function()? onDelete,
    Future<void> Function()? onEdit,
    Future<void> Function()? onAdd,
  }) {
    if (onDelete == null && onEdit == null && onAdd == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) async {
        final action = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: [
            if (onAdd != null)
              const PopupMenuItem<String>(
                value: 'add',
                child: Text('Add', style: TextStyle(fontSize: 11)),
              ),
            if (onEdit != null)
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit', style: TextStyle(fontSize: 11)),
              ),
            if (onDelete != null)
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete', style: TextStyle(fontSize: 11)),
              ),
          ],
        );

        if (!mounted || action == null) return;
        if (action == 'add' && onAdd != null) {
          await onAdd();
        }
        if (action == 'edit' && onEdit != null) {
          await onEdit();
        }
        if (action == 'delete' && onDelete != null) {
          await onDelete();
        }
      },
      child: child,
    );
  }

  TableRow _emptyInventoryRow({
    required int columnCount,
    Color? backgroundColor,
  }) {
    return TableRow(
      decoration: BoxDecoration(color: backgroundColor ?? Colors.white),
      children: List.generate(
        columnCount,
        (_) =>
            SizedBox(height: 28, child: Container(color: Colors.transparent)),
      ),
    );
  }

  List<Widget> _wrapMenuCells(
    List<Widget> cells, {
    Future<void> Function()? onDelete,
    Future<void> Function()? onEdit,
    Future<void> Function()? onAdd,
  }) {
    return cells
        .map(
          (cell) => _withRowMenu(
            child: cell,
            onDelete: onDelete,
            onEdit: onEdit,
            onAdd: onAdd,
          ),
        )
        .toList();
  }

  Widget _inventorySectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2F2F2F),
          ),
        ),
      ),
    );
  }

  Widget _inventoryDraftCell({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: TextFormField(
        controller: controller,
        readOnly: c.isLocked.value,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          filled: true,
          fillColor: const Color(0xFFFFF9CC),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<InventoryProductsStore>();

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading inventory data...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          // ================= MAIN PRODUCTS TABLE =================
          Expanded(flex: 3, child: _buildProductsTable(store)),

          const SizedBox(height: 6),

          // ================= BOTTOM TABLES =================
          Expanded(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      Expanded(child: _premixedMudTable()),
                      const SizedBox(height: 8),
                      Expanded(child: _obmTable()),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(flex: 1, child: _premixedMudTable()),
                      const SizedBox(width: 6),
                      Expanded(flex: 1, child: _obmTable()),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= PRODUCTS TABLE =================
  Widget _buildProductsTable(InventoryProductsStore store) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          _inventorySectionTitle('Products'),
          Expanded(
            child: Obx(() {
              final productsToDisplay = store.selectedProducts;

              if (productsToDisplay.isEmpty) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onSecondaryTapDown: c.isLocked.value
                      ? null
                      : (details) => _showEmptyProductContextMenu(
                          store,
                          details.globalPosition,
                        ),
                  child: Center(
                    child: Text(
                      'No products selected',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = math.max(constraints.maxWidth, 1180.0);
                  return Scrollbar(
                    controller: _mainVerticalScroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _mainHorizontalScroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: SingleChildScrollView(
                          controller: _mainVerticalScroll,
                          child: Table(
                            border: TableBorder.all(
                              color: AppTheme.tableGridBlue,
                              width: 1,
                            ),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: const {
                              0: FixedColumnWidth(40),
                              1: FlexColumnWidth(2.2),
                              2: FlexColumnWidth(1),
                              3: FlexColumnWidth(0.8),
                              4: FlexColumnWidth(1.1),
                              5: FlexColumnWidth(0.95),
                              6: FlexColumnWidth(0.9),
                              7: FlexColumnWidth(1.55),
                              8: FlexColumnWidth(1),
                              9: FlexColumnWidth(0.9),
                              10: FlexColumnWidth(0.8),
                              11: FlexColumnWidth(0.65),
                            },
                            children: [
                              // Header Row
                              TableRow(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3F3F3),
                                ),
                                children: [
                                  _tableHeaderCell('No'),
                                  _tableHeaderCell('Product'),
                                  _tableHeaderCell('Code'),
                                  _tableHeaderCell('SG'),
                                  _tableHeaderCell('Unit'),
                                  _tableHeaderCell('Price\n(Kwd)'),
                                  _tableHeaderCell('Initial'),
                                  _tableHeaderCell('Group'),
                                  _tableHeaderCheckboxCell(
                                    'Vol. Addition',
                                    productsToDisplay.isNotEmpty &&
                                        productsToDisplay.every(
                                          (p) => p.volAdd,
                                        ),
                                    (value) {
                                      for (final product in productsToDisplay) {
                                        product.volAdd = value;
                                      }
                                      store.selectedProducts.refresh();
                                      _scheduleProductsInventorySave();
                                    },
                                  ),
                                  _tableHeaderCheckboxCell(
                                    'Calculate',
                                    productsToDisplay.isNotEmpty &&
                                        productsToDisplay.every(
                                          (p) => p.calculate,
                                        ),
                                    (value) {
                                      for (final product in productsToDisplay) {
                                        product.calculate = value;
                                      }
                                      store.selectedProducts.refresh();
                                      _scheduleProductsInventorySave();
                                    },
                                  ),
                                  _tableHeaderCheckboxCell(
                                    'Plot',
                                    productsToDisplay.isNotEmpty &&
                                        productsToDisplay.every((p) => p.plot),
                                    (value) {
                                      for (final product in productsToDisplay) {
                                        product.plot = value;
                                      }
                                      store.selectedProducts.refresh();
                                      _scheduleProductsInventorySave();
                                    },
                                  ),
                                  _tableHeaderCheckboxCell(
                                    'Tax',
                                    productsToDisplay.isNotEmpty &&
                                        productsToDisplay.every((p) => p.tax),
                                    (value) {
                                      for (final product in productsToDisplay) {
                                        product.tax = value;
                                      }
                                      store.selectedProducts.refresh();
                                      _scheduleProductsInventorySave();
                                    },
                                  ),
                                ],
                              ),
                              // Data Rows
                              ...productsToDisplay.asMap().entries.map((entry) {
                                final index = entry.key;
                                final p = entry.value;
                                final rowCells = [
                                  _tableCell((index + 1).toString()),
                                  _productActionCell(p, store),
                                  _editableTableCell(
                                    p.code,
                                    key: ValueKey(
                                      'product-${_productRowKey(p, index)}-code',
                                    ),
                                    onChanged: (v) {
                                      p.code = v;
                                      _scheduleProductsInventorySave();
                                    },
                                  ),
                                  _editableTableCell(
                                    p.sg,
                                    key: ValueKey(
                                      'product-${_productRowKey(p, index)}-sg',
                                    ),
                                    onChanged: (v) {
                                      p.sg = v;
                                      _scheduleProductsInventorySave();
                                    },
                                  ),
                                  _tableCell(p.formattedUnit),
                                  _editableTableCell(
                                    p.a.isNotEmpty ? p.a : p.price,
                                    key: ValueKey(
                                      'product-${_productRowKey(p, index)}-price',
                                    ),
                                    onChanged: (v) {
                                      p.a = v;
                                      p.price = v;
                                      _scheduleProductsInventorySave();
                                    },
                                  ),
                                  _editableTableCell(
                                    p.initial,
                                    key: ValueKey(
                                      'product-${_productRowKey(p, index)}-initial',
                                    ),
                                    onChanged: (v) {
                                      p.initial = v;
                                      _scheduleProductsInventorySave();
                                    },
                                  ),
                                  _editableTableCell(
                                    p.group,
                                    key: ValueKey(
                                      'product-${_productRowKey(p, index)}-group',
                                    ),
                                    onChanged: (v) {
                                      p.group = v;
                                      _scheduleProductsInventorySave();
                                    },
                                  ),
                                  _checkboxCell(() => p.volAdd, (v) {
                                    p.volAdd = v;
                                    store.selectedProducts.refresh();
                                    _scheduleProductsInventorySave();
                                  }),
                                  _checkboxCell(() => p.calculate, (v) {
                                    p.calculate = v;
                                    store.selectedProducts.refresh();
                                    _scheduleProductsInventorySave();
                                  }),
                                  _checkboxCell(() => p.plot, (v) {
                                    p.plot = v;
                                    store.selectedProducts.refresh();
                                    _scheduleProductsInventorySave();
                                  }),
                                  _checkboxCell(() => p.tax, (v) {
                                    p.tax = v;
                                    store.selectedProducts.refresh();
                                    _scheduleProductsInventorySave();
                                  }),
                                ];

                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: index.isEven
                                        ? Colors.white
                                        : AppTheme.cardColor,
                                  ),
                                  children: _wrapProductMenuCells(
                                    rowCells,
                                    product: p,
                                    store: store,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _productActionCell(
    ProductModel product,
    InventoryProductsStore store,
  ) {
    final label = product.product.trim().isEmpty
        ? 'Untitled Product'
        : product.product;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  String _productRowKey(ProductModel product, int index) {
    final id = product.id?.trim() ?? '';
    if (id.isNotEmpty) return 'id-$id';

    final code = product.code.trim();
    if (code.isNotEmpty) return 'code-$code-$index';

    final name = product.product.trim();
    if (name.isNotEmpty) return 'name-$name-$index';

    return 'row-$index';
  }

  List<Widget> _wrapProductMenuCells(
    List<Widget> cells, {
    required ProductModel product,
    required InventoryProductsStore store,
  }) {
    return cells
        .map(
          (cell) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: c.isLocked.value
                ? null
                : (details) => _showProductContextMenu(
                    product,
                    store,
                    details.globalPosition,
                  ),
            child: cell,
          ),
        )
        .toList();
  }

  Future<void> _showProductContextMenu(
    ProductModel product,
    InventoryProductsStore store,
    Offset position,
  ) async {
    final action = await showMenu<_ProductInventoryAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem<_ProductInventoryAction>(
          value: _ProductInventoryAction.add,
          child: _InventoryMenuItem(icon: Icons.add, label: 'Add product'),
        ),
        PopupMenuItem<_ProductInventoryAction>(
          value: _ProductInventoryAction.edit,
          child: _InventoryMenuItem(icon: Icons.edit, label: 'Edit product'),
        ),
        PopupMenuItem<_ProductInventoryAction>(
          value: _ProductInventoryAction.delete,
          child: _InventoryMenuItem(
            icon: Icons.delete,
            label: 'Delete product',
            color: Colors.red,
          ),
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ProductInventoryAction.add:
        await _showProductEditDialog(ProductModel(), store, isNew: true);
        break;
      case _ProductInventoryAction.edit:
        await _showProductEditDialog(product, store);
        break;
      case _ProductInventoryAction.delete:
        await _removeProductFromInventory(product, store);
        break;
    }
  }

  Future<void> _showEmptyProductContextMenu(
    InventoryProductsStore store,
    Offset position,
  ) async {
    final action = await showMenu<_ProductInventoryAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem<_ProductInventoryAction>(
          value: _ProductInventoryAction.add,
          child: _InventoryMenuItem(icon: Icons.add, label: 'Add product'),
        ),
      ],
    );

    if (!mounted || action != _ProductInventoryAction.add) return;
    await _showProductEditDialog(ProductModel(), store, isNew: true);
  }

  Future<void> _showProductEditDialog(
    ProductModel product,
    InventoryProductsStore store, {
    bool isNew = false,
  }) async {
    final productController = TextEditingController(text: product.product);
    final codeController = TextEditingController(text: product.code);
    final sgController = TextEditingController(text: product.sg);
    final unitNumController = TextEditingController(text: product.unitNum);
    final unitClassController = TextEditingController(text: product.unitClass);
    final priceController = TextEditingController(
      text: product.a.isNotEmpty ? product.a : product.price,
    );
    final initialController = TextEditingController(text: product.initial);
    final groupController = TextEditingController(text: product.group);

    var volAdd = product.volAdd;
    var calculate = product.calculate;
    var plot = product.plot;
    var tax = product.tax;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Product'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogField('Product', productController),
                      const SizedBox(height: 10),
                      _dialogField('Code', codeController),
                      const SizedBox(height: 10),
                      _dialogField('SG', sgController),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogField('Unit Qty', unitNumController),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dialogField('Unit', unitClassController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogField('Price', priceController),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dialogField('Initial', initialController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _dialogField('Group', groupController),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: volAdd,
                        onChanged: (value) {
                          setDialogState(() => volAdd = value ?? false);
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Vol. Add'),
                      ),
                      CheckboxListTile(
                        value: calculate,
                        onChanged: (value) {
                          setDialogState(() => calculate = value ?? false);
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Calculate'),
                      ),
                      CheckboxListTile(
                        value: plot,
                        onChanged: (value) {
                          setDialogState(() => plot = value ?? false);
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Plot'),
                      ),
                      CheckboxListTile(
                        value: tax,
                        onChanged: (value) {
                          setDialogState(() => tax = value ?? false);
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Tax'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final hasDraftData =
                        productController.text.trim().isNotEmpty ||
                        codeController.text.trim().isNotEmpty ||
                        sgController.text.trim().isNotEmpty ||
                        unitNumController.text.trim().isNotEmpty ||
                        unitClassController.text.trim().isNotEmpty ||
                        priceController.text.trim().isNotEmpty ||
                        initialController.text.trim().isNotEmpty ||
                        groupController.text.trim().isNotEmpty ||
                        volAdd ||
                        calculate ||
                        plot ||
                        tax;

                    if (isNew && !hasDraftData) {
                      _showToast('Enter product details first', isError: true);
                      return;
                    }

                    product.product = productController.text.trim();
                    product.code = codeController.text.trim();
                    product.sg = sgController.text.trim();
                    product.unitNum = unitNumController.text.trim();
                    product.unitClass = unitClassController.text.trim();
                    product.a = priceController.text.trim();
                    product.price = priceController.text.trim();
                    product.initial = initialController.text.trim();
                    product.group = groupController.text.trim();
                    product.volAdd = volAdd;
                    product.calculate = calculate;
                    product.plot = plot;
                    product.tax = tax;

                    if (isNew) {
                      store.selectedProducts.add(product);
                    } else {
                      store.selectedProducts.refresh();
                    }
                    Navigator.of(dialogContext).pop();
                    _scheduleProductsInventorySave();
                    _showToast(
                      isNew
                          ? 'Product added to inventory'
                          : 'Product updated in inventory',
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

    productController.dispose();
    codeController.dispose();
    sgController.dispose();
    unitNumController.dispose();
    unitClassController.dispose();
    priceController.dispose();
    initialController.dispose();
    groupController.dispose();
  }

	  Future<void> _removeProductFromInventory(
	    ProductModel product,
	    InventoryProductsStore store,
	  ) async {
	    if (await _isProductUsedInAnyReport(product)) {
	      _showToast(
	        'This product has already been used in a report and cannot be deleted.',
	        isError: true,
	      );
	      return;
	    }

	    final confirmed = await _showDeleteConfirmation('Product');
	    if (!confirmed) return;

    final index = _findProductIndex(store, product);
    if (index == -1) {
      _showToast('Product not found', isError: true);
      return;
    }

    store.selectedProducts.removeAt(index);
    store.selectedProducts.refresh();
    _scheduleProductsInventorySave();
	    _showToast('Product removed from inventory');
	  }

	  Future<bool> _isProductUsedInAnyReport(ProductModel product) async {
	    final currentWellId = wellId.trim();
	    if (currentWellId.isEmpty) return false;

	    try {
	      final uri = Uri.parse('${ApiEndpoint.baseUrl}consume-product').replace(
	        queryParameters: {'wellId': currentWellId},
	      );
	      final response = await http.get(uri, headers: ApiEndpoint.jsonHeaders);
	      if (response.statusCode != 200 && response.statusCode != 201) {
	        return false;
	      }

	      final decoded = jsonDecode(response.body);
	      final List items = decoded is Map ? decoded['data'] ?? const [] : const [];
	      final productId = product.id?.trim() ?? '';
	      final productName = product.product.trim().toLowerCase();
	      final productCode = product.code.trim().toLowerCase();

	      for (final raw in items) {
	        if (raw is! Map) continue;
	        final item = Map<String, dynamic>.from(raw);
	        final itemWellId = item['wellId']?.toString().trim() ?? '';
	        if (itemWellId.isNotEmpty && itemWellId != currentWellId) continue;

	        final used = double.tryParse(item['used']?.toString() ?? '') ?? 0;
	        if (used <= 0) continue;

	        final itemName = item['product']?.toString().trim().toLowerCase() ?? '';
	        final itemCode = item['code']?.toString().trim().toLowerCase() ?? '';
	        final itemProductId =
	            item['productId']?.toString().trim() ?? item['_id']?.toString().trim();
	        final sameId = productId.isNotEmpty && itemProductId == productId;
	        final sameName = productName.isNotEmpty && itemName == productName;
	        final sameCode = productCode.isNotEmpty && itemCode == productCode;
	        if (sameId || sameName || sameCode) return true;
	      }
	    } catch (e) {
	      debugPrint('Product usage check failed: $e');
	    }

	    return false;
	  }

	  int _findProductIndex(InventoryProductsStore store, ProductModel product) {
    return store.selectedProducts.indexWhere((item) {
      if (identical(item, product)) return true;

      final itemId = item.id?.trim() ?? '';
      final productId = product.id?.trim() ?? '';
      if (itemId.isNotEmpty && productId.isNotEmpty && itemId == productId) {
        return true;
      }

      return item.product.trim().toLowerCase() ==
              product.product.trim().toLowerCase() &&
          item.code.trim().toLowerCase() == product.code.trim().toLowerCase();
    });
  }

  Widget _dialogField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // ================= PREMIXED MUD TABLE =================
  Widget _premixedMudTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          _inventorySectionTitle('Pre-mixed Mud'),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = math.max(constraints.maxWidth, 610.0);
                return Scrollbar(
                  controller: _premixedVerticalScroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _premixedHorizontalScroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: SingleChildScrollView(
                        controller: _premixedVerticalScroll,
                        child: Obx(() {
                          final premixedItems = c.premixed.toList(
                            growable: false,
                          );
                          final isLocked = c.isLocked.value;
                          const fillerRows = _minDisplayRows;

                          return Table(
                            border: TableBorder.all(
                              color: AppTheme.tableGridBlue,
                              width: 1,
                            ),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: const {
                              0: FixedColumnWidth(40),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(0.9),
                              3: FlexColumnWidth(1.35),
                              4: FlexColumnWidth(1.15),
                              5: FlexColumnWidth(0.7),
                            },
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF3F3F3),
                                ),
                                children: [
                                  _tableHeaderCell('#'),
                                  _tableHeaderCell('Description'),
                                  _tableHeaderCell('MW\n(ppg)'),
                                  _tableHeaderCell('Leasing Fee\n(Kwd/bbl)'),
                                  _tableHeaderCell('Mud Type'),
                                  _tableHeaderCell('Tax'),
                                ],
                              ),
                              ...premixedItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final e = entry.value;
                                final currentDescription = e.description;
                                final rowCells = [
                                  _tableCell((index + 1).toString()),
                                  _editableTableCell(
                                    e.description,
                                    key: ValueKey('${e.id}-description'),
                                    onTap: () =>
                                        _selectPremixForObm(currentDescription),
                                    onChanged: (v) {
                                      final previousDescription = e.description;
                                      e.description = v;
                                      _selectPremixForObm(v);
                                      _relinkObmToPremix(
                                        previousDescription,
                                        v,
                                      );
                                      _schedulePremixedUpdate(e);
                                    },
                                  ),
                                  _editableTableCell(
                                    e.mw,
                                    key: ValueKey('${e.id}-mw'),
                                    onTap: () =>
                                        _selectPremixForObm(e.description),
                                    onChanged: (v) {
                                      _selectPremixForObm(e.description);
                                      e.mw = v;
                                      _schedulePremixedUpdate(e);
                                    },
                                  ),
                                  _editableTableCell(
                                    e.leasingFee,
                                    key: ValueKey('${e.id}-leasingFee'),
                                    onTap: () =>
                                        _selectPremixForObm(e.description),
                                    onChanged: (v) {
                                      _selectPremixForObm(e.description);
                                      e.leasingFee = v;
                                      _schedulePremixedUpdate(e);
                                    },
                                  ),
                                  _premixedMudTypeDropdown(
                                    value: e.mudType,
                                    onTap: () =>
                                        _selectPremixForObm(e.description),
                                    onChanged: (v) {
                                      _selectPremixForObm(e.description);
                                      e.mudType = v;
                                      c.premixed.refresh();
                                      _schedulePremixedUpdate(e);
                                    },
                                  ),
                                  _checkboxCell(() => e.tax, (v) {
                                    _selectPremixForObm(e.description);
                                    e.tax = v;
                                    c.premixed.refresh();
                                    _schedulePremixedUpdate(e);
                                  }),
                                ];

                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: index.isEven
                                        ? Colors.white
                                        : const Color(0xFFFBFBFB),
                                  ),
                                  children: _wrapMenuCells(
                                    rowCells,
                                    onDelete: isLocked
                                        ? null
                                        : () => _deletePremixedItem(e),
                                  ),
                                );
                              }),
                              TableRow(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFAFAFA),
                                ),
                                children: _wrapMenuCells(
                                  [
                                    _tableCell('${premixedItems.length + 1}'),
                                    _inventoryDraftCell(
                                      controller: c.premixedDescController,
                                      hint: '',
                                      onChanged: (_) =>
                                          _schedulePremixedDraftSave(),
                                    ),
                                    _inventoryDraftCell(
                                      controller: c.premixedMwController,
                                      hint: '',
                                      onChanged: (_) =>
                                          _schedulePremixedDraftSave(),
                                    ),
                                    _inventoryDraftCell(
                                      controller:
                                          c.premixedLeasingFeeController,
                                      hint: '',
                                      onChanged: (_) =>
                                          _schedulePremixedDraftSave(),
                                    ),
                                    _premixedDraftMudTypeCell(),
                                    _checkboxCell(
                                      () => c.premixedTaxNew.value,
                                      (v) {
                                        c.premixedTaxNew.value = v;
                                        _schedulePremixedDraftSave();
                                      },
                                    ),
                                  ],
                                  onAdd:
                                      isLocked || !_hasPremixedDraftData
                                      ? null
                                      : () => _addPremixedFromDraft(),
                                  onDelete:
                                      isLocked || !_hasAnyPremixedDraftData
                                      ? null
                                      : () async => _clearPremixedDraft(),
                                ),
                              ),
                              ...List.generate(
                                fillerRows,
                                (_) => _emptyInventoryRow(columnCount: 6),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= OBM TABLE =================
  Widget _obmTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _inventorySectionTitle(_selectedPremixDescription),
              ),
              SizedBox(
                width: 36,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Inventory Pickup',
                  icon: Icon(
                    Icons.flash_on,
                    size: 16,
                    color: AppTheme.warningColor,
                  ),
                  onPressed: c.isLocked.value || _isObmPickupOpening
                      ? null
                      : () => _openObmInventoryPickup(),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = math.max(constraints.maxWidth, 500.0);
                return Scrollbar(
                  controller: _obmVerticalScroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _obmHorizontalScroll,
                    scrollDirection: Axis.horizontal,
	                    child: SizedBox(
	                      width: tableWidth,
	                      child: SingleChildScrollView(
	                        controller: _obmVerticalScroll,
	                        child: Obx(
	                          () {
                              final obmItems = c.obm.toList(growable: false);
                              final selectedObmItems = _selectedPremixObmItems(
                                obmItems,
                              );
                              final fillerRows =
                                  _minDisplayRows > selectedObmItems.length
                                  ? _minDisplayRows - selectedObmItems.length
                                  : 0;
                              return Table(
	                            border: TableBorder.all(
	                              color: AppTheme.tableGridBlue,
	                              width: 1,
	                            ),
	                            defaultVerticalAlignment:
	                                TableCellVerticalAlignment.middle,
	                            columnWidths: const {
	                              0: FixedColumnWidth(34),
	                              1: FlexColumnWidth(2.2),
	                              2: FlexColumnWidth(1),
	                              3: FlexColumnWidth(0.8),
	                              4: FlexColumnWidth(0.8),
	                              5: FlexColumnWidth(0.9),
	                            },
	                            children: [
	                              TableRow(
	                                decoration: const BoxDecoration(
	                                  color: Color(0xFFF3F3F3),
	                                ),
	                                children: [
	                                  _tableHeaderCell('#'),
	                                  _tableHeaderCell('Product'),
	                                  _tableHeaderCell('Code'),
	                                  _tableHeaderCell('SG'),
	                                  _tableHeaderCell('Conc'),
	                                  _tableHeaderCell('Unit'),
	                                ],
	                              ),
	                              ...selectedObmItems.asMap().entries.map((entry) {
	                                final index = entry.key;
	                                final e = entry.value;
	                                final rowCells = [
		                                  _tableCell((index + 1).toString()),
		                                  _readOnlyInventoryCell(e.product),
		                                  _readOnlyInventoryCell(e.code),
		                                  _readOnlyInventoryCell(e.sg),
		                                  _editableTableCell(
		                                    e.conc,
		                                    key: ValueKey('${e.id}-conc'),
		                                    onChanged: (v) {
		                                      e.conc = v;
		                                      _scheduleObmUpdate(e);
		                                    },
		                                  ),
		                                  _readOnlyInventoryCell(
		                                    _unitForObmItem(e),
		                                  ),
		                                ];

	                                return TableRow(
	                                  decoration: BoxDecoration(
	                                    color: index.isEven
	                                        ? Colors.white
	                                        : const Color(0xFFFBFBFB),
	                                  ),
	                                  children: _wrapMenuCells(
	                                    rowCells,
	                                    onEdit: c.isLocked.value
	                                        ? null
	                                        : () => _showObmEditDialog(e),
	                                    onDelete:
	                                        c.isLocked.value
	                                        ? null
	                                        : () => _deleteObmItem(e),
	                                  ),
	                                );
	                              }),
	                              ...List.generate(
	                                fillerRows,
	                                (_) => _emptyInventoryRow(columnCount: 6),
	                              ),
	                            ],
                              );
                            },
	                        ),
	                      ),
	                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= PREMIXED CRUD OPERATIONS =================

  Future<void> _addPremixedFromDraft({bool silent = false}) async {
    if (!_hasPremixedDraftData) return;
    if (wellId.isEmpty) {
      if (!silent && mounted) {
        _showToast('No well selected', isError: true);
      }
      return;
    }

    _premixedCreateTimer?.cancel();

    final draft = PremixModel(
      description: c.premixedDescController.text.trim(),
      mw: c.premixedMwController.text.trim(),
      leasingFee: c.premixedLeasingFeeController.text.trim(),
      mudType: c.premixedMudTypeController.text.trim(),
      tax: c.premixedTaxNew.value,
    );

    try {
      final created = await _repository.createPremixed(wellId, draft);
      c.premixed.add(created);
      c.premixed.refresh();
      if (_selectedPremixDescription.trim().isEmpty) {
        _selectPremixForObm(created.description);
      }
      c.premixedDescController.clear();
      c.premixedMwController.clear();
      c.premixedLeasingFeeController.clear();
      c.premixedMudTypeController.clear();
      c.premixedTaxNew.value = false;
      if (!silent && mounted) {
        _showToast('Premixed added successfully');
      }
    } catch (e) {
      if (mounted) {
        _showToast('Failed to save premixed', isError: true);
      }
    }
  }

  Future<void> _deletePremixed(String id) async {
    final confirm = await _showDeleteConfirmation('Premixed');
    if (!confirm) return;

    try {
      _premixedUpdateTimers[id]?.cancel();
      _premixedUpdateTimers.remove(id);
      await _repository.deletePremixed(id);
      c.premixed.removeWhere((item) => item.id == id);
      _showToast('Premixed deleted successfully');
    } catch (e) {
      _showToast('Failed to delete premixed', isError: true);
    }
  }

  Future<void> _deletePremixedItem(PremixModel premixed) async {
    final id = premixed.id?.trim() ?? '';
    if (id.isEmpty) {
      final confirm = await _showDeleteConfirmation('Premixed');
      if (!confirm) return;
      c.premixed.remove(premixed);
      c.premixed.refresh();
      _showToast('Premixed removed');
      return;
    }

    await _deletePremixed(id);
  }

  void _clearPremixedDraft() {
    _premixedCreateTimer?.cancel();
    c.premixedDescController.clear();
    c.premixedMwController.clear();
    c.premixedLeasingFeeController.clear();
    c.premixedMudTypeController.clear();
    c.premixedTaxNew.value = false;
    if (mounted) setState(() {});
    _showToast('Premixed draft cleared');
  }

  // ================= OBM CRUD OPERATIONS =================

  Future<void> _addObmFromDraft({bool silent = false}) async {
    if (!_hasObmDraftData) return;
    if (wellId.isEmpty) {
      if (!silent && mounted) {
        _showToast('No well selected', isError: true);
      }
      return;
    }

    _obmCreateTimer?.cancel();

	    final draft = ObmModel(
	      premixDescription: _selectedPremixDescription.trim(),
	      product: c.obmProductController.text.trim(),
	      code: c.obmCodeController.text.trim(),
      sg: c.obmSgController.text.trim(),
      conc: c.obmConcController.text.trim(),
      unit: c.obmUnitController.text.trim(),
    );

    try {
      final created = await _repository.createObm(wellId, draft);
      c.obm.add(
        created.copyWith(
          premixDescription: draft.premixDescription,
          unit: draft.unit,
        ),
      );
      c.obm.refresh();
      await _saveProductsInventorySnapshot();
      c.obmProductController.clear();
      c.obmCodeController.clear();
      c.obmSgController.clear();
      c.obmConcController.clear();
      c.obmUnitController.clear();
      if (!silent && mounted) {
        _showToast('8.0 ppg item added successfully');
      }
    } catch (e) {
      if (mounted) {
        _showToast('Failed to save 8.0 ppg item', isError: true);
      }
    }
  }

	  Future<void> _deleteObm(String id) async {
	    final confirm = await _showDeleteConfirmation('OBM');
	    if (!confirm) return;

    try {
      _obmUpdateTimers[id]?.cancel();
      _obmUpdateTimers.remove(id);
      await _repository.deleteObm(id);
      c.obm.removeWhere((item) => item.id == id);
      _showToast('OBM deleted successfully');
    } catch (e) {
      _showToast('Failed to delete OBM', isError: true);
	    }
	  }

  Future<void> _deleteObmItem(ObmModel item) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) {
      final confirm = await _showDeleteConfirmation('OBM');
      if (!confirm) return;
      c.obm.remove(item);
      c.obm.refresh();
      await _saveProductsInventorySnapshot();
      _showToast('OBM removed');
      return;
    }
    await _deleteObm(id);
    await _saveProductsInventorySnapshot();
  }

  Future<void> _showObmEditDialog(ObmModel item) async {
    final productController = TextEditingController(text: item.product);
    final codeController = TextEditingController(text: item.code);
    final sgController = TextEditingController(text: item.sg);
    final concController = TextEditingController(text: item.conc);
    final unitController = TextEditingController(text: item.unit);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Product'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Product', productController),
                const SizedBox(height: 10),
                _dialogField('Code', codeController),
                const SizedBox(height: 10),
                _dialogField('SG', sgController),
                const SizedBox(height: 10),
                _dialogField('Conc', concController),
                const SizedBox(height: 10),
                _dialogField('Unit', unitController),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              item.product = productController.text.trim();
              item.code = codeController.text.trim();
              item.sg = sgController.text.trim();
              item.conc = concController.text.trim();
              item.unit = unitController.text.trim();
              c.obm.refresh();
              Navigator.of(dialogContext).pop();
              _scheduleObmUpdate(item);
              await _saveProductsInventorySnapshot();
              _showToast('OBM updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    productController.dispose();
    codeController.dispose();
    sgController.dispose();
    concController.dispose();
    unitController.dispose();
  }

  Future<void> _openObmInventoryPickup() async {
    if (_isObmPickupOpening) return;
    setState(() => _isObmPickupOpening = true);

    ProductsPickupController? pickupController;
    if (Get.isRegistered<ProductsPickupController>(
      tag: 'products_pickup_controller',
    )) {
      pickupController = Get.find<ProductsPickupController>(
        tag: 'products_pickup_controller',
      );
      pickupController.selectedProductIndices.clear();
      pickupController.selectedProducts.clear();
    }

    try {
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              const InventoryPickupTabs(applyProductsToMainInventory: false),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isObmPickupOpening = false);
      } else {
        _isObmPickupOpening = false;
      }
    }
    if (!mounted) return;

    if (Get.isRegistered<ProductsPickupController>(
      tag: 'products_pickup_controller',
    )) {
      pickupController = Get.find<ProductsPickupController>(
        tag: 'products_pickup_controller',
      );
    }

    final pickedProducts = pickupController?.selectedProducts.toList() ?? [];

    if (pickedProducts.isEmpty) return;
    if (wellId.isEmpty) {
      _showToast('No well selected', isError: true);
      return;
    }

    for (final product in pickedProducts) {
      final name = product.product.trim();
      final code = product.code.trim();
      if (name.isEmpty && code.isEmpty) continue;

	      final exists = c.obm.any((item) {
	        return item.premixDescription.trim().toLowerCase() ==
	                _selectedPremixDescription.trim().toLowerCase() &&
	            item.product.trim().toLowerCase() == name.toLowerCase() &&
	            item.code.trim().toLowerCase() == code.toLowerCase();
	      });
      if (exists) continue;

	      final obm = ObmModel(
	        premixDescription: _selectedPremixDescription.trim(),
	        product: name,
	        code: code,
	        sg: product.sg.trim(),
        conc: '',
        unit: product.formattedUnit,
      );

      c.obm.add(obm);
    }

    c.obm.refresh();
    await _saveProductsInventorySnapshot();
  }

	  void _selectPremixForObm(String description) {
	    final title = description.trim();
	    if (title.isEmpty) {
	      if (_selectedPremixDescription.isEmpty) return;
	      setState(() => _selectedPremixDescription = '');
	      return;
	    }
	    if (_selectedPremixDescription == title) return;
	    setState(() => _selectedPremixDescription = title);
	  }

	  void _syncObmHeaderWithPremix() {
    final currentExists = c.premixed.any(
      (item) =>
          item.description.trim().isNotEmpty &&
          item.description.trim() == _selectedPremixDescription,
    );
    if (currentExists) return;

    final firstDescription = c.premixed
        .map((item) => item.description.trim())
        .firstWhere((description) => description.isNotEmpty, orElse: () => '');
	    _selectedPremixDescription = firstDescription;
	  }

  void _normalizeObmPremixLinks() {
    final premixDescriptions = c.premixed
        .map((item) => item.description.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (premixDescriptions.length != 1) return;
    final defaultDescription = premixDescriptions.first;
    if (defaultDescription.isEmpty) return;

    var changed = false;
    for (final item in c.obm) {
      if (item.premixDescription.trim().isEmpty) {
        item.premixDescription = defaultDescription;
        changed = true;
      }
    }
    if (changed) {
      c.obm.refresh();
      _scheduleProductsInventorySave();
    }
  }

  void _relinkObmToPremix(String oldDescription, String newDescription) {
    final oldKey = oldDescription.trim().toLowerCase();
    final newKey = newDescription.trim();
    if (oldKey.isEmpty || newKey.isEmpty || oldDescription.trim() == newKey) {
      return;
    }

    var changed = false;
    for (final item in c.obm) {
      if (item.premixDescription.trim().toLowerCase() == oldKey) {
        item.premixDescription = newKey;
        _scheduleObmUpdate(item);
        changed = true;
      }
    }
    if (changed) {
      c.obm.refresh();
      _scheduleProductsInventorySave();
    }
  }

  // ================= HELPERS =================

  Future<bool> _showDeleteConfirmation(String itemType) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete $itemType'),
            content: Text(
              'Are you sure you want to delete this $itemType item?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _headerText(String text, {double? size}) => Text(
    text,
    style: TextStyle(
      fontSize: size ?? 10,
      fontWeight: FontWeight.w700,
      color: AppTheme.textPrimary,
    ),
  );

  Widget _tableHeaderCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    child: Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    ),
  );

  Widget _tableHeaderCheckboxCell(
    String text,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Obx(() {
      final locked = c.isLocked.value;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 0.7,
            child: Checkbox(
              value: value,
              onChanged: locked ? null : (v) => onChanged(v ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _tableCell(String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    child: Text(
      value,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
    ),
  );

  Widget _readOnlyInventoryCell(String value) => Container(
    height: 28,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    color: const Color(0xFFFFF9CC).withOpacity(0.45),
    child: Text(
      value,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
    ),
  );

		  Widget _premixedMudTypeDropdown({
	    required String value,
	    required ValueChanged<String> onChanged,
	    VoidCallback? onTap,
	    bool allowBlank = false,
	  }) {
    const options = ['Water-based', 'Oil-based', 'Synthetic'];
    final cleanValue = value.trim();
    final currentValue = allowBlank && cleanValue.isEmpty
        ? ''
        : options.contains(cleanValue)
        ? cleanValue
        : (mudController?.selectedFluidType.value.trim().isNotEmpty == true
              ? mudController!.selectedFluidType.value
              : options.first);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFFFF9CC),
      child: DropdownButtonHideUnderline(
	        child: DropdownButton<String>(
	          value: options.contains(currentValue)
	              ? currentValue
	              : (allowBlank ? null : options.first),
            onTap: onTap,
	          isExpanded: true,
          hint: const SizedBox.shrink(),
          iconSize: 16,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: c.isLocked.value
              ? null
              : (selected) {
                  if (selected != null) onChanged(selected);
                },
        ),
      ),
	    );
	  }

	  Widget _premixedDraftMudTypeCell() {
	    return AnimatedBuilder(
	      animation: Listenable.merge([
	        c.premixedDescController,
	        c.premixedMwController,
	        c.premixedLeasingFeeController,
	        c.premixedMudTypeController,
	      ]),
	      builder: (context, _) {
	        return Obx(() {
	          final hasDraftData =
	              c.premixedDescController.text.trim().isNotEmpty ||
	              c.premixedMwController.text.trim().isNotEmpty ||
	              c.premixedLeasingFeeController.text.trim().isNotEmpty ||
	              c.premixedMudTypeController.text.trim().isNotEmpty ||
	              c.premixedTaxNew.value;

	          if (!hasDraftData) {
	            return const SizedBox(height: 28);
	          }

	          return _premixedMudTypeDropdown(
	            value: c.premixedMudTypeController.text,
	            allowBlank: true,
	            onChanged: (v) {
	              c.premixedMudTypeController.text = v;
	              setState(() {});
	              _schedulePremixedDraftSave();
	            },
	          );
	        });
	      },
	    );
	  }

	  Widget _editableTableCell(
    String value, {
    Function(String)? onChanged,
    VoidCallback? onTap,
    Key? key,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    child: c.isLocked.value
        ? Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          )
        : _InventoryEditableTextCell(
            key: key,
            value: value,
            onChanged: onChanged,
            onTap: onTap,
          ),
  );

  Widget _checkboxCell(bool Function() getter, Function(bool) onChange) {
    return Obx(() {
      final locked = c.isLocked.value;
      final checked = getter();
      return Center(
        child: Container(
          decoration: BoxDecoration(
            color: checked
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.tableHeaderBlue,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: checked ? AppTheme.successColor : Colors.grey.shade400,
            ),
          ),
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Transform.scale(
            scale: 0.7,
            child: Checkbox(
              value: checked,
              onChanged: locked ? null : (v) => onChange(v!),
              activeColor: AppTheme.successColor,
              checkColor: Colors.white,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      );
    });
  }
}

enum _ProductInventoryAction { add, edit, delete }

class _InventoryMenuItem extends StatelessWidget {
  const _InventoryMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppTheme.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 16, color: itemColor),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 11, color: itemColor)),
      ],
    );
  }
}

class _InventoryEditableTextCell extends StatefulWidget {
  const _InventoryEditableTextCell({
    super.key,
    required this.value,
    this.onChanged,
    this.onTap,
  });

  final String value;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  @override
  State<_InventoryEditableTextCell> createState() =>
      _InventoryEditableTextCellState();
}

class _InventoryEditableTextCellState
    extends State<_InventoryEditableTextCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _InventoryEditableTextCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        border: InputBorder.none,
      ),
    );
  }
}

Map<String, String> _splitInventoryUnit(String rawUnit) {
  final clean = rawUnit.trim();
  if (clean.isEmpty) {
    return {'num': '', 'class': ''};
  }

  final match = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*(.*)$').firstMatch(clean);
  if (match == null) {
    return {'num': '', 'class': clean};
  }

  return {
    'num': match.group(1)?.trim() ?? '',
    'class': match.group(2)?.trim() ?? '',
  };
}
