import 'package:flutter/material.dart';

class DailyCostEngineeringTable extends StatefulWidget {
  const DailyCostEngineeringTable({super.key});

  @override
  State<DailyCostEngineeringTable> createState() => _DailyCostEngineeringTableState();
}

class _DailyCostEngineeringTableState extends State<DailyCostEngineeringTable> {
  // Scroll controllers for the table
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _totalHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Synchronize header and data horizontal scrolling
    _horizontalController.addListener(() {
      _headerHorizontalController.jumpTo(_horizontalController.offset);
      _totalHorizontalController.jumpTo(_horizontalController.offset);
    });
    _headerHorizontalController.addListener(() {
      _horizontalController.jumpTo(_headerHorizontalController.offset);
      _totalHorizontalController.jumpTo(_headerHorizontalController.offset);
    });
    _totalHorizontalController.addListener(() {
      _horizontalController.jumpTo(_totalHorizontalController.offset);
      _headerHorizontalController.jumpTo(_totalHorizontalController.offset);
    });
  }

  static const double rowH = 32.0;
  static const double subColW = 120.0;

  // Data for the table
  List<List<String>> leftRowData = List.generate(50, (index) => List.generate(4, (_) => ''));
  List<List<String>> rightRowData = List.generate(50, (index) => List.generate(20, (_) => ''));

  // Total row data
  List<String> leftTotalData = List.generate(4, (_) => '');
  List<String> rightTotalData = List.generate(20, (_) => '');

  // Table Sub-columns (Chemical Products)
  final List<String> subColumns = [
    'Mud Supervisor-2'
  ];

  int get totalSubCols => subColumns.length;
  double get scrollableWidth => totalSubCols * subColW;

  Widget _fixedCell(String t, double w, {bool bold = false, bool isHeader = false, bool isTotal = false}) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isHeader ? Colors.white.withOpacity(0.3) : const Color(0xffE2E8F0),
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

  Widget _editableFixedCell(int rowIndex, int colIndex, double w) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE2E8F0), width: 0.5),
      ),
      child: TextField(
        controller: TextEditingController(text: leftRowData[rowIndex][colIndex]),
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
          hintText: colIndex == 0 ? '${rowIndex + 1}' : 
                   colIndex == 1 ? 'MM/DD/YYYY' : 
                   colIndex == 2 ? '0.00' : '1',
          hintStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
        onChanged: (value) {
          setState(() {
            leftRowData[rowIndex][colIndex] = value;
          });
        },
      ),
    );
  }

  Widget _totalFixedCell(int colIndex, double w) {
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
        controller: TextEditingController(text: leftTotalData[colIndex]),
        style: const TextStyle(
          fontSize: 11,
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
          hintText: colIndex == 0 ? 'TOTAL' : 
                   colIndex == 1 ? '' : 
                   colIndex == 2 ? '0.00' : '',
          hintStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1890FF).withOpacity(0.7),
          ),
        ),
        onChanged: (value) {
          setState(() {
            leftTotalData[colIndex] = value;
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

  Widget _editableScrollCell(int rowIndex, int colIndex, double w) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE2E8F0), width: 0.5),
      ),
      child: TextField(
        controller: TextEditingController(text: rightRowData[rowIndex][colIndex]),
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
            rightRowData[rowIndex][colIndex] = value;
          });
        },
      ),
    );
  }

  Widget _totalScrollCell(int colIndex, double w) {
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
        controller: TextEditingController(text: rightTotalData[colIndex]),
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
            rightTotalData[colIndex] = value;
          });
        },
      ),
    );
  }

  void _initializeData() {
    if (leftRowData[0][0].isEmpty) {
      for (int i = 0; i < 50; i++) {
        leftRowData[i][0] = '${i + 1}';
        leftRowData[i][1] = i < 3 ? '11/26/2025' : '';
        leftRowData[i][2] = i < 3 ? '96.0' : '';
        leftRowData[i][3] = i < 3 ? '1' : '';
      }
    }
    
    // Initialize total row with default values
    if (leftTotalData[0].isEmpty) {
      leftTotalData[0] = 'TOTAL';
      leftTotalData[2] = '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeData();
    
    return Container(
      color: const Color(0xffF8F9FA),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Title
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Daily Cost Engineering Table',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff2D3748),
              ),
            ),
          ),
          
          // Table Container
          Container(
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
                      _fixedCell('Date', 100, bold: true, isHeader: true),
                      _fixedCell('MD (ft)', 80, bold: true, isHeader: true),
                      _fixedCell('Rpt #', 79, bold: true, isHeader: true),
                      // Right Scrollable Header Cells
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _headerHorizontalController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: subColumns.map((sub) {
                              return _scrollCell(
                                '$sub\n(lb/bbl)',
                                subColW,
                                bold: true,
                                isHeader: true,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Data Rows
                SizedBox(
                  height: 400 - rowH, // Reduced height to accommodate total row
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Fixed Data Columns
                        Container(
                          width: 320,
                          color: Colors.white,
                          child: Column(
                            children: List.generate(
                              50,
                              (i) => Container(
                                height: rowH,
                                decoration: BoxDecoration(
                                  color: i.isOdd ? Colors.white : const Color(0xffF8F9FA),
                                ),
                                child: Row(
                                  children: [
                                    _editableFixedCell(i, 0, 60),
                                    _editableFixedCell(i, 1, 100),
                                    _editableFixedCell(i, 2, 80),
                                    _editableFixedCell(i, 3, 79),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right Scrollable Data Columns
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: scrollableWidth,
                              color: Colors.white,
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

                // Total Row
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
                        width: 320,
                        color: const Color(0xffE6F7FF),
                        child: Row(
                          children: [
                            _totalFixedCell(0, 60),
                            _totalFixedCell(1, 100),
                            _totalFixedCell(2, 80),
                            _totalFixedCell(3, 79),
                          ],
                        ),
                      ),

                      // Right Scrollable Total Cells
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _totalHorizontalController,
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
      ),
    );
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _headerHorizontalController.dispose();
    _verticalController.dispose();
    _totalHorizontalController.dispose();
    super.dispose();
  }
}