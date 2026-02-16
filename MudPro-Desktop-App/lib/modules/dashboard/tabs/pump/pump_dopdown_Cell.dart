import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dashboard_controller.dart';

class PumpDropdownCell extends StatelessWidget {
  final RxString value;
  final List<String> options;

  const PumpDropdownCell({
    super.key,
    required this.value,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<DashboardController>();

    return Obx(() {
      if (dashboard.isLocked.value) {
        return Text(
          value.value,
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        );
      }

      return DropdownButtonHideUnderline(
        child: SizedBox(
          width: 140, // ✅ FIXED WIDTH
          child: DropdownButton<String>(
            value: value.value.isEmpty ? null : value.value,
            isDense: true,
            iconSize: 14,
            items: options
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: const TextStyle(fontSize: 11)),
                    ))
                .toList(),
            onChanged: (v) => value.value = v ?? '',
          ),
        ),
      );
    });
  }
}
