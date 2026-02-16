import 'package:flutter/material.dart';

class DepthCostProductTable extends StatefulWidget {
  const DepthCostProductTable({super.key});

  @override
  State<DepthCostProductTable> createState() => _DepthCostProductTableState();
}

class _DepthCostProductTableState extends State<DepthCostProductTable> {
  // Scroll controllers for both tables
  final ScrollController _table1HorizontalController = ScrollController();
  final ScrollController _table1HeaderHorizontalController = ScrollController();
  final ScrollController _table1TotalHorizontalController = ScrollController();
  final ScrollController _table1LeftVerticalController = ScrollController();
  final ScrollController _table1RightVerticalController = ScrollController();
  final ScrollController _table2HorizontalController = ScrollController();
  final ScrollController _table2HeaderHorizontalController = ScrollController();
  final ScrollController _table2TotalHorizontalController = ScrollController();
  final ScrollController _table2LeftVerticalController = ScrollController();
  final ScrollController _table2RightVerticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Synchronize table 1 header and data horizontal scrolling
    _table1HorizontalController.addListener(() {
      if (_table1HeaderHorizontalController.hasClients) {
        _table1HeaderHorizontalController.jumpTo(_table1HorizontalController.offset);
      }
      if (_table1TotalHorizontalController.hasClients) {
        _table1TotalHorizontalController.jumpTo(_table1HorizontalController.offset);
      }
    });

