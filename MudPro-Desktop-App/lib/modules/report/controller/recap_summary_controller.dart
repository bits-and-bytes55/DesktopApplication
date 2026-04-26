import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';

class RecapSummaryController extends GetxController {
  final ReportApiService _api;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapSummaryController({
    ReportApiService? api,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _api = api ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  final rows = <ReportManagerRow>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _wellWorker;

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(_padWellController.selectedWellId, (_) {
      loadForSelectedWell();
    });
    loadForSelectedWell();
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    super.onClose();
  }

  AppWell? get selectedWell => _padWellController.selectedWell;

  AppPad? get selectedPad => _padWellController.padForWell(selectedWell);

  AppReport? get selectedReport => _reportContext.selectedReport;

  String get selectedReportLabel {
    final report = selectedReport;
    if (report == null) return '';
    if (report.userReportNo.trim().isNotEmpty) {
      return report.userReportNo.trim();
    }
    if (report.reportNo.trim().isNotEmpty) return report.reportNo.trim();
    return '';
  }

  List<ReportManagerRow> get orderedRowsNewest {
    final output = [...rows];
    output.sort(_compareRowsNewest);
    return output;
  }

  ReportManagerRow? get latestRow =>
      orderedRowsNewest.isEmpty ? null : orderedRowsNewest.first;

  ReportManagerRow? get selectedRow {
    final reportId = selectedReport?.id ?? '';
    if (reportId.isEmpty) return null;
    return _firstWhereOrNull(rows, (item) => item.reportId == reportId);
  }

  ReportManagerRow? get activeRow => selectedRow ?? latestRow;

  List<ReportManagerRow> get recentRows => orderedRowsNewest.take(6).toList();

  int get totalReports => rows.length;

  double get maxMeasuredDepth => rows.fold<double>(
    0,
    (maxValue, row) => row.md > maxValue ? row.md : maxValue,
  );

  double get totalDailyCost =>
      rows.fold<double>(0, (sum, row) => sum + row.dailyCost);

  double get averageDailyCost =>
      rows.isEmpty ? 0 : totalDailyCost / rows.length;

  SummaryBreakdownItem? get topActivity =>
      activityBreakdown.isEmpty ? null : activityBreakdown.first;

  SummaryBreakdownItem? get topMudType =>
      mudTypeBreakdown.isEmpty ? null : mudTypeBreakdown.first;

  List<SummaryBreakdownItem> get activityBreakdown =>
      _buildBreakdown((row) => row.activity);

  List<SummaryBreakdownItem> get mudTypeBreakdown =>
      _buildBreakdown((row) => row.mudType);

  Future<void> refreshSummary() => loadForSelectedWell();

  Future<void> loadForSelectedWell() async {
    final wellId = currentBackendWellId;
    errorMessage.value = '';

    if (wellId.isEmpty) {
      rows.clear();
      return;
    }

    isLoading.value = true;

    try {
      final fetched = await _api.fetchReportManagerRows(wellId);
      rows.assignAll(fetched);
    } catch (e) {
      rows.clear();
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  List<SummaryBreakdownItem> _buildBreakdown(
    String Function(ReportManagerRow row) labelOf,
  ) {
    final grouped = <String, List<ReportManagerRow>>{};

    for (final row in rows) {
      final rawLabel = labelOf(row).trim();
      final label = rawLabel.isEmpty ? 'Unspecified' : rawLabel;
      grouped.putIfAbsent(label, () => <ReportManagerRow>[]).add(row);
    }

    final output =
        grouped.entries.map((entry) {
          final totalDailyCost = entry.value.fold<double>(
            0,
            (sum, row) => sum + row.dailyCost,
          );

          return SummaryBreakdownItem(
            label: entry.key,
            reportCount: entry.value.length,
            totalDailyCost: totalDailyCost,
          );
        }).toList()..sort((left, right) {
          final costCompare = right.totalDailyCost.compareTo(
            left.totalDailyCost,
          );
          if (costCompare != 0) return costCompare;
          return left.label.toLowerCase().compareTo(right.label.toLowerCase());
        });

    return output;
  }
}

class SummaryBreakdownItem {
  final String label;
  final int reportCount;
  final double totalDailyCost;

  const SummaryBreakdownItem({
    required this.label,
    required this.reportCount,
    required this.totalDailyCost,
  });

  double get averageDailyCost =>
      reportCount == 0 ? 0 : totalDailyCost / reportCount;
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

int _compareRowsNewest(ReportManagerRow left, ReportManagerRow right) {
  final leftDate = _parseRowDate(left);
  final rightDate = _parseRowDate(right);

  if (leftDate != null && rightDate != null) {
    final dateCompare = rightDate.compareTo(leftDate);
    if (dateCompare != 0) return dateCompare;
  } else if (leftDate != null) {
    return -1;
  } else if (rightDate != null) {
    return 1;
  }

  final leftNo = _reportNumber(left);
  final rightNo = _reportNumber(right);
  if (leftNo != null && rightNo != null) {
    final reportCompare = rightNo.compareTo(leftNo);
    if (reportCompare != 0) return reportCompare;
  } else if (leftNo != null) {
    return -1;
  } else if (rightNo != null) {
    return 1;
  }

  return right.reportLabel.toLowerCase().compareTo(
    left.reportLabel.toLowerCase(),
  );
}

DateTime? _parseRowDate(ReportManagerRow row) {
  for (final value in [row.reportDate, row.createdAt]) {
    final parsed = _tryParseDate(value);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _tryParseDate(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;

  final direct = DateTime.tryParse(text);
  if (direct != null) return direct;

  const patterns = [
    'MM/dd/yyyy',
    'M/d/yyyy',
    'dd/MM/yyyy',
    'd/M/yyyy',
    'MM-dd-yyyy',
    'M-d-yyyy',
    'dd-MM-yyyy',
    'd-M-yyyy',
    'yyyy/MM/dd',
  ];

  for (final pattern in patterns) {
    try {
      return DateFormat(pattern).parseStrict(text);
    } catch (_) {}
  }

  return null;
}

int? _reportNumber(ReportManagerRow row) {
  return int.tryParse(row.reportNo.trim()) ??
      int.tryParse(row.userReportNo.trim());
}

String _friendlyError(Object error) {
  final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (raw.contains('HTML error page returned')) {
    return 'Summary data returned an invalid response. Refresh and try again.';
  }
  if (raw.contains('request timed out') ||
      raw.contains('SocketException') ||
      raw.contains('connection refused')) {
    return 'Summary data could not be loaded right now. Refresh and try again.';
  }
  return raw;
}
