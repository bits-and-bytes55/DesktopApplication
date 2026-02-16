import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';

class SectionNavBar extends StatefulWidget {
  @override
  _SectionNavBarState createState() => _SectionNavBarState();
}

class _SectionNavBarState extends State<SectionNavBar> with TickerProviderStateMixin {
  final tabs = [
    {"name": "Well", "icon": Icons.vertical_align_bottom},
    {"name": "Mud", "icon": Icons.water_drop},
    {"name": "Pump", "icon": Icons.settings},
    {"name": "Operation", "icon": Icons.build},
    {"name": "Pit", "icon": Icons.inbox},

    {"name": "Remarks", "icon": Icons.comment},
  
  ];
  
  final c = Get.find<DashboardController>();
  late AnimationController _animationController;
  late AnimationController _tapAnimationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _tapAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tapAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffF8F9FA), Color(0xffE9ECEF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Obx(() => Row(
            children: List.generate(tabs.length, (i) {
              final isActive = c.activeSectionTab.value == i;
              
              if (isActive) {
                _animationController.forward();
              }

              return Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      c.activeSectionTab.value = i;
                      _playTapAnimation(i);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.9),
                                  AppTheme.primaryColor,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isActive ? null : Colors.transparent,
                        border: Border(
                          right: BorderSide(color: Colors.black.withOpacity(0.05)),
                          bottom: BorderSide(
                            color: isActive ? AppTheme.primaryColor : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: isActive
                                ? Tween<double>(begin: 1, end: 1.2)
                                    .animate(_animationController)
                                : AlwaysStoppedAnimation(1),
                            child: Icon(
                              tabs[i]["icon"] as IconData,
                              size: 16,
                              color: isActive ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            tabs[i]["name"] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                              color: isActive ? Colors.white : AppTheme.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          )),
    );
  }

  void _playTapAnimation(int index) {
    _tapAnimationController.forward().then((_) {
      _tapAnimationController.reverse();
    });
  }
}