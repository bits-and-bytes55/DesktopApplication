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

            /// MAIN CONTENT - NON SCROLLABLE
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
        /// LEFT PROPERTY TABLE - Fixed Width
        SizedBox(
          width: 550,
          child: _leftPanel(),
        ),

        VerticalDivider(width: 1, color: Colors.grey.shade300),

        /// RIGHT RHEOLOGY SIDE - Remaining space
        Expanded(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Fluid Name
          Text(
            "Fluid Name",
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 200,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: c.fluidnameController,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: "Enter fluid name",
                hintStyle: AppTheme.caption.copyWith(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Fluid Type
          Text(
            "Fluid Type",
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 10),
          
          Obx(() => Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: c.selectedFluidType.value,
                items: const [
                  DropdownMenuItem(
                    value: "Water-based",
                    child: Text("Water-based", style: TextStyle(fontSize: 11)),
                  ),
                  DropdownMenuItem(
                    value: "Oil-based",
                    child: Text("Oil-based", style: TextStyle(fontSize: 11)),
                  ),
                  DropdownMenuItem(
                    value: "Synthetic",
                    child: Text("Synthetic", style: TextStyle(fontSize: 11)),
                  ),
                ],
                onChanged: dashboard.isLocked.value 
                    ? null 
                    : (v) => c.changeFluidType(v!),
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                ),
                isDense: true,
              ),
            ),
          )),

          const SizedBox(width: 20),

          // Checkboxes
          Obx(() => Row(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: c.isCompletionFluid.value,
                  onChanged: dashboard.isLocked.value 
                      ? null 
                      : (v) => c.isCompletionFluid.value = v ?? false,
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Text(
                "Completion Fluid",
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          )),

          const SizedBox(width: 12),

          Obx(() => Row(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: c.isWeightedMud.value,
                  onChanged: dashboard.isLocked.value 
                      ? null 
                      : (v) => c.isWeightedMud.value = v ?? false,
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Text(
                "Weighted Mud",
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  // ================= LEFT PANEL =================
  Widget _leftPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.science, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  "Mud Properties",
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Table - Fixed Height with internal scrolling
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Property Column
                          Container(
                            width: 150,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                fontSize: 10,
                              ),
                            ),
                          ),
                          
                          // Sample Columns
                          ...c.samples.map((sample) {
                            return Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
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
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Table Rows - Scrollable content
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Column(
                            children: c.propertyTable.entries.map((entry) {
                              final isLast = c.propertyTable.entries.last.key == entry.key;
                              return Container(
                                height: 30,
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
                                      width: 150,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: Text(
                                        entry.key,
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 10,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    
                                    // Sample Values
                                    ...entry.value.asMap().entries.map((cellEntry) {
                                      final index = cellEntry.key;
                                      final cell = cellEntry.value;
                                      final isLastColumn = index == entry.value.length - 1;
                                      
                                      return Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
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
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rheology Model Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  "Rheology Model",
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() => Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: c.rheologyModel.value,
                      items: const [
                        DropdownMenuItem(
                          value: "Bingham",
                          child: Text("Bingham", style: TextStyle(fontSize: 11)),
                        ),
                        DropdownMenuItem(
                          value: "Power Law",
                          child: Text("Power Law", style: TextStyle(fontSize: 11)),
                        ),
                        DropdownMenuItem(
                          value: "HB",
                          child: Text("HB", style: TextStyle(fontSize: 11)),
                        ),
                      ],
                      onChanged: dashboard.isLocked.value 
                          ? null 
                          : (v) => c.changeModel(v!),
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                      ),
                      isDense: true,
                    ),
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Rheology Table - Fixed Height
          Expanded(
            flex: 3,
            child: Obx(() {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        children: [
                          // RPM Column
                          Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                fontSize: 10,
                              ),
                            ),
                          ),
                          
                          // Sample Columns
                          ...c.samples.map((sample) {
                            return Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
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
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Table Content - Scrollable
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Column(
                            children: c.rheologyTable.entries.map((entry) {
                              final isLast = c.rheologyTable.entries.last.key == entry.key;
                              
                              return Container(
                                height: 30,
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
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: Text(
                                        entry.key,
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 10,
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
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          // Radio Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Obx(() => Transform.scale(
                  scale: 0.8,
                  child: Radio(
                    value: true,
                    groupValue: true,
                    onChanged: dashboard.isLocked.value ? null : (v) {},
                    activeColor: AppTheme.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )),
                Text(
                  "API (RP 13D)",
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 16),
                Obx(() => Transform.scale(
                  scale: 0.8,
                  child: Radio(
                    value: false,
                    groupValue: true,
                    onChanged: dashboard.isLocked.value ? null : (v) {},
                    activeColor: AppTheme.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )),
                Text(
                  "Use All Readings",
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Bottom Tables Row
          Expanded(
            flex: 2,
            child: Row(
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

                const SizedBox(width: 10),

                // Solids Table
                Expanded(
                  child: _smallTable(
                    "Solids",
                    {
                      "Shale CEC (meq/100g)": "15.00",
                      "Bent CEC (meq/100g)": "65.00",
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SMALL TABLE =================
  Widget _smallTable(String title, Map<String, String> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              title,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 10,
              ),
            ),
          ),

          // Content
          ...data.entries.map((e) {
            final isLast = data.entries.last.key == e.key;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                        fontSize: 10,
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
                          fontSize: 10,
                        ),
                      );
                    }
                    return Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: e.value),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          hintText: "Value",
                          hintStyle: AppTheme.caption.copyWith(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
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