import 'package:flutter/material.dart';
import '../../../controller/inventory_snapshot_controller.dart';

class DailyCostTableUsagePage extends StatefulWidget {
  const DailyCostTableUsagePage({super.key});

  @override
  State<DailyCostTableUsagePage> createState() =>
      _DailyCostTableUsagePageState();
}

class _DailyCostTableUsagePageState extends State<DailyCostTableUsagePage> {
  final ScrollController _h = ScrollController();
  final ScrollController _v = ScrollController();

  final InventorySnapshotController _inventoryController =
      InventorySnapshotController();

  // Grouped data: { "Product": [...], "Engineering": [...], ... }
  Map<String, List<Map<String, dynamic>>> _groupedData = {};
  bool _isLoading = true;
  String _errorMessage = '';

  // Summary totals (computed after data loads)
  double _subtotal = 0;
  double _dailyTotal = 0;
  double _prevTotal = 0;
  double _cumTotal = 0;
  double _intervalTotal = 0;
  double _stockBalance = 0;
  double _bulkSetupFee = 0;

  @override
  void initState() {
    super.initState();
    print('🟡 [INIT] DailyCostTableUsagePage initState called');
    _fetchInventoryData();
  }

  // ─────────────────────────────────────────────
  //  FETCH
  // ─────────────────────────────────────────────
  Future<void> _fetchInventoryData() async {
    print('🟡 [FETCH] _fetchInventoryData() started');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Step 1: Generate snapshot
      print('🔵 [FETCH] Calling generateInventorySnapshot...');
      final genResult = await _inventoryController.generateInventorySnapshot();
      print('🟢 [FETCH] generateInventorySnapshot result: $genResult');

      if (genResult['success'] == false) {
        print('🔴 [FETCH] Snapshot generation failed: ${genResult['message']}');
      } else {
        print('🟢 [FETCH] Snapshot generation success. Count: ${genResult['count']}');
      }

      // Step 2: Fetch snapshot data
      print('🔵 [FETCH] Calling getInventorySnapshot...');
      final data = await _inventoryController.getInventorySnapshot();
      print('🟢 [FETCH] getInventorySnapshot returned ${data.length} items');
      print('🟢 [FETCH] Raw data: $data');

      // Step 3: Group by category
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final item in data) {
        final category = (item['category'] ?? 'Unknown').toString();
        print('🔵 [GROUP] Item category: "$category" | itemName: "${item['itemName']}"');
        grouped.putIfAbsent(category, () => []);
        grouped[category]!.add(item);
      }

      print('🟢 [GROUP] Categories found: ${grouped.keys.toList()}');
      grouped.forEach((cat, items) {
        print('   → "$cat": ${items.length} items');
      });

      // Step 4: Compute summary totals
      double subtotal = 0;
      for (final item in data) {
        final s = (item['subtotal'] ?? 0).toDouble();
        subtotal += s;
        print('🔵 [TOTAL] item "${item['itemName']}" subtotal: $s');
      }
      print('🟢 [TOTAL] Computed overall subtotal: $subtotal');

      setState(() {
        _groupedData = grouped;
        _subtotal = subtotal;
        _dailyTotal = subtotal;
        _prevTotal = 0;
        _cumTotal = subtotal;
        _intervalTotal = 0;
        _stockBalance = subtotal;
        _bulkSetupFee = 0;
        _isLoading = false;
      });

