import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/formation_row_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/producst_model.dart'
    hide ProductModel;
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';

class UgController extends GetxController {
  final AuthRepository repository = AuthRepository();

  // Replace with actual well ID logic later
  String get wellId => '507f1f77bcf86cd799439011';

  // Right panel main tab
  final activeRightTab = 'pad'.obs;
  final location = 'Land'.obs;

  // Lock / Unlock
  final isLocked = true.obs;

  final inventoryTab = 'Products'.obs;

  // Products
  RxList<ProductModel> products = <ProductModel>[].obs;

  // Apply Changed Prices option
  final applyChangedPricesOption = 'To All'.obs;
  final fromDate = ''.obs;

  // Footer fields
  final bulkTankSetupFee = ''.obs;
  final taxRate = ''.obs;

  // REPORT TAB STATE
  final considerROP = true.obs;
  final considerRPM = true.obs;
  final considerEccentricity = false.obs;

  final multiRheology = false.obs;

  final safetyMargin = '80.0'.obs;

  // ================= FORMATION =================
  final poreFromTop = true.obs;

  /// Dropdown value (Density / Gradient / Pressure)
  final formationMode = 'Density'.obs;

  /// Formation table rows
  final formations = <FormationRow>[
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
  ].obs;

  /// Load premixed and OBM data from API
  Future<void> loadInventoryData(String wellId) async {
    try {
      // Load Premixed
      final premixedList = await repository.getPremixed(wellId);
      premixed.value = premixedList;

      // Load OBM
      final obmList = await repository.getObm(wellId);
      obm.value = obmList;

      debugPrint('âœ… Inventory data loaded successfully');
      debugPrint('Premixed count: ${premixedList.length}');
      debugPrint('OBM count: ${obmList.length}');
    } catch (e) {
      debugPrint('âŒ Error loading inventory data: $e');

      // Initialize with empty lists if loading fails
      if (premixed.isEmpty) {
        premixed.value = [];
      }
      if (obm.isEmpty) {
        obm.value = [];
      }
    }
  }

  var premixed = <PremixModel>[].obs;
  var obm = <ObmModel>[].obs;

  final packages = <PackageModel>[
    PackageModel('1', '', '', '', '', '', false),
  ].obs;

  final engineering = <EngineeringModel>[
    EngineeringModel('1', 'Mud Supervisor-1', '1', '1', '173.33', false),
    EngineeringModel('2', 'Mud Supervisor-2', '1', '1', '167.74', false),
    EngineeringModel('3', 'Mud Supervisor-3', '1', '1', '185.72', false),
    EngineeringModel('4', 'Mud Supervisor-4', '1', '1', '179.31', false),
  ].obs;

  final services = <ServiceModel>[ServiceModel('1', '', '', '', '', false)].obs;

  // final pumps = <PumpModel>[
  //   PumpModel(
  //     type: 'Triplex'.obs,
  //     model: 'BOMCO-F16'.obs,
  //     linerId: '6.500'.obs,
  //     rodOd: ''.obs,
  //     strokeLength: '12.000'.obs,
  //     efficiency: '95.0'.obs,
  //     displacement: '0.1170'.obs,
  //     maxPumpP: ''.obs,
  //     maxHp: ''.obs,
  //     surfaceLen: ''.obs,
  //     surfaceId: ''.obs,
  //   ),
  //   PumpModel(
  //     type: 'Triplex'.obs,
  //     model: 'BOMCO-F16'.obs,
  //     linerId: '6.000'.obs,
  //     rodOd: ''.obs,
  //     strokeLength: '12.000'.obs,
  //     efficiency: '97.0'.obs,
  //     displacement: '0.1018'.obs,
  //     maxPumpP: ''.obs,
  //     maxHp: ''.obs,
  //     surfaceLen: ''.obs,
  //     surfaceId: ''.obs,
  //   ),
  // ];

