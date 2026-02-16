import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_3d_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_data_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_dogleg_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_plan_tab.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/survey_section_tab.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SurveyView extends StatelessWidget {
  SurveyView({super.key});

  final RxInt selectedTab = 0.obs;

  final List<Map<String, dynamic>> tabs = const [
    {"label": "Data", "icon": Icons.table_chart},
    {"label": "Section", "icon": Icons.account_tree},
    {"label": "Plan", "icon": Icons.timeline},
    {"label": "Dogleg", "icon": Icons.show_chart},
    {"label": "3D", "icon": Icons.rotate_90_degrees_ccw},
  ];


  final demoPlanData = [
  PlanPoint(-600, -950),
  PlanPoint(-520, -800),
  PlanPoint(-450, -650),
  PlanPoint(-380, -500),
  PlanPoint(-300, -350),
  PlanPoint(-220, -180),
  PlanPoint(-150, -40),
  PlanPoint(-120, -10),
];

final demoDoglegData = [
  DoglegPoint(0, 0.2),
  DoglegPoint(500, 0.5),
  DoglegPoint(1200, 2.0),
  DoglegPoint(2000, 1.8),
  DoglegPoint(2800, 0.6),
  DoglegPoint(3500, 0.8),
  DoglegPoint(4500, 0.4),
  DoglegPoint(6000, 0.7),
  DoglegPoint(7000, 2.5),
  DoglegPoint(7800, 4.5),
  DoglegPoint(8500, 5.8),
  DoglegPoint(9200, 6.3),
];

final demo3DWellPath = [
  Well3DPoint(0, 0, 0),
  Well3DPoint(0, 0, -500),
  Well3DPoint(20, 10, -1500),
  Well3DPoint(60, 40, -3000),
  Well3DPoint(120, 90, -5000),
  Well3DPoint(200, 160, -8000),
];




  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _tabBar(),
          const SizedBox(height: 1),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
              ),
              child: Obx(() {
                switch (selectedTab.value) {
                  case 0:
                    return SurveyDataTab();
                  case 1:
                    return const SectionViewChart(points: [],);
                  case 2:
                    return PlanViewChart(points: demoPlanData,);
                  case 3:
                    return  DoglegChart(points: demoDoglegData,);
                  case 4:
                    return  Chart3DPage();
                  default:
                    return SurveyDataTab();
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB BAR =================
  Widget _tabBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Obx(
        () => Row(
          children: [
            const SizedBox(width: 8),
            ...List.generate(tabs.length, (i) {
              final active = selectedTab.value == i;
              return GestureDetector(
                onTap: () => selectedTab.value = i,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? AppTheme.primaryColor : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tabs[i]['icon'],
                        size: 16,
                        color: active ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tabs[i]['label'],
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          color: active ? AppTheme.primaryColor : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              margin: const EdgeInsets.only(right: 12),
              child: Obx(() {
                final activeTabName = tabs[selectedTab.value]['label'];
                return Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activeTabName,
                      style: AppTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}