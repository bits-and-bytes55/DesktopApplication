import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dashboard_controller.dart';

class PumpEditableCell extends StatelessWidget {
  final RxString value;
  final TextAlign align;

  const PumpEditableCell({
    super.key,
    required this.value,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<DashboardController>();

    return Obx(() {
      if (dashboard.isLocked.value) {
        return Text(
          value.value,
          textAlign: align,
          style: const TextStyle(fontSize: 11),
        );
      }

      return SizedBox(
        width: 80, // ✅ FIXED WIDTH
        height: 28,
        child: TextField(
          controller: TextEditingController(text: value.value)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: value.value.length),
            ),
          onChanged: (v) => value.value = v,
          textAlign: align,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(fontSize: 11),
        ),
      );
    });
  }
}
