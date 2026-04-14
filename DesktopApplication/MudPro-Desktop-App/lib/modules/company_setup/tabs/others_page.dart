import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_setup_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_getx_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/others_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/default_mud_properties_page.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OthersPage extends StatelessWidget {
  const OthersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OthersGetxController());
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tableSection(
                            title: 'Activity',
                            items: controller.activities,
                            newRows: controller.newActivityRows,
                            icon: Icons.list_alt,
                            gradient: AppTheme.primaryGradient,
                            width: 350,
                            onSave: () => controller.saveActivities(),
                            onDelete: (id) => controller.deleteActivity(id),
                            onEdit: (item) => controller.showEditDialog(item, 'Activity'),
                            setupController: setupController,
                            isSaving: controller.isActivitiesSaving.value,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _singleColTable(
                                    title: 'Addition',
                                    items: controller.additions,
                                    newRows: controller.newAdditionRows,
                                    icon: Icons.add_circle,
                                    gradient: AppTheme.secondaryGradient,
                                    onSave: () => controller.saveAdditions(),
                                    onDelete: (id) => controller.deleteAddition(id),
                                    onEdit: (item) => controller.showEditDialog(item, 'Addition'),
                                    setupController: setupController,
                                    isSaving: controller.isAdditionsSaving.value,
                                  ),
                                  const SizedBox(width: 12),
                                  _singleColTable(
                                    title: 'Loss',
                                    items: controller.losses,
                                    newRows: controller.newLossRows,
                                    icon: Icons.remove_circle,
                                    gradient: AppTheme.accentGradient,
                                    onSave: () => controller.saveLosses(),
                                    onDelete: (id) => controller.deleteLoss(id),
                                    onEdit: (item) => controller.showEditDialog(item, 'Loss'),
                                    setupController: setupController,
                                    isSaving: controller.isLossesSaving.value,
                                  ),
                                  const SizedBox(width: 12),
                                  _singleColTable(
                                    title: 'Water-based',
                                    items: controller.waterBased,
                                    newRows: controller.newWaterRows,
                                    icon: Icons.water_drop,
                                    gradient: AppTheme.headerGradient,
                                    onSave: () => controller.saveWaterBased(),
                                    onDelete: (id) => controller.deleteWaterBased(id),
                                    onEdit: (item) => controller.showEditDialog(item, 'Water-based'),
                                    setupController: setupController,
                                    isSaving: controller.isWaterSaving.value,
                                  ),
                                  const SizedBox(width: 12),
                                  _singleColTable(
                                    title: 'Oil-based',
                                    items: controller.oilBased,
                                    newRows: controller.newOilRows,
                                    icon: Icons.local_gas_station,
                                    gradient: const LinearGradient(colors: [Color(0xffFFB347), Color(0xffFFCC33)]),
                                    onSave: () => controller.saveOilBased(),
                                    onDelete: (id) => controller.deleteOilBased(id),
                                    onEdit: (item) => controller.showEditDialog(item, 'Oil-based'),
                                    setupController: setupController,
                                    isSaving: controller.isOilSaving.value,
                                  ),
                                  const SizedBox(width: 12),
                                  _singleColTable(
                                    title: 'Synthetic',
                                    items: controller.synthetic,
                                    newRows: controller.newSyntheticRows,
                                    icon: Icons.science,
                                    gradient: const LinearGradient(colors: [Color(0xffDA70D6), Color(0xff9370DB)]),
                                    onSave: () => controller.saveSynthetic(),
                                    onDelete: (id) => controller.deleteSynthetic(id),
                                    onEdit: (item) => controller.showEditDialog(item, 'Synthetic'),
                                    setupController: setupController,
                                    isSaving: controller.isSyntheticSaving.value,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _footerButtons(context, setupController),
              ],
            ),
          ),
          if (controller.isLoading.value)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      )),
    );
  }

  Widget _tableSection({
    required String title,
    required List<dynamic> items,
    required List<TextEditingController> newRows,
    required IconData icon,
    required Gradient gradient,
    double? width,
    required VoidCallback onSave,
    required Function(String) onDelete,
    required Function(dynamic) onEdit,
    required CompanySetupController setupController,
    required bool isSaving,
  }) {
    return Container(
      width: width ?? 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          _sectionHeader(title, icon, gradient),
          _tableHeader(title),
          Expanded(
            child: ListView.builder(
              itemCount: items.length + newRows.length,
              itemBuilder: (context, index) {
                final isExisting = index < items.length;
                if (isExisting) {
                  return _buildExistingRow(items[index], index, onEdit, onDelete, setupController);
                } else {
                  return _buildNewRow(newRows[index - items.length], index, setupController);
                }
              },
            ),
          ),
          _tableSaveButton(onSave, title, setupController, isSaving),
        ],
      ),
    );
  }

  Widget _singleColTable({
    required String title,
    required List<dynamic> items,
    required List<TextEditingController> newRows,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onSave,
    required Function(String) onDelete,
    required Function(dynamic) onEdit,
    required CompanySetupController setupController,
    required bool isSaving,
  }) {
    return _tableSection(
      title: title,
      items: items,
      newRows: newRows,
      icon: icon,
      gradient: gradient,
      onSave: onSave,
      onDelete: onDelete,
      onEdit: onEdit,
      setupController: setupController,
      isSaving: isSaving,
    );
  }

  Widget _sectionHeader(String title, IconData icon, Gradient gradient) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(gradient: gradient, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _tableHeader(String title) {
    return Container(
      height: 32,
      color: AppTheme.tableHeadColor.withOpacity(0.1),
      child: Row(
        children: [
          _headerCell(width: 40, text: '#'),
          _headerCell(text: 'Description', flex: 1),
          _headerCell(width: 80, text: 'Actions'),
        ],
      ),
    );
  }

  Widget _headerCell({double? width, int? flex, required String text}) {
    Widget cell = Container(width: width, alignment: Alignment.center, child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)));
    return flex != null ? Expanded(flex: flex, child: cell) : cell;
  }

  Widget _buildExistingRow(dynamic item, int index, Function(dynamic) onEdit, Function(String) onDelete, CompanySetupController setupController) {
    bool globallyLocked = setupController.isLocked.value;
    String description = '';
    if (item is ActivityItem) description = item.description;
    else if (item is AdditionItem) description = item.name;
    else if (item is LossItem) description = item.name;
    else if (item is WaterBasedItem) description = item.name;
    else if (item is OilBasedItem) description = item.name;
    else if (item is SyntheticItem) description = item.name;

    return Container(
      height: 32,
      decoration: BoxDecoration(color: index % 2 == 0 ? Colors.white : AppTheme.cardColor, border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5))),
      child: Row(
        children: [
          _cell(width: 40, child: Text('${index + 1}', style: const TextStyle(fontSize: 11))),
          _cell(flex: 1, child: Text(description, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
          _cell(width: 80, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () => onEdit(item), icon: const Icon(Icons.edit, size: 14, color: Colors.orange), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              IconButton(onPressed: () => onDelete(item.id!), icon: const Icon(Icons.delete, size: 14, color: Colors.red), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildNewRow(TextEditingController ctrl, int index, CompanySetupController setupController) {
    bool globallyLocked = setupController.isLocked.value;
    return Container(
      height: 32,
      decoration: BoxDecoration(color: index % 2 == 0 ? Colors.white : AppTheme.cardColor, border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5))),
      child: Row(
        children: [
          _cell(width: 40, child: Text('${index + 1}', style: const TextStyle(fontSize: 11))),
          _cell(flex: 1, child: TextField(
            controller: ctrl,
            enabled: !globallyLocked,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
            textAlign: TextAlign.center,
          )),
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
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade200, width: 0.5))),
      child: child,
    );
    return flex != null ? Expanded(flex: flex, child: c) : c;
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

  Widget _footerButtons(BuildContext context, CompanySetupController setupController) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IgnorePointer(
            ignoring: setupController.isLocked.value,
            child: Opacity(
              opacity: setupController.isLocked.value ? 0.6 : 1.0,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const DefaultMudPropertiesPage()),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Mud Properties'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10), side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}