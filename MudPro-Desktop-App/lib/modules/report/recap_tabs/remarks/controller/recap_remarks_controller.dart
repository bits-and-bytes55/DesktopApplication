import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class RecapRemarksController extends GetxController {
  final PadWellController _padWellController;
  final ReportContextController _reportContext;

  RecapRemarksController({
    PadWellController? padWellController,
    ReportContextController? reportContextController,
  }) : _padWellController = padWellController ?? padWellContext,
       _reportContext = reportContextController ?? reportContext;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emptyMessage = ''.obs;
  final rows = <RemarksHistoryRow>[].obs;
  final manualKeywords = <RemarksKeywordRow>[].obs;
  final automaticKeywords = <RemarksKeywordRow>[].obs;
  final nlpKeywords = <RemarksKeywordRow>[].obs;

  Worker? _wellWorker;
  Worker? _reportsWorker;
  Worker? _reportLoadingWorker;

  static final RegExp _wordPattern = RegExp(
    r"[A-Za-z0-9]+(?:[./'-][A-Za-z0-9]+)*",
  );

  static const Set<String> _stopWords = {
    'a',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'been',
    'but',
    'by',
    'for',
    'from',
    'had',
    'has',
    'have',
    'he',
    'her',
    'his',
    'in',
    'into',
    'is',
    'it',
    'its',
    'no',
    'not',
    'of',
    'on',
    'or',
    'our',
    'she',
    'than',
    'that',
    'the',
    'their',
    'there',
    'these',
    'they',
    'this',
    'to',
    'was',
    'were',
    'will',
    'with',
    'without',
    'you',
    'your',
  };

  @override
  void onInit() {
    super.onInit();
    _wellWorker = ever<String>(_padWellController.selectedWellId, (_) => load());
    _reportsWorker = ever<List<AppReport>>(_reportContext.reports, (_) => load());
    _reportLoadingWorker = ever<bool>(_reportContext.isLoading, (_) => load());
    load();
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    _reportsWorker?.dispose();
    _reportLoadingWorker?.dispose();
    super.onClose();
  }

  String get selectedReportId => _reportContext.selectedReportId.value.trim();

  Future<void> load() async {
    errorMessage.value = '';
    emptyMessage.value = '';

    try {
      final wellId = currentBackendWellId.trim();
      final reportSnapshot = _reportContext.reports.toList(growable: false);
      final reportLoading = _reportContext.isLoading.value;

      if (wellId.isEmpty) {
        isLoading.value = false;
        rows.clear();
        manualKeywords.clear();
        automaticKeywords.clear();
        nlpKeywords.clear();
        emptyMessage.value = 'Select a well first to open Remarks recap.';
        return;
      }

      if (reportLoading && reportSnapshot.isEmpty) {
        isLoading.value = true;
        return;
      }

      isLoading.value = false;

      if (reportSnapshot.isEmpty) {
        rows.clear();
        manualKeywords.clear();
        automaticKeywords.clear();
        nlpKeywords.clear();
        emptyMessage.value = 'No reports are available for the selected well.';
        return;
      }

      final ordered = [...reportSnapshot]..sort(_compareReportsOldestFirst);
      final historyRows = ordered
          .map((report) => _buildHistoryRow(report))
          .toList(growable: false);

      rows.assignAll(historyRows);
      manualKeywords.assignAll(_buildManualKeywords(historyRows));
      automaticKeywords.assignAll(_buildAutomaticKeywords(historyRows));
      nlpKeywords.assignAll(_buildNlpKeywords(historyRows));

      if (!historyRows.any((row) => row.hasAnyContent)) {
        emptyMessage.value =
            'Report history is available, but all remarks fields are empty.';
      }
    } catch (error) {
      isLoading.value = false;
      rows.clear();
      manualKeywords.clear();
      automaticKeywords.clear();
      nlpKeywords.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    }
  }

  RemarksHistoryRow _buildHistoryRow(AppReport report) {
    final recommended = report.recommendedTreatment.trim();
    final remarks = report.remarks.trim();
    final recap = report.recapRemarks.trim();
    final internal = report.internalNotes.trim();

    return RemarksHistoryRow(
      reportId: report.id,
      reportLabel: _reportLabel(report),
      reportDate: report.reportDate.trim(),
      createdAt: report.createdAt.trim(),
      recommendedTreatment: recommended,
      remarks: remarks,
      recapRemarks: recap,
      internalNotes: internal,
      recommendedWordCount: _countWords(recommended),
      remarksWordCount: _countWords(remarks),
      recapWordCount: _countWords(recap),
      internalWordCount: _countWords(internal),
    );
  }

  List<RemarksKeywordRow> _buildManualKeywords(List<RemarksHistoryRow> history) {
    final byKey = <String, _KeywordAccumulator>{};

    for (final row in history) {
      _accumulateKeywords(
        byKey,
        row: row,
        source: 'Recommended',
        text: row.recommendedTreatment,
        tokenizer: _manualTokens,
      );
      _accumulateKeywords(
        byKey,
        row: row,
        source: 'Remarks',
        text: row.remarks,
        tokenizer: _manualTokens,
      );
      _accumulateKeywords(
        byKey,
        row: row,
        source: 'Recap',
        text: row.recapRemarks,
        tokenizer: _manualTokens,
      );
      _accumulateKeywords(
        byKey,
        row: row,
        source: 'Internal',
        text: row.internalNotes,
        tokenizer: _manualTokens,
      );
    }

    return _finalizeKeywordRows(byKey, limit: 80);
  }

  List<RemarksKeywordRow> _buildAutomaticKeywords(
    List<RemarksHistoryRow> history,
  ) {
    final byKey = <String, _KeywordAccumulator>{};

    for (final row in history) {
      _accumulateKeywords(
        byKey,
        row: row,
        source: 'Recommended',
        text: row.recommendedTreatment,
        tokenizer: _automaticTokens,
      );
      _accumulateKeywords(
        byKey,
        row: row,
        source: 'Remarks',
        text: row.remarks,
        tokenizer: _automaticTokens,
      );
      _accumulateKeywords(
        byKey,
        row: row,
        source: 'Recap',
        text: row.recapRemarks,
        tokenizer: _automaticTokens,
      );
      _accumulateKeywords(
        byKey,
        row: row,
        source: 'Internal',
        text: row.internalNotes,
        tokenizer: _automaticTokens,
      );
    }

    return _finalizeKeywordRows(byKey, limit: 80);
  }

  List<RemarksKeywordRow> _buildNlpKeywords(List<RemarksHistoryRow> history) {
    final byKey = <String, _KeywordAccumulator>{};

    for (final row in history) {
      _accumulatePhrases(
        byKey,
        row: row,
        source: 'Recommended',
        text: row.recommendedTreatment,
      );
      _accumulatePhrases(
        byKey,
        row: row,
        source: 'Remarks',
        text: row.remarks,
      );
      _accumulatePhrases(
        byKey,
        row: row,
        source: 'Recap',
        text: row.recapRemarks,
      );
      _accumulatePhrases(
        byKey,
        row: row,
        source: 'Internal',
        text: row.internalNotes,
      );
    }

    return _finalizeKeywordRows(byKey, limit: 60);
  }

  void _accumulateKeywords(
    Map<String, _KeywordAccumulator> byKey, {
    required RemarksHistoryRow row,
    required String source,
    required String text,
    required List<_KeywordToken> Function(String text) tokenizer,
  }) {
    for (final token in tokenizer(text)) {
      final key = token.key.trim();
      if (key.isEmpty) continue;

      final item = byKey.putIfAbsent(
        key,
        () => _KeywordAccumulator(display: token.display),
      );
      item.display = item.display.trim().isEmpty ? token.display : item.display;
      item.count += 1;
      item.reportIds.add(row.reportId);
      item.sources.add(source);
      item.example ??= _buildExample(row, source, text);
    }
  }

  void _accumulatePhrases(
    Map<String, _KeywordAccumulator> byKey, {
    required RemarksHistoryRow row,
    required String source,
    required String text,
  }) {
    final tokens = _automaticTokens(text);
    if (tokens.length < 2) return;

    final seenInRow = <String>{};
    for (int index = 0; index < tokens.length - 1; index++) {
      final bigram =
          '${tokens[index].display.toLowerCase()} ${tokens[index + 1].display.toLowerCase()}';
      seenInRow.add(bigram);
    }
    for (int index = 0; index < tokens.length - 2; index++) {
      final trigram =
          '${tokens[index].display.toLowerCase()} ${tokens[index + 1].display.toLowerCase()} ${tokens[index + 2].display.toLowerCase()}';
      seenInRow.add(trigram);
    }

    for (final phrase in seenInRow) {
      final item = byKey.putIfAbsent(
        phrase,
        () => _KeywordAccumulator(display: phrase),
      );
      item.count += 1;
      item.reportIds.add(row.reportId);
      item.sources.add(source);
      item.example ??= _buildExample(row, source, text);
    }
  }

  List<RemarksKeywordRow> _finalizeKeywordRows(
    Map<String, _KeywordAccumulator> byKey, {
    required int limit,
  }) {
    final rows = byKey.entries
        .where((entry) => entry.value.count > 0)
        .map(
          (entry) => RemarksKeywordRow(
            keyword: entry.value.display,
            occurrences: entry.value.count,
            reportsCount: entry.value.reportIds.length,
            sources: entry.value.sources.toList()..sort(),
            example: entry.value.example ?? '',
          ),
        )
        .toList()
      ..sort((left, right) {
        final byCount = right.occurrences.compareTo(left.occurrences);
        if (byCount != 0) return byCount;
        final byReports = right.reportsCount.compareTo(left.reportsCount);
        if (byReports != 0) return byReports;
        return left.keyword.toLowerCase().compareTo(right.keyword.toLowerCase());
      });

    if (rows.length <= limit) return rows;
    return rows.take(limit).toList(growable: false);
  }

  List<_KeywordToken> _manualTokens(String text) {
    return _wordPattern
        .allMatches(text)
        .map((match) => match.group(0)?.trim() ?? '')
        .where((token) => token.length >= 2)
        .map((token) => _KeywordToken(key: token.toLowerCase(), display: token))
        .toList(growable: false);
  }

  List<_KeywordToken> _automaticTokens(String text) {
    return _wordPattern
        .allMatches(text)
        .map((match) => match.group(0)?.trim() ?? '')
        .map((token) => token.toLowerCase())
        .where((token) => token.length >= 3)
        .where((token) => !_stopWords.contains(token))
        .where((token) => RegExp(r'[a-z]').hasMatch(token))
        .map((token) => _KeywordToken(key: token, display: token))
        .toList(growable: false);
  }

  int _countWords(String text) => _wordPattern.allMatches(text).length;

  String _reportLabel(AppReport report) {
    if (report.userReportNo.trim().isNotEmpty) return report.userReportNo.trim();
    if (report.reportNo.trim().isNotEmpty) return report.reportNo.trim();
    return '-';
  }

  String _buildExample(RemarksHistoryRow row, String source, String text) {
    final snippet = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (snippet.isEmpty) return '';
    final shortened = snippet.length > 80 ? '${snippet.substring(0, 80)}...' : snippet;
    return 'Rpt ${row.reportLabel} [$source] $shortened';
  }
}

