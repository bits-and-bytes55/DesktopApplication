import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  static const int rowCount = 100;
  int selectedRow = -1;
  final ScrollController _scrollController = ScrollController();

  final List<List<TextEditingController>> controllers =
      List.generate(rowCount, (_) {
    return List.generate(12, (_) => TextEditingController());
  });

  @override
  void dispose() {
    _scrollController.dispose();
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _table()),
                  const SizedBox(width: 8),
                  _rightToolbar(),
                ],
              ),
            ),
            _footerButtons(),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // MAIN TABLE
  // ======================================================
  Widget _table() {
    return Container(
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
          _headerTop(),
          _headerBottom(),
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
          Expanded(child: _rows()),
        ],
      ),
    );
  }

  // ======================================================
  // HEADER ROW 1
  // ======================================================
  Widget _headerTop() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: const [
          _HCell(45, '#', Icons.numbers, false),
          _HCell(210, 'Product', Icons.inventory, true),
          _HCell(130, 'Code', Icons.code, true),
          _HCell(90, 'SG', Icons.scale, true),
          _HCell(170, 'Unit', Icons.linear_scale, true),
          _HCell(130, 'Group', Icons.category, true),
          Expanded(child: SizedBox()), // Spacer for empty cell
        ],
      ),
    );
  }

  // ======================================================
  // HEADER ROW 2
  // ======================================================
  Widget _headerBottom() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: const [
          _HCell(45, '', null, false),
          _HCell(210, '', null, false),
          _HCell(130, '', null, false),
          _HCell(90, '', null, false),
          _HCell(90, 'Num', Icons.format_list_numbered, true),
          _HCell(90, 'Class', Icons.class_, true),
          _HCell(130, '', null, false),
          _HCell(60, 'Retail', Icons.shopping_cart, true),
          _HCell(60, 'A', Icons.tag, true),
          _HCell(60, 'B', Icons.tag, true),
          _HCell(60, 'C', Icons.tag, true),
          _HCell(60, 'D', Icons.tag, true),
          _HCell(60, 'E', Icons.tag, true),
          _HCell(60, 'F', Icons.tag, true),
        ],
      ),
    );
  }

  // ======================================================
  // TABLE ROWS
  // ======================================================
  Widget _rows() {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: rowCount,
        itemBuilder: (_, row) {
          final selected = row == selectedRow;
          return GestureDetector(
            onTap: () => setState(() => selectedRow = row),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : row % 2 == 0
                        ? Colors.white
                        : AppTheme.cardColor,
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
                    _numberCell(row),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(210, controllers[row][0]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(130, controllers[row][1]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(90, controllers[row][2]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(90, controllers[row][3]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(90, controllers[row][4]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(130, controllers[row][5]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(60, controllers[row][6]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(60, controllers[row][7]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(60, controllers[row][8]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(60, controllers[row][9]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(60, controllers[row][10]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    _cell(60, controllers[row][11]),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _numberCell(int row) {
    return SizedBox(
      width: 45,
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

  Widget _cell(double width, TextEditingController controller) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textPrimary,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  // ======================================================
  // RIGHT ICON TOOLBAR
  // ======================================================
  Widget _rightToolbar() {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: const [
          SizedBox(height: 8),
          _IconBtn(Icons.upload_file, 'Import Master Products'),
          _IconBtn(Icons.download, 'Download Master Products'),
          _IconBtn(Icons.edit, 'Edit Schedule Name'),
          _IconBtn(Icons.category, 'Product Group'),
        ],
      ),
    );
  }

  // ======================================================
  // FOOTER BUTTONS
  // ======================================================
  Widget _footerButtons() {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.errorColor),
              foregroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Close'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// HEADER CELL
// ======================================================
class _HCell extends StatelessWidget {
  final double width;
  final String text;
  final IconData? icon;
  final bool showDivider;

  const _HCell(this.width, this.text, this.icon, this.showDivider);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                right: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text,
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
        ],
      ),
    );
  }
}

// ======================================================
// ICON BUTTON WITH TOOLTIP
// ======================================================
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;

  const _IconBtn(this.icon, this.tooltip);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}