import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class PitSnapshotController extends GetxController {
  PitSnapshotController({
    AuthRepository? authRepository,
    InventorySnapshotController? inventorySnapshotController,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _inventorySnapshotController =
           inventorySnapshotController ?? InventorySnapshotController(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  final AuthRepository _authRepository;
  final InventorySnapshotController _inventorySnapshotController;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;

  final measuredDepth = 0.0.obs;
  final shoeDepth = 0.0.obs;

  final volumeSummaryRows = <PitVolumeSummaryRow>[].obs;
  final activePits = <PitSnapshotPitRow>[].obs;
  final storagePits = <PitSnapshotPitRow>[].obs;
  final concentrationRows = <PitConcentrationRow>[].obs;

  final selectedSystem = 'Active System'.obs;
  final systemOptions = <String>[].obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  List<_SnapshotProduct> _products = const <_SnapshotProduct>[];
  double _activeSystemVolume = 0.0;
  double _endVolume = 0.0;

  String get reportHeaderText {
    final wellName = _padWellController.selectedWellName.trim();
    final report = _reportContext.selectedReport;
    final reportLabel = report?.userReportNo.trim().isNotEmpty == true
        ? report!.userReportNo.trim()
        : (report?.reportNo.trim().isNotEmpty == true
              ? report!.reportNo.trim()
              : '-');

    if (wellName.isEmpty) {
      return '*Daily Report $reportLabel';
    }
    return '*$wellName, Daily Report $reportLabel';
  }

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(
      _padWellController.selectedWellId,
      (_) => load(),
    );
    _reportWorker = ever<String>(
      _reportContext.selectedReportId,
      (_) => load(),
    );
    systemOptions.assignAll(const ['Active System']);
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
      _clearAll();
      emptyMessage.value = 'Select a well first to open Pit Snapshot.';
      return;
    }

    isLoading.value = true;

    try {
      final responses = await Future.wait([
        _authRepository.getVolumeNameCalculation(wellId),
        _inventorySnapshotController.getInventorySnapshot(wellId: wellId),
      ]);

      final volumeResult = Map<String, dynamic>.from(responses[0]);
      final inventoryResult = Map<String, dynamic>.from(responses[1]);

      final warnings = <String>[];

      final volumePayload = volumeResult['success'] == true
          ? _map(_map(volumeResult['data'])['data'])
          : <String, dynamic>{};
      if (volumePayload.isEmpty) {
        warnings.add(
          _text(volumeResult['message']).isNotEmpty
              ? _text(volumeResult['message'])
              : 'Pit snapshot volume data is not available for this report.',
        );
      }

      final inventoryItems = inventoryResult['success'] == true
          ? _extractList(inventoryResult['items'])
          : const <Map<String, dynamic>>[];
      if (inventoryResult['success'] != true) {
        warnings.add(
          _text(inventoryResult['message']).isNotEmpty
              ? _text(inventoryResult['message'])
              : 'Inventory snapshot data is not available for this report.',
        );
      }

      _bindVolumePayload(volumePayload);
      _bindInventory(inventoryItems);

      if (activePits.isEmpty &&
          storagePits.isEmpty &&
          concentrationRows.isEmpty &&
          warnings.isNotEmpty) {
        errorMessage.value = warnings.first;
      } else if (activePits.isEmpty &&
          storagePits.isEmpty &&
          concentrationRows.isEmpty) {
        emptyMessage.value =
            'No Active Pits or Storage snapshot data is saved for this report yet.';
      }
    } catch (error) {
      _clearAll();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  void selectSystem(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !systemOptions.contains(trimmed)) return;
    selectedSystem.value = trimmed;
    _rebuildConcentrationRows();
  }

  void _bindVolumePayload(Map<String, dynamic> payload) {
    final general = _map(payload['general']);
    final casing = _map(payload['casing']);
    final volumeName = _map(payload['volumeName']);

    measuredDepth.value = _number(general['md']);
    shoeDepth.value = _number(casing['shoe']);

    activePits.assignAll(
      _buildPitRows(_extractList(payload['activePitsTable']), isActive: true),
    );
    storagePits.assignAll(
      _buildPitRows(_extractList(payload['storageTable']), isActive: false),
    );

    final activePitsVolume = _number(volumeName['activePits']);
    _activeSystemVolume = _number(volumeName['activeSystem']);
    _endVolume = _number(volumeName['endVol']);

    volumeSummaryRows.assignAll([
      PitVolumeSummaryRow(
        name: 'Hole Vol. Difference',
        value: _number(volumeName['heldVolDifference']),
      ),
      PitVolumeSummaryRow(name: 'Hole', value: _number(volumeName['hole'])),
      PitVolumeSummaryRow(name: 'Active Pits', value: activePitsVolume),
      PitVolumeSummaryRow(name: 'Active System', value: _activeSystemVolume),
      PitVolumeSummaryRow(name: 'End Vol.', value: _endVolume),
      PitVolumeSummaryRow(
        name: 'End Vol. - Active System',
        value: _number(volumeName['endVolMinusActiveSystem']),
        highlightRed: true,
      ),
      PitVolumeSummaryRow(
        name: 'Total Storage',
        value: _number(volumeName['totalStorage']),
      ),
      PitVolumeSummaryRow(
        name: 'Total on Location',
        value: _number(volumeName['totalOnLocation']),
      ),
      PitVolumeSummaryRow(
        name: 'Previous Total on Location',
        value: _number(volumeName['previousTotalOnLocation']),
      ),
    ]);

    final nextOptions = <String>[
      'Active System',
      ...storagePits.map((pit) => pit.pitName),
    ];
    systemOptions.assignAll(nextOptions);
    if (!systemOptions.contains(selectedSystem.value)) {
      selectedSystem.value = 'Active System';
    }
  }

  void _bindInventory(List<Map<String, dynamic>> items) {
    final byKey = <String, _SnapshotProduct>{};

    for (final item in items) {
      if (_normalizeText(item['category']) != 'product') continue;

      final itemName = _text(item['itemName']);
      final code = _text(item['code']);
      final unit = _text(item['unit']);
      final initial = _number(item['initial']);
      final finalValue = _number(item['final']);
      final received = _number(item['rec']);
      final used = _number(item['used']);

      if (itemName.isEmpty || unit.isEmpty) continue;
      if (initial <= 0 && finalValue <= 0 && received <= 0 && used <= 0) {
        continue;
      }

      final basis = _basisFromPackUnit(unit);
      if (basis == null) continue;

      final key = _keyFromCodeOrName(code, itemName);
      byKey[key] = _SnapshotProduct(
        key: key,
        itemName: itemName,
        code: code,
        unitDisplay: unit,
        concentrationUnit: basis.concentrationUnit,
        factorPerPack: basis.factorPerPack,
        initial: initial,
        finalValue: finalValue,
      );
    }

    _products = byKey.values.toList()
      ..sort(
        (left, right) =>
            left.itemName.toLowerCase().compareTo(right.itemName.toLowerCase()),
      );
    _rebuildConcentrationRows();
  }

  void _rebuildConcentrationRows() {
    final system = selectedSystem.value.trim();
    final isActiveSystem = system == 'Active System';
    final startVolume = _activeSystemVolume > 0 ? _activeSystemVolume : 0.0;
    final endVolume = _endVolume > 0
        ? _endVolume
        : (_activeSystemVolume > 0 ? _activeSystemVolume : 0.0);

    final rows = <PitConcentrationRow>[];

    for (var index = 0; index < _products.length; index++) {
      final product = _products[index];
      final startConc = isActiveSystem
          ? _formatConcentration(
              _concentrationFor(
                packs: product.initial,
                factorPerPack: product.factorPerPack,
                systemVolume: startVolume,
              ),
            )
          : '';
      final endConc = isActiveSystem
          ? _formatConcentration(
              _concentrationFor(
                packs: product.finalValue,
                factorPerPack: product.factorPerPack,
                systemVolume: endVolume,
              ),
            )
          : '';

      rows.add(
        PitConcentrationRow(
          rowNumber: index + 1,
          product: '${product.itemName} (${product.concentrationUnit})',
          unit: product.unitDisplay,
          startConc: startConc,
          endConc: endConc,
        ),
      );
    }

    concentrationRows.assignAll(rows);
  }

  List<PitSnapshotPitRow> _buildPitRows(
    List<Map<String, dynamic>> rows, {
    required bool isActive,
  }) {
    final cleaned = <PitSnapshotPitRow>[];

    for (final row in rows) {
      final pitName = _text(row['pitName']);
      if (pitName.isEmpty) continue;

      final measuredVol = _number(row['measuredVol']);
      final calculatedVol = _number(row['calculatedVol']);
      final displayVolume = isActive
          ? measuredVol
          : (measuredVol > 0 ? measuredVol : calculatedVol);

      if (displayVolume <= 0.005) continue;

      cleaned.add(
        PitSnapshotPitRow(
          id: _text(row['_id']),
          pitName: pitName,
          mud: _text(row['mud'] ?? row['fluidType']),
          mw: _number(row['mw']),
          displayVolume: displayVolume,
          isActive: isActive,
        ),
      );
    }

    return cleaned;
  }

  double _concentrationFor({
    required double packs,
    required double factorPerPack,
    required double systemVolume,
  }) {
    if (packs <= 0 || factorPerPack <= 0 || systemVolume <= 0) return 0;
    return (packs * factorPerPack) / systemVolume;
  }

  String _formatConcentration(double value) {
    if (value <= 0) return '';
    return value.toStringAsFixed(2);
  }

  _ConcentrationBasis? _basisFromPackUnit(String unit) {
    final normalized = _normalizeText(unit);
    final amount = _packSize(unit);
    if (amount <= 0) return null;

    if (normalized.contains('ton')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 2000,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('kg')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 2.20462,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('lb')) {
      return _ConcentrationBasis(
        factorPerPack: amount,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('gal')) {
      return _ConcentrationBasis(
        factorPerPack: amount,
        concentrationUnit: 'gal/bbl',
      );
    }
    if (normalized.contains(' bbl') || normalized.startsWith('bbl')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 42,
        concentrationUnit: 'gal/bbl',
      );
    }
    if (normalized.contains(' m3') || normalized.startsWith('m3')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 264.172,
        concentrationUnit: 'gal/bbl',
      );
    }
    if (normalized.contains('ml')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 0.000264172,
        concentrationUnit: 'gal/bbl',
      );
    }
    if (normalized.contains(' l') || normalized.startsWith('l')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 0.264172,
        concentrationUnit: 'gal/bbl',
      );
    }
    return null;
  }

  double _packSize(String unit) {
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(unit);
    if (match == null) return 1;
    return double.tryParse(match.group(0) ?? '') ?? 1;
  }

  void _clearAll() {
    measuredDepth.value = 0;
    shoeDepth.value = 0;
    _activeSystemVolume = 0;
    _endVolume = 0;
    _products = const <_SnapshotProduct>[];
    activePits.clear();
    storagePits.clear();
    volumeSummaryRows.clear();
    concentrationRows.clear();
    systemOptions.assignAll(const ['Active System']);
    selectedSystem.value = 'Active System';
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }
}

