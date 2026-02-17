// Create this file ONLY ONCE: lib/stores/inventory_stores.dart
// Remove any other definitions of these classes from other files

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';

class InventoryProductsStore extends GetxController {
  final RxList<ProductModel> selectedProducts = <ProductModel>[].obs;

  void setSelectedProducts(List<ProductModel> products) {
    selectedProducts.clear();
    selectedProducts.addAll(products);
    print('✅ Products stored: ${selectedProducts.length}');
  }

  void clearSelectedProducts() {
    selectedProducts.clear();
  }
}

class InventoryServicesStore extends GetxController {
  final RxList<PackageItem> selectedPackages = <PackageItem>[].obs;
  final RxList<ServiceItem> selectedServices = <ServiceItem>[].obs;
  final RxList<EngineeringItem> selectedEngineering = <EngineeringItem>[].obs;

  void setSelectedServices({
    required List<PackageItem> packages,
    required List<ServiceItem> services,
    required List<EngineeringItem> engineering,
  }) {
    selectedPackages.clear();
    selectedServices.clear();
    selectedEngineering.clear();
    
    selectedPackages.addAll(packages);
    selectedServices.addAll(services);
    selectedEngineering.addAll(engineering);
    
    print('✅ Services stored - Packages: ${selectedPackages.length}, Services: ${selectedServices.length}, Engineering: ${selectedEngineering.length}');
  }

  void clearAll() {
    selectedPackages.clear();
    selectedServices.clear();
    selectedEngineering.clear();
  }
}