import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class TopInfoBar extends StatelessWidget {
  final padWellC = padWellContext;

  @override
  Widget build(BuildContext context) {
    AppUnits.signature;
    return Container(
      height: 32,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Obx(() => _buildInfoField(
                "Well",
                padWellC.selectedWellName.isEmpty
                    ? 'No well selected'
                    : padWellC.selectedWellName,
              )),
          const SizedBox(width: 20),
          _buildInfoField("Date", "12/27/2025"),
          const SizedBox(width: 20),
          _buildInfoField("Report #", "12"),
          const Spacer(),
          _buildInfoField("MD ${AppUnits.length}", AppUnits.formatValue('9055.0', '(ft)')),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xffFFFCE6),
            border: Border.all(color: Colors.black26),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