class PitSnapshotPitRow {
  const PitSnapshotPitRow({
    required this.id,
    required this.pitName,
    required this.mud,
    required this.mw,
    required this.displayVolume,
    required this.isActive,
  });

  final String id;
  final String pitName;
  final String mud;
  final double mw;
  final double displayVolume;
  final bool isActive;

  String get label => '$pitName, ${displayVolume.toStringAsFixed(2)} bbl';
}

class PitVolumeSummaryRow {
  const PitVolumeSummaryRow({
    required this.name,
    required this.value,
    this.highlightRed = false,
  });

  final String name;
  final double value;
  final bool highlightRed;
}

class PitConcentrationRow {
  const PitConcentrationRow({
    required this.rowNumber,
    required this.product,
    required this.unit,
    required this.startConc,
    required this.endConc,
  });

  final int rowNumber;
  final String product;
  final String unit;
  final String startConc;
  final String endConc;
}

class _SnapshotProduct {
  const _SnapshotProduct({
    required this.key,
    required this.itemName,
    required this.code,
    required this.unitDisplay,
    required this.concentrationUnit,
    required this.factorPerPack,
    required this.initial,
    required this.finalValue,
  });

  final String key;
  final String itemName;
  final String code;
  final String unitDisplay;
  final String concentrationUnit;
  final double factorPerPack;
  final double initial;
  final double finalValue;
}

class _ConcentrationBasis {
  const _ConcentrationBasis({
    required this.factorPerPack,
    required this.concentrationUnit,
  });

  final double factorPerPack;
  final String concentrationUnit;
}

String _keyFromCodeOrName(String code, String itemName) {
  final cleanCode = _normalizeText(code);
  if (cleanCode.isNotEmpty) return 'code:$cleanCode';
  return 'name:${_normalizeText(itemName)}';
}

String _normalizeText(dynamic value) => _text(value).toLowerCase();

String _text(dynamic value) => value?.toString().trim() ?? '';

double _number(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(_text(value).replaceAll(',', '')) ?? 0.0;
}
