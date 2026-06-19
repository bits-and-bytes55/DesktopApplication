import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ReceiveMudController extends GetxController {
  ReceiveMudController({required this.instanceKey});

  final String instanceKey;
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
  Worker? _wellWorker;
  Worker? _reportWorker;
  bool _isProgrammaticUpdate = false;

  // Well ID 
  String get wellId => currentBackendWellId;
  
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

    _wellWorker = ever<String>(
      padWellContext.selectedWellId,
      (_) => _reloadForContext(),
    );
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => _reloadForContext(),
    );
    
    _loadInitialData();
  }
  
  @override
  void onClose() {
    _debounceTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
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

  String _formatNumber(dynamic value, {int decimals = 2}) {
    final n = _parseNumber(value?.toString() ?? '');
    if (n == 0) {
      return '';
    }
    return n.toStringAsFixed(decimals);
  }

  double _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0.0;

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map && value['data'] is List) return value['data'] as List;
    return const [];
  }

  Map<String, dynamic>? _extractEntity(dynamic value) {
    final list = _extractList(value);
    if (list.isNotEmpty && list.first is Map) {
      return Map<String, dynamic>.from(list.first as Map);
    }
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  bool _belongsToThisInstance(Map<String, dynamic> item) {
    final key = (item['operationInstanceKey'] ?? '').toString().trim();
    if (key == instanceKey) return true;
    return key.isEmpty && instanceKey == 'receiveMud::legacy0';
  }

  void _resetLoadedState() {
    _isProgrammaticUpdate = true;
    recordId.value = null;
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
  }

  Future<void> _reloadForContext() async {
    _debounceTimer?.cancel();
    _resetLoadedState();
    await _loadInitialData();
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
    if (wellId.isEmpty) return;
    final volume = _parseNumber(volController.text);
    final lossVolume = hasLossVolume.value
        ? _parseNumber(lossVolumeController.text)
        : 0.0;

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
             await pitController.fetchVolumeNameData();
           }
         } catch(e) {
           print('❌ Failed to auto-delete Receive Mud: $e');
         }
      }
      return; 
    }

    // Must have at least basic parameters to save logically
    if (selectedPremixed.value == null ||
        selectedToDestination.value.isEmpty ||
        volume <= 0) {
      return; 
    }

    isSaving.value = true;
    try {
      final data = {
        'bolNo': bolNoController.text,
        'premixedMud': selectedPremixed.value!.description,
        'mw': _parseNumber(mwController.text),
        'mudType': mudTypeController.text,
        'leasingFee': _parseNumber(leasingFeeController.text),
        'from': fromController.text,
        'to': selectedToDestination.value,
        'volume': volume,
        'leased': true,
        'lossVolume': lossVolume,
        'wellId': wellId,
        'operationInstanceKey': instanceKey,
      };

      if (recordId.value != null) {
         final res = await _repository.updateReceiveMud(wellId, recordId.value!, data);
         if (res['success'] == true) {
             await pitController.fetchVolumeNameData();
             print('✅ Auto-updated Receive Mud');
         }
      } else {
         final res = await _repository.createReceiveMud(wellId, data);
         if (res['success'] == true && res['data'] != null) {
             final item = _extractEntity(res['data']);
             if (item != null) recordId.value = item['_id']?.toString();
             await pitController.fetchVolumeNameData();
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
    if (wellId.isEmpty) return;
    try {
      final res = await _repository.getReceiveMudList(wellId);
      if (res['success'] == true && res['data'] != null) {
        final items = _extractList(res['data']);
        final matchingItems = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where(_belongsToThisInstance)
            .toList();
        if (matchingItems.isNotEmpty) {
           final item = matchingItems.first;
           _isProgrammaticUpdate = true;
           
           recordId.value = item['_id']?.toString();
           bolNoController.text = item['bolNo'] ?? '';
           
           if (item['premixedMud'] != null && item['premixedMud'].toString().isNotEmpty) {
             try {
                final premix = premixedList.firstWhere((p) => p.description.toLowerCase() == item['premixedMud'].toString().toLowerCase());
                selectedPremixedId.value = premix.id ?? '';
                selectedPremixed.value = premix;
             } catch(_) {}
           }
           
           mwController.text = _formatNumber(item['mw'], decimals: 2);
           mudTypeController.text = item['mudType'] ?? '';
           leasingFeeController.text =
               _formatNumber(item['leasingFee'], decimals: 3);
           fromController.text = item['from'] ?? '';
           selectedToDestination.value = item['to'] ?? '';
           volController.text = _formatNumber(item['volume'], decimals: 2);
           isLeased.value = item['leased'] == true;
           hasLossVolume.value = (item['lossVolume'] ?? 0) > 0;
           lossVolumeController.text =
               _formatNumber(item['lossVolume'], decimals: 2);
           
           _isProgrammaticUpdate = false;
           print('✅ Restored Receive Mud data into UI');
        } else {
           _resetLoadedState();
        }
      }
    } catch (e) {
       print('❌ Error fetching receive mud list: $e');
    } finally {
       _isProgrammaticUpdate = false;
    }
  }

  // ================= LOAD PREMIXED MUD =================
  
  Future<void> _loadPremixedMud() async {
    if (wellId.isEmpty) return;
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
         mwController.text = _formatNumber(premixed.mw, decimals: 2);
         mudTypeController.text = premixed.mudType;
         leasingFeeController.text =
             _formatNumber(premixed.leasingFee, decimals: 3);

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

    if (_parseNumber(volController.text) <= 0) {
      _showToast('Vol. must be greater than 0', isError: true);
      return {'success': false, 'message': 'Vol. must be greater than 0'};
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
