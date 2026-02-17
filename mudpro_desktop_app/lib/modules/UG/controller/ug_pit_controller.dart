import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';

class PitController extends GetxController {
  final isLoading = false.obs;
  final isSaving = false.obs;
  final pits = <PitModel>[].obs;
  final selectedPits = <PitModel>[].obs;
  final unselectedPits = <PitModel>[].obs;
  
  final totalCapacity = 0.0.obs;
  
  String? currentWellId;

  @override
  void onInit() {
    super.onInit();
    currentWellId = Get.arguments?['wellId'] ?? 'UG-0293 ST';
    fetchAllPits();
  }

  // ================= FETCH OPERATIONS =================
  
  Future<void> fetchAllPits() async {
    if (currentWellId == null) {
      _showAlert('Well ID is required', isError: true);
      return;
    }

    isLoading.value = true;
    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getAllPits(currentWellId!);

      if (result['success'] == true) {
        final data = result['data'];
        
        if (data != null) {
          if (data is List) {
            if (data.isNotEmpty && data.first is PitModel) {
              pits.value = List<PitModel>.from(data);
            } else {
              pits.value = data
                  .map((item) => PitModel.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          } else {
            pits.clear();
          }
        } else {
          pits.clear();
        }

        totalCapacity.value = _calculateDouble(result['totalCapacity']);
        _updateSeparatedLists();
        _ensureEmptyRow();
      } else {
        _showAlert(result['message'] ?? 'Failed to fetch pits', isError: true);
        _ensureEmptyRow();
      }
    } catch (e) {
      print('Error fetching pits: $e');
      _showAlert('Error fetching pits', isError: true);
      _ensureEmptyRow();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSelectedPits() async {
    if (currentWellId == null) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getSelectedPits(currentWellId!);

      if (result['success'] == true) {
        final data = result['data'];
        
        if (data != null && data is List) {
          if (data.isNotEmpty && data.first is PitModel) {
            selectedPits.value = List<PitModel>.from(data);
          } else {
            selectedPits.value = data
                .map((item) => PitModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } else {
          selectedPits.clear();
        }
      }
    } catch (e) {
      print('Error fetching selected pits: $e');
    }
  }

  Future<void> fetchUnselectedPits() async {
    if (currentWellId == null) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.getUnselectedPits(currentWellId!);

      if (result['success'] == true) {
        final data = result['data'];
        
        if (data != null && data is List) {
          if (data.isNotEmpty && data.first is PitModel) {
            unselectedPits.value = List<PitModel>.from(data);
          } else {
            unselectedPits.value = data
                .map((item) => PitModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } else {
          unselectedPits.clear();
        }
      }
    } catch (e) {
      print('Error fetching unselected pits: $e');
    }
  }

  // ================= BULK SAVE NEW PITS =================
  
  Future<void> bulkSavePits() async {
    if (currentWellId == null) {
      _showAlert('Well ID is required', isError: true);
      return;
    }

    // Get only new pits (without id and with data)
    final newPits = pits
        .where((pit) => pit.id == null && pit.pitName.isNotEmpty && pit.capacity.value > 0)
        .map((pit) => {
              'pitName': pit.pitName,
              'capacity': pit.capacity.value,
              'initialActive': pit.initialActive.value,
            })
        .toList();

    if (newPits.isEmpty) {
      _showAlert('No new pits to save', isError: true);
      return;
    }

    isSaving.value = true;
    try {
      final authRepo = AuthRepository();
      final result = await authRepo.bulkAddPits(
        pits: newPits,
        wellId: currentWellId!,
      );

      if (result['success'] == true) {
        _showAlert('${newPits.length} pit(s) saved successfully', isError: false);
        await fetchAllPits(); // Auto refresh
      } else {
        _showAlert(result['message'] ?? 'Failed to save pits', isError: true);
      }
    } catch (e) {
      print('Error saving pits: $e');
      _showAlert('Error saving pits', isError: true);
    } finally {
      isSaving.value = false;
    }
  }

  // ================= UPDATE OPERATIONS =================
  
  Future<void> togglePitActive(PitModel pit) async {
    if (pit.id == null) return;

    final newStatus = !pit.initialActive.value;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.updatePit(
        id: pit.id!,
        initialActive: newStatus,
      );

      if (result['success'] == true) {
        _showAlert('Status updated', isError: false);
        await fetchAllPits(); // Auto refresh
      } else {
        _showAlert(result['message'] ?? 'Failed to update', isError: true);
      }
    } catch (e) {
      print('Error toggling status: $e');
      _showAlert('Error updating status', isError: true);
    }
  }

  // ================= DELETE OPERATIONS =================
  
  Future<void> deletePit(PitModel pit) async {
    if (pit.id == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Pit'),
        content: Text('Delete "${pit.pitName}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authRepo = AuthRepository();
      final result = await authRepo.deletePit(pit.id!);

      if (result['success'] == true) {
        _showAlert('Pit deleted', isError: false);
        await fetchAllPits(); // Auto refresh
      } else {
        _showAlert(result['message'] ?? 'Failed to delete', isError: true);
      }
    } catch (e) {
      print('Error deleting pit: $e');
      _showAlert('Error deleting', isError: true);
    }
  }

  // ================= HELPER METHODS =================
  
  void _updateSeparatedLists() {
    selectedPits.value = pits.where((p) => p.id != null && p.initialActive.value).toList();
    unselectedPits.value = pits.where((p) => p.id != null && !p.initialActive.value).toList();
    _updateCapacities();
  }

  void _updateCapacities() {
    totalCapacity.value = pits
        .where((pit) => pit.id != null)
        .fold(0.0, (sum, pit) => sum + pit.capacity.value);
  }

  void _ensureEmptyRow() {
    // Always keep one empty row at the end
    final hasEmptyRow = pits.any((p) => p.id == null && p.pitName.isEmpty && p.capacity.value == 0);
    
    if (!hasEmptyRow) {
      pits.add(PitModel(
        pitName: '',
        capacity: 0.0,
        initialActive: false,
      ));
    }
  }

  // Auto-generate new row when current empty row is filled
  void onRowFilled(int index) {
    final pit = pits[index];
    if (pit.id == null && pit.pitName.isNotEmpty && pit.capacity.value > 0) {
      // Add new empty row
      pits.add(PitModel(
        pitName: '',
        capacity: 0.0,
        initialActive: false,
      ));
    }
  }

  bool isRowFilled(PitModel pit) {
    return pit.pitName.isNotEmpty && pit.capacity.value > 0;
  }

  double _calculateDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ================= SIMPLE TOP-RIGHT ALERTS =================
  
  void _showAlert(String message, {required bool isError}) {
    Get.rawSnackbar(
      message: message,
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.only(top: 10, right: 10),
      borderRadius: 4,
      maxWidth: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
        size: 20,
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void showError(String message) => _showAlert(message, isError: true);
  void showSuccess(String message) => _showAlert(message, isError: false);
}