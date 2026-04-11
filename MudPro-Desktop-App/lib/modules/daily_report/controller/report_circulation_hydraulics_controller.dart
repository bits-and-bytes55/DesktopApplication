import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/pump_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/cased_hole_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/drill_string_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/well_general_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/tabs/vol_snapshot_page.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ReportCirculationRow {
  const ReportCirculationRow({
    required this.path,
    required this.volumeBbl,
    required this.minutes,
    required this.strokes,
  });

  final String path;
  final double volumeBbl;
  final double? minutes;
  final double? strokes;
}

class ReportAnnularHydraulicsRow {
  const ReportAnnularHydraulicsRow({
    required this.section,
    required this.lengthFt,
    required this.bottomMdFt,
    required this.annularVelocityFtMin,
    required this.criticalVelocityFtMin,
    required this.criticalRateGpm,
    required this.reynoldsAnnular,
    required this.reynoldsCritical,
    required this.effectiveViscosityCp,
    required this.flowRegime,
    required this.ecdPpg,
    required this.cci,
    required this.pressureDropPsi,
    required this.slipVelocityFtMin,
    required this.ctrPercent,
  });

  final String section;
  final double lengthFt;
  final double bottomMdFt;
  final double? annularVelocityFtMin;
  final double? criticalVelocityFtMin;
  final double? criticalRateGpm;
  final double? reynoldsAnnular;
  final double? reynoldsCritical;
  final double? effectiveViscosityCp;
  final String flowRegime;
  final double? ecdPpg;
  final double? cci;
  final double? pressureDropPsi;
  final double? slipVelocityFtMin;
  final double? ctrPercent;
}

class _BoreSection {
  const _BoreSection({
    required this.description,
    required this.insideDiameterIn,
    required this.startFt,
    required this.endFt,
  });

  final String description;
  final double insideDiameterIn;
  final double startFt;
  final double endFt;
}

class _PipeSection {
  const _PipeSection({
    required this.description,
    required this.outerDiameterIn,
    required this.innerDiameterIn,
    required this.startFt,
    required this.endFt,
  });

  final String description;
  final double outerDiameterIn;
  final double innerDiameterIn;
  final double startFt;
  final double endFt;
}

class ReportCirculationHydraulicsController extends GetxController {
  final circulationRows = <ReportCirculationRow>[].obs;
  final annularRows = <ReportAnnularHydraulicsRow>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final sourceSummary = ''.obs;

