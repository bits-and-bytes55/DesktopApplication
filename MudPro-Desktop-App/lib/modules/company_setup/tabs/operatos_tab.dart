import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

/// =======================================================
/// OPERATOR TAB (IMPROVED TABLE UI)
/// =======================================================
class OperatorTab extends StatefulWidget {
  const OperatorTab({super.key});

  @override
  State<OperatorTab> createState() => _OperatorTabState();
}

class _OperatorTabState extends State<OperatorTab> {
  static const int totalRows = 50; // Reduced for better performance
  int selectedRow = -1;
  int arrowRow = -1;
  final ScrollController _scrollController = ScrollController();

  final List<List<TextEditingController>> controllers =
      List.generate(totalRows, (_) {
    return List.generate(6, (_) => TextEditingController());
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Close Button
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.secondaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_center,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Operator ',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
            
            ],
          ),
          const SizedBox(height: 16),

          // Table Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                color: Colors.white,
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
                  // Table Header with Dark Vertical Dividers
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _HeaderCell(width: 60, text: '#', icon: Icons.numbers, 
                          showRightDivider: true, dividerColor: AppTheme.textPrimary.withOpacity(0.3)),
                        _HeaderCell(width: 180, text: 'Company', icon: Icons.business,
                          showRightDivider: true, dividerColor: AppTheme.textPrimary.withOpacity(0.3)),
                        _HeaderCell(width: 160, text: 'Contact', icon: Icons.person,
                          showRightDivider: true, dividerColor: AppTheme.textPrimary.withOpacity(0.3)),
                        _HeaderCell(width: 240, text: 'Address', icon: Icons.location_on,
                          showRightDivider: true, dividerColor: AppTheme.textPrimary.withOpacity(0.3)),
                        _HeaderCell(width: 160, text: 'Phone', icon: Icons.phone,
                          showRightDivider: true, dividerColor: AppTheme.textPrimary.withOpacity(0.3)),
                        _HeaderCell(width: 240, text: 'E-mail', icon: Icons.email,
                          showRightDivider: true, dividerColor: AppTheme.textPrimary.withOpacity(0.3)),
                        _HeaderCell(width: 140, text: 'Logo', icon: Icons.image,
                          showRightDivider: false),
                      ],
                    ),
                  ),

                  // Table Body
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: totalRows,
                        itemBuilder: (context, row) {
                          final bool isSelected = row == selectedRow;
                          final bool showArrow = row == arrowRow;

                          return Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected 
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
                              child: InkWell(
                                onTap: () => setState(() {
                                  selectedRow = row;
                                }),
                                hoverColor: AppTheme.primaryColor.withOpacity(0.05),
                                child: Row(
                                  children: [
                                    // Number Column with Arrow
                                    SizedBox(
                                      width: 60,
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () => setState(() {
                                                arrowRow = arrowRow == row ? -1 : row;
                                              }),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: showArrow
                                                      ? AppTheme.accentColor
                                                      : AppTheme.secondaryColor.withOpacity(0.2),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${row + 1}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: showArrow
                                                          ? Colors.white
                                                          : AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (showArrow)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4),
                                                child: GestureDetector(
                                                  onTap: () => setState(() {
                                                    selectedRow = row;
                                                  }),
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: isSelected
                                                          ? AppTheme.primaryGradient
                                                          : AppTheme.secondaryGradient,
                                                    ),
                                                    child: Icon(
                                                      isSelected
                                                          ? Icons.check
                                                          : Icons.arrow_forward,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: double.infinity,
                                      color: Colors.grey.shade400,
                                    ),

                                    // Data Cells with Vertical Dividers
                                    _cell(180, controllers[row][0], '', showDivider: true),
                                    _cell(160, controllers[row][1], '', showDivider: true),
                                    _cell(240, controllers[row][2], '', showDivider: true),
                                    _cell(160, controllers[row][3], '', showDivider: true),
                                    _cell(240, controllers[row][4], '', showDivider: true),
                                    _cell(140, controllers[row][5], '', showDivider: false),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer with Close Button
          Container(
            height: 50,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$totalRows operators • Selected: ${selectedRow == -1 ? 'None' : 'Row ${selectedRow + 1}'}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Close Button at bottom
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.errorColor),
                        foregroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (selectedRow != -1) {
                          for (var controller in controllers[selectedRow]) {
                            controller.clear();
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.warningColor),
                        foregroundColor: AppTheme.warningColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Clear Selected'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: AppTheme.primaryButtonStyle.copyWith(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(double width, TextEditingController controller, String hintText, 
      {bool showDivider = true}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                left: BorderSide(color: Colors.grey.shade400, width: 0.5),
              )
            : null,
      ),
      child: TextField(
        controller: controller,
        style: AppTheme.bodyLarge.copyWith(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withOpacity(0.6),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        ),
      ),
    );
  }
}

/// =======================================================
/// OTHER TABS (SAMPLE IMPLEMENTATION)
/// =======================================================

class MudCompanyTab extends StatelessWidget {
  const MudCompanyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Mud Company Configuration',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure mud company settings',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductTab extends StatelessWidget {
  const ProductTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Product Management',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage product catalog and inventory',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.miscellaneous_services,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Services Configuration',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure service offerings',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class OthersTab extends StatelessWidget {
  const OthersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Other Settings',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Additional configuration options',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyTab extends StatelessWidget {
  const SafetyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Safety Protocols',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure safety and compliance settings',
            style: AppTheme.bodySmall.copyWith(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================================================
/// HEADER CELL WIDGET (WITH ICON AND DIVIDER)
/// =======================================================
class _HeaderCell extends StatelessWidget {
  final double width;
  final String text;
  final IconData icon;
  final bool showRightDivider;
  final Color dividerColor;

  const _HeaderCell({
    required this.width,
    required this.text,
    required this.icon,
    this.showRightDivider = true,
    this.dividerColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: showRightDivider
            ? Border(
                right: BorderSide(color: dividerColor, width: 1),
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
}