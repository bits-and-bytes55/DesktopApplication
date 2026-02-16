import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/engineers_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/tabular_database.dart';
import 'package:mudpro_desktop_app/modules/services/api_service.dart';

class WellTabContent extends StatelessWidget {
  final c = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        if (width < 800) {
          return Container(
            color: Colors.white,
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
          return Container(
            height: MediaQuery.of(context).size.height - 120,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT PORTION
                      ConstrainedBox(
                        constraints: BoxConstraints(minWidth: 280, maxWidth: 320),
                        child: LeftPortion(),
                      ),
                      const SizedBox(width: 8),
                      // MIDDLE PORTION
                      Expanded(
                        flex: 4,
                        child: MiddlePortion(),
                      ),
                      const SizedBox(width: 8),
                      // RIGHT PORTION
                      ConstrainedBox(
                        constraints: BoxConstraints(minWidth: 200, maxWidth: 280),
                        child: RightPortion(),
                      ),
                    ],
                  ),
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

  final List<String> activityOptions = [
    'Rig-up/Service', 'Drilling', 'Circulating', 'Tripping', 'Survey',
    'Logging', 'Run Casing', 'Testing', 'Coring/Reaming', 'Cementing'
  ];

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
    fieldControllers['Engineer'] = TextEditingController(text: _getEngineerName(selectedEngineerId));
    fieldControllers['Engineer 2'] = TextEditingController(text: _getEngineerName(selectedEngineer2Id));
    fieldControllers['Activity'] = TextEditingController(text: selectedActivity);
    fieldControllers['Interval'] = TextEditingController(text: selectedInterval);
    fieldControllers['Date'] = TextEditingController(text: selectedDate);
    fieldControllers['Time'] = TextEditingController(text: selectedTime);
  }

