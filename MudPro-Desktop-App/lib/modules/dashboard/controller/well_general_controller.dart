import 'dart:async';
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
  static const int _minTimeDistributionRows = 8;
  static const int _minOpenHoleRows = 3;

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
  var bitMft = ''.obs;
  var bitType = ''.obs;
  var bitSize = ''.obs;
  var bitCount = ''.obs;
  var bitDepthIn = ''.obs;
  var bitDepth = ''.obs;
  var additionalFootage = ''.obs;
  var nptTime = ''.obs;
  var nptCost = ''.obs;
  var depthDrilled = ''.obs;
  final cementPlugEnabled = false.obs;
  var cementPlugVolume = ''.obs;
  var cementPlugTop = ''.obs;
  final timeDistributionRows = <Map<String, String>>[].obs;
  final timeDistributionRevision = 0.obs;
  final openHoleRows = <Map<String, String>>[].obs;
  final openHoleRevision = 0.obs;
  Worker? _wellWorker;
  Worker? _reportWorker;
  final List<Worker> _autoSaveWorkers = <Worker>[];
  Timer? _autoSaveTimer;
  Timer? _depthDrilledTimer;
  int _depthDrilledGeneration = 0;
  bool _isApplyingState = false;

  List<RxString> get _autoSaveFields => [
    reportNo,
    userReportNo,
    date,
    time,
    engineer,
    engineer2,
    operatorRep,
    contractorRep,
    activity,
    md,
    tvd,
    inc,
    azi,
    wob,
    rotWt,
    soWt,
    puWt,
    rpm,
    rop,
    offBottomTq,
    onBottomTq,
    suctionT,
    bottomT,
    interval,
    fit,
    formation,
    bitMft,
    bitType,
    bitSize,
    bitCount,
    bitDepthIn,
    bitDepth,
    additionalFootage,
    nptTime,
    nptCost,
    depthDrilled,
    cementPlugVolume,
    cementPlugTop,
  ];

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
    for (final field in _autoSaveFields) {
      _autoSaveWorkers.add(ever<String>(field, (_) => _scheduleAutoSave()));
    }
    _autoSaveWorkers.add(
      ever<bool>(cementPlugEnabled, (_) => _scheduleAutoSave()),
    );
    _autoSaveWorkers.add(
      ever<int>(timeDistributionRevision, (_) => _scheduleAutoSave()),
    );
    _autoSaveWorkers.add(
      ever<int>(openHoleRevision, (_) => _scheduleAutoSave()),
    );
    _autoSaveWorkers.add(
      ever<String>(md, (_) => _scheduleDepthDrilledRefresh()),
    );
    _autoSaveWorkers.add(
      ever<String>(md, (value) => _syncOpenHoleMdFromGeneral(value)),
    );
    fetchLatest();
  }

  @override
  void onClose() {
    _autoSaveTimer?.cancel();
    _depthDrilledTimer?.cancel();
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    for (final worker in _autoSaveWorkers) {
      worker.dispose();
    }
    super.onClose();
  }

  bool get _hasMeaningfulData {
    return savedId.value.isNotEmpty ||
        _autoSaveFields.any((field) => field.value.trim().isNotEmpty) ||
        cementPlugEnabled.value ||
        _serializeTimeDistributionRows().isNotEmpty ||
        _serializeOpenHoleRows().isNotEmpty;
  }

  void _scheduleAutoSave() {
    if (_isApplyingState || isLoading.value || !_hasMeaningfulData) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 850), () async {
      if (_isApplyingState || isLoading.value || !_hasMeaningfulData) return;
      if (isSaving.value) {
        _scheduleAutoSave();
        return;
      }
      await save();
    });
  }

  void _scheduleDepthDrilledRefresh({bool notifySave = true}) {
    if (_isApplyingState) return;
    _depthDrilledTimer?.cancel();
    _depthDrilledTimer = Timer(const Duration(milliseconds: 250), () async {
      await _refreshDepthDrilled(notifySave: notifySave);
    });
  }

  Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

  Map<String, String> _blankTimeDistributionRow() => {
    'activity': '',
    'time': '',
  };

  Map<String, String> _blankOpenHoleRow() => {
    'description': '',
    'id': '',
    'md': '',
    'washout': '',
  };

  String _formatNumericText(double value) {
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

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
          normalized.add({'activity': activity, 'time': time});
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

  List<Map<String, String>> _normalizeOpenHoleRows(dynamic rawRows) {
    final normalized = <Map<String, String>>[];

    if (rawRows is List) {
      for (final item in rawRows) {
        if (item is Map) {
          normalized.add({
            'description': (item['description'] ?? '').toString().trim(),
            'id': (item['id'] ?? '').toString().trim(),
            'md': (item['md'] ?? '').toString().trim(),
            'washout': (item['washout'] ?? '').toString().trim(),
          });
        }
      }
    }

    while (normalized.length < _minOpenHoleRows) {
      normalized.add(_blankOpenHoleRow());
    }

    return normalized;
  }

  void _setTimeDistributionRows(dynamic rawRows, {bool notify = true}) {
    timeDistributionRows.assignAll(_normalizeTimeDistributionRows(rawRows));
    if (notify) {
      timeDistributionRevision.value++;
    }
  }

  void _setOpenHoleRows(dynamic rawRows, {bool notify = true}) {
    openHoleRows.assignAll(_normalizeOpenHoleRows(rawRows));
    if (notify) {
      openHoleRevision.value++;
    }
  }

  void _syncOpenHoleMdFromGeneral(String value) {
    if (_isApplyingState) return;
    final rows = openHoleRowsForUi;
    while (rows.length < _minOpenHoleRows) {
      rows.add(_blankOpenHoleRow());
    }

    final firstRow = Map<String, String>.from(rows.first);
    final nextMd = value.trim();
    if ((firstRow['md'] ?? '') == nextMd) return;

    firstRow['md'] = nextMd;
    rows[0] = firstRow;
    _setOpenHoleRows(rows);
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

  List<Map<String, String>> get openHoleRowsForUi => openHoleRows
      .map(
        (row) => {
          'description': row['description'] ?? '',
          'id': row['id'] ?? '',
          'md': row['md'] ?? '',
          'washout': row['washout'] ?? '',
        },
      )
      .toList();

  void hydrateOpenHoleRows(dynamic rawRows, {bool notify = true}) {
    final rows = _normalizeOpenHoleRows(rawRows);
    _setOpenHoleRows(rows, notify: notify);
    if (!_isApplyingState && rows.isNotEmpty) {
      final nextMd = (rows.first['md'] ?? '').trim();
      if (md.value != nextMd) {
        md.value = nextMd;
      }
    }
  }

  void updateTimeDistributionRow(
    int index, {
    String? activity,
    String? time,
    bool notify = true,
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
    if (!notify) {
      _scheduleAutoSave();
    }
  }

  void updateOpenHoleRow(
    int index, {
    String? description,
    String? id,
    String? md,
    String? washout,
    bool notify = true,
  }) {
    final rows = openHoleRowsForUi;
    while (rows.length <= index) {
      rows.add(_blankOpenHoleRow());
    }

    final current = Map<String, String>.from(rows[index]);
    if (description != null) {
      current['description'] = description;
    }
    if (id != null) {
      current['id'] = id;
    }
    if (md != null) {
      current['md'] = md;
    }
    if (washout != null) {
      current['washout'] = washout;
    }
    rows[index] = current;
    _setOpenHoleRows(rows, notify: notify);

    if (index == 0 && md != null && this.md.value != md.trim()) {
      this.md.value = md.trim();
    }
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

  List<Map<String, String>> _serializeOpenHoleRows() {
    final serialized = <Map<String, String>>[];

    for (final row in openHoleRows) {
      final description = (row['description'] ?? '').trim();
      final id = (row['id'] ?? '').trim();
      final md = (row['md'] ?? '').trim();
      final washout = (row['washout'] ?? '').trim();
      if (description.isEmpty && id.isEmpty && md.isEmpty && washout.isEmpty) {
        continue;
      }
      serialized.add({
        'description': description,
        'id': id,
        'md': md,
        'washout': washout,
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
    'bitMft': bitMft.value,
    'bitType': bitType.value,
    'bitSize': bitSize.value,
    'bitCount': bitCount.value,
    'bitDepthIn': bitDepthIn.value,
    'bitDepth': bitDepth.value,
    'additionalFootage': double.tryParse(additionalFootage.value) ?? 0,
    'nptTime': double.tryParse(nptTime.value) ?? 0,
    'nptCost': double.tryParse(nptCost.value) ?? 0,
    'depthDrilled': double.tryParse(depthDrilled.value) ?? 0,
    'cementPlugEnabled': cementPlugEnabled.value,
    'cementPlugVolume': cementPlugVolume.value,
    'cementPlugTop': cementPlugTop.value,
    'timeDistributionRows': _serializeTimeDistributionRows(),
    'openHoleRows': _serializeOpenHoleRows(),
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
    bitMft.value = d['bitMft']?.toString() ?? '';
    bitType.value = d['bitType']?.toString() ?? '';
    bitSize.value = d['bitSize']?.toString() ?? '';
    bitCount.value = d['bitCount']?.toString() ?? '';
    bitDepthIn.value = d['bitDepthIn']?.toString() ?? '';
    bitDepth.value = d['bitDepth']?.toString() ?? '';
    additionalFootage.value = (d['additionalFootage'] ?? '').toString();
    nptTime.value = (d['nptTime'] ?? '').toString();
    nptCost.value = (d['nptCost'] ?? '').toString();
    depthDrilled.value = (d['depthDrilled'] ?? '').toString();
    cementPlugEnabled.value = d['cementPlugEnabled'] == true;
    cementPlugVolume.value = d['cementPlugVolume']?.toString() ?? '';
    cementPlugTop.value = d['cementPlugTop']?.toString() ?? '';
    _setTimeDistributionRows(d['timeDistributionRows']);
    _setOpenHoleRows(d['openHoleRows']);
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
    bitMft.value = '';
    bitType.value = '';
    bitSize.value = '';
    bitCount.value = '';
    bitDepthIn.value = '';
    bitDepth.value = '';
    additionalFootage.value = '';
    nptTime.value = '';
    nptCost.value = '';
    depthDrilled.value = '';
    cementPlugEnabled.value = false;
    cementPlugVolume.value = '';
    cementPlugTop.value = '';
    _setTimeDistributionRows(const []);
    _setOpenHoleRows(const []);
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

  Map<String, dynamic>? _findRecordForReport(
    List<dynamic> rawItems, {
    required String reportId,
  }) {
    final items = rawItems
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
    if (items.isEmpty) return null;

    Map<String, dynamic>? firstMatch(bool Function(Map<String, dynamic>) test) {
      for (final item in items) {
        if (test(item)) return item;
      }
      return null;
    }

    if (reportId.isEmpty) return null;
    return firstMatch(
      (item) => (item['reportId']?.toString().trim() ?? '') == reportId,
    );
  }

  dynamic _previousReportForSelected() {
    final selected = reportContext.selectedReport;
    if (selected == null) return null;

    final reports = reportContext.reports.toList(growable: false);
    final currentNo = int.tryParse(selected.reportNo.trim());
    if (currentNo != null) {
      final previousByNumber = reports
          .where((report) {
            if (report.id == selected.id) return false;
            final reportNo = int.tryParse(report.reportNo.trim());
            return reportNo != null && reportNo < currentNo;
          })
          .toList()
        ..sort((a, b) {
          final left = int.tryParse(a.reportNo.trim()) ?? 0;
          final right = int.tryParse(b.reportNo.trim()) ?? 0;
          return right.compareTo(left);
        });
      if (previousByNumber.isNotEmpty) {
        return previousByNumber.first;
      }
    }

    final selectedReportId = reportContext.selectedReportId.value.trim();
    final currentIndex = reports.indexWhere(
      (item) => item.id == selectedReportId,
    );
    if (currentIndex <= 0) return null;
    return reports[currentIndex - 1];
  }

  Future<double?> _loadPreviousReportMd() async {
    final previousReport = _previousReportForSelected();
    if (previousReport == null) return null;

    final response = await http.get(
      Uri.parse(
        '${baseUrl}well-general/$kControllerWellId',
      ).replace(queryParameters: {'reportId': previousReport.id}),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    final List data = decoded['data'] ?? [];
    var matched = _findRecordForReport(
      data,
      reportId: previousReport.id,
    );

    if (matched == null) {
      return null;
    }

    return double.tryParse(
      (matched['md'] ?? '').toString().replaceAll(',', ''),
    );
  }

  Future<void> _refreshDepthDrilled({bool notifySave = true}) async {
    final generation = ++_depthDrilledGeneration;
    final currentMd = double.tryParse(md.value.replaceAll(',', '').trim());

    if (currentMd == null || currentMd <= 0) {
      if (depthDrilled.value.isNotEmpty) {
        depthDrilled.value = '';
        if (notifySave && !_isApplyingState) {
          _scheduleAutoSave();
        }
      }
      return;
    }

    double nextDepth = currentMd;
    try {
      final previousMd = await _loadPreviousReportMd();
      if (generation != _depthDrilledGeneration) return;
      if (previousMd != null) {
        nextDepth = currentMd - previousMd;
      }
    } catch (_) {}

    if (nextDepth < 0) {
      nextDepth = 0;
    }

    final nextText = _formatNumericText(nextDepth);
    if (depthDrilled.value == nextText) return;

    depthDrilled.value = nextText;
    if (notifySave && !_isApplyingState) {
      _scheduleAutoSave();
    }
  }

  Future<void> _syncSelectedReportDate() async {
    final report = reportContext.selectedReport;
    final nextDate = date.value.trim();
    if (report == null ||
        nextDate.isEmpty ||
        report.reportDate.trim() == nextDate) {
      return;
    }

    await reportContext.updateSelectedReport({'reportDate': nextDate});
  }

  Map<String, dynamic>? _findMatchingRecord(List<dynamic> rawItems) {
    final items = rawItems
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
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

    final reportId = report.id.trim();
    if (reportId.isEmpty) return null;
    return firstMatch(
      (item) => (item['reportId']?.toString().trim() ?? '') == reportId,
    );
  }

  // FETCH latest record
  Future<void> fetchLatest() async {
    _autoSaveTimer?.cancel();
    if (kControllerWellId.isEmpty) {
      if (savedId.value.isEmpty && md.value.isEmpty) {
        _isApplyingState = true;
        _clearFields();
        _isApplyingState = false;
      }
      return;
    }
    isLoading.value = true;
    _isApplyingState = true;
    try {
      final primaryUri = Uri.parse('${baseUrl}well-general/$kControllerWellId')
          .replace(
            queryParameters: {
              if (reportContext.selectedReportId.value.isNotEmpty)
                'reportId': reportContext.selectedReportId.value,
            },
          );
      final response = await http.get(primaryUri, headers: _headers);

      print(
        'WellGeneral fetch response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        final matched = _findMatchingRecord(data);

        if (matched != null) {
          _fromJson(matched);
        } else {
          _clearFields();
        }
        _applySelectedReportMetadata();
      } else {
        _clearFields();
        _applySelectedReportMetadata();
      }
    } catch (e) {
      print('WellGeneral fetch error: $e');
      _applySelectedReportMetadata();
    } finally {
      _isApplyingState = false;
      isLoading.value = false;
      await _refreshDepthDrilled(notifySave: false);
    }
  }

  // SAVE (create or update)
  Future<Map<String, dynamic>> save() async {
    _autoSaveTimer?.cancel();
    if (kControllerWellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    await _refreshDepthDrilled(notifySave: false);
    isSaving.value = true;
    try {
      final authRepo = AuthRepository();

      final payload = _toJson();
      payload['wellId'] = kControllerWellId;

      final result = await authRepo.saveWellGeneral(payload);

      if (result['success'] == true) {
        final data = result['data']?['data'];
        if (data is Map) {
          final returnedId = (data['_id'] ?? data['id'])?.toString() ?? '';
          if (returnedId.isNotEmpty && savedId.value != returnedId) {
            savedId.value = returnedId;
          }
        }
        await _syncSelectedReportDate();
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
