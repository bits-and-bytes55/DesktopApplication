import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ReturnLostMudController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  Worker? _wellWorker;
  Worker? _reportWorker;
  final List<Worker> _autoSaveWorkers = <Worker>[];
  Timer? _autoSaveTimer;
  bool _isApplyingState = false;
  
  // Loading states
  final isLoading = false.obs;
  final isSaving = false.obs;
  final recordId = RxnString();
  
  // Premixed Mud checkbox
  final isPremixedMud = false.obs;
  
  // Form controllers
  final toController = TextEditingController();
  final volReturnedController = TextEditingController();
  final bolController = TextEditingController();
  final volLostController = TextEditingController();
  final costOfLostController = TextEditingController();
  
  // Checkbox states
  final isLeased = false.obs;
  
  // Dropdown data
  final premixedList = <PremixModel>[].obs;
  final pitsList = <PitModel>[].obs;
  
  // Selected values
  final selectedPremixedId = ''.obs;
  final selectedPitId = ''.obs;
  
  // Selected objects
  final Rx<PremixModel?> selectedPremixed = Rx<PremixModel?>(null);
  final Rx<PitModel?> selectedPit = Rx<PitModel?>(null);
  
  // Fetched MW and Mud Type
  final mw = ''.obs;
  final mudType = ''.obs;
  
  String? get wellId => currentBackendWellId.isEmpty ? null : currentBackendWellId;
   
  
  @override
  void onInit() {
    super.onInit();
    print('🚀 ReturnLostMudController initialized');
    toController.addListener(_scheduleAutoSave);
    volReturnedController.addListener(_scheduleAutoSave);
    bolController.addListener(_scheduleAutoSave);
    volLostController.addListener(_scheduleAutoSave);
    costOfLostController.addListener(_scheduleAutoSave);
    _autoSaveWorkers.addAll([
      ever<bool>(isPremixedMud, (_) => _scheduleAutoSave()),
      ever<bool>(isLeased, (_) => _scheduleAutoSave()),
      ever<String>(selectedPremixedId, (_) => _scheduleAutoSave()),
      ever<String>(selectedPitId, (_) => _scheduleAutoSave()),
    ]);
    _loadInitialData();
    _wellWorker = ever<String>(
      padWellContext.selectedWellId,
      (_) => _reloadForContext(),
    );
    _reportWorker = ever<String>(
      reportContext.selectedReportId,
      (_) => _reloadForContext(),
    );
  }
  
  @override
  void onClose() {
    _autoSaveTimer?.cancel();
    toController.dispose();
    volReturnedController.dispose();
    bolController.dispose();
    volLostController.dispose();
    costOfLostController.dispose();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _autoSaveWorkers) {
      worker.dispose();
    }
    super.onClose();
  }
  
  String _formatNumber(dynamic value, {int decimals = 2}) {
    final n = _parseNumber(value?.toString() ?? '');
    if (n == 0 && (value == null || value.toString().trim().isEmpty)) {
      return '';
    }
    return n.toStringAsFixed(decimals);
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0.0;
  }

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

  Future<void> _reloadForContext() async {
    _autoSaveTimer?.cancel();
    _isApplyingState = true;
    _clearForm();
    _isApplyingState = false;
    await _loadInitialData();
  }

  bool get _isReturnLostFormEmpty =>
      selectedPremixed.value == null &&
      selectedPit.value == null &&
      toController.text.trim().isEmpty &&
      volReturnedController.text.trim().isEmpty &&
      bolController.text.trim().isEmpty &&
      volLostController.text.trim().isEmpty &&
      costOfLostController.text.trim().isEmpty;

  bool get _hasAutoSavableData {
    if (_isReturnLostFormEmpty) {
      return recordId.value != null && recordId.value!.isNotEmpty;
    }
    final hasVolume =
        _parseNumber(volReturnedController.text) > 0 ||
        _parseNumber(volLostController.text) > 0;
    return selectedPremixed.value != null &&
        selectedPit.value != null &&
        toController.text.trim().isNotEmpty &&
        hasVolume;
  }

  void _scheduleAutoSave() {
    if (_isApplyingState ||
        isLoading.value ||
        isSaving.value ||
        !_hasAutoSavableData) {
      return;
    }
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 850), () async {
      if (_isApplyingState ||
          isLoading.value ||
          isSaving.value ||
          !_hasAutoSavableData) {
        return;
      }
      await saveReturnLostMud(silent: true);
    });
  }

  // ================= LOAD INITIAL DATA =================
  
  Future<void> _loadInitialData() async {
    _autoSaveTimer?.cancel();
    final currentWellId = wellId;
    print('📍 Using wellId: $currentWellId');
    
    if (currentWellId == null) {
      _showToast('Well ID not found', isError: true);
      return;
    }
    
    isLoading.value = true;
    _isApplyingState = true;
    try {
      await Future.wait([
        _loadPremixedMud(),
        _loadPits(),
      ]);
      await _loadExistingReturnLostMud();
    } catch (e) {
      _showToast('Failed to load data', isError: true);
      print('❌ Error loading initial data: $e');
    } finally {
      _isApplyingState = false;
      isLoading.value = false;
    }
  }

  Future<void> _loadExistingReturnLostMud() async {
    final currentWellId = wellId;
    if (currentWellId == null) return;

    try {
      final result = await _repository.getReturnLostMudList(currentWellId);
      if (result['success'] != true) return;

      final items = _extractList(result['data']);
      if (items.isEmpty) {
        _clearForm();
        return;
      }

      final item = Map<String, dynamic>.from(items.first as Map);
      recordId.value = (item['_id'] ?? item['id'] ?? '').toString();

      final premixedName = (item['premixedMud'] ?? '').toString().trim();
      isPremixedMud.value = premixedName.isNotEmpty;
      PremixModel? matchedPremixed;
      for (final premixed in premixedList) {
        if (premixed.description.trim().toLowerCase() ==
            premixedName.toLowerCase()) {
          matchedPremixed = premixed;
          break;
        }
      }
      if (matchedPremixed != null) {
        selectedPremixedId.value = matchedPremixed.id ?? '';
        selectedPremixed.value = matchedPremixed;
      }

      final fromName = (item['from'] ?? '').toString().trim();
      PitModel? matchedPit;
      for (final pit in pitsList) {
        if (pit.pitName.trim().toLowerCase() == fromName.toLowerCase()) {
          matchedPit = pit;
          break;
        }
      }
      if (matchedPit != null) {
        selectedPitId.value = matchedPit.id ?? '';
        selectedPit.value = matchedPit;
      }

      toController.text = (item['to'] ?? '').toString();
      volReturnedController.text = _formatNumber(item['volReturned']);
      bolController.text =
          _parseNumber(item['bol']?.toString() ?? '') == 0
              ? ''
              : _formatNumber(item['bol'], decimals: 0);
      volLostController.text = _formatNumber(item['volLost']);
      costOfLostController.text =
          _parseNumber(item['costOfLostPreTax']?.toString() ?? '') == 0
              ? ''
              : _formatNumber(item['costOfLostPreTax'], decimals: 2);
      mw.value = _formatNumber(item['mw']);
      mudType.value = (item['mudType'] ?? '').toString();
      isLeased.value = item['leased'] == true;
    } catch (e) {
      print('Error loading return/lost mud record: $e');
    }
  }

  Future<void> _refreshPitState() async {
    if (!Get.isRegistered<PitController>()) return;
    final pitCtrl = Get.find<PitController>();
    await pitCtrl.fetchAllPits();
    await pitCtrl.fetchSelectedPits();
    await pitCtrl.fetchUnselectedPits();
    await pitCtrl.fetchVolumeNameData();
  }
  
  // ================= LOAD PREMIXED MUD =================
  
  Future<void> _loadPremixedMud() async {
    final currentWellId = wellId;
    if (currentWellId == null) return;
    
    try {
      print('🔄 Loading premixed mud for wellId: $currentWellId');
      final result = await _repository.getPremixed(currentWellId);
      premixedList.value = result;
      print('✅ Loaded ${result.length} premixed mud entries');
      if (result.isNotEmpty) {
        print('📋 Premixed names: ${result.map((p) => p.description).join(", ")}');
      }
    } catch (e) {
      print('❌ Error loading premixed mud: $e');
      premixedList.clear();
    }
  }
  
  // ================= LOAD PITS =================
  
  Future<void> _loadPits() async {
    final currentWellId = wellId;
    if (currentWellId == null) {
      print('❌ Well ID is null, cannot load pits');
      return;
    }
    
    try {
      print('🔄 Loading pits for wellId: $currentWellId');
      final result = await _repository.getAllPits(currentWellId);
      
      print('📦 Pits API Response: $result');
      
      if (result['success'] == true) {
        final data = result['data'];
        
        if (data != null) {
          if (data is List) {
            if (data.isNotEmpty && data.first is PitModel) {
              pitsList.value = List<PitModel>.from(data);
            } else {
              pitsList.value = data
                  .map((item) => PitModel.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            
            print('✅ Loaded ${pitsList.length} pits successfully');
            if (pitsList.isNotEmpty) {
              print('📋 Pit names: ${pitsList.map((p) => p.pitName).join(", ")}');
            } else {
              print('⚠️ Pits list is empty');
            }
          } else {
            pitsList.clear();
            print('⚠️ Data is not a List, type: ${data.runtimeType}');
          }
        } else {
          pitsList.clear();
          print('⚠️ Data is null');
        }
      } else {
        pitsList.clear();
        print('❌ Failed to load pits: ${result['message']}');
        _showToast('Failed to load pits', isError: true);
      }
    } catch (e) {
      print('❌ Error loading pits: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      pitsList.clear();
      _showToast('Error loading pits: $e', isError: true);
    }
  }
  
  // ================= SELECT PREMIXED MUD =================
  
  void selectPremixed(String premixedId) {
    try {
      selectedPremixedId.value = premixedId;
      selectedPremixed.value = premixedList.firstWhere(
        (p) => p.id == premixedId,
      );
      
      // Update MW and Mud Type
      mw.value = _formatNumber(selectedPremixed.value?.mw);
      mudType.value = selectedPremixed.value?.mudType ?? '';
      _scheduleAutoSave();
      
      print('✅ Selected premixed mud: ${selectedPremixed.value?.description}');
      print('📊 MW: ${mw.value}, Mud Type: ${mudType.value}');
    } catch (e) {
      print('❌ Error selecting premixed mud: $e');
      selectedPremixed.value = null;
      mw.value = '';
      mudType.value = '';
    }
  }
  
  // ================= SELECT PIT =================
  
  void selectPit(String pitId) {
    try {
      selectedPitId.value = pitId;
      selectedPit.value = pitsList.firstWhere(
        (p) => p.id == pitId,
      );
      _scheduleAutoSave();
      print('✅ Selected pit: ${selectedPit.value?.pitName}');
    } catch (e) {
      print('❌ Error selecting pit: $e');
      selectedPit.value = null;
    }
  }
  
  // ================= SAVE RETURN/LOST MUD =================
  
  Future<Map<String, dynamic>> saveReturnLostMud({bool silent = false}) async {
    _autoSaveTimer?.cancel();
    final currentWellId = wellId;
    if (currentWellId == null) {
      if (!silent) _showToast('Well ID not found', isError: true);
      return {'success': false, 'message': 'Well ID not found'};
    }

    if (_isReturnLostFormEmpty) {
      if (recordId.value == null || recordId.value!.isEmpty) {
        if (!silent) {
          _showToast('No Return / Lost Mud data to save', isError: false);
        }
        return {'success': true, 'message': 'No Return / Lost Mud data to save'};
      }

      isSaving.value = true;
      try {
        final deleteResult = await _repository.deleteReturnLostMud(
          currentWellId,
          recordId.value!,
        );
        if (deleteResult['success'] == true) {
          _clearForm();
          await _refreshPitState();
          if (!silent) _showToast('Data deleted successfully', isError: false);
          return {
            'success': true,
            'message': 'Return / Lost Mud deleted successfully',
          };
        } else {
          if (!silent) {
            _showToast(
              deleteResult['message'] ?? 'Failed to delete data',
              isError: true,
            );
          }
          return {
            'success': false,
            'message': deleteResult['message'] ?? 'Failed to delete data',
          };
        }
      } catch (e) {
        print('Error deleting return/lost mud: $e');
        if (!silent) _showToast('Failed to delete data', isError: true);
        return {'success': false, 'message': 'Failed to delete data'};
      } finally {
        isSaving.value = false;
      }
    }

    // Validation
    if (selectedPremixed.value == null) {
      if (!silent) _showToast('Please select Premixed Mud', isError: true);
      return {'success': false, 'message': 'Please select Premixed Mud'};
    }
    
    if (selectedPit.value == null) {
      if (!silent) _showToast('Please select From Pit', isError: true);
      return {'success': false, 'message': 'Please select From Pit'};
    }
    
    if (toController.text.isEmpty) {
      if (!silent) _showToast('To field is required', isError: true);
      return {'success': false, 'message': 'To field is required'};
    }
    
    final returnedVolume = _parseNumber(volReturnedController.text);
    final lostVolume = _parseNumber(volLostController.text);

    if (returnedVolume <= 0 && lostVolume <= 0) {
      if (!silent) {
        _showToast('Returned or Lost volume is required', isError: true);
      }
      return {
        'success': false,
        'message': 'Returned or Lost volume is required',
      };
    }
    
    isSaving.value = true;
    
    try {
      // Prepare data
      final data = {
        'premixedMud': selectedPremixed.value?.description ?? '',
        'from': selectedPit.value!.pitName,
        'to': toController.text,
        'volReturned': returnedVolume,
        'mw': _parseNumber(mw.value),
        'mudType': mudType.value,
        'bol': _parseNumber(bolController.text),
        'volLost': lostVolume,
        'costOfLostPreTax': costOfLostController.text.trim().isEmpty
            ? ''
            : _parseNumber(costOfLostController.text),
        'leased': isLeased.value,
      };
      
      print('📤 Saving return/lost mud data: $data');
      
      final result = recordId.value != null && recordId.value!.isNotEmpty
          ? await _repository.updateReturnLostMud(
              currentWellId,
              recordId.value!,
              data,
            )
          : await _repository.createReturnLostMud(currentWellId, data);
      if (result['success'] != true) {
        if (!silent) {
          _showToast(result['message'] ?? 'Failed to save data', isError: true);
        }
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to save data',
        };
      }

      final savedData = _extractEntity(result['data']);
      if (savedData != null) {
        recordId.value =
            (savedData['_id'] ?? savedData['id'] ?? '').toString();
      }

      await _refreshPitState();
      if (!silent) _showToast('Data saved successfully', isError: false);
      return {
        'success': true,
        'message': 'Return / Lost Mud saved successfully',
      };
      
    } catch (e) {
      print('❌ Error saving return/lost mud: $e');
      if (!silent) _showToast('Failed to save data', isError: true);
      return {'success': false, 'message': 'Failed to save data'};
    } finally {
      isSaving.value = false;
    }
  }
  
  // ================= CLEAR FORM =================
  
  void _clearForm() {
    isPremixedMud.value = false;
    toController.clear();
    volReturnedController.clear();
    bolController.clear();
    volLostController.clear();
    costOfLostController.clear();
    
    selectedPremixedId.value = '';
    selectedPitId.value = '';
    selectedPremixed.value = null;
    selectedPit.value = null;
    recordId.value = null;
    
    mw.value = '';
    mudType.value = '';
    isLeased.value = false;
  }
  
  // ================= REFRESH DATA =================
  
  Future<void> refreshData() async {
    await _loadInitialData();
    _showToast('Data refreshed', isError: false);
  }
  
  // ================= TOAST NOTIFICATIONS =================
  
  void _showToast(String message, {required bool isError}) {
    try {
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
    } catch (e) {
      debugPrint('Return / Lost Mud toast skipped: $message ($e)');
    }
  }
}
