import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mudpro_desktop_app/modules/report/model/cost_of_pad_model.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_models.dart';

class CostOfPadController extends GetxController {
  final ReportApiService _api;
  final PadWellController _padWellController;

  CostOfPadController({
    ReportApiService? api,
    PadWellController? padWellController,
  }) : _api = api ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext;

  final selectedPadId = ''.obs;
  final snapshot = Rxn<PadCostSnapshot>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  PadWellController get padWellController => _padWellController;

  AppPad? get selectedPad => _firstWhereOrNull(
    _padWellController.pads,
    (pad) => pad.id == selectedPadId.value,
  );

  @override
  void onInit() {
    super.onInit();
    syncWithCurrentPad();
  }

  Future<void> syncWithCurrentPad({
    bool preferExistingSelection = false,
  }) async {
    if (_padWellController.pads.isEmpty &&
        !_padWellController.isLoading.value) {
      await _padWellController.reloadData();
    }

    final nextPadId = _pickPadId(
      preferExistingSelection: preferExistingSelection,
    );
    if (nextPadId.isEmpty) {
      selectedPadId.value = '';
      snapshot.value = null;
      errorMessage.value = _padWellController.errorMessage.value;
      return;
    }

    selectedPadId.value = nextPadId;
    await loadForSelectedPad();
  }

  Future<void> refreshPadData() async {
    await _padWellController.reloadData();
    await syncWithCurrentPad(preferExistingSelection: true);
  }

  Future<void> selectPad(String padId) async {
    if (padId.trim().isEmpty) return;
    selectedPadId.value = padId.trim();
    await loadForSelectedPad();
  }

