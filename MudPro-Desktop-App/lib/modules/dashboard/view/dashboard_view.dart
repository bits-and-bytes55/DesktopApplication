import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pit/pit_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pump/pump_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/remarks_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/help_secondary_tabbar.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/report_secondary_tabbar.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/utility_secondary_tabbar.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/editable_table.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/left_report_list.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/lock_bar.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/primary_tabbar.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/home_secondary_tabbar.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/well_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/mud_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/safety_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/jsa_tab_content.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/right_pannel_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/pump_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/pit_view.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/pannel_switcher.dart';
import '../controller/dashboard_controller.dart';
import '../controller/operation_controller.dart';
import '../widgets/top_bar.dart';
import '../widgets/section_navbar.dart';

// ==================== MAIN VIEW ====================
class DashboardView extends StatelessWidget {
  DashboardView({super.key});

  final c = Get.put(DashboardController());
  final ugStC = Get.put(UgStController());
  final ugC = Get.put(UgController());
  final operationC = Get.put(OperationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffF7FAFC), Color(0xffEDF2F7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Top Header with shadow
            Material(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              child: TopHeaderBar(),
            ),

            // Primary Tab Bar
            Material(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.05),
              child: PrimaryTabBar(),
            ),

            // Secondary Tab Bar
            /// SECONDARY TAB BAR (dynamic)
Obx(() {
  switch (c.activePrimaryTab.value) {
    case 0:
      return HomeSecondaryTabbar();
    case 1:
      return ReportSecondaryTabbar();
    case 2:
      return UtilitySecondaryTabbar(); // future
    case 3:
      return HelpSecondaryTabbar(); // future
    default:
      return const SizedBox();
  }
}),


            // Main Content Area
          Expanded(
  child: Stack(
    children: [
      /// MAIN DASHBOARD CONTENT (unchanged)
      _buildMainDashboardContent(),

      /// OVERLAY PAGE
      Obx(() {
        final page = c.overlayPage.value;
        if (page == null) return const SizedBox();

        return Positioned.fill(
          child: Material(
            color: Colors.white,
            elevation: 12,
            child: Column(
              children: [
                /// Top bar with back/close
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    border: Border(
                      bottom:
                          BorderSide(color: Colors.black.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: c.closeOverlay,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: c.closeOverlay,
                      ),
                    ],
                  ),
                ),

                /// PAGE CONTENT
                Expanded(child: page),
              ],
            ),
          ),
        );
      }),
    ],
  ),
),

                ],
              ),
            )



        );



  }

  Widget _buildMainDashboardContent() {
  return Row(
    children: [
      // Left Sidebar
      Material(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        child: LeftReportTree(),
      ),

      // Main Content
      Expanded(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xffFAFBFC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Obx(() {
            if (c.selectedNodeId.value == 'UG') {
              return _buildAnimatedTransition(UGRightPanel());
            } else if (c.selectedNodeId.value == 'UG-0293-ST') {
              return _buildAnimatedTransition(RightPanel());
            } else {
              return _buildAnimatedTransition(
                Column(
                  children: [
                    Material(
                      elevation: 1,
                      shadowColor: Colors.black.withOpacity(0.03),
                      child: SectionNavBar(),
                    ),
                    Material(
                      elevation: 1,
                      shadowColor: Colors.black.withOpacity(0.02),
                      child: LockBar(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Obx(() {
                          switch (c.activeSectionTab.value) {
                            case 0:
                              return WellTabContent();
                            case 1:
                              return MudView();
                            case 2:
                              return PumpPage();
                            case 3:
                              return OperationPage();
                            case 4:
                              return PitPage();
                            case 5:
                              return SafetyTabContent();
                            case 6:
                              return RemarksView();
                            case 7:
                              return JSATabContent();
                            default:
                              return WellTabContent();
                          }
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
        ),
      ),
    ],
  );
}


  Widget _buildAnimatedTransition(Widget child) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
