import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/engineers_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/tabular_database.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class WellTabContent extends StatelessWidget {
  final c = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        
        if (width < 900) {
          // Mobile layout
          return Container(
            color: AppTheme.backgroundColor,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    LeftPortion(),
                    const SizedBox(height: 8),
                    MiddlePortion(),
                    const SizedBox(height: 8),
                    RightPortion(),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Desktop layout - optimized spacing
          double leftWidth = 320;
          double rightWidth = 260;
          
          return Container(
            height: MediaQuery.of(context).size.height - 120,
            color: AppTheme.backgroundColor,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT PORTION - Fixed width
                    SizedBox(
                      width: leftWidth,
                      child: LeftPortion(),
                    ),
                    const SizedBox(width: 6),
                    // MIDDLE PORTION - Takes remaining space
                    Expanded(
                      child: MiddlePortion(),
                    ),
                    const SizedBox(width: 6),
                    // RIGHT PORTION - Fixed width
                    SizedBox(
                      width: rightWidth,
                      child: RightPortion(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

// ==================== LEFT PORTION ====================
class LeftPortion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GeneralSection(),
      ],
    );
  }
}

// ==================== GENERAL SECTION ====================
class GeneralSection extends StatefulWidget {
  @override
  _GeneralSectionState createState() => _GeneralSectionState();
}

class _GeneralSectionState extends State<GeneralSection> {
  final c = Get.find<DashboardController>();
  final engineerController = Get.put(EngineerController());
  final activityController = Get.put(OthersController());

  List<String> activityOptions = [
    'Rig-up/Service', 'Drilling', 'Circulating', 'Tripping', 'Survey',
    'Logging', 'Run Casing', 'Testing', 'Coring/Reaming', 'Cementing'
  ];
  bool _isLoadingActivities = true;

  final List<String> intervalOptions = [
    '22° Hole', '16° Hole', '12 1/4° Hole', '8 1/2° Hole', '6 1/8° Hole', "Completion"
  ];
  
  final Map<String, TextEditingController> fieldControllers = {
    'Report #': TextEditingController(text: '12'),
    'User Report #': TextEditingController(),
    'Bottom T.': TextEditingController(text: '180.0'),
    'MD': TextEditingController(text: '9575.0'),
    'TVD': TextEditingController(text: '7683.0'),
    'Inc': TextEditingController(text: '89.38'),
    'Azi': TextEditingController(text: '299.50'),
    'WOB': TextEditingController(),
    'Rot. Wt.': TextEditingController(),
    'S/O Wt.': TextEditingController(),
    'P/U Wt.': TextEditingController(),
    'RPM': TextEditingController(),
    'ROP': TextEditingController(),
    'Off-bottom TQ': TextEditingController(),
    'On-bottom TQ': TextEditingController(),
    'Suction T.': TextEditingController(),
    'Additional Footage': TextEditingController(text: '0.0'),
    'NPT Time': TextEditingController(),
    'NPT Cost': TextEditingController(),
    'Depth Drilled': TextEditingController(text: '0.0'),
    'Operator Rep.': TextEditingController(text: 'Wang'),
    'Contractor Rep.': TextEditingController(text: 'Jerry'),
    'FIT': TextEditingController(text: 'Completion'),
    'Formation': TextEditingController(text: 'MaG'),
  };

  String selectedDate = 'Tuesday, December 30, 2025';
  String selectedTime = '23:30';
  String? selectedEngineerId;
  String? selectedEngineer2Id;
  String selectedActivity = 'Cementing';
  String selectedInterval = 'Completion';

  @override
  void initState() {
    super.initState();
    _fetchActivities();
    fieldControllers['Engineer'] = TextEditingController(text: _getEngineerName(selectedEngineerId));
    fieldControllers['Engineer 2'] = TextEditingController(text: _getEngineerName(selectedEngineer2Id));
    fieldControllers['Activity'] = TextEditingController(text: selectedActivity);
    fieldControllers['Interval'] = TextEditingController(text: selectedInterval);
    fieldControllers['Date'] = TextEditingController(text: selectedDate);
    fieldControllers['Time'] = TextEditingController(text: selectedTime);
  }

  Future<void> _fetchActivities() async {
    try {
      final activities = await activityController.getActivities();
      setState(() {
        activityOptions = activities.map((activity) => activity.description).toList();
        _isLoadingActivities = false;
        if (!activityOptions.contains(selectedActivity)) {
          selectedActivity = activityOptions.isNotEmpty ? activityOptions.first : 'Cementing';
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingActivities = false;
        if (!activityOptions.contains(selectedActivity)) {
          selectedActivity = activityOptions.isNotEmpty ? activityOptions.first : 'Cementing';
        }
      });
      print('Error fetching activities: $e');
    }
  }

  @override
  void dispose() {
    fieldControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            "General",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
          },
          children: [
            _buildTextFieldRow("Report #", "Report #", ""),
            _buildTextFieldRow("User Report #", "User Report #", ""),
            _buildDateRow("Date"),
            _buildTimeRow("Time"),
            _buildEngineerDropdownRow("Engineer", selectedEngineerId, (value) {
              setState(() => selectedEngineerId = value);
              fieldControllers['Engineer']!.text = _getEngineerName(value);
            }),
            _buildEngineerDropdownRow("Engineer 2", selectedEngineer2Id, (value) {
              setState(() => selectedEngineer2Id = value);
              fieldControllers['Engineer 2']!.text = _getEngineerName(value);
            }),
            _buildTextFieldRow("Operator Rep.", "Operator Rep.", ""),
            _buildTextFieldRow("Contractor Rep.", "Contractor Rep.", ""),
            _buildDropdownRow("Activity", selectedActivity, activityOptions, (value) {
              setState(() => selectedActivity = value!);
            }),
            _buildTextFieldRow("MD", "MD", "ft"),
            _buildTextFieldRow("TVD", "TVD", "ft"),
            _buildTextFieldRow("Inc", "Inc", "°"),
            _buildTextFieldRow("Azi", "Azi", "°"),
            _buildTextFieldRow("WOB", "WOB", "lbf"),
            _buildTextFieldRow("Rot. Wt.", "Rot. Wt.", "lbf"),
            _buildTextFieldRow("S/O Wt.", "S/O Wt.", "lbf"),
            _buildTextFieldRow("P/U Wt.", "P/U Wt.", "lbf"),
            _buildTextFieldRow("RPM", "RPM", "rpm"),
            _buildTextFieldRow("ROP", "ROP", "ft/hr"),
            _buildTextFieldRow("Off-bottom TQ", "Off-bottom TQ", "ft-lb"),
            _buildTextFieldRow("On-bottom TQ", "On-bottom TQ", "ft-lb"),
            _buildTextFieldRow("Suction T.", "Suction T.", "°F"),
            _buildTextFieldRow("Bottom T.", "Bottom T.", "°F"),
            _buildDropdownRow("Interval", selectedInterval, intervalOptions, (value) {
              setState(() => selectedInterval = value!);
            }),
            _buildTextFieldRow("FIT", "FIT", "ppg"),
            _buildTextFieldRow("Formation", "Formation", ""),
            _buildTextFieldRow("Additional Footage", "Additional Footage", "ft"),
            _buildTextFieldRow("NPT Time", "NPT Time", "hr"),
            _buildTextFieldRow("NPT Cost", "NPT Cost", "\$"),
            _buildTextFieldRow("Depth Drilled", "Depth Drilled", "ft"),
          ],
        ),
      ],
    );
  }

  TableRow _buildTextFieldRow(String label, String fieldKey, String unit) {
    final controller = fieldControllers[fieldKey] ?? TextEditingController();
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    controller.text.isNotEmpty ? controller.text : '',
                    style: TextStyle(fontSize: 10, color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                )
              : Container(
                  height: 22,
                  child: TextField(
                    controller: controller,
                    style: TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            unit,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  TableRow _buildDateRow(String label) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(selectedDate, style: TextStyle(fontSize: 10, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                )
              : Container(
                  height: 22,
                  child: TextButton(
                    onPressed: () => _showDatePicker(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(selectedDate, style: TextStyle(fontSize: 10, color: Colors.black), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                )),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
      ],
    );
  }

  TableRow _buildTimeRow(String label) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(selectedTime, style: TextStyle(fontSize: 10, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                )
              : Container(
                  height: 22,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTime,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, size: 14),
                      style: TextStyle(fontSize: 10, color: Colors.black),
                      onChanged: (String? newValue) {
                        if (newValue != null) setState(() => selectedTime = newValue);
                      },
                      items: ['23:30', '22:30', '21:30', '20:30', '19:30', '18:30', '17:30', '16:30'].map<DropdownMenuItem<String>>((String time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(time, style: TextStyle(fontSize: 10))),
                        );
                      }).toList(),
                    ),
                  ),
                )),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
      ],
    );
  }

  TableRow _buildDropdownRow(String label, String value, List<String> options, ValueChanged<String?> onChanged, {String unit = ""}) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(value, style: TextStyle(fontSize: 10, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                )
              : Container(
                  height: 22,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, size: 14),
                      style: TextStyle(fontSize: 10, color: Colors.black),
                      onChanged: onChanged,
                      items: options.map<DropdownMenuItem<String>>((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(option, style: TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Text(unit, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
      ],
    );
  }

  void _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = "${_getDayOfWeek(picked.weekday)}, ${_getMonthName(picked.month)} ${picked.day}, ${picked.year}";
      });
    }
  }

  String _getDayOfWeek(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  String _getEngineerName(String? engineerId) {
    if (engineerId == null) return '';
    final engineer = engineerController.engineers.firstWhere(
      (e) => e.id == engineerId,
      orElse: () => Engineer(firstName: '', lastName: '', cell: '', office: '', email: ''),
    );
    return engineer.id != null ? "${engineer.firstName} ${engineer.lastName}" : '';
  }

  TableRow _buildEngineerDropdownRow(String label, String? engineerId, ValueChanged<String?> onChanged) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(_getEngineerName(engineerId) ?? '', style: TextStyle(fontSize: 10, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                )
              : Container(
                  height: 22,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: engineerId,
                      hint: Text("Select Engineer", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, size: 14),
                      style: TextStyle(fontSize: 10, color: Colors.black),
                      onChanged: onChanged,
                      items: engineerController.engineers.map<DropdownMenuItem<String>>((Engineer engineer) {
                        final fullName = "${engineer.firstName} ${engineer.lastName}";
                        return DropdownMenuItem<String>(
                          value: engineer.id,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(fullName, style: TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
      ],
    );
  }
}

// ==================== MIDDLE PORTION ====================
class MiddlePortion extends StatefulWidget {
  @override
  _MiddlePortionState createState() => _MiddlePortionState();
}

class _MiddlePortionState extends State<MiddlePortion> {
  final c = Get.find<DashboardController>();
  bool cementPlug = false;
  final TextEditingController cementPlugVolController = TextEditingController();
  final TextEditingController plugTopController = TextEditingController();

  @override
  void dispose() {
    cementPlugVolController.dispose();
    plugTopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CasedHoleSection(),
        const SizedBox(height: 6),
        OpenHoleSection(),
        const SizedBox(height: 6),
        // Compact row with checkbox, fields, and button
        Row(
          children: [
            Obx(() => Checkbox(
              value: cementPlug,
              onChanged: c.isLocked.value ? null : (value) {
                setState(() => cementPlug = value ?? false);
              },
              visualDensity: VisualDensity.compact,
              activeColor: AppTheme.primaryColor,
            )),
            Text("Cement Plug Vol. (bbl)", style: TextStyle(fontSize: 10)),
            SizedBox(width: 6),
            SizedBox(
              width: 150,
              child: Container(
                height: 22,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: Obx(() => c.isLocked.value
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(cementPlugVolController.text.isNotEmpty ? cementPlugVolController.text : '', style: TextStyle(fontSize: 10)),
                      )
                    : TextField(
                        controller: cementPlugVolController,
                        style: TextStyle(fontSize: 10),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          border: InputBorder.none,
                        ),
                      )),
              ),
            ),
            SizedBox(width: 12),
            // Tooltip(
            //   message: 'Adjust Length',
            //   child: Icon(Icons.tune, size: 14, color: AppTheme.primaryColor),
            // ),
            SizedBox(width: 6),
            Text("Plug Top (ft)", style: TextStyle(fontSize: 10)),
            SizedBox(width: 6),
            SizedBox(
              width: 150,
              child: Container(
                height: 22,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: Obx(() => c.isLocked.value
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(plugTopController.text.isNotEmpty ? plugTopController.text : '', style: TextStyle(fontSize: 10)),
                      )
                    : TextField(
                        controller: plugTopController,
                        style: TextStyle(fontSize: 10),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          border: InputBorder.none,
                        ),
                      )),
              ),
            ),
         
            
          ],
        ),
        const SizedBox(height: 6),
        DrillStringSection(),
      ],
    );
  }
}

