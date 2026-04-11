import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';

class ReportSolidsAnalysisRow {
  const ReportSolidsAnalysisRow({
    required this.label,
    required this.values,
    this.highlight = false,
  });

  final String label;
  final List<String> values;
  final bool highlight;
}

class _SolidsRowConfig {
  const _SolidsRowConfig(this.label, {this.highlight = false});

  final String label;
  final bool highlight;
}

class ReportSolidsAnalysisController extends GetxController {
  final rows = <ReportSolidsAnalysisRow>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final sourceSummary = ''.obs;

  late final MudController _mudController;
  Worker? _reportWorker;

  static const List<_SolidsRowConfig> _configs = [
    _SolidsRowConfig('LGS (%)', highlight: true),
    _SolidsRowConfig('LGS (lb/bbl)'),
    _SolidsRowConfig('HGS (%)'),
    _SolidsRowConfig('Diss Solids (%)'),
    _SolidsRowConfig('Corr. Solids (%)'),
    _SolidsRowConfig('Brine SG'),
    _SolidsRowConfig('HGS (lb/bbl)'),
    _SolidsRowConfig('Bentonite (%)'),
    _SolidsRowConfig('Bentonite (lb/bbl)'),
    _SolidsRowConfig('Drill Solids (%)', highlight: true),
    _SolidsRowConfig('Drill Solids (lb/bbl)'),
    _SolidsRowConfig('DS/Bent Ratio', highlight: true),
    _SolidsRowConfig('Avg. SG of Solids'),
  ];

  @override
  void onInit() {
    super.onInit();
    _mudController = Get.isRegistered<MudController>()
        ? Get.find<MudController>()
        : Get.put(MudController());

    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      refreshData();
    });

    refreshData();
  }

  @override
  void onClose() {
    _reportWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _mudController.fetchSolidAnalysis();
      rows.assignAll(_buildRows());
      sourceSummary.value = _buildSourceSummary();
    } catch (e) {
      rows.assignAll(_buildRows(useExistingResult: false));
      sourceSummary.value = '';
      errorMessage.value = e.toString();
    } finally {
      if (_mudController.solidAnalysisError.value.isNotEmpty) {
        errorMessage.value = _mudController.solidAnalysisError.value;
      }
      isLoading.value = false;
    }
  }

  List<ReportSolidsAnalysisRow> _buildRows({bool useExistingResult = true}) {
    final result = useExistingResult
        ? _mudController.solidAnalysisResult
        : <String, List<String>>{};
    final hasMudInputs = _hasAnyMudWeight();

    return _configs.map((config) {
      final rawValues = hasMudInputs ? result[config.label] : null;
      final values = List<String>.generate(3, (index) {
        if (rawValues == null || index >= rawValues.length) {
          return '-';
        }
        final value = rawValues[index].trim();
        return value.isEmpty ? '-' : value;
      });
      return ReportSolidsAnalysisRow(
        label: config.label,
        values: values,
        highlight: config.highlight,
      );
    }).toList();
  }

  bool _hasAnyMudWeight() {
    final key = _findPropertyKey((value) {
      return value == 'mw' ||
          value.startsWith('mw') ||
          value.contains('mud weight');
    });
    if (key == null) {
      return false;
    }

    final values = _mudController.propertyTable[key];
    if (values == null) {
      return false;
    }

    for (final value in values.take(3)) {
      final number = double.tryParse(value.value.trim());
      if (number != null && number > 0) {
        return true;
      }
    }
    return false;
  }

  String? _findPropertyKey(bool Function(String value) test) {
    for (final key in _mudController.propertyTable.keys) {
      final normalized = _normalize(key);
      if (test(normalized)) {
        return key;
      }
    }
    return null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('*', '')
        .replaceAll('²', '2')
        .replaceAll('²', '2')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _buildSourceSummary() {
    final parts = <String>[
      'Fluid ${_mudController.selectedFluidType.value}',
      'Source Mud table samples 1-3',
    ];

    final mudWeightKey = _findPropertyKey((value) {
      return value == 'mw' ||
          value.startsWith('mw') ||
          value.contains('mud weight');
    });
    if (mudWeightKey != null) {
      final values = _mudController.propertyTable[mudWeightKey] ?? <RxString>[];
      final sampleSummaries = <String>[];
      for (var index = 0; index < values.length && index < 3; index++) {
        final parsed = double.tryParse(values[index].value.trim());
        if (parsed != null && parsed > 0) {
          sampleSummaries.add('S${index + 1} MW ${parsed.toStringAsFixed(2)}');
        }
      }
      if (sampleSummaries.isNotEmpty) {
        parts.add(sampleSummaries.join(', '));
      }
    }

    return parts.join(' | ');
  }
}
