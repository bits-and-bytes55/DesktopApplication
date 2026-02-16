import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReportRecapTable extends StatefulWidget {
  const ReportRecapTable({super.key});

  @override
  State<ReportRecapTable> createState() => _ReportRecapTableState();
}

class _ReportRecapTableState extends State<ReportRecapTable> {
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  
  // Focus nodes for editable cells
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // Left table data - Product and Group
  final List<Map<String, dynamic>> groupData = [
    {'group': 'Common Chemical', 'cost': '7235.16', 'percent': '49.9', 'hasProducts': true},
    {'group': 'Filtration Control', 'cost': '2628.24', 'percent': '18.1', 'hasProducts': false},
    {'group': 'Shale Inhibitor', 'cost': '2198.00', 'percent': '15.2', 'hasProducts': false},
    {'group': 'Viscosifier', 'cost': '1794.00', 'percent': '12.4', 'hasProducts': false},
    {'group': 'Weight Material', 'cost': '180.00', 'percent': '1.2', 'hasProducts': false},
    {'group': 'Corrosion Inhibitor', 'cost': '103.99', 'percent': '0.7', 'hasProducts': false},
    {'group': 'Biocide', 'cost': '90.00', 'percent': '0.6', 'hasProducts': false},
    {'group': 'Defoamer', 'cost': '0', 'percent': '0.0', 'hasProducts': false},
    {'group': 'Lubricant / Surfactant', 'cost': '0', 'percent': '0.0', 'hasProducts': false},
    {'group': 'Others', 'cost': '0', 'percent': '0.0', 'hasProducts': false},
    {'group': 'Surfactant / Solvent', 'cost': '0', 'percent': '0.0', 'hasProducts': false},
  ];

  final List<Map<String, String>> productData = [
    {'name': 'SIZED CALCIUM CARBONAT...', 'cost': '3150.00', 'percent': '21.7'},
    {'name': 'SIZED CALCIUM CARBONAT...', 'cost': '2730.00', 'percent': '18.8'},
    {'name': 'SODIUM CHLORIDE POWDE...', 'cost': '850.00', 'percent': '5.9'},
    {'name': 'POTASSIUM CHLORIDE PO...', 'cost': '175.00', 'percent': '1.2'},
    {'name': 'SIZED CALCIUM CARBONAT...', 'cost': '105.00', 'percent': '0.7'},
    {'name': 'CAUSTIC SODA', 'cost': '76.96', 'percent': '0.5'},
    {'name': 'CITRIC ACID', 'cost': '62.70', 'percent': '0.4'},
    {'name': 'SODA ASH', 'cost': '49.50', 'percent': '0.3'},
    {'name': 'SODIUM BICARBONATE', 'cost': '36.00', 'percent': '0.2'},
    {'name': 'QSTAR MT', 'cost': '2628.24', 'percent': '18.1'},
    {'name': 'GLYMAX', 'cost': '2198.00', 'percent': '15.2'},
    {'name': 'QXAN', 'cost': '1794.00', 'percent': '12.4'},
    {'name': 'BARITE 4.1 - BIG BAG', 'cost': '180.00', 'percent': '1.2'},
    {'name': 'QMAXCOAT', 'cost': '103.99', 'percent': '0.7'},
    {'name': 'QCIDE T', 'cost': '90.00', 'percent': '0.6'},
    {'name': 'QDEFOAM S', 'cost': '0', 'percent': '0.0'},
    {'name': 'DRILLING DETERGENT', 'cost': '0', 'percent': '0.0'},
    {'name': 'MAXRELEASE W', 'cost': '0', 'percent': '0.0'},
    {'name': 'MAXSWEEP', 'cost': '0', 'percent': '0.0'},
    {'name': 'QSCAV H2S', 'cost': '0', 'percent': '0.0'},
    {'name': 'WELLKLEEN', 'cost': '0', 'percent': '0.0'},
  ];

  // Right side tables data with 10+ rows each
  final List<Map<String, String>> packageData = List.generate(10, (index) => {
    'col1': index == 0 ? '▶' : '',
    'col2': index == 0 ? 'Standard Package' : 'Package ${index + 1}',
    'col3': index == 0 ? '0.00' : '0.00',
    'col4': index == 0 ? '0.0' : '0.0',
  });

  final List<Map<String, String>> serviceData = List.generate(10, (index) => {
    'col1': index == 0 ? '▶' : '',
    'col2': index == 0 ? 'Basic Service' : 'Service ${index + 1}',
    'col3': index == 0 ? '0.00' : '0.00',
    'col4': index == 0 ? '0.0' : '0.0',
  });

  final List<Map<String, String>> engineeringData = List.generate(10, (index) => {
    'col1': index == 0 ? '▶' : '',
    'col2': index == 0 ? 'Mud Supervisor - 2' : 'Engineering ${index + 1}',
    'col3': index == 0 ? '2348.36' : '0.00',
    'col4': index == 0 ? '100.0' : '0.0',
  });

