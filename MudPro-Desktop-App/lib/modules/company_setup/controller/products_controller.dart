import 'dart:async';


import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

typedef ProductImportProgress = void Function(double progress, String message);

class ProductsController extends GetxController {
  final AuthRepository repository = AuthRepository();
  
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxSet<String> existingProductIds = <String>{}.obs;
  
  final RxBool isSaving = false.obs;
  final RxBool isLoading = false.obs;
  final Map<String, Timer> _autosaveTimers = {};
  final Set<String> _autosaveInFlight = {};
  final Set<String> _autosaveQueued = {};
  static const Duration _autosaveDelay = Duration(milliseconds: 800);

  // Track which existing product is currently being inline-edited
  final RxnString editingProductId = RxnString(null);

  // Store original data before inline edit (to restore on cancel)
  ProductModel? _editingOriginalProduct;

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

  void updateProduct(
    int index,
    ProductModel product, {
    bool refresh = true,
  }) {
    if (index >= 0 && index < products.length) {
      if (!identical(products[index], product)) {
        products[index] = product;
      }
      if (refresh) {
        products.refresh();
      }
    }
  }

  bool isExistingProduct(int index) {
    if (index < 0 || index >= products.length) return false;
    final product = products[index];
    return product.id != null && existingProductIds.contains(product.id);
  }

  // Start inline editing — save a deep copy of original data for cancel
  void startInlineEdit(ProductModel product) {
    // If another row is being edited, just close that edit state.
    if (editingProductId.value != null && editingProductId.value != product.id) {
      editingProductId.value = null;
      _editingOriginalProduct = null;
    }

    _editingOriginalProduct = ProductModel(
      id: product.id,
      product: product.product,
      code: product.code,
      sg: product.sg,
      unitNum: product.unitNum,
      unitClass: product.unitClass,
      group: product.group,
      retail: product.retail,
      a: product.a,
      b: product.b,
    );

    editingProductId.value = product.id;
  }

  void queueAutoSave(int index) {
    if (index < 0 || index >= products.length) return;

    final product = products[index];
    if (!product.hasData()) return;

    final key = _autosaveKey(index, product);
    _autosaveTimers[key]?.cancel();
    _autosaveTimers[key] = Timer(
      _autosaveDelay,
      () => _runAutoSave(index, key),
    );
  }

  Future<void> _runAutoSave(int index, String key) async {
    if (index < 0 || index >= products.length) return;
    if (_autosaveInFlight.contains(key)) {
      _autosaveQueued.add(key);
      return;
    }

    final product = products[index];
    if (!product.hasData() || product.product.trim().isEmpty) return;

    _autosaveInFlight.add(key);
    try {
      final isExisting = product.id != null &&
          product.id!.trim().isNotEmpty &&
          existingProductIds.contains(product.id);
      final result = isExisting
          ? await repository.updateProduct(product.id!, product)
          : await repository.addProduct(product);

      if (result['success'] == true) {
        final data = result['data'];
        if (!isExisting && data is Map) {
          final savedProduct = ProductModel.fromJson(
            Map<String, dynamic>.from(data),
          );
          if (savedProduct.id != null && savedProduct.id!.isNotEmpty) {
            product.id = savedProduct.id;
            product.createdAt = savedProduct.createdAt;
            product.updatedAt = savedProduct.updatedAt;
            existingProductIds.add(savedProduct.id!);
            editingProductId.value = savedProduct.id;
            products.refresh();
          }
        } else if (isExisting && data is Map) {
          final savedProduct = ProductModel.fromJson(
            Map<String, dynamic>.from(data),
          );
          product.updatedAt = savedProduct.updatedAt;
        }

        _ensureTrailingBlankRow();
      } else {
        showErrorAlert(result['message'] ?? 'Auto save failed');
      }
    } catch (e) {
      showErrorAlert('Auto save failed: $e');
    } finally {
      _autosaveTimers.remove(key);
      _autosaveInFlight.remove(key);
      final shouldSaveAgain = _autosaveQueued.remove(key);
      if (shouldSaveAgain && index >= 0 && index < products.length) {
        queueAutoSave(index);
      }
    }
  }

