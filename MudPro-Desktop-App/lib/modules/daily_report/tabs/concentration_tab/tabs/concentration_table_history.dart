import 'package:flutter/material.dart';

class ConcentrationTableHistory extends StatefulWidget {
  const ConcentrationTableHistory({super.key});

  @override
  State<ConcentrationTableHistory> createState() => _ConcentrationTableHistoryState();
}

class _ConcentrationTableHistoryState extends State<ConcentrationTableHistory> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const double rowH = 32.0;
  static const double subColW = 120.0;

  // Data for editable rows
  List<List<String>> leftRowData = List.generate(50, (index) => List.generate(4, (_) => ''));
  List<List<String>> rightRowData = List.generate(50, (index) => List.generate(100, (_) => ''));

  // Group definitions with their sub-columns
  final List<Map<String, dynamic>> groups = [
    {
      'title': 'Weight Material',
      'subs': ['BARITE 4.1 - BIG B', 'CALCIUM CHLORIDE PE']
    },
    {
      'title': 'Viscosifier',
      'subs': ['BENTONITE - TON', 'QXAN', 'QXAN PREMIUM', 'HEC']
    },
    {
      'title': 'Common Chemical',
      'subs': [
        'CAUSTIC SODA', 'SODA ASH', 'ZINC CARBONATE', 'SIZED CALCIUM C.',
        'SODIUM BICARBONATE', 'SIZED CALCIUM C.', 'SODIUM CHLORIDE',
        'POTASSIUM CHLORIDE', 'CALCIUM CHLORIDE'
      ]
    },
    {
      'title': 'LCM',
      'subs': [
        'MICA COARSE', 'MICA FINE', 'MICA MEDIUM', 'NUTSHELLS COARSE',
        'NUTSHELLS FINE', 'LCM MIX COARSE', 'LCM MIX FINE', 'LCM MIX MEDIUM',
        'COTTON SEEDS HULL', 'NUTSHELLS MEDIUM', 'FLC 2000'
      ]
    },
    {
      'title': 'Defoamer',
      'subs': ['QDEFOAM S']
    },
    {
      'title': 'Filtration Control',
      'subs': ['QPAC LV', 'QSTAR MT', 'MAXLIG', 'QSTAR HT', 'QMAXTROL', 'QPAC HV']
    },
    {
      'title': 'Others',
      'subs': [
        'QSCAV H2S', 'MAXRELEASE W', 'STRATALLEE', 'QMAXBREAK', 'MAXBEADS',
        'GILSONITE AQUAS', 'QSCAV O2', 'MAXCAP L', 'MAXPHALT L',
        'CBM 11.5 PPG OW', 'CBM PPG OWR', 'CITRIC ACID', 'OBM 8.0 PPG OWR',
        'MAXSWEEP'
      ]
    },
    {
      'title': 'Alkalinity',
      'subs': ['LIME']
    },
    {
      'title': 'Wellbore Strengthening',
      'subs': ['GS SEAL', 'SWELLBLOCK']
    },
    {
      'title': 'OBM Viscosifier',
      'subs': ['MAXCLAY']
    },
    {
      'title': 'Emulsifier',
      'subs': ['QMJL 1 EH', 'QMJL 11 EH']
    },
    {
      'title': 'Wetting Agent',
      'subs': ['MAXEWET XL']
    },
    {
      'title': 'WBM Thinner',
      'subs': ['CHROME FREE LIGNO']
    },
    {
      'title': 'Lubricant / Surfactant',
      'subs': ['DRILLING DETERGENT']
    },
    {
      'title': 'Corrosion Inhibitor',
      'subs': ['QMAXCOAT']
    },
    {
      'title': 'Surfactant / Solvent',
      'subs': ['WELLKLEEN']
    },
    {
      'title': 'OBM Thinner',
      'subs': ['QMAXTHIN']
    },
    {
      'title': 'Biocide',
      'subs': ['QCIDE T']
    },
  ];

  int get _totalSubCols {
    return groups.fold(0, (sum, group) => sum + (group['subs'] as List).length);
  }

  double get _totalScrollableWidth => _totalSubCols * subColW;

  Widget _fixedCell(String t, double w, {bool bold = false, bool isHeader = false}) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isHeader ? Colors.white.withOpacity(0.3) : Color(0xffE2E8F0),
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
          color: isHeader ? Colors.white : Color(0xff2D3748),
        ),
      ),
    );
  }

  Widget _editableFixedCell(int rowIndex, int colIndex, double w) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xffE2E8F0), width: 0.5),
      ),
      child: TextField(
        controller: TextEditingController(text: leftRowData[rowIndex][colIndex]),
        style: TextStyle(
          fontSize: 11,
          color: Color(0xff2D3748),
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

  Widget _scrollCell(String t, double w, {bool bold = false, bool isHeader = false}) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isHeader ? Colors.white.withOpacity(0.3) : Color(0xffE2E8F0),
          width: 0.5,
        ),
        color: isHeader ? (bold ? Color(0xff8BB8E8) : Colors.transparent) : null,
      ),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? Colors.white : Color(0xff2D3748),
        ),
      ),
    );
  }

  Widget _editableScrollCell(int rowIndex, int colIndex, double w) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xffE2E8F0), width: 0.5),
      ),
      child: TextField(
        controller: TextEditingController(text: rightRowData[rowIndex][colIndex]),
        style: TextStyle(
          fontSize: 10,
          color: Color(0xff2D3748),
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: '',
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

  @override
  Widget build(BuildContext context) {
    // Initialize data with sample values for first few rows
    if (leftRowData[0][0].isEmpty) {
      for (int i = 0; i < 50; i++) {
        leftRowData[i][0] = '${i + 1}';
        leftRowData[i][1] = i < 3 ? '11/26/2025' : '';
        leftRowData[i][2] = i < 3 ? '96.0' : '';
        leftRowData[i][3] = i < 3 ? '1' : '';
      }
    }

    return Container(
      color: Color(0xffF8F9FA),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= LEFT FIXED COLUMNS =================
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xffE2E8F0), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Fixed Header with increased height (same as right side)
                Container(
                  height: rowH * 2, // Double height to match right headers
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
                      _fixedCell('No', 60, bold: true, isHeader: true),
                      _fixedCell('Date', 100, bold: true, isHeader: true),
                      _fixedCell('MD (ft)', 80, bold: true, isHeader: true),
                      _fixedCell('Rpt #', 79, bold: true, isHeader: true),
                    ],
                  ),
                ),
                
                // Fixed Data Rows - Now Editable
                Expanded(
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _verticalController,
                      itemCount: 50,
                      itemBuilder: (_, i) => Container(
                        height: rowH,
                        decoration: BoxDecoration(
                          color: i.isOdd ? Colors.white : Color(0xffF8F9FA),
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
              ],
            ),
          ),

          // ================= RIGHT SCROLLABLE =================
          Expanded(
            child: Container(
              color: Colors.white,
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    height: (50 * rowH) + (rowH * 2), // Data rows + Headers
                    child: Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: _totalScrollableWidth,
                          child: Column(
                            children: [
                              // HEADERS SECTION (2 rows height)
                              Container(
                                color: Colors.white,
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
                                        children: groups.map((group) {
                                          final subs = group['subs'] as List<String>;
                                          return Container(
                                            width: subs.length * subColW,
                                            height: rowH,
                                            alignment: Alignment.center,
                                            child: Text(
                                              group['title'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    
                                    // Sub Headers Row
                                    Container(
                                      height: rowH,
                                      child: Row(
                                        children: groups.expand((group) {
                                          final subs = group['subs'] as List<String>;
                                          return subs.map((sub) {
                                            return _scrollCell(
                                              '$sub\n(lb/bbl)',
                                              subColW,
                                              bold: true,
                                              isHeader: true,
                                            );
                                          });
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // DATA ROWS SECTION - Now Editable
                              Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: 50,
                                  itemBuilder: (_, rowIndex) => Container(
                                    height: rowH,
                                    decoration: BoxDecoration(
                                      color: rowIndex.isOdd ? Colors.white : Color(0xffF8F9FA),
                                    ),
                                    child: Row(
                                      children: List.generate(
                                        _totalSubCols,
                                        (colIndex) => _editableScrollCell(rowIndex, colIndex, subColW),
                                      ),
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
    _verticalController.dispose();
    super.dispose();
  }
}