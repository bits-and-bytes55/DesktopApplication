import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/switch_mudtype_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SwitchMudTypeView extends StatelessWidget {
  SwitchMudTypeView({super.key});

  final controller = Get.put(SwitchMudTypeController());
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= ENHANCED HEADER =================
              // _buildHeader(),

              // const SizedBox(height: 20),

              /// SECTION 1
              _enhancedTwoTableSection(
                title: "1. Remove Mud from Active Pits",
                selected: controller.section1Selected,
                leftList: controller.section1Left,
                rightList: controller.section1Right,
                sectionIndex: 1,
              ),

              const SizedBox(height: 20),

              /// SECTION 2
              _enhancedTwoTableSection(
                title: "2. Fill Active Pits",
                selected: controller.section2Selected,
                leftList: controller.section2Left,
                rightList: controller.section2Right,
                sectionIndex: 2,
              ),

              const SizedBox(height: 20),

              /// SECTION 3
              _enhancedSingleTableSection(
                title: "3. Displace Fluid in Hole to Storage",
                list: controller.section3,
              ),

              const SizedBox(height: 24),

              // ================= ACTION BUTTONS =================
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ENHANCED HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.swap_vert_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Switch Mud Type",
                  style: AppTheme.titleMedium.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Manage mud type switching between active pits and storage",
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Total Operations",
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "3 Sections",
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ENHANCED TWO TABLE SECTION WITH RADIO
  // =====================================================
  Widget _enhancedTwoTableSection({
    required String title,
    required RxInt selected,
    required RxList<String?> leftList,
    required RxList<String?> rightList,
    required int sectionIndex,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sectionIndex == 1 
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    sectionIndex == 1 ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                    size: 20,
                    color: sectionIndex == 1 ? AppTheme.primaryColor : AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Obx(() => _enhancedTableWithRadio(
                      label: "Transfer",
                      isActive: selected.value == 0,
                      onSelect: () => selected.value = 0,
                      list: leftList,
                      sectionEnabled: selected.value == 0,
                    )),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Obx(() => _enhancedTableWithRadio(
                      label: "Make Storage",
                      isActive: selected.value == 1,
                      onSelect: () => selected.value = 1,
                      list: rightList,
                      sectionEnabled: selected.value == 1,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ENHANCED TABLE + RADIO
  // =====================================================
  Widget _enhancedTableWithRadio({
    required String label,
    required bool isActive,
    required VoidCallback onSelect,
    required RxList<String?> list,
    required bool sectionEnabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Radio Button Header
        InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive 
                ? AppTheme.primaryColor.withOpacity(0.08)
                : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive 
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? AppTheme.primaryColor : Colors.grey.shade400,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: isActive
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Enhanced Data Table
        _enhancedDataTable(list, sectionEnabled),
      ],
    );
  }

  // =====================================================
  // ENHANCED DATA TABLE WITH WORKING DROPDOWN
  // =====================================================
  Widget _enhancedDataTable(RxList<String?> list, bool enabled) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Pit",
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    "Volume (bbl)",
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          
          // Table Rows
          ...List.generate(
            list.length,
            (index) => Container(
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: index == list.length - 1 
                      ? Colors.transparent 
                      : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Pit Column with Dropdown
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: enabled
                          ? DropdownButton<String>(
                              value: list[index],
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 20,
                                color: Colors.grey.shade400,
                              ),
                              hint: Text(
                                "Select pit",
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  list[index] = newValue;
                                }
                              },
                              items: controller.pitList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            )
                          : Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                list[index] ?? "Select pit",
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: list[index] == null 
                                    ? Colors.grey.shade400 
                                    : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: list[index] == null ? FontStyle.italic : null,
                                ),
                              ),
                            ),
                    ),
                  ),
                  
                  // Volume Column
                  SizedBox(
                    width: 120,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: enabled
                          ? TextField(
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: "0.00",
                                hintStyle: AppTheme.caption.copyWith(
                                  color: Colors.grey.shade400,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              style: AppTheme.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                              keyboardType: TextInputType.number,
                            )
                          : Container(
                              height: 48,
                              alignment: Alignment.centerRight,
                              child: Text(
                                "0.00",
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  // =====================================================
  // ENHANCED SINGLE TABLE SECTION
  // =====================================================
  Widget _enhancedSingleTableSection({
    required String title,
    required RxList<String?> list,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    size: 20,
                    color: AppTheme.infoColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Enhanced Data Table (enabled by default)
          _enhancedDataTable(list, true),
        ],
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              // Cancel action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 0,
            ),
            child: Row(
              children: [
                Icon(Icons.cancel_rounded, size: 18, color: AppTheme.textPrimary),
                const SizedBox(width: 8),
                Text(
                  "Cancel",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              // Execute action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Execute Switch",
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}