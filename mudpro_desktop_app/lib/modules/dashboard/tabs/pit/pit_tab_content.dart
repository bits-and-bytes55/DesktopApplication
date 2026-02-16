import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
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
    return Container(
      color: Colors.white,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (width < 900) {
              return _buildMobileLayout(context);
            } else {
              return _buildDesktopLayout(context);
            }
          },
        );
      }),
    );
  }

  // ================= MOBILE LAYOUT =================
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _activePitsSection(),
            const SizedBox(height: 12),
            _storageSection(),
            const SizedBox(height: 12),
            _volumeSummarySection(),
            const SizedBox(height: 12),
            _haulOffSection(context),
            const SizedBox(height: 12),
            _pitSnapshotButton(),
          ],
        ),
      ),
    );
  }

  // ================= DESKTOP LAYOUT =================
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN - Active Pits
            Flexible(
              flex: 2,
              child: Column(
                children: [
                  _activePitsSection(),
                  const SizedBox(height: 12),
                  _volumeSummarySection(),
                  const SizedBox(height: 12),
                  _pitSnapshotButton(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // RIGHT COLUMN - Storage & Haul Off
            Flexible(
              flex: 3,
              child: Column(
                children: [
                  _storageSection(),
                  const SizedBox(height: 12),
                  _haulOffSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ACTIVE PITS SECTION =================
  Widget _activePitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_damage, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      "Active Pits",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Tooltip(
                  message: "View Concentration",
                  child: InkWell(
                    onTap: () => Get.to(() => PitConcentrationPage()),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.bar_chart,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Table - Simple without card wrapper
        Obx(() {
          if (controller.isLoading.value) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          return Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: SingleChildScrollView(
              child: _buildActivePitsTable(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActivePitsTable() {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
          ),
          children: [
            _buildCompactTableHeaderCell("Pit"),
            _buildCompactTableHeaderCell("Measured Vol\n(bbl)"),
            _buildCompactTableHeaderCell("MW\n(ppg)"),
            _buildCompactTableHeaderCell("Mud"),
          ],
        ),
        
        // Data rows
        ...controller.selectedPits.map((pit) {
          return _buildActivePitDataRow(pit);
        }).toList(),
      ],
    );
  }

  // ================= STORAGE SECTION =================
  Widget _storageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.warehouse, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "Storage",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Table - Simple without card wrapper
        Obx(() {
          if (controller.isLoading.value) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          return Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: SingleChildScrollView(
              child: _buildStorageTable(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStorageTable() {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(2),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
          ),
          children: [
            _buildCompactTableHeaderCell("Pit"),
            _buildCompactTableHeaderCell("Calculated Vol\n(bbl)"),
            _buildCompactTableHeaderCell("Measured Vol\n(bbl)"),
            _buildCompactTableHeaderCell("MW\n(ppg)"),
            _buildCompactTableHeaderCell("Fluid Type"),
          ],
        ),
        
        // Data rows
        ...controller.unselectedPits.map((pit) {
          return _buildStorageDataRow(pit);
        }).toList(),
      ],
    );
  }

  // ================= VOLUME SUMMARY SECTION =================
  Widget _volumeSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.summarize, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "Volume Name",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Content - Simple table layout
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
              verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1.5),
            },
            children: [
              _buildVolumeTableRow("Held Vol. Difference", "32.75"),
              _buildVolumeTableRow("Hole", "574.75"),
              _buildVolumeTableRow("Active Pits", "329.40"),
              _buildVolumeTableRow("Active System", "904.15"),
              _buildVolumeTableRow("End Vol.", "0.00"),
              _buildVolumeTableRow("End Vol. - Active System", "0.00"),
              _buildVolumeTableRow("Total Storage", "0.00"),
              _buildVolumeTableRow("Total on Location", "904.15"),
              _buildVolumeTableRow("Previous Total on Location", "0.00"),
            ],
          ),
        ),
      ],
    );
  }

  // ================= HAUL OFF SECTION =================
  Widget _haulOffSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
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
        ),

        // Content - Reduced width, simple table
        SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
                verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1),
              },
              children: [
                _buildHaulOffTableRow("No. of Loads", "", ""),
                _buildHaulOffTableRow("Vol.", "", "(bbl)"),
                _buildHaulOffTableRow("Weight", "", "(lbm)"),
                _buildHaulOffTableRow("Oil", "", "(%)"),
                _buildHaulOffTableRow("Water", "", "(%)"),
                _buildHaulOffTableRow("Solids", "", "(%)"),
                _buildHaulOffTableRow("OOC Wt.", "", "(%)"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= PIT SNAPSHOT BUTTON =================
  Widget _pitSnapshotButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Get.to(() => PitSnapshotPage()),
        icon: const Icon(Icons.camera_alt, size: 16),
        label: const Text(
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
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // ================= HELPER METHODS =================
  
  Widget _buildCompactTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Active Pits Data Row
  TableRow _buildActivePitDataRow(dynamic pit) {
    return TableRow(
      children: [
        // Pit Name - Read Only
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            pit.pitName ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Measured Vol - Editable
        _buildCompactEditableCell(pit.capacity.toString()),
        // MW - Editable
        _buildCompactEditableCell(""),
        // Mud - Editable
        _buildCompactEditableCell(""),
      ],
    );
  }

  // Storage Data Row
  TableRow _buildStorageDataRow(dynamic pit) {
    return TableRow(
      children: [
        // Pit Name - Read Only
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            pit.pitName ?? '',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Calculated Vol - Editable
        _buildCompactEditableCell("0.00"),
        // Measured Vol - Editable
        _buildCompactEditableCell(pit.capacity.toString()),
        // MW - Editable
        _buildCompactEditableCell(""),
        // Fluid Type - Editable
        _buildCompactEditableCell(""),
      ],
    );
  }

  // Compact Editable Cell
  Widget _buildCompactEditableCell(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Obx(() {
        if (dashboard.isLocked.value) {
          return Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          );
        }
        return TextFormField(
          initialValue: value,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        );
      }),
    );
  }

  // Volume Table Row (2 columns: label, value)
  TableRow _buildVolumeTableRow(String label, String value) {
    return TableRow(
    
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Obx(() {
            if (dashboard.isLocked.value) {
              return Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              );
            }
            return TextFormField(
              initialValue: value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            );
          }),
        ),
      ],
    );
  }

  // Haul Off Table Row (3 columns: label, value, unit)
  TableRow _buildHaulOffTableRow(String label, String value, String unit) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Obx(() {
            if (dashboard.isLocked.value) {
              return Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              );
            }
            return TextFormField(
              initialValue: value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            );
          }),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}