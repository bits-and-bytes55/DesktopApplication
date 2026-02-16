import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pit/pit_concentration.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pit/pit_snapshot.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PitPage extends StatelessWidget {
  PitPage({super.key});
  final PitController controller = Get.put(PitController());
  final dashboard = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (width < 800) {
          return Container(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _header(),
                    const SizedBox(height: 12),
                    _activePits(),
                    const SizedBox(height: 12),
                    _storage(),
                    const SizedBox(height: 12),
                    _volumeSummary(),
                    const SizedBox(height: 12),
                    _haulOff(),
                    const SizedBox(height: 12),
                    _snapshotButton(),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Container(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT PORTION - Active Pits & Volume Summary
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 300, maxWidth: 400),
                      child: Column(
                        children: [
                          _activePits(),
                          const SizedBox(height: 12),
                          _volumeSummary(),
                          const SizedBox(height: 12),
                          _snapshotButton(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // RIGHT PORTION - Storage & Haul Off
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _storage(),
                          const SizedBox(height: 12),
                          _haulOff(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header with teal color
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.storage, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Pit Management",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTIVE PITS =================
  Widget _activePits() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with teal color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_damage, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Active Pits",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => Get.to(() => PitConcentrationPage()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        "Concentration",
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Table
          Obx(() => Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(80),
                      1: FixedColumnWidth(100),
                      2: FixedColumnWidth(80),
                      3: FixedColumnWidth(100),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                        children: [
                          _buildTableHeaderCell("Pit", TextAlign.center),
                          _buildTableHeaderCell("Measured Vol\n(bbl)", TextAlign.center),
                          _buildTableHeaderCell("MW\n(ppg)", TextAlign.center),
                          _buildTableHeaderCell("Mud Type", TextAlign.center),
                        ],
                      ),
                      
                      // Data rows
                      ...controller.activePits.map((row) {
                        return _buildPitDataRow([
                          row["pit"]!.value,
                          row["vol"]!.value,
                          row["mw"]!.value,
                          row["mud"]!.value,
                        ]);
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ================= STORAGE =================
  Widget _storage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with teal color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.warehouse, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Storage",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Table
          Obx(() => Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(80),
                      1: FixedColumnWidth(100),
                      2: FixedColumnWidth(100),
                      3: FixedColumnWidth(80),
                      4: FixedColumnWidth(100),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                        children: [
                          _buildTableHeaderCell("Pit", TextAlign.center),
                          _buildTableHeaderCell("Calc Vol\n(bbl)", TextAlign.center),
                          _buildTableHeaderCell("Measured Vol\n(bbl)", TextAlign.center),
                          _buildTableHeaderCell("MW\n(ppg)", TextAlign.center),
                          _buildTableHeaderCell("Fluid Type", TextAlign.center),
                        ],
                      ),
                      
                      // Data rows
                      ...controller.storage.map((row) {
                        return _buildPitDataRow([
                          row["pit"]!.value,
                          row["calc"]!.value,
                          row["meas"]!.value,
                          row["mw"]!.value,
                          row["fluid"]!.value,
                        ]);
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ================= VOLUME SUMMARY =================
  Widget _volumeSummary() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with teal color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.summarize, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Volume Summary",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: controller.volumeSummary.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e["label"]!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        e["value"]!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HAUL OFF =================
  Widget _haulOff() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with teal color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Haul Off",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Obx(() => Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: controller.haulOff.map((row) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        row["label"]!.value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: _editableContent(row["value"]!),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )),
        ],
      ),
    );
  }

  // ================= SNAPSHOT BUTTON =================
  Widget _snapshotButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => Get.to(() => PitSnapshotPage()),
        icon: Icon(Icons.camera_alt, size: 16),
        label: Text(
          "Pit Snapshot",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  // ================= HELPER METHODS =================
  Widget _buildTableHeaderCell(String text, TextAlign align) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
        ),
        textAlign: align,
      ),
    );
  }

  TableRow _buildPitDataRow(List<String> values) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        color: Colors.white,
      ),
      children: values.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          height: 40,
          child: dashboard.isLocked.value
              ? Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                )
              : TextFormField(
                  initialValue: value,
                  style: TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    border: InputBorder.none,
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                    ),
                  ),
                ),
        );
      }).toList(),
    );
  }

  Widget _editableContent(RxString value) {
    return Obx(() {
      if (dashboard.isLocked.value) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value.value,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        );
      }
      return SizedBox(
        width: 100,
        height: 28,
        child: TextField(
          controller: TextEditingController(text: value.value),
          onChanged: (v) => value.value = v,
          style: TextStyle(fontSize: 11),
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    });
  }
}