// ==================== CASED HOLE SECTION ====================
class CasedHoleSection extends StatefulWidget {
  @override
  _CasedHoleSectionState createState() => _CasedHoleSectionState();
}

class _CasedHoleSectionState extends State<CasedHoleSection> {
  final c = Get.find<DashboardController>();
  final List<String> casingTypes = ['30° CSG', '18 5/8° CSG', '13 3/8° CSG', '9 5/8° CSG', '7° LINER'];
  String selectedCasingType = '30° CSG';
  final ScrollController scrollController = ScrollController();
  int? selectedRowIndex;

  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: '30" CSG'), TextEditingController(text: '30.000'), TextEditingController(), TextEditingController(text: '28.500'), TextEditingController(text: '0.0'), TextEditingController(), TextEditingController()],
    [TextEditingController(text: '18 5/8" CSG'), TextEditingController(text: '18.625'), TextEditingController(), TextEditingController(text: '17.755'), TextEditingController(text: '0.0'), TextEditingController(), TextEditingController()],
    [TextEditingController(text: '13 3/8" CSG'), TextEditingController(text: '13.375'), TextEditingController(), TextEditingController(text: '12.415'), TextEditingController(text: '0.0'), TextEditingController(text: '6000.0'), TextEditingController(text: '6000.0')],
    [TextEditingController(text: '9 5/8" CSG'), TextEditingController(text: '9.625'), TextEditingController(text: '47.000'), TextEditingController(text: '8.755'), TextEditingController(text: '0.0'), TextEditingController(text: '7095.0'), TextEditingController(text: '7095.0')],
    [TextEditingController(text: '7" Liner'), TextEditingController(text: '7.000'), TextEditingController(text: '26.000'), TextEditingController(text: '6.276'), TextEditingController(text: '6872.0'), TextEditingController(text: '8080.0'), TextEditingController(text: '1208.0')],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
  ];

  @override
  void dispose() {
    for (var row in tableData) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                "Cased Hole",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
              ),
            ),
            // SizedBox(width: 8),
            Spacer(),
            Text("Add New Casing", style: TextStyle(fontSize: 9)),
            SizedBox(width: 6),
            Container(
              height: 22,
              padding: EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCasingType,
                  icon: Icon(Icons.arrow_drop_down, size: 14),
                  style: TextStyle(fontSize: 9, color: Colors.black),
                  onChanged: (String? newValue) {
                    if (newValue != null) setState(() => selectedCasingType = newValue);
                  },
                  items: casingTypes.map<DropdownMenuItem<String>>((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: TextStyle(fontSize: 9)),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(width: 6),
            Tooltip(
              message: 'Add New Casing',
              child: InkWell(
                onTap: () => setState(() {
                  tableData.add([TextEditingController(text: selectedCasingType), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()]);
                }),
                child: Icon(Icons.add_box, color: AppTheme.primaryColor, size: 18),
              ),
            ),
            Spacer(),
            // Tooltip(
            //   message: 'View Table',
            //   child: Icon(Icons.table_chart, color: AppTheme.primaryColor, size: 18),
            // ),
          ],
        ),
        SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FixedColumnWidth(200),
              2: FixedColumnWidth(90),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(70),
              5: FixedColumnWidth(70),
              6: FixedColumnWidth(70),
              7: FixedColumnWidth(70),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
                children: [
                  _buildHeaderCell(""),
                  _buildHeaderCell("Description"),
                  _buildHeaderCell("OD\n(in)"),
                  _buildHeaderCell("Wt.\n(lb/ft)"),
                  _buildHeaderCell("ID\n(in)"),
                  _buildHeaderCell("Top\n(ft)"),
                  _buildHeaderCell("Shoe\n(ft)"),
                  _buildHeaderCell("Len.\n(ft)"),
                ],
              ),
              ...tableData.asMap().entries.map((entry) {
                final index = entry.key;
                final rowControllers = entry.value;
                return _buildDataRow(index, rowControllers);
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.primaryColor), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<TextEditingController> controllers) {
    bool isSelected = selectedRowIndex == rowIndex;
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected 
          ? AppTheme.primaryColor.withOpacity(0.1) 
          : (rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50)
      ),
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedRowIndex = selectedRowIndex == rowIndex ? null : rowIndex;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: Icon(
              Icons.play_arrow, 
              size: 11, 
              color: isSelected ? AppTheme.primaryColor : Colors.transparent
            ),
          ),
        ),
        _buildEditableCell(controllers[0]),
        _buildEditableCell(controllers[1]),
        _buildEditableCell(controllers[2]),
        _buildEditableCell(controllers[3]),
        _buildEditableCell(controllers[4]),
        _buildEditableCell(controllers[5]),
        _buildEditableCell(controllers[6]),
      ],
    );
  }

  Widget _buildEditableCell(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Obx(() => c.isLocked.value
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                controller.text.isNotEmpty ? controller.text : '',
                style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
            )
          : Container(
              height: 20,
              child: TextField(
                controller: controller,
                style: TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            )),
    );
  }
}

