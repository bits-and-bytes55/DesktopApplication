import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class WellView extends StatelessWidget {
  WellView({super.key});
  final c = Get.find<UgStController>();

  static const double rowH = 32;
  static const double tableWidth = 700;

  Widget _row(String label, String value) {
    return Container(
      height: rowH,
      decoration: BoxDecoration(
        color: label.hashCode.isEven ? Colors.white : AppTheme.cardColor,
        border:  Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // ---------- LABEL ----------
          Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // ---------- VALUE ----------
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Obx(() => c.isLocked.value
                  ? Text(
                      value,
                      style: AppTheme.bodySmall.copyWith(
                        color: value.isEmpty 
                            ? Colors.grey.shade400 
                            : AppTheme.textPrimary,
                      ),
                    )
                  : TextFormField(
                      initialValue: value,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Enter ${label.toLowerCase()}',
                        hintStyle: AppTheme.caption.copyWith(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    )),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ================= WELL TABLE =================
            Container(
              width: tableWidth,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.headerGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.oil_barrel, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "Well Information",
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
                            "UG-0293 ST",
                            style: AppTheme.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // TABLE CONTENT (Scrollable)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 350, // Fixed height for table with scroll
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _row("Well Name/No.", "UG-0293 ST"),
                            _row("API Well No.", ""),
                            _row("Spud Date", "11/26/2025"),
                            _row("Section/Township/Range", "UMM Gudair (UG)"),
                            _row("Longitude", "3197265.560"),
                            _row("Latitude", "768061.45"),
                            _row("KOP", "2377.44 (m)"),
                            _row("LP", ""),
                            _row("Bulk Tank Setup Fee", "(\$)"),
                            // Add more rows if needed without causing overflow
                            _row("Additional Field 1", ""),
                            _row("Additional Field 2", ""),
                            _row("Additional Field 3", ""),
                            _row("Additional Field 4", ""),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= MEMO SECTION =================
            Container(
              width: tableWidth, // Same width as table
              constraints: const BoxConstraints(
                minHeight: 150,
                maxHeight: 250, // Reduced height
              ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MEMO HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.secondaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notes, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "Memo",
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // MEMO CONTENT (Scrollable)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Obx(() => c.isLocked.value
                          ? Container(
                              width: double.infinity,
                              height: 500,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  "No memo entered. When unlocked, you can add notes about the well configuration, special instructions, or any additional information relevant to this project.",
                                  style: AppTheme.caption.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: TextFormField(
                                  maxLines: null,
                                  expands: true,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(12),
                                    hintText: 'Enter memo notes here...\n\n• Well configuration notes\n• Special instructions\n• Project requirements\n• Safety considerations\n• Additional information',
                                    hintStyle: AppTheme.caption.copyWith(
                                      color: Colors.grey.shade400,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            )),
                    ),
                  ),
                ],
              ),
            ),

            // ================= FOOTER NOTE =================
            const SizedBox(height: 16),
            Container(
              width: tableWidth,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.infoColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Well information is used for reporting and identification purposes. Please ensure all fields are accurate.",
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
