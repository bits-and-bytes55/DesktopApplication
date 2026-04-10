import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ReportContextController extends GetxController {
  final ReportApiService _api;

  ReportContextController({ReportApiService? api})
    : _api = api ?? ReportApiService();

  final reports = <AppReport>[].obs;
  final selectedReportId = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _wellWorker;

  @override
  void onInit() {
    super.onInit();
    final padWellC = padWellContext;
    _wellWorker = ever<String>(padWellC.selectedWellId, (_) {
      loadForSelectedWell();
    });
    loadForSelectedWell();
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    super.onClose();
  }

  AppReport? get selectedReport {
    if (selectedReportId.value.isEmpty) return null;
    return _firstWhereOrNull(
      reports,
      (item) => item.id == selectedReportId.value,
    );
  }

  bool get hasSelectedReport => selectedReport != null;

  String get selectedReportNumber => selectedReport?.reportNo ?? '';

  String get selectedReportDate => selectedReport?.reportDate ?? '';

  bool get isWorkflowComplete =>
      padWellContext.isSelectedPadReadyForWellCreation &&
      padWellContext.isSelectedWellReadyForReportCreation &&
      hasSelectedReport;

  String get nextSuggestedReportNo {
    var maxValue = 0;
    for (final report in reports) {
      final parsed = int.tryParse(report.reportNo.trim());
      if (parsed != null && parsed > maxValue) {
        maxValue = parsed;
      }
    }
    return (maxValue + 1).toString();
  }

  Future<void> reloadData() => loadForSelectedWell();

  Future<void> loadForSelectedWell() async {
    final wellId = currentBackendWellId;
    errorMessage.value = '';
    final previousSelectedId = selectedReportId.value;

    if (wellId.isEmpty) {
      reports.clear();
      selectedReportId.value = '';
      return;
    }

    isLoading.value = true;

    try {
      final fetched = await _api.fetchReports(wellId);
      reports.assignAll(fetched);

      final preserved = _firstWhereOrNull(
        fetched,
        (item) => item.id == previousSelectedId,
      );

      if (preserved != null) {
        selectedReportId.value = preserved.id;
      } else if (fetched.isNotEmpty) {
        selectedReportId.value = fetched.first.id;
      } else {
        selectedReportId.value = '';
      }
    } catch (e) {
      reports.clear();
      selectedReportId.value = '';
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> createReport(
    Map<String, dynamic> payload,
  ) async {
    final wellId = currentBackendWellId;
    if (wellId.isEmpty) {
      throw Exception('No backend well selected');
    }

    final result = await _api.createReport({'wellId': wellId, ...payload});

    final reportId = _extractEntityId(result['data']);
    await loadForSelectedWell();
    if (reportId.isNotEmpty) {
      selectReport(reportId);
    }

    return result;
  }

  Future<Map<String, dynamic>> updateSelectedReport(
    Map<String, dynamic> payload,
  ) async {
    final report = selectedReport;
    if (report == null) {
      throw Exception('No report selected');
    }

    final result = await _api.updateReport(report.id, payload);
    await loadForSelectedWell();
    selectReport(report.id);
    return result;
  }

  void selectReport(String reportId) {
    final report = _firstWhereOrNull(reports, (item) => item.id == reportId);
    if (report == null) return;
    selectedReportId.value = report.id;
  }
}

ReportContextController get reportContext =>
    Get.isRegistered<ReportContextController>()
    ? Get.find<ReportContextController>()
    : Get.put(ReportContextController());

String _extractEntityId(dynamic data) {
  if (data is Map<String, dynamic>) {
    return (data['_id'] ?? data['id'] ?? '').toString().trim();
  }
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    return (map['_id'] ?? map['id'] ?? '').toString().trim();
  }
  return '';
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

String _friendlyError(Object error) {
  final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (raw.contains('HTML error page returned')) {
    return 'Report API returned an invalid response. Refresh and try again.';
  }
  if (raw.contains('request timed out') ||
      raw.contains('SocketException') ||
      raw.contains('connection refused')) {
    return 'Report data could not be loaded right now. Refresh and try again.';
  }
  return raw;
}