  @override
  void dispose() {
    fieldControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xff0d9488),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  "General Information",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(2),
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
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTextFieldRow(String label, String fieldKey, String unit) {
    final controller = fieldControllers[fieldKey] ?? TextEditingController();
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff2c3e50)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    controller.text.isNotEmpty ? controller.text : '-',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                )
              : Container(
                  height: 20,
                  child: TextField(
                    controller: controller,
                    style: TextStyle(fontSize: 9, height: 1.2),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      border: InputBorder.none,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(
            unit,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff2c3e50))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Text(selectedDate, style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
                )
              : Container(
                  height: 20,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
                  child: TextButton(
                    onPressed: () => _showDatePicker(context),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(selectedDate, style: TextStyle(fontSize: 9, color: Colors.black), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 12, color: Colors.grey),
                      ],
                    ),
                  ),
                )),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: Text("", style: TextStyle(fontSize: 9))),
      ],
    );
  }

  TableRow _buildTimeRow(String label) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff2c3e50))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Text(selectedTime, style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
                )
              : Container(
                  height: 20,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTime,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, size: 12),
                      style: TextStyle(fontSize: 9, color: Colors.black),
                      onChanged: (String? newValue) {
                        if (newValue != null) setState(() => selectedTime = newValue);
                      },
                      items: ['23:30', '22:30', '21:30', '20:30', '19:30', '18:30', '17:30', '16:30'].map<DropdownMenuItem<String>>((String time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(time, style: TextStyle(fontSize: 9), textAlign: TextAlign.center)),
                        );
                      }).toList(),
                    ),
                  ),
                )),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: Text("", style: TextStyle(fontSize: 9))),
      ],
    );
  }

  TableRow _buildDropdownRow(String label, String value, List<String> options, ValueChanged<String?> onChanged, {String unit = ""}) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff2c3e50))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Text(value, style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
                )
              : Container(
                  height: 20,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, size: 12),
                      style: TextStyle(fontSize: 9, color: Colors.black),
                      onChanged: onChanged,
                      items: options.map<DropdownMenuItem<String>>((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(option, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: Text(unit, style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center)),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff2c3e50))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Text(_getEngineerName(engineerId) ?? '-', style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
                )
              : Container(
                  height: 20,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: engineerId,
                      hint: Text("Select Engineer", style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, size: 12),
                      style: TextStyle(fontSize: 9, color: Colors.black),
                      onChanged: onChanged,
                      items: engineerController.engineers.map<DropdownMenuItem<String>>((Engineer engineer) {
                        final fullName = "${engineer.firstName} ${engineer.lastName}";
                        return DropdownMenuItem<String>(
                          value: engineer.id,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(fullName, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )),
        ),
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: Text("", style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center)),
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
        const SizedBox(height: 8),
        OpenHoleSection(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Flexible(
                child: Row(
                  children: [
                    Obx(() => Checkbox(
                      value: cementPlug,
                      onChanged: c.isLocked.value ? null : (value) {
                        setState(() => cementPlug = value ?? false);
                      },
                      visualDensity: VisualDensity.compact,
                    )),
                    Text("Cement Plug Vol.", style: TextStyle(fontSize: 9)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
                        child: Obx(() => c.isLocked.value
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Text(cementPlugVolController.text.isNotEmpty ? cementPlugVolController.text : '-', style: TextStyle(fontSize: 9)),
                              )
                            : TextField(
                                controller: cementPlugVolController,
                                style: TextStyle(fontSize: 9),
                                decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), border: InputBorder.none),
                              )),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Row(
                  children: [
                    Text("Plug Top", style: TextStyle(fontSize: 9)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
                        child: Obx(() => c.isLocked.value
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Text(plugTopController.text.isNotEmpty ? plugTopController.text : '-', style: TextStyle(fontSize: 9)),
                              )
                            : TextField(
                                controller: plugTopController,
                                style: TextStyle(fontSize: 9),
                                decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), border: InputBorder.none),
                              )),
                      ),
                    ),
                    SizedBox(width: 4),
                    IconButton(
                      onPressed: c.isLocked.value ? null : () {},
                      icon: Icon(Icons.tune, size: 16, color: Color(0xff0d9488)),
                      tooltip: 'Adjust Length',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6),
              IconButton(
                onPressed: () => Get.to(() => TabularDatabaseView()),
                icon: Icon(Icons.table_chart, size: 20, color: Color(0xff0d9488)),
                tooltip: 'Tabular Database',
                style: IconButton.styleFrom(
                  backgroundColor: Color(0xff0d9488),
                  padding: EdgeInsets.all(8),
                ),
              ),
              // SizedBox(width: 6),
              // ElevatedButton(
              //   onPressed: () async {
              //     try {
              //       final data = await HealthService.checkHealth();
              //       debugPrint("Health data: $data");
              //       Get.snackbar('Success', 'Backend is reachable', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
              //     } catch (e) {
              //       debugPrint('Backend error: $e');
              //       Get.snackbar('Error', e.toString().replaceAll('Exception:', '').trim(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
              //     }
              //   },
              //   style: ElevatedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              //     backgroundColor: Color(0xff0d9488),
              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              //   ),
              //   child: Text('Check Backend', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
              // ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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

  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: '9 5/8" Casing'), TextEditingController(text: '9.625'), TextEditingController(text: '47.000'), TextEditingController(text: '8.681'), TextEditingController(text: '0.0'), TextEditingController(text: '7830.0'), TextEditingController(text: '7830.0')],
    [TextEditingController(text: 'Liner'), TextEditingController(text: '7.000'), TextEditingController(text: '26.000'), TextEditingController(text: '6.276'), TextEditingController(text: '7590.0'), TextEditingController(text: '9053.0'), TextEditingController(text: '1463.0')],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xff0d9488),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text("Cased Hole", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1), borderRadius: BorderRadius.circular(4)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCasingType,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, size: 14, color: Colors.white),
                          style: TextStyle(fontSize: 10, color: Colors.white),
                          dropdownColor: Color(0xff0d9488),
                          onChanged: (String? newValue) {
                            if (newValue != null) setState(() => selectedCasingType = newValue);
                          },
                          items: casingTypes.map<DropdownMenuItem<String>>((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(type, style: TextStyle(fontSize: 10))),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    IconButton(
                      onPressed: () => setState(() {
                        tableData.add([TextEditingController(text: selectedCasingType), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()]);
                      }),
                      icon: Icon(Icons.add, color: Colors.white, size: 16),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), padding: EdgeInsets.all(4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(
            constraints: BoxConstraints(maxHeight: 150),
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildCasedHoleTable(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasedHoleTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FixedColumnWidth(35),  // No.
        1: FixedColumnWidth(100), // Description
        2: FixedColumnWidth(60),  // OD
        3: FixedColumnWidth(70),  // Wt.
        4: FixedColumnWidth(60),  // ID
        5: FixedColumnWidth(70),  // Top
        6: FixedColumnWidth(70),  // Shoe
        7: FixedColumnWidth(70),  // Len.
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Color(0xfff0f9ff)),
          children: [
            _buildHeaderCell("No."),
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
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488)), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<TextEditingController> controllers) {
    return TableRow(
      decoration: BoxDecoration(color: rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text('${rowIndex + 1}', style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Obx(() => c.isLocked.value
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 3),
              child: Text(
                controller.text.isNotEmpty ? controller.text : '-',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            )
          : Container(
              height: 20,
              child: TextField(
                controller: controller,
                style: TextStyle(fontSize: 9, height: 1.2),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  border: InputBorder.none,
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

  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: '8.5" Hole'), TextEditingController(text: '8.500'), TextEditingController(text: '9055.0'), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
    [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()],
  ];

  bool cementPlug = false;
  final TextEditingController cementPlugVolController = TextEditingController();
  final TextEditingController plugTopController = TextEditingController();

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xff0d9488),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.explore, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text("Open Hole", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),

          Container(
            constraints: BoxConstraints(maxHeight: 150),
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(35),
                      1: FixedColumnWidth(120),
                      2: FixedColumnWidth(70),
                      3: FixedColumnWidth(80),
                      4: FixedColumnWidth(80),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Color(0xfff0f9ff)),
                        children: [
                          _buildHeaderCell("No."),
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
              ),
            ),
          ),

          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          //   child: Row(
          //     children: [
          //       Flexible(
          //         child: Row(
          //           children: [
          //             Obx(() => Checkbox(
          //               value: cementPlug,
          //               onChanged: c.isLocked.value ? null : (value) {
          //                 setState(() => cementPlug = value ?? false);
          //               },
          //               visualDensity: VisualDensity.compact,
          //             )),
          //             Text("Cement Plug Vol.", style: TextStyle(fontSize: 9)),
          //             SizedBox(width: 6),
          //             Expanded(
          //               child: Container(
          //                 height: 20,
          //                 decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
          //                 child: Obx(() => c.isLocked.value
          //                     ? Container(
          //                         padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          //                         child: Text(cementPlugVolController.text.isNotEmpty ? cementPlugVolController.text : '-', style: TextStyle(fontSize: 9)),
          //                       )
          //                     : TextField(
          //                         controller: cementPlugVolController,
          //                         style: TextStyle(fontSize: 9),
          //                         decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), border: InputBorder.none),
          //                       )),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       SizedBox(width: 6),
          //       Flexible(
          //         child: Row(
          //           children: [
          //             Text("Plug Top", style: TextStyle(fontSize: 9)),
          //             SizedBox(width: 6),
          //             Expanded(
          //               child: Container(
          //                 height: 20,
          //                 decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
          //                 child: Obx(() => c.isLocked.value
          //                     ? Container(
          //                         padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          //                         child: Text(plugTopController.text.isNotEmpty ? plugTopController.text : '-', style: TextStyle(fontSize: 9)),
          //                       )
          //                     : TextField(
          //                         controller: plugTopController,
          //                         style: TextStyle(fontSize: 9),
          //                         decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), border: InputBorder.none),
          //                       )),
          //               ),
          //             ),
          //             SizedBox(width: 4),
          //             IconButton(
          //               onPressed: c.isLocked.value ? null : () {},
          //               icon: Icon(Icons.tune, size: 16, color: Color(0xff0d9488)),
          //               tooltip: 'Adjust Length',
          //               padding: EdgeInsets.zero,
          //               constraints: BoxConstraints(),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488)), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<TextEditingController> controllers) {
    return TableRow(
      decoration: BoxDecoration(color: rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text('${rowIndex + 1}', style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Obx(() => c.isLocked.value
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 3),
              child: Text(
                controller.text.isNotEmpty ? controller.text : '-',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            )
          : Container(
              height: 20,
              child: TextField(
                controller: controller,
                style: TextStyle(fontSize: 9, height: 1.2),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  border: InputBorder.none,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xff0d9488),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.build, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text("Drill String", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),

          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(35),
                      1: FixedColumnWidth(100),
                      2: FixedColumnWidth(60),
                      3: FixedColumnWidth(70),
                      4: FixedColumnWidth(60),
                      5: FixedColumnWidth(70),
                      6: FixedColumnWidth(80),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Color(0xfff0f9ff)),
                        children: [
                          _buildHeaderCell("No."),
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
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xfff0f9ff),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
              border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Total String Length < Well Depth",
                    style: TextStyle(fontSize: 9, color: Color(0xff0d9488)),
                  ),
                ),
                Row(
                  children: [
                    Text("Total Length (ft): ", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff0d9488))),
                    Container(
                      width: 80,
                      height: 22,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
                      child: Obx(() => c.isLocked.value
                          ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(totalLengthController.text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488))),
                            )
                          : TextField(
                              controller: totalLengthController,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488)),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), border: InputBorder.none),
                            )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488)), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<TextEditingController> controllers) {
    return TableRow(
      decoration: BoxDecoration(color: rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text('${rowIndex + 1}', style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Obx(() => c.isLocked.value
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 3),
              child: Text(
                controller.text.isNotEmpty ? controller.text : '-',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            )
          : Container(
              height: 20,
              child: TextField(
                controller: controller,
                style: TextStyle(fontSize: 9, height: 1.2),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  border: InputBorder.none,
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BitSection(),
        const SizedBox(height: 8),
        NozzleSection(),
        const SizedBox(height: 8),
        TimeDistributionSection(),
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
    'Size': TextEditingController(text: '22.000'),
    'Depth-in': TextEditingController(text: '65.0'),
    'Depth': TextEditingController(text: '96.0'),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xff0d9488),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.diamond, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text("Bit Information", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Color(0xfff0f9ff)),
                  children: [
                    _buildHeaderCell("Field"),
                    _buildHeaderCell("Value"),
                    _buildHeaderCell(""),
                  ],
                ),
                _buildBitRow("Mft", "Mft", ""),
                _buildBitRow("Type", "Type", ""),
                _buildBitRow("No. of Bits", "No. of Bits", ""),
                _buildBitRow("Size", "Size", "in"),
                _buildBitRow("Depth-in", "Depth-in", "ft"),
                _buildBitRow("Depth", "Depth", "ft"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488)), textAlign: TextAlign.center),
    );
  }

  TableRow _buildBitRow(String label, String fieldKey, String unit) {
    final controller = bitControllers[fieldKey] ?? TextEditingController();
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff2c3e50))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    controller.text.isNotEmpty ? controller.text : '-',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                )
              : Container(
                  height: 20,
                  child: TextField(
                    controller: controller,
                    style: TextStyle(fontSize: 9, height: 1.2),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      border: InputBorder.none,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(unit, style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
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
  
  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: '1'), TextEditingController(text: '14')],
    [TextEditingController(text: '2'), TextEditingController()],
    [TextEditingController(text: '3'), TextEditingController()],
  ];
  
  final TextEditingController tfaController = TextEditingController(text: '0.518');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xff0d9488),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text("Nozzle Information", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(35),
                1: FixedColumnWidth(80),
                2: FixedColumnWidth(100),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Color(0xfff0f9ff)),
                  children: [
                    _buildHeaderCell("#"),
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
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TFA (in²)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xff0d9488))),
                Container(
                  width: 70,
                  height: 22,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
                  child: Obx(() => c.isLocked.value
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(tfaController.text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488))),
                        )
                      : TextField(
                          controller: tfaController,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488)),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), border: InputBorder.none),
                        )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488)), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<TextEditingController> controllers) {
    return TableRow(
      decoration: BoxDecoration(color: rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text('${rowIndex + 1}', style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
        ),
        _buildEditableCell(controllers[0]),
        _buildEditableCell(controllers[1]),
      ],
    );
  }

  Widget _buildEditableCell(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Obx(() => c.isLocked.value
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 3),
              child: Text(
                controller.text.isNotEmpty ? controller.text : '-',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            )
          : Container(
              height: 20,
              child: TextField(
                controller: controller,
                style: TextStyle(fontSize: 9, height: 1.2),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  border: InputBorder.none,
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
  @override
  _TimeDistributionSectionState createState() => _TimeDistributionSectionState();
}

class _TimeDistributionSectionState extends State<TimeDistributionSection> {
  final c = Get.find<DashboardController>();

  final List<String> activityOptions = [
    'Rig-up/Service', 'Drilling', 'Circulating', 'Tripping', 'Survey',
    'Logging', 'Run Casing', 'Testing', 'Coring/Reaming', 'Cementing'
  ];

  final ScrollController scrollController = ScrollController();

  List<List<dynamic>> tableData = [
    ['1', 'Rig-up/Service', '2.00'],
    ['2', 'Drilling', '2.30'],
    ['3', 'Circulating', '3.00'],
    ['4', 'Tripping', '2.00'],
    ['5', 'Survey', '1.30'],
    ['6', 'Tripping', '4.00'],
    ['7', 'Cementing', '6.40'],
  ];

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xff0d9488),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text("Time Distribution", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),

          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(40),
                      1: FixedColumnWidth(110),
                      2: FixedColumnWidth(70),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Color(0xfff0f9ff)),
                        children: [
                          _buildHeaderCell("#"),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xff0d9488)), textAlign: TextAlign.center),
    );
  }

  TableRow _buildDataRow(int rowIndex, List<dynamic> rowData) {
    final TextEditingController timeController = TextEditingController(text: rowData[2]);

    return TableRow(
      decoration: BoxDecoration(color: rowIndex % 2 == 0 ? Colors.white : Colors.grey.shade50),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(rowData[0], style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.center),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Text(rowData[1], style: TextStyle(fontSize: 9, color: Colors.grey.shade700), textAlign: TextAlign.left),
                )
              : Container(
                  height: 20,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(4)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: rowData[1],
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
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(option, style: TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Obx(() => c.isLocked.value
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    timeController.text.isNotEmpty ? timeController.text : '-',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                )
              : Container(
                  height: 20,
                  child: TextField(
                    controller: timeController,
                    style: TextStyle(fontSize: 9, height: 1.2),
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      tableData[rowIndex][2] = value;
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                      border: InputBorder.none,
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