import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_left_pannel.dart';
import 'interval_general_tab.dart';
import 'interval_mud_plan_tab.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class IntervalView extends StatefulWidget {
  const IntervalView({super.key});

  @override
  State<IntervalView> createState() => _IntervalViewState();
}

class _IntervalViewState extends State<IntervalView>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ================= MAIN AREA =================
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
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT FIXED PANEL
                    const IntervalLeftPanel(),

                    const SizedBox(width: 12),

                    // RIGHT SWITCHABLE CONTENT
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            // TAB BAR
                            Container(
                              height: 44,
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
                                indicatorWeight: 3,
                                indicatorSize: TabBarIndicatorSize.label,
                                labelStyle: AppTheme.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                unselectedLabelStyle: AppTheme.bodySmall,
                                tabs: const [
                                  Tab(
                                    text: "General",
                                    
                                  ),
                                  Tab(
                                    text: "Mud Plan",
                                   
                                  ),
                                ],
                              ),
                            ),

                            // TAB CONTENT
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ================= BOTTOM PANEL =================
          _bottomPanel(),
        ],
      ),
    );
  }

  Widget _bottomPanel() {
    return Container(
      height: 56,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.summarize, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "End of Interval Conclusions and Recommendations",
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Add final observations and recommendations for this interval",
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              final c = Get.find<UgStController>();
              return ElevatedButton(
                onPressed: c.isLocked.value ? null : () {
                  // Save conclusions
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  "Save Conclusions",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}