import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/operators_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_setup_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/operators_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OperatorTab extends StatefulWidget {
  const OperatorTab({super.key});

  @override
  State<OperatorTab> createState() => _OperatorTabState();
}

class _OperatorTabState extends State<OperatorTab> {
  int selectedRow = -1;
  final ScrollController _scrollController = ScrollController();
  final controller = Get.put(OperatorController());
  final setupController = Get.find<CompanySetupController>();
  final Map<int, List<TextEditingController>> _editControllers = {};
  final Set<int> _editingRows = {};

  @override
  void initState() {
    super.initState();
    controller.fetchOperators();
  }

  void _showSuccess(String message) {
    _showAlert(message, const Color(0xff10B981));
  }

  void _showError(String message) {
    _showAlert(message, const Color(0xffEF4444));
  }

  void _showAlert(String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(backgroundColor == const Color(0xff10B981) ? Icons.check_circle : Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Flexible(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  Future<void> _deleteOperator(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this operator?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) await controller.deleteOperator(id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final row in _editControllers.values) {
      for (final textController in row) {
        textController.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppTheme.secondaryGradient, shape: BoxShape.circle), child: Icon(Icons.business_center, color: Colors.white, size: 18)),
              const SizedBox(width: 10),
              Text('Operator', style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)));
              } else {
                final globallyLocked = setupController.isLocked.value;
                return IgnorePointer(
                  ignoring: globallyLocked,
                  child: Opacity(
                    opacity: globallyLocked ? 0.6 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300, width: 1), color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]),
                      child: Column(
                        children: [
                          Container(
                            height: 36,
                            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                            child: Row(
                              children: [
                                _HeaderCell(width: 45, text: '#', icon: Icons.numbers),
                                _HeaderCell(width: 180, text: 'Company', icon: Icons.business),
                                _HeaderCell(width: 180, text: 'Contact', icon: Icons.person),
                                _HeaderCell(width: 200, text: 'Address', icon: Icons.location_on),
                                _HeaderCell(width: 160, text: 'Phone', icon: Icons.phone),
                                _HeaderCell(width: 200, text: 'E-mail', icon: Icons.email),
                                _HeaderCell(width: 120, text: 'Logo', icon: Icons.image),
                                _HeaderCell(width: 100, text: 'Actions', icon: Icons.settings),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: controller.operators.length + controller.newEntryControllers.length,
                                itemBuilder: (context, row) {
                                  final bool isSelected = row == selectedRow;
                                  final bool isLockedRow = row < controller.operators.length;
                                  final bool isEditing = _editingRows.contains(row);

                                  return Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : row % 2 == 0 ? Colors.white : AppTheme.cardColor,
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => setState(() => selectedRow = row),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 45,
                                              decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade400, width: 1))),
                                              child: Center(
                                                child: Container(
                                                  width: 22, height: 22,
                                                  decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? AppTheme.accentColor : isLockedRow ? AppTheme.secondaryColor.withOpacity(0.15) : AppTheme.secondaryColor.withOpacity(0.15)),
                                                  child: Center(child: Text('${row + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textPrimary))),
                                                ),
                                              ),
                                            ),
                                            if (isLockedRow) ...[
                                              if (isEditing) ...[
                                                ..._buildExistingEditableCells(row),
                                                _editingActionButtons(
                                                  controller.operators[row],
                                                  row,
                                                ),
                                              ] else ...[
                                                _lockedCell(180, controller.operators[row].company),
                                                _lockedCell(180, controller.operators[row].contact),
                                                _lockedCell(200, controller.operators[row].address),
                                                _lockedCell(160, controller.operators[row].phone),
                                                _lockedCell(200, controller.operators[row].email),
                                                _lockedLogoCell(120, controller.operators[row].logoUrl),
                                                _actionButtons(controller.operators[row], row),
                                              ],
                                            ] else ...[
                                              ..._buildEditableCells(row),
                                              _emptyActionsCell(),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            }),
          ),
          Container(
            height: 44, margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppTheme.infoColor),
                    const SizedBox(width: 6),
                    Obx(() => Text('${controller.operators.length + controller.newEntryControllers.length} row(s) • Selected: ${selectedRow == -1 ? 'None' : 'Row ${selectedRow + 1}'}', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontSize: 12))),
                  ],
                ),
                Row(
                  children: [
                    Obx(() => IgnorePointer(
                      ignoring: setupController.isLocked.value,
                      child: Opacity(
                        opacity: setupController.isLocked.value ? 0.6 : 1.0,
                        child: ElevatedButton.icon(
                          onPressed: () => setupController.handleImport(),
                          style: AppTheme.secondaryButtonStyle.copyWith(
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            minimumSize:
                                MaterialStateProperty.all(const Size(0, 32)),
                          ),
                          icon: const Icon(Icons.file_upload, size: 14),
                          label: const Text(
                            'Import',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => setupController.handleExport(),
                      style: AppTheme.secondaryButtonStyle.copyWith(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        minimumSize:
                            MaterialStateProperty.all(const Size(0, 32)),
                      ),
                      icon: const Icon(Icons.file_download, size: 14),
                      label: const Text(
                        'Export',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(onPressed: () => Navigator.of(context).pop(), style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.errorColor), foregroundColor: AppTheme.errorColor, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 32)), icon: const Icon(Icons.close, size: 14), label: const Text('Close', style: TextStyle(fontSize: 12))),
                    const SizedBox(width: 8),
                    Obx(() => IgnorePointer(
                      ignoring: setupController.isLocked.value,
                      child: Opacity(
                        opacity: setupController.isLocked.value ? 0.6 : 1.0,
                        child: Row(
                          children: [
                            OutlinedButton.icon(onPressed: () {
                              if (selectedRow != -1) {
                                final newRowIndex = selectedRow - controller.operators.length;
                                if (newRowIndex >= 0 && newRowIndex < controller.newEntryControllers.length) {
                                  for (var ctrl in controller.newEntryControllers[newRowIndex]) ctrl.clear();
                                }
                              }
                            }, style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.warningColor), foregroundColor: AppTheme.warningColor, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: const Size(0, 32)), icon: const Icon(Icons.delete_outline, size: 14), label: const Text('Clear', style: TextStyle(fontSize: 12))),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(onPressed: () async {
                              final result = await controller.saveOperators();
                              if (result['success'] == true) _showSuccess(result['message']); else _showError(result['message']);
                            }, style: AppTheme.primaryButtonStyle.copyWith(padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 6)), minimumSize: MaterialStateProperty.all(const Size(0, 32))), icon: const Icon(Icons.save, size: 14), label: const Text('Save', style: TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(double width, TextEditingController controller, String hintText, {bool enabled = true}) {
    return Container(
      width: width, padding: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade400, width: 1))),
      child: TextField(controller: controller, enabled: enabled, style: AppTheme.bodyLarge.copyWith(fontSize: 12), decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: hintText, hintStyle: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.5)), contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4))),
    );
  }

  Widget _lockedCell(double width, String text) {
    return Container(
      width: width, padding: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade400, width: 1))),
      child: Row(children: [Expanded(child: Text(text, style: AppTheme.bodyLarge.copyWith(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis))]),
    );
  }

  Widget _lockedLogoCell(double width, String logoUrl) {
    return Container(
      width: width, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade400, width: 1))),
      child: Row(children: [_buildLogoImage(logoUrl), const Spacer()]),
    );
  }

  Widget _actionButtons(OperatorModel operator, int index) {
    return Container(
      width: 100, padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        InkWell(onTap: () => _startInlineEdit(operator, index), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Icon(Icons.edit, size: 14, color: AppTheme.primaryColor))),
        const SizedBox(width: 8),
        InkWell(onTap: () => _deleteOperator(operator.id!), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Icon(Icons.delete, size: 14, color: AppTheme.errorColor))),
      ]),
    );
  }

  Widget _editingActionButtons(OperatorModel operator, int index) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _saveInlineEdit(operator, index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.green),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _cancelInlineEdit(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyActionsCell() => Container(width: 100, padding: const EdgeInsets.symmetric(horizontal: 6));

  List<Widget> _buildEditableCells(int row) {
    final newRowIndex = row - controller.operators.length;
    return [
      _cell(180, controller.newEntryControllers[newRowIndex][0], '', enabled: true),
      _cell(180, controller.newEntryControllers[newRowIndex][1], '', enabled: true),
      _cell(200, controller.newEntryControllers[newRowIndex][2], '', enabled: true),
      _cell(160, controller.newEntryControllers[newRowIndex][3], '', enabled: true),
      _cell(200, controller.newEntryControllers[newRowIndex][4], '', enabled: true),
      _logoCell(120, newRowIndex),
    ];
  }

  List<Widget> _buildExistingEditableCells(int row) {
    final rowControllers = _editControllers[row]!;
    return [
      _cell(180, rowControllers[0], '', enabled: true),
      _cell(180, rowControllers[1], '', enabled: true),
      _cell(200, rowControllers[2], '', enabled: true),
      _cell(160, rowControllers[3], '', enabled: true),
      _cell(200, rowControllers[4], '', enabled: true),
      _logoCell(120, _editLogoKey(row)),
    ];
  }

  Widget _logoCell(double width, int rowIndex) {
    return Container(
      width: width, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade400, width: 1))),
      child: Obx(() {
        final logoBase64 = controller.selectedLogos[rowIndex];
        if (logoBase64 != null && logoBase64.isNotEmpty) {
          return Stack(children: [
            _buildLogoImage(logoBase64, fallback: _buildLogoButton(rowIndex)),
            Positioned(right: 0, top: 0, child: InkWell(onTap: () => controller.clearLogo(rowIndex), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 10, color: Colors.white)))),
          ]);
        }
        return _buildLogoButton(rowIndex);
      }),
    );
  }

  Widget _buildLogoButton(int rowIndex) {
    return InkWell(onTap: () => controller.pickLogoImage(rowIndex), child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate, size: 14, color: AppTheme.primaryColor), const SizedBox(width: 2), Text('Logo', style: TextStyle(fontSize: 10, color: AppTheme.primaryColor))])));
  }

  Widget _buildLogoImage(String logoUrl, {Widget? fallback}) {
    final emptyFallback = fallback ?? Icon(Icons.image, size: 16, color: Colors.grey.shade400);
    if (logoUrl.trim().isEmpty) return emptyFallback;

    if (logoUrl.startsWith('data:image')) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            base64Decode(logoUrl.split(',').last),
            width: 40,
            height: 24,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => emptyFallback,
          ),
        );
      } catch (_) {
        return emptyFallback;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        logoUrl,
        width: 40,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => emptyFallback,
      ),
    );
  }

  int _editLogoKey(int row) => -(row + 1);

  void _startInlineEdit(OperatorModel operator, int row) {
    final existingControllers = _editControllers.remove(row);
    if (existingControllers != null) {
      for (final textController in existingControllers) {
        textController.dispose();
      }
    }
    _editControllers[row] = [
      TextEditingController(text: operator.company),
      TextEditingController(text: operator.contact),
      TextEditingController(text: operator.address),
      TextEditingController(text: operator.phone),
      TextEditingController(text: operator.email),
    ];
    final logoKey = _editLogoKey(row);
    if (operator.logoUrl.isEmpty) {
      controller.selectedLogos.remove(logoKey);
    } else {
      controller.selectedLogos[logoKey] = operator.logoUrl;
    }
    controller.selectedLogos.refresh();
    setState(() => _editingRows.add(row));
  }

  void _cancelInlineEdit(int row) {
    controller.selectedLogos.remove(_editLogoKey(row));
    controller.selectedLogos.refresh();
    setState(() => _editingRows.remove(row));
  }

  Future<void> _saveInlineEdit(OperatorModel operator, int row) async {
    final rowControllers = _editControllers[row];
    if (rowControllers == null || operator.id == null) return;
    final result = await controller.updateOperator(
      operator.id!,
      OperatorModel(
        id: operator.id,
        company: rowControllers[0].text.trim(),
        contact: rowControllers[1].text.trim(),
        address: rowControllers[2].text.trim(),
        phone: rowControllers[3].text.trim(),
        email: rowControllers[4].text.trim(),
        logoUrl:
            controller.selectedLogos[_editLogoKey(row)] ?? operator.logoUrl,
      ),
    );
    if (!mounted) return;
    if (result['success'] == true) {
      controller.selectedLogos.remove(_editLogoKey(row));
      controller.selectedLogos.refresh();
      setState(() => _editingRows.remove(row));
      _showSuccess(result['message']);
    } else {
      _showError(result['message']);
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final double width; final String text; final IconData icon;
  const _HeaderCell({required this.width, required this.text, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(width: width, decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withOpacity(0.2)))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 12, color: Colors.white.withOpacity(0.9)), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3))]));
  }
}
