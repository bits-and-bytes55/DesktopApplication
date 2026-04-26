import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/sce_model.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapSceController extends GetxController {
  RecapSceController({
    AuthRepository? repository,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _repository = repository ?? AuthRepository(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  final AuthRepository _repository;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  static const List<String> shakerLabels = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'Mud Cleaner',
    'Dryer',
  ];

  static const List<String> otherSceLabels = [
    'Degasser',
    'Desander',
    'Desilter',
    'Centrifuge',
    'Barite Rec.',
  ];

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final shakers = <RecapSceShakerRow>[].obs;
  final otherSce = <RecapSceOtherRow>[].obs;
  final plottedItems = <RecapScePlotItem>[].obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(_padWellController.selectedWellId, (_) => load());
    _reportWorker = ever<String>(_reportContext.selectedReportId, (_) => load());
    load();
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final wellId = currentBackendWellId.trim();
    errorMessage.value = '';
    emptyMessage.value = '';

    if (wellId.isEmpty) {
      shakers.clear();
      otherSce.clear();
      plottedItems.clear();
      emptyMessage.value = 'Select a well first to open Solid Control Equipment recap.';
      return;
    }

    isLoading.value = true;
    try {
      final shakerResult = await _repository.getShakers(wellId);
      final otherResult = await _repository.getOtherSce(wellId);

      if (!(shakerResult['success'] == true) && !(otherResult['success'] == true)) {
        throw Exception(
          shakerResult['message'] ??
              otherResult['message'] ??
              'Failed to load SCE recap data.',
        );
      }

      final shakerModels = (shakerResult['data'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => ShakerModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      final otherModels = (otherResult['data'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => OtherSceModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      shakers.assignAll(_buildShakerRows(shakerModels));
      otherSce.assignAll(_buildOtherRows(otherModels));
      plottedItems.assignAll(_buildPlotItems());

      if (!_hasVisibleData()) {
        emptyMessage.value =
            'No saved Solid Control Equipment rows are available for the selected report.';
      }
    } catch (error) {
      shakers.clear();
      otherSce.clear();
      plottedItems.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  bool _hasVisibleData() {
    return shakers.any((item) => item.hasData) || otherSce.any((item) => item.hasData);
  }

  List<RecapSceShakerRow> _buildShakerRows(List<ShakerModel> items) {
    final ordered = <RecapSceShakerRow>[];
    final byLabel = <String, ShakerModel>{};

    for (final item in items) {
      final label = item.shaker.value.trim();
      if (label.isEmpty) continue;
      byLabel[label.toLowerCase()] = item;
    }

    for (final label in shakerLabels) {
      ordered.add(
        RecapSceShakerRow(
          label: label,
          model: byLabel[label.toLowerCase()]?.model.value.trim() ?? '',
          screens: byLabel[label.toLowerCase()]?.screens.value.trim() ?? '',
          time: byLabel[label.toLowerCase()]?.time.value.trim() ?? '',
          plot: byLabel[label.toLowerCase()]?.plot.value ?? false,
        ),
      );
    }

    for (final item in items) {
      final label = item.shaker.value.trim();
      if (label.isEmpty ||
          shakerLabels.any((known) => known.toLowerCase() == label.toLowerCase())) {
        continue;
      }

      ordered.add(
        RecapSceShakerRow(
          label: label,
          model: item.model.value.trim(),
          screens: item.screens.value.trim(),
          time: item.time.value.trim(),
          plot: item.plot.value,
        ),
      );
    }

    return ordered;
  }

  List<RecapSceOtherRow> _buildOtherRows(List<OtherSceModel> items) {
    final ordered = <RecapSceOtherRow>[];
    final byLabel = <String, OtherSceModel>{};

    for (final item in items) {
      final label = item.type.value.trim();
      if (label.isEmpty) continue;
      byLabel[label.toLowerCase()] = item;
    }

    for (final label in otherSceLabels) {
      ordered.add(
        RecapSceOtherRow(
          label: label,
          model1: byLabel[label.toLowerCase()]?.model1.value.trim() ?? '',
          model2: byLabel[label.toLowerCase()]?.model2.value.trim() ?? '',
          model3: byLabel[label.toLowerCase()]?.model3.value.trim() ?? '',
          uf: byLabel[label.toLowerCase()]?.uf.value.trim() ?? '',
          of: byLabel[label.toLowerCase()]?.of.value.trim() ?? '',
          time: byLabel[label.toLowerCase()]?.time.value.trim() ?? '',
          plot: byLabel[label.toLowerCase()]?.plot.value ?? false,
        ),
      );
    }

    for (final item in items) {
      final label = item.type.value.trim();
      if (label.isEmpty ||
          otherSceLabels.any((known) => known.toLowerCase() == label.toLowerCase())) {
        continue;
      }

      ordered.add(
        RecapSceOtherRow(
          label: label,
          model1: item.model1.value.trim(),
          model2: item.model2.value.trim(),
          model3: item.model3.value.trim(),
          uf: item.uf.value.trim(),
          of: item.of.value.trim(),
          time: item.time.value.trim(),
          plot: item.plot.value,
        ),
      );
    }

    return ordered;
  }

  List<RecapScePlotItem> _buildPlotItems() {
    final items = <RecapScePlotItem>[];

    for (final shaker in shakers.where((item) => item.plot && item.hasData)) {
      items.add(
        RecapScePlotItem(
          title: shaker.label,
          subtitle: _joinValues([shaker.model, shaker.screensLabel, shaker.timeLabel]),
          isOtherSce: false,
        ),
      );
    }

    for (final item in otherSce.where((row) => row.plot && row.hasData)) {
      items.add(
        RecapScePlotItem(
          title: item.label,
          subtitle: _joinValues([
            item.modelSummary,
            item.ufLabel,
            item.ofLabel,
            item.timeLabel,
          ]),
          isOtherSce: true,
        ),
      );
    }

    return items;
  }
}

class RecapSceShakerRow {
  final String label;
  final String model;
  final String screens;
  final String time;
  final bool plot;

  const RecapSceShakerRow({
    required this.label,
    required this.model,
    required this.screens,
    required this.time,
    required this.plot,
  });

  bool get hasData => model.isNotEmpty || screens.isNotEmpty || time.isNotEmpty;
  String get screensLabel => screens.isEmpty ? '' : '$screens screens';
  String get timeLabel => time.isEmpty ? '' : '$time hr';
}

class RecapSceOtherRow {
  final String label;
  final String model1;
  final String model2;
  final String model3;
  final String uf;
  final String of;
  final String time;
  final bool plot;

  const RecapSceOtherRow({
    required this.label,
    required this.model1,
    required this.model2,
    required this.model3,
    required this.uf,
    required this.of,
    required this.time,
    required this.plot,
  });

  bool get hasData =>
      model1.isNotEmpty ||
      model2.isNotEmpty ||
      model3.isNotEmpty ||
      uf.isNotEmpty ||
      of.isNotEmpty ||
      time.isNotEmpty;

  String get modelSummary => _joinValues([model1, model2, model3], separator: ' / ');
  String get ufLabel => uf.isEmpty ? '' : 'UF $uf';
  String get ofLabel => of.isEmpty ? '' : 'OF $of';
  String get timeLabel => time.isEmpty ? '' : '$time hr';
}

class RecapScePlotItem {
  final String title;
  final String subtitle;
  final bool isOtherSce;

  const RecapScePlotItem({
    required this.title,
    required this.subtitle,
    required this.isOtherSce,
  });
}

String _joinValues(Iterable<String> values, {String separator = '  |  '}) {
  return values.map((item) => item.trim()).where((item) => item.isNotEmpty).join(separator);
}
