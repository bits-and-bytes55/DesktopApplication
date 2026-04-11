import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class AlertPredictionRow {
  const AlertPredictionRow({
    required this.description,
    required this.unit,
    required this.price,
    required this.todayUsage,
    required this.tomorrowUsage,
    required this.plusOneUsage,
    required this.plusTwoUsage,
    this.previousDayOneUsage,
    this.previousDayTwoUsage,
    this.currentInventory,
    this.zeroInventoryDays,
  });

  final String description;
  final String unit;
  final double price;
  final double? previousDayTwoUsage;
  final double? previousDayOneUsage;
  final double todayUsage;
  final double? currentInventory;
  final double tomorrowUsage;
  final double plusOneUsage;
  final double plusTwoUsage;
  final double? zeroInventoryDays;
}

class ReportAlertPredictionController extends GetxController {
  final productRows = <AlertPredictionRow>[].obs;
  final serviceRows = <AlertPredictionRow>[].obs;
  final summaryData = <String, double>{}.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final summaryText = ''.obs;

  final InventorySnapshotController _inventorySnapshotController =
      InventorySnapshotController();

  Worker? _wellWorker;
  Worker? _reportWorker;

  @override
  void onInit() {
    super.onInit();
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
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _inventorySnapshotController.generateInventorySnapshot();
      final response = await _inventorySnapshotController.getInventorySnapshot();
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to load inventory snapshot');
      }

      final items = (response['items'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();

      productRows.assignAll(
        items
            .where((item) => _isProductCategory(item['category']))
            .map(_toRow)
            .where((row) => row.description.isNotEmpty)
            .toList(),
      );

      serviceRows.assignAll(
        items
            .where((item) => _isServiceCategory(item['category']))
            .map(_toRow)
            .where((row) => row.description.isNotEmpty)
            .toList(),
      );

      summaryData.assignAll(
        _toSummaryMap(response['summary'] as Map<String, dynamic>? ?? const {}),
      );
      summaryText.value = _buildSummary(
        items: items,
        summary: response['summary'] as Map<String, dynamic>? ?? const {},
      );
    } catch (e) {
      productRows.clear();
      serviceRows.clear();
      summaryData.clear();
      summaryText.value = '';
      errorMessage.value = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    } finally {
      isLoading.value = false;
    }
  }

  bool _isProductCategory(dynamic category) {
    final value = _normalize(category);
    return value == 'product' || value == 'package';
  }

  bool _isServiceCategory(dynamic category) {
    final value = _normalize(category);
    return value == 'service' || value == 'engineering';
  }

  AlertPredictionRow _toRow(Map<String, dynamic> item) {
    final todayUsage = _number(item['used']);
    final inventory = _number(item['final']);
    final double predictedUsage = todayUsage > 0 ? todayUsage : 0.0;
    final zeroInventoryDays = predictedUsage > 0 && inventory > 0
        ? inventory / predictedUsage
        : null;

    return AlertPredictionRow(
      description: _text(item['itemName']),
      unit: _text(item['unit']),
      price: _number(item['price']),
      previousDayTwoUsage: null,
      previousDayOneUsage: null,
      todayUsage: todayUsage,
      currentInventory: _isProductCategory(item['category']) ? inventory : null,
      tomorrowUsage: predictedUsage,
      plusOneUsage: predictedUsage,
      plusTwoUsage: predictedUsage,
      zeroInventoryDays: _isProductCategory(item['category'])
          ? zeroInventoryDays
          : null,
    );
  }

  String _buildSummary({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> summary,
  }) {
    final parts = <String>[
      'Rows ${items.length}',
      'Products ${productRows.length}',
      'Services ${serviceRows.length}',
    ];

    final dailyTotal = _number(summary['dailyTotal']);
    if (dailyTotal > 0) {
      parts.add('Daily total ${dailyTotal.toStringAsFixed(2)}');
    }

    final stockBalance = _number(summary['stockBalance']);
    if (stockBalance > 0) {
      parts.add('Stock balance ${stockBalance.toStringAsFixed(2)}');
    }

    return parts.join(' | ');
  }

  Map<String, double> _toSummaryMap(Map<String, dynamic> summary) {
    return {
      'subtotal': _number(summary['subtotal']),
      'taxRate': _number(summary['taxRate']),
      'taxAmount': _number(summary['taxAmount']),
      'dailyTotal': _number(summary['dailyTotal']),
      'prevTotal': _number(summary['prevTotal']),
      'cumTotal': _number(summary['cumTotal']),
      'intervalTotal': _number(summary['intervalTotal']),
      'stockBalance': _number(summary['stockBalance']),
      'bulkTankSetupFee': _number(summary['bulkTankSetupFee']),
    };
  }

  String _normalize(dynamic value) {
    return _text(value).toLowerCase().trim();
  }

  String _text(dynamic value) {
    return value == null ? '' : value.toString().trim();
  }

  double _number(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value.toString().replaceAll(',', '').trim());
    return parsed ?? 0;
  }
}
