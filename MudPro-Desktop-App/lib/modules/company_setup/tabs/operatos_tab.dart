import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/operators_controller.dart';
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

  // Controllers for new entries only
  List<List<TextEditingController>> newEntryControllers = [
    List.generate(6, (_) => TextEditingController()),
  ];

  @override
  void initState() {
    super.initState();
    controller.fetchOperators();
    _addListenersToRow(0);
  }

  void _addListenersToRow(int rowIndex) {
    for (var controller in newEntryControllers[rowIndex]) {
      controller.addListener(() {
        _checkAndAddNewRow(rowIndex);
      });
    }
  }

  void _checkAndAddNewRow(int rowIndex) {
    if (rowIndex == newEntryControllers.length - 1) {
      bool hasData = newEntryControllers[rowIndex].any((c) => c.text.isNotEmpty);
      if (hasData && newEntryControllers.length < 100) {
        setState(() {
          newEntryControllers.add(List.generate(6, (_) => TextEditingController()));
          _addListenersToRow(newEntryControllers.length - 1);
        });
      }
    }
  }

  void _clearRowsAfterSave() {
    for (var row in newEntryControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    setState(() {
      newEntryControllers = [
        List.generate(6, (_) => TextEditingController()),
      ];
      selectedRow = -1;
      _addListenersToRow(0);
    });
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
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  backgroundColor == const Color(0xff10B981)
                      ? Icons.check_circle
                      : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }

  // Show update dialog
  Future<void> _showUpdateOperatorDialog(OperatorModel operator, int index) async {
    final companyController = TextEditingController(text: operator.company);
    final contactController = TextEditingController(text: operator.contact);
    final addressController = TextEditingController(text: operator.address);
    final phoneController = TextEditingController(text: operator.phone);
    final emailController = TextEditingController(text: operator.email);
    final logoController = TextEditingController(text: operator.logoUrl);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Operator'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Contact'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: logoController,
                  decoration: const InputDecoration(labelText: 'Logo URL'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await controller.updateOperator(
                operator.id!,
                OperatorModel(
                  id: operator.id,
                  company: companyController.text.trim(),
                  contact: contactController.text.trim(),
                  address: addressController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  logoUrl: logoController.text.trim(),
                ),
              );
              if (result['success'] == true) {
                _showSuccess(result['message']);
              } else {
                _showError(result['message']);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Show delete confirmation dialog
  Future<void> _deleteOperator(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this operator?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.deleteOperator(id);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var row in newEntryControllers) {
      for (var controller in row) {
        controller.dispose();
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
          // Compact Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppTheme.secondaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_center,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Operator',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Compact Table Container
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                );
              } else {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Compact Table Header
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
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

                      // Compact Table Body
                      Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: controller.operators.length + newEntryControllers.length,
                            itemBuilder: (context, row) {
                              final bool isSelected = row == selectedRow;
                              final bool isLockedRow = row < controller.operators.length;

                              return Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withOpacity(0.08)
                                      : row % 2 == 0
                                          ? Colors.white
                                          : AppTheme.cardColor,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(() {
                                      selectedRow = row;
                                    }),
                                    hoverColor: AppTheme.primaryColor.withOpacity(0.04),
                                    child: Row(
                                      children: [
                                        // Compact Number Column
                                        Container(
                                          width: 45,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: Colors.grey.shade400,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? AppTheme.accentColor
                                                    : isLockedRow
                                                        ? Colors.grey.shade400
                                                        : AppTheme.secondaryColor.withOpacity(0.15),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${row + 1}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Data Cells
                                        if (isLockedRow) ...[
                                          // Locked cells for existing operators
                                          _lockedCell(180, controller.operators[row].company),
                                          _lockedCell(180, controller.operators[row].contact),
                                          _lockedCell(200, controller.operators[row].address),
                                          _lockedCell(160, controller.operators[row].phone),
                                          _lockedCell(200, controller.operators[row].email),
                                          _lockedCell(120, controller.operators[row].logoUrl),
                                          _actionButtons(controller.operators[row], row),
                                        ] else ...[
                                          // Editable cells for new entries
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
                );
              }
            }),
          ),

          // Compact Footer
          Container(
            height: 44,
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: 6),
                    Obx(() => Text(
                          '${controller.operators.length + newEntryControllers.length} row(s) • Selected: ${selectedRow == -1 ? 'None' : 'Row ${selectedRow + 1}'}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        )),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.errorColor),
                        foregroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Close', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (selectedRow != -1) {
                          final newRowIndex = selectedRow - controller.operators.length;
                          if (newRowIndex >= 0 && newRowIndex < newEntryControllers.length) {
                            for (var ctrl in newEntryControllers[newRowIndex]) {
                              ctrl.clear();
                            }
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.warningColor),
                        foregroundColor: AppTheme.warningColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await controller.saveOperators(newEntryControllers);
                        if (result['success'] == true) {
                          _showSuccess(result['message']);
                          _clearRowsAfterSave();
                        } else {
                          _showError(result['message']);
                        }
                      },
                      style: AppTheme.primaryButtonStyle.copyWith(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        minimumSize: MaterialStateProperty.all(const Size(0, 32)),
                      ),
                      icon: const Icon(Icons.save, size: 14),
                      label: const Text('Save', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(double width, TextEditingController controller, String hintText) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
      ),
      child: TextField(
        controller: controller,
        style: AppTheme.bodyLarge.copyWith(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        ),
      ),
    );
  }

  Widget _lockedCell(double width, String text) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.lock,
            size: 12,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  // Actions buttons for locked rows
  Widget _actionButtons(OperatorModel operator, int index) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _showUpdateOperatorDialog(operator, index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.edit,
                size: 14,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _deleteOperator(operator.id!),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.delete,
                size: 14,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty actions cell for new entry rows
  Widget _emptyActionsCell() {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  List<Widget> _buildEditableCells(int row) {
    final newRowIndex = row - controller.operators.length;
    return [
      _cell(180, newEntryControllers[newRowIndex][0], ''),
      _cell(180, newEntryControllers[newRowIndex][1], ''),
      _cell(200, newEntryControllers[newRowIndex][2], ''),
      _cell(160, newEntryControllers[newRowIndex][3], ''),
      _cell(200, newEntryControllers[newRowIndex][4], ''),
      _cell(120, newEntryControllers[newRowIndex][5], ''),
    ];
  }
}

/// =======================================================
/// HEADER CELL WIDGET (COMPACT VERSION)
/// =======================================================
class _HeaderCell extends StatelessWidget {
  final double width;
  final String text;
  final IconData icon;

  const _HeaderCell({
    required this.width,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}