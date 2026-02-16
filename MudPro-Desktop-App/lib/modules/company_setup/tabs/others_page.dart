import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OthersPage extends StatefulWidget {
  const OthersPage({super.key});

  @override
  State<OthersPage> createState() => _OthersPageState();
}

class _OthersPageState extends State<OthersPage> {
  static const int rowCount = 20;

  List<TextEditingController> _genSingleCol() =>
      List.generate(rowCount, (_) => TextEditingController());

  late final activity = _genSingleCol();
  late final addition = _genSingleCol();
  late final loss = _genSingleCol();
  late final water = _genSingleCol();
  late final oil = _genSingleCol();
  late final synthetic = _genSingleCol();

  @override
  void dispose() {
    for (var controller in [...activity, ...addition, ...loss, ...water, ...oil, ...synthetic]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            
            if (availableWidth < 1000) {
              return _mobileLayout();
            } else if (availableWidth < 1400) {
              return _mediumLayout();
            } else {
              return _desktopLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _mobileLayout() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _twoColTable(
                  title: 'Activity',
                  controllers: activity,
                  width: double.infinity,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _singleColTable(title: 'Addition', controllers: addition),
                      const SizedBox(width: 12),
                      _singleColTable(title: 'Loss', controllers: loss),
                      const SizedBox(width: 12),
                      _singleColTable(title: 'Water-based', controllers: water),
                      const SizedBox(width: 12),
                      _singleColTable(title: 'Oil-based', controllers: oil),
                      const SizedBox(width: 12),
                      _singleColTable(title: 'Synthetic', controllers: synthetic),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _footerButtons(),
      ],
    );
  }

  Widget _mediumLayout() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _twoColTable(
                title: 'Activity',
                controllers: activity,
                width: 250,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _singleColTable(title: 'Addition', controllers: addition),
                      const SizedBox(width: 12),
                      _singleColTable(title: 'Loss', controllers: loss),
                      const SizedBox(width: 12),
                      _singleColTable(title: 'Water-based', controllers: water),
                      const SizedBox(width: 12),
                      _singleColTable(title: 'Oil-based', controllers: oil),
                      const SizedBox(width: 12),
                      _singleColTable(title: 'Synthetic', controllers: synthetic),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _footerButtons(),
      ],
    );
  }

  Widget _desktopLayout() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _twoColTable(
                title: 'Activity',
                controllers: activity,
                width: 300,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalTablesWidth = 5 * 210 + 4 * 12; // 5 tables * 210 width + 4 gaps * 12
                    if (constraints.maxWidth >= totalTablesWidth) {
                      // If there's enough space, show all tables without scrolling
                      return Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: Column(
                              children: [
                                Flexible(
                                  child: _singleColTable(title: 'Addition', controllers: addition),
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: _singleColTable(title: 'Loss', controllers: loss),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            flex: 2,
                            child: Column(
                              children: [
                                Flexible(
                                  child: _singleColTable(title: 'Water-based', controllers: water),
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: _singleColTable(title: 'Oil-based', controllers: oil),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            flex: 1,
                            child: _singleColTable(title: 'Synthetic', controllers: synthetic),
                          ),
                        ],
                      );
                    } else {
                      // If not enough space, use horizontal scrolling
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _singleColTable(title: 'Addition', controllers: addition),
                            const SizedBox(width: 12),
                            _singleColTable(title: 'Loss', controllers: loss),
                            const SizedBox(width: 12),
                            _singleColTable(title: 'Water-based', controllers: water),
                            const SizedBox(width: 12),
                            _singleColTable(title: 'Oil-based', controllers: oil),
                            const SizedBox(width: 12),
                            _singleColTable(title: 'Synthetic', controllers: synthetic),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        _footerButtons(),
      ],
    );
  }

  // ======================================================
  // ACTIVITY TABLE (2 COLUMNS) - FIXED
  // ======================================================
  Widget _twoColTable({
    required String title,
    required List<TextEditingController> controllers,
    required double width,
  }) {
    final columnWidths = [50.0, width - 51]; // Account for 1px border
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionHeader(title, Icons.list_alt, AppTheme.primaryGradient),
          _headerRow(['#', 'Description'], columnWidths),
          Expanded(child: _rows2Col(controllers, columnWidths[1])),
        ],
      ),
    );
  }

  Widget _rows2Col(
      List<TextEditingController> controllers, double secondColWidth) {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        itemCount: rowCount,
        itemBuilder: (_, row) {
          return Container(
            height: 32,
            decoration: BoxDecoration(
              color: row % 2 == 0 ? Colors.white : AppTheme.cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  _numCell(row),
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  _editCell(secondColWidth, controllers[row]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ======================================================
  // SINGLE COLUMN TABLES - FIXED
  // =====================================================
  Widget _singleColTable({
    required String title,
    required List<TextEditingController> controllers,
  }) {
    final gradients = [
      AppTheme.secondaryGradient,
      AppTheme.accentGradient,
      AppTheme.headerGradient,
      LinearGradient(
        colors: [Color(0xffFFB347), Color(0xffFFCC33)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Color(0xffDA70D6), Color(0xff9370DB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Color(0xff20B2AA), Color(0xff40E0D0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];
    
    final icons = [
      Icons.add_circle,
      Icons.remove_circle,
      Icons.water_drop,
      Icons.local_gas_station,
      Icons.science,
    ];
    
    final iconIndex = ['Addition', 'Loss', 'Water-based', 'Oil-based', 'Synthetic']
        .indexOf(title);
    
    final columnWidths = [50.0, 159.0];
    final tableWidth = columnWidths[0] + columnWidths[1] + 1; // 50 + 159 + 1 border
    
    return Container(
      width: tableWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionHeader(
            title, 
            iconIndex >= 0 ? icons[iconIndex] : Icons.category,
            iconIndex >= 0 ? gradients[iconIndex] : AppTheme.primaryGradient,
          ),
          _headerRow(['#', title], columnWidths),
          Expanded(child: _rowsSingleCol(controllers, columnWidths[1])),
        ],
      ),
    );
  }

  Widget _rowsSingleCol(List<TextEditingController> controllers, double secondColWidth) {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        itemCount: rowCount,
        itemBuilder: (_, row) {
          return Container(
            height: 32,
            decoration: BoxDecoration(
              color: row % 2 == 0 ? Colors.white : AppTheme.cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  _numCell(row),
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  _editCell(secondColWidth, controllers[row]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ======================================================
  // COMMON UI PARTS - FIXED
  // ======================================================
  Widget _sectionHeader(String text, IconData icon, Gradient gradient) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow(List<String> labels, List<double> widths) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.tableHeadColor.withOpacity(0.9),
            AppTheme.tableHeadColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isLast = i == labels.length - 1;
          return Container(
            width: widths[i],
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border(
                right: isLast 
                  ? BorderSide.none
                  : BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              ),
            ),
            child: Center(
              child: Text(
                labels[i],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _numCell(int row) {
    return SizedBox(
      width: 50,
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.secondaryGradient,
          ),
          child: Center(
            child: Text(
              '${row + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editCell(double width, TextEditingController controller) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textPrimary,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ======================================================
  // FOOTER BUTTONS
  // ======================================================
  Widget _footerButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {
              // Close functionality
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              // Save functionality
              _saveData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveData() {
    // Collect all data from text controllers
    final Map<String, List<String>> data = {
      'Activity': activity.map((c) => c.text).toList(),
      'Addition': addition.map((c) => c.text).toList(),
      'Loss': loss.map((c) => c.text).toList(),
      'Water-based': water.map((c) => c.text).toList(),
      'Oil-based': oil.map((c) => c.text).toList(),
      'Synthetic': synthetic.map((c) => c.text).toList(),
    };

    // TODO: Implement actual save logic
    print('Saving data: $data');
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data saved successfully'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}