// ==================== OPEN HOLE SECTION ====================
class OpenHoleSection extends StatefulWidget {
  @override
  _OpenHoleSectionState createState() => _OpenHoleSectionState();
}

class _OpenHoleSectionState extends State<OpenHoleSection> {
  final c = Get.find<DashboardController>();
  final ScrollController scrollController = ScrollController();
  int? selectedRowIndex;

  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: '8.5" Hole'), TextEditingController(text: '8.500'), TextEditingController(text: '9055.0'), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
  ];

  @override
  void dispose() {
    for (var row in tableData) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                "Open Hole",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
              ),
            ),
            Spacer(),
            // Tooltip(
            //   message: 'Refresh',
            //   child: Icon(Icons.refresh, color: AppTheme.errorColor, size: 18),
            // ),
          ],
        ),
        SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FixedColumnWidth(270),
              2: FixedColumnWidth(130),
              3: FixedColumnWidth(120),
              4: FixedColumnWidth(120),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
                children: [
                  _buildHeaderCell(""),
                  _buildHeaderCell("Description"),
                  _buildHeaderCell("ID\n(in)"),
                  _buildHeaderCell("MD\n(ft)"),
                  _buildHeaderCell("Washout\n(%)"),
                ],
              ),
              ...tableData.asMap().entries.map((entry) {
                final index = entry.key;
                final rowControllers = entry.value;
                return _buildDataRow(index, rowControllers);
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.primaryColor), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<TextEditingController> controllers) {
    bool isSelected = selectedRowIndex == rowIndex;
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected 
          ? AppTheme.primaryColor.withOpacity(0.1) 
          : (rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50)
      ),
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedRowIndex = selectedRowIndex == rowIndex ? null : rowIndex;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: Icon(
              Icons.play_arrow, 
              size: 11, 
              color: isSelected ? AppTheme.primaryColor : Colors.transparent
            ),
          ),
        ),
        _buildEditableCell(controllers[0]),
        _buildEditableCell(controllers[1]),
        _buildEditableCell(controllers[2]),
        _buildEditableCell(controllers[3]),
      ],
    );
  }

  Widget _buildEditableCell(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Obx(() => c.isLocked.value
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                controller.text.isNotEmpty ? controller.text : '',
                style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
            )
          : Container(
              height: 20,
              child: TextField(
                controller: controller,
                style: TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            )),
    );
  }
}

