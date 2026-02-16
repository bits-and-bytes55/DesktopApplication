import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/controller/report_manager_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReportManagerPage extends StatefulWidget {
  const ReportManagerPage({super.key});

  @override
  State<ReportManagerPage> createState() => _ReportManagerPageState();
}

class _ReportManagerPageState extends State<ReportManagerPage> {
  final ReportManagerController rmC = Get.put(ReportManagerController());

  // ---------------- CURRENT WELL ----------------
  String selectedWell = 'UG-0293 ST';
  final wells = ['UG-0293 ST', 'UG-0451 ST', 'UG-0678 ST'];

  // ---------------- SEARCH CRITERIA ----------------
  final criteria = [
    'Date',
    'Report No.',
    'Depth (m)',
    'MW (ppg)',
    'Recommended Tour Treatm.',
    'Remarks',
    'Recap Remarks',
    'Internal Notes',
  ];

  final Map<String, bool> checked = {};
  final Map<String, TextEditingController> minCtrl = {};
  final Map<String, TextEditingController> maxCtrl = {};

  // ---------------- RESULT TABLE ----------------
  int? selectedRowIndex;
  bool hasSearched = false; // Track if search has been performed

  // Dummy data matching the image
  final List<Map<String, dynamic>> allReports = [
    {
      'date': '11/26/2025',
      'report': 1,
      'md': 2386.59,
      'activity': 'Tipping',
      'interval': 'Suspension',
      'mud': 'Water-based',
      'mw': 8.40,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '11/27/2025',
      'report': 2,
      'md': 2386.59,
      'activity': 'Tipping',
      'interval': 'Suspension',
      'mud': 'Water-based',
      'mw': 8.40,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '11/28/2025',
      'report': 3,
      'md': 2386.59,
      'activity': 'Others',
      'interval': 'Suspension',
      'mud': 'Water-based',
      'mw': 8.40,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '11/29/2025',
      'report': 4,
      'md': 2390.55,
      'activity': 'Others',
      'interval': '8.5*hole',
      'mud': 'Oil-based',
      'mw': 10.70,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '11/30/2025',
      'report': 5,
      'md': 2393.60,
      'activity': 'Tipping',
      'interval': '8.5*hole',
      'mud': 'Oil-based',
      'mw': 10.70,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '12/1/2025',
      'report': 6,
      'md': 2407.92,
      'activity': 'Drilling For...',
      'interval': '8.5*hole',
      'mud': 'Oil-based',
      'mw': 10.80,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '12/2/2025',
      'report': 7,
      'md': 2417.07,
      'activity': 'Tipping',
      'interval': '8.5*hole',
      'mud': 'Oil-based',
      'mw': 10.80,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '12/3/2025',
      'report': 8,
      'md': 2691.39,
      'activity': 'Drilling For...',
      'interval': '8.5*hole',
      'mud': 'Oil-based',
      'mw': 10.90,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '12/4/2025',
      'report': 9,
      'md': 2759.97,
      'activity': 'Tipping',
      'interval': '8.5*hole',
      'mud': 'Oil-based',
      'mw': 11.00,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '12/5/2025',
      'report': 10,
      'md': 2759.97,
      'activity': 'Circulation',
      'interval': '8.5*hole',
      'mud': 'Oil-based',
      'mw': 11.00,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '12/6/2025',
      'report': 11,
      'md': 2759.97,
      'activity': 'Others',
      'interval': '8.5*hole',
      'mud': 'Oil-based',
      'mw': 11.00,
      'daily': 0.00,
      'cum': 0.00,
    },
    {
      'date': '12/7/2025',
      'report': 12,
      'md': 2759.97,
      'activity': 'Drilling Ce...',
      'interval': '8.5*hole',
      'mud': 'Oil-based',
      'mw': 11.00,
      'daily': 0.00,
      'cum': 0.00,
    },
  ];

  List<Map<String, dynamic>> filteredReports = [];

