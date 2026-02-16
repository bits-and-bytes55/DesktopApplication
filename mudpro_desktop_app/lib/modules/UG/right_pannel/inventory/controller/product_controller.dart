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
      store.setSelectedProducts(selectedProducts);
      
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