class RemarksHistoryRow {
  final String reportId;
  final String reportLabel;
  final String reportDate;
  final String createdAt;
  final String recommendedTreatment;
  final String remarks;
  final String recapRemarks;
  final String internalNotes;
  final int recommendedWordCount;
  final int remarksWordCount;
  final int recapWordCount;
  final int internalWordCount;

  const RemarksHistoryRow({
    required this.reportId,
    required this.reportLabel,
    required this.reportDate,
    required this.createdAt,
    required this.recommendedTreatment,
    required this.remarks,
    required this.recapRemarks,
    required this.internalNotes,
    required this.recommendedWordCount,
    required this.remarksWordCount,
    required this.recapWordCount,
    required this.internalWordCount,
  });

  int get totalWordCount =>
      recommendedWordCount + remarksWordCount + recapWordCount + internalWordCount;

  bool get hasAnyContent =>
      recommendedTreatment.isNotEmpty ||
      remarks.isNotEmpty ||
      recapRemarks.isNotEmpty ||
      internalNotes.isNotEmpty;

  String get preview {
    for (final value in [
      recommendedTreatment,
      remarks,
      recapRemarks,
      internalNotes,
    ]) {
      final text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) {
        return text.length > 110 ? '${text.substring(0, 110)}...' : text;
      }
    }
    return '-';
  }
}

