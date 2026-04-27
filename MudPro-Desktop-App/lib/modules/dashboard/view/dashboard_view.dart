import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pit/pit_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pump_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/remarks_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/help_secondary_tabbar.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/report_secondary_tabbar.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/utility_secondary_tabbar.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/left_report_list.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/primary_tabbar.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/home_secondary_tabbar.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/well_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/mud/mud_tab_content.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_tab_content.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/right_pannel_view.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/pannel_switcher.dart';
import '../controller/dashboard_controller.dart';
import '../controller/operation_controller.dart';
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
        color: Colors.white,
        child: Column(
          children: [
            // // Top Header with shadow
            // Material(
            //   elevation: 4,
            //   shadowColor: Colors.black.withOpacity(0.1),
            //   child: TopHeaderBar(),
            // ),

            // Primary Tab Bar
            PrimaryTabBar(),

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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
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
      ),
    );
  }

  Widget _buildMainDashboardContent() {
    return Row(
      children: [
        // Left Sidebar
        Material(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          child: LeftReportTree(),
        ),

        // Main Content
        Expanded(
          child: Container(
            color: Colors.white,
            child: Obx(() {
              final selectedNode = c.selectedNodeId.value;
              if (selectedNode == 'pads' || selectedNode.startsWith('pad:')) {
                return _buildAnimatedTransition(UGRightPanel());
              } else if (selectedNode.startsWith('well:')) {
                return _buildAnimatedTransition(RightPanel());
              } else {
                return _buildAnimatedTransition(
                  Column(
                    children: [
                      SectionNavBar(),
                      // Material(
                      //   elevation: 1,
                      //   shadowColor: Colors.black.withOpacity(0.02),
                      //   child: LockBar(),
                      // ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(3, 2, 3, 3),
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
                                return const _PlainReportTab();
                              case 6:
                                return RemarksView();
                              case 7:
                                return const _PlainReportTab();
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

class _PlainReportTab extends StatelessWidget {
  const _PlainReportTab();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.white);
  }
}
