import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class VolumeSnapshotController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final RxMap<String, double> _rawValues = <String, double>{}.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _wellWorker;

  @override
  void onInit() {
    super.onInit();
    load();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) => load());
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    super.onClose();
  }

  bool get hasData => _rawValues.isNotEmpty;

  String get selectedWellName => padWellContext.selectedWellName;

  Future<void> load() async {
    final wellId = currentBackendWellId.trim();
    if (wellId.isEmpty) {
      _rawValues.clear();
      errorMessage.value = 'Select a well first to load volume snapshot.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _repo.getVolumeNameCalculation(wellId);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load volume snapshot');
      }

      final envelope = _asMap(result['data']);
      final payload = _asMap(envelope['data']);
      if (payload.isEmpty) {
        throw Exception('Volume snapshot response is empty');
      }

      final snapshot = _asMap(payload['volSnapshot']);
      final values = snapshot.isNotEmpty
          ? _normalizeSnapshot(snapshot)
          : _deriveLegacySnapshot(payload);

      _rawValues.assignAll(values);
    } catch (e) {
      _rawValues.clear();
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

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  Map<String, double> _normalizeSnapshot(Map<String, dynamic> snapshot) {
    return {
      for (final key in _snapshotKeys) key: _number(snapshot[key]),
    };
  }

  Map<String, double> _deriveLegacySnapshot(Map<String, dynamic> payload) {
    final volumeName = _asMap(payload['volumeName']);
    final totals = _asMap(payload['totalsBreakdown']);

    final receiveMud = _number(totals['receivedMudTotal']);
    final products = _number(totals['consumeProductTotal']);
    final water = _number(totals['addWaterTotal']);
    final formation = _number(totals['otherVolAdditionTotal']);
    final lossTotal = _number(totals['mudLossTotal']);
    final storageLossTotal = _number(totals['mudLossStorageTotal']);
    final returnLost = _number(totals['lostMudTotal']);

    final hole = _number(volumeName['hole']);
    final activePits = _number(volumeName['activePits']);
    final activeSystem = _number(volumeName['activeSystem']);
    final totalStorage = _number(volumeName['totalStorage']);
    final ledgerTotalOnLocation = _number(volumeName['totalOnLocation']);
    final measuredTotalOnLocation = _round2(activeSystem + totalStorage);
    final volumeDifference = _round2(
      ledgerTotalOnLocation - measuredTotalOnLocation,
    );

    return {
      'startVol': _round2(activeSystem - receiveMud - products - water),
      'receiveMud': receiveMud,
      'baseFluid': 0,
      'weightMaterial': 0,
      'products': products,
      'water': water,
      'formation': formation,
      'cuttings': 0,
      'cuttingsRetention': 0,
      'seepage': 0,
      'additionTotal': _round2(receiveMud + products + water + formation),
      'dump': 0,
      'shakers': 0,
      'centrifuge': 0,
      'evaporation': 0,
      'pitCleaning': 0,
      'formationLoss': 0,
      'abandonInHole': 0,
      'leftBehindCasing': 0,
      'tripping': 0,
      'lossTotal': lossTotal,
      'fromStorage': 0,
      'toStorage': 0,
      'returnVol': returnLost,
      'endVol': _number(volumeName['endVol']),
      'endVolActiveSystem': _number(volumeName['endVolMinusActiveSystem']),
      'storageDump': 0,
      'storageEvaporation': 0,
      'storagePitCleaning': 0,
      'premixedMud': 0,
      'leasedMudReceived': 0,
      'leasedMudReturned': 0,
      'nonLeasedMudReceived': receiveMud,
      'nonLeasedMudReturned': returnLost,
      'cumLeased': 0,
      'volumeSummary': totalStorage,
      'hole': hole,
      'activePits': activePits,
      'activeSystem': activeSystem,
      'totalStorage': totalStorage,
      'totalOnLocation': measuredTotalOnLocation,
      'totalOnLocationLedger': ledgerTotalOnLocation,
      'totalOnLocationCumLeased': measuredTotalOnLocation,
      'volumeDifference': volumeDifference,
      'storageLossTotal': storageLossTotal,
    };
  }

  static double _number(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString().replaceAll(',', ''));
    return parsed ?? 0;
  }

  static double _round2(double value) =>
      double.parse(value.toStringAsFixed(2));

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
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Volume Snapshot',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              if (controller.selectedWellName.isNotEmpty)
                Text(
                  controller.selectedWellName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: controller.load,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: Get.back,
          ),
        ],
      ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (controller.errorMessage.value.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          border: Border.all(color: const Color(0xFFFFD7A8)),
                          borderRadius: BorderRadius.circular(4),
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
                            child: _buildLeftTable(
                              controller,
                              constraints.maxHeight - 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRightTables(
                              controller,
                              constraints.maxHeight - 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildLeftTable(
    VolumeSnapshotController controller,
    double availableHeight,
  ) {
    return _SnapshotCard(
      title: 'Active System Volume',
      unitLabel: AppUnits.fluidVolume,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _valueRow(
                    'Start Vol.',
                    controller.display('startVol'),
                    isBold: true,
                  ),
                  _sectionHeader('Addition'),
                  _groupedRows(
                    [
                      _SnapshotRow('Receive Mud', controller.display('receiveMud')),
                      _SnapshotRow('Base Fluid', controller.display('baseFluid')),
                      _SnapshotRow(
                        'Weight Material',
                        controller.display('weightMaterial'),
                      ),
                      _SnapshotRow('Products', controller.display('products')),
                      _SnapshotRow('Water', controller.display('water')),
                      _SnapshotRow('Formation', controller.display('formation')),
                      _SnapshotRow('Cuttings', controller.display('cuttings')),
                      _SnapshotRow(
                        'Cuttings/Retention',
                        controller.display('cuttingsRetention'),
                      ),
                      _SnapshotRow('Seepage', controller.display('seepage')),
                    ],
                    total: controller.display('additionTotal'),
                  ),
                  _sectionHeader('Loss'),
                  _groupedRows(
                    [
                      _SnapshotRow('Dump', controller.display('dump')),
                      _SnapshotRow('Shakers', controller.display('shakers')),
                      _SnapshotRow(
                        'Centrifuge',
                        controller.display('centrifuge'),
                      ),
                      _SnapshotRow(
                        'Evaporation',
                        controller.display('evaporation'),
                      ),
                      _SnapshotRow(
                        'Pit Cleaning',
                        controller.display('pitCleaning'),
                      ),
                      _SnapshotRow(
                        'Formation',
                        controller.display('formationLoss'),
                      ),
                      _SnapshotRow(
                        'Abandon in Hole',
                        controller.display('abandonInHole'),
                      ),
                      _SnapshotRow(
                        'Left behind Casing',
                        controller.display('leftBehindCasing'),
                      ),
                      _SnapshotRow('Tripping', controller.display('tripping')),
                    ],
                    total: controller.display('lossTotal'),
                  ),
                  _sectionHeader('Transfer'),
                  _groupedRows([
                    _SnapshotRow(
                      'From Storage',
                      controller.display('fromStorage'),
                    ),
                    _SnapshotRow(
                      'To Storage',
                      controller.display('toStorage', negative: true),
                      valueColor: Colors.red,
                    ),
                    _SnapshotRow('Return', controller.display('returnVol')),
                  ]),
                  const Divider(
                    height: 1,
                    thickness: 1.5,
                    color: Color(0xFFB8B8B8),
                  ),
                  _valueRow(
                    'End Vol.',
                    controller.display('endVol'),
                    isBold: true,
                  ),
                  _valueRow(
                    'End Vol. - Active System',
                    controller.display('endVolActiveSystem'),
                    isBold: true,
                    valueColor:
                        controller.raw('endVolActiveSystem').abs() > 0.001
                        ? Colors.red
                        : const Color(0xFF333333),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightTables(
    VolumeSnapshotController controller,
    double availableHeight,
  ) {
    final tableHeight = (availableHeight - 24) / 3;

    return Column(
      children: [
        SizedBox(
          height: tableHeight,
          child: _SnapshotCard(
            title: 'Storage Loss',
            unitLabel: AppUnits.fluidVolume,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _valueRow('Dump', controller.display('storageDump')),
                  _valueRow(
                    'Evaporation',
                    controller.display('storageEvaporation'),
                  ),
                  _valueRow(
                    'Pit Cleaning',
                    controller.display('storagePitCleaning'),
                  ),
                  _valueRow(
                    'Premixed Mud',
                    controller.display('premixedMud'),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFB8B8B8),
                  ),
                  _valueRow(
                    'Leased Mud Received',
                    controller.display('leasedMudReceived'),
                  ),
                  _valueRow(
                    'Leased Mud Returned',
                    controller.display('leasedMudReturned'),
                  ),
                  _valueRow(
                    'Non-leased Mud Received',
                    controller.display('nonLeasedMudReceived'),
                  ),
                  _valueRow(
                    'Non-leased Mud Returned',
                    controller.display('nonLeasedMudReturned'),
                  ),
                  _valueRow('Cum. Leased', controller.display('cumLeased')),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFB8B8B8),
                  ),
                  _valueRow(
                    'Volume Summary',
                    controller.display('volumeSummary'),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: tableHeight,
          child: _SnapshotCard(
            title: 'Hole Vol. Difference',
            unitLabel: AppUnits.fluidVolume,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _valueRow('Hole', controller.display('hole'), isBold: true),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFB8B8B8),
                  ),
                  _valueRow(
                    'Active Pits',
                    controller.display('activePits'),
                    isBold: true,
                  ),
                  _valueRow(
                    'Active System',
                    controller.display('activeSystem'),
                    isBold: true,
                  ),
                  _valueRow(
                    'Total Storage',
                    controller.display('totalStorage'),
                    isBold: true,
                  ),
                  _valueRow(
                    'Total on Location',
                    controller.display('totalOnLocation'),
                    isBold: true,
                  ),
                  _valueRow(
                    'Cum. Leased',
                    controller.display('cumLeased'),
                    isBold: true,
                  ),
                  _valueRow(
                    'Volume Difference*',
                    controller.display('volumeDifference'),
                    isBold: true,
                    valueColor:
                        controller.raw('volumeDifference').abs() > 0.001
                        ? Colors.red
                        : const Color(0xFF333333),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFB8B8B8),
                  ),
                  _valueRow(
                    'Total on Location - Cum. Leased',
                    controller.display('totalOnLocationCumLeased'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: tableHeight,
          child: Align(
            alignment: Alignment.topRight,
            child: ElevatedButton(
              onPressed: Get.back,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0D0D0),
                foregroundColor: const Color(0xFF333333),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
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

  Widget _sectionHeader(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFFE6E6FA),
        border: Border(
          top: BorderSide(color: Color(0xFFB8B8B8), width: 1),
          bottom: BorderSide(color: Color(0xFFB8B8B8), width: 1),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B0082),
        ),
      ),
    );
  }

  Widget _groupedRows(List<_SnapshotRow> rows, {String? total}) {
    return Column(
      children: [
        for (final row in rows)
          _valueRow(
            row.label,
            row.value,
            indent: 1,
            valueColor: row.valueColor,
          ),
        if (total != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFD0D0D0), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _valueRow(
    String label,
    String value, {
    int indent = 0,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 10 + (indent * 20.0),
        right: 10,
        top: 4,
        bottom: 4,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD0D0D0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: valueColor ?? const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final String title;
  final String unitLabel;
  final Widget child;

  const _SnapshotCard({
    required this.title,
    required this.unitLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F3),
        border: Border.all(color: const Color(0xFFB8B8B8), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8E8E8),
              border: Border(
                bottom: BorderSide(color: Color(0xFFB8B8B8), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Text(
                  'Vol. $unitLabel',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SnapshotRow {
  final String label;
  final String value;
  final Color? valueColor;

  const _SnapshotRow(
    this.label,
    this.value, {
    this.valueColor,
  });
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
