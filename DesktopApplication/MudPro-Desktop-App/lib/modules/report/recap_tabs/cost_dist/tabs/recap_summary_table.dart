import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class CostSummaryRecapPage extends StatefulWidget {
  const CostSummaryRecapPage({super.key});

  @override
  State<CostSummaryRecapPage> createState() => _CostSummaryRecapPageState();
}

class _CostSummaryRecapPageState extends State<CostSummaryRecapPage> {
  // Summary data
  final Map<String, String> summaryData = {
    'Total Depth': '940.0 (ft)',
    'Total Cost': '16847.75 (€)',
    'Days': '13',
    'Avg. Cost per Unit Length': '18.80 (€/ft)',
    'Avg. Daily Cost': '1295.98 (€/day)',
    'Daily Footage': '68.9 (ft/day)',
    'Cost - Product': '14499.39 (€)',
    'Cost - Premixed Mud': '0.00 (€)',
    'Cost - Package': '0.00 (€)',
    'Cost - Service': '0.00 (€)',
    'Cost - Engineering': '2348.36 (€)',
  };

  // Breakdown table data
  final List<Map<String, dynamic>> breakdownData = [
    {
      'td': '0 - 510.0',
      'interval': '12.25" Inte...',
      'days': '2',
      'mudType': 'Water-based',
      'product': '3348.84',
      'premixedMud': '0',
      'package': '0',
      'service': '0',
      'engineering': '503.22',
      'subtotal': '3852.06',
      'tax': '0',
      'cost': '3852.06',
      'perFt': '7.55',
      'perDay': '1926.03',
      'ftPerDay': '255.0',
    },
    {
      'td': '510.0 - 940.0',
      'interval': '8.5" Interval',
      'days': '6',
      'mudType': 'Water-based',
      'product': '6987.68',
      'premixedMud': '0',
      'package': '0',
      'service': '0',
      'engineering': '1006.44',
      'subtotal': '7994.12',
      'tax': '0',
      'cost': '7994.12',
      'perFt': '18.59',
      'perDay': '1332.35',
      'ftPerDay': '71.7',
    },
    {
      'td': '940.0 - 896.0',
      'interval': '8.5"Sidetra...',
      'days': '4',
      'mudType': 'Water-based',
      'product': '3883.88',
      'premixedMud': '0',
      'package': '0',
      'service': '0',
      'engineering': '670.96',
      'subtotal': '4554.84',
      'tax': '0',
      'cost': '4554.84',
      'perFt': '-103.52',
      'perDay': '1138.71',
      'ftPerDay': '-11.0',
    },
    {
      'td': '896.0 - 896.0',
      'interval': 'Completion ...',
      'days': '1',
      'mudType': 'Water-based',
      'product': '278.99',
      'premixedMud': '0',
      'package': '0',
      'service': '0',
      'engineering': '167.74',
      'subtotal': '446.73',
      'tax': '0',
      'cost': '446.73',
      'perFt': '',
      'perDay': '446.73',
      'ftPerDay': '0.0',
    },
    // Add empty rows for editing
    ...List.generate(8, (index) => {
      'td': '',
      'interval': '',
      'days': '',
      'mudType': '',
      'product': '',
      'premixedMud': '',
      'package': '',
      'service': '',
      'engineering': '',
      'subtotal': '',
      'tax': '',
      'cost': '',
      'perFt': '',
      'perDay': '',
      'ftPerDay': '',
    }),
  ];

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  // Focus nodes for text fields
  late final List<FocusNode> _focusNodes;

  // Controllers for summary table editable cells
  late final List<TextEditingController> _summaryControllers;

  // Controllers for total row editable cells
  late final List<TextEditingController> _totalControllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(breakdownData.length * 15, (index) => FocusNode());
    // Add listeners to focus nodes to hide borders when not focused
    for (var focusNode in _focusNodes) {
      focusNode.addListener(() {
        setState(() {});
      });
    }

    // Initialize summary controllers
    _summaryControllers = List.generate(summaryData.length * 2, (index) => TextEditingController());
    int controllerIndex = 0;
    for (var value in summaryData.values) {
      final parts = value.split(' ');
      final val = parts.isNotEmpty ? parts[0] : '';
      final unit = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _summaryControllers[controllerIndex++] = TextEditingController(text: val);
      _summaryControllers[controllerIndex++] = TextEditingController(text: unit);
    }

