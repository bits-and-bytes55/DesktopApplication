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

  String? get wellId =>
      currentBackendWellId.isEmpty ? null : currentBackendWellId;
  String? get _currentReportId {
    final reportId = reportContext.selectedReportId.value.trim();
    return reportId.isEmpty ? null : reportId;
  }

  @override
  void onInit() {
    super.onInit();
    print('🚀 ReturnLostMudController initialized');
    _loadInitialData();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      _clearForm();
      _loadInitialData();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      _clearForm();
      _loadInitialData();
    });
  }

  @override
  void onClose() {
    toController.dispose();
    volReturnedController.dispose();
    bolController.dispose();
    volLostController.dispose();
    costOfLostController.dispose();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
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
      await Future.wait([_loadPremixedMud(), _loadPits()]);
      await _loadExistingReturnLostMud();
    } catch (e) {
      _showToast('Failed to load data', isError: true);
      print('❌ Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadExistingReturnLostMud() async {
    final currentWellId = wellId;
    if (currentWellId == null) return;

    try {
      final result = await _repository.getReturnLostMudList(
        currentWellId,
        reportId: _currentReportId,
      );
      if (result['success'] != true) return;

      final envelope = result['data'];
      final data = envelope is Map<String, dynamic>
          ? envelope['data']
          : envelope is Map
          ? Map<String, dynamic>.from(envelope)['data']
          : null;
      final items = data is List ? data : const [];
      if (items.isEmpty) {
        recordId.value = null;
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
      volReturnedController.text = (item['volReturned'] ?? '').toString();
      bolController.text = (item['bol'] ?? '').toString();
      volLostController.text = (item['volLost'] ?? '').toString();
      costOfLostController.text = (item['costOfLostPreTax'] ?? '').toString();
      mw.value = (item['mw'] ?? '').toString();
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
        print(
          '📋 Premixed names: ${result.map((p) => p.description).join(", ")}',
        );
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
      final result = await _repository.getAllPits(
        currentWellId,
        reportId: reportContext.selectedReportId.value.trim().isEmpty
            ? null
            : reportContext.selectedReportId.value.trim(),
      );

      print('📦 Pits API Response: $result');

      if (result['success'] == true) {
        final data = result['data'];

        if (data != null) {
          if (data is List) {
            if (data.isNotEmpty && data.first is PitModel) {
              pitsList.value = List<PitModel>.from(data);
            } else {
              pitsList.value = data
                  .map(
                    (item) => PitModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
            }

            print('✅ Loaded ${pitsList.length} pits successfully');
            if (pitsList.isNotEmpty) {
              print(
                '📋 Pit names: ${pitsList.map((p) => p.pitName).join(", ")}',
              );
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
      selectedPit.value = pitsList.firstWhere((p) => p.id == pitId);
      print('✅ Selected pit: ${selectedPit.value?.pitName}');
    } catch (e) {
      print('❌ Error selecting pit: $e');
      selectedPit.value = null;
    }
  }

  // ================= SAVE RETURN/LOST MUD =================

  Future<Map<String, dynamic>> saveReturnLostMud() async {
    final currentWellId = wellId;
    if (currentWellId == null) {
      _showToast('Well ID not found', isError: true);
      return {'success': false, 'message': 'Well ID not found'};
    }

    final isFormEmpty =
        selectedPremixed.value == null &&
        selectedPit.value == null &&
        toController.text.trim().isEmpty &&
        volReturnedController.text.trim().isEmpty &&
        bolController.text.trim().isEmpty &&
        volLostController.text.trim().isEmpty &&
        costOfLostController.text.trim().isEmpty;

    if (isFormEmpty) {
      if (recordId.value == null || recordId.value!.isEmpty) {
        _showToast('No Return / Lost Mud data to save', isError: false);
        return {
          'success': true,
          'message': 'No Return / Lost Mud data to save',
        };
      }

      isSaving.value = true;
      try {
        final deleteResult = await _repository.deleteReturnLostMud(
          currentWellId,
          recordId.value!,
          reportId: _currentReportId,
        );
        if (deleteResult['success'] == true) {
          _clearForm();
          await _refreshPitState();
          _showToast('Data deleted successfully', isError: false);
          return {
            'success': true,
            'message': 'Return / Lost Mud deleted successfully',
          };
        } else {
          _showToast(
            deleteResult['message'] ?? 'Failed to delete data',
            isError: true,
          );
          return {
            'success': false,
            'message': deleteResult['message'] ?? 'Failed to delete data',
          };
        }
      } catch (e) {
        print('Error deleting return/lost mud: $e');
        _showToast('Failed to delete data', isError: true);
        return {'success': false, 'message': 'Failed to delete data'};
      } finally {
        isSaving.value = false;
      }
    }

    // Validation
    if (selectedPremixed.value == null) {
      _showToast('Please select Premixed Mud', isError: true);
      return {'success': false, 'message': 'Please select Premixed Mud'};
    }

    if (selectedPit.value == null) {
      _showToast('Please select From Pit', isError: true);
      return {'success': false, 'message': 'Please select From Pit'};
    }

    if (toController.text.isEmpty) {
      _showToast('To field is required', isError: true);
      return {'success': false, 'message': 'To field is required'};
    }

    if (volReturnedController.text.isEmpty) {
      _showToast('Volume Returned is required', isError: true);
      return {'success': false, 'message': 'Volume Returned is required'};
    }

    isSaving.value = true;

    try {
      // Prepare data
      final data = {
        'premixedMud': selectedPremixed.value?.description ?? '',
        'from': selectedPit.value!.pitName,
        'to': toController.text,
        'volReturned': double.tryParse(volReturnedController.text) ?? 0.0,
        'mw': double.tryParse(mw.value) ?? 0.0,
        'mudType': mudType.value,
        'bol': double.tryParse(bolController.text) ?? 0.0,
        'volLost': double.tryParse(volLostController.text) ?? 0.0,
        'costOfLostPreTax': double.tryParse(costOfLostController.text) ?? 0.0,
        'leased': isLeased.value,
        if (_currentReportId != null) 'reportId': _currentReportId,
      };

      print('📤 Saving return/lost mud data: $data');

      final result = recordId.value != null && recordId.value!.isNotEmpty
          ? await _repository.updateReturnLostMud(
              currentWellId,
              recordId.value!,
              data,
              reportId: _currentReportId,
            )
          : await _repository.createReturnLostMud(
              currentWellId,
              data,
              reportId: _currentReportId,
            );
      if (result['success'] != true) {
        _showToast(result['message'] ?? 'Failed to save data', isError: true);
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to save data',
        };
      }

      final savedData = result['data'];
      if (savedData is Map<String, dynamic>) {
        recordId.value = (savedData['_id'] ?? savedData['id'] ?? '').toString();
      } else if (savedData is Map) {
        final map = Map<String, dynamic>.from(savedData);
        recordId.value = (map['_id'] ?? map['id'] ?? '').toString();
      }

      await _refreshPitState();
      _showToast('Data saved successfully', isError: false);
      return {
        'success': true,
        'message': 'Return / Lost Mud saved successfully',
      };
    } catch (e) {
      print('❌ Error saving return/lost mud: $e');
      _showToast('Failed to save data', isError: true);
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
                child: Opacity(opacity: value, child: child),
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
