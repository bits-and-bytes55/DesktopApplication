import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';

class ReturnLostMudController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  
  // Loading states
  final isLoading = false.obs;
  final isSaving = false.obs;
  
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
  
  // Get wellId from DashboardController
  String? get wellId => "507f1f77bcf86cd799439011"; // Fallback
   
  
  @override
  void onInit() {
    super.onInit();
    print('🚀 ReturnLostMudController initialized');
    _loadInitialData();
  }
  
  @override
  void onClose() {
    toController.dispose();
    volReturnedController.dispose();
    bolController.dispose();
    volLostController.dispose();
    costOfLostController.dispose();
    super.onClose();
  }
  
  // ================= LOAD INITIAL DATA =================
  
  Future<void> _loadInitialData() async {
    final currentWellId = wellId;
    print('📍 Using wellId: $currentWellId');
    
    if (currentWellId == null) {
      _showToast('Well ID not found', isError: true);
      return;
    }
    
    isLoading.value = true;
    try {
      await Future.wait([
        _loadPremixedMud(),
        _loadPits(),
      ]);
    } catch (e) {
      _showToast('Failed to load data', isError: true);
      print('❌ Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
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
      mw.value = selectedPremixed.value?.mw ?? '';
      mudType.value = selectedPremixed.value?.mudType ?? '';
      
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
      print('✅ Selected pit: ${selectedPit.value?.pitName}');
    } catch (e) {
      print('❌ Error selecting pit: $e');
      selectedPit.value = null;
    }
  }
  
  // ================= SAVE RETURN/LOST MUD =================
  
  Future<void> saveReturnLostMud() async {
    // Validation
    if (isPremixedMud.value && selectedPremixed.value == null) {
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
    
    if (volReturnedController.text.isEmpty) {
      _showToast('Volume Returned is required', isError: true);
      return;
    }
    
    final currentWellId = wellId;
    if (currentWellId == null) {
      _showToast('Well ID not found', isError: true);
      return;
    }
    
    isSaving.value = true;
    
    try {
      // Prepare data
      final data = {
        'isPremixedMud': isPremixedMud.value,
        'premixedMudId': isPremixedMud.value ? selectedPremixed.value?.id : null,
        'fromPitId': selectedPit.value!.id,
        'to': toController.text,
        'volumeReturned': double.tryParse(volReturnedController.text) ?? 0.0,
        'mw': mw.value,
        'mudType': mudType.value,
        'bol': bolController.text,
        'volumeLost': double.tryParse(volLostController.text) ?? 0.0,
        'costOfLost': double.tryParse(costOfLostController.text) ?? 0.0,
        'isLeased': isLeased.value,
        'wellId': currentWellId,
      };
      
      print('📤 Saving return/lost mud data: $data');
      
      // TODO: Implement API call to save return/lost mud
      // final result = await _repository.saveReturnLostMud(data);
      
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));
      
      _showToast('Data saved successfully', isError: false);
      _clearForm();
      
    } catch (e) {
      print('❌ Error saving return/lost mud: $e');
      _showToast('Failed to save data', isError: true);
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
}