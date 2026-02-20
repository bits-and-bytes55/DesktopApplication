import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/products_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ProductsPage extends StatelessWidget {
  ProductsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductsController controller = Get.put(ProductsController(), tag: 'products_controller');

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
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Total Products: ${controller.existingProductIds.length}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12),
                  IconButton(
                    onPressed: () => controller.loadProducts(),
                    icon: Icon(Icons.refresh, color: Colors.white, size: 20),
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Table
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xffD1D5DB), width: 1),
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
                        child: _buildTable(controller, constraints),
                      ),
                    );
                  },
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
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: AppTheme.secondaryButtonStyle,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text('Close'),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: controller.isSaving.value
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
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTable(ProductsController controller, BoxConstraints constraints) {
    final double minWidth = 1050;
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
            (index) => _buildTableRow(controller, index, tableWidth),
          ),
        ],
      ),
    ));
  }

  Widget _buildTableHeader(double tableWidth) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppTheme.darkPrimaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _headerCell('No', tableWidth * 0.05),
          _headerCell('Product*', tableWidth * 0.16),
          _headerCell('Code*', tableWidth * 0.11),
          _headerCell('SG*', tableWidth * 0.07),
          Container(
            width: tableWidth * 0.14,
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
                    alignment: Alignment.center,
                    child: Text(
                      'Unit*',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1),
                            ),
                          ),
                          child: Text(
                            'Num',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            'Class',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _headerCell('Group*', tableWidth * 0.11),
          _headerCell('Retail', tableWidth * 0.09),
          _headerCell('Sales price', tableWidth * 0.09),
          _headerCell('COGS', tableWidth * 0.09),
          _headerCell('Actions', tableWidth * 0.09),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableRow(ProductsController controller, int index, double tableWidth) {
    final product = controller.products[index];
    final isLocked = controller.isExistingProduct(index);
    final isEditing = isLocked && controller.editingProductId.value == product.id;

    return Container(
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
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildCell(
            controller,
            tableWidth * 0.16,
            product.product,
            (val) => _updateField(controller, index, 'product', val),
            isLocked: isLocked && !isEditing,
            isEditing: isEditing,
          ),
          _buildCell(
            controller,
            tableWidth * 0.11,
            product.code,
            (val) => _updateField(controller, index, 'code', val),
            isLocked: isLocked && !isEditing,
            isEditing: isEditing,
          ),
          _buildCell(
            controller,
            tableWidth * 0.07,
            product.sg,
            (val) => _updateField(controller, index, 'sg', val),
            isNumeric: true,
            isLocked: isLocked && !isEditing,
            isEditing: isEditing,
          ),
          Container(
            width: tableWidth * 0.14,
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
                      (val) => _updateField(controller, index, 'unitNum', val),
                      isNumeric: true,
                      isLocked: isLocked && !isEditing,
                      isEditing: isEditing,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildCellContent(
                    controller,
                    product.unitClass,
                    (val) => _updateField(controller, index, 'unitClass', val),
                    isLocked: isLocked && !isEditing,
                    isEditing: isEditing,
                  ),
                ),
              ],
            ),
          ),
          _buildCell(
            controller,
            tableWidth * 0.11,
            product.group,
            (val) => _updateField(controller, index, 'group', val),
            isLocked: isLocked && !isEditing,
            isEditing: isEditing,
          ),
          _buildCell(
            controller,
            tableWidth * 0.09,
            product.retail,
            (val) => _updateField(controller, index, 'retail', val),
            isLocked: isLocked && !isEditing,
            isEditing: isEditing,
          ),
          _buildCell(
            controller,
            tableWidth * 0.09,
            product.a,
            (val) => _updateField(controller, index, 'sales price', val),
            isNumeric: true,
            isLocked: isLocked && !isEditing,
            isEditing: isEditing,
          ),
          _buildCell(
            controller,
            tableWidth * 0.09,
            product.b,
            (val) => _updateField(controller, index, 'COGS', val),
            isNumeric: true,
            isLocked: isLocked && !isEditing,
            isEditing: isEditing,
          ),
          _buildActionsCell(controller, tableWidth * 0.09, product, index, isLocked, isEditing),
        ],
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
        alignment: Alignment.center,
        child: Text(
          value,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      style: AppTheme.bodyLarge.copyWith(
        fontSize: 12,
        color: isEditing ? Colors.black : null,
      ),
      textAlign: TextAlign.center,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        isDense: true,
        filled: isEditing,
        fillColor: isEditing ? Colors.white : null,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildActionsCell(
    ProductsController controller,
    double width,
    ProductModel product,
    int index,
    bool isLocked,
    bool isEditing,
  ) {
    if (!isLocked) {
      return Container(
        width: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Color(0xffE5E7EB), width: 0.5),
          ),
        ),
        child: Text(
          '-',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
        ),
      );
    }

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xffE5E7EB), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isEditing) ...[
            // Save Button (confirm inline edit)
            IconButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () => controller.saveInlineEdit(product.id!),
              icon: controller.isSaving.value
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    )
                  : Icon(Icons.save, size: 16),
              color: Colors.green,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Save',
            ),
            SizedBox(width: 4),
            // Cancel Button
            IconButton(
              onPressed: () => controller.cancelInlineEdit(),
              icon: Icon(Icons.close, size: 16),
              color: Colors.orange,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Cancel',
            ),
          ] else ...[
            // Edit Button
            IconButton(
              onPressed: () => controller.startInlineEdit(product),
              icon: Icon(Icons.edit, size: 16),
              color: Colors.blue,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Edit',
            ),
            SizedBox(width: 4),
            // Delete Button
            IconButton(
              onPressed: () {
                controller.showDeleteConfirmation(
                  Get.context!,
                  product.id!,
                  product.product,
                );
              },
              icon: Icon(Icons.delete, size: 16),
              color: Colors.red,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
    );
  }

  void _updateField(ProductsController controller, int index, String field, String value) {
    if (index < 0 || index >= controller.products.length) return;

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

    controller.updateProduct(index, product);

    // Auto-add new row only for new (non-existing) products
    if (!isExisting && index == controller.products.length - 1 && product.hasData()) {
      controller.addProduct();
    }
  }
}