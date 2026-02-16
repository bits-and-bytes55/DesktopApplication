import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/model/well_comparision_model.dart';

class WellComparisonController extends GetxController {
  // Left side pads + reports
  var pads = <PadModel>[].obs;

  // Right side comparison list
  var comparedReports = <ReportModel>[].obs;

  // Toggle checkbox
  void toggleReport(ReportModel report, bool selected) {
    report.isSelected.value = selected;

    if (selected) {
      if (!comparedReports.contains(report)) {
        comparedReports.add(report);
      }
    } else {
      comparedReports.remove(report);
    }
  }

  // Delete from right table
  void deleteComparedReport(ReportModel report) {
    report.isSelected.value = false;
    comparedReports.remove(report);
  }

  // Dummy add pad (later file picker) - Now adds only one report per pad
  void addDummyPad() {
    final padNumber = pads.length + 1;
    
    pads.add(
      PadModel(
        padName: "UN-${300 + padNumber}",
        reports: [
          ReportModel(
            wellName: "TEST WELL ${padNumber}",
            operator: "Big Find",
            fieldBlock: "Big Find",
            api: "${1703127115 + padNumber}",
            rig: "528",
            spudDate: "1/4/2022",
            status: "✔",
          ),
        ].obs,
      ),
    );
  }
}