import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryServicesView extends StatefulWidget {
  const InventoryServicesView({super.key});

  @override
  State<InventoryServicesView> createState() => _InventoryServicesViewState();
}

class _InventoryServicesViewState extends State<InventoryServicesView> {
  final isLocked = false.obs;
  final ScrollController _scrollController = ScrollController();
  
  String get wellId => '507f1f77bcf86cd799439011';

  @override
  void initState() {
    super.initState();
    _loadDataFromAPI();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataFromAPI();
    });
  }

  Future<void> _loadDataFromAPI() async {
    try {
      final inventoryData = await InventoryProductsService.getInventoryData(wellId);
      final store = Get.find<InventoryServicesStore>();
      
      final packagesList = inventoryData['packages'] as List? ?? [];
      store.setSelectedServices(
        packages: packagesList.map((p) => PackageItem.fromJson(p)).toList(),
      );

      final engineeringList = inventoryData['engineering'] as List? ?? [];
      store.setSelectedServices(
        engineering: engineeringList.map((e) => EngineeringItem.fromJson(e)).toList(),
      );

      final servicesList = inventoryData['services'] as List? ?? [];
      store.setSelectedServices(
        services: servicesList.map((s) => ServiceItem.fromJson(s)).toList(),
      );

      print('✅ Services data loaded from API');
      print('Packages: ${store.selectedPackages.length}');
      print('Engineering: ${store.selectedEngineering.length}');
      print('Services: ${store.selectedServices.length}');
    } catch (e) {
      print('❌ Error loading services data: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<InventoryServicesStore>();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Expanded(child: _packagesTable(store)),
                const SizedBox(height: 8),
                const SizedBox(height: 4),
                Expanded(child: _engineeringTable(store)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Expanded(child: _servicesTable(store)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _packagesTable(InventoryServicesStore store) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: const Text(
              'PACKAGES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
              controller: _scrollController,
              itemCount: store.selectedPackages.length,
              itemBuilder: (context, index) {
                final pkg = store.selectedPackages[index];
                return _packageRow(pkg);
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _engineeringTable(InventoryServicesStore store) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: const Text(
              'ENGINEERING',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
              controller: _scrollController,
              itemCount: store.selectedEngineering.length,
              itemBuilder: (context, index) {
                final eng = store.selectedEngineering[index];
                return _engineeringRow(eng);
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _servicesTable(InventoryServicesStore store) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: const Text(
              'SERVICES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
              controller: _scrollController,
              itemCount: store.selectedServices.length,
              itemBuilder: (context, index) {
                final svc = store.selectedServices[index];
                return _serviceRow(svc);
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _packageRow(PackageItem pkg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _cell(pkg.name)),
          Expanded(flex: 2, child: _cell(pkg.price.toString())),
          Expanded(child: _checkboxCell(false, (v) {})),
        ],
      ),
    );
  }

  Widget _engineeringRow(EngineeringItem eng) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _cell(eng.name)),
          Expanded(flex: 2, child: _cell(eng.price.toString())),
          Expanded(child: _checkboxCell(false, (v) {})),
        ],
      ),
    );
  }

  Widget _serviceRow(ServiceItem svc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _cell(svc.name)),
          Expanded(flex: 2, child: _cell(svc.price.toString())),
          Expanded(child: _checkboxCell(false, (v) {})),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _checkboxCell(bool value, Function(bool) onChanged) {
    return Center(
      child: Obx(() => Transform.scale(
        scale: 0.75,
        child: Checkbox(
          value: value,
          onChanged: isLocked.value ? null : (v) => onChanged(v!),
          activeColor: AppTheme.successColor,
          checkColor: Colors.white,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      )),
    );
  }
}
