import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';

class LockBar extends StatefulWidget {
  @override
  _LockBarState createState() => _LockBarState();
}

class _LockBarState extends State<LockBar> with TickerProviderStateMixin {
  final c = Get.find<DashboardController>();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (c.isLocked.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }

      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: 40,
        decoration: BoxDecoration(
          gradient: c.isLocked.value
              ? LinearGradient(
                  colors: [Color(0xffFC8181), Color(0xffF56565)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Color(0xff38B2AC), Color(0xff319795)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: c.isLocked.value
                  ? Row(
                      key: ValueKey('locked'),
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Document Locked",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: ValueKey('unlocked'),
                      children: [
                        Icon(Icons.lock_open, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Document Unlocked",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(width: 20),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  c.toggleLock();
                  _playToggleAnimation();
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 1, end: 1.2)
                            .animate(_animationController),
                        child: Icon(
                          c.isLocked.value ? Icons.lock_open : Icons.lock,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        c.isLocked.value ? "Unlock" : "Lock",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
      );
    });
  }

  void _playToggleAnimation() {
    final controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    final animation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    controller.addListener(() {
      setState(() {});
    });

    controller.forward().then((_) {
      controller.reverse().then((_) {
        controller.dispose();
      });
    });
  }
}