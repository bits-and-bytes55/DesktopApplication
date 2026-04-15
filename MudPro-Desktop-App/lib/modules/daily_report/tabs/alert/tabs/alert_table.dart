import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertUsagePredictionPage extends StatelessWidget {
  const AlertUsagePredictionPage({super.key});

  static const double rowH = 36;

  // ================= CELL =================
  Widget cell(
    String text, {
    double w = 100,
    bool bold = false,
    bool isHeader = false,
    bool isSubHeader = false,
    Alignment align = Alignment.center,
    bool editable = false,
    Color? bgColor,
  }) {
    return Container(
      width: w,
      height: rowH,
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isHeader 
              ? AppTheme.primaryColor
              : isSubHeader
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.grey.shade300,
          width: 0.5,
        ),
        color: isHeader
            ? AppTheme.primaryColor
            : isSubHeader
                ? AppTheme.primaryColor.withOpacity(0.08)
                : bgColor ?? Colors.white,
      ),
      child: editable
          ? TextField(
              controller: TextEditingController(text: text),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: AppTheme.primaryColor,
            )
          : Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isHeader || isSubHeader ? 11 : 12,
                fontWeight: bold || isHeader || isSubHeader
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isHeader
                    ? Colors.white
                    : isSubHeader
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimary,
              ),
            ),
    );
  }

  // ================= HEADER GROUP =================
  Widget group(String title, double width, {bool isHeader = false}) {
    return cell(title,
        w: width,
        bold: true,
        isHeader: isHeader,
        align: Alignment.center);
  }

  // ================= PRODUCT TABLE =================
  Widget productTable() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= TITLE HEADER =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Usage Prediction – Product, Premixed Mud and Package',
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '20 Products',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= TABLE CONTENT =================
          SizedBox(
            height: 450, // Fixed height
            child: Scrollbar(
              thumbVisibility: true,
              interactive: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1250,
                  child: Scrollbar(
                    thumbVisibility: true,
                    interactive: true,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        // ================= HEADER ROW 1 =================
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            group('Description', 220, isHeader: true),
                            group('Unit', 80, isHeader: true),
                            group('Price (€)', 90, isHeader: true),
                            group('Usage', 240, isHeader: true),
                            group('Current Inventory', 130, isHeader: true),
                            group('Daily Usage Prediction', 240, isHeader: true),
                            group('Zero Inventory in D', 150, isHeader: true),
                          ]),
                        ),

                        // ================= HEADER ROW 2 =================
                        Row(children: [
                          cell('', w: 220, isSubHeader: true),
                          cell('', w: 80, isSubHeader: true),
                          cell('', w: 90, isSubHeader: true),
                          cell('-2', w: 80, isSubHeader: true, bold: true),
                          cell('-1', w: 80, isSubHeader: true, bold: true),
                          cell('Today', w: 80, isSubHeader: true, bold: true),
                          cell('', w: 130, isSubHeader: true),
                          cell('Tomorrow', w: 80, isSubHeader: true, bold: true),
                          cell('+1', w: 80, isSubHeader: true, bold: true),
                          cell('+2', w: 80, isSubHeader: true, bold: true),
                          cell('', w: 150, isSubHeader: true),
                        ]),

                        // ================= DATA ROWS =================
                        ...List.generate(20, (index) {
                          final i = index + 1;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 0.5,
                                ),
                              ),
                              color: i.isEven
                                  ? Colors.white
                                  : AppTheme.backgroundColor.withOpacity(0.3),
                            ),
                            child: Row(children: [
                              cell('Item $i',
                                  w: 220,
                                  align: Alignment.centerLeft,
                                  bgColor: Colors.transparent),
                              cell('25.00 kg',
                                  w: 80, bgColor: Colors.transparent),
                              cell('42.00',
                                  w: 90,
                                  editable: true,
                                  bgColor: Colors.transparent),
                              cell('0.00',
                                  w: 80,
                                  editable: true,
                                  bgColor: Colors.transparent),
                              cell('0.00',
                                  w: 80,
                                  editable: true,
                                  bgColor: Colors.transparent),
                              cell('10.00',
                                  w: 80,
                                  editable: true,
                                  bgColor: Colors.transparent),
                              cell('138.00',
                                  w: 130, bgColor: Colors.transparent),
                              cell('10.00', w: 80, bgColor: Colors.transparent),
                              cell('10.00', w: 80, bgColor: Colors.transparent),
                              cell('10.00', w: 80, bgColor: Colors.transparent),
                              cell('—', w: 150, bgColor: Colors.transparent),
                            ]),
                          );
                        }),
                      ],
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

  // ================= SERVICE / ENGINEERING TABLE =================
  Widget serviceTable() {
    return Container(
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= TITLE HEADER =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Usage Prediction – Service and Engineering',
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '20 Services',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= TABLE CONTENT =================
          SizedBox(
            height: 450, // Fixed height
            child: Scrollbar(
              thumbVisibility: true,
              interactive: true,
              thickness: 8,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1100,
                  child: Scrollbar(
                    thumbVisibility: true,
                    interactive: true,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        // ================= HEADER ROW 1 =================
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            group('Description', 260, isHeader: true),
                            group('Unit', 80, isHeader: true),
                            group('Price (€)', 100, isHeader: true),
                            group('Usage', 240, isHeader: true),
                            group('Daily Usage Prediction', 240, isHeader: true),
                          ]),
                        ),

                        // ================= HEADER ROW 2 =================
                        Row(children: [
                          cell('', w: 260, isSubHeader: true),
                          cell('', w: 80, isSubHeader: true),
                          cell('', w: 100, isSubHeader: true),
                          cell('-2', w: 80, isSubHeader: true, bold: true),
                          cell('-1', w: 80, isSubHeader: true, bold: true),
                          cell('Today', w: 80, isSubHeader: true, bold: true),
                          cell('Tomorrow', w: 80, isSubHeader: true, bold: true),
                          cell('+1', w: 80, isSubHeader: true, bold: true),
                          cell('+2', w: 80, isSubHeader: true, bold: true),
                        ]),

                        // ================= DATA ROWS =================
                        ...List.generate(20, (index) {
                          final i = index + 1;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 0.5,
                                ),
                              ),
                              color: i.isEven
                                  ? Colors.white
                                  : AppTheme.backgroundColor.withOpacity(0.3),
                            ),
                            child: Row(children: [
                              cell('Mud Supervisor $i',
                                  w: 260,
                                  align: Alignment.centerLeft,
                                  bgColor: Colors.transparent),
                              cell('1', w: 80, bgColor: Colors.transparent),
                              cell('173.33',
                                  w: 100,
                                  editable: true,
                                  bgColor: Colors.transparent),
                              cell('0.00',
                                  w: 80,
                                  editable: true,
                                  bgColor: Colors.transparent),
                              cell('0.00',
                                  w: 80,
                                  editable: true,
                                  bgColor: Colors.transparent),
                              cell('3.00',
                                  w: 80,
                                  editable: true,
                                  bgColor: Colors.transparent),
                              cell('3.00', w: 80, bgColor: Colors.transparent),
                              cell('3.00', w: 80, bgColor: Colors.transparent),
                              cell('3.00', w: 80, bgColor: Colors.transparent),
                            ]),
                          );
                        }),
                      ],
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

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PAGE HEADER
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Usage Prediction Dashboard',
                    style: AppTheme.titleMedium.copyWith(
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.secondaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.analytics,
                            size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Predictive Analysis',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // MAIN CONTENT WITH FIXED HEIGHT
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    productTable(),
                    const SizedBox(height: 20),
                    serviceTable(),
                    const SizedBox(height: 20),

                    // SUMMARY FOOTER
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.edit,
                                    size: 16, color: AppTheme.successColor),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Editable Fields',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Click on any price or usage field to edit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.infoColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppTheme.infoColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Total: 40 Records',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.infoColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}