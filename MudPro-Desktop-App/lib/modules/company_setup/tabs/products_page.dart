import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/products_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_setup_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ProductsPage extends StatelessWidget {
  ProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductsController controller =
        Get.isRegistered<ProductsController>(tag: 'products_controller')
            ? Get.find<ProductsController>(tag: 'products_controller')
            : Get.put(
                ProductsController(),
                tag: 'products_controller',
              );
    final CompanySetupController setupController = Get.find<CompanySetupController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Products Management',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.companySetupHeaderTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Total Products: ${controller.existingProductIds.length}',
                    style: AppTheme.companySetupBodyMedium.copyWith(
                      color: AppTheme.companySetupHeaderTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () => controller.loadProducts(),
                    icon: Icon(Icons.refresh, color: AppTheme.companySetupHeaderTextColor, size: 20),
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Table
            Expanded(
              child: IgnorePointer(
                ignoring: setupController.isLocked.value,
                child: Opacity(
                  opacity: setupController.isLocked.value ? 0.6 : 1.0,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.tableBorderBlue, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildTable(context, controller, constraints),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xffE5E7EB), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
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
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => setupController.handleExport(),
                    style: AppTheme.secondaryButtonStyle,
                    icon: const Icon(Icons.file_download, size: 16),
                    label: const Text('Export'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: AppTheme.secondaryButtonStyle,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text('Close'),
                    ),
                  ),
                  SizedBox(width: 12),
                  IgnorePointer(
                    ignoring: setupController.isLocked.value,
                    child: Opacity(
                      opacity: setupController.isLocked.value ? 0.6 : 1.0,
                      child: ElevatedButton(
                        onPressed: (controller.isSaving.value || setupController.isLocked.value)
                            ? null
                            : () => controller.saveProducts(),
                        style: AppTheme.primaryButtonStyle,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: controller.isSaving.value
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text('Save'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTable(BuildContext context, ProductsController controller, BoxConstraints constraints) {
    final double minWidth = 980;
    final double tableWidth = constraints.maxWidth > minWidth
        ? constraints.maxWidth - 40
        : minWidth;

    return Obx(() => Container(
      width: tableWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTableHeader(tableWidth),
          ...List.generate(
            controller.products.length,
            (index) => _buildTableRow(context, controller, index, tableWidth),
          ),
        ],
      ),
    ));
  }

  Widget _buildTableHeader(double tableWidth) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _headerCell('No', tableWidth * 0.05),
          _headerCell('Product*', tableWidth * 0.19),
          _headerCell('Code*', tableWidth * 0.12),
          _headerCell('SG*', tableWidth * 0.08),
          Container(
            width: tableWidth * 0.15,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                right: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'Unit*',
                      style: AppTheme.companySetupHeaderDark,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Container(
                  height: 0.5,
                  color: Colors.white.withOpacity(0.2),
                ),
                Container(
                  height: 18,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1),
                            ),
                          ),
                          child: Text(
                            'Num',
                            style: AppTheme.companySetupHeaderDark,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            'Class',
                            style: AppTheme.companySetupHeaderDark,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _headerCell('Group*', tableWidth * 0.13),
          _headerCell('Retail', tableWidth * 0.10),
          _headerCell('Sales price', tableWidth * 0.09),
          _headerCell('COGS', tableWidth * 0.09),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width) {
    return Container(
      width: width,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
      ),
      child: Text(
        title,
        style: AppTheme.companySetupHeaderDark,
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, ProductsController controller, int index, double tableWidth) {
    final setupController = Get.find<CompanySetupController>();
    final product = controller.products[index];
    final isLocked = controller.isExistingProduct(index);
    final isEditing = isLocked && controller.editingProductId.value == product.id;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => _showRowContextMenu(
        context,
        controller,
        product,
        index,
        isLocked,
        isEditing,
        setupController,
        details.globalPosition,
      ),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: isEditing
              ? Color(0xffEFF6FF)
              : isLocked
                  ? Color(0xffF3F4F6)
                  : (index % 2 == 0 ? Color(0xffF9FAFB) : Colors.white),
          border: Border(
            bottom: BorderSide(color: Color(0xffE5E7EB), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // No Column
            Container(
              width: tableWidth * 0.05,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xffE5E7EB), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLocked && !isEditing)
                    Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.lock,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  if (isEditing)
                    Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.blue,
                      ),
                    ),
                   Text(
                     '${index + 1}',
                    style: AppTheme.companySetupBodyBold,
                   ),
                ],
              ),
            ),
            Obx(() {
              final globalLocked = setupController.isLocked.value;
              return Row(
                children: [
                  _buildCell(
                    controller,
                    tableWidth * 0.19,
                    product.product,
                    (val) => _updateField(controller, index, 'product', val, setupController),
                    isLocked: (isLocked && !isEditing) || globalLocked,
                    isEditing: isEditing && !globalLocked,
                  ),
                  _buildCell(
                    controller,
                    tableWidth * 0.12,
                    product.code,
                    (val) => _updateField(controller, index, 'code', val, setupController),
                    isLocked: (isLocked && !isEditing) || globalLocked,
                    isEditing: isEditing && !globalLocked,
                  ),
                  _buildCell(
                    controller,
                    tableWidth * 0.08,
                    product.sg,
                    (val) => _updateField(controller, index, 'sg', val, setupController),
                    isNumeric: true,
                    isLocked: (isLocked && !isEditing) || globalLocked,
                    isEditing: isEditing && !globalLocked,
                  ),
                  Container(
                    width: tableWidth * 0.15,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xffE5E7EB), width: 0.5),
                        right: BorderSide(color: Color(0xffE5E7EB), width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xffE5E7EB), width: 0.5),
                              ),
                            ),
                            child: _buildCellContent(
                              controller,
                              product.unitNum,
                              (val) => _updateField(controller, index, 'unitNum', val, setupController),
                              isNumeric: true,
                              isLocked: (isLocked && !isEditing) || globalLocked,
                              isEditing: isEditing && !globalLocked,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildCellContent(
                            controller,
                            product.unitClass,
                            (val) => _updateField(controller, index, 'unitClass', val, setupController),
                            isLocked: (isLocked && !isEditing) || globalLocked,
                            isEditing: isEditing && !globalLocked,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCell(
                    controller,
                    tableWidth * 0.13,
                    product.group,
                    (val) => _updateField(controller, index, 'group', val, setupController),
                    isLocked: (isLocked && !isEditing) || globalLocked,
                    isEditing: isEditing && !globalLocked,
                  ),
                  _buildCell(
                    controller,
                    tableWidth * 0.10,
                    product.retail,
                    (val) => _updateField(controller, index, 'retail', val, setupController),
                    isLocked: (isLocked && !isEditing) || globalLocked,
                    isEditing: isEditing && !globalLocked,
                  ),
                  _buildCell(
                    controller,
                    tableWidth * 0.09,
                    product.a,
                    (val) => _updateField(controller, index, 'sales price', val, setupController),
                    isNumeric: true,
                    isLocked: (isLocked && !isEditing) || globalLocked,
                    isEditing: isEditing && !globalLocked,
                  ),
                  _buildCell(
                    controller,
                    tableWidth * 0.09,
                    product.b,
                    (val) => _updateField(controller, index, 'COGS', val, setupController),
                    isNumeric: true,
                    isLocked: (isLocked && !isEditing) || globalLocked,
                    isEditing: isEditing && !globalLocked,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(
    ProductsController controller,
    double width,
    String value,
    Function(String) onChanged, {
    bool isNumeric = false,
    bool isLocked = false,
    bool isEditing = false,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xffE5E7EB), width: 0.5),
        ),
      ),
      child: _buildCellContent(
        controller,
        value,
        onChanged,
        isNumeric: isNumeric,
        isLocked: isLocked,
        isEditing: isEditing,
      ),
    );
  }

  Widget _buildCellContent(
    ProductsController controller,
    String value,
    Function(String) onChanged, {
    bool isNumeric = false,
    bool isLocked = false,
    bool isEditing = false,
  }) {
    if (isLocked && !isEditing) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: AppTheme.companySetupBodyText,
          textAlign: TextAlign.left,
        ),
      );
    }

    return _ProductCellEditor(
      value: value,
      onChanged: onChanged,
      isNumeric: isNumeric,
      isEditing: isEditing,
    );
  }

  Future<void> _showRowContextMenu(
    BuildContext context,
    ProductsController controller,
    ProductModel product,
    int index,
    bool isExisting,
    bool isEditing,
    CompanySetupController setupController,
    Offset position,
  ) async {
    if (setupController.isLocked.value) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<_ProductRowAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        _menuItem(_ProductRowAction.create, Icons.add, 'Add product'),
        if (isExisting && !isEditing)
          _menuItem(_ProductRowAction.edit, Icons.edit, 'Edit product'),
        if (product.hasData())
          _menuItem(
            _ProductRowAction.delete,
            Icons.delete,
            isExisting ? 'Delete product' : 'Remove row',
            isDestructive: true,
          ),
      ],
    );

    switch (selected) {
      case _ProductRowAction.create:
        controller.addProduct();
        break;
      case _ProductRowAction.edit:
        controller.startInlineEdit(product);
        break;
      case _ProductRowAction.delete:
        if (isExisting && product.id != null) {
          controller.showDeleteConfirmation(
            context,
            product.id!,
            product.product,
          );
        } else {
          controller.removeUnsavedProduct(index);
        }
        break;
      case null:
        break;
    }
  }

  PopupMenuItem<_ProductRowAction> _menuItem(
    _ProductRowAction action,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : AppTheme.textPrimary;
    return PopupMenuItem<_ProductRowAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.companySetupBodyText.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  void _updateField(ProductsController controller, int index, String field, String value, CompanySetupController setupController) {
    if (index < 0 || index >= controller.products.length) return;
    if (setupController.isLocked.value) return;

    final product = controller.products[index];
    final isExisting = controller.isExistingProduct(index);
    final isEditing = isExisting && controller.editingProductId.value == product.id;

    // Allow update only for new rows or rows currently being inline-edited
    if (isExisting && !isEditing) return;

    switch (field) {
      case 'product':
        product.product = value;
        break;
      case 'code':
        product.code = value;
        break;
      case 'sg':
        product.sg = value;
        break;
      case 'unitNum':
        product.unitNum = value;
        break;
      case 'unitClass':
        product.unitClass = value;
        break;
      case 'group':
        product.group = value;
        break;
      case 'retail':
        product.retail = value;
        break;
      case 'sales price':
        product.a = value;
        break;
      case 'COGS':
        product.b = value;
        break;
    }

    controller.updateProduct(index, product, refresh: false);
    controller.queueAutoSave(index);

    // Auto-add new row only for new (non-existing) products
    if (!isExisting && index == controller.products.length - 1 && product.hasData()) {
      controller.addProduct();
    }
  }
}

enum _ProductRowAction { create, edit, delete }

class _ProductCellEditor extends StatefulWidget {
  const _ProductCellEditor({
    required this.value,
    required this.onChanged,
    required this.isNumeric,
    required this.isEditing,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool isNumeric;
  final bool isEditing;

  @override
  State<_ProductCellEditor> createState() => _ProductCellEditorState();
}

class _ProductCellEditorState extends State<_ProductCellEditor> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _ProductCellEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _textController.text) {
      _textController.text = widget.value;
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      style: AppTheme.companySetupBodyText.copyWith(
        color: widget.isEditing ? AppTheme.companySetupText : null,
      ),
      textAlign: TextAlign.left,
      keyboardType: widget.isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        isDense: true,
        filled: widget.isEditing,
        fillColor: widget.isEditing ? Colors.white : null,
      ),
      onChanged: widget.onChanged,
    );
  }
}