  // ================= SCE =================
  // final shakers = <ShakerModel>[
  //   ShakerModel(id: 1, shaker: '1', model: 'DERRICK # 1', screens: '4', plot: true),
  //   ShakerModel(id: 2, shaker: '2', model: 'DERRICK # 2', screens: '4', plot: true),
  //   ShakerModel(id: 10, shaker: 'Mud Cleaner', model: 'DERRICK # 3', screens: '4', plot: true),
  // ].obs;

  // final otherSce = <OtherSceModel>[
  //   OtherSceModel(type: 'Degasser', model1: 'CHENGDU', plot: true),
  //   OtherSceModel(type: 'Desander', model1: 'DERRICK', plot: true),
  //   OtherSceModel(type: 'Desilter', model1: 'DERRICK', plot: true),
  //   OtherSceModel(type: 'Centrifuge', model1: 'KEMTRON', plot: true),
  //   OtherSceModel(type: 'Barite Rec.', plot: false),
  // ];

  // ---------------- PIT DATA ----------------

  // final pits = <PitModel>[
  //   PitModel(id: 1, pit: 'TRIP TANK', capacity: '120.00', active: true),
  //   PitModel(id: 2, pit: 'SANDTRAP # 1A', capacity: '150.00', active: true),
  //   PitModel(id: 3, pit: 'SETTLING # 1B', capacity: '150.00', active: true),
  //   PitModel(id: 4, pit: 'DEGASSER # 1C', capacity: '150.00', active: true),
  //   PitModel(id: 5, pit: 'DESANDER # 2A', capacity: '170.00', active: true),
  //   PitModel(id: 6, pit: 'DESILTER # 2B', capacity: '170.00', active: true),
  //   PitModel(id: 7, pit: 'INT # 2C', capacity: '190.00', active: false),
  //   PitModel(id: 8, pit: 'INT # 3A', capacity: '190.00', active: false),
  //   PitModel(id: 9, pit: 'INT # 3B', capacity: '190.00', active: false),
  //   PitModel(id: 10, pit: 'INT # 3C', capacity: '100.00', active: false),
  //   PitModel(id: 11, pit: 'SUCTION # 4A', capacity: '315.00', active: true),
  //   PitModel(id: 12, pit: 'SUCTION # 4B', capacity: '315.00', active: true),
  //   PitModel(id: 13, pit: 'RES # 5A', capacity: '315.00', active: false),
  //   PitModel(id: 14, pit: 'RES # 5B', capacity: '315.00', active: false),
  //   PitModel(id: 15, pit: 'RES # 6A', capacity: '315.00', active: false),
  //   PitModel(id: 16, pit: 'RES # 6B', capacity: '315.00', active: false),
  // ].obs;

  // æ·»åŠ æ€»å®¹é‡å“åº”å¼å˜é‡
  final totalCapacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize with empty lists
    premixed.value = [];
    obm.value = [];

