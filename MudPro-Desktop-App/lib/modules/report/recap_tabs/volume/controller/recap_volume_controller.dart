import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapVolumeController extends GetxController {
  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapVolumeController({
    ReportApiService? reportApi,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _reportApi = reportApi ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <VolumeHistoryRow>[].obs;

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
      rows.clear();
      emptyMessage.value = 'Select a well first to open Volume recap.';
      return;
    }

    isLoading.value = true;

    try {
      final summaries = await _reportApi.fetchReportManagerRows(wellId);
      if (summaries.isEmpty) {
        rows.clear();
        emptyMessage.value = 'No reports are available for the selected well.';
        return;
      }

      final ordered = [...summaries]..sort(_compareRowsOldestFirst);
      final reportRows = await Future.wait(
        ordered.map((summary) => _buildHistoryRow(wellId, summary)),
      );

      rows.assignAll(reportRows);
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  List<double> startSeries() =>
      rows.map((row) => row.startVol).toList(growable: false);

  List<double> additionSeries() =>
      rows.map((row) => row.additionTotal).toList(growable: false);

  List<double> lossSeries() =>
      rows.map((row) => row.lossTotal).toList(growable: false);

  List<double> transferSeries() =>
      rows.map((row) => row.transferTotal).toList(growable: false);

  List<double> endSeries() =>
      rows.map((row) => row.endVol).toList(growable: false);

  Future<VolumeHistoryRow> _buildHistoryRow(
    String wellId,
    ReportManagerRow summary,
  ) async {
    final payload = await _fetchVolumePayload(
      wellId: wellId,
      reportId: summary.reportId,
    );

    final responses = await Future.wait<List<Map<String, dynamic>>>([
      _fetchList(path: 'receive-mud/$wellId', reportId: summary.reportId),
      _fetchList(path: 'return-lost-mud/$wellId', reportId: summary.reportId),
      _fetchList(path: 'add-water/$wellId', reportId: summary.reportId),
      _fetchList(path: 'mud-loss/$wellId', reportId: summary.reportId),
      _fetchList(path: 'mud-loss-storage/$wellId', reportId: summary.reportId),
      _fetchList(path: 'other-vol-addition/$wellId', reportId: summary.reportId),
      _fetchList(path: 'transfer-mud/$wellId', reportId: summary.reportId),
    ]);

    final volumeName = _asMap(payload['volumeName']);
    final totals = _asMap(payload['totalsBreakdown']);

    final receiveMudItems = responses[0];
    final returnLostMudItems = responses[1];
    final addWaterItems = responses[2];
    final mudLossItems = responses[3];
    final mudLossStorageItems = responses[4];
    final otherVolItems = responses[5];
    final transferMudItems = responses[6];

    final receiveMud = _sum(receiveMudItems, 'netVolume');
    final leasedMudReceived = _sumWhere(
      receiveMudItems,
      'netVolume',
      (item) => _boolValue(item['leased']),
    );
    final leasedMudReturned = _sumWhere(
      returnLostMudItems,
      'volReturned',
      (item) => _boolValue(item['leased']),
    );
    final leasedMudLost = _sumWhere(
      returnLostMudItems,
      'volLost',
      (item) => _boolValue(item['leased']),
    );

    final returnVol = _sum(returnLostMudItems, 'volReturned');
    final water = _sum(addWaterItems, 'volume');
    final formation = _sum(otherVolItems, 'formation');
    final cuttings = _sum(otherVolItems, 'cuttings');
    final volumeNotFluid = _sum(otherVolItems, 'volumeNotFluid');

    final dump = _sum(mudLossItems, 'dump');
    final shakers = _sum(mudLossItems, 'shakers');
    final centrifuge = _sum(mudLossItems, 'centrifuge');
    final evaporation = _sum(mudLossItems, 'evaporation');
    final pitCleaning = _sum(mudLossItems, 'pitCleaning');
    final formationLoss = _sum(mudLossItems, 'formation');
    final cuttingsRetention = _sum(mudLossItems, 'cuttingsRetention');
    final seepage = _sum(mudLossItems, 'seepage');
    final abandonInHole = _sum(mudLossItems, 'abandonInHole');
    final leftBehindCasing = _sum(mudLossItems, 'leftBehindCasing');
    final tripping = _sum(mudLossItems, 'tripping');
    final extraLossVolume = _sum(mudLossItems, 'extraLossVolume');

    final storageDump = _sum(mudLossStorageItems, 'dump');
    final storageEvaporation = _sum(mudLossStorageItems, 'evaporation');
    final storagePitCleaning = _sum(mudLossStorageItems, 'pitCleaning');

    final transferToStorage = _round2(
      transferMudItems
          .where(
            (item) => _text(item['from']).toLowerCase() == 'active system',
          )
          .fold<double>(
            0,
            (sum, item) => sum + _number(item['totalTransferVol']),
          ),
    );
    final transferFromStorage = _round2(
      transferMudItems
          .where(
            (item) => _text(item['from']).toLowerCase() != 'active system',
          )
          .fold<double>(
            0,
            (sum, item) => sum + _number(item['totalTransferVol']),
          ),
    );

    final baseFluid = 0.0;
    final weightMaterial = 0.0;
    final products = _number(totals['consumeProductTotal']);

    final additionTotal = _round2(
      receiveMud +
          baseFluid +
          weightMaterial +
          products +
          water +
          formation +
          cuttings +
          volumeNotFluid,
    );
    final lossTotal = _round2(
      dump +
          shakers +
          centrifuge +
          evaporation +
          pitCleaning +
          formationLoss +
          cuttingsRetention +
          seepage +
          abandonInHole +
          leftBehindCasing +
          tripping +
          extraLossVolume,
    );
    final transferTotal = _round2(
      transferFromStorage - transferToStorage + returnVol,
    );
    final storageLossTotal = _round2(
      storageDump + storageEvaporation + storagePitCleaning,
    );

    final endVol = _number(volumeName['endVol']);
    final startVol = _round2(endVol - additionTotal + lossTotal - transferTotal);
    final hole = _number(volumeName['hole']);
    final activePits = _number(volumeName['activePits']);
    final activeSystem = _number(volumeName['activeSystem']);
    final totalStorage = _number(volumeName['totalStorage']);
    final totalOnLocation = _number(volumeName['totalOnLocation']);
    final ledgerTotalOnLocation = _number(
      volumeName['ledgerTotalOnLocation'] ?? volumeName['totalOnLocation'],
    );
    final measuredTotalOnLocation = _round2(activeSystem + totalStorage);
    final cumLeasedBase =
        leasedMudReceived - leasedMudReturned - leasedMudLost;
    final cumLeased = _round2(cumLeasedBase < 0 ? 0 : cumLeasedBase);
    final volumeDifference = _round2(
      ledgerTotalOnLocation - measuredTotalOnLocation,
    );

    return VolumeHistoryRow(
      reportId: summary.reportId,
      reportLabel: summary.reportLabel,
      reportDate: summary.reportDate,
      createdAt: summary.createdAt,
      md: summary.md,
      startVol: startVol,
      receiveMud: receiveMud,
      baseFluid: baseFluid,
      weightMaterial: weightMaterial,
      products: products,
      water: water,
      formation: formation,
      cuttings: cuttings,
      volumeNotFluid: volumeNotFluid,
      cuttingsRetention: cuttingsRetention,
      seepage: seepage,
      additionTotal: additionTotal,
      dump: dump,
      shakers: shakers,
      centrifuge: centrifuge,
      evaporation: evaporation,
      pitCleaning: pitCleaning,
      formationLoss: formationLoss,
      abandonInHole: abandonInHole,
      leftBehindCasing: leftBehindCasing,
      tripping: tripping,
      extraLossVolume: extraLossVolume,
      lossTotal: lossTotal,
      fromStorage: transferFromStorage,
      toStorage: transferToStorage,
      returnVol: returnVol,
      transferTotal: transferTotal,
      endVol: endVol,
      storageDump: storageDump,
      storageEvaporation: storageEvaporation,
      storagePitCleaning: storagePitCleaning,
      storageLossTotal: storageLossTotal,
      hole: hole,
      activePits: activePits,
      activeSystem: activeSystem,
      totalStorage: totalStorage,
      totalOnLocation: totalOnLocation,
      ledgerTotalOnLocation: ledgerTotalOnLocation,
      cumLeased: cumLeased,
      volumeDifference: volumeDifference,
    );
  }

  Future<Map<String, dynamic>> _fetchVolumePayload({
    required String wellId,
    required String reportId,
  }) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse('${baseUrl}volume-name/$wellId').replace(
        queryParameters: {
          if (reportId.isNotEmpty) 'reportId': reportId,
        },
      );

      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));
        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode != 200 || decoded['success'] != true) {
          failures.add(
            '${uri.origin}: ${decoded['message'] ?? 'Failed to load volume history'}',
          );
          continue;
        }

        return _asMap(decoded['data']);
      } on TimeoutException {
        failures.add('${uri.origin}: request timed out');
      } on FormatException catch (error) {
        failures.add('${uri.origin}: ${error.message}');
      } catch (error) {
        failures.add('${uri.origin}: ${_cleanError(error)}');
      }
    }

    throw Exception(
      'Volume recap backend routes are not available. '
      'Tried: ${failures.join(' | ')}',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchList({
    required String path,
    required String reportId,
  }) async {
    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: {
          if (reportId.isNotEmpty) 'reportId': reportId,
        },
      );

      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 404) {
          return const <Map<String, dynamic>>[];
        }

        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode != 200 || decoded['success'] != true) {
          continue;
        }

        return _extractList(decoded['data']);
      } catch (_) {
        continue;
      }
    }

    return const <Map<String, dynamic>>[];
  }

  Iterable<String> get _candidateBaseUrls sync* {
    final seen = <String>{};
    for (final baseUrl in [ApiEndpoint.baseUrl, 'http://localhost:3000/api/']) {
      final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
      if (seen.add(normalized)) {
        yield normalized;
      }
    }
  }

  Map<String, dynamic> _decodeObject({
    required String body,
    required Uri uri,
    String? contentType,
  }) {
    final trimmed = body.trim();
    final isJson = (contentType ?? '').toLowerCase().contains('application/json');
    if (!isJson &&
        (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html'))) {
      throw FormatException(
        'HTML error page returned from ${uri.origin}. Expected JSON response.',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw FormatException('Unexpected response format from ${uri.origin}');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final envelope = _asMap(raw);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const <Map<String, dynamic>>[];
  }

  double _sum(List<Map<String, dynamic>> items, String key) {
    return _round2(
      items.fold<double>(0, (sum, item) => sum + _number(item[key])),
    );
  }

  double _sumWhere(
    List<Map<String, dynamic>> items,
    String key,
    bool Function(Map<String, dynamic> item) predicate,
  ) {
    return _round2(
      items.where(predicate).fold<double>(
            0,
            (sum, item) => sum + _number(item[key]),
          ),
    );
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';
}

class VolumeHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final double startVol;
  final double receiveMud;
  final double baseFluid;
  final double weightMaterial;
  final double products;
  final double water;
  final double formation;
  final double cuttings;
  final double volumeNotFluid;
  final double cuttingsRetention;
  final double seepage;
  final double additionTotal;
  final double dump;
  final double shakers;
  final double centrifuge;
  final double evaporation;
  final double pitCleaning;
  final double formationLoss;
  final double abandonInHole;
  final double leftBehindCasing;
  final double tripping;
  final double extraLossVolume;
  final double lossTotal;
  final double fromStorage;
  final double toStorage;
  final double returnVol;
  final double transferTotal;
  final double endVol;
  final double storageDump;
  final double storageEvaporation;
  final double storagePitCleaning;
  final double storageLossTotal;
  final double hole;
  final double activePits;
  final double activeSystem;
  final double totalStorage;
  final double totalOnLocation;
  final double ledgerTotalOnLocation;
  final double cumLeased;
  final double volumeDifference;

  const VolumeHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.startVol,
    required this.receiveMud,
    required this.baseFluid,
    required this.weightMaterial,
    required this.products,
    required this.water,
    required this.formation,
    required this.cuttings,
    required this.volumeNotFluid,
    required this.cuttingsRetention,
    required this.seepage,
    required this.additionTotal,
    required this.dump,
    required this.shakers,
    required this.centrifuge,
    required this.evaporation,
    required this.pitCleaning,
    required this.formationLoss,
    required this.abandonInHole,
    required this.leftBehindCasing,
    required this.tripping,
    required this.extraLossVolume,
    required this.lossTotal,
    required this.fromStorage,
    required this.toStorage,
    required this.returnVol,
    required this.transferTotal,
    required this.endVol,
    required this.storageDump,
    required this.storageEvaporation,
    required this.storagePitCleaning,
    required this.storageLossTotal,
    required this.hole,
    required this.activePits,
    required this.activeSystem,
    required this.totalStorage,
    required this.totalOnLocation,
    required this.ledgerTotalOnLocation,
    required this.cumLeased,
    required this.volumeDifference,
  });
}

double _number(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value?.toString().replaceAll(',', '') ?? '');
  return parsed ?? 0.0;
}

double _round2(double value) => double.parse(value.toStringAsFixed(2));

int _compareRowsOldestFirst(ReportManagerRow left, ReportManagerRow right) {
  final leftDate = _parseReportDate(left);
  final rightDate = _parseReportDate(right);

  if (leftDate != null && rightDate != null) {
    final compare = leftDate.compareTo(rightDate);
    if (compare != 0) return compare;
  } else if (leftDate != null) {
    return -1;
  } else if (rightDate != null) {
    return 1;
  }

  final leftNo = int.tryParse(left.reportLabel);
  final rightNo = int.tryParse(right.reportLabel);
  if (leftNo != null && rightNo != null) {
    return leftNo.compareTo(rightNo);
  }
  return left.reportLabel.toLowerCase().compareTo(
    right.reportLabel.toLowerCase(),
  );
}

DateTime? _parseReportDate(ReportManagerRow row) {
  for (final value in [row.reportDate, row.createdAt]) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    final parts = value.split('/');
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
