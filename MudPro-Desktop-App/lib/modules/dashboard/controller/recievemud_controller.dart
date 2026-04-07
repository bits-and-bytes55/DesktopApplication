import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/options/unit_sync_helpers.dart';

class ReceiveMudController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  final PitController pitController = Get.put(PitController());

  // Loading states
  final isLoading = false.obs;
  final isSaving = false.obs;

  // Form controllers
  final bolNoController = TextEditingController();
  final toController = TextEditingController();
  final volController = TextEditingController();
  final lossVolumeController = TextEditingController();

  // Checkbox states
  final isLeased = false.obs;
  final hasLossVolume = false.obs;

  // Dropdown data
  final premixedList = <PremixModel>[].obs;

  // Selected values
  final selectedPremixedId = ''.obs;
  final selectedPitId = ''.obs;

  // Selected objects
  final Rx<PremixModel?> selectedPremixed = Rx<PremixModel?>(null);
  final Rx<PitModel?> selectedPit = Rx<PitModel?>(null);

  // Well ID - replace with actual well ID from your system
  String get wellId => '507f1f77bcf86cd799439011';
  OptionsController? _optionsController;
  Worker? _unitSystemWorker;
  Worker? _customUnitsWorker;
  Map<String, String> _knownUnits = const {};
  
  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<OptionsController>()) {
      _optionsController = Get.find<OptionsController>();
      _knownUnits = _snapshotUnits();
      _unitSystemWorker = ever(_optionsController!.unitSystem, (_) => _syncDisplayedUnits());
      _customUnitsWorker = ever<Map<String, String>>(
        _optionsController!.customUnits,
        (_) => _syncDisplayedUnits(),
      );
    }
    _loadInitialData();
  }
  
  @override
  void onClose() {
    _unitSystemWorker?.dispose();
    _customUnitsWorker?.dispose();
    bolNoController.dispose();
    toController.dispose();
    volController.dispose();
    lossVolumeController.dispose();
    super.onClose();
  }
  
  // ================= LOAD INITIAL DATA =================

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await _loadPremixedMud();
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
      selectedPremixed.value = premixedList.firstWhere(
        (p) => p.id == premixedId,
      );
      print('✅ Selected premixed mud: ${selectedPremixed.value?.description}');
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
  
  Future<void> saveReceiveMud() async {
    // Validation
    if (bolNoController.text.isEmpty) {
      _showToast('BOL No. is required', isError: true);
      return;
    }
    
    if (selectedPremixed.value == null) {
      _showToast('Please select Premixed Mud', isError: true);
      return;
    }
    
    if (selectedPit.value == null) {
      _showToast('Please select From Pit', isError: true);
      return;
    }
    
    if (toController.text.isEmpty) {
      _showToast('To field is required', isError: true);
      return;
    }
    
    if (volController.text.isEmpty) {
      _showToast('Volume is required', isError: true);
      return;
    }
    
    if (hasLossVolume.value && lossVolumeController.text.isEmpty) {
      _showToast('Loss Volume is required when checked', isError: true);
      return;
    }
    
    isSaving.value = true;
    
    try {
      // Prepare data
      final data = {
        'bolNo': bolNoController.text,
        'premixedMudId': selectedPremixed.value!.id,
        'fromPitId': selectedPit.value!.id,
        'to': toController.text,
        'volume': double.tryParse(volController.text) ?? 0.0,
        'isLeased': isLeased.value,
        'lossVolume': hasLossVolume.value 
            ? (double.tryParse(lossVolumeController.text) ?? 0.0)
            : null,
        'wellId': wellId,
      };
      
      print('📤 Saving receive mud data: $data');
      
      // TODO: Implement API call to save receive mud
      // final result = await _repository.saveReceiveMud(data);
      
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));
      
      _showToast('Mud received successfully', isError: false);
      _clearForm();
      
    } catch (e) {
      print('❌ Error saving receive mud: $e');
      _showToast('Failed to save receive mud', isError: true);
    } finally {
      isSaving.value = false;
    }
  }
  
  // ================= CLEAR FORM =================
  
  void _clearForm() {
    bolNoController.clear();
    toController.clear();
    volController.clear();
    lossVolumeController.clear();
    
    selectedPremixedId.value = '';
    selectedPitId.value = '';
    selectedPremixed.value = null;
    selectedPit.value = null;
    
    isLeased.value = false;
    hasLossVolume.value = false;
  }
  
  // ================= REFRESH DATA =================
  
  Future<void> refreshData() async {
    await _loadInitialData();
    _showToast('Data refreshed', isError: false);
  }
  
  // ================= TOAST NOTIFICATIONS =================
  
  void _showToast(String message, {required bool isError}) {
    final overlay = Get.overlayContext;
    if (overlay == null) return;
    
    final overlayState = Overlay.of(overlay);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.red.shade600 : Colors.green.shade600,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Map<String, String> _snapshotUnits() {
    return AppUnits.snapshotUnits(const ['6', '33']);
  }

  void _syncDisplayedUnits() {
    final nextUnits = _snapshotUnits();
    if (_knownUnits.isEmpty) {
      _knownUnits = nextUnits;
      return;
    }

    for (final controller in [volController, lossVolumeController]) {
      UnitSyncHelpers.convertTextController(
        controller,
        fromUnit: _knownUnits['6'] ?? '(bbl)',
        toUnit: nextUnits['6'] ?? '(bbl)',
      );
    }

    for (var index = 0; index < premixedList.length; index++) {
      final item = premixedList[index];
      premixedList[index] = item.copyWith(
        mw: UnitSyncHelpers.convertRawText(
          item.mw,
          fromUnit: _knownUnits['33'] ?? '(ppg)',
          toUnit: nextUnits['33'] ?? '(ppg)',
        ),
      );
    }

    final currentSelected = selectedPremixed.value;
    if (currentSelected != null) {
      selectedPremixed.value = currentSelected.copyWith(
        mw: UnitSyncHelpers.convertRawText(
          currentSelected.mw,
          fromUnit: _knownUnits['33'] ?? '(ppg)',
          toUnit: nextUnits['33'] ?? '(ppg)',
        ),
      );
    }

    _knownUnits = nextUnits;
  }
}
