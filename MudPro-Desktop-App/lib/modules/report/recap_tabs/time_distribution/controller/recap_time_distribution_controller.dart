import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_api_service.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapTimeDistributionController extends GetxController {
  final ReportApiService _reportApi;
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapTimeDistributionController({
    ReportApiService? reportApi,
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _reportApi = reportApi ?? ReportApiService(),
       _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  static Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

  static const List<Color> _palette = [
    Color(0xFF8CBBD0),
    Color(0xFFB7D9A8),
    Color(0xFFF1C27D),
    Color(0xFFD9A6C3),
    Color(0xFF9FC5E8),
    Color(0xFFC4B2DE),
    Color(0xFF7FD0C3),
    Color(0xFFE7A977),
    Color(0xFFA7B8E8),
    Color(0xFF94C48F),
  ];

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <TimeDistributionHistoryRow>[].obs;
  final activities = <TimeDistributionActivityMeta>[].obs;

  Worker? _wellWorker;
  Worker? _reportWorker;

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(_padWellController.selectedWellId, (_) => load());
    _reportWorker = ever<String>(_reportContext.selectedReportId, (_) => load());
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
      activities.clear();
      emptyMessage.value = 'Select a well first to open Time Distribution recap.';
      return;
    }

    isLoading.value = true;

    try {
      final summaries = await _reportApi.fetchReportManagerRows(wellId);
      if (summaries.isEmpty) {
        rows.clear();
        activities.clear();
        emptyMessage.value = 'No reports are available for the selected well.';
        return;
      }

      final ordered = [...summaries]..sort(_compareRowsOldestFirst);
      final wellGeneralRows = await _fetchWellGeneralRows(wellId);

      final byReportId = _pickLatestByKey(
        wellGeneralRows,
        (item) => _text(item['reportId']),
      );
      final byReportNo = _pickLatestByKey(
        wellGeneralRows,
        (item) => _text(item['reportNo']),
      );
      final byUserReportNo = _pickLatestByKey(
        wellGeneralRows,
        (item) => _text(item['userReportNo']),
      );
      final byDate = _pickLatestByKey(
        wellGeneralRows,
        (item) => _text(item['date']),
      );

      final historyRows = ordered.map((summary) {
        final matched =
            byReportId[summary.reportId] ??
            byUserReportNo[summary.userReportNo] ??
            byReportNo[summary.reportNo] ??
            byDate[summary.reportDate];

        final rawEntries = _normalizeEntries(matched?['timeDistributionRows']);
        final totalHours = _round2(
          rawEntries.fold<double>(0, (sum, item) => sum + item.hours),
        );
        final denominator = totalHours > 24 ? totalHours : 24.0;
        final entries = rawEntries
            .map(
              (item) => TimeDistributionEntry(
                key: item.key,
                activity: item.activity,
                hours: item.hours,
                percent: denominator <= 0
                    ? 0
                    : _round2((item.hours / denominator) * 100),
              ),
            )
            .toList(growable: false);

        return TimeDistributionHistoryRow(
          reportId: summary.reportId,
          reportLabel: summary.reportLabel,
          reportDate: summary.reportDate,
          createdAt: summary.createdAt,
          md: summary.md,
          entries: entries,
          totalHours: totalHours,
          totalPercent: denominator <= 0
              ? 0
              : _round2((totalHours / denominator) * 100),
        );
      }).toList(growable: false);

      rows.assignAll(historyRows);

      final catalog = _buildCatalog(historyRows);
      activities.assignAll(catalog);

      if (catalog.isEmpty) {
        emptyMessage.value =
            'No saved time-distribution history is available for the selected well.';
      }
    } catch (error) {
      rows.clear();
      activities.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWellGeneralRows(String wellId) async {
    final failures = <String>[];

    for (final baseUrl in _candidateBaseUrls) {
      final uri = Uri.parse('${baseUrl}well-general/$wellId');

      try {
        final response = await http
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 20));
        final decoded = _decodeObject(
          body: response.body,
          uri: uri,
          contentType: response.headers['content-type'],
        );

        if (response.statusCode == 200 && decoded['success'] == true) {
          return _extractList(decoded['data']);
        }

        failures.add(
          '${uri.origin}: ${decoded['message'] ?? 'Failed to load time distribution history'}',
        );
      } on TimeoutException {
        failures.add('${uri.origin}: request timed out');
      } on FormatException catch (error) {
        failures.add('${uri.origin}: ${error.message}');
      } catch (error) {
        failures.add('${uri.origin}: ${_cleanError(error)}');
      }
    }

    throw Exception(
      'Time Distribution recap backend routes are not available. '
      'Tried: ${failures.join(' | ')}',
    );
  }

  List<_RawTimeDistributionEntry> _normalizeEntries(dynamic rawRows) {
    final byKey = <String, _RawTimeDistributionEntry>{};

    if (rawRows is List) {
      for (final raw in rawRows.whereType<Map>()) {
        final item = Map<String, dynamic>.from(raw);
        final activity =
            _text(item['description']).isNotEmpty
            ? _text(item['description'])
            : _text(item['activity']);
        final hours = _number(item['hours'] ?? item['time']);

        if (activity.isEmpty && hours <= 0) {
          continue;
        }

        final label = activity.isEmpty ? 'Unspecified' : activity;
        final key = label.toLowerCase();
        final existing = byKey[key];

        if (existing == null) {
          byKey[key] = _RawTimeDistributionEntry(
            key: key,
            activity: label,
            hours: hours,
          );
        } else {
          byKey[key] = _RawTimeDistributionEntry(
            key: key,
            activity: label,
            hours: _round2(existing.hours + hours),
          );
        }
      }
    }

    final list = byKey.values.toList()
      ..sort((left, right) {
        final byHours = right.hours.compareTo(left.hours);
        if (byHours != 0) return byHours;
        return left.activity.toLowerCase().compareTo(
          right.activity.toLowerCase(),
        );
      });
    return list;
  }

  List<TimeDistributionActivityMeta> _buildCatalog(
    List<TimeDistributionHistoryRow> historyRows,
  ) {
    final totalsByKey = <String, double>{};
    final nameByKey = <String, String>{};

    for (final row in historyRows) {
      for (final entry in row.entries) {
        totalsByKey[entry.key] = _round2(
          (totalsByKey[entry.key] ?? 0) + entry.hours,
        );
        nameByKey[entry.key] = entry.activity;
      }
    }

    final sortedKeys = totalsByKey.keys.toList()
      ..sort((left, right) {
        final byTotal = (totalsByKey[right] ?? 0).compareTo(
          totalsByKey[left] ?? 0,
        );
        if (byTotal != 0) return byTotal;
        return (nameByKey[left] ?? '').toLowerCase().compareTo(
          (nameByKey[right] ?? '').toLowerCase(),
        );
      });

    return List<TimeDistributionActivityMeta>.generate(sortedKeys.length, (
      index,
    ) {
      final key = sortedKeys[index];
      return TimeDistributionActivityMeta(
        key: key,
        activity: nameByKey[key] ?? key,
        totalHours: totalsByKey[key] ?? 0,
        color: _palette[index % _palette.length],
      );
    });
  }

  Map<String, Map<String, dynamic>> _pickLatestByKey(
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic> item) keySelector,
  ) {
    final latest = <String, Map<String, dynamic>>{};
    for (final item in items) {
      final key = keySelector(item).trim();
      if (key.isEmpty || latest.containsKey(key)) continue;
      latest[key] = item;
    }
    return latest;
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
    final isJson =
        (contentType ?? '').toLowerCase().contains('application/json');
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

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final envelope = _asMap(raw);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

class TimeDistributionHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final double md;
  final List<TimeDistributionEntry> entries;
  final double totalHours;
  final double totalPercent;

  const TimeDistributionHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.md,
    required this.entries,
    required this.totalHours,
    required this.totalPercent,
  });

  TimeDistributionEntry? entryFor(String key) {
    if (key.trim().isEmpty) return null;
    for (final entry in entries) {
      if (entry.key == key) return entry;
    }
    return null;
  }
}

class TimeDistributionEntry {
  final String key;
  final String activity;
  final double hours;
  final double percent;

  const TimeDistributionEntry({
    required this.key,
    required this.activity,
    required this.hours,
    required this.percent,
  });
}

class TimeDistributionActivityMeta {
  final String key;
  final String activity;
  final double totalHours;
  final Color color;

  const TimeDistributionActivityMeta({
    required this.key,
    required this.activity,
    required this.totalHours,
    required this.color,
  });
}

class _RawTimeDistributionEntry {
  final String key;
  final String activity;
  final double hours;

  const _RawTimeDistributionEntry({
    required this.key,
    required this.activity,
    required this.hours,
  });
}

String _text(dynamic value) => value?.toString().trim() ?? '';

double _number(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0.0;
}

double _round2(double value) => double.parse(value.toStringAsFixed(2));

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

    final parts = value.split('/');
    if (parts.length == 3) {
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (month != null && day != null && year != null) {
        return DateTime(year, month, day);
      }
    }
  }
  return null;
}
