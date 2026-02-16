import 'package:flutter/material.dart';

class CumCostProductTable extends StatefulWidget {
  const CumCostProductTable({super.key});

  @override
  State<CumCostProductTable> createState() => _CumCostProductTableState();
}

class _CumCostProductTableState extends State<CumCostProductTable> {
 // Scroll controllers for both tables
  final ScrollController _table1HorizontalController = ScrollController();
  final ScrollController _table1HeaderHorizontalController = ScrollController();
  final ScrollController _table1TotalHorizontalController = ScrollController();
  final ScrollController _sharedVerticalController = ScrollController();
  final ScrollController _table2HorizontalController = ScrollController();
  final ScrollController _table2HeaderHorizontalController = ScrollController();
  final ScrollController _table2TotalHorizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Synchronize table 1 header and data horizontal scrolling
    _table1HorizontalController.addListener(() {
      _table1HeaderHorizontalController.jumpTo(_table1HorizontalController.offset);
    });
    _table1HeaderHorizontalController.addListener(() {
      _table1HorizontalController.jumpTo(_table1HeaderHorizontalController.offset);
    });

    // Synchronize table 2 header and data horizontal scrolling
    _table2HorizontalController.addListener(() {
      _table2HeaderHorizontalController.jumpTo(_table2HorizontalController.offset);
    });
    _table2HeaderHorizontalController.addListener(() {
      _table2HorizontalController.jumpTo(_table2HeaderHorizontalController.offset);
    });

    // Synchronize table 1 total horizontal scrolling
    _table1HorizontalController.addListener(() {
      _table1TotalHorizontalController.jumpTo(_table1HorizontalController.offset);
    });
    _table1TotalHorizontalController.addListener(() {
      _table1HorizontalController.jumpTo(_table1TotalHorizontalController.offset);
    });

