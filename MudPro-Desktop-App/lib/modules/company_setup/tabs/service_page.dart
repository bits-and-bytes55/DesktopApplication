import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  static const int rowCount = 20;

  final List<List<TextEditingController>> packageControllers =
      _generateControllers();
  final List<List<TextEditingController>> servicesControllers =
      _generateControllers();
  final List<List<TextEditingController>> engineeringControllers =
      _generateControllers();

  static List<List<TextEditingController>> _generateControllers() {
    return List.generate(
      rowCount,
      (_) => List.generate(4, (_) => TextEditingController()),
    );
  }

  @override
  void dispose() {
    for (var table in [packageControllers, servicesControllers, engineeringControllers]) {
      for (var row in table) {
        for (var controller in row) {
          controller.dispose();
        }
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 1200) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _buildTableSections(constraints),
                      ),
                    );
                  } else {
                    return Row(
                      children: _buildTableSections(constraints),
                    );
                  }
                },
              ),
            ),
            _footerButtons(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTableSections(BoxConstraints constraints) {
    return [
      _tableSection(
        title: 'Package',
        controllers: packageControllers,
        icon: Icons.inventory,
        gradient: AppTheme.primaryGradient,
        constraints: constraints,
      ),
      const SizedBox(width: 12),
      _tableSection(
        title: 'Services',
        controllers: servicesControllers,
        icon: Icons.miscellaneous_services,
        gradient: AppTheme.secondaryGradient,
        constraints: constraints,
      ),
      const SizedBox(width: 12),
      _tableSection(
        title: 'Engineering',
        controllers: engineeringControllers,
        icon: Icons.engineering,
        gradient: AppTheme.accentGradient,
        constraints: constraints,
      ),
    ];
  }

  // ======================================================
  // TABLE SECTION
  // ======================================================
  Widget _tableSection({
    required String title,
    required List<List<TextEditingController>> controllers,
    required IconData icon,
    required Gradient gradient,
    required BoxConstraints constraints,
  }) {
    // Calculate responsive widths
    final isSmallScreen = constraints.maxWidth < 400;
    final widths = isSmallScreen
        ? [25.0, 100.0, 50.0, 40.0, 50.0]
        : [35.0, 150.0, 75.0, 65.0, 75.0];

    return Expanded(
      child: Container(
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
            _sectionHeader(title, icon, gradient),
            _tableHeader(widths),
            Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
            Expanded(child: _tableRows(controllers, widths)),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // SECTION TITLE
  // ======================================================
  Widget _sectionHeader(String title, IconData icon, Gradient gradient) {
    return Container(
      height: 36,
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
            width: 24,
            height: 24,
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
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // TABLE HEADER
  // ======================================================
  Widget _tableHeader(List<double> widths) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.tableHeadColor.withOpacity(0.9),
            AppTheme.tableHeadColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          _HeaderCell(width: widths[0], text: '#', icon: Icons.numbers),
          _HeaderCell(width: widths[1], text: 'Name', icon: Icons.text_fields),
          _HeaderCell(width: widths[2], text: 'Code', icon: Icons.code),
          _HeaderCell(width: widths[3], text: 'Unit', icon: Icons.linear_scale),
          Expanded(child: _HeaderCell(text: 'Price (\$)', icon: Icons.attach_money)),
        ],
      ),
    );
  }

  // ======================================================
  // TABLE ROWS
  // ======================================================
  Widget _tableRows(List<List<TextEditingController>> controllers, List<double> widths) {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        itemCount: rowCount,
        itemBuilder: (_, row) {
          return Container(
            height: 28,
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
                  _numberCell(row, widths[0]),
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  _editCell(widths[1], controllers[row][0]),
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  _editCell(widths[2], controllers[row][1]),
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  _editCell(widths[3], controllers[row][2]),
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  _editCell(widths[4], controllers[row][3]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _numberCell(int row, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.secondaryColor.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              '${row + 1}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontSize: 11,
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
class _HeaderCell extends StatelessWidget {
  final double? width;
  final String text;
  final IconData icon;

  const _HeaderCell({this.width, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
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
