import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class TransferMudView extends StatefulWidget {
  const TransferMudView({super.key});

  @override
  State<TransferMudView> createState() => _TransferMudViewState();
}

class _TransferMudViewState extends State<TransferMudView> {
  final DashboardController dashboardController = Get.find<DashboardController>();
  final PitController pitController = Get.put(PitController());

  // Data lists
  final RxList<PitModel> pits = <PitModel>[].obs;

  // Row data for the table
  final RxList<TransferRowData> transferRows = <TransferRowData>[].obs;

  // Selected row index
  final RxInt selectedRow = 0.obs;

  // From dropdown selection
  final Rx<PitModel?> selectedFromPit = Rx<PitModel?>(null);

  // Not Treated Mud checkbox
  final RxBool notTreatedMud = false.obs;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Initialize with 5 empty rows
    for (int i = 0; i < 5; i++) {
      transferRows.add(TransferRowData());
    }
  }

  Future<void> _loadData() async {
    try {
      await pitController.fetchAllPits();
      pits.value = pitController.pits.where((pit) => pit.id != null).toList();
      
      // Set first pit as default in "From" dropdown if available
      if (pits.isNotEmpty) {
        selectedFromPit.value = pits.first;
      }
    } catch (e) {
      print("Error loading pits: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // From Section
              _buildFromSection(),
              const SizedBox(height: 12),

              // Not Treated Mud Checkbox
              _buildNotTreatedSection(),
              const SizedBox(height: 16),

              // Transfer Table
              _buildTransferTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFromSection() {
    return Row(
      children: [
        Text(
          "From",
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180,
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Obx(() => DropdownButtonHideUnderline(
              child: DropdownButton<PitModel>(
                value: selectedFromPit.value,
                isExpanded: true,
                isDense: true,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "Select pit",
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppTheme.textPrimary,
                ),
                menuMaxHeight: 200,
                items: pits.map((pit) {
                  return DropdownMenuItem<PitModel>(
                    value: pit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        pit.pitName,
                        style: AppTheme.bodySmall.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: dashboardController.isLocked.value
                    ? null
                    : (PitModel? value) {
                        selectedFromPit.value = value;
                      },
              ),
            )),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Icon(
            Icons.settings,
            size: 14,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNotTreatedSection() {
    return Obx(() => Row(
      children: [
        InkWell(
          onTap: dashboardController.isLocked.value
              ? null
              : () {
                  notTreatedMud.value = !notTreatedMud.value;
                },
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              border: Border.all(
                color: notTreatedMud.value
                    ? AppTheme.primaryColor
                    : Colors.grey.shade400,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(3),
              color: notTreatedMud.value
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: notTreatedMud.value
                ? Icon(
                    Icons.check,
                    size: 12,
                    color: AppTheme.primaryColor,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "Not Treated Mud",
          style: AppTheme.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ));
  }

  Widget _buildTransferTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table with fixed height
          SizedBox(
            height: 250, // Fixed height for the table
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 500, // Fixed width for 3 columns
                child: Column(
                  children: [
                    // Table Header - Fixed
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildHeaderCell("No", 50),
                          _buildHeaderCell("Pit", 300),
                          _buildHeaderCell("Vol. (bbl)", 150),
                        ],
                      ),
                    ),

                    // Table Rows - Scrollable
                    Expanded(
                      child: Obx(() => SingleChildScrollView(
                        child: Column(
                          children: List.generate(transferRows.length, (index) {
                            final row = transferRows[index];
                            final isSelected = selectedRow.value == index;

                            return Container(
                              decoration: BoxDecoration(
                                color: index % 2 == 0
                                    ? Colors.white
                                    : Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.shade200, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Number cell
                                  _buildNumberCell(index + 1, 50),
                                  // Pit dropdown cell
                                  _buildPitDropdownCell(row, index, isSelected, 300),
                                  // Volume cell
                                  _buildVolumeCell(row, 150),
                                ],
                              ),
                            );
                          }),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPitDropdownCell(
      TransferRowData row, int index, bool isSelected, double width) {
    return GestureDetector(
      onTap: () => selectedRow.value = index,
      child: Container(
        width: width,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Dropdown icon
            Icon(
              isSelected ? Icons.arrow_drop_down : Icons.arrow_right,
              size: 16,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),

            // Dropdown
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PitModel>(
                  value: row.selectedPit,
                  hint: Text(
                    "",
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  isExpanded: true,
                  isDense: true,
                  icon: const SizedBox.shrink(),
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppTheme.textPrimary,
                  ),
                  menuMaxHeight: 250,
                  items: pits.map((pit) {
                    return DropdownMenuItem<PitModel>(
                      value: pit,
                      child: Text(
                        pit.pitName,
                        style: AppTheme.bodySmall.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: dashboardController.isLocked.value
                      ? null
                      : (PitModel? value) {
                          if (value != null) {
                            selectedRow.value = index;
                            row.selectedPit = value;
                            transferRows.refresh();
                            _checkAndAddRow();
                          }
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberCell(int number, double width) {
    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: AppTheme.bodySmall.copyWith(fontSize: 10),
      ),
    );
  }

  Widget _buildVolumeCell(TransferRowData row, double width) {
    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: TextField(
        controller: TextEditingController(text: row.volume),
        enabled: !dashboardController.isLocked.value,
        style: AppTheme.bodySmall.copyWith(fontSize: 10),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          border: InputBorder.none,
        ),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.right,
        onChanged: (val) {
          row.volume = val;
        },
      ),
    );
  }

  void _checkAndAddRow() {
    if (transferRows.length >= 5) {
      final lastRow = transferRows.last;
      if (lastRow.selectedPit != null) {
        transferRows.add(TransferRowData());
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Row data class
class TransferRowData {
  PitModel? selectedPit;
  String volume = '';
}