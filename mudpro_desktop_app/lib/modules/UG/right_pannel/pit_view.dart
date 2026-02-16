import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import '../controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';

class PitView extends StatelessWidget {
  PitView({super.key});

  final c = Get.put(PitController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width / 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildTableHeader(),
              Expanded(child: _buildTableBody()),
              _buildFooter(), // Save button
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_damage, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          const Text(
            "Pit Configuration",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          const Text(
            "Total Capacity: ",
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              "${c.totalCapacity.value.toStringAsFixed(1)} bbl",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ================= TABLE HEADER =================
  Widget _buildTableHeader() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          _headerCell("Pit/Tank", 180),
          _headerCell("Capacity (BBL)", 120),
          _headerCell("Initial Active", 90),
          _headerCell("Actions", 80),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  // ================= TABLE BODY =================
  Widget _buildTableBody() {
    return Obx(() {
      if (c.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      return ListView.builder(
        itemCount: c.pits.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final pit = c.pits[index];
          return _buildPitRow(pit, index);
        },
      );
    });
  }

  // ================= PIT ROW =================
  Widget _buildPitRow(PitModel pit, int index) {
    final bool hasData = pit.id != null;
    
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Pit/Tank Name Column
          _buildNameCell(pit, index, hasData),
          
          // Capacity Column
          _buildCapacityCell(pit, index, hasData),
          
          // Initial Active Column
          _buildActiveCell(pit, hasData),
          
          // Actions Column
          _buildActionsCell(pit, hasData),
        ],
      ),
    );
  }

  Widget _buildNameCell(PitModel pit, int index, bool hasData) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      alignment: Alignment.centerLeft,
      child: hasData
          ? Text(
              pit.pitName,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: TextFormField(
                initialValue: pit.pitName,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  pit.pitName = value;
                  if (c.isRowFilled(pit)) {
                    c.onRowFilled(index);
                  }
                },
              ),
            ),
    );
  }

  Widget _buildCapacityCell(PitModel pit, int index, bool hasData) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      alignment: Alignment.centerLeft,
      child: hasData
          ? Text(
              "${pit.capacity.value.toStringAsFixed(1)} bbl",
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            )
          : Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: TextFormField(
                initialValue: pit.capacity.value > 0 ? pit.capacity.value.toString() : '',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  suffixText: 'bbl',
                  suffixStyle: TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final newCapacity = double.tryParse(value);
                  if (newCapacity != null) {
                    pit.capacity.value = newCapacity;
                    if (c.isRowFilled(pit)) {
                      c.onRowFilled(index);
                    }
                  }
                },
              ),
            ),
    );
  }

  Widget _buildActiveCell(PitModel pit, bool hasData) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 24,
        width: 24,
        child: Obx(() => Checkbox(
          value: pit.initialActive.value,
          onChanged: hasData
              ? (value) => c.togglePitActive(pit)
              : (value) => pit.initialActive.value = value ?? false,
          activeColor: AppTheme.successColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        )),
      ),
    );
  }

  Widget _buildActionsCell(PitModel pit, bool hasData) {
    if (!hasData) {
      return const SizedBox(width: 80);
    }

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Edit button
          IconButton(
            onPressed: () => _showEditDialog(pit),
            icon: const Icon(Icons.edit, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Edit',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          
          // Delete button
          IconButton(
            onPressed: () => c.deletePit(pit),
            icon: const Icon(Icons.delete, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Delete',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // ================= FOOTER WITH SAVE BUTTON =================
  Widget _buildFooter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() => ElevatedButton.icon(
            onPressed: c.isSaving.value ? null : () => c.bulkSavePits(),
            icon: c.isSaving.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, size: 16),
            label: Text(
              c.isSaving.value ? 'Saving...' : 'Save New Pits',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          )),
        ],
      ),
    );
  }

  // ================= EDIT DIALOG =================
  void _showEditDialog(PitModel pit) {
    final nameController = TextEditingController(text: pit.pitName);
    final capacityController = TextEditingController(
      text: pit.capacity.value.toStringAsFixed(1),
    );
    final isActive = pit.initialActive.value.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Pit', style: TextStyle(fontSize: 14)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Pit Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity (BBL)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Obx(() => CheckboxListTile(
                title: const Text('Active', style: TextStyle(fontSize: 12)),
                value: isActive.value,
                onChanged: (value) => isActive.value = value ?? false,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final capacityStr = capacityController.text.trim();

              if (name.isEmpty || capacityStr.isEmpty) {
                c.showError('Please fill all fields');
                return;
              }

              final capacity = double.tryParse(capacityStr);
              if (capacity == null) {
                c.showError('Invalid capacity');
                return;
              }

              if (pit.id != null) {
                c.isLoading.value = true;
                final result = await AuthRepository().updatePit(
                  id: pit.id!,
                  pitName: name,
                  capacity: capacity,
                  initialActive: isActive.value,
                );

                if (result['success'] == true) {
                  Get.back();
                  c.showSuccess('Updated successfully');
                  await c.fetchAllPits(); // Auto refresh
                } else {
                  c.showError(result['message'] ?? 'Update failed');
                }
                c.isLoading.value = false;
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}