// ==================== DRILL STRING SECTION ====================
class DrillStringSection extends StatefulWidget {
  @override
  _DrillStringSectionState createState() => _DrillStringSectionState();
}

class _DrillStringSectionState extends State<DrillStringSection> {
  final c = Get.find<DashboardController>();
  int? selectedRowIndex;

  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: 'DP'), TextEditingController(text: '5.000'), TextEditingController(), TextEditingController(text: '4.276'), TextEditingController(), TextEditingController(text: '7430.4')],
    [TextEditingController(text: 'X-OVER'), TextEditingController(text: '6.500'), TextEditingController(), TextEditingController(text: '2.630'), TextEditingController(), TextEditingController(text: '2.3')],
    [TextEditingController(text: 'DP'), TextEditingController(text: '4.000'), TextEditingController(), TextEditingController(text: '3.340'), TextEditingController(), TextEditingController(text: '851.5')],
    [TextEditingController(text: 'HWDP'), TextEditingController(text: '4.000'), TextEditingController(), TextEditingController(text: '2.438'), TextEditingController(), TextEditingController(text: '92.3')],
    [TextEditingController(text: 'JAR'), TextEditingController(text: '4.750'), TextEditingController(), TextEditingController(text: '2.250'), TextEditingController(), TextEditingController(text: '19.8')],
    [TextEditingController(text: 'HWDP'), TextEditingController(text: '4.000'), TextEditingController(), TextEditingController(text: '2.438'), TextEditingController(), TextEditingController(text: '551.7')],
    [TextEditingController(text: 'DC'), TextEditingController(text: '4.750'), TextEditingController(), TextEditingController(text: '3.340'), TextEditingController(), TextEditingController(text: '31.1')],
    [TextEditingController(text: 'BIT SUB'), TextEditingController(text: '4.750'), TextEditingController(), TextEditingController(text: '2.000'), TextEditingController(), TextEditingController(text: '3.0')],
  ];

  final TextEditingController totalLengthController = TextEditingController(text: '8982.0');
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                "Drill String",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
              ),
            ),
            Spacer(),
          //  SizedBox(width: 150),
          //  Tooltip(
          //     message: 'Tabular Database',
          //     child: ElevatedButton.icon(
          //       onPressed: () => Get.to(() => TabularDatabaseView()),
          //       icon: Icon(Icons.table_chart, size: 14, color: Colors.white),
          //       label: Text('Tabular Database', style: TextStyle(fontSize: 9, color: Colors.white)),
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: AppTheme.primaryColor,
          //         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          //         minimumSize: Size(0, 26),
          //       ),
          //     ),
          //   ),
           
            // SizedBox(width: 4),
            Tooltip(
              onTriggered: () => Get.to(() => TabularDatabaseView()),
              message: 'Tabular Database',
              child: Icon(Icons.table_chart, color: AppTheme.primaryColor, size: 18),
            ),
            SizedBox(width: 4),
            Tooltip(
              message: 'Adjust length',
              child: Icon(Icons.tune, color: AppTheme.primaryColor, size: 18),
            ),
          ],
        ),
        SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FixedColumnWidth(200),
              2: FixedColumnWidth(95),
              3: FixedColumnWidth(95),
              4: FixedColumnWidth(85),
              5: FixedColumnWidth(85),
              6: FixedColumnWidth(85),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
                children: [
                  _buildHeaderCell(""),
                  _buildHeaderCell("Description"),
                  _buildHeaderCell("OD\n(in)"),
                  _buildHeaderCell("Wt.\n(lb/ft)"),
                  _buildHeaderCell("ID\n(in)"),
                  _buildHeaderCell("Grade"),
                  _buildHeaderCell("Len.\n(ft)"),
                ],
              ),
              ...tableData.asMap().entries.map((entry) {
                final index = entry.key;
                final rowControllers = entry.value;
                return _buildDataRow(index, rowControllers);
              }).toList(),
            ],
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          color: AppTheme.primaryColor.withOpacity(0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total String Length < Well Depth", style: TextStyle(fontSize: 9, color: AppTheme.textPrimary)),
              Row(
                children: [
                  Text("Total Length (ft)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                  SizedBox(width: 6),
                  Container(
                    width: 70,
                    height: 20,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                    child: Obx(() => c.isLocked.value
                        ? Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                            child: Text(totalLengthController.text, style: TextStyle(fontSize: 9)),
                          )
                        : TextField(
                            controller: totalLengthController,
                            style: TextStyle(fontSize: 9),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3), border: InputBorder.none),
                          )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.primaryColor), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<TextEditingController> controllers) {
    bool isSelected = selectedRowIndex == rowIndex;
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected 
          ? AppTheme.primaryColor.withOpacity(0.1) 
          : (rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50)
      ),
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedRowIndex = selectedRowIndex == rowIndex ? null : rowIndex;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: Icon(
              Icons.play_arrow, 
              size: 11, 
              color: isSelected ? AppTheme.primaryColor : Colors.transparent
            ),
          ),
        ),
        _buildEditableCell(controllers[0]),
        _buildEditableCell(controllers[1]),
        _buildEditableCell(controllers[2]),
        _buildEditableCell(controllers[3]),
        _buildEditableCell(controllers[4]),
        _buildEditableCell(controllers[5]),
      ],
    );
  }

  Widget _buildEditableCell(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Obx(() => c.isLocked.value
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                controller.text.isNotEmpty ? controller.text : '',
                style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
            )
          : Container(
              height: 20,
              child: TextField(
                controller: controller,
                style: TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            )),
    );
  }
}

