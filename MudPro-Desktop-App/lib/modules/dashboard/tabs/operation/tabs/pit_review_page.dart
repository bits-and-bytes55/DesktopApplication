import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

const _pitReviewBorder = Color(0xFFC8C8C8);
const _pitReviewHeaderFill = Color(0xFFF3F3F3);
const _pitReviewValueFill = Color(0xFFFFF8CC);

class PitReviewController extends GetxController {
  PitReviewController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final storageRows = <PitReviewStorageRow>[].obs;
  final summaryRows = <PitReviewSummaryRow>[].obs;

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

    errorMessage.value = '';
    if (wellId.isEmpty) {
      storageRows.clear();
      summaryRows.clear();
      errorMessage.value = 'Select a well first to open Pit Review.';
      return;
    }
    if (reportId.isEmpty) {
      storageRows.clear();
      summaryRows.clear();
      errorMessage.value = 'Select a report first to open Pit Review.';
      return;
    }

    isLoading.value = true;
    try {
      final result = await _authRepository.getVolumeNameCalculation(wellId);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load pit review');
      }

      final payload = _map(_map(result['data'])['data']);
      final volumeName = _map(payload['volumeName']);
      final storage = _extractList(payload['storageTable']);

      storageRows.assignAll(
        storage
            .where((row) => _text(row['pitName']).isNotEmpty)
            .map(
              (row) => PitReviewStorageRow(
                pitName: _text(row['pitName']),
                capacity: _number(row['capacity']),
                calculatedVol: _number(row['calculatedVol']),
              ),
            )
            .toList(growable: false),
      );

      summaryRows.assignAll([
        PitReviewSummaryRow(
          'Hole Vol. Difference',
          _number(volumeName['heldVolDifference']),
        ),
        PitReviewSummaryRow('Hole', _number(volumeName['hole'])),
        PitReviewSummaryRow('Active Pits', _number(volumeName['activePits'])),
        PitReviewSummaryRow(
          'Active System',
          _number(volumeName['activeSystem']),
        ),
        PitReviewSummaryRow('End Vol.', _number(volumeName['endVol'])),
        PitReviewSummaryRow(
          'End Vol. - Active System',
          _number(volumeName['endVolMinusActiveSystem']),
          highlightRed:
              _number(volumeName['endVolMinusActiveSystem']).abs() > 0.005,
        ),
        PitReviewSummaryRow(
          'Total Storage',
          _number(volumeName['totalStorage']),
        ),
        PitReviewSummaryRow(
          'Total on Location',
          _number(volumeName['totalOnLocation']),
        ),
        PitReviewSummaryRow(
          'Previous Total on Location',
          _number(volumeName['previousTotalOnLocation']),
        ),
      ]);
    } catch (error) {
      storageRows.clear();
      summaryRows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';
}

class PitReviewPage extends StatelessWidget {
  const PitReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PitReviewController>()
        ? Get.find<PitReviewController>()
        : Get.put(PitReviewController());

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Obx(
          () => Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _pitReviewBorder),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _buildStorageTable(controller),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 6,
                                child: _buildSummaryTable(controller),
                              ),
                            ],
                          ),
                        ),
                        if (controller.isLoading.value)
                          const Positioned.fill(
                            child: IgnorePointer(
                              child: ColoredBox(
                                color: Color(0x99FFFFFF),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildFooter(controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pit Review',
              style: TextStyle(
                fontSize: 15,
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

  Widget _buildStorageTable(PitReviewController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'Storage',
            style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _pitReviewBorder),
            ),
            child: Column(
              children: [
                Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: _pitReviewBorder),
                    verticalInside: BorderSide(color: _pitReviewBorder),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1.4),
                    1: FlexColumnWidth(0.95),
                    2: FlexColumnWidth(1.1),
                  },
                  children: const [
                    TableRow(
                      decoration: BoxDecoration(color: _pitReviewHeaderFill),
                      children: [
                        _PitReviewHeaderCell('Pit'),
                        _PitReviewHeaderCell('Capacity\n(bbl)'),
                        _PitReviewHeaderCell('Calculated Vol.\n(bbl)'),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child:
                      controller.errorMessage.value.isNotEmpty &&
                          controller.storageRows.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              controller.errorMessage.value,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: controller.storageRows.length,
                          itemBuilder: (context, index) {
                            final row = controller.storageRows[index];
                            return Container(
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: _pitReviewBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 14,
                                    child: _PitReviewValueCell(
                                      row.pitName,
                                      fill: Colors.white,
                                      alignRight: false,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 10,
                                    child: _PitReviewValueCell(
                                      row.capacity.toStringAsFixed(2),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 11,
                                    child: _PitReviewValueCell(
                                      row.calculatedVol.toStringAsFixed(2),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTable(PitReviewController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text('', style: TextStyle(fontSize: 12)),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _pitReviewBorder),
          ),
          child: Table(
            border: const TableBorder(
              horizontalInside: BorderSide(color: _pitReviewBorder),
              verticalInside: BorderSide(color: _pitReviewBorder),
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.9),
              1: FlexColumnWidth(0.9),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: _pitReviewHeaderFill),
                children: [
                  _PitReviewHeaderCell('Volume Name'),
                  _PitReviewHeaderCell('Volume\n(bbl)'),
                ],
              ),
              ...controller.summaryRows.map(
                (row) => TableRow(
                  children: [
                    _PitReviewValueCell(
                      row.name,
                      fill: Colors.white,
                      alignRight: false,
                    ),
                    _PitReviewValueCell(
                      row.value.toStringAsFixed(2),
                      textColor: row.highlightRed ? Colors.red : Colors.black87,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(PitReviewController controller) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 104,
            child: OutlinedButton(
              onPressed: controller.isLoading.value ? null : controller.load,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF555555),
                side: const BorderSide(color: _pitReviewBorder),
                backgroundColor: const Color(0xFFF8F8F8),
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text('Refresh'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 104,
            child: OutlinedButton(
              onPressed: Get.back,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF555555),
                side: const BorderSide(color: _pitReviewBorder),
                backgroundColor: const Color(0xFFF8F8F8),
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}

class PitReviewStorageRow {
  const PitReviewStorageRow({
    required this.pitName,
    required this.capacity,
    required this.calculatedVol,
  });

  final String pitName;
  final double capacity;
  final double calculatedVol;
}

class PitReviewSummaryRow {
  const PitReviewSummaryRow(this.name, this.value, {this.highlightRed = false});

  final String name;
  final double value;
  final bool highlightRed;
}

class _PitReviewHeaderCell extends StatelessWidget {
  const _PitReviewHeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF444444),
        ),
      ),
    );
  }
}

class _PitReviewValueCell extends StatelessWidget {
  const _PitReviewValueCell(
    this.text, {
    this.fill = _pitReviewValueFill,
    this.alignRight = true,
    this.textColor = Colors.black87,
  });

  final String text;
  final Color fill;
  final bool alignRight;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      color: fill,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: textColor),
      ),
    );
  }
}
