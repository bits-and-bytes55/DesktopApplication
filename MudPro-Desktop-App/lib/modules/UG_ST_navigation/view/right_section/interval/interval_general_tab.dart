import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class IntervalGeneralTab extends StatelessWidget {
  const IntervalGeneralTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c    = Get.find<IntervalController>();
    final dashCtrl = Get.find<DashboardController>();

    return Obx(() {
      if (c.isLoading.value) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }

      final iv = c.selected.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT COLUMN ──────────────────────────────────────
            Expanded(
              child: Column(children: [
                _tableCard(c, dashCtrl, iv),
                const SizedBox(height: 10),
                _textCard("Interval Summary",    c.intervalSummaryCtrl, dashCtrl),
                const SizedBox(height: 10),
                _textCard("Solid Control",       c.solidControlCtrl, dashCtrl),
              ]),
            ),
            const SizedBox(width: 10),
            // ── RIGHT COLUMN ─────────────────────────────────────
            Expanded(
              child: Column(children: [
                _textCard("Interval Conclusion and Recommendations",
                    c.intervalConclusionCtrl, dashCtrl),
                const SizedBox(height: 10),
                _textCard("Sweeps",      c.sweepsCtrl,      dashCtrl),
                const SizedBox(height: 10),
                _textCard("Lab Testing", c.labTestingCtrl,  dashCtrl),
              ]),
            ),
          ],
        ),
      );
    });
  }

  // ── TABLE CARD (heading = selected interval name) ────────────────
  Widget _tableCard(
    IntervalController c,
    DashboardController dashCtrl,
    IntervalItem? iv,
  ) {
    final heading = iv?.name ?? "—";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          height: 34,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            const Icon(Icons.table_chart, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                heading,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Save button
            Obx(() => c.isSaving.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                : InkWell(
                    onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : c.saveGeneralData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: dashCtrl.isLocked.value ? Colors.grey : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("Save",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  )),
          ]),
        ),

        // Rows
        Table(
          border: TableBorder.all(color: Colors.grey.shade200, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(140),
            1: FlexColumnWidth(),
            2: FixedColumnWidth(48),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _tRow("Formation",      c.formationCtrl,   "",      dashCtrl),
            _tRow("Bit Size",       c.bitSizeCtrl,     "(in)",  dashCtrl),
            _tRow("Casing",         c.casingCtrl,      "(in)",  dashCtrl),
            _tRow("Interval FIT",   c.intervalFITCtrl, "(ppg)", dashCtrl),
            _tRow("Mud Description",c.mudDescCtrl,     "",      dashCtrl),
            _tRow("Mud Type",       c.mudTypeCtrl,     "",      dashCtrl),
          ],
        ),
      ]),
    );
  }

  // ── TABLE ROW ────────────────────────────────────────────────────
  TableRow _tRow(
    String label,
    TextEditingController ctrl,
    String suffix,
    DashboardController dashCtrl,
  ) {
    return TableRow(
      decoration: BoxDecoration(
        color: label.hashCode.isEven ? Colors.white : const Color(0xffF8FAFC),
      ),
      children: [
        // Label
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xff374151))),
        ),
        // Input
        Obx(() => Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: dashCtrl.isLocked.value
              ? GestureDetector(
                  onTap: () => dashCtrl.showLockedPopup(),
                  behavior: HitTestBehavior.opaque,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(ctrl.text,
                        style: const TextStyle(fontSize: 11, color: Color(0xff6B7280))),
                  ),
                )
              : TextField(
                  controller: ctrl,
                  style: const TextStyle(fontSize: 11, color: Color(0xff111827)),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
        )),
        // Suffix
        Container(
          height: 30,
          alignment: Alignment.center,
          child: Text(suffix,
              style: const TextStyle(fontSize: 10, color: Color(0xff9CA3AF))),
        ),
      ],
    );
  }

  // ── TEXT AREA CARD ───────────────────────────────────────────────
  Widget _textCard(
    String title,
    TextEditingController ctrl,
    DashboardController dashCtrl,
  ) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(children: [
            const Icon(Icons.notes, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
        // Body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Obx(() => dashCtrl.isLocked.value
                ? GestureDetector(
                    onTap: () => dashCtrl.showLockedPopup(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ctrl.text.isEmpty ? "—" : ctrl.text,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xff6B7280)),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: ctrl,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xff111827)),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(8),
                        hintText: 'Enter $title...',
                        hintStyle: const TextStyle(
                            fontSize: 11, color: Color(0xffD1D5DB)),
                      ),
                    ),
                  )),
          ),
        ),
      ]),
    );
  }
}