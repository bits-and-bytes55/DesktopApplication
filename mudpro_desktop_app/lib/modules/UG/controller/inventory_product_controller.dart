// import 'package:get/get.dart';
// import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
// import 'package:mudpro_desktop_app/modules/UG/model/producst_model.dart' hide ProductModel;
// import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
// import 'package:flutter/material.dart';

// class InventoryController extends GetxController {
//   final AuthRepository repository = AuthRepository();

//   // Observable lists
//   RxList<ProductModel> products = <ProductModel>[].obs;
//   RxList<PremixModel> premixed = <PremixModel>[].obs;
//   RxList<ObmModel> obm = <ObmModel>[].obs;

//   // Loading and lock states
//   RxBool isLoading = false.obs;
//   RxBool isLocked = true.obs;

//   // Pagination
//   RxInt currentPage = 1.obs;
//   RxInt totalProducts = 0.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchProducts();
//     _initializePremixed();
//     _initializeObm();
//   }

//   // Fetch products from API
//   Future<void> fetchProducts({int page = 1, String? search, String? group}) async {
//     isLoading.value = true;

//     try {
//       final result = await repository.getProducts(
//         page: page,
//         limit: 100, // Get more products for inventory
//         search: search,
//         group: group,
//       );

//       if (result['success']) {
//         final fetchedProducts = result['products'] as List<dynamic>;
        
//         products.value = fetchedProducts
//             .map((p) => ProductModel.fromJson(p.toJson()))
//             .toList();

//         totalProducts.value = result['total'];
//         currentPage.value = result['page'];

//         isLoading.value = false;
//       } else {
//         isLoading.value = false;
//         Get.snackbar(
//           'Error',
//           result['message'],
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//       }
//     } catch (e) {
//       isLoading.value = false;
//       Get.snackbar(
//         'Error',
//         'Failed to fetch products: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   // Refresh products
//   Future<void> refreshProducts() async {
//     await fetchProducts(page: currentPage.value);
//   }

//   // Toggle product selection
//   void toggleProductSelection(int index) {
//     if (index < products.length) {
//       products[index].isSelected = !products[index].isSelected;
//       products.refresh();
//     }
//   }

//   // Select all products
//   void selectAllProducts(bool value) {
//     for (var product in products) {
//       product.isSelected = value;
//     }
//     products.refresh();
//   }

//   // Get selected products count
//   int get selectedProductsCount {
//     return products.where((p) => p.isSelected).length;
//   }

//   // Export selected products
//   List<Map<String, dynamic>> exportSelectedProducts() {
//     return products
//         .where((p) => p.isSelected)
//         .map((p) => p.toExportJson())
//         .toList();
//   }

//   // Toggle lock/unlock
//   void toggleLock() {
//     isLocked.value = !isLocked.value;
//   }

//   // Update product field
//   void updateProductField(int index, String field, String value) {
//     if (index >= products.length) return;

//     final product = products[index];
//     switch (field) {
//       case 'product':
//         product.product = value;
//         break;
//       case 'code':
//         product.code = value;
//         break;
//       case 'sg':
//         product.sg = value;
//         break;
//       case 'unit':
//         product.unit = value;
//         break;
//       case 'price':
//         product.price = value;
//         break;
//       case 'initial':
//         product.initial = value;
//         break;
//       case 'group':
//         product.group = value;
//         break;
//     }
//     products.refresh();
//   }

//   // Toggle product checkbox
//   void toggleProductCheckbox(int index, String field, bool value) {
//     if (index >= products.length) return;

//     final product = products[index];
//     switch (field) {
//       case 'volAdd':
//         product.volAdd = value;
//         break;
//       case 'calculate':
//         product.calculate = value;
//         break;
//       case 'tax':
//         product.tax = value;
//         break;
//     }
//     products.refresh();
//   }

//   // Initialize premixed data (demo data)
//   void _initializePremixed() {
//     premixed.value = [
//       PremixModel(id: '1', description: 'Base Mud', mw: '8.5', leasingFee: '100', mudType: 'WBM'),
//       PremixModel(id: '2', description: 'Enhanced Mud', mw: '9.0', leasingFee: '150', mudType: 'OBM'),
//     ];
//   }

//   // Initialize OBM data (demo data)
//   void _initializeObm() {
//     obm.value = [
//       ObmModel(id: '1', product: 'Base Oil', code: 'BO-001', sg: '0.85', conc: '70'),
//       ObmModel(id: '2', product: 'Emulsifier', code: 'EM-001', sg: '0.95', conc: '5'),
//     ];
//   }

//   // Toggle premixed selection
//   void togglePremixedSelection(int index) {
//     if (index < premixed.length) {
//       premixed[index].isSelected = !premixed[index].isSelected;
//       premixed.refresh();
//     }
//   }

//   // Toggle OBM selection
//   void toggleObmSelection(int index) {
//     if (index < obm.length) {
//       obm[index].isSelected = !obm[index].isSelected;
//       obm.refresh();
//     }
//   }

//   // Export selected premixed
//   List<Map<String, dynamic>> exportSelectedPremixed() {
//     return premixed
//         .where((p) => p.isSelected)
//         .map((p) => p.toExportJson())
//         .toList();
//   }

//   // Export selected OBM
//   List<Map<String, dynamic>> exportSelectedObm() {
//     return obm
//         .where((o) => o.isSelected)
//         .map((o) => o.toExportJson())
//         .toList();
//   }

//   // Save selected items
//   Future<void> saveSelectedItems() async {
//     final selectedProducts = exportSelectedProducts();
//     final selectedPremixed = exportSelectedPremixed();
//     final selectedObm = exportSelectedObm();

//     if (selectedProducts.isEmpty && selectedPremixed.isEmpty && selectedObm.isEmpty) {
//       Get.snackbar(
//         'No Selection',
//         'Please select at least one item to export',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     // Here you can implement your export logic
//     Get.snackbar(
//       'Export Ready',
//       'Selected ${selectedProducts.length} products, ${selectedPremixed.length} premixed, ${selectedObm.length} OBM items',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//     );

//     // TODO: Implement actual export logic here
//     print('Selected Products: $selectedProducts');
//     print('Selected Premixed: $selectedPremixed');
//     print('Selected OBM: $selectedObm');
//   }
// }