  void removeUnsavedProduct(int index) {
    if (index < 0 || index >= products.length) return;
    final product = products[index];
    if (isExistingProduct(index)) return;

    _cancelAutoSave(index, product);
    products.removeAt(index);
    _ensureTrailingBlankRow();
    products.refresh();
  }

  void _ensureTrailingBlankRow() {
    if (products.isEmpty || products.last.hasData()) {
      addProduct();
    }
  }

  String _autosaveKey(int index, ProductModel product) {
    final id = product.id?.trim() ?? '';
    return id.isNotEmpty ? 'id:$id' : 'new:$index';
  }

  void _cancelAutoSave(int index, ProductModel product) {
    final keys = {
      _autosaveKey(index, product),
      if (product.id != null && product.id!.trim().isNotEmpty)
        'id:${product.id!.trim()}',
      'new:$index',
    };
    for (final key in keys) {
      _autosaveTimers.remove(key)?.cancel();
      _autosaveInFlight.remove(key);
      _autosaveQueued.remove(key);
    }
  }

  // Cancel inline edit — restore original data
  void cancelInlineEdit() {
    if (editingProductId.value == null || _editingOriginalProduct == null) {
      editingProductId.value = null;
      return;
    }

    final idx = products.indexWhere((p) => p.id == editingProductId.value);
    if (idx != -1 && _editingOriginalProduct != null) {
      products[idx] = _editingOriginalProduct!;
      products.refresh();
    }

    editingProductId.value = null;
    _editingOriginalProduct = null;
  }

  // Save inline edited row — calls update API
  Future<void> saveInlineEdit(String productId) async {
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx == -1) return;

    final product = products[idx];

    if (!product.isValid()) {
      showErrorAlert('Please fill all required fields (Product, Code, SG, Unit Num, Unit Class, Group)');
      return;
    }

    await updateProductData(productId, product);

