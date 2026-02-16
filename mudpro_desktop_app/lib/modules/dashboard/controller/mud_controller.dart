import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';

class MudController extends GetxController {
  final samples = ['1', '2', '3', 'Plan-L', 'Plan-H'];
  
  // Controller instance
  final othersController = OthersController();

  /// Fluid Type
  var selectedFluidType = 'Water-based'.obs;
  
  /// LEFT TABLE DATA - Dynamic based on fluid type
  final propertyTable = <String, List<RxString>>{}.obs;

  /// RIGHT TABLE DATA - Rheology
  final rheologyTable = <String, List<RxString>>{}.obs;

  var rheologyModel = 'Bingham'.obs;
  
  // Checkboxes
  var isCompletionFluid = false.obs;
  var isWeightedMud = false.obs;

  final fluidnameController = TextEditingController();
  
  // Loading state
  var isLoading = false.obs;

  @override
  void onInit() {
    _initRheologyTable();
    loadFluidTypeData(); // Load initial data
    super.onInit();
  }

  /// Load data based on selected fluid type
  Future<void> loadFluidTypeData() async {
    isLoading.value = true;
    
    try {
      propertyTable.clear();
      
      if (selectedFluidType.value == 'Water-based') {
        await _loadWaterBasedData();
      } else if (selectedFluidType.value == 'Oil-based') {
        await _loadOilBasedData();
      } else if (selectedFluidType.value == 'Synthetic') {
        await _loadSyntheticData();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Load Water-based data
  Future<void> _loadWaterBasedData() async {
    final data = await othersController.getWaterBased();
    
    // Common fields for all types
    _addCommonFields();
    
    // Add Water-based specific fields
    for (var item in data) {
      if (item.name != null && item.name!.isNotEmpty) {
        propertyTable[item.name!] = List.generate(
          samples.length, 
          (_) => ''.obs,
        );
      }
    }
  }

  /// Load Oil-based data
  Future<void> _loadOilBasedData() async {
    final data = await othersController.getOilBased();
    
    // Common fields for all types
    _addCommonFields();
    
    // Add Oil-based specific fields
    for (var item in data) {
      if (item.name != null && item.name!.isNotEmpty) {
        propertyTable[item.name!] = List.generate(
          samples.length, 
          (_) => ''.obs,
        );
      }
    }
  }

  /// Load Synthetic data
  Future<void> _loadSyntheticData() async {
    final data = await othersController.getSynthetic();
    
    // Common fields for all types
    _addCommonFields();
    
    // Add Synthetic specific fields
    for (var item in data) {
      if (item.name != null && item.name!.isNotEmpty) {
        propertyTable[item.name!] = List.generate(
          samples.length, 
          (_) => ''.obs,
        );
      }
    }
  }

  /// Add common fields that appear in all fluid types
  void _addCommonFields() {
    final commonFields = [
      'Description',
      'Sample from',
      'Time Sample Taken (hh:mm)',
    ];
    
    for (var field in commonFields) {
      propertyTable[field] = List.generate(
        samples.length, 
        (_) => ''.obs,
      );
    }
  }

  void _initRheologyTable() {
    _updateRheologyRows();
  }

  void changeFluidType(String type) {
    selectedFluidType.value = type;
    loadFluidTypeData();
  }

  void changeModel(String model) {
    rheologyModel.value = model;
    _updateRheologyRows();
  }

  void _updateRheologyRows() {
    final rows = rheologyModel.value == 'Bingham'
        ? ['600', '300', '200', '100', '6', '3', 'PV (cp)', 'YP (lb/100ft²)']
        : rheologyModel.value == 'Power Law'
            ? ['600', '300', '200', '100', '6', '3', 'n', 'K (lbf-s^n/100ft2)']
            : ['600', '300', '200', '100', '6', '3', 'Yield Stress (lbf/100ft2)', 'n', 'K (lbf-s^n/100ft2)'];

    rheologyTable.clear();
    for (var r in rows) {
      rheologyTable[r] = List.generate(samples.length, (_) => ''.obs);
    }
  }

  @override
  void onClose() {
    fluidnameController.dispose();
    super.onClose();
  }
}