    // Initialize total controllers
    _totalControllers = List.generate(15, (index) => TextEditingController());
    // Populate with initial values from total row
    _totalControllers[0] = TextEditingController(text: 'Total/Average');
    _totalControllers[1] = TextEditingController(text: '');
    _totalControllers[2] = TextEditingController(text: '13');
    _totalControllers[3] = TextEditingController(text: '');
    _totalControllers[4] = TextEditingController(text: '14499.39');
    _totalControllers[5] = TextEditingController(text: '');
    _totalControllers[6] = TextEditingController(text: '');
    _totalControllers[7] = TextEditingController(text: '');
    _totalControllers[8] = TextEditingController(text: '2348.36');
    _totalControllers[9] = TextEditingController(text: '16847.75');
    _totalControllers[10] = TextEditingController(text: '');
    _totalControllers[11] = TextEditingController(text: '16847.75');
    _totalControllers[12] = TextEditingController(text: '18.80');
    _totalControllers[13] = TextEditingController(text: '1295.98');
    _totalControllers[14] = TextEditingController(text: '68.9');
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (var controller in _summaryControllers) {
      controller.dispose();
    }
    for (var controller in _totalControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundColor,
            AppTheme.backgroundColor.withOpacity(0.95),
          ],
        ),
      ),
      child: SingleChildScrollView(
        controller: _verticalController,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title with gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.assessment, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Cost Distribution - Summary (After Tax)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Current Report',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Table
            _buildSummaryTable(),
            const SizedBox(height: 20),

            // Breakdown Table Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.table_chart, size: 18, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Cost Distribution - Breakdown',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Edit values directly in cells',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Breakdown Table
            _buildBreakdownTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTable() {
    final entries = summaryData.entries.toList();
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2,
      child: Container(
        decoration: AppTheme.elevatedCardDecoration,
        padding: const EdgeInsets.all(1),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.2),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1),
          },
          border: TableBorder(
            horizontalInside: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
            top: BorderSide(
              color: AppTheme.primaryColor,
              width: 1,
            ),
            bottom: BorderSide(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          children: [
            // Table Header
            TableRow(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
              ),
              children: [
                _buildTableCell('Metric', isHeader: true),
                _buildTableCell('Value', isHeader: true, textAlign: TextAlign.center),
                _buildTableCell('Unit', isHeader: true),
              ],
            ),
            // Data Rows
            ...entries.map((entry) {
              final index = entries.indexOf(entry);
              final parts = entry.value.split(' ');
              final value = parts.isNotEmpty ? parts[0] : '';
              final unit = parts.length > 1 ? parts.sublist(1).join(' ') : '';

              return TableRow(
                decoration: BoxDecoration(
                  color: index % 2 == 0
                      ? Colors.white
                      : AppTheme.backgroundColor.withOpacity(0.5),
                ),
                children: [
                  _buildTableCell(entry.key, textAlign: TextAlign.left),
                  _buildEditableValueCell(value, _summaryControllers[index * 2]),
                  _buildTableCell(unit, textAlign: TextAlign.left),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            _buildBreakdownHeader(),
            
            // Data Rows
            SizedBox(
              height: 380, // Reduced height
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...breakdownData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      return _buildBreakdownRow(row, index);
                    }).toList(),
                    // Total Row
                    _buildTotalRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryColor.withOpacity(0.8), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('TD\n(ft)', width: 85),
          _buildHeaderCell('Interval', width: 100),
          _buildHeaderCell('Days', width: 55),
          _buildHeaderCell('Mud Type', width: 90),
          // Subtotal group
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
                right: BorderSide(color: Colors.white.withOpacity(0.4), width: 1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 500,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                  child: Text(
                    'Subtotal (€)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildHeaderCell('Product', width: 85),
                    _buildHeaderCell('Premixed\nMud', width: 85),
                    _buildHeaderCell('Package', width: 85),
                    _buildHeaderCell('Service', width: 85),
                    _buildHeaderCell('Engineering', width: 85),
                    _buildHeaderCell('Subtotal', width: 85),
                  ],
                ),
              ],
            ),
          ),
          _buildHeaderCell('Tax\n(€)', width: 65),
          _buildHeaderCell('Cost\n(€)', width: 85),
          _buildHeaderCell('(€/ft)', width: 65),
          _buildHeaderCell('(€/day)', width: 85),
          _buildHeaderCell('(ft/day)', width: 65),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(Map<String, dynamic> row, int index) {
    final isEvenRow = index % 2 == 0;
    return Container(
      height: 36, // Fixed row height
      decoration: BoxDecoration(
        color: isEvenRow ? Colors.white : AppTheme.backgroundColor.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _buildEditableDataCell(row['td'], width: 85, index: index, fieldIndex: 0),
          _buildEditableDataCell(row['interval'], width: 100, index: index, fieldIndex: 1),
          _buildEditableDataCell(row['days'], width: 55, index: index, fieldIndex: 2),
          _buildEditableDataCell(row['mudType'], width: 90, index: index, fieldIndex: 3),
          _buildEditableDataCell(row['product'], width: 85, index: index, fieldIndex: 4),
          _buildEditableDataCell(row['premixedMud'], width: 85, index: index, fieldIndex: 5),
          _buildEditableDataCell(row['package'], width: 85, index: index, fieldIndex: 6),
          _buildEditableDataCell(row['service'], width: 85, index: index, fieldIndex: 7),
          _buildEditableDataCell(row['engineering'], width: 85, index: index, fieldIndex: 8),
          _buildEditableDataCell(row['subtotal'], width: 85, index: index, fieldIndex: 9, isHighlight: true),
          _buildEditableDataCell(row['tax'], width: 65, index: index, fieldIndex: 10),
          _buildEditableDataCell(row['cost'], width: 85, index: index, fieldIndex: 11, isHighlight: true),
          _buildEditableDataCell(row['perFt'], width: 65, index: index, fieldIndex: 12),
          _buildEditableDataCell(row['perDay'], width: 85, index: index, fieldIndex: 13),
          _buildEditableDataCell(row['ftPerDay'], width: 65, index: index, fieldIndex: 14),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    return Container(
      height: 38, // Slightly taller for total row
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.secondaryColor.withOpacity(0.9), AppTheme.secondaryColor.withOpacity(0.7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.8), width: 1),
      ),
      child: Row(
        children: [
          _buildDataCell('Total/Average', width: 85, isBold: true, color: AppTheme.textPrimary),
          _buildDataCell('', width: 100),
          _buildDataCell('13', width: 55, isBold: true, color: AppTheme.textPrimary),
          _buildDataCell('', width: 90),
          _buildDataCell('14499.39', width: 85, isBold: true, color: AppTheme.textPrimary),
          _buildDataCell('', width: 85),
          _buildDataCell('', width: 85),
          _buildDataCell('', width: 85),
          _buildDataCell('2348.36', width: 85, isBold: true, color: AppTheme.textPrimary),
          _buildDataCell('16847.75', width: 85, isBold: true, color: AppTheme.textPrimary),
          _buildDataCell('', width: 65),
          _buildDataCell('16847.75', width: 85, isBold: true, color: AppTheme.textPrimary),
          _buildDataCell('18.80', width: 65, isBold: true, color: AppTheme.textPrimary),
          _buildDataCell('1295.98', width: 85, isBold: true, color: AppTheme.textPrimary),
          _buildDataCell('68.9', width: 65, isBold: true, color: AppTheme.textPrimary),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double width = 85}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {
    bool isHeader = false,
    TextAlign textAlign = TextAlign.center,
    bool isValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : (isValue ? FontWeight.w500 : FontWeight.w400),
          color: isHeader ? AppTheme.primaryColor : AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEditableValueCell(String text, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-\s]')),
        ],
        onChanged: (value) {
          // Handle data change if needed
        },
      ),
    );
  }

  Widget _buildEditableDataCell(dynamic text, {
    double width = 85, 
    bool isHighlight = false,
    required int index,
    required int fieldIndex,
  }) {
    final focusNodeIndex = index * 15 + fieldIndex;
    final focusNode = _focusNodes[focusNodeIndex];
    final controller = TextEditingController(text: text?.toString() ?? '');
    
    return Container(
      width: width,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isHighlight ? AppTheme.primaryColor.withOpacity(0.05) : null,
        border: Border(
          right: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none, // No border
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-\s]')),
        ],
        onChanged: (value) {
          // Handle data change if needed
        },
      ),
    );
  }

  Widget _buildDataCell(String text, {
    double width = 85, 
    bool isBold = false,
    Color color = Colors.white,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}