    // Clear editing state only on success (updateProductData calls loadProducts on success)
    editingProductId.value = null;
    _editingOriginalProduct = null;
  }

  // Update product API call
  Future<void> updateProductData(String productId, ProductModel product) async {
    isSaving.value = true;

    try {
      final result = await repository.updateProduct(productId, product);

      if (result['success'] == true) {
        showSuccessAlert(result['message'] ?? 'Product updated successfully');
        await loadProducts();
      } else {
        showErrorAlert(result['message'] ?? 'Failed to update product');
      }
    } catch (e) {
      showErrorAlert('Failed to update product: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // Delete product API call
  Future<void> deleteProduct(String productId) async {
    isSaving.value = true;

    try {
      final result = await repository.deleteProduct(productId);

      if (result['success'] == true) {
        showSuccessAlert(result['message'] ?? 'Product deleted successfully');
        await loadProducts();
      } else {
        showErrorAlert(result['message'] ?? 'Failed to delete product');
      }
    } catch (e) {
      showErrorAlert('Failed to delete product: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // Show delete confirmation dialog
  void showDeleteConfirmation(BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$productName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteProduct(productId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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

  // ─── Export/Import Helpers ────────────────────────────────────────────────

  List<List<String>> getExportData() {
    List<List<String>> data = [[
      'Record ID',
      'Product',
      'Code',
      'SG',
      'Unit Num',
      'Unit Class',
      'Group',
      'Retail',
      'Sales Price',
      'COGS',
    ]];
    for (var p in products) {
      if (p.id != null || p.hasData()) {
        data.add([
          p.id ?? '',
          p.product.toString(),
          p.code.toString(),
          p.sg.toString(),
          p.unitNum.toString(),
          p.unitClass.toString(),
          p.group.toString(),
          p.retail.toString(),
          p.a.toString(),
          p.b.toString(),
        ]);
      }
    }
    return data;
  }

  Future<Map<String, dynamic>> importFromData(
    List<List<String>> rows, {
    ProductImportProgress? onProgress,
  }) async {
    onProgress?.call(0.02, 'Reading product rows...');
    final parsedRows = _parseImportedRows(rows);
    if (parsedRows.isEmpty) {
      return {
        'success': false,
        'message': 'No valid product rows found in the selected file',
      };
    }

    onProgress?.call(0.08, 'Preparing products...');
    int updated = 0;
    int inserted = 0;
    final errors = <String>[];

    final byId = <String, ProductModel>{};
    final byCode = <String, ProductModel>{};
    final byProduct = <String, ProductModel>{};
    for (final product in products) {
      final id = product.id?.trim();
      if (id != null && id.isNotEmpty) {
        byId[id] = product;
      }
      final codeKey = _normalizeKey(product.code);
      if (codeKey.isNotEmpty) {
        byCode[codeKey] = product;
      }
      final productKey = _normalizeKey(product.product);
      if (productKey.isNotEmpty) {
        byProduct[productKey] = product;
      }
    }

    final newProducts = <ProductModel>[];
    final newProductKeys = <String>{};

    for (int i = 0; i < parsedRows.length; i += 1) {
      final row = parsedRows[i];
      onProgress?.call(
        0.10 + (0.55 * (i / parsedRows.length)),
        'Checking product ${i + 1} of ${parsedRows.length}...',
      );

      if (row.product.trim().isEmpty && row.code.trim().isEmpty) {
        errors.add('Row ${row.rowNumber}: Product or Code is required');
        continue;
      }

      final matchedProduct = _findExistingProduct(
        recordId: row.recordId,
        code: row.code,
        product: row.product,
        byId: byId,
        byCode: byCode,
        byProduct: byProduct,
      );
      final importedProduct = _productFromImportRow(row, matchedProduct);

      if (matchedProduct?.id != null) {
        if (!_sameProductData(matchedProduct!, importedProduct)) {
          final result = await repository.updateProduct(
            matchedProduct.id!,
            importedProduct.copyWith(id: matchedProduct.id),
          );
          if (result['success'] == true) {
            updated += 1;
          } else {
            errors.add(
              'Product ${row.code.isEmpty ? row.product : row.code}: ${result['message'] ?? 'Update failed'}',
            );
          }
        }
      } else {
        if (importedProduct.product.trim().isEmpty) {
          errors.add('Row ${row.rowNumber}: Product is required');
          continue;
        }

        final codeKey = _normalizeKey(importedProduct.code);
        final productKey = _normalizeKey(importedProduct.product);
        final duplicateKey = codeKey.isNotEmpty ? codeKey : productKey;
        if (duplicateKey.isNotEmpty && !newProductKeys.add(duplicateKey)) {
          errors.add('Row ${row.rowNumber}: duplicate row skipped');
          continue;
        }

        newProducts.add(importedProduct);
      }
    }

    if (newProducts.isNotEmpty) {
      for (int i = 0; i < newProducts.length; i += 1) {
        final product = newProducts[i];
        onProgress?.call(
          0.70 + (0.25 * (i / newProducts.length)),
          'Adding product ${i + 1} of ${newProducts.length}...',
        );
        final result = await repository.addProduct(product);
        if (result['success'] == true) {
          inserted += 1;
        } else {
          errors.add(
            'Product ${product.product}: ${result['message'] ?? 'Add failed'}',
          );
        }
      }
    }

    onProgress?.call(0.96, 'Refreshing products...');
    await loadProducts();
    onProgress?.call(1, 'Import completed');

    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message':
            'Products import finished with issues. Updated: $updated, Added: $inserted',
        'updated': updated,
        'inserted': inserted,
        'errors': errors,
      };
    }

    return {
      'success': true,
      'message': 'Products imported successfully. Updated: $updated, Added: $inserted',
      'updated': updated,
      'inserted': inserted,
    };
  }

  ProductModel? _findExistingProduct({
    required String recordId,
    required String code,
    required String product,
    required Map<String, ProductModel> byId,
    required Map<String, ProductModel> byCode,
    required Map<String, ProductModel> byProduct,
  }) {
    final trimmedId = recordId.trim();
    if (trimmedId.isNotEmpty && byId.containsKey(trimmedId)) {
      return byId[trimmedId];
    }

    final normalizedCode = _normalizeKey(code);
    if (normalizedCode.isNotEmpty && byCode.containsKey(normalizedCode)) {
      return byCode[normalizedCode];
    }

    final normalizedProduct = _normalizeKey(product);
    if (normalizedProduct.isNotEmpty &&
        byProduct.containsKey(normalizedProduct)) {
      return byProduct[normalizedProduct];
    }

    return null;
  }

  ProductModel _productFromImportRow(
    _ImportedProductRow row,
    ProductModel? existing,
  ) {
    return ProductModel(
      id: existing?.id,
      product: row.product.trim(),
      code: row.code.trim(),
      sg: row.sg.trim(),
      unitNum: row.unitNum.trim(),
      unitClass: row.unitClass.trim(),
      group: row.group.trim(),
      retail: _normalizeRetail(row.retail),
      a: row.a.trim(),
      b: row.b.trim(),
    );
  }

  bool _sameProductData(ProductModel existing, ProductModel imported) {
    return existing.product.trim() == imported.product.trim() &&
        existing.code.trim() == imported.code.trim() &&
        existing.sg.trim() == imported.sg.trim() &&
        existing.unitNum.trim() == imported.unitNum.trim() &&
        existing.unitClass.trim() == imported.unitClass.trim() &&
        existing.group.trim() == imported.group.trim() &&
        existing.retail.trim() == imported.retail.trim() &&
        existing.a.trim() == imported.a.trim() &&
        existing.b.trim() == imported.b.trim();
  }

  List<_ImportedProductRow> _parseImportedRows(List<List<String>> rows) {
    if (rows.isEmpty) return const [];

    final headerInfo = _findProductHeader(rows);
    final headerIndexes = headerInfo?.indexes;
    final startIndex = headerInfo == null ? 0 : headerInfo.rowIndex + 1;
    final useMudCompanyTemplate = headerIndexes != null &&
        _isMudCompanyProductTemplate(headerIndexes);
    final parsed = <_ImportedProductRow>[];

    for (int i = startIndex; i < rows.length; i += 1) {
      final row = List<String>.from(rows[i]);
      while (row.length < 10) {
        row.add('');
      }

      if (_hasProductHeaders(_headerIndexes(row))) {
        continue;
      }

      final importedRow = useMudCompanyTemplate
          ? _parseMudCompanyTemplateRow(row, i + 1)
          : _parseStandardProductRow(row, headerIndexes, i + 1);

      if (!importedRow.hasData) {
        continue;
      }

      parsed.add(importedRow);
    }

    return parsed;
  }

  _ImportedProductRow _parseStandardProductRow(
    List<String> row,
    Map<String, int>? headerIndexes,
    int rowNumber,
  ) {
    return _ImportedProductRow(
      rowNumber: rowNumber,
      recordId: _cellValue(
        row,
        headerIndexes,
        const ['record id', 'id'],
        fallbackIndex: 0,
      ),
      product: _cellValue(
        row,
        headerIndexes,
        const [
          'product',
          'product name',
          'company brand name',
          'brand name',
          'item',
          'item name',
          'material',
        ],
        fallbackIndex: headerIndexes == null ? 0 : 1,
      ),
      code: _cellValue(
        row,
        headerIndexes,
        const ['code', 'product code', 'item code'],
        fallbackIndex: headerIndexes == null ? 1 : 2,
      ),
      sg: _cellValue(
        row,
        headerIndexes,
        const ['sg', 's g', 'density', 'density sg', 'density s g', 'specific gravity'],
        fallbackIndex: headerIndexes == null ? 2 : 3,
      ),
      unitNum: _cellValue(
        row,
        headerIndexes,
        const ['unit num', 'unit number', 'qty', 'quantity', 'size', 'num'],
        fallbackIndex: headerIndexes == null ? 3 : 4,
      ),
      unitClass: _cellValue(
        row,
        headerIndexes,
        const ['unit class', 'class', 'unit'],
        fallbackIndex: headerIndexes == null ? 4 : 5,
      ),
      group: _cellValue(
        row,
        headerIndexes,
        const ['group', 'product category', 'category'],
        fallbackIndex: headerIndexes == null ? 5 : 6,
      ),
      retail: _cellValue(
        row,
        headerIndexes,
        const ['retail', 'retail price'],
        fallbackIndex: headerIndexes == null ? 6 : 7,
      ),
      a: _cellValue(
        row,
        headerIndexes,
        const ['a', 'sales price', 'price a', 'a price'],
        fallbackIndex: headerIndexes == null ? 7 : 8,
      ),
      b: _cellValue(
        row,
        headerIndexes,
        const ['b', 'cogs', 'price b', 'b price'],
        fallbackIndex: headerIndexes == null ? 8 : 9,
      ),
    );
  }

  _ImportedProductRow _parseMudCompanyTemplateRow(
    List<String> row,
    int rowNumber,
  ) {
    final unitPair = _splitUnitText(_valueAt(row, 3));
    final unitNum = _firstNotEmpty([_valueAt(row, 4), unitPair.num]);
    final unitClass = _firstNotEmpty([_valueAt(row, 5), unitPair.unit]);

    return _ImportedProductRow(
      rowNumber: rowNumber,
      recordId: '',
      product: _valueAt(row, 2),
      code: '',
      sg: _valueAt(row, 7),
      unitNum: unitNum,
      unitClass: unitClass,
      group: _valueAt(row, 8),
      retail: '',
      a: '',
      b: '',
    );
  }

  _ProductHeaderInfo? _findProductHeader(List<List<String>> rows) {
    final scanCount = rows.length < 20 ? rows.length : 20;
    for (int i = 0; i < scanCount; i += 1) {
      final indexes = _headerIndexes(rows[i]);
      if (_hasProductHeaders(indexes)) {
        return _ProductHeaderInfo(rowIndex: i, indexes: indexes);
      }
    }
    return null;
  }

  bool _hasProductHeaders(Map<String, int> headers) {
    final keys = headers.keys.toSet();
    if (keys.contains('product') ||
        keys.contains('product name') ||
        keys.contains('company brand name') ||
        keys.contains('brand name')) {
      return true;
    }

    if (keys.contains('code') && keys.contains('sg')) {
      return true;
    }

    return keys.where(_isProductSpecificHeaderKey).length >= 2;
  }

  bool _isProductSpecificHeaderKey(String key) {
    return const {
      'product',
      'product name',
      'company brand name',
      'brand name',
      'item',
      'item name',
      'material',
      'code',
      'product code',
      'item code',
      'sg',
      's g',
      'density',
      'density sg',
      'density s g',
      'specific gravity',
      'unit num',
      'unit number',
      'qty',
      'quantity',
      'size',
      'num',
      'unit class',
      'class',
      'unit',
      'group',
      'product category',
      'category',
      'retail',
      'retail price',
      'a',
      'sales price',
      'price a',
      'a price',
      'b',
      'cogs',
      'price b',
      'b price',
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
    for (final timer in _autosaveTimers.values) {
      timer.cancel();
    }
    _autosaveTimers.clear();
    _autosaveInFlight.clear();
    _autosaveQueued.clear();
    products.clear();
    existingProductIds.clear();
    editingProductId.value = null;
    _editingOriginalProduct = null;
    super.onClose();
  }
}

class _ImportedProductRow {
  final int rowNumber;
  final String recordId;
  final String product;
  final String code;
  final String sg;
  final String unitNum;
  final String unitClass;
  final String group;
  final String retail;
  final String a;
  final String b;

  const _ImportedProductRow({
    required this.rowNumber,
    required this.recordId,
    required this.product,
    required this.code,
    required this.sg,
    required this.unitNum,
    required this.unitClass,
    required this.group,
    required this.retail,
    required this.a,
    required this.b,
  });

  bool get hasData {
    return recordId.trim().isNotEmpty ||
        product.trim().isNotEmpty ||
        code.trim().isNotEmpty ||
        sg.trim().isNotEmpty ||
        unitNum.trim().isNotEmpty ||
        unitClass.trim().isNotEmpty ||
        group.trim().isNotEmpty ||
        retail.trim().isNotEmpty ||
        a.trim().isNotEmpty ||
        b.trim().isNotEmpty;
  }
}

class _ProductHeaderInfo {
  final int rowIndex;
  final Map<String, int> indexes;

  const _ProductHeaderInfo({
    required this.rowIndex,
    required this.indexes,
  });
}

class _SplitUnit {
  final String num;
  final String unit;

  const _SplitUnit(this.num, this.unit);
}
