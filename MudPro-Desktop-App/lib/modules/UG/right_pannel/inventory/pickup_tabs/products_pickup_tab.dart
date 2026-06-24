import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/product_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ProductsPickupPage extends StatefulWidget {
  const ProductsPickupPage({super.key, this.applyToMainInventory = true});

  final bool applyToMainInventory;

  @override
  State<ProductsPickupPage> createState() => _ProductsPickupPageState();
}

class _ProductsPickupPageState extends State<ProductsPickupPage> {
  static const double _numberWidth = 44;
  static const double _selectWidth = 42;
  static const double _productWidth = 250;
  static const double _codeWidth = 220;
  static const double _sgWidth = 78;
  static const double _qtyWidth = 120;
  static const double _unitWidth = 86;
  static const double _groupWidth = 120;
  static const double _retailWidth = 110;
  static const double _priceAWidth = 98;

  late final ProductsPickupController controller;
  String _selectedPriceSchedule = 'Retail';

  double get _tableWidth =>
      _numberWidth +
      _selectWidth +
      _productWidth +
      _codeWidth +
      _sgWidth +
      _qtyWidth +
      _unitWidth +
      _groupWidth +
      _retailWidth +
      _priceAWidth;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ProductsPickupController>(
          tag: 'products_pickup_controller',
        )
        ? Get.find<ProductsPickupController>(tag: 'products_pickup_controller')
        : Get.put(
            ProductsPickupController(),
            tag: 'products_pickup_controller',
          );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isLoading.value) {
        controller.loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Container(
        color: AppTheme.backgroundColor,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            const SizedBox(height: 6),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.max(_tableWidth, constraints.maxWidth);
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFC8C8C8)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: width,
                        height: constraints.maxHeight,
                        child: Column(
                          children: [
                            _buildHeader(width),
                            Expanded(child: _buildBody()),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildFooter(),
          ],
        ),
      );
    });
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
            child: Row(
        children: [
          const Text(
            'Product',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          (() {
            final existingEntries = controller.products
                .asMap()
                .entries
                .where((entry) => controller.isExistingProduct(entry.key))
                .toList();
            final allExistingSelected = existingEntries.isNotEmpty &&
                existingEntries.every(
                  (entry) => controller.selectedProductIndices.contains(entry.key),
                );
            return _selectAllBox(
              checked: allExistingSelected,
              tooltip: allExistingSelected ? 'Clear all products' : 'Select all products',
              onTap: () {
              if (allExistingSelected) {
                controller.clearProductSelection();
              } else {
                controller.selectAllExistingProducts();
              }
            },
            );
          })(),
          const Spacer(),
          const Text(
            'Price Schedule',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 28,
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPriceSchedule,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, size: 18),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                ),
                items: const [
                  DropdownMenuItem(value: 'Retail', child: Text('Retail')),
                  DropdownMenuItem(value: 'A', child: Text('A')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedPriceSchedule = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: controller.isSaving.value ? null : controller.saveProducts,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 28),
            ),
            child: controller.isSaving.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save New',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double width) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFD1D5DB)),
        ),
      ),
      child: Row(
        children: [
          _headerCell('', _numberWidth),
          _headerCell('', _selectWidth),
          _headerCell('Product', _productWidth),
          _headerCell('Code', _codeWidth),
          _headerCell('SG', _sgWidth),
          _headerCell('Qty', _qtyWidth),
          _headerCell('Unit', _unitWidth),
          _headerCell('Group', _groupWidth),
          _headerCell('Retail', _retailWidth),
          _headerCell('A', _priceAWidth),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        itemCount: controller.products.length,
        itemBuilder: (context, index) {
          final product = controller.products[index];
          final isExisting = controller.isExistingProduct(index);
          final isSelected = controller.isProductSelected(index);

          return InkWell(
            onTap: isExisting ? () => controller.toggleProductSelection(index) : null,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: isExisting
                    ? (isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : const Color(0xffF3F4F6))
                    : (index.isEven ? AppTheme.cardColor : Colors.white),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 0.6,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _rowNumberCell(index + 1),
                  _selectionCell(index, isExisting, isSelected),
                  _dataCell(
                    width: _productWidth,
                    child: _cellContent(
                      value: product.product,
                      onChanged: (value) => _updateField(index, 'product', value),
                      isExisting: isExisting,
                      align: TextAlign.left,
                    ),
                  ),
                  _dataCell(
                    width: _codeWidth,
                    child: _cellContent(
                      value: product.code,
                      onChanged: (value) => _updateField(index, 'code', value),
                      isExisting: isExisting,
                      align: TextAlign.left,
                    ),
                  ),
                  _dataCell(
                    width: _sgWidth,
                    child: _cellContent(
                      value: product.sg,
                      onChanged: (value) => _updateField(index, 'sg', value),
                      isExisting: isExisting,
                      align: TextAlign.right,
                      isNumeric: true,
                    ),
                  ),
                  _dataCell(
                    width: _qtyWidth,
                    child: _cellContent(
                      value: product.unitNum,
                      onChanged: (value) => _updateField(index, 'unitNum', value),
                      isExisting: isExisting,
                      align: TextAlign.right,
                      isNumeric: true,
                    ),
                  ),
                  _dataCell(
                    width: _unitWidth,
                    child: _cellContent(
                      value: product.unitClass,
                      onChanged: (value) => _updateField(index, 'unitClass', value),
                      isExisting: isExisting,
                      align: TextAlign.left,
                    ),
                  ),
                  _dataCell(
                    width: _groupWidth,
                    child: _cellContent(
                      value: product.group,
                      onChanged: (value) => _updateField(index, 'group', value),
                      isExisting: isExisting,
                      align: TextAlign.left,
                    ),
                  ),
                  _dataCell(
                    width: _retailWidth,
                    child: _cellContent(
                      value: product.retail,
                      onChanged: (value) => _updateField(index, 'retail', value),
                      isExisting: isExisting,
                      align: TextAlign.right,
                    ),
                  ),
                  _dataCell(
                    width: _priceAWidth,
                    child: _cellContent(
                      value: product.a,
                      onChanged: (value) => _updateField(index, 'a', value),
                      isExisting: isExisting,
                      align: TextAlign.right,
                      isNumeric: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rowNumberCell(int rowNo) {
    return Container(
      width: _numberWidth,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 8),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
        ),
      ),
      child: Text(
        '$rowNo',
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF4C4C4C),
        ),
      ),
    );
  }

  Widget _selectionCell(int index, bool isExisting, bool isSelected) {
    return Container(
      width: _selectWidth,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
        ),
      ),
      child: isExisting
          ? SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: isSelected,
                activeColor: AppTheme.primaryColor,
                side: BorderSide(color: Colors.grey.shade400),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) => controller.toggleProductSelection(index),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _dataCell({required double width, required Widget child}) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
        ),
      ),
      child: child,
    );
  }

  Widget _cellContent({
    required String value,
    required ValueChanged<String> onChanged,
    required bool isExisting,
    required TextAlign align,
    bool isNumeric = false,
  }) {
    if (isExisting) {
      return Container(
        alignment: align == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF1F1F1F),
          ),
          textAlign: align,
        ),
      );
    }

    final textController = TextEditingController(text: value)
      ..selection = TextSelection.collapsed(offset: value.length);

    return TextField(
      controller: textController,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      textAlign: align,
      style: const TextStyle(fontSize: 11, color: Color(0xFF1F1F1F)),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(92, 34),
              foregroundColor: const Color(0xFF3B3B3B),
              side: const BorderSide(color: Color(0xFFBEBEBE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
	            onPressed: controller.selectedProducts.isEmpty
	                ? null
	                : () async {
                    Set<String>? overwriteKeys;
                    if (widget.applyToMainInventory &&
                        controller.selectedProductsConflictWithInventory()) {
                      overwriteKeys = await _confirmProductOverwrite(
                        controller.selectedProductConflicts(),
                      );
                      if (overwriteKeys == null) return;
                    }
                    if (widget.applyToMainInventory &&
                        !controller.applySelectedProducts(
                          overwriteKeys: overwriteKeys,
                        )) {
                      return;
                    }
	                    Get.back();
	                    Get.snackbar(
	                      'Success',
	                      widget.applyToMainInventory
	                          ? '${controller.selectedProducts.length} products applied to inventory'
	                          : '${controller.selectedProducts.length} products selected',
	                      snackPosition: SnackPosition.TOP,
	                      backgroundColor: const Color(0xff10B981),
	                      colorText: Colors.white,
	                      duration: const Duration(seconds: 2),
	                    );
	                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(92, 34),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

	  Widget _headerCell(String title, double width) {
	    return Container(
      height: 34,
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFC8C8C8), width: 0.8),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF323232),
        ),
      ),
	    );
	  }

  Widget _selectAllBox({
    required bool checked,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: checked ? AppTheme.primaryColor : Colors.white,
            border: Border.all(color: const Color(0xFFB8B8B8), width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: checked
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Future<Set<String>?> _confirmProductOverwrite(
    List<Map<String, dynamic>> conflicts,
  ) {
    if (conflicts.isEmpty) return Future.value(<String>{});
    return showDialog<Set<String>>(
      context: context,
      builder: (context) => _InventoryOverwriteDialog(
        rows: conflicts,
      ),
    );
  }

  void _updateField(int index, String field, String value) {
    if (controller.isExistingProduct(index) ||
        index < 0 ||
        index >= controller.products.length) {
      return;
    }

    final ProductModel product = controller.products[index];

    switch (field) {
      case 'product':
        product.product = value;
        break;
      case 'code':
        product.code = value;
        break;
      case 'sg':
        product.sg = value;
        break;
      case 'unitNum':
        product.unitNum = value;
        break;
      case 'unitClass':
        product.unitClass = value;
        break;
      case 'group':
        product.group = value;
        break;
      case 'retail':
        product.retail = value;
        break;
      case 'a':
        product.a = value;
        break;
    }

    controller.updateProduct(index, product);

    if (index == controller.products.length - 1 && product.hasData()) {
      controller.addProduct();
    }
  }
}

class _InventoryOverwriteDialog extends StatefulWidget {
  const _InventoryOverwriteDialog({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  State<_InventoryOverwriteDialog> createState() =>
      _InventoryOverwriteDialogState();
}

class _InventoryOverwriteDialogState extends State<_InventoryOverwriteDialog> {
  late final Set<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    _selectedKeys = widget.rows
        .map((row) => (row['key'] ?? '').toString())
        .where((key) => key.isNotEmpty)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final allChecked =
        widget.rows.isNotEmpty && _selectedKeys.length == widget.rows.length;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Warning',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following item(s) already exist in inventory. Please select the ones you would like to overwrite.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC8C8C8)),
              ),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF3F3F3),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38,
                          child: Checkbox(
                            value: allChecked,
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selectedKeys
                                    ..clear()
                                    ..addAll(
                                      widget.rows.map(
                                        (row) => (row['key'] ?? '').toString(),
                                      ),
                                    );
                                } else {
                                  _selectedKeys.clear();
                                }
                              });
                            },
                          ),
                        ),
                        _dialogHeaderCell('Category', 140),
                        _dialogHeaderCell('Item', 190),
                        _dialogHeaderCell('PriceOld\n(Kwd)', 110),
                        _dialogHeaderCell('PriceNew\n(Kwd)', 110),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.rows.length,
                      itemBuilder: (context, index) {
                        final row = widget.rows[index];
                        final key = (row['key'] ?? '').toString();
                        final checked = _selectedKeys.contains(key);
                        return Container(
                          color: index.isEven
                              ? const Color(0xFFFFF9CC)
                              : Colors.white,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 38,
                                child: Checkbox(
                                  value: checked,
                                  onChanged: (_) {
                                    setState(() {
                                      if (checked) {
                                        _selectedKeys.remove(key);
                                      } else {
                                        _selectedKeys.add(key);
                                      }
                                    });
                                  },
                                ),
                              ),
                              _dialogBodyCell(
                                (row['category'] ?? '').toString(),
                                140,
                              ),
                              _dialogBodyCell((row['item'] ?? '').toString(), 190),
                              _dialogBodyCell(
                                _formatPrice(row['oldPrice']),
                                110,
                                alignRight: true,
                              ),
                              _dialogBodyCell(
                                _formatPrice(row['newPrice']),
                                110,
                                alignRight: true,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(Set<String>.from(_selectedKeys)),
          child: const Text('Accept'),
        ),
      ],
    );
  }

  Widget _dialogHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _dialogBodyCell(String text, double width, {bool alignRight = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFFD8D8D8)),
          top: BorderSide(color: Color(0xFFD8D8D8)),
        ),
      ),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatPrice(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (number == null) return '0.000';
    return number.toStringAsFixed(3);
  }
}
