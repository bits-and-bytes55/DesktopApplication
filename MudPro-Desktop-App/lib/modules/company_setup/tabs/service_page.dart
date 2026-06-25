import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_setup_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/services_getx_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ServicesGetxController());
    final setupController = Get.find<CompanySetupController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() => Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: IgnorePointer(
                    ignoring: setupController.isLocked.value,
                    child: Opacity(
                      opacity: setupController.isLocked.value ? 0.6 : 1.0,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 1200,
                              child: Row(
                                children: [
                                  _tableSection(
                                    title: 'Package',
                                    existingData: controller.packages,
                                    newRows: controller.newPackageRows,
                                    icon: Icons.inventory,
                                    gradient: AppTheme.primaryGradient,
                                    onSave: () => controller.savePackages(),
                                    onDelete: (id) => controller.deletePackage(id),
                                    editingId: controller.editingPackageId.value,
                                    onStartEdit: (item) => controller.startEditingPackage(item),
                                    onCancelEdit: () => controller.cancelEditingPackage(),
                                    onSaveEdit: () => controller.savePackageEdit(),
                                    setupController: setupController,
                                    isSaving: controller.isPackagesSaving.value,
                                  ),
                                  const SizedBox(width: 12),
                                  _tableSection(
                                    title: 'Services',
                                    existingData: controller.services,
                                    newRows: controller.newServiceRows,
                                    icon: Icons.miscellaneous_services,
                                    gradient: AppTheme.secondaryGradient,
                                    onSave: () => controller.saveServices(),
                                    onDelete: (id) => controller.deleteService(id),
                                    editingId: controller.editingServiceId.value,
                                    onStartEdit: (item) => controller.startEditingService(item),
                                    onCancelEdit: () => controller.cancelEditingService(),
                                    onSaveEdit: () => controller.saveServiceEdit(),
                                    setupController: setupController,
                                    isSaving: controller.isServicesSaving.value,
                                  ),
                                  const SizedBox(width: 12),
                                  _tableSection(
                                    title: 'Engineering',
                                    existingData: controller.engineering,
                                    newRows: controller.newEngineeringRows,
                                    icon: Icons.engineering,
                                    gradient: AppTheme.accentGradient,
                                    onSave: () => controller.saveEngineering(),
                                    onDelete: (id) => controller.deleteEngineering(id),
                                    editingId: controller.editingEngineeringId.value,
                                    onStartEdit: (item) => controller.startEditingEngineering(item),
                                    onCancelEdit: () => controller.cancelEditingEngineering(),
                                    onSaveEdit: () => controller.saveEngineeringEdit(),
                                    setupController: setupController,
                                    isSaving: controller.isEngineeringSaving.value,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                _footerButtons(setupController),
              ],
            ),
          ),
          if (controller.isLoading.value)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      )),
    );
  }

  Widget _tableSection({
    required String title,
    required List<dynamic> existingData,
    required List<dynamic> newRows,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onSave,
    required Function(String) onDelete,
    required String? editingId,
    required Function(dynamic) onStartEdit,
    required VoidCallback onCancelEdit,
    required Future<void> Function() onSaveEdit,
    required CompanySetupController setupController,
    required bool isSaving,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            _sectionHeader(title, icon, gradient),
            _tableHeader(),
            Container(height: 1, color: AppTheme.tableGridBlue),
            Expanded(
              child: ListView.builder(
                itemCount: existingData.length + newRows.length,
                itemBuilder: (context, index) {
                  final isExisting = index < existingData.length;
                  if (isExisting) {
                    final item = existingData[index];
                    final isEditing = editingId == item.id;
                    return _buildExistingRow(item, isEditing, index, onStartEdit, onCancelEdit, onSaveEdit, onDelete, setupController);
                  } else {
                    final rowIndex = index - existingData.length;
                    final row = newRows[rowIndex];
                    return _buildNewRow(row, index, setupController);
                  }
                },
              ),
            ),
            _tableSaveButton(onSave, title, setupController, isSaving),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Gradient gradient) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 32,
      color: AppTheme.tableHeadColor.withOpacity(0.1),
      child: Row(
        children: [
          _headerCell(width: 40, text: '#'),
          _headerCell(text: 'Name', flex: 3),
          _headerCell(text: 'Code', flex: 2),
          _headerCell(text: 'Unit', flex: 1),
          _headerCell(text: 'Price', flex: 2),
          _headerCell(width: 80, text: 'Actions'),
        ],
      ),
    );
  }

  Widget _headerCell({double? width, int? flex, required String text}) {
    Widget cell = Container(
      width: width,
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
    return flex != null ? Expanded(flex: flex, child: cell) : cell;
  }

  Widget _buildExistingRow(dynamic item, bool isEditing, int index, 
      Function(dynamic) onStartEdit, VoidCallback onCancelEdit, Future<void> Function() onSaveEdit, 
      Function(String) onDelete, CompanySetupController setupController) {
    bool globallyLocked = setupController.isLocked.value;
    
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isEditing ? Colors.blue.withOpacity(0.05) : (index % 2 == 0 ? Colors.white : AppTheme.cardColor),
        border: Border(bottom: BorderSide(color: AppTheme.tableBorderBlue, width: 0.5)),
      ),
      child: Row(
        children: [
          _cell(width: 40, child: Text('${index + 1}', style: const TextStyle(fontSize: 11))),
          _cell(flex: 3, child: isEditing ? _editField(item.nameController) : _textCell(item.name)),
          _cell(flex: 2, child: isEditing ? _editField(item.codeController) : _textCell(item.code)),
          _cell(flex: 1, child: isEditing ? _editField(item.unitController) : _textCell(item.unit)),
          _cell(flex: 2, child: isEditing ? _editField(item.priceController, isNumeric: true) : _textCell(item.price.toString())),
          _cell(width: 80, child: isEditing 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(onPressed: onSaveEdit, icon: const Icon(Icons.check, size: 14, color: Colors.green), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        IconButton(onPressed: onCancelEdit, icon: const Icon(Icons.close, size: 14, color: Colors.red), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(onPressed: () => onStartEdit(item), icon: const Icon(Icons.edit, size: 14, color: Colors.orange), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        IconButton(onPressed: () => onDelete(item.id), icon: const Icon(Icons.delete, size: 14, color: Colors.red), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    )),
        ],
      ),
    );
  }

  Widget _buildNewRow(dynamic row, int index, CompanySetupController setupController) {
    bool globallyLocked = setupController.isLocked.value;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : AppTheme.cardColor,
        border: Border(bottom: BorderSide(color: AppTheme.tableBorderBlue, width: 0.5)),
      ),
      child: Row(
        children: [
          _cell(width: 40, child: Text('${index + 1}', style: const TextStyle(fontSize: 11))),
          _cell(flex: 3, child: _editField(row[0], enabled: !globallyLocked)),
          _cell(flex: 2, child: _editField(row[1], enabled: !globallyLocked)),
          _cell(flex: 1, child: _editField(row[2], enabled: !globallyLocked)),
          _cell(flex: 2, child: _editField(row[3], isNumeric: true, enabled: !globallyLocked)),
          _cell(width: 80, child: const Text('-', style: TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Widget _cell({double? width, int? flex, required Widget child}) {
    Widget c = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border(left: BorderSide(color: AppTheme.tableBorderBlue, width: 0.5))),
      child: child,
    );
    return flex != null ? Expanded(flex: flex, child: c) : c;
  }

  Widget _textCell(String text) => Text(text, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis);

  Widget _editField(TextEditingController ctrl, {bool isNumeric = false, bool enabled = true}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      style: const TextStyle(fontSize: 11),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
      textAlign: TextAlign.center,
    );
  }

  Widget _tableSaveButton(VoidCallback onSave, String title, CompanySetupController setupController, bool isSaving) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity,
        height: 28,
        child: ElevatedButton(
          onPressed: (setupController.isLocked.value || isSaving) ? null : onSave,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: isSaving 
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Save $title', style: const TextStyle(fontSize: 11, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _footerButtons(CompanySetupController setupController) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: setupController.isLocked.value
                ? null
                : () => setupController.handleImport(),
            style: AppTheme.secondaryButtonStyle,
            icon: const Icon(Icons.file_upload, size: 16),
            label: const Text('Import'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => setupController.handleExport(),
            style: AppTheme.secondaryButtonStyle,
            icon: const Icon(Icons.file_download, size: 16),
            label: const Text('Export'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: AppTheme.secondaryButtonStyle,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
