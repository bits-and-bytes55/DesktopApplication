import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';

class EditableTable extends StatelessWidget {
  final c = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 16,
                headingRowHeight: 48,
                dataRowHeight: 44,
                headingTextStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.3,
                ),
                dataTextStyle: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
                headingRowColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    return AppTheme.cardColor;
                  },
                ),
                dataRowColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    return states.contains(MaterialState.selected)
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.white;
                  },
                ),
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                columns: [
                  _buildDataColumn("Description", Icons.description),
                  _buildDataColumn("MD", Icons.straighten),
                  _buildDataColumn("TVD", Icons.vertical_align_bottom),
                  _buildDataColumn("Inc", Icons.trending_up),
                ],
                rows: List.generate(10, (index) {
                  return DataRow(
                    cells: [
                      _buildDataCell(index < 6 ? "Casing ${index + 1}" : "", c.isLocked.value),
                      _buildDataCell(index < 6 ? "9055" : "", c.isLocked.value),
                      _buildDataCell(index < 6 ? "8630" : "", c.isLocked.value),
                      _buildDataCell(index < 6 ? "73.45" : "", c.isLocked.value),
                    ],
                  );
                }),
              ),
            ),
          ),
        ));
  }

  DataColumn _buildDataColumn(String label, IconData icon) {
    return DataColumn(
      label: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataCell _buildDataCell(String value, bool locked) {
    return DataCell(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: locked
            ? Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              )
            : Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextFormField(
                  initialValue: value,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}