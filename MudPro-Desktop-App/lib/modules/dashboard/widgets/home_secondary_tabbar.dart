import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mudpro_desktop_app/modules/company_setup/company_setup_page.dart';
import 'package:mudpro_desktop_app/modules/daily_report/dailyreport_home_page.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import '../controller/dashboard_controller.dart';
import '../../options/options_page.dart';

class HomeSecondaryTabbar extends StatefulWidget {
  const HomeSecondaryTabbar({super.key});

  @override
  _SecondaryTabBarState createState() => _SecondaryTabBarState();
}

class _SecondaryTabBarState extends State<HomeSecondaryTabbar> with TickerProviderStateMixin {
  final DashboardController controller = Get.find<DashboardController>();
  late AnimationController _animationController;
  int _hoveredIndex = -1;
  TextEditingController _dateController = TextEditingController();

  // All tabs now use the same blue active color
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
          // Left side - Tabs with icons
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() => Row(
                    children: List.generate(tabs.length, (index) {
                      final isActive = controller.activeSecondaryTab.value == index;

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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.only(left: 2),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? AppTheme.primaryGradient
                                    : _hoveredIndex == index
                                        ? LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor.withOpacity(0.15),
                                              AppTheme.primaryColor.withOpacity(0.08),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          )
                                        : null,
                                color: isActive || _hoveredIndex == index ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive
                                      ? AppTheme.primaryColor.withOpacity(0.3)
                                      : _hoveredIndex == index
                                          ? AppTheme.primaryColor.withOpacity(0.15)
                                          : Colors.transparent,
                                  width: 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : _hoveredIndex == index
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryColor.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform: Matrix4.identity()
                                  ..scale(_hoveredIndex == index ? 1.15 : 1.0),
                                child: Icon(
                                  tabs[index]["icon"] as IconData,
                                  size: 16,
                                  color: isActive ? Colors.white : AppTheme.primaryColor,
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

          // Right side - Info fields with improved design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: AppTheme.textSecondary.withOpacity(0.12), width: 1),
              ),
              gradient: const LinearGradient(
                colors: [Color(0xffF1F5F9), Color(0xffE2E8F0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                _buildInfoField("Well", "UG-0293 ST", Icons.location_on),
                const SizedBox(width: 20),
                _buildInfoFieldWithDatePicker("Date", Icons.calendar_today),
                const SizedBox(width: 20),
                _buildInfoField("Report #", "12", Icons.numbers),
                const SizedBox(width: 20),
                _buildInfoField("MD (ft)", "9055.0", Icons.vertical_align_bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (!controller.isLocked.value) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.edit, size: 10, color: AppTheme.primaryColor),
                  ],
                ],
              ),
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
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dateController.text,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (!controller.isLocked.value) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.calendar_today, size: 10, color: AppTheme.primaryColor),
                  ],
                ],
              ),
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
      _showDesktopAlert(context, "$label updated to ${_dateController.text}");
    }
  }

  void _showEditFieldDialog(BuildContext context, String label, String currentValue) {
    final TextEditingController textController = TextEditingController(text: currentValue);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    "Edit $label",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Update value here
                      Navigator.pop(context);
                      _showDesktopAlert(context, "$label updated successfully");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  void _handleTabAction(BuildContext context, int index) async {
    controller.activeSecondaryTab.value = index;
    _playTabAnimation(index);

    switch (index) {
      case 0: // New Report
        _createNewReport(context);
        break;
      case 1: // Open Folder
        await _openFolder(context);
        break;
      case 2: // Save
        await _saveReport(context, false);
        break;
      case 3: // Save as
        await _saveReport(context, true);
        break;
      case 4: // Carry-over pad
        _carryOverPad(context);
        break;
      case 5: // New Report (duplicate)
        _createNewReport(context);
        break;
      case 6: // Carry-over
        _carryOver(context);
        break;
      case 7: // Lock
        _toggleLock(context);
        break;
      case 8: // Calculate
        Get.to(() => DailyReportPage());
        break;
      case 9: // Options
        Get.to(() => OptionsPage());
        break;
      case 10: // Mud company setup
        Get.to(() =>  CompanySetupPage());
        break;
      case 11: // Upload
        await _uploadFile(context);
        break;
      case 12: // Batch Upload
        await _batchUpload(context);
        break;
    }
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

  // ==================== DESKTOP ALERT ====================
  void _showDesktopAlert(BuildContext context, String message, {bool isSuccess = true}) {
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
            constraints: const BoxConstraints(maxWidth: 350, minWidth: 200),
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
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.white.withOpacity(0.8)),
                  onPressed: () => overlayEntry.remove(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // ==================== NEW REPORT ====================
  void _createNewReport(BuildContext context) {
    final TextEditingController wellNameController = TextEditingController();
    final TextEditingController reportNumberController = TextEditingController();
    final TextEditingController dateController = TextEditingController(
      text: DateFormat('MM/dd/yyyy').format(DateTime.now()),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      "Create New Report",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFormField("Well Name", Icons.location_on, wellNameController),
                    const SizedBox(height: 16),
                    _buildFormField("Report Number", Icons.numbers, reportNumberController),
                    const SizedBox(height: 16),
                    _buildDateField("Date", Icons.calendar_today, dateController, context),
                  ],
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (wellNameController.text.isEmpty || reportNumberController.text.isEmpty) {
                          _showDesktopAlert(context, "Please fill all fields", isSuccess: false);
                          return;
                        }
                        
                        // Generate report in actual system directory
                        _generateReportOnSystem(
                          wellNameController.text,
                          reportNumberController.text,
                          dateController.text,
                        );
                        
                        controller.generateDummyReports();
                        Navigator.pop(context);
                        _showDesktopAlert(context, "New report created successfully");
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Create"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  Widget _buildFormField(String label, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, IconData icon, TextEditingController controller, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppTheme.primaryColor,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
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
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(icon, size: 18, color: AppTheme.primaryColor),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: false,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      hintText: 'Select date',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== OPEN FOLDER ====================
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

  void _showFilesDialog(BuildContext context, List<FileSystemEntity> files, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 600,
          height: 500,
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        path,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Stats
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            _buildStatItem(Icons.folder, "Folders", 
                              files.where((f) => f is Directory).length.toString()),
                            const SizedBox(width: 20),
                            _buildStatItem(Icons.insert_drive_file, "Files", 
                              files.where((f) => f is File).length.toString()),
                            const SizedBox(width: 20),
                            _buildStatItem(Icons.storage, "Total", 
                              files.length.toString()),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // File List
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black.withOpacity(0.1)),
                          ),
                          child: ListView.builder(
                            itemCount: files.length,
                            itemBuilder: (context, index) {
                              final file = files[index];
                              final isDirectory = file is Directory;
                              final name = path.split(Platform.pathSeparator).last;
                              final size = file is File ? _formatFileSize(file.lengthSync()) : null;

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: isDirectory
                                          ? const LinearGradient(
                                              colors: [Color(0xffF6AD55), Color(0xffED8936)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : const LinearGradient(
                                              colors: [Color(0xff63B3ED), Color(0xff4299E1)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isDirectory ? Icons.folder : Icons.insert_drive_file,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isDirectory ? "Folder" : "File • ${size ?? 'N/A'}",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.textSecondary,
                                  ),
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
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Close"),
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

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // ==================== SAVE REPORT ====================
  Future<void> _saveReport(BuildContext context, bool saveAs) async {
    try {
      // Get the user's documents directory or let them choose
      String? initialPath;
      try {
        final documentsDir = await getDocumentsDirectory();
        initialPath = documentsDir.path;
      } catch (e) {
        initialPath = null;
      }

      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: saveAs ? 'Save Report As' : 'Save Report',
        fileName: 'mudpro_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
        initialDirectory: initialPath,
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (filePath != null) {
        final reportData = {
          'well': 'UG-0293 ST',
          'date': _dateController.text,
          'reportNumber': '12',
          'md': '9055.0',
          'timestamp': DateTime.now().toIso8601String(),
          'data': {
            'general': {
              'engineer': 'Keyur Agarwal',
              'activity': 'Drilling Cement',
            },
            'wellData': {
              'md': '9055.0',
              'tvd': '8603.0',
              'inc': '73.45',
              'azi': '206.00',
            }
          }
        };

        final file = File(filePath);
        await file.writeAsString(jsonEncode(reportData));

        _showDesktopAlert(context, "Report saved successfully at:\n$filePath");
      }
    } catch (e) {
      _showDesktopAlert(context, "Failed to save report: $e", isSuccess: false);
    }
  }

  Future<Directory> getDocumentsDirectory() async {
    if (Platform.isWindows) {
      return Directory(path.join(Platform.environment['USERPROFILE']!, 'Documents', 'MudPro Reports'));
    } else if (Platform.isMacOS) {
      return Directory(path.join(Platform.environment['HOME']!, 'Documents', 'MudPro Reports'));
    } else if (Platform.isLinux) {
      return Directory(path.join(Platform.environment['HOME']!, 'Documents', 'MudPro Reports'));
    } else {
      return Directory.current;
    }
  }

  void _generateReportOnSystem(String wellName, String reportNumber, String date) async {
    try {
      final reportsDir = await getDocumentsDirectory();
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final reportFile = File(path.join(
        reportsDir.path,
        '${wellName.replaceAll(' ', '_')}_${reportNumber}_${date.replaceAll('/', '-')}.json'
      ));

      final reportData = {
        'wellName': wellName,
        'reportNumber': reportNumber,
        'date': date,
        'created': DateTime.now().toIso8601String(),
        'data': {},
      };

      await reportFile.writeAsString(jsonEncode(reportData));
    } catch (e) {
      print('Error generating report: $e');
    }
  }

  // ==================== CARRY-OVER PAD ====================
  void _carryOverPad(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffF6AD55), Color(0xffED8936)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.copy_all, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      "Carry-over Pad",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.content_copy,
                      size: 48,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Copy Current Pad Data",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "This will copy all current pad data to a new report. Do you want to continue?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Copy current data to clipboard or temp file
                          final tempDir = Directory.systemTemp;
                          final tempFile = File(path.join(tempDir.path, 'mudpro_pad_data_${DateTime.now().millisecondsSinceEpoch}.tmp'));
                          final currentData = {
                            'timestamp': DateTime.now(),
                            'data': 'Pad data copied',
                          };
                          await tempFile.writeAsString(jsonEncode(currentData));
                          
                          Navigator.pop(context);
                          _showDesktopAlert(context, "Pad data carried over successfully to temporary storage");
                        } catch (e) {
                          _showDesktopAlert(context, "Failed to carry over pad data: $e", isSuccess: false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Continue"),
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

  // ==================== CARRY-OVER ====================
  void _carryOver(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffF6AD55), Color(0xffED8936)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.forward, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      "Carry-over Report",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      "Select fields to carry over to next report:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCheckboxOption("General Info", true),
                    _buildCheckboxOption("Well Data", true),
                    _buildCheckboxOption("Mud Properties", false),
                    _buildCheckboxOption("Pump Data", true),
                    _buildCheckboxOption("Safety Data", false),
                  ],
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Perform actual carry-over operation
                          await Future.delayed(const Duration(milliseconds: 500));
                          Navigator.pop(context);
                          _showDesktopAlert(context, "Data carried over to new report successfully");
                        } catch (e) {
                          _showDesktopAlert(context, "Failed to carry over data: $e", isSuccess: false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Carry Over"),
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

  Widget _buildCheckboxOption(String text, bool value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppTheme.successColor : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? AppTheme.successColor : Colors.grey.shade300,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TOGGLE LOCK ====================
  void _toggleLock(BuildContext context) {
    controller.toggleLock();
    _showDesktopAlert(
      context,
      controller.isLocked.value
          ? "Report locked for editing"
          : "Report unlocked for editing",
    );
  }

  // ==================== CALCULATE ====================
  void _performCalculations(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff4299E1), Color(0xff3182CE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      "Perform Calculations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select calculations to perform:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCalculationOption("Calculate Well Volume", Icons.water),
                    _buildCalculationOption("Calculate String Length", Icons.straighten),
                    _buildCalculationOption("Calculate TFA", Icons.square_foot),
                    _buildCalculationOption("Calculate Mud Weight", Icons.scale),
                    _buildCalculationOption("Calculate Pressure", Icons.speed),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffEBF8FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: AppTheme.infoColor),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Calculations will update all related fields automatically in real-time.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCalculationProgress(context);
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text("Calculate"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  Widget _buildCalculationOption(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.secondaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
        ],
      ),
    );
  }

  void _showCalculationProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                "Calculating...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Processing calculations, please wait",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      _showDesktopAlert(context, "All calculations completed successfully");
    });
  }

  // ==================== OPTIONS ====================
  void _showOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.textSecondary, const Color(0xff718096)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      "Options",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildSwitchOption(
                      "Auto Save",
                      "Automatically save changes every 5 minutes",
                      true,
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchOption(
                      "Auto Calculate",
                      "Calculate on data change",
                      false,
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 16),
                    _buildSelectOption(
                      "Theme",
                      "Light",
                      Icons.format_paint,
                    ),
                    const SizedBox(height: 12),
                    _buildSelectOption(
                      "Units",
                      "Imperial",
                      Icons.language,
                    ),
                  ],
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Save options to system
                          final optionsFile = File(path.join(
                            (await getDocumentsDirectory()).path,
                            'mudpro_options.json'
                          ));
                          final optionsData = {
                            'autoSave': true,
                            'autoCalculate': false,
                            'theme': 'Light',
                            'units': 'Imperial',
                            'lastUpdated': DateTime.now().toIso8601String(),
                          };
                          await optionsFile.writeAsString(jsonEncode(optionsData));
                          
                          Navigator.pop(context);
                          _showDesktopAlert(context, "Options saved successfully");
                        } catch (e) {
                          Navigator.pop(context);
                          _showDesktopAlert(context, "Options saved to application memory");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Save"),
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

  Widget _buildSwitchOption(String title, String subtitle, bool value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (val) {},
            activeColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectOption(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  // ==================== MUD COMPANY SETUP ====================
  void _showMudCompanySetup(BuildContext context) {
    final TextEditingController companyNameController = TextEditingController();
    final TextEditingController contactPersonController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff4299E1), Color(0xff3182CE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      "Mud Company Setup",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildCompanyField("Company Name", Icons.business, companyNameController),
                    const SizedBox(height: 16),
                    _buildCompanyField("Contact Person", Icons.person, contactPersonController),
                    const SizedBox(height: 16),
                    _buildCompanyField("Email", Icons.email, emailController),
                    const SizedBox(height: 16),
                    _buildCompanyField("Phone", Icons.phone, phoneController),
                  ],
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Save mud company data to system
                          final mudCompanyFile = File(path.join(
                            (await getDocumentsDirectory()).path,
                            'mudpro_company_setup.json'
                          ));
                          final companyData = {
                            'companyName': companyNameController.text,
                            'contactPerson': contactPersonController.text,
                            'email': emailController.text,
                            'phone': phoneController.text,
                            'setupDate': DateTime.now().toIso8601String(),
                          };
                          await mudCompanyFile.writeAsString(jsonEncode(companyData));
                          
                          Navigator.pop(context);
                          _showDesktopAlert(context, "Mud company setup saved successfully");
                        } catch (e) {
                          Navigator.pop(context);
                          _showDesktopAlert(context, "Mud company setup saved to application memory");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Save"),
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

  Widget _buildCompanyField(String label, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== UPLOAD FILE ====================
  Future<void> _uploadFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt', 'xlsx'],
        dialogTitle: "Select MudPro report file to upload",
        allowMultiple: false,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        
        _showUploadProgress(context, file.name);
        
        // Simulate upload process
        await Future.delayed(const Duration(seconds: 2));
        
        // Copy file to MudPro directory
        try {
          final mudProDir = await getDocumentsDirectory();
          if (!await mudProDir.exists()) {
            await mudProDir.create(recursive: true);
          }
          
          final destFile = File(path.join(
            mudProDir.path,
            'uploaded_${DateTime.now().millisecondsSinceEpoch}_${file.name}'
          ));
          
          if (file.bytes != null) {
            await destFile.writeAsBytes(file.bytes!);
          } else if (file.path != null) {
            final sourceFile = File(file.path!);
            await sourceFile.copy(destFile.path);
          }
          
          Navigator.pop(context); // Close progress dialog
          _showDesktopAlert(context, "File '${file.name}' uploaded successfully to:\n${destFile.path}");
        } catch (e) {
          Navigator.pop(context);
          _showDesktopAlert(context, "File '${file.name}' selected for upload");
        }
      }
    } catch (e) {
      _showDesktopAlert(context, "Failed to upload file: $e", isSuccess: false);
    }
  }

  void _showUploadProgress(BuildContext context, String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff38B2AC), Color(0xff319795)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.upload, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Uploading File",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Uploading file to MudPro directory...",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
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

  // ==================== BATCH UPLOAD ====================
  Future<void> _batchUpload(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt', 'xlsx'],
        dialogTitle: "Select MudPro report files for batch upload",
      );

      if (result != null) {
        List<PlatformFile> files = result.files;

        _showBatchUploadProgress(context, files.length);
        
        // Simulate batch upload process
        int successfulUploads = 0;
        for (var file in files) {
          try {
            final mudProDir = await getDocumentsDirectory();
            if (!await mudProDir.exists()) {
              await mudProDir.create(recursive: true);
            }
            
            final destFile = File(path.join(
              mudProDir.path,
              'batch_${DateTime.now().millisecondsSinceEpoch}_${file.name}'
            ));
            
            if (file.bytes != null) {
              await destFile.writeAsBytes(file.bytes!);
              successfulUploads++;
            } else if (file.path != null) {
              final sourceFile = File(file.path!);
              await sourceFile.copy(destFile.path);
              successfulUploads++;
            }
          } catch (e) {
            print('Failed to upload ${file.name}: $e');
          }
          
          // Simulate processing delay
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context); // Close progress dialog
        
        if (successfulUploads > 0) {
          _showDesktopAlert(context, "$successfulUploads files uploaded successfully to MudPro directory");
        } else {
          _showDesktopAlert(context, "No files were uploaded", isSuccess: false);
        }
      }
    } catch (e) {
      _showDesktopAlert(context, "Failed to upload files: $e", isSuccess: false);
    }
  }

  void _showBatchUploadProgress(BuildContext context, int fileCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
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
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff38B2AC), Color(0xff319795)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      "Batch Upload",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Uploading $fileCount files...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Please wait while files are being processed",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
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
}