    // Synchronize table 2 total horizontal scrolling
    _table2HorizontalController.addListener(() {
      _table2TotalHorizontalController.jumpTo(_table2HorizontalController.offset);
    });
    _table2TotalHorizontalController.addListener(() {
      _table2HorizontalController.jumpTo(_table2TotalHorizontalController.offset);
    });
  }

  static const double rowH = 32.0;
  static const double subColW = 120.0;

  // Data for Table 1
  List<List<String>> table1LeftRowData = List.generate(50, (index) => List.generate(4, (_) => ''));
  List<List<String>> table1RightRowData = List.generate(50, (index) => List.generate(50, (_) => ''));

  // Total data for Table 1
  List<String> table1LeftTotalData = List.generate(4, (_) => '');
  List<String> table1RightTotalData = List.generate(50, (_) => '');

  // Data for Table 2
  List<List<String>> table2LeftRowData = List.generate(50, (index) => List.generate(4, (_) => ''));
  List<List<String>> table2RightRowData = List.generate(50, (index) => List.generate(60, (_) => ''));

  // Total data for Table 2
  List<String> table2LeftTotalData = List.generate(4, (_) => '');
  List<String> table2RightTotalData = List.generate(60, (_) => '');

  // Table 1 Sub-columns (Chemical Products)
  final List<String> table1SubColumns = [
     'GILSONITE AQUASOL 300',
     'QMAXTROL',
     'MAXLIG',
    'BARITE 4.1 - BIG BAG',
     'GS SEAL',
   'SIZED CALCIUM..',
   'SIZED CALCIUM C.',
   'MAXWET XL',
   'SIZED CALCIUM..',
   'MAXCLAY',
   'QXAN',
    'CALCIUM CHLORIDE PE',
    'BENTONITE - TON',
    'QXAN',
    'QXAN PREMIUM',
    'HEC',
    'CAUSTIC SODA',
    'SODA ASH',
    'ZINC CARBONATE',
    
    // 'SODIUM BICARBONATE',
    // 'SODIUM CHLORIDE',
    // 'POTASSIUM CHLORIDE',
    // 'CALCIUM CHLORIDE',
    // 'MICA COARSE',
    // 'MICA FINE',
    // 'MICA MEDIUM',
    // 'NUTSHELLS COARSE',
    // 'NUTSHELLS FINE',
    // 'LCM MIX COARSE',
    // 'LCM MIX FINE',
    // 'LCM MIX MEDIUM',
    // 'COTTON SEEDS HULL',
    // 'NUTSHELLS MEDIUM',
    // 'FLC 2000',
    // 'QDEFOAM S',
    // 'QPAC LV',
    // 'QSTAR MT',
    // 'MAXLIG',
    // 'QSTAR HT',
    
    // 'QPAC HV',
    // 'QSCAV H2S',
    // 'MAXRELEASE W',
    // 'STRATALLEE',
    // 'QMAXBREAK',
    // 'MAXBEADS',
   
    // 'QSCAV O2',
    // 'MAXCAP L',
    // 'MAXPHALT L',
    // 'CBM 11.5 PPG OW',
    // 'CBM PPG OWR',
    // 'CITRIC ACID',
    // 'OBM 8.0 PPG OWR',
    // 'MAXSWEEP',
    // 'LIME',
    
    'SWELLBLOCK',
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
    // 'MOTORS',
    // 'MWD/LWD',
    // 'DRILLING CHEMICALS',
    // 'FUEL COST',
    // 'WATER TRANSPORT',
    // 'WASTE DISPOSAL',
    // 'CAMP SERVICES',
    // 'MEDICAL SERVICES',
    // 'SECURITY',
    // 'COMMUNICATIONS',
    // 'LABOR COST',
    // 'SUPERVISION',
    // 'ENGINEERING',
    // 'GEOLOGY',
    // 'ENVIRONMENTAL',
    // 'SAFETY EQUIPMENT',
    // 'FIRE FIGHTING',
    // 'FIRST AID',
    // 'PPE',
    // 'VEHICLE MAINT',
    // 'EQUIPMENT REPAIR',
    // 'TOOL RENTAL',
    // 'CRANE SERVICES',
    // 'LOADING/UNLOADING',
    // 'STORAGE COSTS',
    // 'INSURANCE',
    // 'PERMITS/LICENSES',
    // 'CUSTOMS CLEARANCE',
    // 'TAXES/LEVIES',
    // 'BANK CHARGES',
    // 'TRAVEL COSTS',
    // 'ACCOMMODATION',
    // 'FOOD CATERING',
    // 'LAUNDRY SERVICES',
    // 'OFFICE SUPPLIES',
    // 'IT SERVICES',
    // 'TRAINING COSTS',
    // 'AUDIT FEES',
    // 'LEGAL FEES',
    // 'CONSULTING FEES',
    // 'WEATHER SERVICES',
    // 'SATELLITE IMAGERY',
    // 'SURVEY COSTS',
    'MAPPING',
    'DATA PROCESSING',
    'REPORTING',
  ];

  int get table1TotalSubCols => table1SubColumns.length;
  int get table2TotalSubCols => table2SubColumns.length;

  double get table1ScrollableWidth => table1TotalSubCols * subColW;
  double get table2ScrollableWidth => table2TotalSubCols * subColW;

  Widget _fixedCell(String t, double w, {bool bold = false, bool isHeader = false}) {
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
        color: isHeader ? Colors.transparent : null,
      ),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? Colors.white : const Color(0xff2D3748),
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
            rowData[rowIndex][colIndex] = value;
          });
        },
      ),
    );
  }

  Widget _scrollCell(String t, double w, {bool bold = false, bool isHeader = false}) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isHeader ? Colors.white.withOpacity(0.3) : const Color(0xffE2E8F0),
          width: 0.5,
        ),
        color: isHeader ? (bold ? const Color(0xff8BB8E8) : Colors.transparent) : null,
      ),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? Colors.white : const Color(0xff2D3748),
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

  Widget _totalFixedCell(int colIndex, double w, List<String> totalData) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE2E8F0), width: 0.5),
        color: const Color(0xffF8F9FA),
      ),
      child: TextField(
        controller: TextEditingController(text: totalData[colIndex]),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xff2D3748),
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: colIndex == 0 ? 'Total' : '',
          hintStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
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

  Widget _totalScrollCell(int colIndex, double w, List<String> totalData) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffE2E8F0), width: 0.5),
        color: const Color(0xffF8F9FA),
      ),
      child: TextField(
        controller: TextEditingController(text: totalData[colIndex]),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
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
    required ScrollController verticalController,
    required List<List<String>> leftRowData,
    required List<List<String>> rightRowData,
    required List<String> leftTotalData,
    required List<String> rightTotalData,
    required VoidCallback initializeData,
  }) {
    initializeData();
    
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
          height: 400, // Fixed height for vertical scrolling
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
                        controller: horizontalController == _table1HorizontalController
                            ? _table1HeaderHorizontalController
                            : _table2HeaderHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: subColumns.map((sub) {
                            return _scrollCell(
                              '$sub',
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
              Expanded(
                child: SingleChildScrollView(
                  controller: verticalController,
                  scrollDirection: Axis.vertical,
                  child: Row(
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
                                  _editableFixedCell(i, 0, 60, leftRowData),
                                  _editableFixedCell(i, 1, 100, leftRowData),
                                  _editableFixedCell(i, 2, 80, leftRowData),
                                  _editableFixedCell(i, 3, 79, leftRowData),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Right Scrollable Data Columns
                      Expanded(
                        child: SingleChildScrollView(
                          controller: horizontalController,
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
                    ],
                  ),
                ),
              ),

              // Total Row
              Container(
                height: rowH,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffE2E8F0), width: 0.5),
                  color: const Color(0xffEEEEEE),
                ),
                child: Row(
                  children: [
                    // Left Fixed Total Cells
                    _totalFixedCell(0, 60, leftTotalData),
                    _totalFixedCell(1, 100, leftTotalData),
                    _totalFixedCell(2, 80, leftTotalData),
                    _totalFixedCell(3, 79, leftTotalData),
                    // Right Scrollable Total Cells
                    Expanded(
                      child: SingleChildScrollView(
                        controller: totalHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            totalSubCols,
                            (colIndex) => _totalScrollCell(colIndex, subColW, rightTotalData),
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
        table1LeftRowData[i][1] = i < 3 ? '11/26/2025' : '';
        table1LeftRowData[i][2] = i < 3 ? '96.0' : '';
        table1LeftRowData[i][3] = i < 3 ? '1' : '';
      }
    }
  }

  void _initializeTable2Data() {
    if (table2LeftRowData[0][0].isEmpty) {
      for (int i = 0; i < 50; i++) {
        table2LeftRowData[i][0] = '${i + 1}';
        table2LeftRowData[i][1] = i < 3 ? '11/27/2025' : '';
        table2LeftRowData[i][2] = i < 3 ? '105.5' : '';
        table2LeftRowData[i][3] = i < 3 ? '2' : '';
      }
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
            title: 'Cumulative Cost - Products',
            subColumns: table1SubColumns,
            totalSubCols: table1TotalSubCols,
            scrollableWidth: table1ScrollableWidth,
            horizontalController: _table1HorizontalController,
            headerHorizontalController: _table1HeaderHorizontalController,
            totalHorizontalController: _table1TotalHorizontalController,
            verticalController: _sharedVerticalController,
            leftRowData: table1LeftRowData,
            rightRowData: table1RightRowData,
            leftTotalData: table1LeftTotalData,
            rightTotalData: table1RightTotalData,
            initializeData: _initializeTable1Data,
          ),

          const SizedBox(height: 32.0),

          // Second Table - Equipment & Services
          _buildTable(
            title: 'Cumulative Cost - Group',
            subColumns: table2SubColumns,
            totalSubCols: table2TotalSubCols,
            scrollableWidth: table2ScrollableWidth,
            horizontalController: _table2HorizontalController,
            headerHorizontalController: _table2HeaderHorizontalController,
            totalHorizontalController: _table2TotalHorizontalController,
            verticalController: _sharedVerticalController,
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
    _sharedVerticalController.dispose();
    _table2HorizontalController.dispose();
    _table2HeaderHorizontalController.dispose();
    _table2TotalHorizontalController.dispose();
    super.dispose();
  }
}