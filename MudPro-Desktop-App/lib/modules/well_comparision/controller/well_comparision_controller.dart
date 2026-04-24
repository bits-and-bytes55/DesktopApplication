import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/model/well_comparision_model.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';

class WellComparisonController extends GetxController {
  final PadWellController padWellC = padWellContext;
  final ReportApiService _reportApi;

  WellComparisonController({ReportApiService? reportApi})
    : _reportApi = reportApi ?? ReportApiService();

  final pads = <PadModel>[].obs;
  final comparedReports = <ReportModel>[].obs;
  final isLoading = false.obs;
  final isComparing = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    refreshPads();
  }

  int get selectedReportCount => _selectedReports.length;

  List<ReportModel> get _selectedReports {
    final reports = <ReportModel>[];
    for (final pad in pads) {
      for (final well in pad.wells) {
        for (final report in well.reports) {
          if (report.isSelected.value) {
            reports.add(report);
          }
        }
      }
    }
    return reports;
  }

  void toggleReport(ReportModel report, bool selected) {
    report.isSelected.value = selected;
    if (!selected) {
      comparedReports.removeWhere((item) => item.reportId == report.reportId);
    }
  }

  void compareSelectedReports() {
    isComparing.value = true;
    comparedReports.assignAll(_selectedReports);
    isComparing.value = false;
  }

  void clearComparedReports() {
    for (final report in comparedReports) {
      report.isSelected.value = false;
    }
    comparedReports.clear();
  }

  void deleteComparedReport(ReportModel report) {
    report.isSelected.value = false;
    comparedReports.removeWhere((item) => item.reportId == report.reportId);
  }

  Future<void> refreshPads() async {
    final previousSelectedIds = _selectedReports
        .map((report) => report.reportId)
        .toSet();
    final previousComparedIds = comparedReports
        .map((report) => report.reportId)
        .toSet();

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await padWellC.reloadData();

      final reportRowsByWellId = await _loadReportRowsByWellId(
        padWellC.wells.toList(),
      );

      final nextPads = padWellC.pads.map((pad) {
        final padWells = padWellC.wellsForPad(pad.id);

        return PadModel(
          padId: pad.id,
          padName: pad.displayName,
          wells: padWells
              .map(
                (well) => ComparisonWellModel(
                  wellId: well.id,
                  wellName: well.displayName,
                  operatorName: pad.operator,
                  fieldBlock: pad.fieldBlock,
                  apiWellNo: well.apiWellNo,
                  rig: pad.rig,
                  spudDate: well.spudDate,
                  reports:
                      (reportRowsByWellId[well.id] ??
                              const <ReportManagerRow>[])
                          .map(
                            (row) => _mapReportRow(
                              pad: pad,
                              well: well,
                              row: row,
                              selected: previousSelectedIds.contains(
                                row.reportId,
                              ),
                            ),
                          )
                          .toList()
                          .obs,
                ),
              )
              .toList()
              .obs,
        );
      }).toList();

      pads.assignAll(nextPads);

      final nextCompared = <ReportModel>[];
      for (final pad in nextPads) {
        for (final well in pad.wells) {
          for (final report in well.reports) {
            if (previousComparedIds.contains(report.reportId)) {
              nextCompared.add(report);
            }
          }
        }
      }
      comparedReports.assignAll(nextCompared);
    } catch (e) {
      pads.clear();
      comparedReports.clear();
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
      isComparing.value = false;
    }
  }

  Future<Map<String, List<ReportManagerRow>>> _loadReportRowsByWellId(
    List<AppWell> wells,
  ) async {
    final entries = await Future.wait(
      wells.map((well) async {
        try {
          final rows = await _reportApi.fetchReportManagerRows(well.id);
          return MapEntry(well.id, rows);
        } catch (_) {
          return MapEntry(well.id, const <ReportManagerRow>[]);
        }
      }),
    );

    return Map<String, List<ReportManagerRow>>.fromEntries(entries);
  }

  ReportModel _mapReportRow({
    required AppPad pad,
    required AppWell well,
    required ReportManagerRow row,
    required bool selected,
  }) {
    return ReportModel(
      reportId: row.reportId,
      reportNo: row.reportNo,
      userReportNo: row.userReportNo,
      reportDate: row.reportDate,
      title: row.title,
      wellId: well.id,
      wellName: well.displayName,
      operatorName: pad.operator,
      fieldBlock: pad.fieldBlock,
      apiWellNo: well.apiWellNo,
      rig: pad.rig,
      spudDate: well.spudDate,
      activity: row.activity,
      interval: row.interval,
      mudType: row.mudType,
      recommendedTreatment: row.recommendedTreatment,
      remarks: row.remarks,
      recapRemarks: row.recapRemarks,
      internalNotes: row.internalNotes,
      md: row.md,
      mw: row.mw,
      dailyCost: row.dailyCost,
      cumulativeCost: row.cumulativeCost,
      isSelected: selected.obs,
    );
  }
}

String _friendlyError(Object error) {
  final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (raw.contains('HTML error page returned')) {
    return 'Well Comparison data returned an invalid response. Refresh and try again.';
  }
  if (raw.contains('request timed out') ||
      raw.contains('SocketException') ||
      raw.contains('connection refused')) {
    return 'Well Comparison data could not be loaded right now. Refresh and try again.';
  }
  return raw;
}
