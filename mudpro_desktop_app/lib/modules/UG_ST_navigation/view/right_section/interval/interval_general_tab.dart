import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class IntervalGeneralTab extends StatelessWidget {
  const IntervalGeneralTab({super.key});

  static const double boxHeight = 140;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<UgStController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN
              Expanded(
                child: Column(
                  children: [
                    _tableBox(c),
                    const SizedBox(height: 12),
                    _textBox("Interval Summary", c),
                    const SizedBox(height: 12),
                    _textBox("Solid Control", c),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // RIGHT COLUMN
              Expanded(
                child: Column(
                  children: [
                    _textBox("Interval Conclusion and Recommendations", c),
                    const SizedBox(height: 12),
                    _textBox("Sweeps", c),
                    const SizedBox(height: 12),
                    _textBox("Lab Testing", c),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= TABLE BOX =================
  Widget _tableBox(UgStController c) {
    return Container(
      height: boxHeight,
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
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.table_chart, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "New Interval (1)",
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // TABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
                columnWidths: const {
                  0: FixedColumnWidth(160),
                  1: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _tableRow("Formation", c),
                  _tableRow("Bit Size", c, suffix: "(in)"),
                  _tableRow("Casing", c, suffix: "(in)"),
                  _tableRow("Interval FIT", c, suffix: "(ppg)"),
                  _tableRow("Mud Description", c),
                  _tableRow("Mud Type", c),
                  _tableRow("Additional Field 1", c),
                  _tableRow("Additional Field 2", c),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TEXT BOX =================
  Widget _textBox(String title, UgStController c) {
    return Container(
      height: boxHeight,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.description, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Obx(
                () => c.isLocked.value
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            "Click unlock to edit content",
                            style: AppTheme.caption.copyWith(
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: TextFormField(
                          maxLines: null,
                          expands: true,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            hintText: 'Enter $title...',
                            hintStyle: AppTheme.caption.copyWith(
                              color: Colors.grey.shade400,
                            ),
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

  // ================= TABLE ROW =================
  TableRow _tableRow(
    String label,
    UgStController c, {
    String suffix = "",
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: label.hashCode.isEven ? Colors.white : AppTheme.cardColor,
      ),
      children: [
        _cell(label, isLabel: true),
        Obx(
          () => c.isLocked.value
              ? _cell(suffix, isLabel: false)
              : _editableCell(suffix),
        ),
      ],
    );
  }

  Widget _cell(String text, {required bool isLabel}) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontWeight: isLabel ? FontWeight.w600 : FontWeight.normal,
          color: isLabel ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _editableCell(String hint) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: TextFormField(
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
        ),
      ),
    );
  }
}