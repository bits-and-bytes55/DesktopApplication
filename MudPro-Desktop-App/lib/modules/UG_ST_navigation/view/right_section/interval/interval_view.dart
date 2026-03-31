import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_left_pannel.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_general_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_mud_plan_tab.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class IntervalView extends StatefulWidget {
  const IntervalView({super.key});

  @override
  State<IntervalView> createState() => _IntervalViewState();
}

class _IntervalViewState extends State<IntervalView>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  late IntervalController _ivCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialise (or find) the IntervalController and load data
    _ivCtrl = Get.put(IntervalController());
    final ugSt = Get.find<UgStController>();
    // Pass the wellId from your UgStController (adjust field name as needed)
    _ivCtrl.init(ugSt.selectedWellId.value ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ── MAIN AREA ──────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT panel
                    const IntervalLeftPanel(),
                    const SizedBox(width: 10),
                    // RIGHT — tabs
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(children: [
                          // Tab bar
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: AppTheme.primaryColor,
                              unselectedLabelColor: AppTheme.textSecondary,
                              indicatorColor: AppTheme.primaryColor,
                              indicatorWeight: 2.5,
                              indicatorSize: TabBarIndicatorSize.label,
                              labelStyle: AppTheme.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600),
                              unselectedLabelStyle: AppTheme.bodySmall,
                              tabs: const [
                                Tab(text: "General"),
                                Tab(text: "Mud Plan"),
                              ],
                            ),
                          ),
                          // Tab content
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: TabBarView(
                                controller: _tabController,
                                children: const [
                                  IntervalGeneralTab(),
                                  IntervalMudPlanTab(),
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── BOTTOM PANEL ───────────────────────────────────────
          _bottomPanel(),
        ],
      ),
    );
  }

  Widget _bottomPanel() {
    final c    = Get.find<IntervalController>();
    final ugSt = Get.find<UgStController>();

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          Icon(Icons.summarize_outlined, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "End of Interval Conclusions and Recommendations",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  "Add final observations and recommendations for this interval",
                  style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Obx(() => ElevatedButton(
            onPressed: (ugSt.isLocked.value || c.isSaving.value)
                ? null
                : c.saveGeneralData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
            child: c.isSaving.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                : const Text("Save Conclusions"),
          )),
        ]),
      ),
    );
  }
}