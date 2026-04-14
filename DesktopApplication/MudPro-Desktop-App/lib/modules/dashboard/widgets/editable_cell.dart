import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';

class EditableCell extends StatelessWidget {
  final RxString value;
  final double minHeight;

  const EditableCell({super.key, required this.value, this.minHeight = 32});

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<DashboardController>();

    return Obx(() {
      if (dashboard.isLocked.value) {
        return Container(
          constraints: BoxConstraints(
            minHeight: minHeight,
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            value.value.isEmpty ? "-" : value.value,
            style: AppTheme.caption.copyWith(
              color: value.value.isEmpty 
                  ? Colors.grey.shade400 
                  : AppTheme.textPrimary,
              fontStyle: value.value.isEmpty 
                  ? FontStyle.italic 
                  : FontStyle.normal,
            ),
          ),
        );
      }

      return Container(
        constraints: BoxConstraints(
          minHeight: minHeight,
        ),
        child: TextField(
          controller: TextEditingController(text: value.value),
          onChanged: (v) => value.value = v,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            hintText: "Enter value",
            hintStyle: AppTheme.caption.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
          style: AppTheme.caption.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
      );
    });
  }
}