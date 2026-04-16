import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProductsController extends GetxController {
  final AuthRepository repository = AuthRepository();
  
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxSet<String> existingProductIds = <String>{}.obs;
  
  final RxBool isSaving = false.obs;
  final RxBool isLoading = false.obs;

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

  // Start inline editing — save a deep copy of original data for cancel
  void startInlineEdit(ProductModel product) {
    // If another row is being edited, cancel it first
    if (editingProductId.value != null && editingProductId.value != product.id) {
      cancelInlineEdit();
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

  Future<Map<String, dynamic>> importFromData(List<List<String>> rows) async {
    final parsedRows = _parseImportedRows(rows);
    if (parsedRows.isEmpty) {
      return {
        'success': false,
        'message': 'No valid product rows found in the selected file',
      };
    }

    int updated = 0;
    int inserted = 0;
    final errors = <String>[];

    final byId = <String, ProductModel>{};
    final byCode = <String, ProductModel>{};
    for (final product in products) {
      final id = product.id?.trim();
      if (id != null && id.isNotEmpty) {
        byId[id] = product;
      }
      final codeKey = _normalizeKey(product.code);
      if (codeKey.isNotEmpty) {
        byCode[codeKey] = product;
      }
    }

    final newProducts = <ProductModel>[];

    for (final row in parsedRows) {
      final importedProduct = ProductModel(
        product: row.product,
        code: row.code,
        sg: row.sg,
        unitNum: row.unitNum,
        unitClass: row.unitClass,
        group: row.group,
        retail: row.retail,
        a: row.a,
        b: row.b,
      );

      final matchedProduct = _findExistingProduct(
        recordId: row.recordId,
        code: row.code,
        byId: byId,
        byCode: byCode,
      );

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
        newProducts.add(importedProduct);
      }
    }

    if (newProducts.isNotEmpty) {
      final result = newProducts.length == 1
          ? await repository.addProduct(newProducts.first)
          : await repository.bulkAddProducts(newProducts);

      if (result['success'] == true) {
        inserted += newProducts.length;
      } else {
        errors.add(result['message'] ?? 'Failed to add imported products');
      }
    }

    await loadProducts();

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
    required Map<String, ProductModel> byId,
    required Map<String, ProductModel> byCode,
  }) {
    final trimmedId = recordId.trim();
    if (trimmedId.isNotEmpty && byId.containsKey(trimmedId)) {
      return byId[trimmedId];
    }

    final normalizedCode = _normalizeKey(code);
    if (normalizedCode.isNotEmpty && byCode.containsKey(normalizedCode)) {
      return byCode[normalizedCode];
    }

    return null;
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

    final header = rows.first.map((cell) => cell.trim().toLowerCase()).toList();
    final hasRecordId = header.isNotEmpty && header.first == 'record id';
    final startIndex = _looksLikeProductHeader(rows.first) ? 1 : 0;
    final parsed = <_ImportedProductRow>[];

    for (int i = startIndex; i < rows.length; i += 1) {
      final row = List<String>.from(rows[i]);
      final minimumLength = hasRecordId ? 10 : 9;
      while (row.length < minimumLength) {
        row.add('');
      }

      if (_looksLikeProductHeader(row)) {
        continue;
      }

      final offset = hasRecordId ? 1 : 0;
      final values = row.skip(offset).take(9).map((value) => value.trim()).toList();
      if (values.every((value) => value.isEmpty)) {
        continue;
      }

      parsed.add(
        _ImportedProductRow(
          recordId: hasRecordId ? row[0].trim() : '',
          product: values[0],
          code: values[1],
          sg: values[2],
          unitNum: values[3],
          unitClass: values[4],
          group: values[5],
          retail: values[6],
          a: values[7],
          b: values[8],
        ),
      );
    }

    return parsed;
  }

  bool _looksLikeProductHeader(List<String> row) {
    final normalized = row.map((cell) => cell.trim().toLowerCase()).toList();
    return normalized.contains('product') &&
        normalized.contains('code') &&
        normalized.contains('sg');
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
    editingProductId.value = null;
    _editingOriginalProduct = null;
    super.onClose();
  }
}

class _ImportedProductRow {
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
}
