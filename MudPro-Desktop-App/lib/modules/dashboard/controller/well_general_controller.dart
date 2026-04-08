import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart'
    show kControllerWellId;
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class WellGeneralController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;

  var isLoading = false.obs;
  var isSaving = false.obs;
  var savedId = ''.obs; // ID of currently loaded record

  // All field values as Rx strings so UI can react
  var reportNo = ''.obs;
  var userReportNo = ''.obs;
  var date = ''.obs;
  var time = ''.obs;
  var engineer = ''.obs;
  var engineer2 = ''.obs;
  var operatorRep = ''.obs;
  var contractorRep = ''.obs;
  var activity = ''.obs;
  var md = ''.obs;
  var tvd = ''.obs;
  var inc = ''.obs;
  var azi = ''.obs;
  var wob = ''.obs;
  var rotWt = ''.obs;
  var soWt = ''.obs;
  var puWt = ''.obs;
  var rpm = ''.obs;
  var rop = ''.obs;
  var offBottomTq = ''.obs;
  var onBottomTq = ''.obs;
  var suctionT = ''.obs;
  var bottomT = ''.obs;
  var interval = ''.obs;
  var fit = ''.obs;
  var formation = ''.obs;
  var additionalFootage = ''.obs;
  var nptTime = ''.obs;
  var nptCost = ''.obs;
  var depthDrilled = ''.obs;
  Worker? _wellWorker;
  Worker? _reportWorker;
  Worker? _unitMapWorker;
  Worker? _unitSystemWorker;

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      fetchLatest();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      _applySelectedReportMetadata();
    });
    final options = AppUnits.controller;
    _unitMapWorker = ever<dynamic>(options.customUnits, (_) {
      if (kControllerWellId.isNotEmpty) {
        fetchLatest();
      }
    });
    _unitSystemWorker = ever<dynamic>(options.unitSystem, (_) {
      if (kControllerWellId.isNotEmpty) {
        fetchLatest();
      }
    });
    fetchLatest();
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    _unitMapWorker?.dispose();
    _unitSystemWorker?.dispose();
    super.onClose();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  double _toBaseValue(
    String rawValue, {
    required String displayUnit,
    required String baseUnit,
  }) {
    final parsed = double.tryParse(rawValue.trim());
    if (parsed == null) {
      return 0;
    }
    return AppUnits.convertValue(parsed, displayUnit, baseUnit) ?? parsed;
  }

  String _fromBaseValue(
    dynamic rawValue, {
    required String baseUnit,
    required String displayUnit,
  }) {
    if (rawValue == null || rawValue.toString().trim().isEmpty) {
      return '';
    }
    final parsed = double.tryParse(rawValue.toString().trim());
    if (parsed == null) {
      return rawValue.toString();
    }
    final converted =
        AppUnits.convertValue(parsed, baseUnit, displayUnit) ?? parsed;
    return _formatNumber(converted);
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0';
    }
    if (value == value.truncateToDouble()) {
      return value.truncate().toString();
    }
    return value
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Map<String, dynamic> _toJson() => {
    if (savedId.value.isNotEmpty) 'recordId': savedId.value,
    'reportNo': reportNo.value,
    'userReportNo': userReportNo.value,
    'date': date.value,
    'time': time.value,
    'engineer': engineer.value,
    'engineer2': engineer2.value,
    'operatorRep': operatorRep.value,
    'contractorRep': contractorRep.value,
    'activity': activity.value,
    'md': _toBaseValue(
      md.value,
      displayUnit: AppUnits.length,
      baseUnit: '(ft)',
    ),
    'tvd': _toBaseValue(
      tvd.value,
      displayUnit: AppUnits.length,
      baseUnit: '(ft)',
    ),
    'inc': double.tryParse(inc.value) ?? 0,
    'azi': double.tryParse(azi.value) ?? 0,
    'wob': _toBaseValue(
      wob.value,
      displayUnit: AppUnits.force,
      baseUnit: '(lbf)',
    ),
    'rotWt': _toBaseValue(
      rotWt.value,
      displayUnit: AppUnits.force,
      baseUnit: '(lbf)',
    ),
    'soWt': _toBaseValue(
      soWt.value,
      displayUnit: AppUnits.force,
      baseUnit: '(lbf)',
    ),
    'puWt': _toBaseValue(
      puWt.value,
      displayUnit: AppUnits.force,
      baseUnit: '(lbf)',
    ),
    'rpm': double.tryParse(rpm.value) ?? 0,
    'rop': _toBaseValue(
      rop.value,
      displayUnit: AppUnits.rop,
      baseUnit: '(ft/hr)',
    ),
    'offBottomTq': _toBaseValue(
      offBottomTq.value,
      displayUnit: AppUnits.torque,
      baseUnit: '(ft-lb)',
    ),
    'onBottomTq': _toBaseValue(
      onBottomTq.value,
      displayUnit: AppUnits.torque,
      baseUnit: '(ft-lb)',
    ),
    'suctionT': _toBaseValue(
      suctionT.value,
      displayUnit: AppUnits.temperature,
      baseUnit: '(Â°F)',
    ),
    'bottomT': _toBaseValue(
      bottomT.value,
      displayUnit: AppUnits.temperature,
      baseUnit: '(Â°F)',
    ),
    'interval': interval.value,
    'fit': _toBaseValue(
      fit.value,
      displayUnit: AppUnits.mudWeight,
      baseUnit: '(ppg)',
    ),
    'formation': formation.value,
    'additionalFootage': _toBaseValue(
      additionalFootage.value,
      displayUnit: AppUnits.length,
      baseUnit: '(ft)',
    ),
    'nptTime': double.tryParse(nptTime.value) ?? 0,
    'nptCost': double.tryParse(nptCost.value) ?? 0,
    'depthDrilled': _toBaseValue(
      depthDrilled.value,
      displayUnit: AppUnits.length,
      baseUnit: '(ft)',
    ),
  };

  void _fromJson(Map<String, dynamic> d) {
    savedId.value = d['_id'] ?? '';
    reportNo.value = d['reportNo']?.toString() ?? '';
    userReportNo.value = d['userReportNo']?.toString() ?? '';
    date.value = d['date']?.toString() ?? '';
    time.value = d['time']?.toString() ?? '';
    engineer.value = d['engineer']?.toString() ?? '';
    engineer2.value = d['engineer2']?.toString() ?? '';
    operatorRep.value = d['operatorRep']?.toString() ?? '';
    contractorRep.value = d['contractorRep']?.toString() ?? '';
    activity.value = d['activity']?.toString() ?? '';
    md.value = _fromBaseValue(
      d['md'],
      baseUnit: '(ft)',
      displayUnit: AppUnits.length,
    );
    tvd.value = _fromBaseValue(
      d['tvd'],
      baseUnit: '(ft)',
      displayUnit: AppUnits.length,
    );
    inc.value = (d['inc'] ?? '').toString();
    azi.value = (d['azi'] ?? '').toString();
    wob.value = _fromBaseValue(
      d['wob'],
      baseUnit: '(lbf)',
      displayUnit: AppUnits.force,
    );
    rotWt.value = _fromBaseValue(
      d['rotWt'],
      baseUnit: '(lbf)',
      displayUnit: AppUnits.force,
    );
    soWt.value = _fromBaseValue(
      d['soWt'],
      baseUnit: '(lbf)',
      displayUnit: AppUnits.force,
    );
    puWt.value = _fromBaseValue(
      d['puWt'],
      baseUnit: '(lbf)',
      displayUnit: AppUnits.force,
    );
    rpm.value = (d['rpm'] ?? '').toString();
    rop.value = _fromBaseValue(
      d['rop'],
      baseUnit: '(ft/hr)',
      displayUnit: AppUnits.rop,
    );
    offBottomTq.value = _fromBaseValue(
      d['offBottomTq'],
      baseUnit: '(ft-lb)',
      displayUnit: AppUnits.torque,
    );
    onBottomTq.value = _fromBaseValue(
      d['onBottomTq'],
      baseUnit: '(ft-lb)',
      displayUnit: AppUnits.torque,
    );
    suctionT.value = _fromBaseValue(
      d['suctionT'],
      baseUnit: '(Â°F)',
      displayUnit: AppUnits.temperature,
    );
    bottomT.value = _fromBaseValue(
      d['bottomT'],
      baseUnit: '(Â°F)',
      displayUnit: AppUnits.temperature,
    );
    interval.value = d['interval']?.toString() ?? '';
    fit.value = _fromBaseValue(
      d['fit'],
      baseUnit: '(ppg)',
      displayUnit: AppUnits.mudWeight,
    );
    formation.value = d['formation']?.toString() ?? '';
    additionalFootage.value = _fromBaseValue(
      d['additionalFootage'],
      baseUnit: '(ft)',
      displayUnit: AppUnits.length,
    );
    nptTime.value = (d['nptTime'] ?? '').toString();
    nptCost.value = (d['nptCost'] ?? '').toString();
    depthDrilled.value = _fromBaseValue(
      d['depthDrilled'],
      baseUnit: '(ft)',
      displayUnit: AppUnits.length,
    );
  }

  void _clearFields() {
    savedId.value = '';
    reportNo.value = '';
    userReportNo.value = '';
    date.value = '';
    time.value = '';
    engineer.value = '';
    engineer2.value = '';
    operatorRep.value = '';
    contractorRep.value = '';
    activity.value = '';
    md.value = '';
    tvd.value = '';
    inc.value = '';
    azi.value = '';
    wob.value = '';
    rotWt.value = '';
    soWt.value = '';
    puWt.value = '';
    rpm.value = '';
    rop.value = '';
    offBottomTq.value = '';
    onBottomTq.value = '';
    suctionT.value = '';
    bottomT.value = '';
    interval.value = '';
    fit.value = '';
    formation.value = '';
    additionalFootage.value = '';
    nptTime.value = '';
    nptCost.value = '';
    depthDrilled.value = '';
  }

  void _applySelectedReportMetadata() {
    final report = reportContext.selectedReport;
    if (report == null) return;

    reportNo.value = report.reportNo;
    userReportNo.value = report.userReportNo.isNotEmpty
        ? report.userReportNo
        : report.reportNo;
    if (report.reportDate.isNotEmpty) {
      date.value = report.reportDate;
    }
  }

  // ─── FETCH latest record ───────────────────────
  Future<void> fetchLatest() async {
    if (kControllerWellId.isEmpty) {
      _clearFields();
      return;
    }
    isLoading.value = true;
    try {
      _clearFields();
      final response = await http.get(
        Uri.parse('${baseUrl}well-general/$kControllerWellId'),
        headers: _headers,
      );

      print(
        'WellGeneral fetch response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        if (data.isNotEmpty) {
          _fromJson(data.first);
        }
        _applySelectedReportMetadata();
      }
    } catch (e) {
      print('WellGeneral fetch error: $e');
      _applySelectedReportMetadata();
    } finally {
      isLoading.value = false;
    }
  }

  // ─── SAVE (create or update) ───────────────────
  Future<Map<String, dynamic>> save() async {
    if (kControllerWellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    isSaving.value = true;
    try {
      final authRepo = AuthRepository();

      // We always send the wellId from kControllerWellId to the new unified Save endpoint
      final payload = _toJson();
      payload['wellId'] = kControllerWellId;

      final result = await authRepo.saveWellGeneral(payload);

      if (result['success'] == true) {
        final data =
            result['data']?['data']; // auth_repo returns {success, data: {success, data, message}}
        if (data != null) {
          _fromJson(data);
        }
        return {
          'success': true,
          'message': 'Well General data saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to save Well General data',
        };
      }
    } catch (e) {
      print('WellGeneral save error: $e');
      return {'success': false, 'message': 'Error saving Well General: $e'};
    } finally {
      isSaving.value = false;
    }
  }
}
