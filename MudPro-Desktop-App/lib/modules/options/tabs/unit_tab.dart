import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/tabs/unit_customization_popup.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

import '../model/unit_system_model.dart';

class UnitRightPanel extends StatefulWidget {
  const UnitRightPanel({super.key});

  @override
  State<UnitRightPanel> createState() => _UnitRightPanelState();
}

class _UnitRightPanelState extends State<UnitRightPanel> {
  final ScrollController _scrollController = ScrollController();

  // Store which dropdown is open
  final List<GlobalKey> _dropdownKeys = List.generate(49, (index) => GlobalKey());

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OptionsController>();

    return Container(
      color: Colors.white,
      child: Obx(() {
        const selectedTab = 0; // Fixed for this tab
        final unitSystem = controller.unitSystem.value;
        final customSystem = controller.selectedCustomSystem.value;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unit System Selection Card - Smaller
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit System',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Smaller Radio Buttons
                      Row(
                        children: [
                          _radio(controller, UnitSystem.us, 'US Oil Field'),
                          const SizedBox(width: 8),
                          _radio(controller, UnitSystem.si, 'SI'),
                          const SizedBox(width: 8),
                          _radio(controller, UnitSystem.customized, 'Customized'),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Custom System Controls - Only Dropdown and Button
                      if (unitSystem == UnitSystem.customized)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Dropdown only
                                SizedBox(
                                  width: 220,
                                  child: DropdownButtonFormField<String>(
                                    value: controller.unitSystemNames.contains(customSystem) ? customSystem : (controller.unitSystemNames.isNotEmpty ? controller.unitSystemNames.first : null),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Select Template',
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    onChanged: unitSystem == UnitSystem.customized
                                        ? (v) => controller.selectUnitSystemByName(v!)
                                        : null,
                                    items: controller.unitSystemNames.map((name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name, style: const TextStyle(fontSize: 13)),
                                    )).toList(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Button for customization popup
                                ElevatedButton.icon(
                                  onPressed: (){
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const UnitSystemCustomizationPopup(),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 1,
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text(
                                    'Customize',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Click customize to modify unit system',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Parameters Table - Smaller and takes half width
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        // Table Header with 3 columns - Smaller
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  'No.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Parameter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:  Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'Unit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Scrollable Table - Smaller rows
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              itemCount: OptionsController.parameters.length,
                              itemBuilder: (context, index) {
                                final parameter = OptionsController.parameters[index];
                                final isEven = index % 2 == 0;
                                
                                return Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isEven ? Colors.white : Colors.grey.shade50,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Column 1: Number
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          parameter['number']!,
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Column 2: Parameter Name
                                      Expanded(
                                        child: Text(
                                          parameter['name']!,
                                          style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Column 3: Unit
                                      SizedBox(
                                        width: 140,
                                        child: unitSystem == UnitSystem.customized
                                            // Custom Dropdown Menu - Opens below row
                                            ? _buildCustomDropdown(index, controller)
                                            // Normal unit display for US and SI
                                            : Container(
                                                height: 32,
                                                alignment: Alignment.centerLeft,
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  controller.getUnit(index),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Custom dropdown that opens below the row
  Widget _buildCustomDropdown(int index, OptionsController controller) {
    final number = OptionsController.parameters[index]['number']!;
    final unitOptions = controller.getUnitsForParam(number);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: PopupMenuButton<String>(
        key: _dropdownKeys[index],
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(maxHeight: 250, minWidth: 140),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        onSelected: (String newValue) {
          controller.onUnitChanged(
            systemId: controller.selectedCustomSystemId.value,
            paramNumber: number,
            newUnit: newValue,
          );
        },
        itemBuilder: (BuildContext context) {
          return unitOptions.map<PopupMenuEntry<String>>((String unit) {
            return PopupMenuItem<String>(
              value: unit,
              height: 36,
              child: Text(unit, style: const TextStyle(fontSize: 12)),
            );
          }).toList();
        },
        child: Obx(() {
          final currentValue = controller.customUnits[number] ?? '';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    currentValue.isEmpty ? '-' : currentValue,
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _radio(OptionsController controller, UnitSystem value, String label) {
    return Expanded(
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: controller.unitSystem.value == value 
                ? AppTheme.primaryColor 
                : Colors.grey.shade300,
            width: controller.unitSystem.value == value ? 1.5 : 1,
          ),
          color: controller.unitSystem.value == value 
              ? AppTheme.primaryColor.withOpacity(0.05)
              : Colors.white,
        ),
        child: InkWell(
          onTap: () => controller.unitSystem.value = value,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: controller.unitSystem.value == value 
                          ? AppTheme.primaryColor 
                          : Colors.grey.shade400,
                      width: controller.unitSystem.value == value ? 1.5 : 1,
                    ),
                  ),
                  child: controller.unitSystem.value == value
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: controller.unitSystem.value == value 
                        ? AppTheme.primaryColor 
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}