// ==================== RIGHT PORTION ====================
class RightPortion extends StatelessWidget {
  final activityController = Get.put(OthersController());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BitSection(),
        const SizedBox(height: 6),
        NozzleSection(),
        const SizedBox(height: 6),
        TimeDistributionSection(activityController: activityController),
      ],
    );
  }
}

// ==================== BIT SECTION ====================
class BitSection extends StatefulWidget {
  @override
  _BitSectionState createState() => _BitSectionState();
}

class _BitSectionState extends State<BitSection> {
  final c = Get.find<DashboardController>();
  
  final Map<String, TextEditingController> bitControllers = {
    'Mft': TextEditingController(text: 'VAREL'),
    'Type': TextEditingController(text: 'MT-TCI'),
    'No. of Bits': TextEditingController(text: '1'),
    'Size': TextEditingController(text: '6.125'),
    'Depth-in': TextEditingController(text: ''),
    'Depth': TextEditingController(text: '8982.0'),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            "Bit",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
          ),
        ),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
          },
          children: [
            _buildBitRow("Mft", "Mft", ""),
            _buildBitRow("Type", "Type", ""),
            _buildBitRow("No. of Bits", "No. of Bits", ""),
            _buildBitRow("Size", "Size", "(in)"),
            _buildBitRow("Depth-in", "Depth-in", "(ft)"),
            _buildBitRow("Depth", "Depth", "(ft)"),
          ],
        ),
      ],
    );
  }

  TableRow _buildBitRow(String label, String fieldKey, String unit) {
    final controller = bitControllers[fieldKey] ?? TextEditingController();
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    controller.text.isNotEmpty ? controller.text : '',
                    style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                )
              : Container(
                  height: 20,
                  child: TextField(
                    controller: controller,
                    style: TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(unit, style: TextStyle(fontSize: 9, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

// ==================== NOZZLE SECTION ====================
class NozzleSection extends StatefulWidget {
  @override
  _NozzleSectionState createState() => _NozzleSectionState();
}

class _NozzleSectionState extends State<NozzleSection> {
  final c = Get.find<DashboardController>();
  int? selectedRowIndex;
  
  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: '1'), TextEditingController(text: '3'), TextEditingController(text: '14')],
    [TextEditingController(text: '2'), TextEditingController(), TextEditingController()],
    [TextEditingController(text: '3'), TextEditingController(), TextEditingController()],
  ];
  
  final TextEditingController tfaController = TextEditingController(text: '0.518');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            "Nozzle (1/32in)",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
          ),
        ),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FixedColumnWidth(110),
            2: FixedColumnWidth(110),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
              children: [
                _buildHeaderCell(""),
                _buildHeaderCell("No."),
                _buildHeaderCell("Size\n(1/32in)"),
              ],
            ),
            ...tableData.asMap().entries.map((entry) {
              final index = entry.key;
              final rowControllers = entry.value;
              return _buildDataRow(index, rowControllers);
            }).toList(),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          color: AppTheme.primaryColor.withOpacity(0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TFA (in²)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: Obx(() => c.isLocked.value
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        child: Text(tfaController.text, style: TextStyle(fontSize: 9)),
                      )
                    : TextField(
                        controller: tfaController,
                        style: TextStyle(fontSize: 9),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3), border: InputBorder.none),
                      )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.primaryColor), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<TextEditingController> controllers) {
    bool isSelected = selectedRowIndex == rowIndex;
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected 
          ? AppTheme.primaryColor.withOpacity(0.1) 
          : (rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50)
      ),
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedRowIndex = selectedRowIndex == rowIndex ? null : rowIndex;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: Icon(
              Icons.play_arrow, 
              size: 11, 
              color: isSelected ? AppTheme.primaryColor : Colors.transparent
            ),
          ),
        ),
        _buildEditableCell(controllers[1]),
        _buildEditableCell(controllers[2]),
      ],
    );
  }

  Widget _buildEditableCell(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Obx(() => c.isLocked.value
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                controller.text.isNotEmpty ? controller.text : '',
                style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
            )
          : Container(
              height: 20,
              child: TextField(
                controller: controller,
                style: TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            )),
    );
  }
}

