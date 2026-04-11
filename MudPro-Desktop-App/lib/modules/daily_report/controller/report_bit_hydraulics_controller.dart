import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/nozzle_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/well_general_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/utility/utils/bit_hydraulics_calculator.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class ReportBitHydraulicsController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final snapshot = Rxn<BitHydraulicsSnapshot>();

  final mudWeightPpg = RxnDouble();
  final bitSizeIn = RxnDouble();
  final tfaIn2 = RxnDouble();
  final flowRateGpm = RxnDouble();
  final standpipePressurePsi = RxnDouble();
  final dhToolsPressureLossPsi = RxnDouble();
  final motorPressureLossPsi = RxnDouble();

  late final NozzleController _nozzleController;
  late final WellGeneralController _wellGeneralController;
  late final PitController _pitController;

  Worker? _wellWorker;
  Worker? _reportWorker;

  String get _currentWellId => padWellContext.selectedWellId.value.trim();

  @override
  void onInit() {
    super.onInit();
    _nozzleController = Get.isRegistered<NozzleController>()
        ? Get.find<NozzleController>()
        : Get.put(NozzleController());
    _wellGeneralController = Get.isRegistered<WellGeneralController>()
        ? Get.find<WellGeneralController>()
        : Get.put(WellGeneralController());
    _pitController = Get.isRegistered<PitController>()
        ? Get.find<PitController>()
        : Get.put(PitController());

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
    errorMessage.value = '';

    final wellId = _currentWellId;
    final selectedReport = reportContext.selectedReport;
    if (wellId.isEmpty || selectedReport == null) {
      _clearSnapshot();
      return;
    }

    try {
      isLoading.value = true;
      await Future.wait([
        _nozzleController.fetchNozzle(forceReset: true),
        _wellGeneralController.fetchLatest(),
        _pitController.fetchAllPits(),
      ]);

      final summary = selectedReport.pumpRateAndPressure;
      flowRateGpm.value = summary.pumpRate;
      standpipePressurePsi.value = summary.pumpPressure;
      dhToolsPressureLossPsi.value = summary.dhToolsPressureLoss;
      motorPressureLossPsi.value = summary.motorPressureLoss;
      tfaIn2.value = _nozzleController.tfa.value > 0
          ? _nozzleController.tfa.value
          : null;
      mudWeightPpg.value = _resolveMudWeight(_pitController.activePitRows);
      bitSizeIn.value = await _resolveBitSizeInches(
        wellId: wellId,
        intervalName: _wellGeneralController.interval.value,
      );

      final nextSnapshot = calculateBitHydraulics(
        BitHydraulicsInputs(
          mudWeightPpg: mudWeightPpg.value ?? 0,
          flowRateGpm: flowRateGpm.value ?? 0,
          standpipePressurePsi: standpipePressurePsi.value ?? 0,
          totalFlowAreaIn2: tfaIn2.value ?? 0,
          bitSizeIn: bitSizeIn.value,
          dhToolsPressureLossPsi: dhToolsPressureLossPsi.value ?? 0,
          motorPressureLossPsi: motorPressureLossPsi.value ?? 0,
        ),
      );

      snapshot.value = nextSnapshot;
      if (nextSnapshot == null) {
        errorMessage.value =
            'Pump pressure, pump rate, and nozzle TFA required';
      }
    } catch (e) {
      _clearSnapshot();
      errorMessage.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _clearSnapshot() {
    snapshot.value = null;
    mudWeightPpg.value = null;
    bitSizeIn.value = null;
    tfaIn2.value = null;
    flowRateGpm.value = null;
    standpipePressurePsi.value = null;
    dhToolsPressureLossPsi.value = null;
    motorPressureLossPsi.value = null;
  }

  double? _resolveMudWeight(List<PitModel> activePits) {
    final rows =
        activePits.where((pit) => (pit.density?.value ?? 0) > 0).toList()
          ..sort((left, right) {
            final leftVolume = left.volume?.value ?? 0;
            final rightVolume = right.volume?.value ?? 0;
            return rightVolume.compareTo(leftVolume);
          });

    if (rows.isEmpty) {
      return null;
    }

    return rows.first.density?.value;
  }

  Future<double?> _resolveBitSizeInches({
    required String wellId,
    required String intervalName,
  }) async {
    final parsedFromIntervalLabel = _parseBitSize(intervalName);
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoint.baseUrl}intervals/$wellId'),
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return parsedFromIntervalLabel;
      }

      final json = jsonDecode(response.body);
      final data = json['data'];
      if (data is! List) {
        return parsedFromIntervalLabel;
      }

      final rows = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => item['_type'] != 'group')
          .toList();

      final normalizedInterval = _normalize(intervalName);
      if (normalizedInterval.isNotEmpty) {
        final matched = _firstWhereOrNull<Map<String, dynamic>>(
          rows,
          (row) =>
              _normalize(row['name']?.toString() ?? '') == normalizedInterval,
        );
        final matchedSize = _parseBitSize(
          matched?['bitSize']?.toString() ?? '',
        );
        if (matchedSize != null && matchedSize > 0) {
          return matchedSize;
        }
      }

      for (final row in rows) {
        final next = _parseBitSize(row['bitSize']?.toString() ?? '');
        if (next != null && next > 0) {
          return next;
        }
      }
    } catch (_) {
      return parsedFromIntervalLabel;
    }

    return parsedFromIntervalLabel;
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
        return whole + (numerator / denominator);
      }
    }

    final simpleFraction = RegExp(r'^(\d+)/(\d+)$').firstMatch(cleaned);
    if (simpleFraction != null) {
      final numerator = double.tryParse(simpleFraction.group(1) ?? '');
      final denominator = double.tryParse(simpleFraction.group(2) ?? '');
      if (numerator != null && denominator != null && denominator != 0) {
        return numerator / denominator;
      }
    }

    final direct = double.tryParse(cleaned);
    if (direct != null) {
      return direct;
    }

    final decimalMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
    return decimalMatch == null
        ? null
        : double.tryParse(decimalMatch.group(1) ?? '');
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}
