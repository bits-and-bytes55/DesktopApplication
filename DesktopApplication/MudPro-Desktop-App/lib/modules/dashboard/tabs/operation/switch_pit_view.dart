import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import '../../controller/dashboard_controller.dart';

class SwitchPitView extends StatefulWidget {
  const SwitchPitView({super.key});

  @override
  State<SwitchPitView> createState() => _SwitchPitViewState();
}

class _SwitchPitViewState extends State<SwitchPitView> {
  final PitController pitController = Get.put(PitController());
  final DashboardController dashboardController = Get.find<DashboardController>();

  final ScrollController activePitScrollController = ScrollController();
  final ScrollController storagePitScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await pitController.fetchSelectedPits();
    await pitController.fetchUnselectedPits();
  }

  @override
  void dispose() {
    activePitScrollController.dispose();
    storagePitScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Pits Section
          _buildActivePitsSection(),
          const SizedBox(height: 16),
          // Storage Pits Section
          _buildStoragePitsSection(),
        ],
      ),
    );
  }

  // ===================================================
  // ACTIVE PITS SECTION
  // ===================================================
  Widget _buildActivePitsSection() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.6, // Reduced width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.95),
                  AppTheme.primaryColor,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  "Active Pits - Uncheck to Move to Storage",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Table
          _buildActivePitsTable(),
        ],
      ),
    );
  }

  // ===================================================
  // STORAGE PITS SECTION
  // ===================================================
  Widget _buildStoragePitsSection() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45, // More reduced width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.95),
                  AppTheme.primaryColor,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  "Storage - Check to Move to Active Pits",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Table
          _buildStoragePitsTable(),
        ],
      ),
    );
  }

  // ===================================================
  // ACTIVE PITS TABLE (4 COLUMNS)
  // ===================================================
  Widget _buildActivePitsTable() {
    return Column(
      children: [
        // Fixed Header
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.5), // #
              1: FlexColumnWidth(2.0), // Pit
              2: FlexColumnWidth(0.8), // Checked
              3: FlexColumnWidth(1.2), // Measured Vol.
            },
            children: [
              TableRow(
                children: [
                  _buildHeaderCell("#"),
                  _buildHeaderCell("Pit"),
                  _buildHeaderCell("Checked"),
                  _buildHeaderCell("Measured Vol. (bbl)"),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Body
        Obx(() {
          if (pitController.isLoading.value) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            );
          }

          if (pitController.selectedPits.isEmpty) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                "No active pits",
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            );
          }

          return Container(
            constraints: const BoxConstraints(maxHeight: 180), // Reduced height
            child: Scrollbar(
              controller: activePitScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: activePitScrollController,
                shrinkWrap: true,
                itemCount: pitController.selectedPits.length,
                itemBuilder: (context, index) {
                  final pit = pitController.selectedPits[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: index.isEven ? Colors.white : Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(0.5),
                        1: FlexColumnWidth(2.0),
                        2: FlexColumnWidth(0.8),
                        3: FlexColumnWidth(1.2),
                      },
                      children: [
                        TableRow(
                          children: [
                            _buildDataCell("${index + 1}"),
                            _buildDataCell(pit.pitName, isLeft: true),
                            _buildCheckboxCell(pit, true),
                            _buildDataCell(pit.capacity.value.toStringAsFixed(2)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===================================================
  // STORAGE PITS TABLE (3 COLUMNS)
  // ===================================================
  Widget _buildStoragePitsTable() {
    return Column(
      children: [
        // Fixed Header
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.5), // #
              1: FlexColumnWidth(2.5), // Pit
              2: FlexColumnWidth(0.8), // Checked
            },
            children: [
              TableRow(
                children: [
                  _buildHeaderCell("#"),
                  _buildHeaderCell("Pit"),
                  _buildHeaderCell("Checked"),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Body
        Obx(() {
          if (pitController.isLoading.value) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            );
          }

          if (pitController.unselectedPits.isEmpty) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                "No storage pits",
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            );
          }

          return Container(
            constraints: const BoxConstraints(maxHeight: 180), // Reduced height
            child: Scrollbar(
              controller: storagePitScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: storagePitScrollController,
                shrinkWrap: true,
                itemCount: pitController.unselectedPits.length,
                itemBuilder: (context, index) {
                  final pit = pitController.unselectedPits[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: index.isEven ? Colors.white : Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(0.5),
                        1: FlexColumnWidth(2.5),
                        2: FlexColumnWidth(0.8),
                      },
                      children: [
                        TableRow(
                          children: [
                            _buildDataCell("${index + 1}"),
                            _buildDataCell(pit.pitName, isLeft: true),
                            _buildCheckboxCell(pit, false),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===================================================
  // HELPER WIDGETS
  // ===================================================
  
  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11, // Reduced font size
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
        textAlign: text == "#" || text == "Checked" ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isLeft = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11, // Reduced font size
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        textAlign: isLeft ? TextAlign.left : TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCheckboxCell(dynamic pit, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
      alignment: Alignment.center,
      child: Obx(() {
        // For active pits: checkbox is checked when initialActive is true
        // For storage pits: checkbox is checked when initialActive is false (inverted)
        bool checkboxValue = isActive ? pit.initialActive.value : !pit.initialActive.value;
        
        return Transform.scale(
          scale: 0.85, // Slightly smaller checkbox
          child: Checkbox(
            value: checkboxValue,
            onChanged: dashboardController.isLocked.value
                ? null
                : (v) async {
                    // Toggle the pit status
                    await pitController.togglePitActive(pit);
                    
                    // Reload data to reflect changes
                    await _loadData();
                  },
            activeColor: AppTheme.primaryColor,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        );
      }),
    );
  }
}