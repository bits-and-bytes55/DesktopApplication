import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_general_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_left_pannel.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/interval_mud_plan_tab.dart';

const Color _ivBorder = Color(0xFFC9CED6);
const Color _ivLocked = Color(0xFFFFF6C7);

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
    _wellWorker?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ugSt = Get.find<UgStController>();
    final intervalCtrl = Get.find<IntervalController>();

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 30,
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              indicator: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(color: _ivBorder),
                                  left: BorderSide(color: _ivBorder),
                                  right: BorderSide(color: _ivBorder),
                                ),
                              ),
                              dividerColor: Colors.transparent,
                              labelColor: const Color(0xFF2F2F2F),
                              unselectedLabelColor: const Color(0xFF2F2F2F),
                              labelStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                              tabs: const [
                                Tab(text: 'General'),
                                Tab(text: 'Mud Plan'),
                              ],
                            ),
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
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'End of Well Conclusion and Recommendations',
                      style: TextStyle(fontSize: 10, color: Color(0xFF2F2F2F)),
                    ),
                  ),
                  Expanded(
                    child: Obx(
                      () => TextField(
                        controller: intervalCtrl.endOfIntervalCtrl,
                        readOnly: ugSt.isLocked.value,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2F2F2F),
                        ),
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
