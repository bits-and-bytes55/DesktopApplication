import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class VolumeSnapshotController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final RxMap<String, double> _rawValues = <String, double>{}.obs;
  final RxMap<String, double> _volumeNameValues = <String, double>{}.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  @override
  void onInit() {
    super.onInit();
    load();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) => load());
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) => load());
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    super.onClose();
  }

  bool get hasData => _rawValues.isNotEmpty;

  String get selectedWellName => padWellContext.selectedWellName;

  Future<void> load() async {
    final wellId = currentBackendWellId.trim();
    if (wellId.isEmpty) {
      _rawValues.clear();
      _volumeNameValues.clear();
      errorMessage.value = 'Select a well first to load volume snapshot.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _repo.getVolumeNameCalculation(
        wellId,
        reportId: reportContext.selectedReportId.value.trim().isEmpty
            ? null
            : reportContext.selectedReportId.value.trim(),
      );
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load volume snapshot');
      }

      final envelope = _asMap(result['data']);
      final payload = _asMap(envelope['data']);
      if (payload.isEmpty) {
        throw Exception('Volume snapshot response is empty');
      }

      final snapshot = _asMap(payload['volSnapshot']);
      final volumeName = _asMap(payload['volumeName']);
      final values = snapshot.isNotEmpty
          ? _normalizeSnapshot(snapshot)
          : await _deriveOperationSnapshot(payload, wellId);
      final volumeNameValues = volumeName.isNotEmpty
          ? _normalizeVolumeName(volumeName)
          : _deriveLegacyVolumeName(payload);

      _rawValues.assignAll(values);
      _volumeNameValues.assignAll(volumeNameValues);
    } catch (e) {
      _rawValues.clear();
      _volumeNameValues.clear();
      errorMessage.value = e.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );
    } finally {
      isLoading.value = false;
    }
  }

  String display(String key, {bool negative = false}) {
    final value = raw(key) * (negative ? -1 : 1);
    final converted =
        AppUnits.convertValue(value, '(bbl)', AppUnits.fluidVolume) ?? value;
    return _format(converted);
  }

  double raw(String key) => (_rawValues[key] ?? 0).toDouble();

  String displayVolumeName(String key, {bool negative = false}) {
    final value = rawVolumeName(key) * (negative ? -1 : 1);
    return _format(value);
  }

  double rawVolumeName(String key) => (_volumeNameValues[key] ?? 0).toDouble();

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  Map<String, double> _normalizeSnapshot(Map<String, dynamic> snapshot) {
    return {for (final key in _snapshotKeys) key: _number(snapshot[key])};
  }

  Map<String, double> _normalizeVolumeName(Map<String, dynamic> volumeName) {
    return {
      'heldVolDifference': _number(volumeName['heldVolDifference']),
      'hole': _number(volumeName['hole']),
      'activePits': _number(volumeName['activePits']),
      'activeSystem': _number(volumeName['activeSystem']),
      'endVol': _number(volumeName['endVol']),
      'endVolMinusActiveSystem': _number(volumeName['endVolMinusActiveSystem']),
      'totalStorage': _number(volumeName['totalStorage']),
      'totalOnLocation': _number(volumeName['totalOnLocation']),
      'previousTotalOnLocation': _number(volumeName['previousTotalOnLocation']),
    };
  }

  Map<String, double> _deriveLegacyVolumeName(Map<String, dynamic> payload) {
    final volumeName = _asMap(payload['volumeName']);
    return {
      'heldVolDifference': _number(volumeName['heldVolDifference']),
      'hole': _number(volumeName['hole']),
      'activePits': _number(volumeName['activePits']),
      'activeSystem': _number(volumeName['activeSystem']),
      'endVol': _number(volumeName['endVol']),
      'endVolMinusActiveSystem': _number(volumeName['endVolMinusActiveSystem']),
      'totalStorage': _number(volumeName['totalStorage']),
      'totalOnLocation': _number(volumeName['totalOnLocation']),
      'previousTotalOnLocation': 0,
    };
  }

  Future<Map<String, double>> _deriveOperationSnapshot(
    Map<String, dynamic> payload,
    String wellId,
  ) async {
    final volumeName = _asMap(payload['volumeName']);
    final totals = _asMap(payload['totalsBreakdown']);

    final responses = await Future.wait<List<Map<String, dynamic>>>([
      _fetchList(() => _repo.getReceiveMudList(wellId)),
      _fetchList(() => _repo.getReturnLostMudList(wellId)),
      _fetchList(() => _repo.getAddWaterList(wellId)),
      _fetchList(() => _repo.getMudLossList(wellId)),
      _fetchList(() => _repo.getMudLossStorageList(wellId)),
      _fetchList(() => _repo.getOtherVolAdditionList(wellId)),
      _fetchList(() => _repo.getTransferMud(wellId)),
    ]);

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
    final nonLeasedMudReceived = _round2(receiveMud - leasedMudReceived);

    final returnVol = _sum(returnLostMudItems, 'volReturned');
    final leasedMudReturned = _sumWhere(
      returnLostMudItems,
      'volReturned',
      (item) => _boolValue(item['leased']),
    );
    final nonLeasedMudReturned = _round2(returnVol - leasedMudReturned);
    final leasedMudLost = _sumWhere(
      returnLostMudItems,
      'volLost',
      (item) => _boolValue(item['leased']),
    );

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

    final storageDump = _sum(mudLossStorageItems, 'dump');
    final storageEvaporation = _sum(mudLossStorageItems, 'evaporation');
    final storagePitCleaning = _sum(mudLossStorageItems, 'pitCleaning');

    final transferToStorage = _round2(
      transferMudItems
          .where(
            (item) =>
                (item['from'] ?? '').toString().trim().toLowerCase() ==
                'active system',
          )
          .fold<double>(
            0,
            (sum, item) => sum + _number(item['totalTransferVol']),
          ),
    );
    final transferFromStorage = _round2(
      transferMudItems
          .where(
            (item) =>
                (item['from'] ?? '').toString().trim().toLowerCase() !=
                'active system',
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
          tripping,
    );
    final storageLossTotal = _round2(
      storageDump + storageEvaporation + storagePitCleaning,
    );

    final endVol = _number(volumeName['endVol']);
    final transferNet = _round2(
      transferFromStorage - transferToStorage + returnVol,
    );
    final startVol = _round2(endVol - additionTotal + lossTotal - transferNet);

    final hole = _number(volumeName['hole']);
    final activePits = _number(volumeName['activePits']);
    final activeSystem = _number(volumeName['activeSystem']);
    final totalStorage = _number(volumeName['totalStorage']);
    final ledgerTotalOnLocation = _number(volumeName['totalOnLocation']);
    final measuredTotalOnLocation = _round2(activeSystem + totalStorage);
    final cumLeased = _round2(
      (leasedMudReceived - leasedMudReturned - leasedMudLost).clamp(
        0,
        double.infinity,
      ),
    );
    final volumeDifference = _round2(
      ledgerTotalOnLocation - measuredTotalOnLocation,
    );

    return {
      'startVol': startVol,
      'receiveMud': receiveMud,
      'baseFluid': baseFluid,
      'weightMaterial': weightMaterial,
      'products': products,
      'water': water,
      'formation': formation,
      'cuttings': cuttings,
      'volumeNotFluid': volumeNotFluid,
      'cuttingsRetention': cuttingsRetention,
      'seepage': seepage,
      'additionTotal': additionTotal,
      'dump': dump,
      'shakers': shakers,
      'centrifuge': centrifuge,
      'evaporation': evaporation,
      'pitCleaning': pitCleaning,
      'formationLoss': formationLoss,
      'abandonInHole': abandonInHole,
      'leftBehindCasing': leftBehindCasing,
      'tripping': tripping,
      'lossTotal': lossTotal,
      'fromStorage': transferFromStorage,
      'toStorage': transferToStorage,
      'returnVol': returnVol,
      'endVol': endVol,
      'endVolActiveSystem': _number(volumeName['endVolMinusActiveSystem']),
      'storageDump': storageDump,
      'storageEvaporation': storageEvaporation,
      'storagePitCleaning': storagePitCleaning,
      'premixedMud': receiveMud,
      'leasedMudReceived': leasedMudReceived,
      'leasedMudReturned': leasedMudReturned,
      'nonLeasedMudReceived': nonLeasedMudReceived,
      'nonLeasedMudReturned': nonLeasedMudReturned,
      'cumLeased': cumLeased,
      'volumeSummary': totalStorage,
      'hole': hole,
      'activePits': activePits,
      'activeSystem': activeSystem,
      'totalStorage': totalStorage,
      'totalOnLocation': measuredTotalOnLocation,
      'totalOnLocationLedger': ledgerTotalOnLocation,
      'totalOnLocationCumLeased': cumLeased,
      'volumeDifference': volumeDifference,
      'storageLossTotal': storageLossTotal,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchList(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      final result = await request();
      if (result['success'] != true) {
        return const <Map<String, dynamic>>[];
      }
      return _extractList(result['data']);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.map(_asMap).where((item) => item.isNotEmpty).toList();
    }

    final envelope = _asMap(raw);
    final data = envelope['data'];
    if (data is List) {
      return data.map(_asMap).where((item) => item.isNotEmpty).toList();
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
      items
          .where(predicate)
          .fold<double>(0, (sum, item) => sum + _number(item[key])),
    );
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }

  static double _number(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString().replaceAll(',', ''));
    return parsed ?? 0;
  }

  static double _round2(double value) => double.parse(value.toStringAsFixed(2));

  String _format(double value) {
    final normalized = value.abs() < 0.000001 ? 0 : value;
    final absValue = normalized.abs();
    final fixed = absValue.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integerPart = parts.first;
    final buffer = StringBuffer();

    for (var i = 0; i < integerPart.length; i++) {
      final reverseIndex = integerPart.length - i;
      buffer.write(integerPart[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    final text = '${buffer.toString()}.${parts.last}';
    return normalized < 0 ? '-$text' : text;
  }
}

class VolumeSnapshotPage extends StatelessWidget {
  const VolumeSnapshotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VolumeSnapshotController>()
        ? Get.find<VolumeSnapshotController>()
        : Get.put(VolumeSnapshotController());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Obx(() {
        final unitSignature = AppUnits.signature;

        if (controller.isLoading.value && !controller.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty && !controller.hasData) {
          return _ErrorState(
            message: controller.errorMessage.value,
            onRetry: controller.load,
          );
        }

        return KeyedSubtree(
          key: ValueKey(unitSignature),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFC8C8C8)),
                ),
                child: Column(
                  children: [
                    _buildHeader(controller),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: Column(
                          children: [
                            if (controller.errorMessage.value.isNotEmpty)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E5),
                                  border: Border.all(
                                    color: const Color(0xFFFFD7A8),
                                  ),
                                ),
                                child: Text(
                                  controller.errorMessage.value,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8A5A00),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 11,
                                    child: _buildLeftTable(controller),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 8,
                                    child: _buildRightTables(controller),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(VolumeSnapshotController controller) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Volume Snapshot',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.close, color: Color(0xFF7A7A7A), size: 24),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTable(VolumeSnapshotController controller) {
    final transferTotal =
        controller.raw('fromStorage') -
        controller.raw('toStorage') +
        controller.raw('returnVol');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Active System Volume',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ),
        Expanded(
          child: _sheetPanel(
            child: SingleChildScrollView(
              child: Table(
                border: TableBorder.all(color: const Color(0xFFC4C4C4)),
                columnWidths: const {
                  0: FixedColumnWidth(102),
                  1: FlexColumnWidth(1.5),
                  2: FixedColumnWidth(122),
                  3: FixedColumnWidth(118),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      _headerCell(''),
                      _headerCell(''),
                      _headerCell('Vol. ${AppUnits.fluidVolume}'),
                      _headerCell(''),
                    ],
                  ),
                  _spreadsheetRow(
                    group: 'Start Vol.',
                    label: '',
                    value: '',
                    total: controller.display('startVol'),
                    emphasizeGroup: true,
                    groupTextColor: const Color(0xFF2E79C9),
                  ),
                  _spreadsheetRow(
                    group: 'Addition',
                    label: 'Receive Mud',
                    value: controller.display('receiveMud'),
                    total: controller.display('additionTotal'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Base Fluid',
                    value: controller.display('baseFluid'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Weight Material',
                    value: controller.display('weightMaterial'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Products',
                    value: controller.display('products'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Water',
                    value: controller.display('water'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Formation',
                    value: controller.display('formation'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Cuttings',
                    value: controller.display('cuttings'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Volume Not Fluid',
                    value: controller.display('volumeNotFluid'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Cuttings/Retention',
                    value: controller.display('cuttingsRetention'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Seepage',
                    value: controller.display('seepage'),
                  ),
                  _spreadsheetRow(
                    group: 'Loss',
                    label: 'Dump',
                    value: controller.display('dump'),
                    total: controller.display('lossTotal'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Shakers',
                    value: controller.display('shakers'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Centrifuge',
                    value: controller.display('centrifuge'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Evaporation',
                    value: controller.display('evaporation'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Pit Cleaning',
                    value: controller.display('pitCleaning'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Formation',
                    value: controller.display('formationLoss'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Abandon in Hole',
                    value: controller.display('abandonInHole'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Left behind Casing',
                    value: controller.display('leftBehindCasing'),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Tripping',
                    value: controller.display('tripping'),
                  ),
                  _spreadsheetRow(
                    group: 'Transfer',
                    label: 'From Storage',
                    value: controller.display('fromStorage'),
                    total: controller._format(transferTotal),
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'To Storage',
                    value: controller.display('toStorage', negative: true),
                    valueColor: Colors.red,
                  ),
                  _spreadsheetRow(
                    group: '',
                    label: 'Return',
                    value: controller.display('returnVol'),
                  ),
                  _spreadsheetRow(
                    group: 'End Vol.',
                    label: '',
                    value: '',
                    total: controller.display('endVol'),
                    emphasizeGroup: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightTables(VolumeSnapshotController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tableSection(
                  title: 'Storage Loss',
                  child: Table(
                    border: TableBorder.all(color: const Color(0xFFC4C4C4)),
                    columnWidths: const {
                      0: FlexColumnWidth(),
                      1: FixedColumnWidth(132),
                    },
                    children: [
                      TableRow(
                        children: [
                          _headerCell(''),
                          _headerCell('Vol. ${AppUnits.fluidVolume}'),
                        ],
                      ),
                      _twoColumnRow('Dump', controller.display('storageDump')),
                      _twoColumnRow(
                        'Evaporation',
                        controller.display('storageEvaporation'),
                      ),
                      _twoColumnRow(
                        'Pit Cleaning',
                        controller.display('storagePitCleaning'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _tableSection(
                  title: 'Premixed Mud',
                  child: Table(
                    border: TableBorder.all(color: const Color(0xFFC4C4C4)),
                    columnWidths: const {
                      0: FlexColumnWidth(),
                      1: FixedColumnWidth(132),
                    },
                    children: [
                      TableRow(
                        children: [
                          _headerCell(''),
                          _headerCell('Vol. ${AppUnits.fluidVolume}'),
                        ],
                      ),
                      _twoColumnRow(
                        'Leased Mud Received',
                        controller.display('leasedMudReceived'),
                      ),
                      _twoColumnRow(
                        'Leased Mud Returned',
                        controller.display('leasedMudReturned'),
                      ),
                      _twoColumnRow(
                        'Non-leased Mud Received',
                        controller.display('nonLeasedMudReceived'),
                      ),
                      _twoColumnRow(
                        'Non-leased Mud Returned',
                        controller.display('nonLeasedMudReturned'),
                      ),
                      _twoColumnRow(
                        'Cum. Leased',
                        controller.display('cumLeased'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _tableSection(
                  title: 'Volume Summary',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Table(
                        border: TableBorder.all(color: const Color(0xFFC4C4C4)),
                        columnWidths: const {
                          0: FlexColumnWidth(),
                          1: FixedColumnWidth(132),
                        },
                        children: [
                          TableRow(
                            children: [
                              _headerCell(''),
                              _headerCell('Vol. ${AppUnits.fluidVolume}'),
                            ],
                          ),
                          _twoColumnRow(
                            'Hole Vol. Difference',
                            controller.displayVolumeName('heldVolDifference'),
                          ),
                          _twoColumnRow(
                            'Hole',
                            controller.displayVolumeName('hole'),
                          ),
                          _twoColumnRow(
                            'Active Pits',
                            controller.displayVolumeName('activePits'),
                          ),
                          _twoColumnRow(
                            'Active System',
                            controller.displayVolumeName('activeSystem'),
                          ),
                          _twoColumnRow(
                            'Total Storage',
                            controller.displayVolumeName('totalStorage'),
                          ),
                          _twoColumnRow(
                            'Total on Location',
                            controller.displayVolumeName('totalOnLocation'),
                          ),
                          _twoColumnRow(
                            'Cum. Leased',
                            controller.display('cumLeased'),
                          ),
                          _twoColumnRow(
                            'Volume Difference*',
                            controller.display('volumeDifference'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '*Total on Location - Cum. Leased',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 108,
            child: OutlinedButton(
              onPressed: Get.back,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF555555),
                side: const BorderSide(color: Color(0xFFC4C4C4)),
                backgroundColor: const Color(0xFFF8F8F8),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ),
        _sheetPanel(child: child),
      ],
    );
  }

  Widget _sheetPanel({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC4C4C4)),
      ),
      child: child,
    );
  }

  TableRow _spreadsheetRow({
    required String group,
    required String label,
    required String value,
    String total = '',
    bool emphasizeGroup = false,
    Color? groupTextColor,
    Color? valueColor,
  }) {
    return TableRow(
      children: [
        _bodyCell(group, emphasize: emphasizeGroup, textColor: groupTextColor),
        _bodyCell(label),
        _valueCell(value, valueColor: valueColor),
        _valueCell(total),
      ],
    );
  }

  TableRow _twoColumnRow(String label, String value) {
    return TableRow(children: [_bodyCell(label), _valueCell(value)]);
  }

  Widget _headerCell(String text) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF444444),
        ),
      ),
    );
  }

  Widget _bodyCell(String text, {bool emphasize = false, Color? textColor}) {
    return Container(
      height: 26,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
          color: textColor ?? const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _valueCell(String text, {Color? valueColor}) {
    return Container(
      height: 26,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFFFF8C6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          color: valueColor ?? const Color(0xFF333333),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Color(0xFF9A9A9A),
            ),
            const SizedBox(height: 12),
            const Text(
              'Volume snapshot load failed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5F6B7A),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _snapshotKeys = [
  'startVol',
  'receiveMud',
  'baseFluid',
  'weightMaterial',
  'products',
  'water',
  'formation',
  'cuttings',
  'volumeNotFluid',
  'cuttingsRetention',
  'seepage',
  'additionTotal',
  'dump',
  'shakers',
  'centrifuge',
  'evaporation',
  'pitCleaning',
  'formationLoss',
  'abandonInHole',
  'leftBehindCasing',
  'tripping',
  'lossTotal',
  'fromStorage',
  'toStorage',
  'returnVol',
  'endVol',
  'endVolActiveSystem',
  'storageDump',
  'storageEvaporation',
  'storagePitCleaning',
  'premixedMud',
  'leasedMudReceived',
  'leasedMudReturned',
  'nonLeasedMudReceived',
  'nonLeasedMudReturned',
  'cumLeased',
  'volumeSummary',
  'hole',
  'activePits',
  'activeSystem',
  'totalStorage',
  'totalOnLocation',
  'totalOnLocationLedger',
  'totalOnLocationCumLeased',
  'volumeDifference',
  'storageLossTotal',
];
