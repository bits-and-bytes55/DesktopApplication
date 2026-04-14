import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/product_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/products_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ProductsPickupPage extends StatelessWidget {
  ProductsPickupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductsPickupController controller = Get.put(ProductsPickupController(), tag: 'products_pickup_controller');

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
                  SizedBox(width: 20),
                  Text(
                    'Selected: ${controller.selectedProducts.length}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
                    onPressed: controller.selectedProducts.isEmpty
                        ? null
                        : () {
                            controller.applySelectedProducts();
                            Get.back();
                            Get.snackbar(
                              'Success',
                              '${controller.selectedProducts.length} products applied to inventory',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Color(0xff10B981),
                              colorText: Colors.white,
                              duration: Duration(seconds: 2),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text('Apply Selected'),
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

  Widget _buildTable(ProductsPickupController controller, BoxConstraints constraints) {
    final double minWidth = 950;
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
          _headerCell('Product*', tableWidth * 0.18),
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
          _headerCell('Group*', tableWidth * 0.12),
          _headerCell('Retail', tableWidth * 0.10),
          _headerCell('Sales price', tableWidth * 0.10),
          _headerCell('COGS', tableWidth * 0.10),
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

  Widget _buildTableRow(ProductsPickupController controller, int index, double tableWidth) {
    final product = controller.products[index];
    final isLocked = controller.isExistingProduct(index);
    final isSelected = controller.isProductSelected(index);

    return InkWell(
      onTap: isLocked ? () => controller.toggleProductSelection(index) : null,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : (isLocked
                  ? Color(0xffF3F4F6)
                  : (index % 2 == 0 ? Color(0xffF9FAFB) : Colors.white)),
          border: Border(
            bottom: BorderSide(color: Color(0xffE5E7EB), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // No Column with selection indicator
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
                  if (isLocked)
                    Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.lock,
                        size: 12,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                    ),
                  Text(
                    '${index + 1}',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 12,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            _buildCell(
              controller,
              tableWidth * 0.18,
              product.product,
              (val) => _updateField(controller, index, 'product', val),
              isLocked: isLocked,
            ),
            _buildCell(
              controller,
              tableWidth * 0.12,
              product.code,
              (val) => _updateField(controller, index, 'code', val),
              isLocked: isLocked,
            ),
            _buildCell(
              controller,
              tableWidth * 0.08,
              product.sg,
              (val) => _updateField(controller, index, 'sg', val),
              isNumeric: true,
              isLocked: isLocked,
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
                        (val) => _updateField(controller, index, 'unitNum', val),
                        isNumeric: true,
                        isLocked: isLocked,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildCellContent(
                      controller,
                      product.unitClass,
                      (val) => _updateField(controller, index, 'unitClass', val),
                      isLocked: isLocked,
                    ),
                  ),
                ],
              ),
            ),
            _buildCell(
              controller,
              tableWidth * 0.12,
              product.group,
              (val) => _updateField(controller, index, 'group', val),
              isLocked: isLocked,
            ),
            _buildCell(
              controller,
              tableWidth * 0.10,
              product.retail,
              (val) => _updateField(controller, index, 'retail', val),
              isLocked: isLocked,
            ),
            _buildCell(
              controller,
              tableWidth * 0.10,
              product.a,
              (val) => _updateField(controller, index, 'sales price', val),
              isNumeric: true,
              isLocked: isLocked,
            ),
            _buildCell(
              controller,
              tableWidth * 0.10,
              product.b,
              (val) => _updateField(controller, index, 'COGS', val),
              isNumeric: true,
              isLocked: isLocked,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(
    ProductsPickupController controller,
    double width,
    String value,
    Function(String) onChanged, {
    bool isNumeric = false,
    bool isLocked = false,
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
      ),
    );
  }

  Widget _buildCellContent(
    ProductsPickupController controller,
    String value,
    Function(String) onChanged, {
    bool isNumeric = false,
    bool isLocked = false,
  }) {
    if (isLocked) {
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
      style: AppTheme.bodyLarge.copyWith(fontSize: 12),
      textAlign: TextAlign.center,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }

  void _updateField(ProductsPickupController controller, int index, String field, String value) {
    if (controller.isExistingProduct(index)) {
      return;
    }

    if (index < 0 || index >= controller.products.length) {
      return;
    }

    final product = controller.products[index];

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

    if (index == controller.products.length - 1 && product.hasData()) {
      controller.addProduct();
    }
  }
}