  late final CasedHoleUIController _casedHoleController;
  late final DrillStringController _drillStringController;
  late final WellGeneralController _wellGeneralController;
  late final PumpController _pumpController;
  late final PitController _pitController;
  late final VolumeSnapshotController _volumeSnapshotController;
  late final MudController _mudController;

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
    _pumpController = Get.isRegistered<PumpController>()
        ? Get.find<PumpController>()
        : Get.put(PumpController());
    _pitController = Get.isRegistered<PitController>()
        ? Get.find<PitController>()
        : Get.put(PitController());
    _volumeSnapshotController = Get.isRegistered<VolumeSnapshotController>()
        ? Get.find<VolumeSnapshotController>()
        : Get.put(VolumeSnapshotController());
    _mudController = Get.isRegistered<MudController>()
        ? Get.find<MudController>()
        : Get.put(MudController());

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
      circulationRows.clear();
      annularRows.clear();
      sourceSummary.value = '';
      errorMessage.value = 'Select a well first to load hydraulics.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await Future.wait([
        _casedHoleController.fetchTableCasings(),
        _drillStringController.fetchDrillStrings(),
        _wellGeneralController.fetchLatest(),
        _pumpController.loadPumps(wellId),
        _pitController.fetchAllPits(),
        _volumeSnapshotController.load(),
      ]);

      final mdFt = _readNumber(_wellGeneralController.md.value) ?? 0;
      final pumpRateGpm = _resolvePumpRateGpm();
      final pumpDisplacementBblStroke = _resolvePumpDisplacementBblStroke();
      final mudWeightPpg = _resolveMudWeightPpg();
      final pvCp = _resolveMudValue(
            keys: const [
              'plastic viscosity',
              'pv',
              'pv (cp)',
              'pv (cps)',
            ],
          ) ??
          15;
      final yp = _resolveMudValue(
            keys: const [
              'yield point',
              'yp',
              'yp (lbf/100ft2)',
              'yp (lbf/100ft²)',
            ],
          ) ??
          20;

      final pipeSections = _buildPipeSections(mdFt);
      final boreSections = _buildBoreSections(mdFt);
      final annularResults = _buildAnnularRows(
        boreSections: boreSections,
        pipeSections: pipeSections,
        flowRateGpm: pumpRateGpm,
        mudWeightPpg: mudWeightPpg,
        plasticViscosityCp: pvCp,
        yieldPoint: yp,
      );
      annularRows.assignAll(annularResults);

      final drillStringVolume = _calculateDrillStringVolume(pipeSections);
      final annularVolume = _calculateAnnularVolume();
      final surfaceVolume = _calculateSurfaceVolume();
      final activeSystemVolume = _volumeSnapshotController.rawVolumeName(
        'activeSystem',
      );
      circulationRows.assignAll(
        _buildCirculationRows(
          drillStringVolumeBbl: drillStringVolume,
          annularVolumeBbl: annularVolume,
          surfaceVolumeBbl: surfaceVolume,
          activeSystemVolumeBbl: activeSystemVolume,
          flowRateGpm: pumpRateGpm,
          pumpDisplacementBblStroke: pumpDisplacementBblStroke,
        ),
      );

      sourceSummary.value = _buildSourceSummary(
        flowRateGpm: pumpRateGpm,
        mudWeightPpg: mudWeightPpg,
        plasticViscosityCp: pvCp,
        yieldPoint: yp,
        annularCount: annularResults.length,
      );
    } catch (e) {
      circulationRows.clear();
      annularRows.clear();
      sourceSummary.value = '';
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  double _resolvePumpRateGpm() {
    final summaryRate = reportContext.selectedReport?.pumpRateAndPressure.pumpRate ?? 0;
    if (summaryRate > 0) {
      return summaryRate;
    }

    double totalRate = 0;
    for (final pump in _pumpController.pumps) {
      final rate = _readNumber(pump.rate.value);
      if (rate != null && rate > 0) {
        totalRate += AppUnits.convertValue(
              rate,
              AppUnits.drillingFlowRate,
              '(gpm)',
            ) ??
            rate;
        continue;
      }

      final displacement = _readNumber(pump.displacement.value);
      final spm = _readNumber(pump.spm.value);
      if (displacement == null || spm == null || displacement <= 0 || spm <= 0) {
        continue;
      }
      final baseDisplacement = AppUnits.convertValue(
            displacement,
            AppUnits.strokeDisplacement,
            '(bbl/stk)',
          ) ??
          displacement;
      totalRate += baseDisplacement * spm * 42;
    }
    return totalRate;
  }

  double _resolvePumpDisplacementBblStroke() {
    double total = 0;
    for (final pump in _pumpController.pumps) {
      final displacement = _readNumber(pump.displacement.value);
      final spm = _readNumber(pump.spm.value) ?? 0;
      if (displacement == null || displacement <= 0 || spm <= 0) {
        continue;
      }
      total += AppUnits.convertValue(
            displacement,
            AppUnits.strokeDisplacement,
            '(bbl/stk)',
          ) ??
          displacement;
    }
    return total;
  }

  double _resolveMudWeightPpg() {
    final mudTableValue = _resolveMudValue(
      keys: const [
        'mud weight',
        'mw',
        'mud weight (ppg)',
        'mw (ppg)',
      ],
    );
    if (mudTableValue != null && mudTableValue > 0) {
      return AppUnits.convertValue(mudTableValue, AppUnits.mudWeight, '(ppg)') ??
          mudTableValue;
    }

    final activePits =
        _pitController.activePitRows.where((pit) => (pit.density?.value ?? 0) > 0).toList()
          ..sort((left, right) {
            final leftVolume = left.volume?.value ?? 0;
            final rightVolume = right.volume?.value ?? 0;
            return rightVolume.compareTo(leftVolume);
          });
    return activePits.isEmpty ? 10 : activePits.first.density!.value;
  }

  double? _resolveMudValue({required List<String> keys}) {
    final sampleIndex = _selectedSampleIndex();

    final rheologyValue = _readFromTable(
      table: _mudController.rheologyTable,
      keys: keys,
      sampleIndex: sampleIndex,
    );
    if (rheologyValue != null && rheologyValue > 0) {
      return rheologyValue;
    }

    final propertyValue = _readFromTable(
      table: _mudController.propertyTable,
      keys: keys,
      sampleIndex: sampleIndex,
    );
    if (propertyValue != null && propertyValue > 0) {
      return propertyValue;
    }

    final r600 = _readFromTable(
      table: _mudController.rheologyTable,
      keys: const ['600', 'r600'],
      sampleIndex: sampleIndex,
    );
    final r300 = _readFromTable(
      table: _mudController.rheologyTable,
      keys: const ['300', 'r300'],
      sampleIndex: sampleIndex,
    );
    if (keys.any((key) => key.contains('pv')) && r600 != null && r300 != null) {
      return math.max(0, r600 - r300);
    }
    if (keys.any((key) => key.contains('yp')) && r600 != null && r300 != null) {
      final pv = math.max(0, r600 - r300);
      return math.max(0, r300 - pv);
    }

    return null;
  }

  double? _readFromTable({
    required Map<String, List<RxString>> table,
    required List<String> keys,
    required int sampleIndex,
  }) {
    for (final entry in table.entries) {
      final normalized = _normalize(entry.key);
      final isMatch = keys.any((key) {
        final normalizedKey = _normalize(key);
        return normalized == normalizedKey || normalized.contains(normalizedKey);
      });
      if (!isMatch || sampleIndex >= entry.value.length) {
        continue;
      }
      final value = _readNumber(entry.value[sampleIndex].value);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  int _selectedSampleIndex() {
    final raw = _mudController.sampleForCalculation.value.trim();
    final index = _mudController.samples.indexOf(raw);
    return index >= 0 ? index : 0;
  }

  List<_PipeSection> _buildPipeSections(double mdFt) {
    final baseSections = <_PipeSection>[];
    double running = 0;

    for (final entry in _drillStringController.entries) {
      final od = _readNumber(entry.od.text);
      final id = _readNumber(entry.idCtrl.text);
      final length = _readNumber(entry.length.text);
      if (od == null ||
          id == null ||
          length == null ||
          od <= 0 ||
          id <= 0 ||
          length <= 0) {
        continue;
      }
      baseSections.add(
        _PipeSection(
          description: _fallback(entry.description.text, 'Drill String'),
          outerDiameterIn: od,
          innerDiameterIn: id,
          startFt: running,
          endFt: running + length,
        ),
      );
      running += length;
    }

    if (baseSections.isEmpty || mdFt <= 0) {
      return baseSections;
    }

    if (running < mdFt) {
      final reference = _firstDrillPipe(baseSections) ?? baseSections.first;
      final fillLength = mdFt - running;
      return [
        _PipeSection(
          description: 'Drill Pipe',
          outerDiameterIn: reference.outerDiameterIn,
          innerDiameterIn: reference.innerDiameterIn,
          startFt: 0,
          endFt: fillLength,
        ),
        ...baseSections.map(
          (section) => _PipeSection(
            description: section.description,
            outerDiameterIn: section.outerDiameterIn,
            innerDiameterIn: section.innerDiameterIn,
            startFt: section.startFt + fillLength,
            endFt: section.endFt + fillLength,
          ),
        ),
      ];
    }

    return baseSections
        .map(
          (section) => _PipeSection(
            description: section.description,
            outerDiameterIn: section.outerDiameterIn,
            innerDiameterIn: section.innerDiameterIn,
            startFt: section.startFt,
            endFt: math.min(section.endFt, mdFt),
          ),
        )
        .where((section) => section.endFt > section.startFt)
        .toList();
  }

  _PipeSection? _firstDrillPipe(List<_PipeSection> sections) {
    for (final section in sections) {
      final normalized = section.description.toLowerCase();
      if (normalized.contains('drill pipe') || normalized == 'dp') {
        return section;
      }
    }
    return null;
  }

  List<_BoreSection> _buildBoreSections(double mdFt) {
    final rows = <_BoreSection>[];
    final casings = _casedHoleController.entries
        .where((entry) => entry.hasContent)
        .toList()
      ..sort((left, right) {
        final leftTop = _readNumber(left.top.text) ?? 0;
        final rightTop = _readNumber(right.top.text) ?? 0;
        return leftTop.compareTo(rightTop);
      });

    for (final entry in casings) {
      final id = _readNumber(entry.idCtrl.text);
      final top = _readNumber(entry.top.text);
      final shoe = _readNumber(entry.shoe.text);
      if (id == null ||
          top == null ||
          shoe == null ||
          id <= 0 ||
          shoe <= top) {
        continue;
      }
      rows.add(
        _BoreSection(
          description: _fallback(entry.description.text, 'Cased Hole'),
          insideDiameterIn: id,
          startFt: top,
          endFt: mdFt > 0 ? math.min(shoe, mdFt) : shoe,
        ),
      );
    }

    final deepestShoe = rows.isEmpty
        ? 0.0
        : rows.map((row) => row.endFt).reduce(math.max);
    if (mdFt > deepestShoe) {
      final openHoleSize = _parseBitSize(_wellGeneralController.interval.value) ??
          (rows.isEmpty ? null : rows.last.insideDiameterIn);
      if (openHoleSize != null && openHoleSize > 0) {
        rows.add(
          _BoreSection(
            description: 'Open Hole',
            insideDiameterIn: openHoleSize,
            startFt: deepestShoe,
            endFt: mdFt,
          ),
        );
      }
    }

    return rows.where((row) => row.endFt > row.startFt).toList();
  }

  List<ReportAnnularHydraulicsRow> _buildAnnularRows({
    required List<_BoreSection> boreSections,
    required List<_PipeSection> pipeSections,
    required double flowRateGpm,
    required double mudWeightPpg,
    required double plasticViscosityCp,
    required double yieldPoint,
  }) {
    final rows = <ReportAnnularHydraulicsRow>[];

    for (final bore in boreSections) {
      for (final pipe in pipeSections) {
        final start = math.max(bore.startFt, pipe.startFt);
        final end = math.min(bore.endFt, pipe.endFt);
        final length = end - start;
        if (length <= 0 || bore.insideDiameterIn <= pipe.outerDiameterIn) {
          continue;
        }

        final area = bore.insideDiameterIn * bore.insideDiameterIn -
            pipe.outerDiameterIn * pipe.outerDiameterIn;
        final velocity = flowRateGpm > 0 ? (24.51 * flowRateGpm) / area : null;
        final hydraulicDiameter = bore.insideDiameterIn - pipe.outerDiameterIn;
        final effectiveViscosity = velocity == null || velocity <= 0
            ? null
            : plasticViscosityCp +
                (5 * yieldPoint * hydraulicDiameter / velocity);
        final reynolds = _calculateReynolds(
          velocityFtMin: velocity,
          hydraulicDiameterIn: hydraulicDiameter,
          mudWeightPpg: mudWeightPpg,
          effectiveViscosityCp: effectiveViscosity,
        );
        final criticalVelocity = _calculateCriticalVelocity(
          hydraulicDiameterIn: hydraulicDiameter,
          mudWeightPpg: mudWeightPpg,
          effectiveViscosityCp: effectiveViscosity,
        );
        final criticalRate = criticalVelocity == null
            ? null
            : criticalVelocity * area / 24.51;
        final pressureDrop = _calculatePressureDrop(
          lengthFt: length,
          hydraulicDiameterIn: hydraulicDiameter,
          velocityFtMin: velocity,
          mudWeightPpg: mudWeightPpg,
          reynolds: reynolds,
        );
        final ecd = pressureDrop == null || end <= 0
            ? null
            : mudWeightPpg + pressureDrop / (0.052 * end);
        final slipVelocity = _calculateSlipVelocity(
          mudWeightPpg: mudWeightPpg,
          yieldPoint: yieldPoint,
        );
        final ctr = velocity == null || velocity <= 0
            ? null
            : ((velocity - slipVelocity) / velocity * 100).clamp(0, 100);
        final cci = slipVelocity <= 0 || velocity == null
            ? null
            : velocity / slipVelocity;

        rows.add(
          ReportAnnularHydraulicsRow(
            section: '${pipe.description} in ${bore.description}',
            lengthFt: length,
            bottomMdFt: end,
            annularVelocityFtMin: velocity,
            criticalVelocityFtMin: criticalVelocity,
            criticalRateGpm: criticalRate,
            reynoldsAnnular: reynolds,
            reynoldsCritical: 2100,
            effectiveViscosityCp: effectiveViscosity,
            flowRegime: _flowRegime(reynolds),
            ecdPpg: ecd,
            cci: cci,
            pressureDropPsi: pressureDrop,
            slipVelocityFtMin: slipVelocity,
            ctrPercent: ctr?.toDouble(),
          ),
        );
      }
    }

    return rows;
  }

  List<ReportCirculationRow> _buildCirculationRows({
    required double drillStringVolumeBbl,
    required double annularVolumeBbl,
    required double surfaceVolumeBbl,
    required double activeSystemVolumeBbl,
    required double flowRateGpm,
    required double pumpDisplacementBblStroke,
  }) {
    final downholeVolume = drillStringVolumeBbl + annularVolumeBbl;
    final circulatingVolume = downholeVolume + surfaceVolumeBbl;
    final activeVolume = activeSystemVolumeBbl > 0
        ? activeSystemVolumeBbl
        : circulatingVolume;

    return [
      _circulationRow(
        path: 'Surface to Bit',
        volumeBbl: drillStringVolumeBbl,
        flowRateGpm: flowRateGpm,
        pumpDisplacementBblStroke: pumpDisplacementBblStroke,
      ),
      _circulationRow(
        path: 'Bit to Surface',
        volumeBbl: annularVolumeBbl,
        flowRateGpm: flowRateGpm,
        pumpDisplacementBblStroke: pumpDisplacementBblStroke,
      ),
      _circulationRow(
        path: 'Bottoms Up',
        volumeBbl: annularVolumeBbl,
        flowRateGpm: flowRateGpm,
        pumpDisplacementBblStroke: pumpDisplacementBblStroke,
      ),
      _circulationRow(
        path: 'Downhole Volume',
        volumeBbl: downholeVolume,
        flowRateGpm: flowRateGpm,
        pumpDisplacementBblStroke: pumpDisplacementBblStroke,
      ),
      _circulationRow(
        path: 'Surface Lines',
        volumeBbl: surfaceVolumeBbl,
        flowRateGpm: flowRateGpm,
        pumpDisplacementBblStroke: pumpDisplacementBblStroke,
      ),
      _circulationRow(
        path: 'Full Circulation',
        volumeBbl: circulatingVolume,
        flowRateGpm: flowRateGpm,
        pumpDisplacementBblStroke: pumpDisplacementBblStroke,
      ),
      _circulationRow(
        path: 'Active System',
        volumeBbl: activeVolume,
        flowRateGpm: flowRateGpm,
        pumpDisplacementBblStroke: pumpDisplacementBblStroke,
      ),
    ].where((row) => row.volumeBbl > 0).toList();
  }

  ReportCirculationRow _circulationRow({
    required String path,
    required double volumeBbl,
    required double flowRateGpm,
    required double pumpDisplacementBblStroke,
  }) {
    final minutes = flowRateGpm > 0 ? volumeBbl * 42 / flowRateGpm : null;
    final strokes = pumpDisplacementBblStroke > 0
        ? volumeBbl / pumpDisplacementBblStroke
        : null;
    return ReportCirculationRow(
      path: path,
      volumeBbl: volumeBbl,
      minutes: minutes,
      strokes: strokes,
    );
  }

  double _calculateDrillStringVolume(List<_PipeSection> sections) {
    return sections.fold(0, (sum, section) {
      final length = math.max(0, section.endFt - section.startFt);
      return sum +
          (section.innerDiameterIn * section.innerDiameterIn / 1029.4) * length;
    });
  }

  double _calculateAnnularVolume() {
    final mdFt = _readNumber(_wellGeneralController.md.value) ?? 0;
    final boreSections = _buildBoreSections(mdFt);
    final pipeSections = _buildPipeSections(mdFt);
    double total = 0;
    for (final bore in boreSections) {
      for (final pipe in pipeSections) {
        final start = math.max(bore.startFt, pipe.startFt);
        final end = math.min(bore.endFt, pipe.endFt);
        final length = end - start;
        if (length <= 0 || bore.insideDiameterIn <= pipe.outerDiameterIn) {
          continue;
        }
        total +=
            ((bore.insideDiameterIn * bore.insideDiameterIn -
                        pipe.outerDiameterIn * pipe.outerDiameterIn) /
                    1029.4) *
                length;
      }
    }
    return total;
  }

  double _calculateSurfaceVolume() {
    double total = 0;
    for (final pump in _pumpController.pumps) {
      final length = _readNumber(pump.surfaceLen.value);
      final insideDiameter = _readNumber(pump.surfaceId.value);
      if (length == null ||
          insideDiameter == null ||
          length <= 0 ||
          insideDiameter <= 0) {
        continue;
      }
      final lengthFt =
          AppUnits.convertValue(length, AppUnits.length, '(ft)') ?? length;
      final idIn =
          AppUnits.convertValue(insideDiameter, AppUnits.diameter, '(in)') ??
              insideDiameter;
      total += (idIn * idIn / 1029.4) * lengthFt;
    }
    return total;
  }

  double? _calculateReynolds({
    required double? velocityFtMin,
    required double hydraulicDiameterIn,
    required double mudWeightPpg,
    required double? effectiveViscosityCp,
  }) {
    if (velocityFtMin == null ||
        velocityFtMin <= 0 ||
        hydraulicDiameterIn <= 0 ||
        mudWeightPpg <= 0 ||
        effectiveViscosityCp == null ||
        effectiveViscosityCp <= 0) {
      return null;
    }
    return 928 *
        mudWeightPpg *
        (velocityFtMin / 60) *
        hydraulicDiameterIn /
        effectiveViscosityCp;
  }

  double? _calculateCriticalVelocity({
    required double hydraulicDiameterIn,
    required double mudWeightPpg,
    required double? effectiveViscosityCp,
  }) {
    if (hydraulicDiameterIn <= 0 ||
        mudWeightPpg <= 0 ||
        effectiveViscosityCp == null ||
        effectiveViscosityCp <= 0) {
      return null;
    }
    return 2100 * effectiveViscosityCp / (928 * mudWeightPpg * hydraulicDiameterIn) * 60;
  }

  double? _calculatePressureDrop({
    required double lengthFt,
    required double hydraulicDiameterIn,
    required double? velocityFtMin,
    required double mudWeightPpg,
    required double? reynolds,
  }) {
    if (lengthFt <= 0 ||
        hydraulicDiameterIn <= 0 ||
        velocityFtMin == null ||
        velocityFtMin <= 0 ||
        mudWeightPpg <= 0 ||
        reynolds == null ||
        reynolds <= 0) {
      return null;
    }

    final frictionFactor = reynolds < 2100
        ? 64 / reynolds
        : 0.3164 / math.pow(reynolds, 0.25);
    final hydraulicDiameterFt = hydraulicDiameterIn / 12;
    final velocityFtSec = velocityFtMin / 60;
    final densityLbFt3 = mudWeightPpg * 7.48052;
    final dynamicPressure = densityLbFt3 * velocityFtSec * velocityFtSec / 64.348;
    return frictionFactor * (lengthFt / hydraulicDiameterFt) * dynamicPressure / 144;
  }

  double _calculateSlipVelocity({
    required double mudWeightPpg,
    required double yieldPoint,
  }) {
    final value = 60 - (1.5 * mudWeightPpg) - (0.2 * yieldPoint);
    return value.clamp(5, 60).toDouble();
  }

  String _flowRegime(double? reynolds) {
    if (reynolds == null) {
      return '-';
    }
    if (reynolds < 2100) {
      return 'Lam';
    }
    if (reynolds < 4000) {
      return 'Trans';
    }
    return 'Turb';
  }

  String _buildSourceSummary({
    required double flowRateGpm,
    required double mudWeightPpg,
    required double plasticViscosityCp,
    required double yieldPoint,
    required int annularCount,
  }) {
    final parts = <String>[
      if (flowRateGpm > 0) 'Flow ${_formatCompact(flowRateGpm)} gpm',
      'MW ${_formatCompact(mudWeightPpg)} ppg',
      'PV ${_formatCompact(plasticViscosityCp)} cP',
      'YP ${_formatCompact(yieldPoint)}',
      if (annularCount > 0) 'Annular sections $annularCount',
    ];
    return parts.join(' | ');
  }

  double? _readNumber(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final direct = double.tryParse(text.replaceAll(',', ''));
    if (direct != null) {
      return direct;
    }
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(text);
    return match == null ? null : double.tryParse(match.group(0) ?? '');
  }

  double? _parseBitSize(String raw) {
    final cleaned = raw
        .replaceAll('"', ' ')
        .replaceAll("'", ' ')
        .replaceAll(RegExp(r'\bin\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final mixedFraction = RegExp(r'(\d+)\s+(\d+)/(\d+)').firstMatch(cleaned);
    if (mixedFraction != null) {
      final whole = double.tryParse(mixedFraction.group(1) ?? '');
      final numerator = double.tryParse(mixedFraction.group(2) ?? '');
      final denominator = double.tryParse(mixedFraction.group(3) ?? '');
      if (whole != null &&
          numerator != null &&
          denominator != null &&
          denominator != 0) {
        return whole + numerator / denominator;
      }
    }

    final direct = double.tryParse(cleaned);
    if (direct != null) {
      return direct;
    }
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
    return match == null ? null : double.tryParse(match.group(1) ?? '');
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('*', '')
      .replaceAll('²', '2')
      .replaceAll('²', '2')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _fallback(String raw, String fallback) {
    final value = raw.trim();
    return value.isEmpty ? fallback : value;
  }

  String _formatCompact(double value) {
    if (!value.isFinite) {
      return '-';
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
