import 'package:flutter/material.dart';

class TopInfoBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildInfoField("Well", "UG-0293 ST"),
          const SizedBox(width: 20),
          _buildInfoField("Date", "12/27/2025"),
          const SizedBox(width: 20),
          _buildInfoField("Report #", "12"),
          const Spacer(),
          _buildInfoField("MD (ft)", "9055.0"),
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