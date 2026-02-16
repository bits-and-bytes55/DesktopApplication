import 'package:flutter/material.dart';

class ConcentrationCurrentTable extends StatefulWidget {
  const ConcentrationCurrentTable({super.key});

  @override
  State<ConcentrationCurrentTable> createState() => _ConcentrationCurrentTableState();
}

class _ConcentrationCurrentTableState extends State<ConcentrationCurrentTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalLeftController = ScrollController();
  final ScrollController _verticalRightController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Sync vertical scrolls
    _verticalLeftController.addListener(() {
      if (_verticalRightController.hasClients) {
        _verticalRightController.jumpTo(_verticalLeftController.offset);
      }
    });
    _verticalRightController.addListener(() {
      if (_verticalLeftController.hasClients) {
        _verticalLeftController.jumpTo(_verticalRightController.offset);
      }
    });
  }

  static const double rowH = 32.0;
  static const double headerH = 64.0; // Increased header height
  static const double groupWidth = 160.0;
  static const double subColWidth = 80.0;

  // Data for editable rows
  List<List<String>> productData = List.generate(100, (index) => 
    ['${index + 1}', 'Product ${index + 1}', 'lb/bbl'] + List.filled(10, '0.00')
  );

  Widget _cell(String t,
      {double w = 80,
      bool bold = false,
      Alignment a = Alignment.center,
      Color? bg,
      bool isHeader = false}) {
    return Container(
      width: w,
      height: isHeader ? headerH : rowH,
      alignment: a,
      padding: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bg ?? (isHeader ? Colors.transparent : null),
        border: Border.all(
          color: isHeader ? Colors.white.withOpacity(0.3) : Color(0xffE2E8F0),
          width: 0.5,
        ),
      ),
      child: isHeader 
          ? Align(
              alignment: Alignment.center,
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : Text(
              t,
              style: TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                color: isHeader ? Colors.white : Color(0xff2D3748),
              ),
            ),
    );
  }

  Widget _headerGroupTitle(String title) {
    return Container(
      width: groupWidth,
      height: rowH,
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
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _headerSubGroup() {
    return Container(
      width: groupWidth,
      height: rowH,
      child: Row(
        children: [
          Container(
            width: subColWidth,
            height: rowH,
            decoration: BoxDecoration(
              color: Color(0xff8BB8E8),
            ),
            child: Center(
              child: Text(
                'Start',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            width: subColWidth,
            height: rowH,
            decoration: BoxDecoration(
              color: Color(0xff8BB8E8),
            ),
            child: Center(
              child: Text(
                'End',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableCell({
    required String value,
    required double width,
    Alignment alignment = Alignment.center,
    Color? bg,
    bool isLeftTable = false,
    int rowIndex = 0,
    int colIndex = 0,
  }) {
    return Container(
      width: width,
      height: rowH,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: Color(0xffE2E8F0), width: 0.5),
      ),
      child: TextField(
        controller: TextEditingController(text: value),
        style: TextStyle(
          fontSize: 11,
          color: Color(0xff2D3748),
        ),
        textAlign: alignment == Alignment.centerLeft
            ? TextAlign.left
            : TextAlign.right,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: '',
          hintStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
        onChanged: (val) {
          setState(() {
            if (isLeftTable) {
              if (colIndex == 0) {
                productData[rowIndex][0] = val;
              } else if (colIndex == 1) {
                productData[rowIndex][1] = val;
              } else if (colIndex == 2) {
                productData[rowIndex][2] = val;
              }
            } else {
              // Right table data (columns 3-12)
              productData[rowIndex][colIndex + 3] = val;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xffF8F9FA),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== FIXED LEFT COLUMNS ==========
          Container(
            width: 340,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xffE2E8F0), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Fixed Header - Increased height
                Container(
                  height: headerH,
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
                  child: Row(children: [
                    _cell('#', w: 60, bold: true, isHeader: true),
                    _cell('Product', w: 180, bold: true, isHeader: true),
                    _cell('Conc. Unit', w: 99, bold: true, isHeader: true),
                  ]),
                ),
                
                // Fixed Data Rows - Editable
                Expanded(
                  child: Scrollbar(
                    controller: _verticalLeftController,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _verticalLeftController,
                      itemCount: productData.length,
                      itemBuilder: (_, i) => Container(
                        height: rowH,
                        decoration: BoxDecoration(
                          color: i.isOdd ? Colors.white : Color(0xffF8F9FA),
                        ),
                        child: Row(children: [
                          // # (Editable)
                          _editableCell(
                            value: productData[i][0],
                            width: 60,
                            alignment: Alignment.center,
                            isLeftTable: true,
                            rowIndex: i,
                            colIndex: 0,
                          ),

                          // Product Name (Editable)
                          _editableCell(
                            value: productData[i][1],
                            width: 180,
                            alignment: Alignment.centerLeft,
                            isLeftTable: true,
                            rowIndex: i,
                            colIndex: 1,
                          ),

                          // Conc. Unit (Editable)
                          _editableCell(
                            value: productData[i][2],
                            width: 99,
                            alignment: Alignment.center,
                            isLeftTable: true,
                            rowIndex: i,
                            colIndex: 2,
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ========== SCROLLABLE RIGHT ==========
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // HEADERS SECTION (2 rows)
                  SizedBox(
                    height: headerH,
                    child: Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: groupWidth * 5, // Fixed width for 5 groups
                          child: Column(
                            children: [
                              // Main Group Titles Row
                              Container(
                                height: rowH,
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
                                child: Row(
                                  children: [
                                    _headerGroupTitle('Active System'),
                                    _headerGroupTitle('Suction 4A'),
                                    _headerGroupTitle('Suction 4B'),
                                    _headerGroupTitle('Reserve 5A'),
                                    _headerGroupTitle('Reserve 5B'),
                                  ],
                                ),
                              ),
                              // Sub Headers Row
                              Container(
                                height: rowH,
                                child: Row(
                                  children: [
                                    _headerSubGroup(),
                                    _headerSubGroup(),
                                    _headerSubGroup(),
                                    _headerSubGroup(),
                                    _headerSubGroup(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // DATA ROWS SECTION (Editable)
                  Expanded(
                    child: Scrollbar(
                      controller: _verticalRightController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _verticalRightController,
                        scrollDirection: Axis.vertical,
                        child: Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: groupWidth * 5, // Fixed width for 5 groups
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: productData.length,
                                itemBuilder: (_, i) => Container(
                                  height: rowH,
                                  decoration: BoxDecoration(
                                    color: i.isOdd ? Colors.white : Color(0xffF8F9FA),
                                  ),
                                  child: Row(
                                    children: List.generate(
                                      10, // 5 groups × 2 columns each = 10 columns
                                      (j) => _editableCell(
                                        value: productData[i][j + 3],
                                        width: subColWidth,
                                        alignment: Alignment.centerRight,
                                        rowIndex: i,
                                        colIndex: j,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalLeftController.dispose();
    _verticalRightController.dispose();
    super.dispose();
  }
}