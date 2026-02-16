import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/editable_cell.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudView extends StatelessWidget {
  MudView({super.key});

  final c = Get.put(MudController());
  final dashboard = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 1024;
        
        return Column(
          children: [
            /// TOP CONTROLS
            _topControls(),
            
            Divider(height: 1, color: Colors.grey.shade300),

            /// MAIN CONTENT
            Expanded(
              child: isSmallScreen 
                  ? _buildMobileLayout()
                  : _buildDesktopLayout(),
            ),
          ],
        );
      },
    );
  }

  // ================= DESKTOP LAYOUT =================
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LEFT PROPERTY TABLE
        Expanded(
          flex: 2,
          child: _leftPanel(),
        ),

        VerticalDivider(width: 1, color: Colors.grey.shade300),

        /// RIGHT RHEOLOGY SIDE - Made fully scrollable
        Expanded(
          flex: 3,
          child: _rightPanel(),
        ),
      ],
    );
  }

  // ================= MOBILE LAYOUT =================
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _leftPanel(),
            const SizedBox(height: 16),
            _rightPanel(),
          ],
        ),
      ),
    );
  }

  // ================= TOP CONTROLS =================
  Widget _topControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fluid Name Row
          Row(
            children: [
              Text(
                "Fluid Name",
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  width: 300,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: c.fluidnameController,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      hintText: "Enter fluid name",
                      hintStyle: AppTheme.caption.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Fluid Type and Options Row
          Row(
            children: [
              Text(
                "Fluid Type",
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              
              // Fluid Type Dropdown
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: "Water-based",
                    items: const [
                      DropdownMenuItem(
                        value: "Water-based",
                        child: Text("Water-based", style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: "Oil-based",
                        child: Text("Oil-based", style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: "Synthetic",
                        child: Text("Synthetic", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (_) {},
                    style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Checkboxes
              Row(
                children: [
                  Obx(() => Checkbox(
                    value: false,
                    onChanged: dashboard.isLocked.value ? null : (v) {},
                    activeColor: AppTheme.primaryColor,
                  )),
                  Text(
                    "Completion Fluid",
                    style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              Row(
                children: [
                  Obx(() => Checkbox(
                    value: false,
                    onChanged: dashboard.isLocked.value ? null : (v) {},
                    activeColor: AppTheme.primaryColor,
                  )),
                  Text(
                    "Weighted Mud",
                    style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= LEFT PANEL =================
  Widget _leftPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.science, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "Mud Properties",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Table
          Expanded(
            child: Obx(() {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Property Column
                              Container(
                                width: 200,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Text(
                                  "Property",
                                  style: AppTheme.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              
                              // Sample Columns
                              ...c.samples.map((sample) {
                                return Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: sample == c.samples.last 
                                              ? Colors.transparent 
                                              : Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      sample,
                                      textAlign: TextAlign.center,
                                      style: AppTheme.caption.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        // Table Rows
                        ...c.propertyTable.entries.map((entry) {
                          final isLast = c.propertyTable.entries.last.key == entry.key;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isLast ? Colors.transparent : Colors.grey.shade100,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Property Name
                                Container(
                                  width: 200,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  child: Text(
                                    entry.key,
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                
                                // Sample Values
                                ...entry.value.asMap().entries.map((cellEntry) {
                                  final index = cellEntry.key;
                                  final cell = cellEntry.value;
                                  final isLastColumn = index == entry.value.length - 1;
                                  
                                  return Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: isLastColumn 
                                                ? Colors.transparent 
                                                : Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                      child: EditableCell(value: cell),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= RIGHT PANEL =================
  Widget _rightPanel() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rheology Model Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(
                    "Rheology Model",
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Obx(() => DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: c.rheologyModel.value,
                        items: const [
                          DropdownMenuItem(
                            value: "Bingham",
                            child: Text("Bingham", style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: "Power Law",
                            child: Text("Power Law", style: TextStyle(fontSize: 12)),
                          ),
                          DropdownMenuItem(
                            value: "HB",
                            child: Text("HB", style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        onChanged: (v) => c.changeModel(v!),
                        style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
                      ),
                    )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rheology Table - FIXED HEIGHT
            Obx(() {
              return Container(
                height: 400, // Increased fixed height
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      child: Row(
                        children: [
                          // RPM Column
                          Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Text(
                              "RPM",
                              style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          
                          // Sample Columns
                          ...c.samples.map((sample) {
                            return Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: sample == c.samples.last 
                                          ? Colors.transparent 
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  sample,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Table Content - FIXED: Always show even when locked/unlocked
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Column(
                            children: _getRheologyTableRows(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Radio Options
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Obx(() => Radio(
                    value: true,
                    groupValue: true,
                    onChanged: dashboard.isLocked.value ? null : (v) {},
                    activeColor: AppTheme.primaryColor,
                  )),
                  Text(
                    "API (RP 13D)",
                    style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 20),
                  Obx(() => Radio(
                    value: false,
                    groupValue: true,
                    onChanged: dashboard.isLocked.value ? null : (v) {},
                    activeColor: AppTheme.primaryColor,
                  )),
                  Text(
                    "Use All Readings",
                    style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bottom Tables
            Row(
              children: [
                // Specific Gravity Table
                Expanded(
                  child: _smallTable(
                    "Specific Gravity",
                    {
                      "Oil (SG)": "0.80",
                      "HGS (SG)": "4.20",
                      "LGS (SG)": "2.60",
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Others Table
                Expanded(
                  child: _smallTable(
                    "Others",
                    {
                      "BHCT (°F)": "180.0",
                      "ESD (ppg)": "8.4",
                      "ECD (ppg)": "8.6",
                      "ROC (%)": "12.5",
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get rheology table rows with dummy data
  List<Widget> _getRheologyTableRows() {
    final rows = c.rheologyTable.entries.toList();
    
    // Add dummy data if empty
    if (rows.isEmpty) {
      return [];
    }
    
    return rows.map((entry) {
      final isLast = rows.last.key == entry.key;
      
      // Get dummy data based on RPM
      List<String> dummyData = _getDummyDataForRPM(entry.key);
      
      return Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : Colors.grey.shade100,
            ),
          ),
        ),
        child: Row(
          children: [
            // RPM Value
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Text(
                entry.key,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            
            // Sample Values - Use dummy data
            ...List.generate(c.samples.length, (index) {
              final isLastColumn = index == c.samples.length - 1;
              final value = dummyData.length > index ? dummyData[index] : "";
              
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: isLastColumn 
                            ? Colors.transparent 
                            : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: EditableCell(value: RxString(value)),
                ),
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  // Helper method to get dummy data for different RPMs
  List<String> _getDummyDataForRPM(String rpm) {
    switch (rpm) {
      case "600":
        return ["45", "48", "46", "50", "55"];
      case "300":
        return ["28", "30", "29", "32", "35"];
      case "200":
        return ["22", "24", "23", "25", "28"];
      case "100":
        return ["16", "18", "17", "20", "22"];
      case "6":
        return ["8", "9", "8", "10", "12"];
      case "3":
        return ["6", "7", "6", "8", "10"];
      case "PV (cp)":
        return ["17", "18", "17", "18", "20"];
      case "YP (lb/100ft²)":
        return ["11", "12", "12", "14", "15"];
      default:
        return ["", "", "", "", ""];
    }
  }

  // ================= SMALL TABLE =================
  Widget _smallTable(String title, Map<String, String> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Text(
              title,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Content
          ...data.entries.map((e) {
            final isLast = data.entries.last.key == e.key;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isLast ? Colors.transparent : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (dashboard.isLocked.value) {
                      return Text(
                        e.value.isEmpty ? "-" : e.value,
                        style: AppTheme.caption.copyWith(
                          color: e.value.isEmpty 
                              ? Colors.grey.shade400 
                              : AppTheme.textPrimary,
                          fontStyle: e.value.isEmpty 
                              ? FontStyle.italic 
                              : FontStyle.normal,
                        ),
                      );
                    }
                    return Container(
                      width: 100,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: e.value),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
                  }),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}