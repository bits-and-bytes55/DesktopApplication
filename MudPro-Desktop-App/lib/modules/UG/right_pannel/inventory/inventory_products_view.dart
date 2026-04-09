import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';

class InventoryProductsView extends StatefulWidget {
  const InventoryProductsView({super.key});

  @override
  State<InventoryProductsView> createState() => _InventoryProductsViewState();
}

class _InventoryProductsViewState extends State<InventoryProductsView> {
  final c = Get.find<UgController>();
  final dashCtrl = Get.find<DashboardController>();
  final _repository = AuthRepository();
  
  // Use a hardcoded wellId for now - replace with actual well ID from your auth
  String get wellId => '507f1f77bcf86cd799439011'; // Replace with actual wellId
  
  bool _isLoading = false;

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

  void _clearPremixedControllers() {
    _premixedControllers.values.forEach((controller) => controller.clear());
  }

  void _clearObmControllers() {
    _obmControllers.values.forEach((controller) => controller.clear());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
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
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
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
          Expanded(
            flex: 3,
            child: _buildProductsTable(store),
          ),

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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Obx(() => Text(
                    '${store.selectedProducts.length} items',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final productsToDisplay = store.selectedProducts;

              if (productsToDisplay.isEmpty) {
                return Center(
                  child: Text(
                    'No products selected',
                    style: TextStyle(color: Colors.grey),
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
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
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
                                AppTheme.primaryColor.withOpacity(0.05)
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _headerText('Concentration'),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                          child: Center(child: _headerText('Calculate', size: 9))),
                                      Expanded(child: Center(child: _headerText('Plot', size: 9))),
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
                          return TableRow(
                            decoration: BoxDecoration(
                              color: index.isEven ? Colors.white : AppTheme.cardColor,
                            ),
                            children: [
                              _tableCell((index + 1).toString()),
                              _editableTableCell(p.product, onChanged: (v) {
                                p.product = v;
                                store.selectedProducts.refresh();
                              }),
                              _editableTableCell(p.code, onChanged: (v) {
                                p.code = v;
                                store.selectedProducts.refresh();
                              }),
                              _editableTableCell(p.sg, onChanged: (v) {
                                p.sg = v;
                                store.selectedProducts.refresh();
                              }),
                              _tableCell(p.formattedUnit),
                              _editableTableCell(p.a, onChanged: (v) {
                                p.a = v;
                                store.selectedProducts.refresh();
                              }),
                              _editableTableCell(p.initial, onChanged: (v) {
                                p.initial = v;
                                store.selectedProducts.refresh();
                              }),
                              _editableTableCell(p.group, onChanged: (v) {
                                p.group = v;
                                store.selectedProducts.refresh();
                              }),
                              _checkboxCell(() => p.volAdd, (v) {
                                p.volAdd = v;
                                store.selectedProducts.refresh();
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: _checkboxCell(() => p.calculate, (v) {
                                        p.calculate = v;
                                        store.selectedProducts.refresh();
                                      }),
                                    ),
                                    Expanded(
                                      child: _checkboxCell(() => p.plot ?? false, (v) {
                                        p.plot = v;
                                        store.selectedProducts.refresh();
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              _checkboxCell(() => p.tax, (v) {
                                p.tax = v;
                                store.selectedProducts.refresh();
                              }),
                            ],
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

  // ================= PREMIXED MUD TABLE =================
  Widget _premixedMudTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
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
                Icon(Icons.macro_off, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Premixed Mud',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${c.premixed.length} items',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _premixedVerticalScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _premixedHorizontalScroll,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _premixedVerticalScroll,
                  child: Obx(() => Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(40),
                      1: FixedColumnWidth(180),
                      2: FixedColumnWidth(80),
                      3: FixedColumnWidth(100),
                      4: FixedColumnWidth(100),
                      5: FixedColumnWidth(60),
                      6: FixedColumnWidth(90),
                    },
                    children: [
                      // Header Row
                      TableRow(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.1),
                              AppTheme.primaryColor.withOpacity(0.05)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        children: [
                          _tableHeaderCell('#'),
                          _tableHeaderCell('Description'),
                          _tableHeaderCell('MW'),
                          _tableHeaderCell('Leasing Fee'),
                          _tableHeaderCell('Mud Type'),
                          _tableHeaderCell('Tax'),
                          _tableHeaderCell('Actions'),
                        ],
                      ),
                      // Data Rows
                      ...c.premixed.asMap().entries.map((entry) {
                        final index = entry.key;
                        final e = entry.value;
                        return TableRow(
                          decoration: BoxDecoration(
                            color: index.isEven ? Colors.white : AppTheme.cardColor,
                          ),
                          children: [
                            _tableCell((index + 1).toString()),
                            _editableTableCell(e.description, key: ValueKey(e.id ?? e.description), onChanged: (v) {
                              e.description = v;
                              c.premixed.refresh();
                            }),
                            _editableTableCell(e.mw, key: ValueKey(e.id ?? e.mw), onChanged: (v) {
                              e.mw = v;
                              c.premixed.refresh();
                            }),
                            _editableTableCell(e.leasingFee, key: ValueKey(e.id ?? e.leasingFee), onChanged: (v) {
                              e.leasingFee = v;
                              c.premixed.refresh();
                            }),
                            _editableTableCell(e.mudType, key: ValueKey(e.id ?? e.mudType), onChanged: (v) {
                              e.mudType = v;
                              c.premixed.refresh();
                            }),
                            _checkboxCell(() => e.tax, (v) {
                              e.tax = v;
                              c.premixed.refresh();
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.save, size: 14, color: Colors.blue),
                                    onPressed: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : () => _updatePremixed(e),
                                    tooltip: 'Update',
                                    padding: EdgeInsets.all(2),
                                    constraints: BoxConstraints(),
                                  ),
                                  SizedBox(width: 2),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 14, color: Colors.red),
                                    onPressed: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : () => _deletePremixed(e.id!),
                                    tooltip: 'Delete',
                                    padding: EdgeInsets.all(2),
                                    constraints: BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                      // Empty row for adding new data
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(Icons.add, size: 14, color: Colors.green),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: TextFormField(
                              controller: c.premixedDescController,
                              readOnly: dashCtrl.isLocked.value,
                              onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Enter description...',
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: TextFormField(
                              controller: c.premixedMwController,
                              readOnly: dashCtrl.isLocked.value,
                              onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'MW...',
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: TextFormField(
                              controller: c.premixedLeasingFeeController,
                              readOnly: dashCtrl.isLocked.value,
                              onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Fee...',
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: TextFormField(
                              controller: c.premixedMudTypeController,
                              readOnly: dashCtrl.isLocked.value,
                              onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Type...',
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Obx(() => _checkboxCell(() => c.premixedTaxNew.value, (v) {
                            c.premixedTaxNew.value = v;
                          })),
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.green, size: 18),
                              onPressed: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : _addPremixedFromEmptyRow,
                              tooltip: 'Add',
                              padding: EdgeInsets.all(2),
                              constraints: BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
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
                Icon(Icons.oil_barrel, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '8.0 ppg OBM (70/30) with Bar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${c.obm.length} items',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _obmVerticalScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _obmHorizontalScroll,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _obmVerticalScroll,
                  child: Obx(() => Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(40),
                      1: FixedColumnWidth(180),
                      2: FixedColumnWidth(100),
                      3: FixedColumnWidth(80),
                      4: FixedColumnWidth(80),
                      5: FixedColumnWidth(80),
                      6: FixedColumnWidth(90),
                    },
                    children: [
                      // Header Row
                      TableRow(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.1),
                              AppTheme.primaryColor.withOpacity(0.05)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        children: [
                          _tableHeaderCell('#'),
                          _tableHeaderCell('Product'),
                          _tableHeaderCell('Code'),
                          _tableHeaderCell('SG'),
                          _tableHeaderCell('Conc'),
                          _tableHeaderCell('Unit'),
                          _tableHeaderCell('Actions'),
                        ],
                      ),
                      // Data Rows
                      ...c.obm.asMap().entries.map((entry) {
                        final index = entry.key;
                        final e = entry.value;
                        return TableRow(
                          decoration: BoxDecoration(
                            color: index.isEven ? Colors.white : AppTheme.cardColor,
                          ),
                          children: [
                            _tableCell((index + 1).toString()),
                            _editableTableCell(e.product, key: ValueKey(e.id ?? e.product), onChanged: (v) {
                              e.product = v;
                              c.obm.refresh();
                            }),
                            _editableTableCell(e.code, key: ValueKey(e.id ?? e.code), onChanged: (v) {
                              e.code = v;
                              c.obm.refresh();
                            }),
                            _editableTableCell(e.sg, key: ValueKey(e.id ?? e.sg), onChanged: (v) {
                              e.sg = v;
                              c.obm.refresh();
                            }),
                            _editableTableCell(e.conc, key: ValueKey(e.id ?? e.conc), onChanged: (v) {
                              e.conc = v;
                              c.obm.refresh();
                            }),
                            _editableTableCell(e.unit, key: ValueKey(e.id ?? e.unit), onChanged: (v) {
                              e.unit = v;
                              c.obm.refresh();
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.save, size: 14, color: Colors.blue),
                                    onPressed: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : () => _updateObm(e),
                                    tooltip: 'Update',
                                    padding: EdgeInsets.all(2),
                                    constraints: BoxConstraints(),
                                  ),
                                  SizedBox(width: 2),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 14, color: Colors.red),
                                    onPressed: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : () => _deleteObm(e.id!),
                                    tooltip: 'Delete',
                                    padding: EdgeInsets.all(2),
                                    constraints: BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                      // Empty row for adding new data
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(Icons.add, size: 14, color: Colors.green),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: TextFormField(
                              controller: c.obmProductController,
                              readOnly: dashCtrl.isLocked.value,
                              onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Enter product...',
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: TextFormField(
                              controller: c.obmCodeController,
                              readOnly: dashCtrl.isLocked.value,
                              onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Code...',
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: TextFormField(
                              controller: c.obmSgController,
                              readOnly: dashCtrl.isLocked.value,
                              onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'SG...',
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: TextFormField(
                              controller: c.obmConcController,
                              readOnly: dashCtrl.isLocked.value,
                              onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Conc...',
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            child: TextFormField(
                              controller: c.obmUnitController,
                              readOnly: dashCtrl.isLocked.value,
                              onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
                              style: TextStyle(fontSize: 10, color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: 'Unit...',
                                hintStyle: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.green, size: 18),
                              onPressed: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : _addObmFromEmptyRow,
                              tooltip: 'Add',
                              padding: EdgeInsets.all(2),
                              constraints: BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= PREMIXED CRUD OPERATIONS =================

  Future<void> _addPremixedFromEmptyRow() async {
    final res = await c.saveInventory();
    if (res['success'] == true) {
      if (res['message'] != 'No changes to save') {
        _showToast(res['message']);
      }
    } else {
      _showToast(res['message'], isError: true);
    }
  }

  Future<void> _updatePremixed(PremixModel premixed) async {
    if (premixed.id == null || premixed.id!.isEmpty) {
      _showToast('Invalid premixed ID', isError: true);
      return;
    }

    try {
      await _repository.updatePremixed(premixed.id!, premixed);
      c.premixed.refresh();
      _showToast('Premixed updated successfully');
    } catch (e) {
      _showToast('Failed to update premixed', isError: true);
    }
  }

  Future<void> _deletePremixed(String id) async {
    final confirm = await _showDeleteConfirmation('Premixed');
    if (!confirm) return;

    try {
      await _repository.deletePremixed(id);
      c.premixed.removeWhere((item) => item.id == id);
      _showToast('Premixed deleted successfully');
    } catch (e) {
      _showToast('Failed to delete premixed', isError: true);
    }
  }

  // ================= OBM CRUD OPERATIONS =================

  Future<void> _addObmFromEmptyRow() async {
    final res = await c.saveInventory();
    if (res['success'] == true) {
      if (res['message'] != 'No changes to save') {
        _showToast(res['message']);
      }
    } else {
      _showToast(res['message'], isError: true);
    }
  }

  Future<void> _updateObm(ObmModel obm) async {
    if (obm.id == null || obm.id!.isEmpty) {
      _showToast('Invalid OBM ID', isError: true);
      return;
    }

    try {
      await _repository.updateObm(obm.id!, obm);
      c.obm.refresh();
      _showToast('OBM updated successfully');
    } catch (e) {
      _showToast('Failed to update OBM', isError: true);
    }
  }

  Future<void> _deleteObm(String id) async {
    final confirm = await _showDeleteConfirmation('OBM');
    if (!confirm) return;

    try {
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
            content: Text('Are you sure you want to delete this $itemType item?'),
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
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      );
  Widget _tableCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _editableTableCell(String val, {Key? key, required void Function(String) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Obx(() => dashCtrl.isLocked.value
          ? GestureDetector(
              onTap: () => dashCtrl.showLockedPopup(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(val,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
              ),
            )
          : TextFormField(
              key: key ?? ValueKey(val),
              initialValue: val,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 9, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                border: InputBorder.none,
              ),
              textAlign: TextAlign.center,
            )),
    );
  }

  Widget _checkboxCell(bool Function() getValue, void Function(bool) onChanged) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: getValue()
              ? AppTheme.successColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: getValue() ? AppTheme.successColor : Colors.grey.shade400,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Obx(() {
          final val = getValue();
          return GestureDetector(
            onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(
              absorbing: dashCtrl.isLocked.value,
              child: Transform.scale(
                scale: 0.7,
                child: Checkbox(
                  value: val,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: AppTheme.successColor,
                  checkColor: Colors.white,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
