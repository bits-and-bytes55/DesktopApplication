import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ReportConcentrationRow {
  const ReportConcentrationRow({
    required this.sourceType,
    required this.product,
    required this.descriptor,
    required this.secondaryMetricLabel,
    required this.secondaryMetric,
    required this.primaryMetricLabel,
    required this.primaryMetric,
    required this.unit,
  });

  final String sourceType;
  final String product;
  final String descriptor;
  final String secondaryMetricLabel;
  final double? secondaryMetric;
  final String primaryMetricLabel;
  final double primaryMetric;
  final String unit;
}

class ReportConcentrationReferenceRow {
  const ReportConcentrationReferenceRow({
    required this.index,
    required this.report,
    required this.system,
    required this.snapshotType,
    required this.snapshotState,
    required this.isSelected,
  });

  final int index;
  final AppReport report;
  final String system;
  final String snapshotType;
  final String snapshotState;
  final bool isSelected;
}

class ReportConcentrationController extends GetxController {
  final systems = const <String>[
    'Active System',
    'Sand Trap',
    'Desander 1A',
    'Desilter 1B',
    'Intermediate 2A',
    'Intermediate 2B',
    'Intermediate 2C',
    'Suction 4A',
    'Suction 4B',
    'Reserve 5A',
    'Reserve 5B',
    'Reserve 6A',
    'Reserve 6B',
    'Pill 3A',
    'Pill 3B',
    'Slug 3C',
    'Trip Tank',
  ];

  final selectedSystem = 'Active System'.obs;
  final currentRows = <ReportConcentrationRow>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final updatedLabel = ''.obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  int get premixedCount =>
      currentRows.where((row) => row.sourceType == 'Premixed').length;

  int get obmCount =>
      currentRows.where((row) => row.sourceType == 'OBM').length;

  String get currentWellLabel {
    final label = padWellContext.selectedWellName.trim();
    return label.isEmpty ? 'No well selected' : label;
  }

  String get selectedReportLabel {
    final report = reportContext.selectedReport;
    if (report == null) {
      return '';
    }

    final reportNo = report.reportNo.trim();
    if (reportNo.isNotEmpty) {
      return 'Rpt $reportNo';
    }

    final userReportNo = report.userReportNo.trim();
    if (userReportNo.isNotEmpty) {
      return 'Rpt $userReportNo';
    }

    return report.displayName;
  }

  String get summaryText {
    final parts = <String>[
      currentWellLabel,
      selectedSystem.value,
      'Rows ${currentRows.length}',
      'Premixed $premixedCount',
      'OBM $obmCount',
    ];

    final reportLabel = selectedReportLabel;
    if (reportLabel.isNotEmpty) {
      parts.add(reportLabel);
    }

    if (updatedLabel.value.isNotEmpty) {
      parts.add(updatedLabel.value);
    }

    return parts.join(' | ');
  }

  String get guidanceText {
    if (currentRows.isEmpty) {
      return 'No premixed or OBM concentration rows are available for this well.';
    }
    return 'Premixed rows use MW and OBM rows use concentration from the UG inventory snapshot.';
  }

  List<ReportConcentrationRow> get chartRows {
    final rows = currentRows.where((row) => row.primaryMetric > 0).toList()
      ..sort(
        (left, right) => right.primaryMetric.compareTo(left.primaryMetric),
      );
    return rows.take(8).toList();
  }

  List<ReportConcentrationReferenceRow> get referenceRows {
    final reports = reportContext.reports.toList();
    final snapshotState = currentRows.isEmpty
        ? 'No live concentration snapshot'
        : '${currentRows.length} rows | Premixed $premixedCount | OBM $obmCount';

    return reports.asMap().entries.map((entry) {
      final report = entry.value;
      return ReportConcentrationReferenceRow(
        index: entry.key + 1,
        report: report,
        system: selectedSystem.value,
        snapshotType: 'Live UG Snapshot',
        snapshotState: snapshotState,
        isSelected: report.id == reportContext.selectedReportId.value,
      );
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      refreshData();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      refreshData();
    });
    refreshData();
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    super.onClose();
  }

  void updateSelectedSystem(String? system) {
    if (system == null) {
      return;
    }

    final trimmed = system.trim();
    if (trimmed.isEmpty || trimmed == selectedSystem.value) {
      return;
    }

    selectedSystem.value = trimmed;
  }

  Future<void> refreshData() async {
    final wellId = currentBackendWellId.trim();
    if (wellId.isEmpty) {
      currentRows.clear();
      updatedLabel.value = '';
      errorMessage.value = 'Select a well to load concentration snapshot.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final rawData = await InventoryProductsService.getInventoryData(wellId);
      final data = _map(rawData);

      final rows = <ReportConcentrationRow>[
        ..._buildPremixedRows(_list(data['premixed'])),
        ..._buildObmRows(_list(data['obm'])),
      ];

      rows.sort((left, right) {
        final sourceCompare = _sourceRank(
          left.sourceType,
        ).compareTo(_sourceRank(right.sourceType));
        if (sourceCompare != 0) {
          return sourceCompare;
        }
        return left.product.toLowerCase().compareTo(
          right.product.toLowerCase(),
        );
      });

      currentRows.assignAll(rows);
      updatedLabel.value = _formatUpdatedLabel(data['updatedAt']);
    } catch (e) {
      currentRows.clear();
      updatedLabel.value = '';
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  List<ReportConcentrationRow> _buildPremixedRows(
    List<Map<String, dynamic>> items,
  ) {
    return items
        .map(PremixModel.fromJson)
        .where((item) => item.description.trim().isNotEmpty)
        .map((item) {
          final mw = _number(item.mw);
          return ReportConcentrationRow(
            sourceType: 'Premixed',
            product: item.description.trim(),
            descriptor: item.mudType.trim().isEmpty ? '-' : item.mudType.trim(),
            secondaryMetricLabel: 'MW',
            secondaryMetric: mw > 0 ? mw : null,
            primaryMetricLabel: 'MW',
            primaryMetric: mw,
            unit: 'ppg',
          );
        })
        .toList();
  }

  List<ReportConcentrationRow> _buildObmRows(List<Map<String, dynamic>> items) {
    return items
        .map(ObmModel.fromJson)
        .where((item) => item.product.trim().isNotEmpty)
        .map((item) {
          final sg = _number(item.sg);
          final conc = _number(item.conc);
          final unit = item.unit.trim().isEmpty ? 'lb/bbl' : item.unit.trim();

          return ReportConcentrationRow(
            sourceType: 'OBM',
            product: item.product.trim(),
            descriptor: item.code.trim().isEmpty ? '-' : item.code.trim(),
            secondaryMetricLabel: 'SG',
            secondaryMetric: sg > 0 ? sg : null,
            primaryMetricLabel: 'Conc',
            primaryMetric: conc,
            unit: unit,
          );
        })
        .toList();
  }

  int _sourceRank(String sourceType) {
    switch (sourceType) {
      case 'Premixed':
        return 0;
      case 'OBM':
        return 1;
      default:
        return 9;
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  double _number(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }

    final cleaned = value
        .toString()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatUpdatedLabel(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return '';
    }

    final local = parsed.toLocal();
    return 'Snapshot ${_two(local.day)}/${_two(local.month)}/${local.year} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