  Future<void> loadForSelectedPad() async {
    final pad = selectedPad;
    errorMessage.value = '';

    if (pad == null) {
      snapshot.value = null;
      return;
    }

    final wells = _padWellController.wellsForPad(pad.id);
    if (wells.isEmpty) {
      snapshot.value = PadCostSnapshot(
        pad: pad,
        wells: const <WellCostSummary>[],
        reports: const <PadCostReportRow>[],
        activityBreakdown: const <CostBucketSummary>[],
        mudTypeBreakdown: const <CostBucketSummary>[],
      );
      return;
    }

    isLoading.value = true;

    try {
      final results = await Future.wait(
        wells.map((well) async {
          try {
            final rows = await _api.fetchReportManagerRows(well.id);
            return _WellLoadResult(well: well, rows: rows);
          } catch (e) {
            return _WellLoadResult(
              well: well,
              rows: const <ReportManagerRow>[],
              error: '${well.displayName}: ${_friendlyError(e)}',
            );
          }
        }),
      );

      final failures = results
          .where((item) => item.error.isNotEmpty)
          .map((item) => item.error)
          .toList();

      snapshot.value = _buildSnapshot(pad, results);
      errorMessage.value = failures.isEmpty
          ? ''
          : 'Some wells could not be refreshed: ${failures.join(' | ')}';
    } catch (e) {
      snapshot.value = null;
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  String _pickPadId({required bool preferExistingSelection}) {
    final availablePadIds = _padWellController.pads
        .map((pad) => pad.id)
        .toSet();
    final currentPadId = _padWellController.selectedPadId.value.trim();
    final existingPadId = selectedPadId.value.trim();

    if (preferExistingSelection && availablePadIds.contains(existingPadId)) {
      return existingPadId;
    }
    if (availablePadIds.contains(currentPadId)) {
      return currentPadId;
    }
    if (availablePadIds.contains(existingPadId)) {
      return existingPadId;
    }
    return _padWellController.pads.isEmpty
        ? ''
        : _padWellController.pads.first.id;
  }

  PadCostSnapshot _buildSnapshot(AppPad pad, List<_WellLoadResult> results) {
    final wellSummaries = results.map(_buildWellSummary).toList()
      ..sort((left, right) {
        final cumulativeCompare = right.latestCumulativeCost.compareTo(
          left.latestCumulativeCost,
        );
        if (cumulativeCompare != 0) return cumulativeCompare;
        return left.well.displayName.toLowerCase().compareTo(
          right.well.displayName.toLowerCase(),
        );
      });

    final reports = <PadCostReportRow>[
      for (final summary in wellSummaries)
        for (final row in summary.rows)
          PadCostReportRow(
            well: summary.well,
            row: row,
            isLatestForWell: summary.latestRow?.reportId == row.reportId,
          ),
    ]..sort((left, right) => _compareRowsNewest(left.row, right.row));

    return PadCostSnapshot(
      pad: pad,
      wells: wellSummaries,
      reports: reports,
      activityBreakdown: _buildBreakdown(
        reports,
        (report) => report.row.activity,
      ),
      mudTypeBreakdown: _buildBreakdown(
        reports,
        (report) => report.row.mudType,
      ),
    );
  }

  WellCostSummary _buildWellSummary(_WellLoadResult result) {
    final sortedRows = [...result.rows]..sort(_compareRowsNewest);
    final latestRow = sortedRows.isEmpty ? null : sortedRows.first;
    final totalDailyCost = sortedRows.fold<double>(
      0,
      (sum, row) => sum + row.dailyCost,
    );
    final maxMeasuredDepth = sortedRows.fold<double>(
      0,
      (maxValue, row) => row.md > maxValue ? row.md : maxValue,
    );
    final bulkTankSetupFee = _toDouble(result.well.bulkTankSetupFee);

    return WellCostSummary(
      well: result.well,
      rows: sortedRows,
      latestRow: latestRow,
      totalDailyCost: totalDailyCost,
      averageDailyCost: sortedRows.isEmpty
          ? 0
          : totalDailyCost / sortedRows.length,
      latestDailyCost: latestRow?.dailyCost ?? 0,
      latestCumulativeCost: latestRow?.cumulativeCost ?? 0,
      maxMeasuredDepth: maxMeasuredDepth,
      bulkTankSetupFee: bulkTankSetupFee,
      latestReportDate: latestRow?.reportDate ?? '',
    );
  }

  List<CostBucketSummary> _buildBreakdown(
    List<PadCostReportRow> reports,
    String Function(PadCostReportRow report) labelOf,
  ) {
    final grouped = <String, List<PadCostReportRow>>{};

    for (final report in reports) {
      final rawLabel = labelOf(report).trim();
      final label = rawLabel.isEmpty ? 'Unspecified' : rawLabel;
      grouped.putIfAbsent(label, () => <PadCostReportRow>[]).add(report);
    }

    final breakdown =
        grouped.entries.map((entry) {
          final items = entry.value;
          final totalDailyCost = items.fold<double>(
            0,
            (sum, item) => sum + item.row.dailyCost,
          );
          final wellCount = items.map((item) => item.well.id).toSet().length;

          return CostBucketSummary(
            label: entry.key,
            totalDailyCost: totalDailyCost,
            averageDailyCost: items.isEmpty ? 0 : totalDailyCost / items.length,
            reportCount: items.length,
            wellCount: wellCount,
          );
        }).toList()..sort((left, right) {
          final costCompare = right.totalDailyCost.compareTo(
            left.totalDailyCost,
          );
          if (costCompare != 0) return costCompare;
          return left.label.toLowerCase().compareTo(right.label.toLowerCase());
        });

    return breakdown;
  }
}

class _WellLoadResult {
  final AppWell well;
  final List<ReportManagerRow> rows;
  final String error;

  const _WellLoadResult({
    required this.well,
    required this.rows,
    this.error = '',
  });
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

double _toDouble(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9.-]'), '');
  return double.tryParse(normalized) ?? 0;
}

String _friendlyError(Object error) {
  final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (raw.contains('HTML error page returned')) {
    return 'Cost of Pad data returned an invalid response. Refresh and try again.';
  }
  if (raw.contains('request timed out') ||
      raw.contains('SocketException') ||
      raw.contains('connection refused')) {
    return 'Cost of Pad data could not be loaded right now. Refresh and try again.';
  }
  return raw;
}