    // Synchronize table 2 header and data horizontal scrolling
    _table2HorizontalController.addListener(() {
      if (_table2HeaderHorizontalController.hasClients) {
        _table2HeaderHorizontalController.jumpTo(_table2HorizontalController.offset);
      }
      if (_table2TotalHorizontalController.hasClients) {
        _table2TotalHorizontalController.jumpTo(_table2HorizontalController.offset);
      }
    });
  }

  static const double rowH = 32.0;
  static const double subColW = 120.0;

  // Data for Table 1
  List<List<String>> table1LeftRowData = List.generate(50, (index) => List.generate(2, (_) => ''));
  List<List<String>> table1RightRowData = List.generate(50, (index) => List.generate(6, (_) => ''));
  
  // Total data for Table 1
  List<String> table1LeftTotalData = List.generate(2, (_) => '');
  List<String> table1RightTotalData = List.generate(6, (_) => '');

  // Data for Table 2
  List<List<String>> table2LeftRowData = List.generate(50, (index) => List.generate(2, (_) => ''));
  List<List<String>> table2RightRowData = List.generate(50, (index) => List.generate(27, (_) => ''));
  
  // Total data for Table 2
  List<String> table2LeftTotalData = List.generate(2, (_) => '');
  List<String> table2RightTotalData = List.generate(27, (_) => '');

  // Table 1 Sub-columns (Chemical Products)
  final List<String> table1SubColumns = [
    'Product',
    'Premixed Mud',
    'Package',
    'Service',
    'Engineering',
    'Total'
  ];

  // Table 2 Sub-columns (Equipment & Services)
  final List<String> table2SubColumns = [
    'Premixed Mud',
    'Filteration Control',
    'Others',
    'Common Chemicals',
    'Weighting Materials',
    'Wellbore Strengthening',
    'Wetting Agents',
    'OBM Viscosifiers',
    'Viscosifiers',
    'OBM Thinner',
    'Biocides',
    'DRILL PIPE RENTAL',
    'DRILL COLLAR RENTAL',
    'HEAVY WEIGHT RENTAL',
    'MUD PUMP SERVICE',
    'CEMENTING SERVICE',
    'WIRELINE SERVICE',
    'MUD LOGGING',
    'WELL TESTING',
    'CRA SERVICE',
    'DRILLING BITS',
    'REAMERS',
    'STABILIZERS',
    'SHOCK TOOLS',
    'MAPPING',
    'DATA PROCESSING',
    'REPORTING',
  ];

  int get table1TotalSubCols => table1SubColumns.length;
  int get table2TotalSubCols => table2SubColumns.length;

  double get table1ScrollableWidth => table1TotalSubCols * subColW;
  double get table2ScrollableWidth => table2TotalSubCols * subColW;

  Widget _fixedCell(String t, double w, {bool bold = false, bool isHeader = false, bool isTotal = false}) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isHeader ? Colors.white.withOpacity(0.3) : 
                isTotal ? const Color(0xff1890FF).withOpacity(0.3) : const Color(0xffE2E8F0),
          width: 0.5,
        ),
        color: isTotal ? const Color(0xffE6F7FF) : (isHeader ? Colors.transparent : null),
      ),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isTotal || bold ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? Colors.white : (isTotal ? const Color(0xff1890FF) : const Color(0xff2D3748)),
        ),
      ),
    );
  }

  Widget _editableFixedCell(int rowIndex, int colIndex, double w, List<List<String>> rowData) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE2E8F0), width: 0.5),
      ),
      child: TextField(
        controller: TextEditingController(text: rowData[rowIndex][colIndex]),
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xff2D3748),
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: colIndex == 0 ? '${rowIndex + 1}' : '0.00',
          hintStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
        onChanged: (value) {
          setState(() {
            rowData[rowIndex][colIndex] = value;
          });
        },
      ),
    );
  }

  Widget _totalFixedCell(int colIndex, double w, List<String> totalData) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff1890FF).withOpacity(0.3), width: 0.5),
        color: const Color(0xffE6F7FF),
      ),
      child: TextField(
        controller: TextEditingController(text: totalData[colIndex]),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xff1890FF),
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: colIndex == 0 ? 'TOTAL' : '0.00',
          hintStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1890FF).withOpacity(0.7),
          ),
        ),
        onChanged: (value) {
          setState(() {
            totalData[colIndex] = value;
          });
        },
      ),
    );
  }

  Widget _scrollCell(String t, double w, {bool bold = false, bool isHeader = false, bool isTotal = false}) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isHeader ? Colors.white.withOpacity(0.3) : 
                isTotal ? const Color(0xff1890FF).withOpacity(0.3) : const Color(0xffE2E8F0),
          width: 0.5,
        ),
        color: isTotal ? const Color(0xffE6F7FF) : (isHeader ? (bold ? const Color(0xff8BB8E8) : Colors.transparent) : null),
      ),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isTotal || bold ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? Colors.white : (isTotal ? const Color(0xff1890FF) : const Color(0xff2D3748)),
        ),
      ),
    );
  }

  Widget _editableScrollCell(int rowIndex, int colIndex, double w, List<List<String>> rowData) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE2E8F0), width: 0.5),
      ),
      child: TextField(
        controller: TextEditingController(text: rowData[rowIndex][colIndex]),
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xff2D3748),
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: '0.00',
          hintStyle: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade400,
          ),
        ),
        onChanged: (value) {
          setState(() {
            rowData[rowIndex][colIndex] = value;
          });
        },
      ),
    );
  }

  Widget _totalScrollCell(int colIndex, double w, List<String> totalData) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xff1890FF).withOpacity(0.3), width: 0.5),
        color: const Color(0xffE6F7FF),
      ),
      child: TextField(
        controller: TextEditingController(text: totalData[colIndex]),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xff1890FF),
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: '0.00',
          hintStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1890FF).withOpacity(0.7),
          ),
        ),
        onChanged: (value) {
          setState(() {
            totalData[colIndex] = value;
          });
        },
      ),
    );
  }

  Widget _buildTable({
    required String title,
    required List<String> subColumns,
    required int totalSubCols,
    required double scrollableWidth,
    required ScrollController horizontalController,
    required ScrollController headerHorizontalController,
    required ScrollController totalHorizontalController,
    required ScrollController leftVerticalController,
    required ScrollController rightVerticalController,
    required List<List<String>> leftRowData,
    required List<List<String>> rightRowData,
    required List<String> leftTotalData,
    required List<String> rightTotalData,
    required VoidCallback initializeData,
  }) {
    initializeData();

    const double tableHeight = 334.0;
    final double dataHeight = tableHeight - (rowH * 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Title
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff2D3748),
            ),
          ),
        ),

        // Table Container with fixed height
        Container(
          height: tableHeight, // Fixed height for vertical scrolling
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xffE2E8F0)),
          ),
          child: Column(
            children: [
              // Fixed Header Row
              Container(
                height: rowH,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff6C9BCF),
                      Color(0xff5A8BC5),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    // Left Fixed Header Cells
                    _fixedCell('No', 60, bold: true, isHeader: true),
                    _fixedCell('MD (ft)', 80, bold: true, isHeader: true),
                    // Right Scrollable Header Cells
                    Expanded(
                      child: SingleChildScrollView(
                        controller: headerHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: scrollableWidth,
                          child: Row(
                            children: subColumns.map((sub) {
                              return _scrollCell(
                                sub,
                                subColW,
                                bold: true,
                                isHeader: true,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Data Rows with reduced height
              Expanded(
                child: Row(
                  children: [
                    // Left Fixed Data Columns
                    Container(
                      width: 140,
                      height: dataHeight,
                      color: Colors.white,
                      child: Scrollbar(
                        controller: leftVerticalController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: leftVerticalController,
                          shrinkWrap: false,
                          itemCount: 50,
                          itemBuilder: (context, i) => Container(
                            height: rowH,
                            decoration: BoxDecoration(
                              color: i.isOdd ? Colors.white : const Color(0xffF8F9FA),
                            ),
                            child: Row(
                              children: [
                                _editableFixedCell(i, 0, 60, leftRowData),
                                _editableFixedCell(i, 1, 80, leftRowData),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right Scrollable Data Columns
                    Expanded(
                      child: Scrollbar(
                        controller: horizontalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: scrollableWidth,
                            child: Scrollbar(
                              controller: rightVerticalController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: rightVerticalController,
                                scrollDirection: Axis.vertical,
                                child: SizedBox(
                                  height: 50 * rowH, // Total height of all data rows
                                  child: Column(
                                    children: List.generate(
                                      50,
                                      (rowIndex) => Container(
                                        height: rowH,
                                        decoration: BoxDecoration(
                                          color: rowIndex.isOdd ? Colors.white : const Color(0xffF8F9FA),
                                        ),
                                        child: Row(
                                          children: List.generate(
                                            totalSubCols,
                                            (colIndex) => _editableScrollCell(
                                              rowIndex,
                                              colIndex,
                                              subColW,
                                              rightRowData,
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
                      ),
                    ),
                  ],
                ),
              ),

              // Total Row (Fixed at bottom)
              Container(
                height: rowH,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: const Color(0xff1890FF).withOpacity(0.5), width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    // Left Fixed Total Cells
                    Container(
                      width: 140,
                      color: const Color(0xffE6F7FF),
                      child: Row(
                        children: [
                          _totalFixedCell(0, 60, leftTotalData),
                          _totalFixedCell(1, 80, leftTotalData),
                        ],
                      ),
                    ),

                    // Right Scrollable Total Cells
                    Expanded(
                      child: SingleChildScrollView(
                        controller: totalHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width: scrollableWidth,
                          color: const Color(0xffE6F7FF),
                          child: Row(
                            children: List.generate(
                              totalSubCols,
                              (colIndex) => _totalScrollCell(
                                colIndex,
                                subColW,
                                rightTotalData,
                              ),
                            ),
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
      ],
    );
  }

  void _initializeTable1Data() {
    if (table1LeftRowData[0][0].isEmpty) {
      for (int i = 0; i < 50; i++) {
        table1LeftRowData[i][0] = '${i + 1}';
        table1LeftRowData[i][1] = i < 3 ? '96.0' : '';
      }
    }
    
    if (table1LeftTotalData[0].isEmpty) {
      table1LeftTotalData[0] = 'TOTAL';
      table1LeftTotalData[1] = '0.00';
    }
  }

  void _initializeTable2Data() {
    if (table2LeftRowData[0][0].isEmpty) {
      for (int i = 0; i < 50; i++) {
        table2LeftRowData[i][0] = '${i + 1}';
        table2LeftRowData[i][1] = i < 3 ? '105.5' : '';
      }
    }
    
    if (table2LeftTotalData[0].isEmpty) {
      table2LeftTotalData[0] = 'TOTAL';
      table2LeftTotalData[1] = '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF8F9FA),
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // First Table - Chemical Products
          _buildTable(
            title: 'Depth Cost - All Categories',
            subColumns: table1SubColumns,
            totalSubCols: table1TotalSubCols,
            scrollableWidth: table1ScrollableWidth,
            horizontalController: _table1HorizontalController,
            headerHorizontalController: _table1HeaderHorizontalController,
            totalHorizontalController: _table1TotalHorizontalController,
            leftVerticalController: _table1LeftVerticalController,
            rightVerticalController: _table1RightVerticalController,
            leftRowData: table1LeftRowData,
            rightRowData: table1RightRowData,
            leftTotalData: table1LeftTotalData,
            rightTotalData: table1RightTotalData,
            initializeData: _initializeTable1Data,
          ),

          const SizedBox(height: 32.0),

          // Second Table - Equipment & Services
          _buildTable(
            title: 'Depth Cost - Group',
            subColumns: table2SubColumns,
            totalSubCols: table2TotalSubCols,
            scrollableWidth: table2ScrollableWidth,
            horizontalController: _table2HorizontalController,
            headerHorizontalController: _table2HeaderHorizontalController,
            totalHorizontalController: _table2TotalHorizontalController,
            leftVerticalController: _table2LeftVerticalController,
            rightVerticalController: _table2RightVerticalController,
            leftRowData: table2LeftRowData,
            rightRowData: table2RightRowData,
            leftTotalData: table2LeftTotalData,
            rightTotalData: table2RightTotalData,
            initializeData: _initializeTable2Data,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _table1HorizontalController.dispose();
    _table1HeaderHorizontalController.dispose();
    _table1TotalHorizontalController.dispose();
    _table1LeftVerticalController.dispose();
    _table1RightVerticalController.dispose();
    _table2HorizontalController.dispose();
    _table2HeaderHorizontalController.dispose();
    _table2TotalHorizontalController.dispose();
    _table2LeftVerticalController.dispose();
    _table2RightVerticalController.dispose();
    super.dispose();
  }
}