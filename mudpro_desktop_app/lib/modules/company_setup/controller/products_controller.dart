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