import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/model/well_comparision_model.dart';

class WellComparisonController extends GetxController {
  final PadWellController padWellC = padWellContext;

  // Left side pads + reports
  var pads = <PadModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Right side comparison list
  var comparedReports = <ReportModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshPads();
  }

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

  Future<void> refreshPads() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await padWellC.reloadData();
      pads.assignAll(
        padWellC.pads.map((pad) {
          final wells = padWellC.wellsForPad(pad.id);
          return PadModel(
            padName: pad.displayName,
            reports: wells
                .map(
                  (well) => ReportModel(
                    wellName: well.displayName,
                    operator: pad.operator,
                    fieldBlock: pad.fieldBlock,
                    api: well.apiWellNo,
                    rig: pad.rig,
                    spudDate: well.spudDate,
                    status: '',
                  ),
                )
                .toList()
                .obs,
          );
        }).toList(),
      );
      comparedReports.clear();
    } catch (e) {
      pads.clear();
      comparedReports.clear();
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
