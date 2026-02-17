import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SurveyTableActual extends StatefulWidget {
  const SurveyTableActual({super.key});

  @override
  State<SurveyTableActual> createState() => _SurveyActualTablePageState();
}

class _SurveyActualTablePageState extends State<SurveyTableActual> {
  static const double rowH = 36; // Slightly increased height

  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalController = ScrollController();

  final List<double> colW = [
    70,  // No
    150, // Date
    100,  // Rpt
    100,  // MD
    100,  // TVD Input
    100,  // TVD Calc
    100,  // Inc
    100,  // Azi
    100,  // Vsec
    100,  // N+/S
    100,  // E+/W
    100,  // Dogleg
  ];

  double get tableWidth => colW.reduce((a, b) => a + b);

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    super.dispose();
  }

  Widget cell(
    double w, {
    String? text,
    bool bold = false,
    bool editable = false,
    bool isHeader = false,
    bool isSubHeader = false,
    TextAlign align = TextAlign.center,
  }) {
    return Container(
      width: w,
      height: rowH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
        color: isHeader
            ? AppTheme.primaryColor
            : isSubHeader
                ? AppTheme.primaryColor.withOpacity(0.1)
                : editable
                    ? Colors.white
                    : (int.tryParse(text ?? '0') != null && (int.parse(text!) % 2 == 0))
                        ? Colors.white
                        : Colors.grey.shade50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: editable
          ? TextField(
              textAlign: align,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            )
          : Text(
              text ?? '',
              textAlign: align,
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

  // ================= HEADER =================
  Widget header() {
    return Column(
      children: [
        // Main Header Row
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            cell(colW[0], text: 'No', isHeader: true),
            cell(colW[1], text: 'Date', isHeader: true),
            cell(colW[2], text: 'Rpt #', isHeader: true),
            cell(colW[3], text: 'MD (ft)', isHeader: true),
            cell(colW[4] + colW[5], text: 'TVD (ft)', isHeader: true),
            cell(colW[6], text: 'Inc (°)', isHeader: true),
            cell(colW[7], text: 'Azi (°)', isHeader: true),
            cell(colW[8], text: 'Vsec (ft)', isHeader: true),
            cell(colW[9], text: 'N+/S (ft)', isHeader: true),
            cell(colW[10], text: 'E+/W (ft)', isHeader: true),
            cell(colW[11], text: 'Dogleg (°/100ft)', isHeader: true),
          ]),
        ),
        // Sub-header Row
        Row(children: [
          cell(colW[0], isSubHeader: true),
          cell(colW[1], isSubHeader: true),
          cell(colW[2], isSubHeader: true),
          cell(colW[3], isSubHeader: true),
          cell(colW[4], text: 'Input', isSubHeader: true),
          cell(colW[5], text: 'Calculated', isSubHeader: true),
          cell(colW[6], isSubHeader: true),
          cell(colW[7], isSubHeader: true),
          cell(colW[8], isSubHeader: true),
          cell(colW[9], isSubHeader: true),
          cell(colW[10], isSubHeader: true),
          cell(colW[11], isSubHeader: true),
        ]),
      ],
    );
  }

  // ================= DATA ROW =================
  Widget row(int i) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(children: [
        cell(colW[0], text: '$i', bold: true),
        cell(colW[1], editable: true),
        cell(colW[2], editable: true),
        cell(colW[3], editable: true),
        cell(colW[4], editable: true),
        cell(colW[5], editable: true),
        cell(colW[6], editable: true),
        cell(colW[7], editable: true),
        cell(colW[8], editable: true),
        cell(colW[9], editable: true),
        cell(colW[10], editable: true),
        cell(colW[11], editable: true),
      ]),
    );
  }

  // ================= SUMMARY FOOTER =================
  Widget summaryFooter() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: SingleChildScrollView(
        controller: horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Row(
            children: [
              Container(
                width: colW[0],
                height: rowH,
                alignment: Alignment.center,
                child: const Icon(Icons.summarize, size: 18, color: Colors.grey),
              ),
              Container(
                width: colW[1],
                height: rowH,
                alignment: Alignment.center,
                child: Text(
                  'Total Records: 50',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Container(
                width: colW[2],
                height: rowH,
                alignment: Alignment.center,
                child: const Icon(Icons.edit, size: 16, color: Colors.grey),
              ),
              Container(
                width: colW[3],
                height: rowH,
                alignment: Alignment.center,
                child: Text(
                  'Edit Mode',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              Container(
                width: colW[4],
                height: rowH,
                alignment: Alignment.center,
                child: const Icon(Icons.save, size: 16, color: Colors.grey),
              ),
              Container(
                width: colW[5] + colW[6] + colW[7] + colW[8] + colW[9] + colW[10] + colW[11],
                height: rowH,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Survey Data Table',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TABLE HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
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
                    'Survey Data Table - Actual Measurements',
                    style: AppTheme.titleMedium.copyWith(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.table_chart, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text(
                              '12 Columns × 50 Rows',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // MAIN TABLE
            Expanded(
              child: Container(
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
                  children: [
                    // TABLE CONTENT
                    Expanded(
                      child: Scrollbar(
                        controller: horizontalController,
                        thumbVisibility: true,
                        interactive: true,
                        thickness: 8,
                        radius: const Radius.circular(4),
                        child: SingleChildScrollView(
                          controller: horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Scrollbar(
                              controller: verticalController,
                              thumbVisibility: true,
                              interactive: true,
                              thickness: 8,
                              radius: const Radius.circular(4),
                              child: ListView(
                                controller: verticalController,
                                shrinkWrap: true,
                                children: [
                                  header(),
                                  ...List.generate(50, (index) => row(index + 1)),
                                  const SizedBox(height: 1), // Spacing before footer
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // SUMMARY FOOTER
                    summaryFooter(),
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