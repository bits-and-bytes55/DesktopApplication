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
      selectedPackages.assignAll(packages.map(_clonePackage));
    }
    if (services != null) {
      selectedServices.assignAll(services.map(_cloneService));
    }
    if (engineering != null) {
      selectedEngineering.assignAll(engineering.map(_cloneEngineering));
    }
    print(
      'Services stored: pkgs=${selectedPackages.length}, srvs=${selectedServices.length}, eng=${selectedEngineering.length}',
	    );
	  }

	  void mergeSelectedServices({
	    List<PackageItem>? packages,
	    List<ServiceItem>? services,
	    List<EngineeringItem>? engineering,
	    bool overwrite = true,
	  }) {
	    if (packages != null) {
	      selectedPackages.assignAll(
	        _mergePackages(selectedPackages, packages, overwrite),
	      );
	    }
	    if (services != null) {
	      selectedServices.assignAll(
	        _mergeServices(selectedServices, services, overwrite),
	      );
	    }
	    if (engineering != null) {
	      selectedEngineering.assignAll(
	        _mergeEngineering(selectedEngineering, engineering, overwrite),
	      );
	    }
	    print(
	      'Services merged: pkgs=${selectedPackages.length}, srvs=${selectedServices.length}, eng=${selectedEngineering.length}',
	    );
	  }

	  bool hasPackageConflict(List<PackageItem> packages) {
	    final existingKeys = selectedPackages
	        .map(_packageKey)
	        .where((key) => key.isNotEmpty)
	        .toSet();
	    return packages.any((item) {
	      final key = _packageKey(item);
	      return key.isNotEmpty && existingKeys.contains(key);
	    });
	  }

	  bool hasServiceConflict(List<ServiceItem> services) {
	    final existingKeys = selectedServices
	        .map(_serviceKey)
	        .where((key) => key.isNotEmpty)
	        .toSet();
	    return services.any((item) {
	      final key = _serviceKey(item);
	      return key.isNotEmpty && existingKeys.contains(key);
	    });
	  }

	  bool hasEngineeringConflict(List<EngineeringItem> engineering) {
	    final existingKeys = selectedEngineering
	        .map(_engineeringKey)
	        .where((key) => key.isNotEmpty)
	        .toSet();
	    return engineering.any((item) {
	      final key = _engineeringKey(item);
	      return key.isNotEmpty && existingKeys.contains(key);
	    });
	  }

	  void clearAll() {
	    selectedPackages.clear();
	    selectedServices.clear();
	    selectedEngineering.clear();
	  }

	  List<PackageItem> _mergePackages(
	    Iterable<PackageItem> current,
	    Iterable<PackageItem> incoming,
	    bool overwrite,
	  ) {
	    final merged = <String, PackageItem>{};
	    for (final item in current) {
	      final key = _packageKey(item);
	      if (key.isNotEmpty) merged[key] = _clonePackage(item);
	    }
	    for (final item in incoming) {
	      final key = _packageKey(item);
	      if (key.isEmpty || (!overwrite && merged.containsKey(key))) continue;
	      merged[key] = _clonePackage(item);
	    }
	    return merged.values.toList();
	  }

	  List<ServiceItem> _mergeServices(
	    Iterable<ServiceItem> current,
	    Iterable<ServiceItem> incoming,
	    bool overwrite,
	  ) {
	    final merged = <String, ServiceItem>{};
	    for (final item in current) {
	      final key = _serviceKey(item);
	      if (key.isNotEmpty) merged[key] = _cloneService(item);
	    }
	    for (final item in incoming) {
	      final key = _serviceKey(item);
	      if (key.isEmpty || (!overwrite && merged.containsKey(key))) continue;
	      merged[key] = _cloneService(item);
	    }
	    return merged.values.toList();
	  }

	  List<EngineeringItem> _mergeEngineering(
	    Iterable<EngineeringItem> current,
	    Iterable<EngineeringItem> incoming,
	    bool overwrite,
	  ) {
	    final merged = <String, EngineeringItem>{};
	    for (final item in current) {
	      final key = _engineeringKey(item);
	      if (key.isNotEmpty) merged[key] = _cloneEngineering(item);
	    }
	    for (final item in incoming) {
	      final key = _engineeringKey(item);
	      if (key.isEmpty || (!overwrite && merged.containsKey(key))) continue;
	      merged[key] = _cloneEngineering(item);
	    }
	    return merged.values.toList();
	  }

	  String _packageKey(PackageItem item) {
	    return _serviceInventoryKey(item.id, item.code, item.name);
	  }

	  String _serviceKey(ServiceItem item) {
	    return _serviceInventoryKey(item.id, item.code, item.name);
	  }

	  String _engineeringKey(EngineeringItem item) {
	    return _serviceInventoryKey(item.id, item.code, item.name);
	  }

	  String _serviceInventoryKey(String? id, String code, String name) {
	    final cleanId = id?.trim() ?? '';
	    if (cleanId.isNotEmpty) return 'id:$cleanId';
	    final cleanCode = code.trim().toLowerCase();
	    if (cleanCode.isNotEmpty) return 'code:$cleanCode';
	    final cleanName = name.trim().toLowerCase();
	    if (cleanName.isNotEmpty) return 'name:$cleanName';
	    return '';
	  }

	  PackageItem _clonePackage(PackageItem item) {
    return PackageItem(
      id: item.id,
      name: item.name,
      code: item.code,
      unit: item.unit,
      price: item.price,
      initial: item.initial,
      tax: item.tax,
    );
  }

  ServiceItem _cloneService(ServiceItem item) {
    return ServiceItem(
      id: item.id,
      name: item.name,
      code: item.code,
      unit: item.unit,
      price: item.price,
      initial: item.initial,
      tax: item.tax,
    );
  }

  EngineeringItem _cloneEngineering(EngineeringItem item) {
    return EngineeringItem(
      id: item.id,
      name: item.name,
      code: item.code,
      unit: item.unit,
      price: item.price,
      initial: item.initial,
      tax: item.tax,
    );
  }
}
