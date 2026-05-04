import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/model/ug_inventory_product_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
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
  final _repository = AuthRepository();
  final padWellC = padWellContext;
  static const int _minDisplayRows = 5;

  String get wellId => padWellC.selectedWellId.value;

  bool _isLoading = false;
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

  bool get _hasObmDraftData {
    return c.obmProductController.text.trim().isNotEmpty &&
        (c.obmCodeController.text.trim().isNotEmpty ||
            c.obmSgController.text.trim().isNotEmpty ||
            c.obmConcController.text.trim().isNotEmpty ||
            c.obmUnitController.text.trim().isNotEmpty);
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
    if (id.isEmpty || c.isLocked.value) return;
    _obmUpdateTimers[id]?.cancel();
    _obmUpdateTimers[id] = Timer(const Duration(milliseconds: 800), () async {
      try {
        final updated = await _repository.updateObm(id, obm);
        final index = c.obm.indexWhere((item) => item.id == id);
        if (index != -1) {
          c.obm[index] = updated;
          c.obm.refresh();
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
    Future<void> Function()? onAdd,
  }) {
    if (onDelete == null && onAdd == null) {
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
    Future<void> Function()? onAdd,
  }) {
    return cells
        .map(
          (cell) => _withRowMenu(child: cell, onDelete: onDelete, onAdd: onAdd),
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
            fontSize: 11,
            fontWeight: FontWeight.w500,
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
        style: const TextStyle(fontSize: 10, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
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
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // ================= MAIN PRODUCTS TABLE =================
          Expanded(flex: 3, child: _buildProductsTable(store)),

          const SizedBox(height: 8),

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
                      const SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
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
                Icon(Icons.inventory, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Products Inventory',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Obx(
                    () => Text(
                      '${store.selectedProducts.length} items',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

              return Scrollbar(
                controller: _mainVerticalScroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _mainHorizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _mainVerticalScroll,
                    child: Table(
                      border: TableBorder.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(40),
                        1: FixedColumnWidth(250),
                        2: FixedColumnWidth(140),
                        3: FixedColumnWidth(100),
                        4: FixedColumnWidth(100),
                        5: FixedColumnWidth(100),
                        6: FixedColumnWidth(100),
                        7: FixedColumnWidth(140),
                        8: FixedColumnWidth(80),
                        9: FixedColumnWidth(140),
                        10: FixedColumnWidth(80),
                      },
                      children: [
                        // Header Row
                        TableRow(
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
                          children: [
                            _tableHeaderCell('No'),
                            _tableHeaderCell('Product'),
                            _tableHeaderCell('Code'),
                            _tableHeaderCell('SG'),
                            _tableHeaderCell('Unit'),
                            _tableHeaderCell('Price'),
                            _tableHeaderCell('Initial'),
                            _tableHeaderCell('Group'),
                            _tableHeaderCell('Vol. Add'),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _headerText('Concentration'),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: _headerText(
                                            'Calculate',
                                            size: 9,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: _headerText('Plot', size: 9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _tableHeaderCell('Tax'),
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
                              key: ValueKey('product-${_productRowKey(p, index)}-code'),
                              onChanged: (v) {
                                p.code = v;
                                _scheduleProductsInventorySave();
                              },
                            ),
                            _editableTableCell(
                              p.sg,
                              key: ValueKey('product-${_productRowKey(p, index)}-sg'),
                              onChanged: (v) {
                                p.sg = v;
                                _scheduleProductsInventorySave();
                              },
                            ),
                            _tableCell(p.formattedUnit),
                            _editableTableCell(
                              p.a.isNotEmpty ? p.a : p.price,
                              key: ValueKey('product-${_productRowKey(p, index)}-price'),
                              onChanged: (v) {
                                p.a = v;
                                p.price = v;
                                _scheduleProductsInventorySave();
                              },
                            ),
                            _editableTableCell(
                              p.initial,
                              key: ValueKey('product-${_productRowKey(p, index)}-initial'),
                              onChanged: (v) {
                                p.initial = v;
                                _scheduleProductsInventorySave();
                              },
                            ),
                            _editableTableCell(
                              p.group,
                              key: ValueKey('product-${_productRowKey(p, index)}-group'),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 1,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _checkboxCell(() => p.calculate, (
                                      v,
                                    ) {
                                      p.calculate = v;
                                      store.selectedProducts.refresh();
                                      _scheduleProductsInventorySave();
                                    }),
                                  ),
                                  Expanded(
                                    child: _checkboxCell(() => p.plot, (v) {
                                      p.plot = v;
                                      store.selectedProducts.refresh();
                                      _scheduleProductsInventorySave();
                                    }),
                                  ),
                                ],
                              ),
                            ),
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
        style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
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
  }
  ) async {
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
                    final hasDraftData = productController.text.trim().isNotEmpty ||
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
    final fillerRows = _minDisplayRows > c.premixed.length + 1
        ? _minDisplayRows - (c.premixed.length + 1)
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC9CDD3)),
      ),
      child: Column(
        children: [
          _inventorySectionTitle('Pre-mixed Mud'),
          Expanded(
            child: Scrollbar(
              controller: _premixedVerticalScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _premixedHorizontalScroll,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _premixedVerticalScroll,
                  child: Obx(
                    () => Table(
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(40),
                        1: FixedColumnWidth(180),
                        2: FixedColumnWidth(80),
                        3: FixedColumnWidth(110),
                        4: FixedColumnWidth(100),
                        5: FixedColumnWidth(60),
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
                        ...c.premixed.asMap().entries.map((entry) {
                          final index = entry.key;
                          final e = entry.value;
                          final rowCells = [
                            _tableCell((index + 1).toString()),
                            _editableTableCell(
                              e.description,
                              key: ValueKey('${e.id}-description'),
                              onChanged: (v) {
                                e.description = v;
                                _schedulePremixedUpdate(e);
                              },
                            ),
                            _editableTableCell(
                              e.mw,
                              key: ValueKey('${e.id}-mw'),
                              onChanged: (v) {
                                e.mw = v;
                                _schedulePremixedUpdate(e);
                              },
                            ),
                            _editableTableCell(
                              e.leasingFee,
                              key: ValueKey('${e.id}-leasingFee'),
                              onChanged: (v) {
                                e.leasingFee = v;
                                _schedulePremixedUpdate(e);
                              },
                            ),
                            _editableTableCell(
                              e.mudType,
                              key: ValueKey('${e.id}-mudType'),
                              onChanged: (v) {
                                e.mudType = v;
                                _schedulePremixedUpdate(e);
                              },
                            ),
                            _checkboxCell(() => e.tax, (v) {
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
                              onDelete:
                                  c.isLocked.value || (e.id?.isEmpty ?? true)
                                  ? null
                                  : () => _deletePremixed(e.id!),
                            ),
                          );
                        }),
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAFAFA),
                          ),
                          children: _wrapMenuCells(
                            [
                              _tableCell('${c.premixed.length + 1}'),
                              _inventoryDraftCell(
                                controller: c.premixedDescController,
                                hint: '',
                                onChanged: (_) => _schedulePremixedDraftSave(),
                              ),
                              _inventoryDraftCell(
                                controller: c.premixedMwController,
                                hint: '',
                                onChanged: (_) => _schedulePremixedDraftSave(),
                              ),
                              _inventoryDraftCell(
                                controller: c.premixedLeasingFeeController,
                                hint: '',
                                onChanged: (_) => _schedulePremixedDraftSave(),
                              ),
                              _inventoryDraftCell(
                                controller: c.premixedMudTypeController,
                                hint: '',
                                onChanged: (_) => _schedulePremixedDraftSave(),
                              ),
                              Obx(
                                () => _checkboxCell(
                                  () => c.premixedTaxNew.value,
                                  (v) {
                                    c.premixedTaxNew.value = v;
                                    _schedulePremixedDraftSave();
                                  },
                                ),
                              ),
                            ],
                            onAdd: c.isLocked.value
                                ? null
                                : () => _addPremixedFromDraft(),
                          ),
                        ),
                        ...List.generate(
                          fillerRows,
                          (_) => _emptyInventoryRow(columnCount: 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= OBM TABLE =================
  Widget _obmTable() {
    final fillerRows = _minDisplayRows > c.obm.length + 1
        ? _minDisplayRows - (c.obm.length + 1)
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC9CDD3)),
      ),
      child: Column(
        children: [
          _inventorySectionTitle('8.0 ppg'),
          Expanded(
            child: Scrollbar(
              controller: _obmVerticalScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _obmHorizontalScroll,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _obmVerticalScroll,
                  child: Obx(
                    () => Table(
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(40),
                        1: FixedColumnWidth(180),
                        2: FixedColumnWidth(100),
                        3: FixedColumnWidth(80),
                        4: FixedColumnWidth(80),
                        5: FixedColumnWidth(80),
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
                        ...c.obm.asMap().entries.map((entry) {
                          final index = entry.key;
                          final e = entry.value;
                          final rowCells = [
                            _tableCell((index + 1).toString()),
                            _editableTableCell(
                              e.product,
                              key: ValueKey('${e.id}-product'),
                              onChanged: (v) {
                                e.product = v;
                                _scheduleObmUpdate(e);
                              },
                            ),
                            _editableTableCell(
                              e.code,
                              key: ValueKey('${e.id}-code'),
                              onChanged: (v) {
                                e.code = v;
                                _scheduleObmUpdate(e);
                              },
                            ),
                            _editableTableCell(
                              e.sg,
                              key: ValueKey('${e.id}-sg'),
                              onChanged: (v) {
                                e.sg = v;
                                _scheduleObmUpdate(e);
                              },
                            ),
                            _editableTableCell(
                              e.conc,
                              key: ValueKey('${e.id}-conc'),
                              onChanged: (v) {
                                e.conc = v;
                                _scheduleObmUpdate(e);
                              },
                            ),
                            _editableTableCell(
                              e.unit,
                              key: ValueKey('${e.id}-unit'),
                              onChanged: (v) {
                                e.unit = v;
                                _scheduleObmUpdate(e);
                              },
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
                              onDelete:
                                  c.isLocked.value || (e.id?.isEmpty ?? true)
                                  ? null
                                  : () => _deleteObm(e.id!),
                            ),
                          );
                        }),
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAFAFA),
                          ),
                          children: _wrapMenuCells(
                            [
                              _tableCell('${c.obm.length + 1}'),
                              _inventoryDraftCell(
                                controller: c.obmProductController,
                                hint: '',
                                onChanged: (_) => _scheduleObmDraftSave(),
                              ),
                              _inventoryDraftCell(
                                controller: c.obmCodeController,
                                hint: '',
                                onChanged: (_) => _scheduleObmDraftSave(),
                              ),
                              _inventoryDraftCell(
                                controller: c.obmSgController,
                                hint: '',
                                onChanged: (_) => _scheduleObmDraftSave(),
                              ),
                              _inventoryDraftCell(
                                controller: c.obmConcController,
                                hint: '',
                                onChanged: (_) => _scheduleObmDraftSave(),
                              ),
                              _inventoryDraftCell(
                                controller: c.obmUnitController,
                                hint: '',
                                onChanged: (_) => _scheduleObmDraftSave(),
                              ),
                            ],
                            onAdd: c.isLocked.value
                                ? null
                                : () => _addObmFromDraft(),
                          ),
                        ),
                        ...List.generate(
                          fillerRows,
                          (_) => _emptyInventoryRow(columnCount: 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
      product: c.obmProductController.text.trim(),
      code: c.obmCodeController.text.trim(),
      sg: c.obmSgController.text.trim(),
      conc: c.obmConcController.text.trim(),
      unit: c.obmUnitController.text.trim(),
    );

    try {
      final created = await _repository.createObm(wellId, draft);
      c.obm.add(created);
      c.obm.refresh();
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
      fontSize: size ?? 9,
      fontWeight: FontWeight.w600,
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
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    ),
  );

  Widget _tableCell(String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    child: Text(
      value,
      style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
    ),
  );

  Widget _editableTableCell(
    String value, {
    Function(String)? onChanged,
    Key? key,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    child: c.isLocked.value
        ? Text(
            value,
            style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
          )
        : _InventoryEditableTextCell(
            key: key,
            value: value,
            onChanged: onChanged,
          ),
  );

  Widget _checkboxCell(bool Function() getter, Function(bool) onChange) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: getter()
              ? AppTheme.successColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: getter() ? AppTheme.successColor : Colors.grey.shade400,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Transform.scale(
          scale: 0.7,
          child: Checkbox(
            value: getter(),
            onChanged: c.isLocked.value ? null : (v) => onChange(v!),
            activeColor: AppTheme.successColor,
            checkColor: Colors.white,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
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
  });

  final String value;
  final ValueChanged<String>? onChanged;

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
      onChanged: widget.onChanged,
      style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
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