class RemarksKeywordRow {
  final String keyword;
  final int occurrences;
  final int reportsCount;
  final List<String> sources;
  final String example;

  const RemarksKeywordRow({
    required this.keyword,
    required this.occurrences,
    required this.reportsCount,
    required this.sources,
    required this.example,
  });
}

class _KeywordAccumulator {
  String display;
  int count;
  final Set<String> reportIds;
  final Set<String> sources;
  String? example;

  _KeywordAccumulator({
    required this.display,
  }) : count = 0,
       reportIds = <String>{},
       sources = <String>{};
}

class _KeywordToken {
  final String key;
  final String display;

  const _KeywordToken({
    required this.key,
    required this.display,
  });
}

int _compareReportsOldestFirst(AppReport left, AppReport right) {
  final leftDate = _parseDate(left.reportDate, left.createdAt);
  final rightDate = _parseDate(right.reportDate, right.createdAt);

  if (leftDate != null && rightDate != null) {
    final compare = leftDate.compareTo(rightDate);
    if (compare != 0) return compare;
  } else if (leftDate != null) {
    return -1;
  } else if (rightDate != null) {
    return 1;
  }

  final leftNo = int.tryParse(left.userReportNo.trim().isNotEmpty
      ? left.userReportNo.trim()
      : left.reportNo.trim());
  final rightNo = int.tryParse(right.userReportNo.trim().isNotEmpty
      ? right.userReportNo.trim()
      : right.reportNo.trim());

  if (leftNo != null && rightNo != null && leftNo != rightNo) {
    return leftNo.compareTo(rightNo);
  }

  return left.displayName.toLowerCase().compareTo(right.displayName.toLowerCase());
}

DateTime? _parseDate(String rawDate, String createdAt) {
  for (final raw in [rawDate.trim(), createdAt.trim()]) {
    if (raw.isEmpty) continue;

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;

    final parts = raw.split('/');
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
