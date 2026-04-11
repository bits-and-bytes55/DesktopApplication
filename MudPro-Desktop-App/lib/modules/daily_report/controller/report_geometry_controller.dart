import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/cased_hole_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/drill_string_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/well_general_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ReportGeometryRow {
  const ReportGeometryRow({
    required this.description,
    required this.startFt,
    required this.endFt,
    required this.volumeBbl,
    required this.volumePerFtBbl,
  });

  final String description;
  final double? startFt;
  final double? endFt;
  final double volumeBbl;
  final double volumePerFtBbl;
}

class ReportGeometryController extends GetxController {
  final rows = <ReportGeometryRow>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final sourceSummary = ''.obs;

  late final CasedHoleUIController _casedHoleController;
  late final DrillStringController _drillStringController;
  late final WellGeneralController _wellGeneralController;

  Worker? _wellWorker;
  Worker? _reportWorker;

  @override
  void onInit() {
    super.onInit();
    _casedHoleController = Get.isRegistered<CasedHoleUIController>()
        ? Get.find<CasedHoleUIController>()
        : Get.put(CasedHoleUIController());
    _drillStringController = Get.isRegistered<DrillStringController>()
        ? Get.find<DrillStringController>()
        : Get.put(DrillStringController());
    _wellGeneralController = Get.isRegistered<WellGeneralController>()
        ? Get.find<WellGeneralController>()
        : Get.put(WellGeneralController());

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

  Future<void> refreshData() async {
    final wellId = padWellContext.selectedWellId.value.trim();
    if (wellId.isEmpty) {
      rows.clear();
      sourceSummary.value = '';
      errorMessage.value = 'Select a well first to load geometry.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await Future.wait([
        _casedHoleController.fetchTableCasings(),
        _drillStringController.fetchDrillStrings(),
        _wellGeneralController.fetchLatest(),
      ]);

      final nextRows = <ReportGeometryRow>[];
      nextRows.addAll(_buildCasingRows());
      nextRows.addAll(_buildOpenHoleRows());
      nextRows.addAll(_buildDrillStringRows());
      nextRows.addAll(_buildPadRows());

      rows.assignAll(nextRows);
      sourceSummary.value = _buildSourceSummary(nextRows);
    } catch (e) {
      rows.clear();
      sourceSummary.value = '';
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  List<ReportGeometryRow> _buildCasingRows() {
    final output = <ReportGeometryRow>[];
    final entries =
        _casedHoleController.entries.where((entry) => entry.hasContent).toList()
          ..sort((left, right) {
            final leftTop = _parseNumber(left.top.text) ?? 0;
            final rightTop = _parseNumber(right.top.text) ?? 0;
            return leftTop.compareTo(rightTop);
          });

    for (final entry in entries) {
      final idIn = _parseNumber(entry.idCtrl.text);
      final startFt = _parseNumber(entry.top.text);
      final endFt = _parseNumber(entry.shoe.text);
      if (idIn == null ||
          idIn <= 0 ||
          startFt == null ||
          endFt == null ||
          endFt <= startFt) {
        continue;
      }

      output.add(
        ReportGeometryRow(
          description: _fallbackText(
            entry.description.text,
            fallback: '${_formatCompact(idIn)} in Casing',
          ),
          startFt: startFt,
          endFt: endFt,
          volumeBbl: _calculateVolumeBbl(
            insideDiameterIn: idIn,
            lengthFt: endFt - startFt,
          ),
          volumePerFtBbl: _capacityBblPerFt(idIn),
        ),
      );
    }

    return output;
  }

  List<ReportGeometryRow> _buildOpenHoleRows() {
    final validCasings =
        _casedHoleController.entries
            .where((entry) => entry.hasContent)
            .where((entry) => (_parseNumber(entry.idCtrl.text) ?? 0) > 0)
            .where((entry) => (_parseNumber(entry.shoe.text) ?? 0) > 0)
            .toList()
          ..sort((left, right) {
            final leftShoe = _parseNumber(left.shoe.text) ?? 0;
            final rightShoe = _parseNumber(right.shoe.text) ?? 0;
            return leftShoe.compareTo(rightShoe);
          });

    final latestCasing = validCasings.isEmpty ? null : validCasings.last;
    final holeIdIn = _parseNumber(latestCasing?.idCtrl.text);
    final shoeFt = _parseNumber(latestCasing?.shoe.text);
    final mdFt = _parseNumber(_wellGeneralController.md.value);

    if (holeIdIn == null ||
        holeIdIn <= 0 ||
        shoeFt == null ||
        mdFt == null ||
        mdFt <= shoeFt) {
      return const <ReportGeometryRow>[];
    }

    final labelText = latestCasing?.description.text.trim() ?? '';
    final description = labelText.isNotEmpty
        ? '$labelText Open Hole'
        : '${_formatCompact(holeIdIn)} in Open Hole';

    return [
      ReportGeometryRow(
        description: description,
        startFt: shoeFt,
        endFt: mdFt,
        volumeBbl: _calculateVolumeBbl(
          insideDiameterIn: holeIdIn,
          lengthFt: mdFt - shoeFt,
        ),
        volumePerFtBbl: _capacityBblPerFt(holeIdIn),
      ),
    ];
  }

  List<ReportGeometryRow> _buildDrillStringRows() {
    final output = <ReportGeometryRow>[];
    double runningDepthFt = 0;

    for (final entry in _drillStringController.entries) {
      final idIn = _parseNumber(entry.idCtrl.text);
      final lengthFt = _parseNumber(entry.length.text);
      if (idIn == null || idIn <= 0 || lengthFt == null || lengthFt <= 0) {
        continue;
      }

      final startFt = runningDepthFt;
      final endFt = runningDepthFt + lengthFt;
      runningDepthFt = endFt;

      output.add(
        ReportGeometryRow(
          description: _fallbackText(
            entry.description.text,
            fallback: 'Drill String',
          ),
          startFt: startFt,
          endFt: endFt,
          volumeBbl: _calculateVolumeBbl(
            insideDiameterIn: idIn,
            lengthFt: lengthFt,
          ),
          volumePerFtBbl: _capacityBblPerFt(idIn),
        ),
      );
    }

    return output;
  }

  List<ReportGeometryRow> _buildPadRows() {
    final pad = padWellContext.selectedPad;
    if (pad == null) {
      return const <ReportGeometryRow>[];
    }

    final riserIdIn = _parseNumber(pad.riserID);
    final airGapFt = _parseNumber(pad.airGap) ?? 0;
    final waterDepthFt = _parseNumber(pad.waterDepth) ?? 0;
    final riserLengthFt = airGapFt + waterDepthFt;

    if (riserIdIn == null || riserIdIn <= 0 || riserLengthFt <= 0) {
      return const <ReportGeometryRow>[];
    }

    return [
      ReportGeometryRow(
        description: 'Riser',
        startFt: 0,
        endFt: riserLengthFt,
        volumeBbl: _calculateVolumeBbl(
          insideDiameterIn: riserIdIn,
          lengthFt: riserLengthFt,
        ),
        volumePerFtBbl: _capacityBblPerFt(riserIdIn),
      ),
    ];
  }

  String _buildSourceSummary(List<ReportGeometryRow> geometryRows) {
    if (geometryRows.isEmpty) {
      return '';
    }

    final casingCount = geometryRows
        .where((row) => row.description.toLowerCase().contains('casing'))
        .length;
    final drillCount = geometryRows
        .where((row) => row.description.toLowerCase().contains('drill'))
        .length;
    final hasOpenHole = geometryRows.any(
      (row) => row.description.toLowerCase().contains('open hole'),
    );
    final hasRiser = geometryRows.any(
      (row) => row.description.toLowerCase().contains('riser'),
    );
    final mdFt = _parseNumber(_wellGeneralController.md.value);

    final parts = <String>[
      if (casingCount > 0) 'Casing $casingCount',
      if (drillCount > 0) 'Drill String $drillCount',
      if (hasOpenHole) 'Open Hole linked',
      if (hasRiser) 'Riser included',
      if (mdFt != null && mdFt > 0) 'MD ${_formatCompact(mdFt)} ft',
    ];

    return parts.join(' | ');
  }

  double _capacityBblPerFt(double insideDiameterIn) =>
      (insideDiameterIn * insideDiameterIn) / 1029.4;

  double _calculateVolumeBbl({
    required double insideDiameterIn,
    required double lengthFt,
  }) {
    final volume = _capacityBblPerFt(insideDiameterIn) * lengthFt;
    return double.parse(volume.toStringAsFixed(2));
  }

  double? _parseNumber(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    final cleaned = text.replaceAll(',', '');
    final direct = double.tryParse(cleaned);
    if (direct != null) {
      return direct;
    }

    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(cleaned);
    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(0) ?? '');
  }

  String _fallbackText(String value, {required String fallback}) {
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _formatCompact(double value) {
    if (!value.isFinite) {
      return '0';
    }
    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
