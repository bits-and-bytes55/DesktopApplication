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
import 'package:mudpro_desktop_app/modules/dashboard/widgets/home_secondary_tabbar.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

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
    return Column(
      children: [
        // ───── IMPROVED TOP TAB BAR ─────
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
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
                  child: Row(
                    children: tabs.map(_tabButton).toList(),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 8),
                child: Obx(() => IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: c.isLocked.value 
                            ? LinearGradient(
                                colors: [Color(0xffFC8181), Color(0xffF56565)],
                              )
                            : AppTheme.secondaryGradient,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          c.isLocked.value ? Icons.lock : Icons.lock_open,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: c.toggleLock,
                    )),
              ),
            ],
          ),
        ),

        // ───── TAB CONTENT ─────
        Expanded(
          child: Container(
            color: AppTheme.backgroundColor,
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
            gradient: selected ? AppTheme.primaryGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            border: selected
                ? null
                : Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
          ),
          child: Text(
            id.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? Colors.white : AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    });
  }
}