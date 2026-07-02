import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/formation_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/alert_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/report_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/pad_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/pit_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/pump_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/sce_view.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/ug_ui_pattern.dart';

class UGRightPanel extends StatelessWidget {
  final c = Get.find<UgController>();

  final tabs = const [
    'pad',
    'inventory',
    'pit',
    'pump',
    'sce',
    'formation',
    'report',
    'alert',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: ugDataText,
      child: ColoredBox(
        color: ugPageBackground,
        child: Column(
          children: [
        // ───── IMPROVED TOP TAB BAR ─────
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: ugPageBackground,
            border: Border(
              bottom: const BorderSide(color: ugBorder, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: tabs.map(_tabButton).toList()),
                ),
              ),
            ],
          ),
        ),

        // ───── TAB CONTENT ─────
        Expanded(
          child: Container(
            color: ugPageBackground,
            child: Obx(() {
              switch (c.activeRightTab.value) {
                case 'pad':
                  return PadView();
                case 'inventory':
                  return InventoryView();
                case 'pit':
                  return PitView();
                case 'pump':
                  return PumpView();
                case 'sce':
                  return SceView();
                case 'formation':
                  return FormationView();
                case 'report':
                  return ReportView();
                case 'alert':
                  return AlertView();
                default:
                  return Center(
                    child: Text('Coming Soon', style: AppTheme.bodyLarge),
                  );
              }
            }),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String id) {
    return Obx(() {
      final selected = c.activeRightTab.value == id;
      return InkWell(
        onTap: () => c.switchRightTab(id),
        onHover: (hovering) {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: selected ? ugSectionHeader : ugColumnHeader,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            border: Border.all(color: ugBorder),
          ),
          child: Text(
            id.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.black,
              letterSpacing: 0,
            ),
          ),
        ),
      );
    });
  }
}
