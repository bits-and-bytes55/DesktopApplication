import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudTreatedController extends GetxController {
  MudTreatedController({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  final receiveMud = ''.obs;
  final baseFluid = ''.obs;
  final weightMaterial = ''.obs;
  final products = ''.obs;
  final water = ''.obs;
  final formation = ''.obs;
  final cuttings = ''.obs;
  final subTotal = ''.obs;
  final total = ''.obs;
  final fromStorage = ''.obs;
  final mudTreated = ''.obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) => load());
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) => load());
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
    final reportId = reportContext.selectedReportId.value.trim();

    if (wellId.isEmpty) {
      _reset();
      errorMessage.value = 'Select a well first to load Mud Treated.';
      return;
    }
    if (reportId.isEmpty) {
      _reset();
      errorMessage.value = 'Select a report first to load Mud Treated.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _repository.getVolumeNameCalculation(wellId);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load Mud Treated');
      }

      final payload = _map(_map(result['data'])['data']);
      final totals = _map(payload['totalsBreakdown']);
      final otherVolItems = await _fetchList(
        () => _repository.getOtherVolAdditionList(wellId),
      );
      final transferMudItems = await _fetchList(
        () => _repository.getTransferMud(wellId),
      );

      final receiveMudValue = _number(totals['receivedMudTotal']);
      final baseFluidValue = 0.0;
      final weightMaterialValue = 0.0;
      final productsValue = _number(totals['consumeProductTotal']);
      final waterValue = _number(totals['addWaterTotal']);
      final formationValue = _sum(otherVolItems, 'formation');
      final cuttingsValue = _sum(otherVolItems, 'cuttings');
      final fromStorageValue = _sumWhere(
        transferMudItems,
        'totalTransferVol',
        (item) =>
            (item['from'] ?? '').toString().trim().toLowerCase() !=
            'active system',
      );
      final totalValue = _round2(
        receiveMudValue +
            baseFluidValue +
            weightMaterialValue +
            productsValue +
            waterValue +
            formationValue +
            cuttingsValue,
      );

      receiveMud.value = _format(receiveMudValue);
      baseFluid.value = _format(baseFluidValue);
      weightMaterial.value = _format(weightMaterialValue);
      products.value = _format(productsValue);
      water.value = _format(waterValue);
      formation.value = _format(formationValue);
      cuttings.value = _format(cuttingsValue);
      subTotal.value = _format(totalValue);
      total.value = _format(totalValue);
      fromStorage.value = _format(fromStorageValue);
      mudTreated.value = _format(_round2(totalValue + fromStorageValue));
    } catch (e) {
      _reset();
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchList(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      final result = await request();
      if (result['success'] != true) return const <Map<String, dynamic>>[];
      return _extractList(result['data']);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.map(_map).where((item) => item.isNotEmpty).toList();
    }

    final envelope = _map(raw);
    final data = envelope['data'];
    if (data is List) {
      return data.map(_map).where((item) => item.isNotEmpty).toList();
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
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

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  double _round2(double value) => double.parse(value.toStringAsFixed(2));

  String _format(double value) => _round2(value).toStringAsFixed(2);

  void _reset() {
    receiveMud.value = '';
    baseFluid.value = '';
    weightMaterial.value = '';
    products.value = '';
    water.value = '';
    formation.value = '';
    cuttings.value = '';
    subTotal.value = '';
    total.value = '';
    fromStorage.value = '';
    mudTreated.value = '';
  }
}

class MudTreatedPage extends StatelessWidget {
  const MudTreatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<MudTreatedController>()
        ? Get.find<MudTreatedController>()
        : Get.put(MudTreatedController());

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        title: const Text(
          'Mud Treated',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
            onPressed: controller.load,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Center(
          child: SizedBox(
            width: 500,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.errorMessage.value.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        border: Border.all(color: const Color(0xFFFFD7A8)),
                      ),
                      child: Text(
                        controller.errorMessage.value,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A5A00),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildAdditionTable(controller),
                  const SizedBox(height: 20),
                  _buildActiveSystemTable(controller),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(
                            color: Color(0xFFB0B0B0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAdditionTable(MudTreatedController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFA0A0A0), width: 1),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
        },
        border: TableBorder.all(color: const Color(0xFFD0D0D0), width: 0.5),
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppTheme.primaryColor),
            children: [
              _buildHeaderCell('Addition'),
              _buildHeaderCell('Active System\n(bbl)'),
            ],
          ),
          _buildDataRow('Receive Mud', controller.receiveMud),
          _buildDataRow('Base Fluid', controller.baseFluid),
          _buildDataRow('Weight Material', controller.weightMaterial),
          _buildDataRow('Products', controller.products),
          _buildDataRow('Water', controller.water),
          _buildDataRow('Formation', controller.formation),
          _buildDataRow('Cuttings', controller.cuttings),
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
            children: [
              _buildLabelCell('Sub Total', bold: true),
              _buildValueCell(controller.subTotal, bold: true),
            ],
          ),
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
            children: [
              _buildLabelCell('Total', bold: true),
              _buildValueCell(controller.total, bold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSystemTable(MudTreatedController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFA0A0A0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFD0D0D0), width: 0.5),
              ),
            ),
            child: const Text(
              'Active System',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          _buildActiveSystemRow('From Storage', controller.fromStorage),
          _buildActiveSystemRow('Mud Treated', controller.mudTreated),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  TableRow _buildDataRow(String label, RxString value) {
    return TableRow(children: [_buildLabelCell(label), _buildValueCell(value)]);
  }

  Widget _buildLabelCell(String text, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildValueCell(RxString value, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      alignment: Alignment.centerRight,
      color: const Color(0xFFFFF8C6),
      child: Obx(
        () => Text(
          value.value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSystemRow(String label, RxString value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD0D0D0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ),
          SizedBox(
            width: 100,
            child: Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8C6),
                  border: Border.all(color: const Color(0xFFB0B0B0), width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  value.value,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '(bbl)',
            style: TextStyle(fontSize: 9, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
