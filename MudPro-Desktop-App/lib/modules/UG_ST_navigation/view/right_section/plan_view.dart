import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';

class PlanPageView extends StatelessWidget {
  const PlanPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final UgStController controller = Get.find<UgStController>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ================= TOP SUMMARY + QUICK FILL =================
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryTable(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _quickFillButton(),
                    ),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryTable(),
                    const Spacer(),
                    _quickFillButton(),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 16),

          // ================= BIG PLAN TABLE =================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // TABLE HEADER
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.headerGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.timeline, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "Drilling Plan Analysis",
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "3 intervals",
                            style: AppTheme.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TABLE CONTENT
                  Expanded(
                    child: _bigPlanTable(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SUMMARY TABLE =================
  Widget _summaryTable() {
    final UgStController controller = Get.find<UgStController>();
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
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
          // HEADER
          Container(
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.summarize, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  "Plan Summary",
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // TABLE
          Obx(() => Table(
            border: TableBorder.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
            },
            children: [
              _summaryHeaderRow(),
              for (int i = 0; i < controller.summaryData.length; i++)
                _summaryDataRow(
                  controller.summaryData[i]['type']!,
                  controller.summaryData[i]['amount']!,
                  controller.summaryData[i]['unit']!,
                  i,
                ),
            ],
          )),
        ],
      ),
    );
  }

  TableRow _summaryHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      children: [
        _headerCell("Type"),
        _headerCell("Amount"),
        _headerCell("Unit"),
      ],
    );
  }

  TableRow _summaryDataRow(String label, String value, String unit, int index) {
    return TableRow(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : AppTheme.cardColor,
      ),
      children: [
        _summaryCell(label, isLabel: true),
        _summaryCell(value, isLabel: false, index: index, key: 'amount'),
        _summaryCell(unit, isLabel: false, index: index, key: 'unit'),
      ],
    );
  }

  Widget _summaryCell(String text, {bool isLabel = false, int? index, String? key}) {
    final UgStController controller = Get.find<UgStController>();
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Obx(() => controller.isLocked.value
          ? Text(
              text,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: isLabel ? FontWeight.w600 : FontWeight.normal,
                color: isLabel ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
              textAlign: isLabel ? TextAlign.left : TextAlign.center,
            )
          : TextFormField(
              initialValue: text,
              onChanged: (value) {
                if (index != null && key != null) {
                  controller.updateSummaryData(index, key, value);
                }
              },
              style: AppTheme.bodySmall.copyWith(
                fontWeight: isLabel ? FontWeight.w600 : FontWeight.normal,
                color: isLabel ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
              textAlign: isLabel ? TextAlign.left : TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )),
    );
  }

  Widget _headerCell(String text) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ================= QUICK FILL =================
  Widget _quickFillButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
        label: Text(
          "Quick Fill",
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // ================= BIG TABLE =================
  Widget _bigPlanTable() {
    final UgStController controller = Get.find<UgStController>();
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Obx(() => Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            columnWidths: const {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(90),
              2: FixedColumnWidth(70),
              3: FixedColumnWidth(100),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(80),
              6: FixedColumnWidth(90),
              7: FixedColumnWidth(90),
              8: FixedColumnWidth(80),
              9: FixedColumnWidth(90),
              10: FixedColumnWidth(90),
              11: FixedColumnWidth(120),
              12: FixedColumnWidth(120),
              13: FixedColumnWidth(130),
              14: FixedColumnWidth(130),
              15: FixedColumnWidth(70),
            },
            children: [
              _mainHeaderRow(),
              _subHeaderRow(),
              for (int i = 0; i < controller.planData.length; i++)
                _dataRow(controller.planData[i], i),
            ],
          )),
        ),
      ),
    );
  }

  // ================= HEADERS =================
  TableRow _mainHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      children: [
        _tableHeaderCell("#"),
        _tableHeaderCell("MD\n(m)"),
        _tableHeaderCell("Days"),
        _tableHeaderCell("Cost\n(\$)"),
        _tableHeaderCell("MW\n(ppg)"),
        _tableHeaderCell(""),
        _tableHeaderCell("Visc\n(sec/qt)"),
        _tableHeaderCell(""),
        _tableHeaderCell("PV\n(cp)"),
        _tableHeaderCell("YP\n(lb/100ft²)"),
        _tableHeaderCell(""),
        _tableHeaderCell("API Filtrate\n(mL/30min)"),
        _tableHeaderCell(""),
        _tableHeaderCell("HTHP Filtrate\n(mL/30min)"),
        _tableHeaderCell(""),
        _tableHeaderCell("pH"),
      ],
    );
  }

  TableRow _subHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
      ),
      children: [
        _subHeaderCell("Int"),
        _subHeaderCell("Depth"),
        _subHeaderCell("Duration"),
        _subHeaderCell("Cumulative"),
        _subHeaderCell("L"),
        _subHeaderCell("H"),
        _subHeaderCell("L"),
        _subHeaderCell("H"),
        _subHeaderCell("Plastic"),
        _subHeaderCell("L"),
        _subHeaderCell("H"),
        _subHeaderCell("L"),
        _subHeaderCell("H"),
        _subHeaderCell("L"),
        _subHeaderCell("H"),
        _subHeaderCell("Value"),
      ],
    );
  }

  Widget _tableHeaderCell(String text) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _subHeaderCell(String text) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTheme.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ================= DATA ROW =================
  TableRow _dataRow(List<String> values, int rowIndex) {
    final UgStController controller = Get.find<UgStController>();
    return TableRow(
      decoration: BoxDecoration(
        color: rowIndex.isEven ? Colors.white : AppTheme.cardColor,
      ),
      children: values.asMap().entries.map((entry) {
        int colIndex = entry.key;
        String v = entry.value;
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: Obx(() => controller.isLocked.value
              ? Text(
                  v,
                  style: AppTheme.caption.copyWith(
                    color: v.isEmpty ? Colors.grey.shade400 : AppTheme.textPrimary,
                    fontWeight: v.isEmpty ? FontWeight.normal : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                )
              : TextFormField(
                  initialValue: v,
                  onChanged: (value) {
                    controller.updatePlanData(rowIndex, colIndex, value);
                  },
                  style: AppTheme.caption.copyWith(
                    color: v.isEmpty ? Colors.grey.shade400 : AppTheme.textPrimary,
                    fontWeight: v.isEmpty ? FontWeight.normal : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                )),
        );
      }).toList(),
    );
  }
}