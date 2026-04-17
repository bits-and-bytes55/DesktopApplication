import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart'
    show kControllerWellId;
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class WellGeneralController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;
  static const int _minTimeDistributionRows = 5;

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
  final timeDistributionRows = <Map<String, String>>[].obs;
  final timeDistributionRevision = 0.obs;
  Worker? _wellWorker;
  Worker? _reportWorker;

  @override
  void onInit() {
    super.onInit();
    _setTimeDistributionRows(const [], notify: false);
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      fetchLatest();
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      fetchLatest();
    });
    fetchLatest();
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    super.onClose();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _blankTimeDistributionRow() => {
    'activity': '',
    'time': '',
  };

  String _formatTimeDistributionValue(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    return value.toString().trim();
  }

  List<Map<String, String>> _normalizeTimeDistributionRows(dynamic rawRows) {
    final normalized = <Map<String, String>>[];

    if (rawRows is List) {
      for (final item in rawRows) {
        if (item is Map) {
          final activity = (item['activity'] ?? item['description'] ?? '')
              .toString()
              .trim();
          final time = _formatTimeDistributionValue(
            item['time'] ?? item['hours'],
          );
          normalized.add({
            'activity': activity,
            'time': time,
          });
        }
      }
    }

    while (normalized.length < _minTimeDistributionRows) {
      normalized.add(_blankTimeDistributionRow());
    }

    if (normalized.isNotEmpty &&
        normalized.last['activity']!.trim().isNotEmpty) {
      normalized.add(_blankTimeDistributionRow());
    }

    return normalized;
  }

  void _setTimeDistributionRows(dynamic rawRows, {bool notify = true}) {
    timeDistributionRows.assignAll(_normalizeTimeDistributionRows(rawRows));
    if (notify) {
      timeDistributionRevision.value++;
    }
  }

  List<Map<String, String>> get timeDistributionRowsForUi =>
      timeDistributionRows
          .map(
            (row) => {
              'activity': row['activity'] ?? '',
              'time': row['time'] ?? '',
            },
          )
          .toList();

  void hydrateTimeDistributionRows(dynamic rawRows, {bool notify = true}) {
    _setTimeDistributionRows(rawRows, notify: notify);
  }

  void updateTimeDistributionRow(
    int index, {
    String? activity,
    String? time,
    bool notify = false,
  }) {
    final rows = timeDistributionRowsForUi;
    while (rows.length <= index) {
      rows.add(_blankTimeDistributionRow());
    }

    final current = Map<String, String>.from(rows[index]);
    if (activity != null) {
      current['activity'] = activity;
    }
    if (time != null) {
      current['time'] = time;
    }
    rows[index] = current;
    _setTimeDistributionRows(rows, notify: notify);
  }

  List<Map<String, dynamic>> _serializeTimeDistributionRows() {
    final serialized = <Map<String, dynamic>>[];

    for (final row in timeDistributionRows) {
      final activity = (row['activity'] ?? '').trim();
      final time = (row['time'] ?? '').trim();
      if (activity.isEmpty && time.isEmpty) {
        continue;
      }

      serialized.add({
        'description': activity,
        'hours': double.tryParse(time) ?? 0,
      });
    }

    return serialized;
  }

  Map<String, dynamic> _toJson() => {
    if (savedId.value.isNotEmpty) 'recordId': savedId.value,
    if (reportContext.selectedReportId.value.isNotEmpty)
      'reportId': reportContext.selectedReportId.value,
    'reportNo': reportNo.value.isNotEmpty
        ? reportNo.value
        : reportContext.selectedReportNumber,
    'userReportNo': userReportNo.value.isNotEmpty
        ? userReportNo.value
        : reportContext.selectedReportNumber,
    'date': date.value,
    'time': time.value,
    'engineer': engineer.value,
    'engineer2': engineer2.value,
    'operatorRep': operatorRep.value,
    'contractorRep': contractorRep.value,
    'activity': activity.value,
    'md': double.tryParse(md.value) ?? 0,
    'tvd': double.tryParse(tvd.value) ?? 0,
    'inc': double.tryParse(inc.value) ?? 0,
    'azi': double.tryParse(azi.value) ?? 0,
    'wob': double.tryParse(wob.value) ?? 0,
    'rotWt': double.tryParse(rotWt.value) ?? 0,
    'soWt': double.tryParse(soWt.value) ?? 0,
    'puWt': double.tryParse(puWt.value) ?? 0,
    'rpm': double.tryParse(rpm.value) ?? 0,
    'rop': double.tryParse(rop.value) ?? 0,
    'offBottomTq': double.tryParse(offBottomTq.value) ?? 0,
    'onBottomTq': double.tryParse(onBottomTq.value) ?? 0,
    'suctionT': double.tryParse(suctionT.value) ?? 0,
    'bottomT': double.tryParse(bottomT.value) ?? 0,
    'interval': interval.value,
    'fit': fit.value,
    'formation': formation.value,
    'additionalFootage': double.tryParse(additionalFootage.value) ?? 0,
    'nptTime': double.tryParse(nptTime.value) ?? 0,
    'nptCost': double.tryParse(nptCost.value) ?? 0,
    'depthDrilled': double.tryParse(depthDrilled.value) ?? 0,
    'timeDistributionRows': _serializeTimeDistributionRows(),
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
    md.value = (d['md'] ?? '').toString();
    tvd.value = (d['tvd'] ?? '').toString();
    inc.value = (d['inc'] ?? '').toString();
    azi.value = (d['azi'] ?? '').toString();
    wob.value = (d['wob'] ?? '').toString();
    rotWt.value = (d['rotWt'] ?? '').toString();
    soWt.value = (d['soWt'] ?? '').toString();
    puWt.value = (d['puWt'] ?? '').toString();
    rpm.value = (d['rpm'] ?? '').toString();
    rop.value = (d['rop'] ?? '').toString();
    offBottomTq.value = (d['offBottomTq'] ?? '').toString();
    onBottomTq.value = (d['onBottomTq'] ?? '').toString();
    suctionT.value = (d['suctionT'] ?? '').toString();
    bottomT.value = (d['bottomT'] ?? '').toString();
    interval.value = d['interval']?.toString() ?? '';
    fit.value = d['fit']?.toString() ?? '';
    formation.value = d['formation']?.toString() ?? '';
    additionalFootage.value = (d['additionalFootage'] ?? '').toString();
    nptTime.value = (d['nptTime'] ?? '').toString();
    nptCost.value = (d['nptCost'] ?? '').toString();
    depthDrilled.value = (d['depthDrilled'] ?? '').toString();
    _setTimeDistributionRows(d['timeDistributionRows']);
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
    _setTimeDistributionRows(const []);
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

  Map<String, dynamic>? _findMatchingRecord(List<dynamic> rawItems) {
    final items = rawItems.whereType<Map>().map(Map<String, dynamic>.from).toList();
    if (items.isEmpty) return null;

    final report = reportContext.selectedReport;
    if (report == null) {
      return items.first;
    }

    Map<String, dynamic>? firstMatch(bool Function(Map<String, dynamic>) test) {
      for (final item in items) {
        if (test(item)) return item;
      }
      return null;
    }

    final reportNo = report.reportNo.trim();
    final userReportNo = report.userReportNo.trim();
    final reportDate = report.reportDate.trim();

    return firstMatch(
          (item) => (item['reportNo']?.toString().trim() ?? '') == reportNo,
        ) ??
        firstMatch(
          (item) =>
              userReportNo.isNotEmpty &&
              (item['userReportNo']?.toString().trim() ?? '') == userReportNo,
        ) ??
        firstMatch(
          (item) =>
              reportDate.isNotEmpty &&
              (item['date']?.toString().trim() ?? '') == reportDate,
        );
  }

  // FETCH latest record
  Future<void> fetchLatest() async {
    if (kControllerWellId.isEmpty) {
      if (savedId.value.isEmpty && md.value.isEmpty) {
        _clearFields();
      }
      return;
    }
    isLoading.value = true;
    try {
      final primaryUri = Uri.parse('${baseUrl}well-general/$kControllerWellId').replace(
        queryParameters: {
          if (reportContext.selectedReportId.value.isNotEmpty)
            'reportId': reportContext.selectedReportId.value,
        },
      );
      final response = await http.get(
        primaryUri,
        headers: _headers,
      );

      print(
        'WellGeneral fetch response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        var matched = _findMatchingRecord(data);

        if (matched == null) {
          final reportNo = reportContext.selectedReportNumber.trim();
          if (reportNo.isNotEmpty) {
            final fallbackUri = Uri.parse('${baseUrl}well-general/$kControllerWellId')
                .replace(queryParameters: {'reportNo': reportNo});
            final fallbackResponse = await http.get(
              fallbackUri,
              headers: _headers,
            );
            if (fallbackResponse.statusCode == 200) {
              final fallbackJson = jsonDecode(fallbackResponse.body);
              final List fallbackData = fallbackJson['data'] ?? [];
              matched = _findMatchingRecord(fallbackData);
            }
          }
        }

        if (matched == null &&
            reportContext.selectedReportId.value.isNotEmpty) {
          final fallbackResponse = await http.get(
            Uri.parse('${baseUrl}well-general/$kControllerWellId'),
            headers: _headers,
          );
          if (fallbackResponse.statusCode == 200) {
            final fallbackJson = jsonDecode(fallbackResponse.body);
            final List fallbackData = fallbackJson['data'] ?? [];
            matched = _findMatchingRecord(fallbackData);
          }
        }

        if (matched != null) {
          _fromJson(matched);
        } else if (savedId.value.isEmpty && md.value.isEmpty) {
          _clearFields();
        }
        _applySelectedReportMetadata();
      } else {
        if (savedId.value.isEmpty && md.value.isEmpty) {
          _clearFields();
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

  // SAVE (create or update)
  Future<Map<String, dynamic>> save() async {
    if (kControllerWellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    isSaving.value = true;
    try {
      final authRepo = AuthRepository();

      final payload = _toJson();
      payload['wellId'] = kControllerWellId;

      final result = await authRepo.saveWellGeneral(payload);

      if (result['success'] == true) {
        final data = result['data']?['data'];
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