  @override
  void initState() {
    super.initState();
    for (var c in criteria) {
      checked[c] = false;
      minCtrl[c] = TextEditingController();
      maxCtrl[c] = TextEditingController();
    }
    // Initialize with dummy data
    filteredReports = allReports.map((e) => Map<String, dynamic>.from(e)).toList();
    hasSearched = true;
  }

  @override
  void dispose() {
    // Dispose text controllers
    for (var controller in minCtrl.values) {
      controller.dispose();
    }
    for (var controller in maxCtrl.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isSmallScreen = constraints.maxWidth < 1200;
        
        return Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER SECTION =================
              _buildHeader(),
              const SizedBox(height: 16),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= LEFT PANEL - SEARCH CRITERIA =================
                    Container(
                      width: isSmallScreen ? constraints.maxWidth * 0.4 : 420,
                      constraints: BoxConstraints(minWidth: 380),
                      decoration: AppTheme.cardDecoration.copyWith(
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: _buildSearchCriteria(),
                    ),
                    const SizedBox(width: 16),

                    // ================= RIGHT PANEL - RESULTS TABLE =================
                    Expanded(
                      child: Container(
                        decoration: AppTheme.cardDecoration.copyWith(
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: _buildResultTable(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ================= ACTION BUTTONS =================
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.elevatedCardDecoration.copyWith(
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.folder_open, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            'Report Manager - $selectedWell',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            'Current Well:',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),

          // Well Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: selectedWell,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
              items: wells
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: AppTheme.bodySmall),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => selectedWell = v!),
            ),
          ),

          const Spacer(),
        ],
      )
    );
  }

  // ================= LEFT PANEL - SEARCH CRITERIA =================
  Widget _buildSearchCriteria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with table head color
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.tableHeadColor, // Using table head color
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Search Criteria',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Criteria Table
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Table Header with table head color
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.tableHeadColor, // Using table head color
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            'Select',
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Variable',
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Min Value',
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Max Value',
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Criteria Rows - Always editable
                  ...criteria.map((name) => _criteriaRow(name)),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _clearAll,
                          style: AppTheme.secondaryButtonStyle.copyWith(
                            backgroundColor: MaterialStateProperty.all(Colors.white),
                          ),
                          child: Text(
                            'Clear All',
                            style: AppTheme.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _search,
                          style: AppTheme.primaryButtonStyle,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Search Reports',
                                style: AppTheme.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _criteriaRow(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: checked[name],
              onChanged: (v) => setState(() => checked[name] = v!),
              fillColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return AppTheme.primaryColor;
                  }
                  return Colors.white;
                },
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: minCtrl[name],
                style: AppTheme.caption,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Min',
                  hintStyle: AppTheme.caption.copyWith(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: maxCtrl[name],
                style: AppTheme.caption,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Max',
                  hintStyle: AppTheme.caption.copyWith(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= RIGHT PANEL - RESULTS TABLE =================
  Widget _buildResultTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with table head color
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.tableHeadColor, // Using table head color
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.table_chart, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Search Results',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${filteredReports.length} reports found',
                  style: AppTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (selectedRowIndex != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Row ${selectedRowIndex! + 1} selected',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowHeight: 36,
                  dividerThickness: 0.5,
                  headingRowColor: MaterialStateProperty.all(AppTheme.tableHeadColor), // Table header color
                  dataRowColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppTheme.primaryColor.withOpacity(0.1);
                      }
                      return Colors.transparent;
                    },
                  ),
                  columns: [
                    _dataColumn('#'),
                    _dataColumn('Date'),
                    _dataColumn('Report No'),
                    _dataColumn('MD (m)'),
                    _dataColumn('Activity'),
                    _dataColumn('Interval'),
                    _dataColumn('Mud Type'),
                    _dataColumn('MW (ppg)'),
                    _dataColumn('Daily Cost'),
                    _dataColumn('Cum. Cost'),
                  ],
                  rows: List.generate(filteredReports.length, (i) {
                    final r = filteredReports[i];
                    return DataRow(
                      selected: selectedRowIndex == i,
                      onSelectChanged: (selected) {
                        if (selected != null) {
                          setState(() {
                            if (selected) {
                              selectedRowIndex = i;
                            } else if (selectedRowIndex == i) {
                              selectedRowIndex = null;
                            }
                          });
                        }
                      },
                      cells: [
                        // Row number
                        DataCell(
                          Container(
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        _editableDataCell(
                          r['date'].toString(),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                filteredReports[i]['date'] = value;
                              });
                            }
                          },
                        ),
                        _editableDataCell(
                          r['report'].toString(),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                filteredReports[i]['report'] = int.tryParse(value) ?? r['report'];
                              });
                            }
                          },
                          isNumeric: true,
                        ),
                        _editableDataCell(
                          r['md'].toStringAsFixed(2),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                filteredReports[i]['md'] = double.tryParse(value) ?? r['md'];
                              });
                            }
                          },
                          isNumeric: true,
                        ),
                        _editableDataCell(
                          r['activity'].toString(),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                filteredReports[i]['activity'] = value;
                              });
                            }
                          },
                        ),
                        _editableDataCell(
                          r['interval'].toString(),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                filteredReports[i]['interval'] = value;
                              });
                            }
                          },
                        ),
                        _editableDataCell(
                          r['mud'].toString(),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                filteredReports[i]['mud'] = value;
                              });
                            }
                          },
                        ),
                        _editableDataCell(
                          r['mw'].toStringAsFixed(2),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                filteredReports[i]['mw'] = double.tryParse(value) ?? r['mw'];
                              });
                            }
                          },
                          isNumeric: true,
                        ),
                        _editableDataCell(
                          '\$${r['daily'].toStringAsFixed(2)}',
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final cleanValue = value.replaceAll('\$', '');
                              setState(() {
                                filteredReports[i]['daily'] = double.tryParse(cleanValue) ?? r['daily'];
                              });
                            }
                          },
                          isNumeric: true,
                        ),
                        _editableDataCell(
                          '\$${r['cum'].toStringAsFixed(2)}',
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final cleanValue = value.replaceAll('\$', '');
                              setState(() {
                                filteredReports[i]['cum'] = double.tryParse(cleanValue) ?? r['cum'];
                              });
                            }
                          },
                          isNumeric: true,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataColumn _dataColumn(String label) {
    return DataColumn(
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white, // White text on table head color
          ),
        ),
      ),
    );
  }

  DataCell _editableDataCell(
    String text, {
    required ValueChanged<String> onChanged,
    bool isNumeric = false,
  }) {
    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: TextEditingController(text: text),
          style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(4),
          ),
          onChanged: onChanged,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          textAlign: isNumeric ? TextAlign.right : TextAlign.left,
        ),
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: selectedRowIndex != null ? _deleteRow : null,
            icon: Icon(Icons.delete_outline, size: 16),
            label: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: selectedRowIndex != null ? _selectRow : null,
            icon: Icon(Icons.check_circle, size: 16),
            label: Text('Select'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  // ================= ACTIONS =================
  void _clearAll() {
    setState(() {
      for (var k in checked.keys) {
        checked[k] = false;
        minCtrl[k]!.clear();
        maxCtrl[k]!.clear();
      }
      // Keep showing dummy data even after clear
      hasSearched = true;
    });
  }

  void _search() {
    setState(() {
      // Always show dummy data when search is clicked
      hasSearched = true;
      selectedRowIndex = null;
    });
  }

  void _deleteRow() {
    if (selectedRowIndex != null) {
      setState(() {
        filteredReports.removeAt(selectedRowIndex!);
        selectedRowIndex = null;
      });
    }
  }

  void _selectRow() {
    if (selectedRowIndex != null) {
      debugPrint('Selected row: $selectedRowIndex');
      // Show success message using alert dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Report Selected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Row ${selectedRowIndex! + 1} has been selected',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}