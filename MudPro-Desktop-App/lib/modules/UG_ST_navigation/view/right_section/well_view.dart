import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/well_general_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class WellView extends StatelessWidget {
  WellView({super.key});
  final c = Get.find<UgStController>();
  final wellGenCtrl = Get.isRegistered<WellGeneralController>()
      ? Get.find<WellGeneralController>()
      : Get.put(WellGeneralController());
  final dashCtrl = Get.find<DashboardController>();
  final _tableScrollCtrl = ScrollController();
  final _memoScrollCtrl  = ScrollController();

  static const double rowH = 28; // Increased height for better visibility
  static const double tableWidth = 600; // Decreased width

  Widget _row(String label, RxString value) {
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
                fontSize: 10.5, // Slightly smaller font to fit vertically
              ),
              overflow: TextOverflow.visible,
            ),
          ),

          // ---------- VALUE ----------
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Obx(() {
                final isLocked = dashCtrl.isLocked.value;
                return isLocked
                    ? GestureDetector(
                        onTap: () => dashCtrl.showLockedPopup(),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          value.value,
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: 10.5,
                            color: value.value.isEmpty 
                                ? Colors.grey.shade400 
                                : AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      )
                    : TextFormField(
                        controller: TextEditingController(text: value.value)
                          ..selection = TextSelection.fromPosition(
                              TextPosition(offset: value.value.length)),
                        onChanged: (v) => value.value = v,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 10.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.headerGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.oil_barrel, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Well Information",
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Obx(() => Text(
                              wellGenCtrl.wellNameNo.value,
                              style: AppTheme.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            )),
                      ),
                    ],
                  ),
                ),

                // TABLE CONTENT (Scrollable)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 280, // Slightly increased due to taller rows
                  ),
                  child: Scrollbar(
                    controller: _tableScrollCtrl,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _tableScrollCtrl,
                      child: Column(
                        children: [
                          _row("Well Name/No.", wellGenCtrl.wellNameNo),
                          _row("API Well No.", wellGenCtrl.apiWellNo),
                          _row("Spud Date", wellGenCtrl.spudDate),
                          _row("Section/Township/Range", wellGenCtrl.sectionTownshipRange),
                          _row("Longitude", wellGenCtrl.longitude),
                          _row("Latitude", wellGenCtrl.latitude),
                          _row("KOP", wellGenCtrl.kop),
                          _row("LP", wellGenCtrl.lp),
                          _row("Bulk Tank Setup Fee", wellGenCtrl.bulkTankSetupFee),
                          _row("Additional Field 1", "".obs),
                          _row("Additional Field 2", "".obs),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ================= MEMO SECTION =================
          Container(
            constraints: const BoxConstraints(
              minHeight: 100,
              maxHeight: 200, // Adjusted height
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Memo",
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // MEMO CONTENT
                SizedBox(
                  height: 150,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Obx(() => dashCtrl.isLocked.value
                        ? GestureDetector(
                            onTap: () => dashCtrl.showLockedPopup(),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: SingleChildScrollView(
                                controller: _memoScrollCtrl,
                                child: Text(
                                  wellGenCtrl.memo.value.isEmpty 
                                      ? "No memo available." 
                                      : wellGenCtrl.memo.value,
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: wellGenCtrl.memo.value.isEmpty ? Colors.grey.shade500 : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Scrollbar(
                              controller: _memoScrollCtrl,
                              child: TextFormField(
                                controller: TextEditingController(text: wellGenCtrl.memo.value)
                                  ..selection = TextSelection.fromPosition(
                                      TextPosition(offset: wellGenCtrl.memo.value.length)),
                                maxLines: null,
                                onChanged: (v) => wellGenCtrl.memo.value = v,
                                style: AppTheme.bodySmall.copyWith(fontSize: 11),
                                scrollController: _memoScrollCtrl,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(8),
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
          const SizedBox(height: 8),
          Container(
            width: tableWidth,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppTheme.infoColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Well information is used for reporting and identification purposes.",
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
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
