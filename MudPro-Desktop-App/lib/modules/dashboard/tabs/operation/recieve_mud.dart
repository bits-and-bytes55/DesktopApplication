import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/recievemud_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReceiveMudView extends StatelessWidget {
  ReceiveMudView({super.key});

  final ReceiveMudController controller = Get.put(ReceiveMudController());
  final DashboardController dashboardController = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          const SizedBox(height: 16),
          
          // Main Content - Compressed width
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Form (compressed)
              Container(
                width: 450, // Fixed compressed width
                child: _buildFormSection(),
              ),
              
              Expanded(child: SizedBox()), // Spacer to push everything left
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Receive Mud',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
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
          // BOL No
          _buildBolSection(),
          
          Divider(height: 1, color: Colors.grey.shade300),
          
          // Data Table
          _buildDataTable(),
          
          Divider(height: 1, color: Colors.grey.shade300),
          
          // Loss Volume Section (below table)
          _buildLossVolumeSection(),
        ],
      ),
    );
  }

  Widget _buildBolSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 70,
            child: Text(
              'BOL. No.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Obx(() => TextField(
              controller: controller.bolNoController,
              enabled: !dashboardController.isLocked.value,
              style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(3),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                filled: true,
                fillColor: dashboardController.isLocked.value 
                    ? Colors.grey.shade100 
                    : Colors.white,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        );
      }

      return Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
          verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        columnWidths: const {
          0: FixedColumnWidth(100),
          1: FlexColumnWidth(2),
          2: FixedColumnWidth(70),
        },
        children: [
          // Premixed Mud Row
          _buildPremixedMudRow(),
          
          // Dynamic rows from selected premixed mud
          if (controller.selectedPremixed.value != null) ...[
            _buildTableRow('MW', controller.selectedPremixed.value!.mw, AppUnits.displayUnit('33', fallback: '(ppg)')),
            _buildTableRow('Mud Type', controller.selectedPremixed.value!.mudType, ''),
            _buildTableRow('Leasing Fee', controller.selectedPremixed.value!.leasingFee, '(kwd/bbl)'),
          ],
          
          // From (Pit Dropdown)
          _buildFromPitRow(),
          
          // To (Manual Input)
          _buildEditableRow('To', controller.toController, ''),
          
          // Vol. (Manual Input)
          _buildEditableRow('Vol.', controller.volController, AppUnits.displayUnit('6', fallback: '(bbl)')),
          
          // Leased Checkbox
          _buildLeasedRow(),
        ],
      );
    });
  }

  TableRow _buildPremixedMudRow() {
    return TableRow(
      children: [
        _buildLabelCell('Premixed Mud'),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Obx(() => Container(
            height: 30,
            decoration: BoxDecoration(
              color: dashboardController.isLocked.value 
                  ? Colors.grey.shade100 
                  : Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(3),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedPremixedId.value.isEmpty 
                    ? null 
                    : controller.selectedPremixedId.value,
                hint: Text(
                  'Select',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                isExpanded: true,
                isDense: true,
                icon: Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade700),
                style: TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                dropdownColor: Colors.white,
                items: controller.premixedList.map((premixed) {
                  return DropdownMenuItem<String>(
                    value: premixed.id,
                    child: Text(
                      premixed.description,
                      style: TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: dashboardController.isLocked.value 
                    ? null 
                    : (value) {
                        if (value != null) {
                          controller.selectPremixed(value);
                        }
                      },
                padding: EdgeInsets.symmetric(horizontal: 8),
                menuMaxHeight: 200,
              ),
            ),
          )),
        ),
        _buildUnitCell(''),
      ],
    );
  }

  TableRow _buildFromPitRow() {
    return TableRow(
      children: [
        _buildLabelCell('From'),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Obx(() => Container(
            height: 30,
            decoration: BoxDecoration(
              color: dashboardController.isLocked.value 
                  ? Colors.grey.shade100 
                  : Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(3),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedPitId.value.isEmpty 
                    ? null 
                    : controller.selectedPitId.value,
                hint: Text(
                  'Select Pit',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                isExpanded: true,
                isDense: true,
                icon: Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade700),
                style: TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                dropdownColor: Colors.white,
                items: controller.pitController.pits.map((pit) {
                  return DropdownMenuItem<String>(
                    value: pit.id,
                    child: Text(
                      pit.pitName,
                      style: TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: dashboardController.isLocked.value 
                    ? null 
                    : (value) {
                        if (value != null) {
                          controller.selectPit(value);
                        }
                      },
                padding: EdgeInsets.symmetric(horizontal: 8),
                menuMaxHeight: 200,
              ),
            ),
          )),
        ),
        _buildUnitCell(''),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value, String unit) {
    return TableRow(
      children: [
        _buildLabelCell(label),
        _buildValueCell(value),
        _buildUnitCell(unit),
      ],
    );
  }

  TableRow _buildEditableRow(String label, TextEditingController controller, String unit) {
    return TableRow(
      children: [
        _buildLabelCell(label),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Obx(() => TextField(
            controller: controller,
            enabled: !dashboardController.isLocked.value,
            style: TextStyle(fontSize: 11, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(3),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(3),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              filled: true,
              fillColor: dashboardController.isLocked.value 
                  ? Colors.grey.shade100 
                  : Colors.white,
            ),
          )),
        ),
        _buildUnitCell(unit),
      ],
    );
  }

  TableRow _buildLeasedRow() {
    return TableRow(
      children: [
        _buildLabelCell('Leased'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Obx(() => Row(
            children: [
              Transform.scale(
                scale: 0.85,
                child: Checkbox(
                  value: controller.isLeased.value,
                  onChanged: dashboardController.isLocked.value 
                      ? null 
                      : (value) {
                          controller.isLeased.value = value ?? false;
                        },
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          )),
        ),
        _buildUnitCell(''),
      ],
    );
  }

  Widget _buildLabelCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: Colors.grey.shade50,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildValueCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: Colors.white,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildUnitCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: Colors.grey.shade50,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLossVolumeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Obx(() => Row(
            children: [
              Transform.scale(
                scale: 0.85,
                child: Checkbox(
                  value: controller.hasLossVolume.value,
                  onChanged: dashboardController.isLocked.value 
                      ? null 
                      : (value) {
                          controller.hasLossVolume.value = value ?? false;
                        },
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Loss Volume',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          )),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Obx(() => TextField(
              controller: controller.lossVolumeController,
              enabled: !dashboardController.isLocked.value && controller.hasLossVolume.value,
              style: TextStyle(fontSize: 11, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(3),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(3),
                ),
                filled: true,
                fillColor: !controller.hasLossVolume.value || dashboardController.isLocked.value
                    ? Colors.grey.shade100 
                    : Colors.white,
                suffixText: AppUnits.displayUnit('6', fallback: '(bbl)'),
                suffixStyle: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}
