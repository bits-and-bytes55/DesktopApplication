import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ReportManagerController extends GetxController {
  final ReportApiService _api;

  ReportManagerController({ReportApiService? api})
    : _api = api ?? ReportApiService();

  final rows = <ReportManagerRow>[].obs;
  final isLoading = false.obs;
  final isDeleting = false.obs;
  final errorMessage = ''.obs;
  final selectedReportId = ''.obs;

  Worker? _wellWorker;

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      loadForSelectedWell();
    });
    loadForSelectedWell();
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    super.onClose();
  }

  ReportManagerRow? get selectedRow => _firstWhereOrNull(
    rows,
    (item) => item.reportId == selectedReportId.value,
  );

  bool get hasSelection => selectedRow != null;

  Future<void> loadForSelectedWell({String? preferredReportId}) async {
    final wellId = currentBackendWellId;
    final retainedSelection = preferredReportId?.trim().isNotEmpty == true
        ? preferredReportId!.trim()
        : selectedReportId.value.trim().isNotEmpty
        ? selectedReportId.value.trim()
        : reportContext.selectedReportId.value.trim();

    errorMessage.value = '';

    if (wellId.isEmpty) {
      rows.clear();
      selectedReportId.value = '';
      return;
    }

    isLoading.value = true;

    try {
      final fetched = await _api.fetchReportManagerRows(wellId);
      rows.assignAll(fetched);

      final preserved = _firstWhereOrNull(
        fetched,
        (item) => item.reportId == retainedSelection,
      );
      selectedReportId.value = preserved?.reportId ?? '';
    } catch (e) {
      rows.clear();
      selectedReportId.value = '';
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshRows() => loadForSelectedWell();

  void selectRow(String reportId) {
    final row = _firstWhereOrNull(rows, (item) => item.reportId == reportId);
    selectedReportId.value = row?.reportId ?? '';
  }

  void clearSelection() {
    selectedReportId.value = '';
  }

  Future<void> activateSelectedReport() async {
    final row = selectedRow;
    if (row == null) {
      throw Exception('Select a report first.');
    }

    await reportContext.loadForSelectedWell(preferredReportId: row.reportId);
    reportContext.selectReport(row.reportId);

    final dashboard = Get.find<DashboardController>();
    dashboard.navigate('report:${row.reportId}');
    dashboard.closeOverlay();
  }

  Future<void> deleteSelectedReport() async {
    final row = selectedRow;
    if (row == null) {
      throw Exception('Select a report first.');
    }

    isDeleting.value = true;

    try {
      await _api.deleteReport(row.reportId);
      clearSelection();
      await reportContext.loadForSelectedWell();
      await loadForSelectedWell(
        preferredReportId: reportContext.selectedReportId.value,
      );

      final dashboard = Get.find<DashboardController>();
      final activeReportId = reportContext.selectedReportId.value.trim();
      if (activeReportId.isNotEmpty) {
        dashboard.navigate('report:$activeReportId');
      }
    } finally {
      isDeleting.value = false;
    }
  }
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
    return 'Report Manager API returned an invalid response. Refresh and try again.';
  }
  if (raw.contains('request timed out') ||
      raw.contains('SocketException') ||
      raw.contains('connection refused')) {
    return 'Report Manager data could not be loaded right now. Refresh and try again.';
  }
  return raw;
}
