import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/utils/alert_service.dart';
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
  
  // Auto-update / Data sync states
  final recordId = RxnString(null);
  Timer? _debounceTimer;
  bool _isProgrammaticUpdate = false;

  // Well ID 
  String get wellId => kControllerWellId;

  // =========== LIST STATE for history view ===========
  final receiveMudRecords = <Map<String, dynamic>>[].obs;
  final selectedRecordIndex = RxnInt(null);
  final isDeleting = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    
    // Attach autosave listeners
    bolNoController.addListener(triggerAutoSave);
    fromController.addListener(triggerAutoSave);
    volController.addListener(triggerAutoSave);
    lossVolumeController.addListener(triggerAutoSave);
    mwController.addListener(triggerAutoSave);
    mudTypeController.addListener(triggerAutoSave);
    leasingFeeController.addListener(triggerAutoSave);
    
    ever(selectedPremixedId, (_) => triggerAutoSave());
    ever(selectedToDestination, (_) => triggerAutoSave());
    ever(hasLossVolume, (_) => triggerAutoSave());
    
    _loadInitialData();
  }
  
  @override
  void onClose() {
    _debounceTimer?.cancel();
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
  
  // ================= DEBOUNCED AUTO SAVE =================
  
  void triggerAutoSave() {
    if (_isProgrammaticUpdate) return;
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _autoSaveReceiveMud();
    });
  }

  Future<void> _autoSaveReceiveMud() async {
    // If the core fields are removed, consider it a DELETE action
    if (selectedPremixed.value == null && 
        selectedToDestination.value.isEmpty && 
        bolNoController.text.isEmpty) {
      if (recordId.value != null) {
         try {
           final res = await _repository.deleteReceiveMud(wellId, recordId.value!);
           if (res['success'] == true) {
             print('✅ Automatically deleted cleared Receive Mud row');
             recordId.value = null;
           }
         } catch(e) {
           print('❌ Failed to auto-delete Receive Mud: $e');
         }
      }
      return; 
    }

    // Must have at least basic parameters to save logically
    if (selectedPremixed.value == null || selectedToDestination.value.isEmpty) {
      return; 
    }

    isSaving.value = true;
    try {
      final data = {
        'bolNo': bolNoController.text,
        'premixedMud': selectedPremixed.value!.description,
        'mw': mwController.text,
        'mudType': mudTypeController.text,
        'leasingFee': leasingFeeController.text,
        'from': fromController.text,
        'to': selectedToDestination.value,
        'volume': double.tryParse(volController.text) ?? 0.0,
        'leased': true,
        'lossVolume': hasLossVolume.value 
            ? (double.tryParse(lossVolumeController.text) ?? 0.0)
            : 0,
        'wellId': wellId,
      };

      if (recordId.value != null) {
         final res = await _repository.updateReceiveMud(wellId, recordId.value!, data);
         if (res['success'] == true) {
             print('✅ Auto-updated Receive Mud');
         }
      } else {
         final res = await _repository.createReceiveMud(wellId, data);
         if (res['success'] == true && res['data'] != null && res['data'].isNotEmpty) {
             final item = res['data'].firstWhere((e) => true, orElse: () => null); // data is an array
             if (item != null) recordId.value = item['_id'];
             print('✅ Auto-created Receive Mud');
         }
      }
    } catch (e) {
       print('❌ Error auto-saving Receive Mud: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ================= LOAD INITIAL DATA =================

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await _loadPremixedMud();
      await pitController.fetchUnselectedPits();
      await _loadReceiveMudData(); // FETCH SERVER STATE
    } catch (e) {
      _showToast('Failed to load data', isError: true);
      print('Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // ================= GET RECEIVE MUD LIST =================
  
  Future<void> _loadReceiveMudData() async {
    try {
      final res = await _repository.getReceiveMudList(wellId);
      if (res['success'] == true && res['data'] != null) {
        final raw = res['data'];
        final List items = (raw is Map && raw['data'] is List)
            ? raw['data']
            : (raw is List ? raw : []);
        receiveMudRecords.value = List<Map<String, dynamic>>.from(
            items.map((e) => Map<String, dynamic>.from(e as Map)));
        
        if (items.isNotEmpty) {
           _restoreFromRecord(items.first);
        }
      }
    } catch (e) {
       print('❌ Error fetching receive mud list: $e');
    } finally {
       _isProgrammaticUpdate = false;
    }
  }

  void _restoreFromRecord(Map<String, dynamic> item) {
    _isProgrammaticUpdate = true;
    recordId.value = item['_id'];
    bolNoController.text = item['bolNo'] ?? '';
    
    if (item['premixedMud'] != null && item['premixedMud'].toString().isNotEmpty) {
      try {
         final premix = premixedList.firstWhere(
           (p) => p.description.toLowerCase() == item['premixedMud'].toString().toLowerCase());
         selectedPremixedId.value = premix.id ?? '';
         selectedPremixed.value = premix;
      } catch(_) {}
    }
    
    mwController.text = item['mw']?.toString() ?? '';
    mudTypeController.text = item['mudType'] ?? '';
    leasingFeeController.text = item['leasingFee']?.toString() ?? '';
    fromController.text = item['from'] ?? '';
    selectedToDestination.value = item['to'] ?? '';
    volController.text = item['volume']?.toString() ?? '';
    isLeased.value = item['leased'] == true;
    hasLossVolume.value = (item['lossVolume'] ?? 0) > 0;
    lossVolumeController.text = item['lossVolume']?.toString() ?? '';
    _isProgrammaticUpdate = false;
    print('✅ Restored Receive Mud data into UI');
  }

  void loadRecord(int index) {
    if (index < 0 || index >= receiveMudRecords.length) return;
    selectedRecordIndex.value = index;
    _restoreFromRecord(receiveMudRecords[index]);
  }

  void deselectRecord() {
    selectedRecordIndex.value = null;
    _clearForm();
    recordId.value = null;
  }

  Future<void> deleteRecord(int index) async {
    if (index < 0 || index >= receiveMudRecords.length) return;
    final rec = receiveMudRecords[index];
    final id = rec['_id']?.toString();
    if (id == null) return;

    isDeleting.value = true;
    try {
      final res = await _repository.deleteReceiveMud(wellId, id);
      if (res['success'] == true) {
        receiveMudRecords.removeAt(index);
        // If we deleted the currently loaded record, clear the form
        if (recordId.value == id) {
          _clearForm();
          recordId.value = null;
          selectedRecordIndex.value = null;
        } else if (selectedRecordIndex.value != null) {
          if (selectedRecordIndex.value! >= receiveMudRecords.length) {
            selectedRecordIndex.value = null;
          }
        }
        _showToast('Record deleted', isError: false);
      } else {
        _showToast('Delete failed: ${res["message"]}', isError: true);
      }
    } catch (e) {
      _showToast('Error deleting: $e', isError: true);
    } finally {
      isDeleting.value = false;
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
      _isProgrammaticUpdate = true; // Temporary disable auto-sync while changing multiple params
      selectedPremixedId.value = premixedId;
      
      if (premixedId.isEmpty) {
         selectedPremixed.value = null;
         mwController.clear();
         mudTypeController.clear();
         leasingFeeController.clear();
      } else {
         final premixed = premixedList.firstWhere((p) => p.id == premixedId);
         selectedPremixed.value = premixed;
         
         // Auto-populate MW, Mud Type, Leasing Fee
         mwController.text = premixed.mw;
         mudTypeController.text = premixed.mudType;
         leasingFeeController.text = premixed.leasingFee;

         print('✅ Selected premixed mud: ${premixed.description}');
      }
    } catch (e) {
      print('❌ Error selecting premixed mud: $e');
      selectedPremixed.value = null;
    } finally {
      _isProgrammaticUpdate = false;
      triggerAutoSave();
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
  
  // ================= SAVE RECEIVE MUD (MANUAL BUTTON) =================
  
  Future<Map<String, dynamic>> saveReceiveMud() async {
    // This is essentially redundant since Auto-Save handles it, but kept for explicit saves
    if (selectedPremixed.value == null) {
      _showToast('Please select Premixed Mud', isError: true);
      return {'success': false, 'message': 'Please select Premixed Mud'};
    }
    
    if (selectedToDestination.value.isEmpty) {
      _showToast('To field is required', isError: true);
      return {'success': false, 'message': 'To field is required'};
    }
    
    await _autoSaveReceiveMud();
    
    if (recordId.value != null) {
       _showToast('Mud received successfully', isError: false);
       return {'success': true};
    } else {
       _showToast('Failed to explicitly save', isError: true);
       return {'success': false};
    }
  }
  
  // ================= CLEAR FORM =================
  
  void _clearForm() {
    _isProgrammaticUpdate = true;
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
    _isProgrammaticUpdate = false;
    
    triggerAutoSave(); // which evaluates deletion logic
  }
  
  // ================= REFRESH DATA =================
  
  Future<void> refreshData() async {
    await _loadInitialData();
    _showToast('Data refreshed', isError: false);
  }
  
  // ================= TOAST NOTIFICATIONS =================
  
  void _showToast(String message, {required bool isError}) {
    AlertService.show(message, isSuccess: !isError);
  }
}