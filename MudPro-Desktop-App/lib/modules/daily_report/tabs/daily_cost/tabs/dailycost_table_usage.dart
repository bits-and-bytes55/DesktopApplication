import 'package:flutter/material.dart';

class DailyCostTableUsagePage extends StatefulWidget {
  const DailyCostTableUsagePage({super.key});

  @override
  State<DailyCostTableUsagePage> createState() =>
      _DailyCostTableUsagePageState();
}

class _DailyCostTableUsagePageState extends State<DailyCostTableUsagePage> {
  final ScrollController _h = ScrollController();
  final ScrollController _v = ScrollController();

  static const double rowHeight = 32;

  // EXACT SAME COLUMN ORDER
  final List<double> col = [
    60,  // #
    160, // Category
    200, // Item
    80,  // Price
    80,  // Rec
    80,  // Ret
    80,  // Used
    80,  // Initial
    80,  // Rec
    80,  // Ret
    80,  // Adj
    80,  // Used
    80,  // Final
    100, // Subtotal
    80,  // Cost $
    80,  // Cost %
    80,  // Total $
    78,  // Total %
  ];

  double get tableWidth => col.reduce((a, b) => a + b);

  // ================= CELL =================
  Widget cell(
    String v,
    double w, {
    bool bold = false,
    Alignment a = Alignment.center,
    Color? bg,
    double? h,
    bool isHeader = false,
  }) {
    return Container(
      width: w,
      height: h ?? rowHeight,
      alignment: a,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: isHeader 
            ? Colors.white.withOpacity(0.3) 
            : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Text(
        v,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? Colors.white : Colors.grey.shade800,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ================= HEADER =================
  Widget header() {
    Widget h(String t, double w, {bool isHeader = false}) => 
        cell(t, w, bold: true, isHeader: isHeader);

    return Column(
      children: [
        Container(
          height: rowHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff6C9BCF),
                Color(0xff5A8BC5),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            h('#', col[0], isHeader: true),
            h('Category', col[1], isHeader: true),
            h('Item', col[2], isHeader: true),
            h('Price', col[3], isHeader: true),
            Container(
              width: col[4] * 3,
              height: rowHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                'Cumulative',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            h('Initial', col[7], isHeader: true),
            h('Rec.', col[8], isHeader: true),
            h('Ret.', col[9], isHeader: true),
            h('Adj.', col[10], isHeader: true),
            h('Used', col[11], isHeader: true),
            h('Final', col[12], isHeader: true),
            h('Subtotal', col[13], isHeader: true),
            Container(
              width: col[14] * 2,
              height: rowHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                'Cost',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              width: col[16] + col[17],
              height: rowHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                'Total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
        ),
        Container(
          height: rowHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff8BB8E8),
                Color(0xff7AA8D8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(children: [
            cell('', col[0], isHeader: true),
            cell('', col[1], isHeader: true),
            cell('', col[2], isHeader: true),
            cell('', col[3], isHeader: true),
            h('Rec.', col[4], isHeader: true),
            h('Ret.', col[5], isHeader: true),
            h('Used', col[6], isHeader: true),
            cell('', col[7], isHeader: true),
            cell('', col[8], isHeader: true),
            cell('', col[9], isHeader: true),
            cell('', col[10], isHeader: true),
            cell('', col[11], isHeader: true),
            cell('', col[12], isHeader: true),
            cell('', col[13], isHeader: true),
            h('\$', col[14], isHeader: true),
            h('%', col[15], isHeader: true),
            h('\$', col[16], isHeader: true),
            h('%', col[17], isHeader: true),
          ]),
        ),
      ],
    );
  }

  // ================= EDITABLE CELL =================
  Widget editableCell({
    required String initialValue,
    required double width,
    Alignment alignment = Alignment.center,
    Color? bg,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      width: width,
      height: rowHeight,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade800,
        ),
        textAlign: alignment == Alignment.centerLeft 
            ? TextAlign.left 
            : TextAlign.right,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: '',
          hintStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
        keyboardType: keyboardType,
        onChanged: (val) {
          // Handle data change
        },
      ),
    );
  }

  // ================= DATA ROW =================
  Widget dataRow(int i, {bool isProduct = true}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      cell('$i', col[0]),
      cell('', col[1]),
      editableCell(
        initialValue: 'Item $i',
        width: col[2],
        alignment: Alignment.centerLeft,
      ),
      editableCell(
        initialValue: '12.50',
        width: col[3],
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
      editableCell(
        initialValue: '10',
        width: col[4],
        keyboardType: TextInputType.number,
      ),
      editableCell(
        initialValue: '2',
        width: col[5],
        keyboardType: TextInputType.number,
      ),
      editableCell(
        initialValue: '8',
        width: col[6],
        keyboardType: TextInputType.number,
      ),
      editableCell(
        initialValue: '0',
        width: col[7],
        keyboardType: TextInputType.number,
      ),
      editableCell(
        initialValue: '0',
        width: col[8],
        keyboardType: TextInputType.number,
      ),
      editableCell(
        initialValue: '0',
        width: col[9],
        keyboardType: TextInputType.number,
      ),
      editableCell(
        initialValue: '0',
        width: col[10],
        keyboardType: TextInputType.number,
      ),
      editableCell(
        initialValue: '8',
        width: col[11],
        keyboardType: TextInputType.number,
      ),
      editableCell(
        initialValue: '8',
        width: col[12],
        keyboardType: TextInputType.number,
      ),
      editableCell(
        initialValue: '100',
        width: col[13],
        keyboardType: TextInputType.number,
      ),
      cell('', col[14]),
      cell('', col[15]),
      cell('', col[16]),
      cell('', col[17]),
    ]);
  }

  // ================= SUMMARY ROW =================
  Widget summaryRow(String label, String value) {
    return Row(children: [
      Container(
        width: tableWidth - col.last,
        height: rowHeight,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      Container(
        width: col.last,
        height: rowHeight,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xff6C9BCF),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    const int productRows = 20;
    const int engineeringRows = 6;

    return Scaffold(
      backgroundColor: Color(0xffFAF9F6), // AppTheme.backgroundColor
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(0xffE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Scrollbar(
            controller: _h,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _h,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header(),

                    Expanded(
                      child: Scrollbar(
                        controller: _v,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _v,
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Column(
                                    children: [
                                      for (int i = 1; i <= productRows; i++)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: i.isOdd
                                                ? Colors.white
                                                : Color(0xffF8F9FA),
                                          ),
                                          child: dataRow(i, isProduct: true),
                                        ),
                                      for (int i = 1; i <= engineeringRows; i++)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: (productRows + i).isOdd
                                                ? Colors.white
                                                : Color(0xffF8F9FA),
                                          ),
                                          child: dataRow(productRows + i, isProduct: false),
                                        ),
                                    ],
                                  ),
                                  Positioned(
                                    left: col[0],
                                    top: 0,
                                    child: Container(
                                      width: col[1],
                                      height: productRows * rowHeight,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: Color(0xffE8F4FD),
                                        border: Border.all(color: Colors.grey.shade200, width: 0.5),
                                      ),
                                      child: Text(
                                        'Product',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff6C9BCF),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: col[0],
                                    top: productRows * rowHeight,
                                    child: Container(
                                      width: col[1],
                                      height: engineeringRows * rowHeight,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: BoxDecoration(
                                        color: Color(0xffF0E8FD),
                                        border: Border.all(color: Colors.grey.shade200, width: 0.5),
                                      ),
                                      child: Text(
                                        'Engineering',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xffA8D5BA),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: tableWidth - col[16] - col[17],
                                    top: 0,
                                    child: Row(children: [
                                      Container(
                                        width: col[16],
                                        height: productRows * rowHeight,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: Color(0xffE8F4FD).withOpacity(0.7),
                                          border: Border.all(color: Colors.grey.shade200, width: 0.5),
                                        ),
                                        child: Text(
                                          '5000',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xff6C9BCF),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: col[17],
                                        height: productRows * rowHeight,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: Color(0xffE8F4FD).withOpacity(0.7),
                                          border: Border.all(color: Colors.grey.shade200, width: 0.5),
                                        ),
                                        child: Text(
                                          '85.8',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xff6C9BCF),
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                  Positioned(
                                    left: tableWidth - col[16] - col[17],
                                    top: productRows * rowHeight,
                                    child: Row(children: [
                                      Container(
                                        width: col[16],
                                        height: engineeringRows * rowHeight,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: Color(0xffF0E8FD).withOpacity(0.7),
                                          border: Border.all(color: Colors.grey.shade200, width: 0.5),
                                        ),
                                        child: Text(
                                          '520',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xffA8D5BA),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: col[17],
                                        height: engineeringRows * rowHeight,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: Color(0xffF0E8FD).withOpacity(0.7),
                                          border: Border.all(color: Colors.grey.shade200, width: 0.5),
                                        ),
                                        child: Text(
                                          '14.2',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xffA8D5BA),
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),

                              // ===== BOTTOM SUMMARY =====
                              summaryRow('Subtotal (\$)', '3655.70'),
                              summaryRow('Tax (0.000%)', '0.00'),
                              summaryRow('Daily Total (\$)', '3655.70'),
                              summaryRow('Prev. Total (\$)', '0.00'),
                              summaryRow('Cum. Total (\$)', '3655.70'),
                              summaryRow('Interval Total (\$)', '0.00'),
                              summaryRow('Stock Balance (\$)', '3655.70'),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xffF8F9FA),
                                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                                ),
                                child: summaryRow('Bulk Setup Fee (\$)', '17403.76'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}