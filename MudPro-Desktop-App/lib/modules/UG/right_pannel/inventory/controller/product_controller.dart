import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
// IMPORTANT: Import the centralized stores

class ProductsPickupController extends GetxController {
  final AuthRepository repository = AuthRepository();
  
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxSet<String> existingProductIds = <String>{}.obs;
  
  // Selection tracking
  final RxSet<int> selectedProductIndices = <int>{}.obs;
  final RxList<ProductModel> selectedProducts = <ProductModel>[].obs;
  
  final RxBool isSaving = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    isLoading.value = true;

    try {
      final result = await repository.getProducts(page: 1, limit: 1000);
      
      if (result['success'] == true) {
        final List<ProductModel> fetchedProducts = result['products'] ?? [];
        
        existingProductIds.clear();
        for (var product in fetchedProducts) {
          if (product.id != null) {
            existingProductIds.add(product.id!);
          }
        }
        
        products.clear();
        products.addAll(fetchedProducts);
        
        addProduct();
        
      } else {
        products.clear();
        addProduct();
        showErrorAlert(result['message'] ?? 'Failed to load products');
      }
    } catch (e) {
      products.clear();
      addProduct();
      showErrorAlert('Failed to load products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void addProduct() {
    products.add(ProductModel());
  }

  void updateProduct(int index, ProductModel product) {
    if (index >= 0 && index < products.length) {
      products[index] = product;
      products.refresh();
    }
  }

  bool isExistingProduct(int index) {
    if (index < 0 || index >= products.length) return false;
    final product = products[index];
    return product.id != null && existingProductIds.contains(product.id);
  }

  // Selection methods
  bool isProductSelected(int index) {
    return selectedProductIndices.contains(index);
  }

  void toggleProductSelection(int index) {
    if (!isExistingProduct(index)) return;
    
    if (selectedProductIndices.contains(index)) {
      selectedProductIndices.remove(index);
      selectedProducts.removeWhere((p) => p.id == products[index].id);
    } else {
      selectedProductIndices.add(index);
      selectedProducts.add(products[index]);
    }
    
    selectedProductIndices.refresh();
    selectedProducts.refresh();
  }

  void applySelectedProducts() {
    try {
      // Find the store (don't create new one)
      final store = Get.find<InventoryProductsStore>();
      store.mergeSelectedProducts(selectedProducts);
      
      print('✅ Applied ${selectedProducts.length} products to inventory');
    } catch (e) {
      print('❌ Error applying products: $e');
      showErrorAlert('Failed to apply products. Please restart the app.');
    }
  }

  Future<void> saveProducts() async {
    final newProducts = products.where((p) => 
      (p.id == null || !existingProductIds.contains(p.id)) && p.hasData()
    ).toList();
    
    if (newProducts.isEmpty) {
      showErrorAlert('No new data to save');
      return;
    }

    final validProducts = newProducts.where((p) => p.isValid()).toList();

    if (validProducts.isEmpty) {
      showErrorAlert('Please fill all required fields (Product, Code, SG, Unit Num, Unit Class, Group)');
      return;
    }

    isSaving.value = true;

    try {
      Map<String, dynamic> result;

      if (validProducts.length == 1) {
        result = await repository.addProduct(validProducts.first);
      } else {
        result = await repository.bulkAddProducts(validProducts);
      }

      if (result['success'] == true) {
        showSuccessAlert(result['message'] ?? 'Products saved successfully');
        await loadProducts();
      } else {
        showErrorAlert(result['message'] ?? 'Failed to save products');
      }
    } catch (e) {
      showErrorAlert('Failed to save products: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> exportProductsToExcel() async {
    try {
      final rows = _getPickupExportRows();
      if (rows.length <= 1) {
        showErrorAlert('No products to export');
        return;
      }

      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Products'];
      for (final row in rows) {
        sheet.appendRow(row.cast<dynamic>());
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Inventory Pickup Products',
        fileName:
            'inventory_pickup_products_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile == null) return;
      if (!outputFile.toLowerCase().endsWith('.xlsx')) {
        outputFile = '$outputFile.xlsx';
      }

      final bytes = excel.save();
      if (bytes == null) {
        showErrorAlert('Failed to create Excel file');
        return;
      }

      File(outputFile)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);

      showSuccessAlert('Products exported successfully');
    } catch (e) {
      showErrorAlert('Export failed: $e');
    }
  }

  Future<void> importProductsFromExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.single.path == null) return;

    isSaving.value = true;
    try {
      final rows = _readExcelRows(result.files.single.path!);
      final importedRows = _parsePickupImportRows(rows);
      if (importedRows.isEmpty) {
        showErrorAlert('No valid product rows found');
        return;
      }

      final existingByCode = <String, ProductModel>{};
      final existingByProduct = <String, ProductModel>{};
      for (final product in products) {
        if (product.id == null) continue;
        final codeKey = _normalizeKey(product.code);
        if (codeKey.isNotEmpty) {
          existingByCode[codeKey] = product;
        }
        final productKey = _normalizeKey(product.product);
        if (productKey.isNotEmpty) {
          existingByProduct[productKey] = product;
        }
      }

      int added = 0;
      int updated = 0;
      int unchanged = 0;
      final errors = <String>[];
      final newProducts = <ProductModel>[];
      final newProductCodes = <String>{};

      for (final row in importedRows) {
        if (row.product.trim().isEmpty && row.code.trim().isEmpty) {
          errors.add('Row ${row.rowNumber}: Product or Code is required');
          continue;
        }

        final codeKey = _normalizeKey(row.code);
        final productKey = _normalizeKey(row.product);
        final existingProduct =
            existingByCode[codeKey] ?? existingByProduct[productKey];
        final importedProduct = _productFromImportRow(row, existingProduct);

        if (existingProduct?.id != null) {
          if (_sameProductData(existingProduct!, importedProduct)) {
            unchanged += 1;
            continue;
          }

          final updateResult = await repository.updateProduct(
            existingProduct.id!,
            importedProduct.copyWith(id: existingProduct.id),
          );
          if (updateResult['success'] == true) {
            updated += 1;
          } else {
            errors.add(
              'Row ${row.rowNumber}: ${updateResult['message'] ?? 'Update failed'}',
            );
          }
          continue;
        }

        if (importedProduct.product.trim().isEmpty) {
          errors.add('Row ${row.rowNumber}: Product is required');
          continue;
        }

        final duplicateKey = codeKey.isNotEmpty ? codeKey : productKey;
        if (duplicateKey.isNotEmpty && !newProductCodes.add(duplicateKey)) {
          errors.add('Row ${row.rowNumber}: duplicate row skipped');
          continue;
        }

        newProducts.add(importedProduct);
      }

      if (newProducts.isNotEmpty) {
        for (final product in newProducts) {
          final addResult = await repository.addProduct(product);
          if (addResult['success'] == true) {
            added += 1;
          } else {
            errors.add(
              'Product ${product.product}: ${addResult['message'] ?? 'Add failed'}',
            );
          }
        }
      }

      await loadProducts();

      final summary = 'Added: $added, Updated: $updated, Unchanged: $unchanged';
      if (errors.isEmpty) {
        showSuccessAlert('Products imported successfully. $summary');
      } else {
        showErrorAlert('Import completed with issues. $summary');
        Get.defaultDialog(
          title: 'Import Issues',
          middleText: errors.take(20).join('\n'),
          textConfirm: 'OK',
          onConfirm: () => Get.back(),
        );
      }
    } catch (e) {
      showErrorAlert('Import failed: $e');
    } finally {
      isSaving.value = false;
    }
  }

  List<List<String>> _getPickupExportRows() {
    final rows = <List<String>>[
      ['Product', 'Code', 'SG', 'Qty', 'Unit', 'Group', 'Retail', 'A'],
    ];

    for (final product in products) {
      if (!product.hasData()) continue;
      rows.add([
        product.product,
        product.code,
        product.sg,
        product.unitNum,
        product.unitClass,
        product.group,
        product.retail,
        product.a,
      ]);
    }

    return rows;
  }

  List<List<String>> _readExcelRows(String path) {
    final bytes = File(path).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheetName = _resolveProductSheet(excel);
    if (sheetName == null) return const [];

    final table = excel.tables[sheetName];
    if (table == null) return const [];

    return table.rows
        .map((row) => row.map((cell) => _excelCellText(cell?.value)).toList())
        .toList();
  }

  String? _resolveProductSheet(Excel excel) {
    if (excel.tables.isEmpty) return null;
    for (final name in excel.tables.keys) {
      final normalized = name.trim().toLowerCase();
      if (normalized == 'products' || normalized == 'product') {
        return name;
      }
    }
    return excel.tables.keys.first;
  }

  List<_ImportedPickupProductRow> _parsePickupImportRows(
    List<List<String>> rows,
  ) {
    if (rows.isEmpty) return const [];

    final headerInfo = _findPickupHeader(rows);
    final headerIndexes = headerInfo?.indexes;
    final startIndex = headerInfo == null ? 0 : headerInfo.rowIndex + 1;
    final useMudCompanyTemplate = headerIndexes != null &&
        _isMudCompanyProductTemplate(headerIndexes);
    final parsed = <_ImportedPickupProductRow>[];

    for (int i = startIndex; i < rows.length; i += 1) {
      final row = List<String>.from(rows[i]);
      while (row.length < 8) {
        row.add('');
      }

      if (_hasPickupHeaders(_headerIndexes(row))) {
        continue;
      }

      if (useMudCompanyTemplate) {
        final legacyRow = _parseMudCompanyTemplateRow(row, i + 1);
        if (!legacyRow.hasData) continue;
        parsed.add(legacyRow);
        continue;
      }

      final product = _cellValue(
        row,
        headerIndexes,
        const ['product', 'product name', 'item', 'item name', 'material'],
        fallbackIndex: 0,
      );
      final code = _cellValue(
        row,
        headerIndexes,
        const ['code', 'product code', 'item code'],
        fallbackIndex: 1,
      );
      final sg = _cellValue(
        row,
        headerIndexes,
        const ['sg', 's g', 'specific gravity'],
        fallbackIndex: 2,
      );
      final qty = _cellValue(
        row,
        headerIndexes,
        const ['qty', 'quantity', 'unit num', 'unit number', 'num'],
        fallbackIndex: 3,
      );
      final unit = _cellValue(
        row,
        headerIndexes,
        const ['unit', 'unit class', 'class'],
        fallbackIndex: 4,
      );
      final group = _cellValue(
        row,
        headerIndexes,
        const ['group'],
        fallbackIndex: 5,
      );
      final retail = _cellValue(
        row,
        headerIndexes,
        const ['retail', 'retail price'],
        fallbackIndex: 6,
      );
      final a = _cellValue(
        row,
        headerIndexes,
        const ['a', 'sales price', 'price a', 'a price'],
        fallbackIndex: 7,
      );

      if ([product, code, sg, qty, unit, group, retail, a]
          .every((value) => value.trim().isEmpty)) {
        continue;
      }

      parsed.add(
        _ImportedPickupProductRow(
          rowNumber: i + 1,
          product: product,
          code: code,
          sg: sg,
          qty: qty,
          unit: unit,
          group: group,
          retail: retail,
          a: a,
        ),
      );
    }

    return parsed;
  }

  _PickupHeaderInfo? _findPickupHeader(List<List<String>> rows) {
    final scanCount = rows.length < 20 ? rows.length : 20;
    for (int i = 0; i < scanCount; i += 1) {
      final indexes = _headerIndexes(rows[i]);
      if (_hasPickupHeaders(indexes)) {
        return _PickupHeaderInfo(rowIndex: i, indexes: indexes);
      }
    }
    return null;
  }

  bool _hasPickupHeaders(Map<String, int> headers) {
    return headers.keys.any(_isPickupHeaderKey);
  }

  bool _isPickupHeaderKey(String key) {
    return const {
      'product',
      'product name',
      'item',
      'item name',
      'material',
      'company brand name',
      'brand name',
      'code',
      'product code',
      'item code',
      'sg',
      's g',
      'density',
      'density sg',
      'density s g',
      'specific gravity',
      'qty',
      'quantity',
      'unit num',
      'unit number',
      'num',
      'unit',
      'unit class',
      'class',
      'group',
      'product category',
      'category',
      'retail',
      'retail price',
      'a',
      'sales price',
      'price a',
      'a price',
    }.contains(key);
  }

  bool _isMudCompanyProductTemplate(Map<String, int> headers) {
    return headers.containsKey('company brand name') ||
        headers.containsKey('density s g') ||
        headers.containsKey('product category');
  }

  Map<String, int> _headerIndexes(List<String> row) {
    final indexes = <String, int>{};
    for (int i = 0; i < row.length; i += 1) {
      final key = _headerKey(row[i]);
      if (key.isNotEmpty) {
        indexes[key] = i;
      }
    }
    return indexes;
  }

  String _cellValue(
    List<String> row,
    Map<String, int>? headerIndexes,
    List<String> aliases, {
    required int fallbackIndex,
  }) {
    if (headerIndexes != null) {
      for (final alias in aliases) {
        final index = headerIndexes[_headerKey(alias)];
        if (index != null && index >= 0 && index < row.length) {
          return row[index].trim();
        }
      }
      return '';
    }

    return fallbackIndex >= 0 && fallbackIndex < row.length
        ? row[fallbackIndex].trim()
        : '';
  }

  _ImportedPickupProductRow _parseMudCompanyTemplateRow(
    List<String> row,
    int rowNumber,
  ) {
    final unitPair = _splitUnitText(_valueAt(row, 3));
    final qty = _firstNotEmpty([_valueAt(row, 4), unitPair.num]);
    final unit = _firstNotEmpty([_valueAt(row, 5), unitPair.unit]);

    return _ImportedPickupProductRow(
      rowNumber: rowNumber,
      product: _valueAt(row, 2),
      code: '',
      sg: _valueAt(row, 7),
      qty: qty,
      unit: unit,
      group: _valueAt(row, 8),
      retail: 'No',
      a: '',
    );
  }

  ProductModel _productFromImportRow(
    _ImportedPickupProductRow row,
    ProductModel? existing,
  ) {
    return ProductModel(
      id: existing?.id,
      product: row.product.trim(),
      code: row.code.trim(),
      sg: row.sg.trim(),
      unitNum: row.qty.trim(),
      unitClass: row.unit.trim(),
      group: row.group.trim(),
      retail: _normalizeRetail(row.retail),
      a: row.a.trim(),
    );
  }

  String _normalizeRetail(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    if (normalized == 'yes' || normalized == 'y' || normalized == 'true') {
      return 'Yes';
    }
    if (normalized == 'no' || normalized == 'n' || normalized == 'false') {
      return 'No';
    }
    return value.trim();
  }

  _SplitUnit _splitUnitText(String value) {
    final match = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*(.*)$')
        .firstMatch(value.trim());
    if (match == null) return const _SplitUnit('', '');
    return _SplitUnit(
      match.group(1)?.trim() ?? '',
      match.group(2)?.trim() ?? '',
    );
  }

  String _valueAt(List<String> row, int index) {
    return index >= 0 && index < row.length ? row[index].trim() : '';
  }

  String _firstNotEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  String _excelCellText(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value
          .toStringAsFixed(6)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return value.toString().trim();
  }

  bool _sameProductData(ProductModel existing, ProductModel imported) {
    return existing.product.trim() == imported.product.trim() &&
        existing.code.trim() == imported.code.trim() &&
        existing.sg.trim() == imported.sg.trim() &&
        existing.unitNum.trim() == imported.unitNum.trim() &&
        existing.unitClass.trim() == imported.unitClass.trim() &&
        existing.group.trim() == imported.group.trim() &&
        existing.retail.trim() == imported.retail.trim() &&
        existing.a.trim() == imported.a.trim();
  }

  String _headerKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeKey(String value) => value.trim().toLowerCase();

  void showSuccessAlert(String message) {
    Get.rawSnackbar(
      messageText: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xff10B981),
      borderRadius: 8,
      margin: EdgeInsets.only(top: 16, right: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 3),
      maxWidth: 400,
      animationDuration: Duration(milliseconds: 300),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  void showErrorAlert(String message) {
    Get.rawSnackbar(
      messageText: Row(
        children: [
          Icon(Icons.error, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xffEF4444),
      borderRadius: 8,
      margin: EdgeInsets.only(top: 16, right: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 3),
      maxWidth: 400,
      animationDuration: Duration(milliseconds: 300),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  Future<void> uploadExcel(String filePath) async {
    isLoading.value = true;

    try {
      final result = await repository.uploadExcel(filePath);
      
      if (result['success'] == true) {
        showSuccessAlert(result['message'] ?? 'Excel uploaded successfully');
        await loadProducts();

        if (result['errors'] != null && result['errors'].isNotEmpty) {
          Get.defaultDialog(
            title: 'Import Errors',
            middleText: 'Some rows had errors:\n${result['errors'].join('\n')}',
            textConfirm: 'OK',
            onConfirm: () => Get.back(),
          );
        }
      } else {
        showErrorAlert(result['message'] ?? 'Failed to upload Excel');
      }
    } catch (e) {
      showErrorAlert('Failed to upload Excel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    products.clear();
    existingProductIds.clear();
    selectedProductIndices.clear();
    selectedProducts.clear();
    super.onClose();
  }
}

class _ImportedPickupProductRow {
  final int rowNumber;
  final String product;
  final String code;
  final String sg;
  final String qty;
  final String unit;
  final String group;
  final String retail;
  final String a;

  const _ImportedPickupProductRow({
    required this.rowNumber,
    required this.product,
    required this.code,
    required this.sg,
    required this.qty,
    required this.unit,
    required this.group,
    required this.retail,
    required this.a,
  });

  bool get hasData {
    return product.trim().isNotEmpty ||
        code.trim().isNotEmpty ||
        sg.trim().isNotEmpty ||
        qty.trim().isNotEmpty ||
        unit.trim().isNotEmpty ||
        group.trim().isNotEmpty ||
        retail.trim().isNotEmpty ||
        a.trim().isNotEmpty;
  }
}

class _PickupHeaderInfo {
  final int rowIndex;
  final Map<String, int> indexes;

  const _PickupHeaderInfo({
    required this.rowIndex,
    required this.indexes,
  });
}

class _SplitUnit {
  final String num;
  final String unit;

  const _SplitUnit(this.num, this.unit);
}
