import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';

class ReceiveMudController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  final PitController pitController = Get.put(PitController());

  // Loading states
  final isLoading = false.obs;
  final isSaving = false.obs;

  // Form controllers
  final bolNoController = TextEditingController();
  final fromController = TextEditingController(); // From: manual text input
  final toController = TextEditingController();
  final volController = TextEditingController();
  final lossVolumeController = TextEditingController();
  final mwController = TextEditingController();
  final mudTypeController = TextEditingController();
  final leasingFeeController = TextEditingController();

  // To dropdown selection
  final selectedToDestination = ''.obs;

  // Checkbox states
  final isLeased = true.obs;
  final hasLossVolume = false.obs;

  // Dropdown data
  final premixedList = <PremixModel>[].obs;
  final obmRows = <ObmModel>[].obs; // For concentration dialog

  // Selected values
  final selectedPremixedId = ''.obs;
  final selectedPitId = ''.obs;

  // Selected objects
  final Rx<PremixModel?> selectedPremixed = Rx<PremixModel?>(null);
  final Rx<PitModel?> selectedPit = Rx<PitModel?>(null);

  // Well ID 
  String get wellId => '507f1f77bcf86cd799439011';
  
  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }
  
  @override
  void onClose() {
    bolNoController.dispose();
    fromController.dispose();
    toController.dispose();
    volController.dispose();
    lossVolumeController.dispose();
    mwController.dispose();
    mudTypeController.dispose();
    leasingFeeController.dispose();
    super.onClose();
  }
  
  // ================= LOAD INITIAL DATA =================

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await _loadPremixedMud();
      await pitController.fetchUnselectedPits();
    } catch (e) {
      _showToast('Failed to load data', isError: true);
      print('Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // ================= LOAD PREMIXED MUD =================
  
  Future<void> _loadPremixedMud() async {
    try {
      final result = await _repository.getPremixed(wellId);
      premixedList.value = result;
      print('✅ Loaded ${result.length} premixed mud entries');
    } catch (e) {
      print('❌ Error loading premixed mud: $e');
      premixedList.clear();
    }
  }
  

  
  // ================= SELECT PREMIXED MUD =================
  
  void selectPremixed(String premixedId) {
    try {
      selectedPremixedId.value = premixedId;
      final premixed = premixedList.firstWhere((p) => p.id == premixedId);
      selectedPremixed.value = premixed;
      
      // Auto-populate MW, Mud Type, Leasing Fee
      mwController.text = premixed.mw;
      mudTypeController.text = premixed.mudType;
      leasingFeeController.text = premixed.leasingFee;

      print('✅ Selected premixed mud: ${premixed.description}');
    } catch (e) {
      print('❌ Error selecting premixed mud: $e');
      selectedPremixed.value = null;
    }
  }
  
  // ================= SELECT PIT =================

  void selectPit(String pitId) {
    try {
      selectedPitId.value = pitId;
      selectedPit.value = pitController.pits.firstWhere(
        (p) => p.id == pitId,
      );
      print('✅ Selected pit: ${selectedPit.value?.pitName}');
    } catch (e) {
      print('❌ Error selecting pit: $e');
      selectedPit.value = null;
    }
  }
  
  // ================= SAVE RECEIVE MUD =================
  
  Future<Map<String, dynamic>> saveReceiveMud() async {
    // Validation
    if (selectedPremixed.value == null) {
      _showToast('Please select Premixed Mud', isError: true);
      return {'success': false, 'message': 'Please select Premixed Mud'};
    }
    
    if (selectedToDestination.value.isEmpty) {
      _showToast('To field is required', isError: true);
      return {'success': false, 'message': 'To field is required'};
    }
    
    isSaving.value = true;
    
    try {
      // Prepare data
      final data = {
        'bolNo': bolNoController.text,
        'premixedMud': selectedPremixed.value!.description,
        'mw': mwController.text,
        'mudType': mudTypeController.text,
        'leasingFee': leasingFeeController.text,
        'from': fromController.text,
        'to': selectedToDestination.value,
        'volume': double.tryParse(volController.text) ?? 0.0,
        'leased': true, // Always true since UI is locked to true
        'lossVolume': hasLossVolume.value 
            ? (double.tryParse(lossVolumeController.text) ?? 0.0)
            : 0,
        'wellId': wellId,
      };
      
      print('📤 Saving receive mud data: $data');
      
      // Perform API call
      final result = await _repository.createReceiveMud(wellId, data);
      
      if (result['success'] == true) {
        _showToast('Mud received successfully', isError: false);
        _clearForm();
      } else {
        _showToast('Failed to save: ${result['message']}', isError: true);
      }
      
      return result;
    } catch (e) {
      print('❌ Error saving receive mud: $e');
      _showToast('Failed to save receive mud', isError: true);
      return {'success': false, 'message': e.toString()};
    } finally {
      isSaving.value = false;
    }
  }
  
  // ================= CLEAR FORM =================
  
  void _clearForm() {
    bolNoController.clear();
    fromController.clear();
    toController.clear();
    volController.clear();
    lossVolumeController.clear();
    mwController.clear();
    mudTypeController.clear();
    leasingFeeController.clear();
    
    selectedPremixedId.value = '';
    selectedPitId.value = '';
    selectedPremixed.value = null;
    selectedPit.value = null;
    selectedToDestination.value = '';
    
    isLeased.value = true;
    hasLossVolume.value = false;
  }
  
  // ================= REFRESH DATA =================
  
  Future<void> refreshData() async {
    await _loadInitialData();
    _showToast('Data refreshed', isError: false);
  }
  
  // ================= TOAST NOTIFICATIONS =================
  
  void _showToast(String message, {required bool isError}) {
    Get.snackbar(
      isError ? 'Error' : 'Success',
      message,
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.only(top: 16, right: 16, left: 200),
      duration: const Duration(seconds: 3),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}