// ==================== TIME DISTRIBUTION SECTION ====================
class TimeDistributionSection extends StatefulWidget {
  final OthersController activityController;

  TimeDistributionSection({required this.activityController});

  @override
  _TimeDistributionSectionState createState() => _TimeDistributionSectionState();
}

class _TimeDistributionSectionState extends State<TimeDistributionSection> {
  final c = Get.find<DashboardController>();
  int? selectedRowIndex;

  List<String> activityOptions = [];
  bool _isLoadingActivities = true;

  final ScrollController scrollController = ScrollController();

  List<List<dynamic>> tableData = [
    ['1', 'MUD BOP', '2.00'],
    ['2', 'Install Wellhead', '2.30'],
    ['3', 'N/Up BOP', '3.00'],
    ['4', 'Pressure Test', '3.00'],
    ['5', 'Others', '2.00'],
    ['6', 'Circulation', '1.30'],
    ['7', 'Tripping', '4.00'],
    ['8', 'Drilling Cement', '6.90'],
  ];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final activities = await widget.activityController.getActivities();
      setState(() {
        activityOptions = activities.map((activity) => activity.description).toList();
        _isLoadingActivities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingActivities = false;
      });
      print('Error fetching activities: $e');
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            "Time Distribution",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
          ),
        ),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(3),
            2: FixedColumnWidth(55),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15)),
              children: [
                _buildHeaderCell(""),
                _buildHeaderCell("Activity"),
                _buildHeaderCell("Time\n(hr)"),
              ],
            ),
            ...tableData.asMap().entries.map((entry) {
              final index = entry.key;
              final rowData = entry.value;
              return _buildDataRow(index, rowData);
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.primaryColor), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<dynamic> rowData) {
    final TextEditingController timeController = TextEditingController(text: rowData[2]);
    bool isSelected = selectedRowIndex == rowIndex;

    return TableRow(
      decoration: BoxDecoration(
        color: isSelected 
          ? AppTheme.primaryColor.withOpacity(0.1) 
          : (rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50)
      ),
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedRowIndex = selectedRowIndex == rowIndex ? null : rowIndex;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: Icon(
              Icons.play_arrow, 
              size: 11, 
              color: isSelected ? AppTheme.primaryColor : Colors.transparent
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(rowData[1], style: TextStyle(fontSize: 9, color: AppTheme.textPrimary), textAlign: TextAlign.left),
                )
              : Container(
                  height: 20,
                  child: _isLoadingActivities
                      ? Center(child: SizedBox(height: 10, width: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryColor)))
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: activityOptions.contains(rowData[1]) ? rowData[1] : (activityOptions.isNotEmpty ? activityOptions.first : null),
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, size: 12),
                            style: TextStyle(fontSize: 9, color: Colors.black),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  tableData[rowIndex][1] = newValue;
                                });
                              }
                            },
                            items: activityOptions.map<DropdownMenuItem<String>>((String option) {
                              return DropdownMenuItem<String>(
                                value: option,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(option, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    timeController.text.isNotEmpty ? timeController.text : '',
                    style: TextStyle(fontSize: 9, color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                )
              : Container(
                  height: 20,
                  child: TextField(
                    controller: timeController,
                    style: TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      tableData[rowIndex][2] = value;
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                )),
        ),
      ],
    );
  }
}