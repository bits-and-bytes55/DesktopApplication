import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/recap_daily_cost/controller/recap_daily_cost_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapCumCostController extends GetxController {
  final RecapDailyCostController _dailyCostController;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapCumCostController({
    RecapDailyCostController? dailyCostController,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _dailyCostController =
           dailyCostController ??
           (Get.isRegistered<RecapDailyCostController>()
               ? Get.find<RecapDailyCostController>()
               : Get.put(RecapDailyCostController())),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <CumulativeCostRow>[].obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

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
      emptyMessage.value = 'Select a well first to open Cumulative Cost recap.';
      return;
    }

    isLoading.value = true;

    try {
      await _dailyCostController.load();
      if (_dailyCostController.errorMessage.value.isNotEmpty) {
        throw Exception(_dailyCostController.errorMessage.value);
      }

      final dailyRows = [..._dailyCostController.rows];
      if (dailyRows.isEmpty) {
        rows.clear();
        emptyMessage.value = _dailyCostController.emptyMessage.value.isNotEmpty
            ? _dailyCostController.emptyMessage.value
            : 'No cumulative cost history is available yet.';
        return;
      }

      final runningProduct = <String, double>{};
      final runningPremixed = <String, double>{};
      final runningPackage = <String, double>{};
      final runningService = <String, double>{};
      final runningEngineering = <String, double>{};

      final history = <CumulativeCostRow>[];

      for (final row in dailyRows) {
        _mergeMaps(runningProduct, row.productItems);
        _mergeMaps(runningPremixed, row.premixedMudItems);
        _mergeMaps(runningPackage, row.packageItems);
        _mergeMaps(runningService, row.serviceItems);
        _mergeMaps(runningEngineering, row.engineeringItems);

        final productItems = Map<String, double>.from(runningProduct);
        final premixedItems = Map<String, double>.from(runningPremixed);
        final packageItems = Map<String, double>.from(runningPackage);
        final serviceItems = Map<String, double>.from(runningService);
        final engineeringItems = Map<String, double>.from(runningEngineering);

        final productTotal = _sum(productItems.values);
        final premixedTotal = _sum(premixedItems.values);
        final packageTotal = _sum(packageItems.values);
        final serviceTotal = _sum(serviceItems.values);
        final engineeringTotal = _sum(engineeringItems.values);

        history.add(
          CumulativeCostRow(
            reportId: row.reportId,
            reportLabel: row.reportLabel,
            reportDate: row.reportDate,
            md: row.md,
            productItems: productItems,
            premixedMudItems: premixedItems,
            packageItems: packageItems,
            serviceItems: serviceItems,
            engineeringItems: engineeringItems,
            productTotal: productTotal,
            premixedMudTotal: premixedTotal,
            packageTotal: packageTotal,
            serviceTotal: serviceTotal,
            engineeringTotal: engineeringTotal,
          ),
        );
      }

      rows.assignAll(history);
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  List<double> get productSeries =>
      rows.map((row) => row.productTotal / 1000).toList();
  List<double> get premixedSeries =>
      rows.map((row) => row.premixedMudTotal / 1000).toList();
  List<double> get packageSeries =>
      rows.map((row) => row.packageTotal / 1000).toList();
  List<double> get serviceSeries =>
      rows.map((row) => row.serviceTotal / 1000).toList();
  List<double> get engineeringSeries =>
      rows.map((row) => row.engineeringTotal / 1000).toList();
  List<double> get totalSeries => rows.map((row) => row.total / 1000).toList();

  List<String> get productColumns => _orderedKeys((row) => row.productItems);
  List<String> get premixedColumns =>
      _orderedKeys((row) => row.premixedMudItems);
  List<String> get packageColumns => _orderedKeys((row) => row.packageItems);
  List<String> get serviceColumns => _orderedKeys((row) => row.serviceItems);
  List<String> get engineeringColumns =>
      _orderedKeys((row) => row.engineeringItems);

  List<String> get allCategoryColumns => const [
    'Product',
    'Premixed Mud',
    'Package',
    'Service',
    'Engineering',
    'Total',
  ];

  double allCategoryValueForRow(CumulativeCostRow row, String column) {
    switch (column) {
      case 'Product':
        return row.productTotal;
      case 'Premixed Mud':
        return row.premixedMudTotal;
      case 'Package':
        return row.packageTotal;
      case 'Service':
        return row.serviceTotal;
      case 'Engineering':
        return row.engineeringTotal;
      case 'Total':
        return row.total;
      default:
        return 0;
    }
  }

  List<String> _orderedKeys(
    Map<String, double> Function(CumulativeCostRow row) getter,
  ) {
    if (rows.isEmpty) return const <String>[];

    final totals = <String, double>{};
    for (final row in rows) {
      final values = getter(row);
      for (final entry in values.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
      }
    }

    final keys = totals.keys.toList();
    keys.sort((left, right) {
      final amountCompare = (totals[right] ?? 0).compareTo(totals[left] ?? 0);
      if (amountCompare != 0) return amountCompare;
      return left.toLowerCase().compareTo(right.toLowerCase());
    });
    return keys;
  }

  void _mergeMaps(Map<String, double> target, Map<String, double> source) {
    for (final entry in source.entries) {
      target[entry.key] = (target[entry.key] ?? 0) + entry.value;
    }
  }

  double _sum(Iterable<double> values) =>
      values.fold<double>(0, (sum, value) => sum + value);
}

class CumulativeCostRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final double md;
  final Map<String, double> productItems;
  final Map<String, double> premixedMudItems;
  final Map<String, double> packageItems;
  final Map<String, double> serviceItems;
  final Map<String, double> engineeringItems;
  final double productTotal;
  final double premixedMudTotal;
  final double packageTotal;
  final double serviceTotal;
  final double engineeringTotal;

  const CumulativeCostRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.md,
    required this.productItems,
    required this.premixedMudItems,
    required this.packageItems,
    required this.serviceItems,
    required this.engineeringItems,
    required this.productTotal,
    required this.premixedMudTotal,
    required this.packageTotal,
    required this.serviceTotal,
    required this.engineeringTotal,
  });

  double get total =>
      productTotal +
      premixedMudTotal +
      packageTotal +
      serviceTotal +
      engineeringTotal;
}
