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

  Map<String, List<Map<String, dynamic>>> _groupedData = {};
  bool _isLoading = true;
  String _errorMessage = '';

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
    _fetchInventoryData();
  }

  // ─────────────────────────────────────────────
  //  FETCH — GET only, no generate ever from this page
  // ─────────────────────────────────────────────
  Future<void> _fetchInventoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _inventoryController.getInventorySnapshot();

      if (data.isEmpty) {
        setState(() {
          _groupedData = {};
          _subtotal = 0;
          _dailyTotal = 0;
          _prevTotal = 0;
          _cumTotal = 0;
          _intervalTotal = 0;
          _stockBalance = 0;
          _bulkSetupFee = 0;
          _isLoading = false;
        });
        return;
      }

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final item in data) {
        final category = (item['category'] ?? 'Unknown').toString();
        grouped.putIfAbsent(category, () => []);
        grouped[category]!.add(item);
      }

      double subtotal = 0;
      final double grandTotal = (data[0]['totalDollar'] ?? 0).toDouble();
      for (final item in data) {
        subtotal += (item['subtotal'] ?? 0).toDouble();
      }

      setState(() {
        _groupedData = grouped;
        _subtotal = subtotal;
        _dailyTotal = grandTotal > 0 ? grandTotal : subtotal;
        _prevTotal = 0;
        _cumTotal = _dailyTotal;
        _intervalTotal = 0;
        _stockBalance = _dailyTotal;
        _bulkSetupFee = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ─────────────────────────────────────────────
  //  LAYOUT CONSTANTS
  //  0  #        1  Category   2  Item
  //  3  Code     4  Unit       5  Price
  //  6  Cum Rec  7  Cum Ret    8  Cum Used
  //  9  Initial  10 Rec        11 Ret
  // 12  Adj      13 Used       14 Final
  // 15  Subtotal 16 Cost ($)   17 Total ($)
  // ─────────────────────────────────────────────
  static const double rowHeight = 32;

  final List<double> col = [
    60,  // 0  #
    150, // 1  Category
    150, // 2  Item
    90,  // 3  Code
    80,  // 4  Unit
    75,  // 5  Price
    75,  // 6  Cum Rec
    75,  // 7  Cum Ret
    75,  // 8  Cum Used
    75,  // 9  Initial
    75,  // 10 Rec
    75,  // 11 Ret
    75,  // 12 Adj
    75,  // 13 Used
    75,  // 14 Final
    100, // 15 Subtotal
    100, // 16 Cost ($)
    150, // 17 Total ($)
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
  //  CELL
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
  //  HEADER
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
            h('#',        col[0],  isHeader: true),
            h('Category', col[1],  isHeader: true),
            h('Item',     col[2],  isHeader: true),
            h('Code',     col[3],  isHeader: true),
            h('Unit',     col[4],  isHeader: true),
            h('Price',    col[5],  isHeader: true),
            // Cumulative span (3 sub-cols)
            Container(
              width: col[6] + col[7] + col[8],
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
            h('Initial',    col[9],  isHeader: true),
            h('Rec.',       col[10], isHeader: true),
            h('Ret.',       col[11], isHeader: true),
            h('Adj.',       col[12], isHeader: true),
            h('Used',       col[13], isHeader: true),
            h('Final',      col[14], isHeader: true),
            h('Subtotal',   col[15], isHeader: true),
            h('Cost (\$)',  col[16], isHeader: true),
            h('Total (\$)', col[17], isHeader: true),
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
            cell('', col[0],  isHeader: true),
            cell('', col[1],  isHeader: true),
            cell('', col[2],  isHeader: true),
            cell('', col[3],  isHeader: true),
            cell('', col[4],  isHeader: true),
            cell('', col[5],  isHeader: true),
            h('Rec.',  col[6],  isHeader: true),
            h('Ret.',  col[7],  isHeader: true),
            h('Used',  col[8],  isHeader: true),
            cell('', col[9],  isHeader: true),
            cell('', col[10], isHeader: true),
            cell('', col[11], isHeader: true),
            cell('', col[12], isHeader: true),
            cell('', col[13], isHeader: true),
            cell('', col[14], isHeader: true),
            cell('', col[15], isHeader: true),
            cell('', col[16], isHeader: true),
            cell('', col[17], isHeader: true),
          ]),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  DATA ROW
  // ─────────────────────────────────────────────
  Widget dataRow(int rowIndex, Map<String, dynamic> item, Color bg) {
    final code     = item['code']?.toString() ?? '';
    final unit     = item['unit']?.toString() ?? '';
    final price    = _fmt(item['price']);
    final cumRec   = _fmt(item['cumulativeRec'],  decimals: 0);
    final cumRet   = _fmt(item['cumulativeRet'],  decimals: 0);
    final cumUsed  = _fmt(item['cumulativeUsed'], decimals: 0);
    final initial  = _fmt(item['initial'],        decimals: 0);
    final rec      = _fmt(item['rec'],            decimals: 0);
    final ret      = _fmt(item['ret'],            decimals: 0);
    final adj      = _fmt(item['adj'],            decimals: 0);
    final used     = _fmt(item['used'],           decimals: 0);
    final finalVal = _fmt(item['final'],          decimals: 0);
    final subtotal = _fmt(item['subtotal']);
    final costVal  = _fmt(item['costDollar']);

    return Container(
      color: bg,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        cell('$rowIndex',                        col[0]),
        cell('',                                 col[1]),  // overlay handles category
        cell(item['itemName']?.toString() ?? '', col[2],  a: Alignment.centerLeft),
        cell(code,     col[3],  a: Alignment.centerLeft),
        cell(unit,     col[4],  a: Alignment.center),
        cell(price,    col[5],  a: Alignment.centerRight),
        cell(cumRec,   col[6],  a: Alignment.centerRight),
        cell(cumRet,   col[7],  a: Alignment.centerRight),
        cell(cumUsed,  col[8],  a: Alignment.centerRight),
        cell(initial,  col[9],  a: Alignment.centerRight),
        cell(rec,      col[10], a: Alignment.centerRight),
        cell(ret,      col[11], a: Alignment.centerRight),
        cell(adj,      col[12], a: Alignment.centerRight),
        cell(used,     col[13], a: Alignment.centerRight),
        cell(finalVal, col[14], a: Alignment.centerRight),
        cell(subtotal, col[15], a: Alignment.centerRight),
        cell(costVal,  col[16], a: Alignment.centerRight),
        cell('',       col[17], a: Alignment.centerRight),  // overlay handles total
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  SUMMARY ROW
  // ─────────────────────────────────────────────
  Widget summaryRow(String label, String value) {
    return Row(children: [
      Expanded(
        child: Container(
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
  //  CATEGORY STYLE
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

  // ─────────────────────────────────────────────
  //  CATEGORY BLOCK
  // ─────────────────────────────────────────────
  Widget _buildCategoryBlock(
    String category,
    List<Map<String, dynamic>> items,
    int startIndex,
  ) {
    final style = _styleForCategory(category);
    final blockHeight = items.length * rowHeight;

    double catTotal = 0;
    for (final item in items) {
      catTotal += (item['costDollar'] ?? 0).toDouble();
    }

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

        // ── Total overlay (last column, merged) ──
        Positioned(
          left: tableWidth - col[17],
          top: 0,
          child: Container(
            width: col[17],
            height: blockHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: style.bgTotal.withOpacity(0.7),
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Text(
              _fmt(catTotal),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: style.totalColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
            onPressed: _fetchInventoryData,
            tooltip: 'Refresh',
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
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
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
    final categories = _groupedData.keys.toList();

    int globalRowIndex = 1;
    final List<Widget> categoryBlocks = [];
    for (final cat in categories) {
      final items = _groupedData[cat]!;
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
                            ...categoryBlocks,
                            summaryRow('Subtotal (\$)',        _fmt(_subtotal)),
                            summaryRow('Tax (0.000%)',          ''),
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