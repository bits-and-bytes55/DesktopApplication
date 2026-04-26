import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapEngineerController extends GetxController {
  RecapEngineerController({
    ReportApiService? reportApi,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _reportApi = reportApi ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <RecapEngineerRow>[].obs;

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
      emptyMessage.value = 'Select a well first to open Engineer recap.';
      return;
    }

    isLoading.value = true;

    try {
      final summaries = await _reportApi.fetchReportManagerRows(wellId);
      if (summaries.isEmpty) {
        rows.clear();
        emptyMessage.value = 'No reports are available for the selected well.';
        return;
      }

      final ordered = [...summaries]..sort(_compareRowsOldestFirst);

      List<Map<String, dynamic>> wellGeneralRows;
      try {
        wellGeneralRows = await _fetchWellGeneralRows(wellId);
      } catch (_) {
        wellGeneralRows = const <Map<String, dynamic>>[];
      }

      List<Engineer> engineers;
      try {
        engineers = await _fetchEngineers();
      } catch (_) {
        engineers = const <Engineer>[];
      }

      final byReportId = _pickLatestByKey(
        wellGeneralRows,
        (row) => _text(row['reportId']),
      );
      final byReportNo = _pickLatestByKey(
        wellGeneralRows,
        (row) => _text(row['reportNo']),
      );
      final byUserReportNo = _pickLatestByKey(
        wellGeneralRows,
        (row) => _text(row['userReportNo']),
      );

      final engineerByName = <String, Engineer>{};
      for (final engineer in engineers) {
        final fullName = _normalizeName(
          _fullName(engineer.firstName, engineer.lastName),
        );
        if (fullName.isEmpty || engineerByName.containsKey(fullName)) continue;
        engineerByName[fullName] = engineer;
      }

      final aggregates = <String, _EngineerAccumulator>{};
      for (int index = 0; index < ordered.length; index++) {
        final summary = ordered[index];
        final reportKey = summary.reportId.isNotEmpty
            ? summary.reportId
            : '${summary.reportLabel}_${summary.reportDate}_$index';
        final matched =
            byReportId[summary.reportId] ??
            byReportNo[summary.reportNo] ??
            byUserReportNo[summary.userReportNo] ??
            _matchByDate(wellGeneralRows, summary);

        final assignedNames = _uniqueNames([
          _text(matched?['engineer']),
          _text(matched?['engineer2']),
          summary.engineer,
          summary.engineer2,
        ]);

        for (final assignedName in assignedNames) {
          final normalized = _normalizeName(assignedName);
          if (normalized.isEmpty) continue;

          final accumulator = aggregates.putIfAbsent(normalized, () {
            final matchedEngineer = engineerByName[normalized];
            final split = _splitName(
              matchedEngineer == null
                  ? assignedName
                  : _fullName(
                      matchedEngineer.firstName,
                      matchedEngineer.lastName,
                    ),
            );
            return _EngineerAccumulator(
              firstName: matchedEngineer?.firstName ?? split.$1,
              lastName: matchedEngineer?.lastName ?? split.$2,
              cell: matchedEngineer?.cell ?? '',
              office: matchedEngineer?.office ?? '',
              email: matchedEngineer?.email ?? '',
              photo: matchedEngineer?.photo ?? '',
            );
          });
          accumulator.reportIds.add(reportKey);
        }
      }

      final totalReports = ordered.length;
      final built =
          aggregates.values
              .map((item) {
                final days = item.reportIds.length;
                final percentage = totalReports == 0
                    ? 0.0
                    : (days / totalReports) * 100;
                return RecapEngineerRow(
                  firstName: item.firstName,
                  lastName: item.lastName,
                  cell: item.cell,
                  office: item.office,
                  email: item.email,
                  photo: item.photo,
                  days: days,
                  percentage: percentage,
                );
              })
              .toList(growable: false)
            ..sort((left, right) {
              final dayCompare = right.days.compareTo(left.days);
              if (dayCompare != 0) return dayCompare;
              final nameCompare = left.firstName.toLowerCase().compareTo(
                right.firstName.toLowerCase(),
              );
              if (nameCompare != 0) return nameCompare;
              return left.lastName.toLowerCase().compareTo(
                right.lastName.toLowerCase(),
              );
            });

      rows.assignAll(built);
      if (built.isEmpty) {
        emptyMessage.value = 'No engineer assignments are available yet.';
      }
    } catch (error) {
      rows.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWellGeneralRows(
    String wellId,
  ) async {
    final decoded = await _getObject(path: 'well-general/$wellId');
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<List<Engineer>> _fetchEngineers() async {
    final decoded = await _getObject(path: ApiEndpoint.getEngineersData);
    final data = decoded['data'];
    if (data is! List) return const <Engineer>[];
    return data
        .whereType<Map>()
        .map((item) => Engineer.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getObject({
    required String path,
    Map<String, String>? queryParameters,
  }) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParameters);

      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));
        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode != 200) {
          failures.add(
            '${uri.origin}: ${decoded['message'] ?? 'HTTP ${response.statusCode}'}',
          );
          continue;
        }

        if (decoded['success'] != true) {
          failures.add(
            '${uri.origin}: ${decoded['message'] ?? 'Request failed'}',
          );
          continue;
        }

        return decoded;
      } on TimeoutException {
        failures.add('${uri.origin}: request timed out');
      } on FormatException catch (error) {
        failures.add('${uri.origin}: ${error.message}');
      } catch (error) {
        failures.add('${uri.origin}: ${_cleanError(error)}');
      }
    }

    throw Exception(
      'Engineer recap backend routes are not available. '
      'Tried: ${failures.join(' | ')}',
    );
  }

  Iterable<String> get _candidateBaseUrls sync* {
    final seen = <String>{};
    for (final baseUrl in [ApiEndpoint.baseUrl, 'http://localhost:3000/api/']) {
      final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
      if (seen.add(normalized)) {
        yield normalized;
      }
    }
  }

  Map<String, dynamic> _decodeObject({
    required String body,
    required Uri uri,
    String? contentType,
  }) {
    final trimmed = body.trim();
    final isJson = (contentType ?? '').toLowerCase().contains(
      'application/json',
    );
    if (!isJson &&
        (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html'))) {
      throw FormatException(
        'HTML error page returned from ${uri.origin}. Expected JSON response.',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw FormatException('Unexpected response format from ${uri.origin}');
  }

  Map<String, Map<String, dynamic>> _pickLatestByKey(
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic> item) keyFor,
  ) {
    final ordered = [...items]
      ..sort((left, right) {
        final leftTime = _timestampOf(left);
        final rightTime = _timestampOf(right);
        return rightTime.compareTo(leftTime);
      });

    final output = <String, Map<String, dynamic>>{};
    for (final item in ordered) {
      final key = keyFor(item);
      if (key.isEmpty || output.containsKey(key)) continue;
      output[key] = item;
    }
    return output;
  }

  Map<String, dynamic>? _matchByDate(
    List<Map<String, dynamic>> candidates,
    ReportManagerRow summary,
  ) {
    final targetDate =
        _parseDate(summary.reportDate) ?? _parseDate(summary.createdAt);
    if (targetDate == null) return null;

    for (final candidate in candidates) {
      final candidateDate =
          _parseDate(_text(candidate['date'])) ??
          _parseDate(_text(candidate['createdAt']));
      if (candidateDate == null) continue;
      if (_sameDay(candidateDate, targetDate)) {
        return candidate;
      }
    }
    return null;
  }

  int _timestampOf(Map<String, dynamic> item) {
    for (final value in [
      item['updatedAt'],
      item['createdAt'],
      item['date'],
      item['reportDate'],
    ]) {
      final parsed = _parseDate(_text(value));
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    return 0;
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  bool _sameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class RecapEngineerRow {
  final String firstName;
  final String lastName;
  final String cell;
  final String office;
  final String email;
  final String photo;
  final int days;
  final double percentage;

  const RecapEngineerRow({
    required this.firstName,
    required this.lastName,
    required this.cell,
    required this.office,
    required this.email,
    required this.photo,
    required this.days,
    required this.percentage,
  });
}

class _EngineerAccumulator {
  final String firstName;
  final String lastName;
  final String cell;
  final String office;
  final String email;
  final String photo;
  final Set<String> reportIds = <String>{};

  _EngineerAccumulator({
    required this.firstName,
    required this.lastName,
    required this.cell,
    required this.office,
    required this.email,
    required this.photo,
  });
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String _normalizeName(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

String _fullName(String firstName, String lastName) => [
  firstName.trim(),
  lastName.trim(),
].where((value) => value.isNotEmpty).join(' ');

List<String> _uniqueNames(List<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value
      in values.map((item) => item.trim()).where((item) => item.isNotEmpty)) {
    final normalized = _normalizeName(value);
    if (!seen.add(normalized)) continue;
    result.add(value);
  }
  return result;
}

(String, String) _splitName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .toList();
  if (parts.isEmpty) return ('', '');
  if (parts.length == 1) return (parts.first, '');
  return (parts.first, parts.sublist(1).join(' '));
}

int _compareRowsOldestFirst(ReportManagerRow left, ReportManagerRow right) {
  final leftDate = _parseReportDate(left);
  final rightDate = _parseReportDate(right);

  if (leftDate != null && rightDate != null) {
    final compare = leftDate.compareTo(rightDate);
    if (compare != 0) return compare;
  } else if (leftDate != null) {
    return -1;
  } else if (rightDate != null) {
    return 1;
  }

  final leftNo = int.tryParse(left.reportLabel);
  final rightNo = int.tryParse(right.reportLabel);
  if (leftNo != null && rightNo != null) {
    return leftNo.compareTo(rightNo);
  }
  return left.reportLabel.toLowerCase().compareTo(
    right.reportLabel.toLowerCase(),
  );
}

DateTime? _parseReportDate(ReportManagerRow row) {
  for (final value in [row.reportDate, row.createdAt]) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return null;
}