      print('🟢 [FETCH] setState done. UI should refresh now.');
    } catch (e, stackTrace) {
      print('🔴 [FETCH] Exception caught: $e');
      print('🔴 [FETCH] StackTrace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ─────────────────────────────────────────────
  //  LAYOUT CONSTANTS
  // ─────────────────────────────────────────────
  static const double rowHeight = 32;

  final List<double> col = [
    60,  // 0  #
    150, // 1  Category
    150, // 2  Item
    75,  // 3  Price
    75,  // 4  Cum Rec
    75,  // 5  Cum Ret
    75,  // 6  Cum Used
    75,  // 7  Initial
    75,  // 8  Rec
    75,  // 9  Ret
    75,  // 10 Adj
    75,  // 11 Used
    75,  // 12 Final
    100, // 13 Subtotal
    75,  // 14 Cost $
    75,  // 15 Cost %
    75,  // 16 Total $
    78,  // 17 Total %
  ];

  double get tableWidth => col.reduce((a, b) => a + b);

  // ─────────────────────────────────────────────
  //  HELPER: format number
  // ─────────────────────────────────────────────
  String _fmt(dynamic v, {int decimals = 2}) {
    if (v == null) return '';
    final d = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    if (decimals == 0) return d.toStringAsFixed(0);
    return d.toStringAsFixed(decimals);
  }

  // ─────────────────────────────────────────────
  //  CELL (view-only)
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  //  HEADER (unchanged)
  // ─────────────────────────────────────────────
  Widget header() {
    Widget h(String t, double w, {bool isHeader = false}) =>
        cell(t, w, bold: true, isHeader: isHeader);

    return Column(
      children: [
        // ── Row 1: grouped labels ──
        Container(
          height: rowHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff6C9BCF), Color(0xff5A8BC5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            h('#', col[0], isHeader: true),
            h('Category', col[1], isHeader: true),
            h('Item', col[2], isHeader: true),
            h('Price', col[3], isHeader: true),
            // Cumulative span
            Container(
              width: col[4] * 3,
              height: rowHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 0.5),
              ),
              child: const Text('Cumulative',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
            h('Initial', col[7], isHeader: true),
            h('Rec.', col[8], isHeader: true),
            h('Ret.', col[9], isHeader: true),
            h('Adj.', col[10], isHeader: true),
            h('Used', col[11], isHeader: true),
            h('Final', col[12], isHeader: true),
            h('Subtotal', col[13], isHeader: true),
            // Cost span
            Container(
              width: col[14] * 2,
              height: rowHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 0.5),
              ),
              child: const Text('Cost',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
            // Total span
            Container(
              width: col[16] + col[17],
              height: rowHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 0.5),
              ),
              child: const Text('Total',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ]),
        ),

        // ── Row 2: sub-labels ──
        Container(
          height: rowHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff8BB8E8), Color(0xff7AA8D8)],
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

  // ─────────────────────────────────────────────
  //  DATA ROW (view-only, dynamic)
  // ─────────────────────────────────────────────
  Widget dataRow(int rowIndex, Map<String, dynamic> item, Color bg) {
    print('🔵 [ROW] Building row $rowIndex for item: "${item['itemName']}" | category: "${item['category']}"');

    final price       = _fmt(item['price']);
    final cumRec      = _fmt(item['cumulativeRec'], decimals: 0);
    final cumRet      = _fmt(item['cumulativeRet'], decimals: 0);
    final cumUsed     = _fmt(item['cumulativeUsed'], decimals: 0);
    final initial     = _fmt(item['initial'], decimals: 0);
    final rec         = _fmt(item['rec'], decimals: 0);
    final ret         = _fmt(item['ret'], decimals: 0);
    final adj         = _fmt(item['adj'], decimals: 0);
    final used        = _fmt(item['used'], decimals: 0);
    final finalVal    = _fmt(item['final'], decimals: 0);
    final subtotal    = _fmt(item['subtotal']);
    final costDollar  = _fmt(item['costDollar']);
    final costPercent = _fmt(item['costPercent']);
    final totalDollar = _fmt(item['totalDollar']);
    final totalPercent= _fmt(item['totalPercent']);

    print('   price=$price | cumRec=$cumRec | cumRet=$cumRet | cumUsed=$cumUsed');
    print('   initial=$initial | rec=$rec | ret=$ret | adj=$adj | used=$used | final=$finalVal');
    print('   subtotal=$subtotal | costDollar=$costDollar | costPercent=$costPercent');
    print('   totalDollar=$totalDollar | totalPercent=$totalPercent');

    return Container(
      color: bg,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        cell('$rowIndex', col[0]),
        cell('', col[1]),           // category column — filled by Stack overlay
        cell(item['itemName']?.toString() ?? '', col[2], a: Alignment.centerLeft),
        cell(price,       col[3],  a: Alignment.centerRight),
        cell(cumRec,      col[4],  a: Alignment.centerRight),
        cell(cumRet,      col[5],  a: Alignment.centerRight),
        cell(cumUsed,     col[6],  a: Alignment.centerRight),
        cell(initial,     col[7],  a: Alignment.centerRight),
        cell(rec,         col[8],  a: Alignment.centerRight),
        cell(ret,         col[9],  a: Alignment.centerRight),
        cell(adj,         col[10], a: Alignment.centerRight),
        cell(used,        col[11], a: Alignment.centerRight),
        cell(finalVal,    col[12], a: Alignment.centerRight),
        cell(subtotal,    col[13], a: Alignment.centerRight),
        cell(costDollar,  col[14], a: Alignment.centerRight),
        cell(costPercent, col[15], a: Alignment.centerRight),
        cell(totalDollar, col[16], a: Alignment.centerRight),
        cell(totalPercent,col[17], a: Alignment.centerRight),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  SUMMARY ROW (unchanged)
  // ─────────────────────────────────────────────
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
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700)),
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
        child: Text(value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xff6C9BCF))),
      ),
    ]);
  }

  // ─────────────────────────────────────────────
  //  CATEGORY BLOCK  (rows + overlay label)
  // ─────────────────────────────────────────────
  _CategoryStyle _styleForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'product':
        return _CategoryStyle(
          bgLabel: const Color(0xffE8F4FD),
          bgTotal: const Color(0xffE8F4FD),
          labelColor: const Color(0xff6C9BCF),
          totalColor: const Color(0xff6C9BCF),
        );
      case 'service':
      case 'premixed mud':
        return _CategoryStyle(
          bgLabel: const Color(0xffFFF3CD),
          bgTotal: const Color(0xffFFF3CD),
          labelColor: const Color(0xff856404),
          totalColor: const Color(0xff856404),
        );
      case 'engineering':
        return _CategoryStyle(
          bgLabel: const Color(0xffF0E8FD),
          bgTotal: const Color(0xffF0E8FD),
          labelColor: const Color(0xffA8D5BA),
          totalColor: const Color(0xffA8D5BA),
        );
      default:
        return _CategoryStyle(
          bgLabel: Colors.grey.shade100,
          bgTotal: Colors.grey.shade100,
          labelColor: Colors.grey.shade700,
          totalColor: Colors.grey.shade700,
        );
    }
  }

  Widget _buildCategoryBlock(
    String category,
    List<Map<String, dynamic>> items,
    int startIndex,
  ) {
    print('🔵 [BLOCK] Building category block: "$category" with ${items.length} items, starting at row $startIndex');

    final style = _styleForCategory(category);
    final blockHeight = items.length * rowHeight;

    // Compute category totals for Total $ and Total %
    double catTotalDollar = 0;
    double catTotalPercent = 0;
    for (final item in items) {
      catTotalDollar  += (item['totalDollar']  ?? 0).toDouble();
      catTotalPercent += (item['totalPercent'] ?? 0).toDouble();
    }
    print('🟢 [BLOCK] "$category" → totalDollar=$catTotalDollar | totalPercent=$catTotalPercent');

    return Stack(
      children: [
        // ── data rows ──
        Column(
          children: List.generate(items.length, (idx) {
            final rowBg = (startIndex + idx).isOdd
                ? Colors.white
                : const Color(0xffF8F9FA);
            return dataRow(startIndex + idx, items[idx], rowBg);
          }),
        ),

        // ── category label overlay ──
        Positioned(
          left: col[0],
          top: 0,
          child: Container(
            width: col[1],
            height: blockHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: style.bgLabel,
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: style.labelColor,
              ),
            ),
          ),
        ),

        // ── Total $ overlay ──
        Positioned(
          left: tableWidth - col[16] - col[17],
          top: 0,
          child: Row(children: [
            Container(
              width: col[16],
              height: blockHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: style.bgTotal.withOpacity(0.7),
                border: Border.all(color: Colors.grey.shade200, width: 0.5),
              ),
              child: Text(
                _fmt(catTotalDollar),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: style.totalColor),
              ),
            ),
            Container(
              width: col[17],
              height: blockHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: style.bgTotal.withOpacity(0.7),
                border: Border.all(color: Colors.grey.shade200, width: 0.5),
              ),
              child: Text(
                _fmt(catTotalPercent),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: style.totalColor),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    print('🟡 [BUILD] build() called | isLoading=$_isLoading | categories=${_groupedData.keys.toList()}');

    return Scaffold(
      backgroundColor: const Color(0xffFAF9F6),
      appBar: AppBar(
        title: Text('Inventory Snapshot',
            style: TextStyle(color: Colors.blue[900])),
        backgroundColor: const Color(0xffFAF9F6),
        toolbarHeight: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              print('🟡 [UI] Refresh button pressed');
              _fetchInventoryData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text('Error: $_errorMessage',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchInventoryData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildTable(),
    );
  }

  Widget _buildTable() {
    print('🟡 [TABLE] _buildTable() called');

    // Build blocks in order of categories received
    final categories = _groupedData.keys.toList();
    print('🔵 [TABLE] Category order: $categories');

    // Flat list so we can give correct row numbers
    int globalRowIndex = 1;
    final List<Widget> categoryBlocks = [];
    for (final cat in categories) {
      final items = _groupedData[cat]!;
      print('🔵 [TABLE] Rendering "$cat" block: ${items.length} rows starting at $globalRowIndex');
      categoryBlocks.add(
        _buildCategoryBlock(cat, items, globalRowIndex),
      );
      globalRowIndex += items.length;
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                            // ── all category blocks ──
                            ...categoryBlocks,

                            // ── summary rows ──
                            summaryRow('Subtotal (\$)',        _fmt(_subtotal)),
                            summaryRow('Tax (0.000%)',          '0.00'),
                            summaryRow('Daily Total (\$)',      _fmt(_dailyTotal)),
                            summaryRow('Prev. Total (\$)',      _fmt(_prevTotal)),
                            summaryRow('Cum. Total (\$)',       _fmt(_cumTotal)),
                            summaryRow('Interval Total (\$)',   _fmt(_intervalTotal)),
                            summaryRow('Stock Balance (\$)',    _fmt(_stockBalance)),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xffF8F9FA),
                                border: Border.all(
                                    color: Colors.grey.shade200, width: 0.5),
                              ),
                              child: summaryRow(
                                  'Bulk Setup Fee (\$)', _fmt(_bulkSetupFee)),
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
    );
  }

  @override
  void dispose() {
    print('🟡 [DISPOSE] DailyCostTableUsagePage disposed');
    _h.dispose();
    _v.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
//  Helper model for category styling
// ─────────────────────────────────────────────
class _CategoryStyle {
  final Color bgLabel;
  final Color bgTotal;
  final Color labelColor;
  final Color totalColor;

  const _CategoryStyle({
    required this.bgLabel,
    required this.bgTotal,
    required this.labelColor,
    required this.totalColor,
  });
}