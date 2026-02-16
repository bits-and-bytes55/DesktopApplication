// ==================== CONTROLLER ====================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'dart:async';

class DashboardController extends GetxController {
  var activePrimaryTab = 0.obs;
  var activeSectionTab = 0.obs;
  var activeSecondaryTab = (-1).obs; // No active tab initially
  var isLocked = true.obs;
  var reports = <String>[].obs;
  var selectedReport = 11.obs; // #12 selected
  var casings = <List<String>>[].obs;

  // Debouncing for frequent updates
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 100);

  void toggleLock() => isLocked.toggle();

  @override
  void onInit() {
    generateDummyReports();
    generateDummyCasings();
    super.onInit();
  }



  /// secondary tab index per primary tab
 var activeHomeTab = (-1).obs;
  var activeReportTab = (-1).obs;
  var activeUtilityTab = (-1).obs;
  var activeHelpTab = (-1).obs;

  /// overlay page (null = no overlay)
  Rx<Widget?> overlayPage = Rx<Widget?>(null);

  void openOverlay(Widget page) {
    overlayPage.value = page;
  }

  void closeOverlay() {
    overlayPage.value = null;
  }

  void setPrimaryTab(int index) {
    _debounce(() {
      activePrimaryTab.value = index;
      activeSecondaryTab.value = -1; // reset secondary to no active tab
    });
  }

  void _debounce(Function action) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(_debounceDuration, () => action());
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

 // 👇 All actions kept here (clean separation)
  void createNewReport(BuildContext context) {}
  void openFolder(BuildContext context) {}
  void saveReport(BuildContext context, bool saveAs) {}
  void openCarryOverPad(BuildContext context) {}
  void carryOver(BuildContext context) {}
  void performCalculations(BuildContext context) {}
  void showOptions(BuildContext context) {}
  void showMudCompanySetup(BuildContext context) {}
  void uploadFile(BuildContext context) {}
  void batchUpload(BuildContext context) {}
  

  void generateDummyReports() {
    reports.assignAll([
      "#1  7830.0 ft",
      "#2  7830.0 ft",
      "#3  7830.0 ft",
      "#4  7843.0 ft",
      "#5  7855.0 ft",
      "#6  7890.0 ft",
      "#7  7930.0 ft",
      "#8  8630.0 ft",
      "#9  9055.0 ft",
      "#10  9055.0 ft",
      "#11  9055.0 ft",
      "#12  7830.0 ft",
    ]);
  }

  void generateDummyCasings() {
    casings.assignAll([
      ['9 5/8" Casing', "9.625", "47.000", "8.681", "0.0", "7830.0", "7830.0"],
      ['Liner', "7.000", "26.000", "6.276", "7590.0", "9053.0", "1463.0"],
    ]);
  }

  void addCasing(String description) {
    if (description.isNotEmpty) {
      casings.add([description, "", "", "", "", "", ""]);
    }
  }


   var selectedNodeId = ''.obs;

  /// Tree data (date → reports)
  final reportsTree = <ReportDate>[
    ReportDate(
      date: '11/26/2025',
      items: [
        '11 7830 ft 23:30',
      ],
    ),
    ReportDate(
      date: '11/27/2025',
      items: [
        '1 7830 ft 23:30',
        '2 7830 ft 23:30',
      ],
    ),
    ReportDate(
      date: '11/28/2025',
      items: [
        '3 7830 ft 23:30',
      ],
    ),
  ].obs;

  void navigate(String id) {
    selectedNodeId.value = id;
    // 👉 yahin se API / report load karna
  }
}

class ReportDate {
  final String date;
  final List<String> items;
  bool expanded;

  ReportDate({
    required this.date,
    required this.items,
    this.expanded = true,
  });
}
