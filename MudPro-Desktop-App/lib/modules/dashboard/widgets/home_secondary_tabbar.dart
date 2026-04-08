import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mudpro_desktop_app/modules/company_setup/company_setup_page.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/products_controller.dart';
import 'package:mudpro_desktop_app/modules/daily_report/dailyreport_home_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import '../controller/dashboard_controller.dart';
import '../../options/options_page.dart';

// ── Import controllers needed for save ──
import 'package:mudpro_desktop_app/modules/dashboard/controller/well_general_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/consume_product_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/operation_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/recievemud_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/cased_hole_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/drill_string_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';

// Static well ID — change as needed
class HomeSecondaryTabbar extends StatefulWidget {
  const HomeSecondaryTabbar({super.key});

  @override
  _SecondaryTabBarState createState() => _SecondaryTabBarState();
}

class _SecondaryTabBarState extends State<HomeSecondaryTabbar>
    with TickerProviderStateMixin {
  final DashboardController controller = Get.find<DashboardController>();
  final CompanyController companyController = Get.put(CompanyController());
  final ProductsController productsController =
      Get.put(ProductsController(), tag: 'products_controller');
  final InventorySnapshotController _snapshotController =
      InventorySnapshotController();
  final PadWellController padWellC = padWellContext;

  late AnimationController _animationController;
  int _hoveredIndex = -1;
  TextEditingController _dateController = TextEditingController();

  final List<Map<String, dynamic>> tabs = [
    {"icon": Icons.add_circle_outline},
    {"icon": Icons.folder_open},
    {"icon": Icons.save},
    {"icon": Icons.save_as},
    {"icon": Icons.copy_all},
    {"icon": Icons.insert_drive_file},
    {"icon": Icons.forward},
    {"icon": Icons.lock},
    {"icon": Icons.play_circle_fill},
    {"icon": Icons.settings},
    {"icon": Icons.business},
    {"icon": Icons.upload},
    {"icon": Icons.cloud_upload},
  ];

  final List<String> tooltips = [
    "New Report",
    "Open Folder",
    "Save",
    "Save as",
    "Carry-over pad",
    "New Report",
    "Carry-over",
    "Lock",
    "Calculate",
    "Options",
    "Mud company",
    "Upload",
    "Batch Upload",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _dateController.text = DateFormat('MM/dd/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xffF8FAFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() => Row(
                    children: List.generate(tabs.length, (index) {
                      final isActive =
                          controller.activeSecondaryTab.value == index;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredIndex = index),
                        onExit: (_) => setState(() => _hoveredIndex = -1),
                        child: Tooltip(
                          message: tooltips[index],
                          waitDuration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          child: GestureDetector(
                            onTap: () => _handleTabAction(context, index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.only(left: 2),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? AppTheme.primaryGradient
                                    : _hoveredIndex == index
                                        ? LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor
                                                  .withOpacity(0.15),
                                              AppTheme.primaryColor
                                                  .withOpacity(0.08),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          )
                                        : null,
                                color: isActive || _hoveredIndex == index
                                    ? null
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive
                                      ? AppTheme.primaryColor.withOpacity(0.3)
                                      : _hoveredIndex == index
                                          ? AppTheme.primaryColor
                                              .withOpacity(0.15)
                                          : Colors.transparent,
                                  width: 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : _hoveredIndex == index
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform: Matrix4.identity()
                                  ..scale(
                                      _hoveredIndex == index ? 1.15 : 1.0),
                                child: Icon(
                                  tabs[index]["icon"] as IconData,
                                  size: 16,
                                  color: isActive
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  )),
            ),
          ),

          // Right info fields
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                    color: AppTheme.textSecondary.withOpacity(0.12), width: 1),
              ),
              gradient: const LinearGradient(
                colors: [Color(0xffF1F5F9), Color(0xffE2E8F0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Obx(() => _buildInfoField(
                      "Well",
                      padWellC.selectedWellName.isEmpty
                          ? "No well selected"
                          : padWellC.selectedWellName,
                      Icons.location_on,
                    )),
                const SizedBox(width: 20),
                _buildInfoFieldWithDatePicker("Date", Icons.calendar_today),
                const SizedBox(width: 20),
                _buildInfoField("Report #", "12", Icons.numbers),
                const SizedBox(width: 20),
                _buildInfoField(
                    "MD (ft)", "9055.0", Icons.vertical_align_bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SAVE — hits all APIs in sequence
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _saveAll(BuildContext context) async {
    if (controller.isLocked.value) {
      _showDesktopAlert(context, "Report is locked. Unlock to save.",
          isSuccess: false);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(
                  color: AppTheme.primaryColor, strokeWidth: 2.5),
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Saving...",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text("Saving all data",
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ]),
          ),
        ),
      ),
    );

    final List<String> errorMessages = [];
    final activeTab = controller.activeSectionTab.value;
    String successMessage = "Data saved successfully!";

    try {
      if (activeTab == 0) { // Well Tab
        // ── 1. Save Well General ──────────────────────────────────────────
        final wellGenCtrl = Get.isRegistered<WellGeneralController>() ? Get.find<WellGeneralController>() : null;
        if (wellGenCtrl != null) {
          final res = await wellGenCtrl.save();
          if (res['success'] == true) {
            successMessage = res['message'];
          } else {
            errorMessages.add(res['message'] ?? 'Well General save failed');
          }
        }

        // ── 2. Save Casing ──────────────────────────────────────────────
        final casedCtrl = Get.isRegistered<CasedHoleUIController>() ? Get.find<CasedHoleUIController>() : null;
        if (casedCtrl != null) {
          final res = await casedCtrl.saveAll();
          if (res['success'] == true) {
            successMessage = res['message'];
          } else {
            errorMessages.add(res['message'] ?? 'Casing save failed');
          }
        }

        // ── 3. Save Drill String ──────────────────────────────────────────
        final drillStrCtrl = Get.isRegistered<DrillStringController>() ? Get.find<DrillStringController>() : null;
        if (drillStrCtrl != null) {
          final res = await drillStrCtrl.saveAll();
          if (res['success'] == true) {
            successMessage = res['message'];
          } else {
            errorMessages.add(res['message'] ?? 'Drill String save failed');
          }
        }
      } else if (activeTab == 1) { // Inventory Tab
        final ugCtrl = Get.isRegistered<UgController>() ? Get.find<UgController>() : null;
        if (ugCtrl != null) {
          final res = await ugCtrl.saveInventory();
          if (res['success'] == true) {
            successMessage = res['message'];
          } else {
            errorMessages.add(res['message'] ?? 'Inventory save failed');
          }
        }
      } else if (activeTab == 3) { // Operations Tab
        try {
          final opCtrl = Get.isRegistered<OperationController>() ? Get.find<OperationController>() : null;
          if (opCtrl != null) {
            final selectedOpIndex = opCtrl.selectedRowIndex.value;
            final selectedOp = opCtrl.dropdownValues[selectedOpIndex];
            final authRepo = AuthRepository();

            if (selectedOp == OperationType.consumeProduct) {
              // ── Inventory Snapshot + Product Save ────────────────────────
              final snapResult = await _snapshotController.generateInventorySnapshot();
              if (snapResult['success'] != true) {
                errorMessages.add('Consume Product snapshot: ${snapResult['message'] ?? 'Failed'}');
              }

              if (opCtrl.totalVolume.value > 0) {
                 final tVol = opCtrl.totalVolume.value;
                 final activeWellId = padWellC.selectedWellId.value;
                 if (activeWellId.isEmpty) {
                   errorMessages.add('Operations API: no backend well selected');
                 } else {
                   final res = await authRepo.saveConsumeProductVolumeName({
                      'wellId': activeWellId,
                      'product': 'Water',
                      'volumeBbl': tVol,
                   });
                   if (res['success'] == true) {
                      successMessage = "Operations volume data saved";
                   } else {
                      errorMessages.add('Operations API: ${res['message'] ?? 'Failed'}');
                   }
                 }
              }
            } else if (selectedOp == OperationType.addWater) {
              // ── Add Water ────────────────────────────────────────────────
              final waterRes = await opCtrl.saveAddWater();
              if (waterRes['success'] == true) {
                successMessage = waterRes['message'];
              } else {
                if (waterRes['message'] != 'No new transfers to save' && !waterRes['message'].contains('No new')) {
                  errorMessages.add('Add Water: ${waterRes['message']}');
                }
              }
            } else if (selectedOp == OperationType.transferMud) {
              // ── Transfer Mud ─────────────────────────────────────────────
              final pitCtrl = Get.isRegistered<PitController>() ? Get.find<PitController>() : null;
              if (pitCtrl != null) {
                final res = await pitCtrl.saveTransferMud();
                if (res['success'] == true) {
                  successMessage = res['message'];
                } else {
                  errorMessages.add('Transfer Mud: ${res['message'] ?? 'Failed'}');
                }
              }
            } else if (selectedOp == OperationType.receiveMud) {
              // ── Receive Mud ──────────────────────────────────────────────
              final recieveMudCtrl = Get.isRegistered<ReceiveMudController>() ? Get.find<ReceiveMudController>() : null;
              if (recieveMudCtrl != null) {
                final res = await recieveMudCtrl.saveReceiveMud();
                if (res['success'] == true) {
                  successMessage = res['message'];
                } else {
                  errorMessages.add('Receive Mud: ${res['message'] ?? 'Failed'}');
                }
              }
            }
          }
        } catch (e) {
          errorMessages.add('Operations save error: $e');
        }
      } else if (activeTab == 4) { // Pit Tab
        final pitCtrl = Get.isRegistered<PitController>() ? Get.find<PitController>() : null;
        if (pitCtrl != null) {
          final res = await pitCtrl.saveAllActivePits();
          if (res['success'] == true) {
            successMessage = res['message'];
          } else {
            errorMessages.add(res['message'] ?? 'Pit save failed');
          }
          await pitCtrl.fetchVolumeNameData();
        }
      }
    } finally {
      // Close progress dialog
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (errorMessages.isEmpty) {
      _showDesktopAlert(context, successMessage);
    } else {
      _showDesktopAlert(
        context,
        "Issues found:\n${errorMessages.join('\n')}",
        isSuccess: false,
      );
    }
  }

  // ── Tab handler ───────────────────────────────────────────────────────────
  void _handleTabAction(BuildContext context, int index) async {
    controller.activeSecondaryTab.value = index;
    _playTabAnimation(index);

    switch (index) {
      case 0:
        _createNewReport(context);
        break;
      case 1:
        await _openFolder(context);
        break;
      case 2:
        // ✅ Save button → save all
        await _saveAll(context);
        break;
      case 3:
        await _saveReport(context, true);
        break;
      case 4:
        _carryOverPad(context);
        break;
      case 5:
        _createNewReport(context);
        break;
      case 6:
        _carryOver(context);
        break;
      case 7:
        _toggleLock(context);
        break;
      case 8:
        Get.to(() => DailyReportPage());
        break;
      case 9:
        Get.to(() => OptionsPage());
        break;
      case 10:
        Get.to(() => const CompanySetupPage());
        break;
      case 11:
        await _uploadFile(context);
        break;
      case 12:
        await _batchUpload(context);
        break;
    }
  }

  // ── Info fields ───────────────────────────────────────────────────────────

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 4),
        Obx(() => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (!controller.isLocked.value) {
                    _showEditFieldDialog(context, label, value);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    border: Border.all(
                      color: controller.isLocked.value
                          ? Colors.black.withOpacity(0.1)
                          : AppTheme.primaryColor.withOpacity(0.3),
                      width: controller.isLocked.value ? 0.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1))
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    if (!controller.isLocked.value) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.edit,
                          size: 10, color: AppTheme.primaryColor),
                    ],
                  ]),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildInfoFieldWithDatePicker(String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 4),
        Obx(() => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (!controller.isLocked.value) {
                    _showDatePickerDialog(context, label);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    border: Border.all(
                      color: controller.isLocked.value
                          ? Colors.black.withOpacity(0.1)
                          : AppTheme.primaryColor.withOpacity(0.3),
                      width: controller.isLocked.value ? 0.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1))
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_dateController.text,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    if (!controller.isLocked.value) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.calendar_today,
                          size: 10, color: AppTheme.primaryColor),
                    ],
                  ]),
                ),
              ),
            )),
      ],
    );
  }

  void _showDatePickerDialog(BuildContext context, String label) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
      _showDesktopAlert(context, "$label updated to ${_dateController.text}");
    }
  }

  void _showEditFieldDialog(
      BuildContext context, String label, String currentValue) {
    final TextEditingController textController =
        TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xffF8FAFC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(Icons.edit, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Text("Edit $label",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel",
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDesktopAlert(
                          context, "$label updated successfully");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playTabAnimation(int index) {
    final AnimationController animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    animationController.forward().then((_) {
      animationController.reverse().then((_) {
        animationController.dispose();
      });
    });
  }

  void _showDesktopAlert(BuildContext context, String message,
      {bool isSuccess = true}) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: 20,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutBack,
            constraints:
                const BoxConstraints(maxWidth: 350, minWidth: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSuccess
                    ? [const Color(0xff38B2AC), const Color(0xff319795)]
                    : [const Color(0xffFC8181), const Color(0xffF56565)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close,
                    size: 16, color: Colors.white.withOpacity(0.8)),
                onPressed: () => overlayEntry.remove(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  Future<void> _generateDailyInventoryExcel(BuildContext context) async {
    try {
      _showUploadProgress(context, "Generating Daily Inventory Report...");
      await companyController.fetchCompanyDetails();
      final company = companyController.company.value;
      if (company == null) {
        Navigator.pop(context);
        _showDesktopAlert(context, "Company data not found", isSuccess: false);
        return;
      }
      await productsController.loadProducts();
      var excel = Excel.createExcel();
      excel.delete('Sheet1');
      var sheet = excel['Inventory'];
      sheet.setColWidth(0, 20);
      sheet.setColWidth(1, 12);
      if (Navigator.canPop(context)) Navigator.pop(context);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = "${dir.path}/Daily_Inventory_$timestamp.xlsx";
      var fileBytes = excel.encode();
      if (fileBytes == null) {
        _showDesktopAlert(context, "Failed to generate Excel file",
            isSuccess: false);
        return;
      }
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      await OpenFilex.open(filePath);
      _showDesktopAlert(context, "Excel file generated successfully!");
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showDesktopAlert(context, "Failed to generate Excel: $e",
          isSuccess: false);
    }
  }

  void _setCellValue(Sheet sheet, String cellAddress, String value,
      {bool bold = false,
      int fontSize = 10,
      String? bgColor,
      bool isNumber = false}) {
    var cell = sheet.cell(CellIndex.indexByString(cellAddress));
    if (isNumber && value.isNotEmpty) {
      final numValue = double.tryParse(value);
      cell.value = numValue ?? value;
    } else {
      cell.value = value;
    }
    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  void _createNewReport(BuildContext context) {
    final TextEditingController wellNameController = TextEditingController();
    final TextEditingController reportNumberController =
        TextEditingController();
    final TextEditingController dateController =
        TextEditingController(text: DateFormat('MM/dd/yyyy').format(DateTime.now()));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xffF8FAFC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text("Create New Report",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  _buildFormField(
                      "Well Name", Icons.location_on, wellNameController),
                  const SizedBox(height: 16),
                  _buildFormField(
                      "Report Number", Icons.numbers, reportNumberController),
                  const SizedBox(height: 16),
                  _buildDateField(
                      "Date", Icons.calendar_today, dateController, context),
                ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Colors.black.withOpacity(0.1)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel",
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (wellNameController.text.isEmpty ||
                            reportNumberController.text.isEmpty) {
                          _showDesktopAlert(context, "Please fill all fields",
                              isSuccess: false);
                          return;
                        }
                        _generateReportOnSystem(wellNameController.text,
                            reportNumberController.text, dateController.text);
                        Navigator.pop(context);
                        _showDesktopAlert(
                            context, "New report created successfully");
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Create"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
      String label, IconData icon, TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primaryColor),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ),
    ]);
  }

  Widget _buildDateField(String label, IconData icon,
      TextEditingController controller, BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                    primary: AppTheme.primaryColor, onPrimary: Colors.white),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            controller.text = DateFormat('MM/dd/yyyy').format(picked);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withOpacity(0.1)),
          ),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(icon, size: 18, color: AppTheme.primaryColor),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: false,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    hintText: 'Select date'),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Future<void> _openFolder(BuildContext context) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select MudPro Reports Folder',
      );
      if (selectedDirectory != null) {
        final directory = Directory(selectedDirectory);
        if (await directory.exists()) {
          final files = directory.listSync();
          _showFilesDialog(context, files, selectedDirectory);
        } else {
          _showDesktopAlert(context, "Folder does not exist", isSuccess: false);
        }
      }
    } catch (e) {
      _showDesktopAlert(context, "Failed to open folder: $e", isSuccess: false);
    }
  }

  void _showFilesDialog(BuildContext context, List<FileSystemEntity> files,
      String folderPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                const Icon(Icons.folder_open, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(folderPath,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis)),
              ]),
            ),
            Expanded(
                child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final isDir = file is Directory;
                final name = file.path.split(Platform.pathSeparator).last;
                return ListTile(
                  leading: Icon(
                      isDir ? Icons.folder : Icons.insert_drive_file,
                      color:
                          isDir ? Colors.orange : AppTheme.primaryColor),
                  title: Text(name, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(isDir ? "Folder" : "File",
                      style: const TextStyle(fontSize: 10)),
                );
              },
            )),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Close"),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _saveReport(BuildContext context, bool saveAs) async {
    try {
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: saveAs ? 'Save Report As' : 'Save Report',
        fileName:
            'mudpro_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );
      if (filePath != null) {
        final reportData = {
          'well': padWellC.selectedWellName,
          'wellId': padWellC.selectedWellId.value,
          'date': _dateController.text,
          'reportNumber': '12',
          'md': '9055.0',
          'timestamp': DateTime.now().toIso8601String(),
        };
        final file = File(filePath);
        await file.writeAsString(jsonEncode(reportData));
        _showDesktopAlert(context, "Report saved successfully");
      }
    } catch (e) {
      _showDesktopAlert(context, "Failed to save report: $e", isSuccess: false);
    }
  }

  Future<Directory> getDocumentsDirectory() async {
    if (Platform.isWindows) {
      return Directory(path.join(
          Platform.environment['USERPROFILE']!, 'Documents', 'MudPro Reports'));
    } else if (Platform.isMacOS || Platform.isLinux) {
      return Directory(path.join(
          Platform.environment['HOME']!, 'Documents', 'MudPro Reports'));
    } else {
      return Directory.current;
    }
  }

  void _generateReportOnSystem(
      String wellName, String reportNumber, String date) async {
    try {
      final reportsDir = await getDocumentsDirectory();
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      final reportFile = File(path.join(
        reportsDir.path,
        '${wellName.replaceAll(' ', '_')}_${reportNumber}_${date.replaceAll('/', '-')}.json',
      ));
      await reportFile.writeAsString(jsonEncode(
          {'wellName': wellName, 'reportNumber': reportNumber, 'date': date}));
    } catch (e) {
      debugPrint('Error generating report: $e');
    }
  }

  void _carryOverPad(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Carry-over Pad"),
        content: const Text(
            "This will copy all current pad data to a new report. Continue?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDesktopAlert(context, "Pad data carried over successfully");
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: Colors.white),
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _carryOver(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Carry-over Report"),
        content: const Text(
            "This will carry selected data to the next report."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDesktopAlert(context, "Data carried over successfully");
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: Colors.white),
            child: const Text("Carry Over"),
          ),
        ],
      ),
    );
  }

  void _toggleLock(BuildContext context) {
    controller.toggleLock();
    _showDesktopAlert(
      context,
      controller.isLocked.value
          ? "Report locked for editing"
          : "Report unlocked for editing",
    );
  }

  Future<void> _uploadFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt', 'xlsx'],
        allowMultiple: false,
      );
      if (result != null) {
        final file = result.files.first;
        _showUploadProgress(context, file.name);
        await Future.delayed(const Duration(seconds: 1));
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showDesktopAlert(context, "File '${file.name}' uploaded successfully");
      }
    } catch (e) {
      _showDesktopAlert(context, "Failed to upload: $e", isSuccess: false);
    }
  }

  void _showUploadProgress(BuildContext context, String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: AppTheme.successColor),
            const SizedBox(height: 16),
            Text(fileName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            const Text("Processing...",
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
      ),
    );
  }

  Future<void> _batchUpload(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt', 'xlsx'],
      );
      if (result != null) {
        _showUploadProgress(context, "${result.files.length} files");
        await Future.delayed(const Duration(seconds: 1));
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showDesktopAlert(
            context, "${result.files.length} files uploaded successfully");
      }
    } catch (e) {
      _showDesktopAlert(context, "Batch upload failed: $e", isSuccess: false);
    }
  }
}

class ExcelColor {
  static const String green = 'FF00FF00';
  static const String lightGreen = 'FF90EE90';
  static const String gray = 'FF808080';
  static const String gray25 = 'FFC0C0C0';
  static const String lightGray = 'FFD3D3D3';
}