  final List<Map<String, String>> allCategoriesData = [
    {'category': 'Product', 'cost': '14499.39', 'percent': '86.1'},
    {'category': 'Engineering', 'cost': '2348.36', 'percent': '13.9'},
    {'category': 'Premixed Mud', 'cost': '0', 'percent': '0.0'},
    {'category': 'Package', 'cost': '0', 'percent': '0.0'},
    {'category': 'Service', 'cost': '0', 'percent': '0.0'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers for all cells
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers for group data
    for (int i = 0; i < groupData.length; i++) {
      _controllers['group-$i'] = TextEditingController(text: groupData[i]['group']);
      _controllers['group-cost-$i'] = TextEditingController(text: groupData[i]['cost']);
      _controllers['group-percent-$i'] = TextEditingController(text: groupData[i]['percent']);
      _focusNodes['group-$i'] = FocusNode();
      _focusNodes['group-cost-$i'] = FocusNode();
      _focusNodes['group-percent-$i'] = FocusNode();
    }

    // Initialize controllers for product data
    for (int i = 0; i < productData.length; i++) {
      _controllers['product-name-$i'] = TextEditingController(text: productData[i]['name']);
      _controllers['product-cost-$i'] = TextEditingController(text: productData[i]['cost']);
      _controllers['product-percent-$i'] = TextEditingController(text: productData[i]['percent']);
      _focusNodes['product-name-$i'] = FocusNode();
      _focusNodes['product-cost-$i'] = FocusNode();
      _focusNodes['product-percent-$i'] = FocusNode();
    }

    // Initialize controllers for right side tables
    _initializeRightTableControllers();
  }

  void _initializeRightTableControllers() {
    // Package table
    for (int i = 0; i < packageData.length; i++) {
      _controllers['package-col2-$i'] = TextEditingController(text: packageData[i]['col2']);
      _controllers['package-col3-$i'] = TextEditingController(text: packageData[i]['col3']);
      _controllers['package-col4-$i'] = TextEditingController(text: packageData[i]['col4']);
    }

    // Service table
    for (int i = 0; i < serviceData.length; i++) {
      _controllers['service-col2-$i'] = TextEditingController(text: serviceData[i]['col2']);
      _controllers['service-col3-$i'] = TextEditingController(text: serviceData[i]['col3']);
      _controllers['service-col4-$i'] = TextEditingController(text: serviceData[i]['col4']);
    }

    // Engineering table
    for (int i = 0; i < engineeringData.length; i++) {
      _controllers['engineering-col2-$i'] = TextEditingController(text: engineeringData[i]['col2']);
      _controllers['engineering-col3-$i'] = TextEditingController(text: engineeringData[i]['col3']);
      _controllers['engineering-col4-$i'] = TextEditingController(text: engineeringData[i]['col4']);
    }

    // All categories table
    for (int i = 0; i < allCategoriesData.length; i++) {
      _controllers['category-$i'] = TextEditingController(text: allCategoriesData[i]['category']);
      _controllers['category-cost-$i'] = TextEditingController(text: allCategoriesData[i]['cost']);
      _controllers['category-percent-$i'] = TextEditingController(text: allCategoriesData[i]['percent']);
    }
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    // Dispose all controllers and focus nodes
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          return isDesktop
              ? _buildDesktopLayout()
              : _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Section - Product and Group Table
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(12),
            child: _buildProductGroupTable(),
          ),
        ),