    fetchProducts();
  }

  // Fetch products from API
  Future<void> fetchProducts({
    int page = 1,
    String? search,
    String? group,
  }) async {
    try {
      final result = await repository.getProducts(
        page: page,
        limit: 100, // Get more products for inventory
        search: search,
        group: group,
      );

      if (result['success']) {
        final fetchedProducts = result['products'] as List<dynamic>;
        products.value = fetchedProducts.map((p) => p as ProductModel).toList();
      } else {
        Get.snackbar(
          'Error',
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch products: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Fetch packages from API
  Future<void> fetchPackages() async {
    try {
      final serviceController = ServiceController();
      final fetchedPackages = await serviceController.getPackages();
      packages.value = fetchedPackages
          .map(
            (item) => PackageModel(
              item.id ?? '',
              item.name,
              item.code,
              item.unit,
              item.price.toString(),
              '', // initial
              false, // tax
            ),
          )
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch packages: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Fetch engineering from API
  Future<void> fetchEngineering() async {
    try {
      final serviceController = ServiceController();
      final fetchedEngineering = await serviceController.getEngineering();
      engineering.value = fetchedEngineering
          .map(
            (item) => EngineeringModel(
              item.id ?? '',
              item.name,
              item.code,
              item.unit,
              item.price.toString(),
              false, // tax
            ),
          )
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch engineering: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Fetch services from API
  Future<void> fetchServices() async {
    try {
      final serviceController = ServiceController();
      final fetchedServices = await serviceController.getServices();
      services.value = fetchedServices
          .map(
            (item) => ServiceModel(
              item.id ?? '',
              item.name,
              item.code,
              item.unit,
              item.price.toString(),
              false, // tax
            ),
          )
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch services: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Fetch all services data
  Future<void> fetchServicesData() async {
    await Future.wait([fetchPackages(), fetchEngineering(), fetchServices()]);
  }

  // ================= è®¡ç®—æ€»å®¹é‡æ–¹æ³• =================
  // void updateTotalCapacity() {
  //   double sum = 0.0;

  //   for (var pit in pits) {
  //     // è§£æžå®¹é‡å­—ç¬¦ä¸²ä¸ºæ•°å­—
  //     final capacityStr = pit.capacity;
  //     if (capacityStr != null && capacityStr.isNotEmpty) {
  //       try {
  //         final capacityValue = double.tryParse(capacityStr);
  //         if (capacityValue != null) {
  //           sum += capacityValue;
  //         }
  //       } catch (e) {
  //         debugPrint('è§£æžå®¹é‡æ—¶å‡ºé”™: ${pit.pit} - $capacityStr');
  //       }
  //     }
  //   }

  //   totalCapacity.value = sum;
  // }

  // // ================= æ›´æ–°å•ä¸ªå‘çš„å®¹é‡ =================
  // void updatePitCapacity(int pitId, String newCapacity) {
  //   final pit = pits.firstWhereOrNull((p) => p.id == pitId);
  //   if (pit != null) {
  //     pit.capacity = newCapacity;
  //     updateTotalCapacity(); // æ›´æ–°æ€»å®¹é‡
  //   }
  // }

  // // ================= åˆ‡æ¢å‘çš„æ¿€æ´»çŠ¶æ€ =================
  // void togglePitActive(int pitId) {
  //   final pit = pits.firstWhereOrNull((p) => p.id == pitId);
  //   if (pit != null) {
  //     pit.active.value = !pit.active.value;
  //     // å¦‚æžœéœ€è¦ï¼Œå¯ä»¥æ ¹æ®æ¿€æ´»çŠ¶æ€æ›´æ–°æ€»å®¹é‡
  //     updateTotalCapacity();
  //   }
  // }

  // // ================= èŽ·å–æ¿€æ´»å‘çš„æ€»å®¹é‡ =================
  // double getActivePitsTotalCapacity() {
  //   double sum = 0.0;

  //   for (var pit in pits) {
  //     if (pit.active.value) {
  //       final capacityStr = pit.capacity;
  //       if (capacityStr != null && capacityStr.isNotEmpty) {
  //         try {
  //           final capacityValue = double.tryParse(capacityStr);
  //           if (capacityValue != null) {
  //             sum += capacityValue;
  //           }
  //         } catch (e) {
  //           debugPrint('è§£æžå®¹é‡æ—¶å‡ºé”™: ${pit.pit} - $capacityStr');
  //         }
  //       }
  //     }
  //   }

  //   return sum;
  // }

  // // ================= èŽ·å–æ¿€æ´»å‘çš„æ•°é‡ =================
  // int getActivePitsCount() {
  //   return pits.where((pit) => pit.active.value).length;
  // }

  // // ================= æ·»åŠ æ–°å‘ =================
  // void addNewPit(String pitName, String capacity, bool isActive) {
  //   final newId = pits.isNotEmpty ? pits.last.id! + 1 : 1;
  //   pits.add(PitModel(
  //     id: newId,
  //     pit: pitName,
  //     capacity: capacity,
  //     active: isActive,
  //   ));
  //   updateTotalCapacity();
  // }

  // // ================= åˆ é™¤å‘ =================
  // void removePit(int pitId) {
  //   pits.removeWhere((pit) => pit.id == pitId);
  //   updateTotalCapacity();
  // }

  void switchRightTab(String tab) {
    activeRightTab.value = tab;
  }

  void toggleLock() {
    isLocked.toggle();
  }
}
