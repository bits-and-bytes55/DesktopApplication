// Create this file ONLY ONCE: lib/stores/inventory_stores.dart
// Remove any other definitions of these classes from other files

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';

class InventoryProductsStore extends GetxController {
  final RxList<ProductModel> selectedProducts = <ProductModel>[].obs;

  void setSelectedProducts(List<ProductModel> products) {
    selectedProducts.assignAll(products.map(_cloneProduct));
    print('Products stored: ${selectedProducts.length}');
  }

  void mergeSelectedProducts(List<ProductModel> products) {
    final merged = <String, ProductModel>{};

    for (final product in selectedProducts) {
      final key = _productKey(product);
      if (key.isNotEmpty) {
        merged[key] = _cloneProduct(product);
      }
    }

    for (final product in products) {
      final key = _productKey(product);
      if (key.isNotEmpty) {
        merged[key] = _cloneProduct(product);
      }
    }

    selectedProducts.assignAll(merged.values);
    print('Products merged: ${selectedProducts.length}');
  }

  void clearSelectedProducts() {
    selectedProducts.clear();
  }

  String _productKey(ProductModel product) {
    final id = product.id?.trim() ?? '';
    if (id.isNotEmpty) return 'id:$id';

    final code = product.code.trim().toLowerCase();
    if (code.isNotEmpty) return 'code:$code';

    final name = product.product.trim().toLowerCase();
    if (name.isNotEmpty) return 'name:$name';

    return '';
  }

  ProductModel _cloneProduct(ProductModel product) {
    return ProductModel(
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
      price: product.price,
      initial: product.initial,
      volAdd: product.volAdd,
      calculate: product.calculate,
      plot: product.plot,
      tax: product.tax,
      isSelected: product.isSelected,
      isDeleted: product.isDeleted,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }
}

class InventoryServicesStore extends GetxController {
  final RxList<PackageItem> selectedPackages = <PackageItem>[].obs;
  final RxList<ServiceItem> selectedServices = <ServiceItem>[].obs;
  final RxList<EngineeringItem> selectedEngineering = <EngineeringItem>[].obs;

  void setSelectedServices({
    List<PackageItem>? packages,
    List<ServiceItem>? services,
    List<EngineeringItem>? engineering,
  }) {
    if (packages != null) {
      selectedPackages.assignAll(packages);
    }
    if (services != null) {
      selectedServices.assignAll(services);
    }
    if (engineering != null) {
      selectedEngineering.assignAll(engineering);
    }
    print(
      'Services stored: pkgs=${selectedPackages.length}, srvs=${selectedServices.length}, eng=${selectedEngineering.length}',
    );
  }

  void clearAll() {
    selectedPackages.clear();
    selectedServices.clear();
    selectedEngineering.clear();
  }
}
