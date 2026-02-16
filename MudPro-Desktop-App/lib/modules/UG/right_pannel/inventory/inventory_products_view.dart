import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/producst_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryProductsView extends StatelessWidget {
  final c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // ================= MAIN PRODUCTS TABLE =================
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppTheme.headerGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.inventory, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Products Inventory',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Obx(() => Text(
                            '${c.products.length} items',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() => Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Table(
                            border: TableBorder.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            columnWidths: const {
                              0: FixedColumnWidth(40),
                              1: FixedColumnWidth(260),
                              2: FixedColumnWidth(90),
                              3: FixedColumnWidth(70),
                              4: FixedColumnWidth(90),
                              5: FixedColumnWidth(90),
                              6: FixedColumnWidth(90),
                              7: FixedColumnWidth(140),
                              8: FixedColumnWidth(90),
                              9: FixedColumnWidth(90),
                              10: FixedColumnWidth(70),
                            },
                            children: [
                              _headerRow([
                                '#',
                                'Product',
                                'Code',
                                'SG',
                                'Unit',
                                'Price',
                                'Initial',
                                'Group',
                                'Vol. Add',
                                'Calculate',
                                'Tax',
                              ]),
                              ...c.products.map((p) => _productRow(p)),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ================= BOTTOM TABLES =================
          Expanded(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      Expanded(child: _premixedMudTable()),
                      const SizedBox(height: 8),
                      Expanded(child: _obmTable()),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(flex: 1, child: _premixedMudTable()),
                      const SizedBox(width: 8),
                      Expanded(flex: 1, child: _obmTable()),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= PRODUCT ROW =================
  TableRow _productRow(ProductModel p) {
    return TableRow(
      decoration: BoxDecoration(
        color: p.id!.isEven ? Colors.white : AppTheme.cardColor,
      ),
      children: [
        _cell(p.id.toString()),
        _editableCell(p.product, onChanged: (v) {
          p.product = v;
          c.products.refresh();
        }),
        _editableCell(p.code, onChanged: (v) {
          p.code = v;
          c.products.refresh();
        }),
        _editableCell(p.sg, onChanged: (v) {
          p.sg = v;
          c.products.refresh();
        }),
        _editableCell(p.unit, onChanged: (v) {
          p.unit = v;
          c.products.refresh();
        }),
        _editableCell(p.price, onChanged: (v) {
          p.price = v;
          c.products.refresh();
        }),
        _editableCell(p.initial, onChanged: (v) {
          p.initial = v;
          c.products.refresh();
        }),
        _editableCell(p.group, onChanged: (v) {
          p.group = v;
          c.products.refresh();
        }),
        _checkbox(() => p.volAdd, (v) {
          p.volAdd = v;
          c.products.refresh();
        }),
        _checkbox(() => p.calculate, (v) {
          p.calculate = v;
          c.products.refresh();
        }),
        _checkbox(() => p.tax, (v) {
          p.tax = v;
          c.products.refresh();
        }),
      ],
    );
  }

  // ================= PREMIXED =================
  Widget _premixedMudTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.macro_off, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Premixed Mud',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
                columnWidths: const {
                  0: FixedColumnWidth(40),
                  1: FlexColumnWidth(),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(90),
                  4: FixedColumnWidth(90),
                  5: FixedColumnWidth(60),
                },
                children: [
                  _headerRow(['#', 'Description', 'MW', 'Leasing Fee', 'Mud Type', 'Tax']),
                  ...c.premixed.map((e) => TableRow(
                    decoration: BoxDecoration(
                      color: e.id.hashCode.isEven ? Colors.white : AppTheme.cardColor,
                    ),
                    children: [
                      _cell(e.id),
                      _editableCell(e.description, onChanged: (v) {
                        e.description = v;
                        c.premixed.refresh();
                      }),
                      _editableCell(e.mw, onChanged: (v) {
                        e.mw = v;
                        c.premixed.refresh();
                      }),
                      _editableCell(e.leasingFee, onChanged: (v) {
                        e.leasingFee = v;
                        c.premixed.refresh();
                      }),
                      _editableCell(e.mudType, onChanged: (v) {
                        e.mudType = v;
                        c.premixed.refresh();
                      }),
                      _checkbox(() => e.tax, (v) {
                        e.tax = v;
                        c.premixed.refresh();
                      }),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= OBM =================
  Widget _obmTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.oil_barrel, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '8.0 ppg OBM (70/30) with Bar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
                columnWidths: const {
                  0: FixedColumnWidth(40),
                  1: FlexColumnWidth(),
                  2: FixedColumnWidth(80),
                  3: FixedColumnWidth(80),
                  4: FixedColumnWidth(80),
                },
                children: [
                  _headerRow(['#', 'Product', 'Code', 'SG', 'Conc']),
                  ...c.obm.map((e) => TableRow(
                    decoration: BoxDecoration(
                      color: e.id.hashCode.isEven ? Colors.white : AppTheme.cardColor,
                    ),
                    children: [
                      _cell(e.id),
                      _editableCell(e.product, onChanged: (v) {
                        e.product = v;
                        c.obm.refresh();
                      }),
                      _editableCell(e.code, onChanged: (v) {
                        e.code = v;
                        c.obm.refresh();
                      }),
                      _editableCell(e.sg, onChanged: (v) {
                        e.sg = v;
                        c.obm.refresh();
                      }),
                      _editableCell(e.conc, onChanged: (v) {
                        e.conc = v;
                        c.obm.refresh();
                      }),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================
  TableRow _headerRow(List<String> h) => TableRow(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.05)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    children: h.map((e) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        e,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    )).toList(),
  );

  Widget _cell(String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Text(
      v,
      style: TextStyle(
        fontSize: 10,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        color: AppTheme.textPrimary,
      ),
    ),
  );

  Widget _editableCell(String value, {Function(String)? onChanged}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    child: Obx(() => c.isLocked.value
        ? Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textPrimary,
            ),
          )
        : Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextFormField(
              initialValue: value,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                border: InputBorder.none,
              ),
            ),
          )),
  );

  Widget _checkbox(bool Function() getter, Function(bool) onChange) {
    return Center(
      child: Obx(() => Container(
        decoration: BoxDecoration(
          color: getter() ? AppTheme.successColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: getter() ? AppTheme.successColor : Colors.grey.shade400,
          ),
        ),
        margin: const EdgeInsets.all(4),
        child: Checkbox(
          value: getter(),
          onChanged: c.isLocked.value ? null : (v) => onChange(v!),
          activeColor: AppTheme.successColor,
          checkColor: Colors.white,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      )),
    );
  }
}