        // Divider with gradient
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppTheme.primaryColor.withOpacity(0.3),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Right Section - 4 Small Tables
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              controller: _rightScrollController,
              child: Column(
                children: [
                  _buildSmallTableWithTitle(
                    title: 'Cost Distribution - Package',
                    data: packageData,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildSmallTableWithTitle(
                    title: 'Cost Distribution - Service',
                    data: serviceData,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  _buildSmallTableWithTitle(
                    title: 'Cost Distribution - Engineering',
                    data: engineeringData,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildAllCategoriesTable(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildProductGroupTable(),
          const SizedBox(height: 16),
          _buildSmallTableWithTitle(
            title: 'Cost Distribution - Package',
            data: packageData,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSmallTableWithTitle(
            title: 'Cost Distribution - Service',
            data: serviceData,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildSmallTableWithTitle(
            title: 'Cost Distribution - Engineering',
            data: engineeringData,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildAllCategoriesTable(),
        ],
      ),
    );
  }

  Widget _buildProductGroupTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cost Distribution - Product and Group',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${productData.length} items',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table
          Expanded(
            child: SingleChildScrollView(
              controller: _leftScrollController,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Column(
                  children: [
                    // Header
                    _buildTableHeader(),
                    // Data Rows
                    ..._buildProductGroupRows(),
                    // Total Row
                    _buildTotalRow(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(36),
          1: FlexColumnWidth(2.2),
          2: FlexColumnWidth(1),
          3: FixedColumnWidth(65),
          4: FixedColumnWidth(36),
          5: FlexColumnWidth(2.2),
          6: FlexColumnWidth(1),
          7: FixedColumnWidth(65),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        children: [
          TableRow(
            children: [
              _buildTableHeaderCell(''),
              _buildTableHeaderCell('Group'),
              _buildTableHeaderCell('Cost\n(€)'),
              _buildTableHeaderCell('(%)'),
              _buildTableHeaderCell(''),
              _buildTableHeaderCell('Product'),
              _buildTableHeaderCell('Cost\n(€)'),
              _buildTableHeaderCell('(%)'),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductGroupRows() {
    List<Widget> rows = [];
    int productIndex = 0;

    for (int i = 0; i < groupData.length; i++) {
      final group = groupData[i];
      
      if (i == 0) {
        // Common Chemical with 9 products
        for (int j = 0; j < 9; j++) {
          final product = productData[productIndex];
          rows.add(
            Table(
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FlexColumnWidth(2.2),
                2: FlexColumnWidth(1),
                3: FixedColumnWidth(65),
                4: FixedColumnWidth(36),
                5: FlexColumnWidth(2.2),
                6: FlexColumnWidth(1),
                7: FixedColumnWidth(65),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade100, width: 0.5),
                verticalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: j % 2 == 0 ? Colors.white : AppTheme.backgroundColor.withOpacity(0.4),
                  ),
                  children: [
                    _buildTableCell(
                      j == 0 ? '▼' : '',
                      isExpander: true,
                      isBold: j == 0,
                    ),
                    j == 0 
                        ? _buildEditableCell('group-$i', _controllers['group-$i']!)
                        : _buildTableCell(''),
                    j == 0 
                        ? _buildEditableCell('group-cost-$i', _controllers['group-cost-$i']!, isHighlight: true)
                        : _buildTableCell(''),
                    j == 0 
                        ? _buildEditableCell('group-percent-$i', _controllers['group-percent-$i']!)
                        : _buildTableCell(''),
                    _buildTableCell('${j + 1}', textAlign: TextAlign.center),
                    _buildEditableCell('product-name-$productIndex', _controllers['product-name-$productIndex']!),
                    _buildEditableCell('product-cost-$productIndex', _controllers['product-cost-$productIndex']!, isHighlight: true),
                    _buildEditableCell('product-percent-$productIndex', _controllers['product-percent-$productIndex']!),
                  ],
                ),
              ],
            ),
          );
          productIndex++;
        }
      } else {
        // Other groups with single product
        final product = productData[productIndex];
        rows.add(
          Table(
            columnWidths: const {
              0: FixedColumnWidth(36),
              1: FlexColumnWidth(2.2),
              2: FlexColumnWidth(1),
              3: FixedColumnWidth(65),
              4: FixedColumnWidth(36),
              5: FlexColumnWidth(2.2),
              6: FlexColumnWidth(1),
              7: FixedColumnWidth(65),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade100, width: 0.5),
              verticalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: i % 2 == 0 ? Colors.white : AppTheme.backgroundColor.withOpacity(0.4),
                ),
                children: [
                  _buildTableCell('${i + 1}', textAlign: TextAlign.center),
                  _buildEditableCell('group-$i', _controllers['group-$i']!),
                  _buildEditableCell('group-cost-$i', _controllers['group-cost-$i']!, isHighlight: true),
                  _buildEditableCell('group-percent-$i', _controllers['group-percent-$i']!),
                  _buildTableCell('1', textAlign: TextAlign.center),
                  _buildEditableCell('product-name-$productIndex', _controllers['product-name-$productIndex']!),
                  _buildEditableCell('product-cost-$productIndex', _controllers['product-cost-$productIndex']!, isHighlight: true),
                  _buildEditableCell('product-percent-$productIndex', _controllers['product-percent-$productIndex']!),
                ],
              ),
            ],
          ),
        );
        productIndex++;
      }
    }

    return rows;
  }

  Widget _buildTotalRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.2),
        border: Border(
          top: BorderSide(color: AppTheme.secondaryColor, width: 1.5),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(36),
          1: FlexColumnWidth(2.2),
          2: FlexColumnWidth(1),
          3: FixedColumnWidth(65),
          4: FixedColumnWidth(36),
          5: FlexColumnWidth(2.2),
          6: FlexColumnWidth(1),
          7: FixedColumnWidth(65),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        children: [
          TableRow(
            children: [
              _buildTableCell('', isBold: true),
              _buildTableCell('Total', isBold: true),
              _buildTableCell('14229.39', isBold: true),
              _buildTableCell('100', isBold: true),
              _buildTableCell('', isBold: true),
              _buildTableCell('', isBold: true),
              _buildTableCell('14229.39', isBold: true),
              _buildTableCell('100', isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTableWithTitle({
    required String title,
    required List<Map<String, String>> data,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title with colored gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(_getTableIcon(title), color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${data.length} rows',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable table with fixed height
          Container(
            height: 240, // Fixed height for scrollable content
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  _buildSmallTableHeader(),
                  // Data Rows
                  ...data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return _buildSmallTableRow(row, index, data.length);
                  }),
                  // Total Row
                  _buildSmallTableTotalRow(color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(36),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1),
          3: FixedColumnWidth(65),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        children: [
          TableRow(
            children: [
              _buildTableHeaderCell(''),
              _buildTableHeaderCell('Name'),
              _buildTableHeaderCell('Cost\n(€)'),
              _buildTableHeaderCell('(%)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTableRow(Map<String, String> row, int index, int totalRows) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(36),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FixedColumnWidth(65),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade100, width: 0.5),
        verticalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: index % 2 == 0 ? Colors.white : AppTheme.backgroundColor.withOpacity(0.4),
          ),
          children: [
            _buildTableCell(row['col1'] ?? '', isExpander: true),
            _buildEditableCell(
              '${_getTablePrefix(row['col2'] ?? '')}-col2-$index',
              TextEditingController(text: row['col2']),
            ),
            _buildEditableCell(
              '${_getTablePrefix(row['col2'] ?? '')}-col3-$index',
              TextEditingController(text: row['col3']),
              isHighlight: true,
            ),
            _buildEditableCell(
              '${_getTablePrefix(row['col2'] ?? '')}-col4-$index',
              TextEditingController(text: row['col4']),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallTableTotalRow(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: color.withOpacity(0.4), width: 1),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(36),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1),
          3: FixedColumnWidth(65),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        children: [
          TableRow(
            children: [
              _buildTableCell('', isBold: true),
              _buildTableCell('Total', isBold: true),
              _buildTableCell('0.00', isBold: true),
              _buildTableCell('100', isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllCategoriesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.category, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cost Distribution - All Categories',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '5 categories',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Table
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FixedColumnWidth(36),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1),
                4: FixedColumnWidth(65),
              },
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  children: [
                    _buildTableHeaderCell(''),
                    _buildTableHeaderCell(''),
                    _buildTableHeaderCell('Category'),
                    _buildTableHeaderCell('Cost\n(€)'),
                    _buildTableHeaderCell('(%)'),
                  ],
                ),
                // Data rows with colors
                ...allCategoriesData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final colors = [
                    Colors.blue.shade100,
                    Colors.purple.shade100,
                    Colors.orange.shade100,
                    Colors.amber.shade100,
                    Colors.green.shade100,
                  ];
                  
                  return TableRow(
                    decoration: BoxDecoration(color: colors[index]),
                    children: [
                      _buildTableCell('▼', isExpander: true),
                      _buildTableCell('${index + 1}', textAlign: TextAlign.center),
                      _buildEditableCell('category-$index', TextEditingController(text: item['category'])),
                      _buildEditableCell('category-cost-$index', TextEditingController(text: item['cost']), isHighlight: true),
                      _buildEditableCell('category-percent-$index', TextEditingController(text: item['percent'])),
                    ],
                  );
                }),
                // Total
                TableRow(
                  decoration: BoxDecoration(color: AppTheme.secondaryColor.withOpacity(0.2)),
                  children: [
                    _buildTableCell('', isBold: true),
                    _buildTableCell('', isBold: true),
                    _buildTableCell('Total', isBold: true),
                    _buildTableCell('16847.75', isBold: true),
                    _buildTableCell('100', isBold: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {
    bool isBold = false,
    bool isExpander = false,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: isExpander ? AppTheme.primaryColor : AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEditableCell(String key, TextEditingController controller, {bool isHighlight = false}) {
    final focusNode = _focusNodes[key] ?? FocusNode();
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = focusNode;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      color: isHighlight ? AppTheme.primaryColor.withOpacity(0.05) : null,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: InputBorder.none,
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
      ),
    );
  }

  IconData _getTableIcon(String title) {
    if (title.contains('Package')) return Icons.inventory;
    if (title.contains('Service')) return Icons.build;
    if (title.contains('Engineering')) return Icons.engineering;
    if (title.contains('All Categories')) return Icons.category;
    return Icons.table_chart;
  }

  String _getTablePrefix(String text) {
    if (text.contains('Package')) return 'package';
    if (text.contains('Service')) return 'service';
    if (text.contains('Engineering')) return 'engineering';
    return 'item';
  }
}