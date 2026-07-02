import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_setup_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/services_getx_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  ServicesGetxController get _controller =>
      Get.isRegistered<ServicesGetxController>()
      ? Get.find<ServicesGetxController>()
      : Get.put(ServicesGetxController());

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
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
                                    controller: controller,
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
                                    controller: controller,
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
                                    controller: controller,
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
    required ServicesGetxController controller,
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
                    return _buildExistingRow(
                      existingData[index],
                      index,
                      onStartEdit,
                      onCancelEdit,
                      onSaveEdit,
                      onDelete,
                      controller,
                      setupController,
                    );
                  } else {
                    final rowIndex = index - existingData.length;
                    final row = newRows[rowIndex];
                    return _buildNewRow(
                      row,
                      rowIndex,
                      index,
                      newRows,
                      controller,
                      setupController,
                    );
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
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.companySetupHeaderTextColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.companySetupHeaderDark.copyWith(fontSize: 12),
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
        ],
      ),
    );
  }

  Widget _headerCell({double? width, int? flex, required String text}) {
    Widget cell = Container(
      width: width,
      alignment: Alignment.center,
      child: Text(text, style: AppTheme.companySetupBodyBold),
    );
    return flex != null ? Expanded(flex: flex, child: cell) : cell;
  }

  Widget _buildExistingRow(dynamic item, int index, 
      Function(dynamic) onStartEdit, VoidCallback onCancelEdit, Future<void> Function() onSaveEdit, 
      Function(String) onDelete, ServicesGetxController controller, CompanySetupController setupController) {
    return Obx(() {
      final isEditing = _editingIdForItem(controller, item) == item.id;
      return Builder(
        builder: (context) => GestureDetector(
          key: ValueKey('${item.id}-${isEditing ? 'edit' : 'view'}'),
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) => _showRowMenu(
            context: context,
            position: details.globalPosition,
            item: item,
            isEditing: isEditing,
            onStartEdit: onStartEdit,
            onCancelEdit: onCancelEdit,
            onSaveEdit: onSaveEdit,
            onDelete: onDelete,
          ),
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: isEditing
                  ? Colors.blue.withOpacity(0.05)
                  : (index % 2 == 0 ? Colors.white : AppTheme.cardColor),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.tableBorderBlue,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                _cell(
                  width: 40,
                  child: Text(
                    '${index + 1}',
                    style: AppTheme.companySetupBodyText,
                  ),
                ),
                _cell(
                  flex: 3,
                  child: isEditing
                      ? _editField(controller.inlineName, autofocus: true)
                      : _textCell(item.name),
                ),
                _cell(
                  flex: 2,
                  child: isEditing
                      ? _editField(controller.inlineCode)
                      : _textCell(item.code),
                ),
                _cell(
                  flex: 1,
                  child: isEditing
                      ? _editField(controller.inlineUnit)
                      : _textCell(item.unit),
                ),
                _cell(
                  flex: 2,
                  child: isEditing
                      ? _editField(controller.inlinePrice, isNumeric: true)
                      : _textCell(item.price.toString()),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNewRow(
    dynamic row,
    int rowIndex,
    int index,
    dynamic rows,
    ServicesGetxController controller,
    CompanySetupController setupController,
  ) {
    bool globallyLocked = setupController.isLocked.value;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : AppTheme.cardColor,
        border: Border(bottom: BorderSide(color: AppTheme.tableBorderBlue, width: 0.5)),
      ),
      child: Row(
        children: [
          _cell(width: 40, child: Text('${index + 1}', style: AppTheme.companySetupBodyText)),
          _cell(
            flex: 3,
            child: _editField(
              row[0],
              enabled: !globallyLocked,
              onChanged: (_) => controller.updateNewRows(rows, rowIndex),
            ),
          ),
          _cell(
            flex: 2,
            child: _editField(
              row[1],
              enabled: !globallyLocked,
              onChanged: (_) => controller.updateNewRows(rows, rowIndex),
            ),
          ),
          _cell(
            flex: 1,
            child: _editField(
              row[2],
              enabled: !globallyLocked,
              onChanged: (_) => controller.updateNewRows(rows, rowIndex),
            ),
          ),
          _cell(
            flex: 2,
            child: _editField(
              row[3],
              isNumeric: true,
              enabled: !globallyLocked,
              onChanged: (_) => controller.updateNewRows(rows, rowIndex),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRowMenu({
    required BuildContext context,
    required Offset position,
    required dynamic item,
    required bool isEditing,
    required Function(dynamic) onStartEdit,
    required VoidCallback onCancelEdit,
    required Future<void> Function() onSaveEdit,
    required Function(String) onDelete,
  }) async {
    final rowId = item.id?.toString().trim() ?? '';
    if (rowId.isEmpty) return;

    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        if (!isEditing)
          const PopupMenuItem<String>(
            value: 'edit',
            child: Text('Edit', style: AppTheme.companySetupBodyText),
          ),
        if (isEditing)
          const PopupMenuItem<String>(
            value: 'save',
            child: Text('Save', style: AppTheme.companySetupBodyText),
          ),
        if (isEditing)
          const PopupMenuItem<String>(
            value: 'cancel',
            child: Text('Cancel', style: AppTheme.companySetupBodyText),
          ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete', style: AppTheme.companySetupBodyText),
        ),
      ],
    );

    switch (action) {
      case 'edit':
        onStartEdit(item);
        break;
      case 'save':
        await onSaveEdit();
        break;
      case 'cancel':
        onCancelEdit();
        break;
      case 'delete':
        onDelete(rowId);
        break;
    }
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

  Widget _textCell(String text) => Text(text, style: AppTheme.companySetupBodyText, overflow: TextOverflow.ellipsis);

  Widget _editField(
    TextEditingController ctrl, {
    bool isNumeric = false,
    bool enabled = true,
    bool autofocus = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      style: AppTheme.companySetupBodyText,
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
              : Text('Save $title', style: AppTheme.companySetupHeaderWhite),
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

  String? _editingIdForItem(ServicesGetxController controller, dynamic item) {
    if (item is PackageItem) return controller.editingPackageId.value;
    if (item is ServiceItem) return controller.editingServiceId.value;
    if (item is EngineeringItem) return controller.editingEngineeringId.value;
    return null;
  }
