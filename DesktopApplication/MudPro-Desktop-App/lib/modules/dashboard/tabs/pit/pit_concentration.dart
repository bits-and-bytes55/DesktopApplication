import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/pit_concentration_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PitConcentrationPage extends StatelessWidget {
  PitConcentrationPage({super.key});

  final PitConcentrationController controller =
      Get.put(PitConcentrationController());
  final dashboard = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 1000,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _systemDropdown(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _table(),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                "Pit Concentration Management",
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 24),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  // ================= DROPDOWN =================
  Widget _systemDropdown() {
    return Obx(() => Container(
      width: 300,
      child: DropdownButtonFormField<String>(
        value: controller.selectedSystem.value,
        items: controller.systems
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: AppTheme.caption),
              ),
            )
            .toList(),
        onChanged: (v) => controller.selectedSystem.value = v!,
        decoration: InputDecoration(
          isDense: true,
          labelText: "Select System",
          labelStyle: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
      ),
    ));
  }

  // ================= TABLE =================
  Widget _table() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Obx(() {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Table Header
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      _tableHeaderCell("Product", flex: 2),
                      _tableHeaderCell("Unit", flex: 1),
                      _tableHeaderCell("Start Conc.", flex: 2),
                      _tableHeaderCell("End Conc.", flex: 2),
                    ],
                  ),
                ),

                // Table Rows
                ...controller.products.map((row) {
                  return Container(
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Row(
                      children: [
                        _tableCell(row["product"]!.value, flex: 2),
                        _tableCell(row["unit"]!.value, flex: 1),
                        _editableTableCell(row["start"]!, flex: 2),
                        _editableTableCell(row["end"]!, flex: 2),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _tableHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTheme.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _tableCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTheme.caption.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _editableTableCell(RxString value, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Obx(() {
          if (dashboard.isLocked.value) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                value.value.isEmpty ? "-" : value.value,
                style: AppTheme.caption.copyWith(
                  color: value.value.isEmpty 
                    ? Colors.grey.shade400 
                    : AppTheme.textPrimary,
                  fontStyle: value.value.isEmpty 
                    ? FontStyle.italic 
                    : FontStyle.normal,
                ),
              ),
            );
          }
          return Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: TextEditingController(text: value.value),
              onChanged: (v) => value.value = v,
              textAlign: TextAlign.left,
              style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                hintText: "Enter value",
                hintStyle: AppTheme.caption.copyWith(color: Colors.grey.shade400),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ================= FOOTER =================
  Widget _footer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            dashboard.isLocked.value ? "🔒 Data is locked" : "🔓 Data is editable",
            style: AppTheme.caption.copyWith(
              color: dashboard.isLocked.value 
                ? Colors.grey.shade600 
                : AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(color: AppTheme.textSecondary),
            ),
            child: Text(
              "Cancel",
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              // Save logic here
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              "Save Changes",
              style: AppTheme.caption.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}