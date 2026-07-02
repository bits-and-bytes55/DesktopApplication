import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_general_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_left_pannel.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_mud_plan_tab.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_setup_ui_pattern.dart';

const Color _ivBorder = wellSetupBorder;
const Color _ivLocked = wellSetupLockedEditable;

class IntervalView extends StatefulWidget {
  const IntervalView({super.key});

  @override
  State<IntervalView> createState() => _IntervalViewState();
}

class _IntervalViewState extends State<IntervalView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final IntervalController _ivCtrl;
  Worker? _wellWorker;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_saveMudPlanOnTabLeave);

    _ivCtrl = Get.isRegistered<IntervalController>()
        ? Get.find<IntervalController>()
        : Get.put(IntervalController(), permanent: true);
    final ugSt = Get.find<UgStController>();
    final initialWellId = ugSt.selectedWellId.value ?? '';
    _ivCtrl.init(initialWellId);
    _wellWorker = ever<String?>(ugSt.selectedWellId, (wellId) {
      final nextWellId = wellId ?? '';
      if (nextWellId == _ivCtrl.wellId.value) return;
      _ivCtrl.init(nextWellId);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_saveMudPlanOnTabLeave);
    _wellWorker?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _saveMudPlanOnTabLeave() {
    if (_tabController.previousIndex != 1 || _tabController.index == 1) {
      return;
    }
    if (Get.isRegistered<MudController>()) {
      Get.find<MudController>().saveMudReportState(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ugSt = Get.find<UgStController>();
    final intervalCtrl = Get.find<IntervalController>();

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: wellSetupPageBackground,
          border: Border.all(color: _ivBorder),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: 345, child: IntervalLeftPanel()),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 30,
                          color: AppTheme.primaryColor,
                          alignment: Alignment.centerLeft,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            indicatorColor: Colors.white,
                            indicatorWeight: 2,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white,
                            labelStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: const [
                              Tab(text: 'General'),
                              Tab(text: 'Mud Plan'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: _ivBorder),
                                left: BorderSide(color: _ivBorder),
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
                ],
              ),
            ),
            Container(
              height: 162,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _ivBorder)),
              ),
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    color: wellSetupSectionHeader,
                    child: Text(
                      'End of Well Conclusion and Recommendations',
                      style: wellSetupSectionText,
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => TextField(
                        controller: intervalCtrl.endOfIntervalCtrl,
                        readOnly: ugSt.isLocked.value,
                        maxLines: null,
                        expands: true,
                        style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: ugSt.isLocked.value
                              ? _ivLocked
                              : Colors.white,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: _ivBorder),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: _ivBorder),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: _ivBorder),
                          ),
                          contentPadding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
