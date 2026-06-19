import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
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
  final holeVolumeRows = <PitHoleVolumeRow>[].obs;
  final activePits = <PitSnapshotPitRow>[].obs;
  final storagePits = <PitSnapshotPitRow>[].obs;
  final concentrationRows = <PitConcentrationRow>[].obs;

  final selectedSystem = 'Active System'.obs;
  final systemOptions = <String>['Active System'].obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  List<_ComputedConcentrationRow> _computedConcentrationRows =
      const <_ComputedConcentrationRow>[];
  Map<String, List<_ComputedConcentrationRow>> _computedConcentrationRowsBySystem =
      const <String, List<_ComputedConcentrationRow>>{};
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
    Future.microtask(load);
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final wellId = currentBackendWellId.trim();
    final reportId = _reportContext.selectedReportId.value.trim();

    errorMessage.value = '';
    emptyMessage.value = '';

    if (wellId.isEmpty) {
      _clearAll();
      emptyMessage.value = 'Select a well first to open Pit Snapshot.';
      return;
    }

    if (reportId.isEmpty) {
      _clearAll();
      emptyMessage.value = 'Select a report first to open Pit Snapshot.';
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
      await _bindConcentrationHistory(
        wellId: wellId,
        currentReportId: reportId,
        currentVolumePayload: volumePayload,
        currentInventoryItems: inventoryItems,
      );

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
    holeVolumeRows.assignAll(
      _buildHoleVolumeRows(_map(payload['holeVolumeBreakdown'])),
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

  Future<void> _bindConcentrationHistory({
    required String wellId,
    required String currentReportId,
    required Map<String, dynamic> currentVolumePayload,
    required List<Map<String, dynamic>> currentInventoryItems,
  }) async {
    final reports = _orderedReportsUpToSelected(currentReportId);
    if (reports.isEmpty) {
      _computedConcentrationRows = _buildCurrentOnlyConcentrationRows(
        volumePayload: currentVolumePayload,
        inventoryItems: currentInventoryItems,
      );
      _rebuildConcentrationRows();
      return;
    }

    final cumulativeAmountsBySystem = <String, Map<String, double>>{};
    final productMetaByKey = <String, _SnapshotProduct>{};
    var previousEndVolume = 0.0;
    var selectedRows = const <_ComputedConcentrationRow>[];
    var selectedRowsBySystem = const <String, List<_ComputedConcentrationRow>>{};

    for (final report in reports) {
      final source = report.id == currentReportId
          ? _HistoricalConcentrationSource(
              volumePayload: currentVolumePayload,
              inventoryItems: currentInventoryItems,
            )
          : await _loadHistoricalConcentrationSource(
              wellId: wellId,
              reportId: report.id,
            );

      final systemVolumes = _systemVolumesFromPayload(source.volumePayload);
      final usedAmountsBySystem = _allocatedProductAmountsBySystem(
        volumePayload: source.volumePayload,
        inventoryItems: source.inventoryItems,
        productMetaByKey: productMetaByKey,
      );
      final reportProductKeys = <String>{};
      for (final item in source.inventoryItems) {
        if (_normalizeText(item['category']) != 'product') continue;

        final product = _snapshotProductFromInventoryItem(item);
        if (product == null) continue;

        reportProductKeys.add(product.key);
        productMetaByKey[product.key] = product;
      }

      final startVolume = previousEndVolume > 0 ? previousEndVolume : 0.0;
      final endVolume = _resolveConcentrationEndVolume(source.volumePayload);
      final reportSystems = <String>{
        'Active System',
        ...systemVolumes.keys,
        ...cumulativeAmountsBySystem.keys,
        ...usedAmountsBySystem.keys,
      };
      final rowsBySystem = <String, List<_ComputedConcentrationRow>>{};

      for (final system in reportSystems) {
        final cumulativeAmounts =
            cumulativeAmountsBySystem.putIfAbsent(system, () => <String, double>{});
        final usedAmounts = usedAmountsBySystem[system] ?? const <String, double>{};
        final keys = {
          ...cumulativeAmounts.keys,
          ...usedAmounts.keys,
          if (report.id == currentReportId) ...reportProductKeys,
        }.toList()
          ..sort((left, right) {
            final leftMeta = productMetaByKey[left];
            final rightMeta = productMetaByKey[right];
            final leftName = leftMeta?.itemName.toLowerCase() ?? left;
            final rightName = rightMeta?.itemName.toLowerCase() ?? right;
            return leftName.compareTo(rightName);
          });

        final systemStartVolume =
            system == 'Active System' ? startVolume : 0.0;
        final systemEndVolume = systemVolumes[system] ??
            (system == 'Active System' ? endVolume : 0.0);
        final rows = <_ComputedConcentrationRow>[];

        for (final key in keys) {
          final product = productMetaByKey[key];
          if (product == null) continue;

          final startAmount = cumulativeAmounts[key] ?? 0.0;
          final endAmount = startAmount + (usedAmounts[key] ?? 0.0);
          final isCurrentReportProduct =
              report.id == currentReportId && reportProductKeys.contains(key);
          if (startAmount <= 0 && endAmount <= 0 && !isCurrentReportProduct) {
            continue;
          }

          rows.add(
            _ComputedConcentrationRow(
              key: key,
              itemName: product.itemName,
              unitDisplay: product.unitDisplay,
              concentrationUnit: product.concentrationUnit,
              startConcentration: _concentrationForAmount(
                amount: startAmount,
                systemVolume: systemStartVolume,
              ),
              endConcentration: _concentrationForAmount(
                amount: endAmount,
                systemVolume: systemEndVolume,
              ),
            ),
          );

          if (endAmount > 0) {
            cumulativeAmounts[key] = endAmount;
          } else {
            cumulativeAmounts.remove(key);
          }
        }

        rowsBySystem[system] = rows;
      }

      if (report.id == currentReportId) {
        selectedRowsBySystem = rowsBySystem;
        selectedRows =
            rowsBySystem['Active System'] ?? const <_ComputedConcentrationRow>[];
      }

      if (endVolume > 0) {
        previousEndVolume = endVolume;
      }
    }

    _computedConcentrationRowsBySystem = selectedRowsBySystem;
    _computedConcentrationRows = selectedRows;
    _rebuildConcentrationRows();
  }

  Future<_HistoricalConcentrationSource> _loadHistoricalConcentrationSource({
    required String wellId,
    required String reportId,
  }) async {
    final responses = await Future.wait([
      _authRepository.getVolumeNameCalculation(
        wellId,
        reportIdOverride: reportId,
      ),
      _inventorySnapshotController.getInventorySnapshot(
        wellId: wellId,
        reportIdOverride: reportId,
      ),
    ]);

    final volumeResult = Map<String, dynamic>.from(responses[0]);
    final inventoryResult = Map<String, dynamic>.from(responses[1]);

    return _HistoricalConcentrationSource(
      volumePayload: volumeResult['success'] == true
          ? _map(_map(volumeResult['data'])['data'])
          : const <String, dynamic>{},
      inventoryItems: inventoryResult['success'] == true
          ? _extractList(inventoryResult['items'])
          : const <Map<String, dynamic>>[],
    );
  }

  List<_ComputedConcentrationRow> _buildCurrentOnlyConcentrationRows({
    required Map<String, dynamic> volumePayload,
    required List<Map<String, dynamic>> inventoryItems,
  }) {
    final systemVolumes = _systemVolumesFromPayload(volumePayload);
    final productMetaByKey = <String, _SnapshotProduct>{};
    final usedAmountsBySystem = _allocatedProductAmountsBySystem(
      volumePayload: volumePayload,
      inventoryItems: inventoryItems,
      productMetaByKey: productMetaByKey,
    );
    final reportProductKeys = <String>{};

    for (final item in inventoryItems) {
      if (_normalizeText(item['category']) != 'product') continue;

      final product = _snapshotProductFromInventoryItem(item);
      if (product == null) continue;
      productMetaByKey[product.key] = product;
      reportProductKeys.add(product.key);
    }

    final rowsBySystem = <String, List<_ComputedConcentrationRow>>{};
    final systems = <String>{
      'Active System',
      ...systemVolumes.keys,
      ...usedAmountsBySystem.keys,
    };

    for (final system in systems) {
      final usedAmounts = usedAmountsBySystem[system] ?? const <String, double>{};
      final systemVolume = systemVolumes[system] ??
          (system == 'Active System'
              ? _resolveConcentrationEndVolume(volumePayload)
              : 0.0);
      final keys = {...reportProductKeys, ...usedAmounts.keys}.toList()
        ..sort((left, right) {
          final leftMeta = productMetaByKey[left];
          final rightMeta = productMetaByKey[right];
          final leftName = leftMeta?.itemName.toLowerCase() ?? left;
          final rightName = rightMeta?.itemName.toLowerCase() ?? right;
          return leftName.compareTo(rightName);
        });
      final rows = <_ComputedConcentrationRow>[];

      for (final key in keys) {
        final product = productMetaByKey[key];
        if (product == null) continue;
        final endAmount = usedAmounts[key] ?? 0.0;

        rows.add(
          _ComputedConcentrationRow(
            key: product.key,
            itemName: product.itemName,
            unitDisplay: product.unitDisplay,
            concentrationUnit: product.concentrationUnit,
            startConcentration: 0.0,
            endConcentration: _concentrationForAmount(
              amount: endAmount,
              systemVolume: systemVolume,
            ),
          ),
        );
      }

      rowsBySystem[system] = rows;
    }

    _computedConcentrationRowsBySystem = rowsBySystem;
    return rowsBySystem['Active System'] ?? const <_ComputedConcentrationRow>[];
  }

  void _rebuildConcentrationRows() {
    final selectedRows =
        _computedConcentrationRowsBySystem[selectedSystem.value] ??
        _computedConcentrationRows;
    concentrationRows.assignAll(
      List.generate(selectedRows.length, (index) {
        final row = selectedRows[index];
        final concentrationUnit = row.concentrationUnit.trim();
        return PitConcentrationRow(
          rowNumber: index + 1,
          product: concentrationUnit.isEmpty
              ? row.itemName
              : '${row.itemName} ($concentrationUnit)',
          unit: row.unitDisplay,
          startConc: _formatConcentration(row.startConcentration),
          endConc: _formatConcentration(row.endConcentration),
        );
      }),
    );
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

  Map<String, double> _systemVolumesFromPayload(Map<String, dynamic> payload) {
    final volumeName = _map(payload['volumeName']);
    final volumes = <String, double>{};
    final activeSystem = _number(volumeName['activeSystem']);
    final endVol = _number(volumeName['endVol']);
    volumes['Active System'] = activeSystem > 0 ? activeSystem : endVol;

    for (final row in _extractList(payload['storageTable'])) {
      final pitName = _text(row['pitName']);
      if (pitName.isEmpty) continue;
      final measuredVol = _number(row['measuredVol']);
      final calculatedVol = _number(row['calculatedVol']);
      final volume = measuredVol > 0 ? measuredVol : calculatedVol;
      volumes[pitName] = volume;
    }

    return volumes;
  }

  Map<String, Map<String, double>> _allocatedProductAmountsBySystem({
    required Map<String, dynamic> volumePayload,
    required List<Map<String, dynamic>> inventoryItems,
    required Map<String, _SnapshotProduct> productMetaByKey,
  }) {
    final result = <String, Map<String, double>>{};
    final distributionStates = _distributionStatesByOperation(volumePayload);
    final massSources = _extractList(volumePayload['consumeProductMassSources']);
    final sourceRows = massSources.isNotEmpty
        ? massSources
        : inventoryItems
              .where((item) => _normalizeText(item['category']) == 'product')
              .toList(growable: false);

    for (final row in sourceRows) {
      final product = _snapshotProductFromProductSource(row);
      if (product == null) continue;

      productMetaByKey[product.key] = product;
      final used = _number(row['used']);
      final amount = used > 0 ? used * product.factorPerPack : 0.0;
      if (amount <= 0) continue;

      final operationKey = _text(row['operationInstanceKey']);
      final allocations = _distributionAllocationsForOperation(
        operationKey: operationKey,
        distributionStates: distributionStates,
      );

      allocations.forEach((system, fraction) {
        if (fraction <= 0) return;
        final systemAmounts = result.putIfAbsent(
          system,
          () => <String, double>{},
        );
        systemAmounts[product.key] =
            (systemAmounts[product.key] ?? 0.0) + (amount * fraction);
      });
    }

    return result;
  }

  Map<String, Map<String, dynamic>> _distributionStatesByOperation(
    Map<String, dynamic> volumePayload,
  ) {
    final states = <String, Map<String, dynamic>>{};
    for (final state in _extractList(volumePayload['consumeProductDistributionStates'])) {
      final key = _text(state['operationInstanceKey']);
      states[key] = state;
    }

    if (states.isEmpty) {
      final primary = _map(volumePayload['consumeProductDistribution']);
      if (primary.isNotEmpty) {
        states[''] = primary;
      }
    }

    return states;
  }

  Map<String, double> _distributionAllocationsForOperation({
    required String operationKey,
    required Map<String, Map<String, dynamic>> distributionStates,
  }) {
    final state = distributionStates[operationKey] ??
        distributionStates[''] ??
        (distributionStates.isNotEmpty
            ? distributionStates.values.first
            : const <String, dynamic>{});
    final rows = _extractList(state['distributions']);
    final positiveRows = rows
        .where((row) => _text(row['pitName']).isNotEmpty && _number(row['volume']) > 0)
        .toList(growable: false);
    final total = positiveRows.fold<double>(
      0.0,
      (sum, row) => sum + _number(row['volume']),
    );

    if (total <= 0) {
      return const {'Active System': 1.0};
    }

    final allocations = <String, double>{};
    for (final row in positiveRows) {
      final system = _normalizeSystemName(_text(row['pitName']));
      allocations[system] =
          (allocations[system] ?? 0.0) + (_number(row['volume']) / total);
    }

    return allocations;
  }

  String _normalizeSystemName(String value) {
    return _normalizeText(value) == 'active system' ? 'Active System' : value;
  }

  List<PitHoleVolumeRow> _buildHoleVolumeRows(Map<String, dynamic> values) {
    return [
      PitHoleVolumeRow(label: 'String', value: _number(values['string'])),
      PitHoleVolumeRow(label: 'Annulus', value: _number(values['annulus'])),
      PitHoleVolumeRow(label: 'Below bit', value: _number(values['belowBit'])),
      PitHoleVolumeRow(label: 'Hole', value: _number(values['hole'])),
      PitHoleVolumeRow(
        label: 'Displacement',
        value: _number(values['displacement']),
      ),
    ];
  }

  _SnapshotProduct? _snapshotProductFromInventoryItem(
    Map<String, dynamic> item,
  ) {
    return _snapshotProductFromFields(
      itemName: _text(item['itemName']),
      code: _text(item['code']),
      unit: _text(item['unit']),
    );
  }

  _SnapshotProduct? _snapshotProductFromProductSource(
    Map<String, dynamic> item,
  ) {
    return _snapshotProductFromFields(
      itemName: _text(item['product'] ?? item['itemName']),
      code: _text(item['code']),
      unit: _text(item['unit']),
    );
  }

  _SnapshotProduct? _snapshotProductFromFields({
    required String itemName,
    required String code,
    required String unit,
  }) {
    if (itemName.isEmpty || unit.isEmpty) return null;

    final basis = _basisFromPackUnit(unit);

    return _SnapshotProduct(
      key: _keyFromCodeOrName(code, itemName),
      itemName: itemName,
      code: code,
      unitDisplay: unit,
      concentrationUnit: basis?.concentrationUnit ?? '',
      factorPerPack: basis?.factorPerPack ?? 0,
    );
  }

  List<AppReport> _orderedReportsUpToSelected(String selectedReportId) {
    if (selectedReportId.trim().isEmpty) return const <AppReport>[];

    final reports = _reportContext.reports.toList()
      ..sort(_compareReportsOldestFirst);
    final selectedIndex = reports.indexWhere(
      (item) => item.id == selectedReportId,
    );
    if (selectedIndex < 0) return const <AppReport>[];
    return reports.sublist(0, selectedIndex + 1);
  }

  double _resolveConcentrationEndVolume(Map<String, dynamic> volumePayload) {
    final volumeName = _map(volumePayload['volumeName']);
    final distribution = _map(volumePayload['consumeProductDistribution']);

    final endVol = _number(volumeName['endVol']);
    if (endVol > 0) return endVol;

    final activeSystem = _number(volumeName['activeSystem']);
    if (activeSystem > 0) return activeSystem;

    final distributedTotal = _number(distribution['totalVolume']);
    if (distributedTotal > 0) return distributedTotal;

    return 0.0;
  }

  double _concentrationForAmount({
    required double amount,
    required double systemVolume,
  }) {
    if (amount <= 0 || systemVolume <= 0) return 0;
    return amount / systemVolume;
  }

  String _formatConcentration(double value) {
    if (value.isNaN || value.isInfinite || value <= 0) {
      return '0.00';
    }
    return value.toStringAsFixed(2);
  }

  _ConcentrationBasis? _basisFromPackUnit(String unit) {
    final normalized = _normalizeText(unit);
    final amount = _packSize(unit);
    if (amount <= 0) return null;

    if (normalized.contains('bag')) {
      return const _ConcentrationBasis(
        factorPerPack: _solidBagKg * _kgToLb,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('drum')) {
      return const _ConcentrationBasis(
        factorPerPack: _liquidDrumGal * _galToLiter * _liquidSg * _kgToLb,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('gal')) {
      return _ConcentrationBasis(
        factorPerPack: amount * _galToLiter * _liquidSg * _kgToLb,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('ton') || normalized == 'mt' || normalized.endsWith(' mt')) {
      return _ConcentrationBasis(
        factorPerPack: amount * 1000 * _kgToLb,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('kg')) {
      return _ConcentrationBasis(
        factorPerPack: amount * _kgToLb,
        concentrationUnit: 'lb/bbl',
      );
    }
    if (normalized.contains('lb')) {
      return _ConcentrationBasis(
        factorPerPack: amount,
        concentrationUnit: 'lb/bbl',
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
    _computedConcentrationRows = const <_ComputedConcentrationRow>[];
    _computedConcentrationRowsBySystem =
        const <String, List<_ComputedConcentrationRow>>{};
    activePits.clear();
    storagePits.clear();
    volumeSummaryRows.clear();
    holeVolumeRows.clear();
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

const double _solidBagKg = 25.0;
const double _liquidDrumGal = 55.0;
const double _liquidSg = 1.0;
const double _galToLiter = 3.78541;
const double _kgToLb = 2.20462;

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

class PitHoleVolumeRow {
  const PitHoleVolumeRow({required this.label, required this.value});

  final String label;
  final double value;
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
  });

  final String key;
  final String itemName;
  final String code;
  final String unitDisplay;
  final String concentrationUnit;
  final double factorPerPack;
}

class _ComputedConcentrationRow {
  const _ComputedConcentrationRow({
    required this.key,
    required this.itemName,
    required this.unitDisplay,
    required this.concentrationUnit,
    required this.startConcentration,
    required this.endConcentration,
  });

  final String key;
  final String itemName;
  final String unitDisplay;
  final String concentrationUnit;
  final double startConcentration;
  final double endConcentration;
}

class _HistoricalConcentrationSource {
  const _HistoricalConcentrationSource({
    required this.volumePayload,
    required this.inventoryItems,
  });

  final Map<String, dynamic> volumePayload;
  final List<Map<String, dynamic>> inventoryItems;
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

int _compareReportsOldestFirst(AppReport left, AppReport right) {
  final leftDate = _parseReportDate(left.reportDate, left.createdAt);
  final rightDate = _parseReportDate(right.reportDate, right.createdAt);

  if (leftDate != null && rightDate != null) {
    final dateCompare = leftDate.compareTo(rightDate);
    if (dateCompare != 0) return dateCompare;
  } else if (leftDate != null) {
    return -1;
  } else if (rightDate != null) {
    return 1;
  }

  final leftNo = _reportOrderValue(left);
  final rightNo = _reportOrderValue(right);
  if (leftNo != rightNo) {
    return leftNo.compareTo(rightNo);
  }

  return left.createdAt.compareTo(right.createdAt);
}

int _reportOrderValue(AppReport report) {
  final userNo = int.tryParse(report.userReportNo.trim());
  final reportNo = int.tryParse(report.reportNo.trim());
  return userNo ?? reportNo ?? 0;
}

DateTime? _parseReportDate(String reportDate, String createdAt) {
  for (final value in [reportDate, createdAt]) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) continue;

    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed;

    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
  }
  return null;
}
