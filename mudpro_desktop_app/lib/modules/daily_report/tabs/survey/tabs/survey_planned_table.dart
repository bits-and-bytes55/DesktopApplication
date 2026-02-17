import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SurveyTablePlanned extends StatelessWidget {
  const SurveyTablePlanned({super.key});

  static const double rowH = 34;

  Widget cell(
    String t,
    double w, {
    bool bold = false,
    bool isHeader = false,
    bool editable = true,
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
            : editable
                ? Colors.white
                : Colors.grey.shade50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: TextEditingController(text: t),
        enabled: editable,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: isHeader ? Colors.white : AppTheme.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  'Survey Data Table - Planned Measurements',
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.table_chart,
                          size: 14, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text(
                        '9 Columns × 50 Rows',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
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
              child: Scrollbar(
                thumbVisibility: true,
                interactive: true,
                thickness: 8,
                radius: const Radius.circular(4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 900,
                    child: Column(
                      children: [
                        // HEADER ROW
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            cell('No', 60, bold: true, isHeader: true),
                            cell('MD (ft)', 90, bold: true, isHeader: true),
                            cell('Inc (°)', 90, bold: true, isHeader: true),
                            cell('Azi (°)', 90, bold: true, isHeader: true),
                            cell('TVD (ft)', 90, bold: true, isHeader: true),
                            cell('Vsec', 90, bold: true, isHeader: true),
                            cell('N+/S-', 90, bold: true, isHeader: true),
                            cell('E+/W-', 90, bold: true, isHeader: true),
                            cell('Dogleg (11ft)', 90, bold: true, isHeader: true),
                          ]),
                        ),
                        
                        // DATA ROWS
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            interactive: true,
                            thickness: 8,
                            radius: const Radius.circular(4),
                            child: ListView.builder(
                              itemCount: 50,
                              itemBuilder: (_, i) => Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(children: [
                                  cell('${i + 1}', 60, editable: false),
                                  cell('', 90),
                                  cell('', 90),
                                  cell('', 90),
                                  cell('', 90),
                                  cell('', 90),
                                  cell('', 90),
                                  cell('', 90),
                                  cell('', 90),
                                ]),
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
          ),

          // TABLE FOOTER
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.table_rows,
                          size: 16, color: Colors.blueGrey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Planned Survey Data',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Page 1/1',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Editable Table',
                        style: TextStyle(
                          fontSize: 10,
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
    );
  }
}