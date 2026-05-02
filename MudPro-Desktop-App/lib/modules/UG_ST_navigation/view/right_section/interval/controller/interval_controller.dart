import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

// ════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ════════════════════════════════════════════════════════════════════

/// One interval item (leaf node in the list)
class IntervalItem {
  final String id;
  String name;
  int order;
  String? groupId;

  // General tab — table fields
  String formation = '';
  String bitSize = '';
  String casing = '';
  String intervalFIT = '';
  String mudDescription = '';
  String mudType = '';

  // General tab — text areas
  String intervalSummary = '';
  String solidControl = '';
  String intervalConclusion = '';
  String sweeps = '';
  String labTesting = '';
  String endOfIntervalConclusion = '';

  IntervalItem({
    required this.id,
    required this.name,
    required this.order,
    this.groupId,
    this.formation = '',
    this.bitSize = '',
    this.casing = '',
    this.intervalFIT = '',
    this.mudDescription = '',
    this.mudType = '',
    this.intervalSummary = '',
    this.solidControl = '',
    this.intervalConclusion = '',
    this.sweeps = '',
    this.labTesting = '',
    this.endOfIntervalConclusion = '',
  });

  factory IntervalItem.fromJson(Map<String, dynamic> j) => IntervalItem(
    id: j['_id'] ?? '',
    name: j['name'] ?? 'New Interval',
    order: j['order'] ?? 0,
    groupId: j['groupId']?.toString(),
    formation: j['formation'] ?? '',
    bitSize: j['bitSize'] ?? '',
    casing: j['casing'] ?? '',
    intervalFIT: j['intervalFIT'] ?? '',
    mudDescription: j['mudDescription'] ?? '',
    mudType: j['mudType'] ?? '',
    intervalSummary: j['intervalSummary'] ?? '',
    solidControl: j['solidControl'] ?? '',
    intervalConclusion: j['intervalConclusion'] ?? '',
    sweeps: j['sweeps'] ?? '',
    labTesting: j['labTesting'] ?? '',
    endOfIntervalConclusion: j['endOfIntervalConclusion'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'formation': formation,
    'bitSize': bitSize,
    'casing': casing,
    'intervalFIT': intervalFIT,
    'mudDescription': mudDescription,
    'mudType': mudType,
    'intervalSummary': intervalSummary,
    'solidControl': solidControl,
    'intervalConclusion': intervalConclusion,
    'sweeps': sweeps,
    'labTesting': labTesting,
    'endOfIntervalConclusion': endOfIntervalConclusion,
  };
}

/// A group node that contains multiple IntervalItems
class IntervalGroup {
  final String id;
  String name;
  int order;
  List<String> intervalIds;
  bool collapsed;

  IntervalGroup({
    required this.id,
    required this.name,
    required this.order,
    required this.intervalIds,
    this.collapsed = false,
  });

  factory IntervalGroup.fromJson(Map<String, dynamic> j) => IntervalGroup(
    id: j['_id'] ?? '',
    name: j['name'] ?? 'Group',
    order: j['order'] ?? 0,
    intervalIds: List<String>.from(
      (j['intervalIds'] ?? []).map((e) => e.toString()),
    ),
    collapsed: j['collapsed'] ?? false,
  );
}

/// A union type for the flat list (either a group header or a standalone interval)
class ListNode {
  final bool isGroup;
  final IntervalItem? interval;
  final IntervalGroup? group;

  const ListNode.interval(this.interval) : isGroup = false, group = null;
  const ListNode.group(this.group) : isGroup = true, interval = null;
}

// ════════════════════════════════════════════════════════════════════
//  CONTROLLER
// ════════════════════════════════════════════════════════════════════

class IntervalController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;
  static const Duration _generalSaveDebounce = Duration(milliseconds: 850);

  Map<String, String> get _headers => ApiEndpoint.jsonHeaders;

  // ── Reactive state ───────────────────────────────────────────────
  final RxList<IntervalItem> intervals = <IntervalItem>[].obs;
  final RxList<IntervalGroup> groups = <IntervalGroup>[].obs;
  final Rx<IntervalItem?> selected = Rx<IntervalItem?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString wellId = ''.obs;
  Timer? _generalSaveTimer;
  IntervalItem? _pendingGeneralSave;
  bool _isHydratingControllers = false;

  // TextEditingControllers for the General tab (updated when selection changes)
  final formationCtrl = TextEditingController();
  final bitSizeCtrl = TextEditingController();
  final casingCtrl = TextEditingController();
  final intervalFITCtrl = TextEditingController();
  final mudDescCtrl = TextEditingController();
  final mudTypeCtrl = TextEditingController();
  final intervalSummaryCtrl = TextEditingController();
  final solidControlCtrl = TextEditingController();
  final intervalConclusionCtrl = TextEditingController();
  final sweepsCtrl = TextEditingController();
  final labTestingCtrl = TextEditingController();
  final endOfIntervalCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _attachGeneralAutosaveListeners();
  }

  @override
  void onClose() {
    _generalSaveTimer?.cancel();
    formationCtrl.dispose();
    bitSizeCtrl.dispose();
    casingCtrl.dispose();
    intervalFITCtrl.dispose();
    mudDescCtrl.dispose();
    mudTypeCtrl.dispose();
    intervalSummaryCtrl.dispose();
    solidControlCtrl.dispose();
    intervalConclusionCtrl.dispose();
    sweepsCtrl.dispose();
    labTestingCtrl.dispose();
    endOfIntervalCtrl.dispose();
    super.onClose();
  }

  void _attachGeneralAutosaveListeners() {
    for (final controller in [
      formationCtrl,
      bitSizeCtrl,
      casingCtrl,
      intervalFITCtrl,
      mudDescCtrl,
      mudTypeCtrl,
      intervalSummaryCtrl,
      solidControlCtrl,
      intervalConclusionCtrl,
      sweepsCtrl,
      labTestingCtrl,
      endOfIntervalCtrl,
    ]) {
      controller.addListener(_handleGeneralFieldChanged);
    }
  }

  void _handleGeneralFieldChanged() {
    if (_isHydratingControllers || isLoading.value) return;
    final iv = selected.value;
    if (iv == null) return;

    _syncIntervalFromControllers(iv);
    _pendingGeneralSave = iv;
    _generalSaveTimer?.cancel();
    _generalSaveTimer = Timer(_generalSaveDebounce, () async {
      final pending = _pendingGeneralSave;
      if (pending == null) return;
      if (isSaving.value) {
        _generalSaveTimer = Timer(
          const Duration(milliseconds: 250),
          _handleGeneralFieldChanged,
        );
        return;
      }
      await saveGeneralData(target: pending);
    });
  }

  void _syncIntervalFromControllers(IntervalItem iv) {
    iv.formation = formationCtrl.text;
    iv.bitSize = bitSizeCtrl.text;
    iv.casing = casingCtrl.text;
    iv.intervalFIT = intervalFITCtrl.text;
    iv.mudDescription = mudDescCtrl.text;
    iv.mudType = mudTypeCtrl.text;
    iv.intervalSummary = intervalSummaryCtrl.text;
    iv.solidControl = solidControlCtrl.text;
    iv.intervalConclusion = intervalConclusionCtrl.text;
    iv.sweeps = sweepsCtrl.text;
    iv.labTesting = labTestingCtrl.text;
    iv.endOfIntervalConclusion = endOfIntervalCtrl.text;
    intervals.refresh();
    selected.refresh();
  }

  // ── Computed flat list for the sidebar ──────────────────────────
  /// Returns the merged, ordered list of groups + standalone intervals.
  List<ListNode> get flatList {
    final List<ListNode> result = [];
    final Set<String> grouped = groups.expand((g) => g.intervalIds).toSet();

    // Build a map: order → node
    final Map<int, ListNode> byOrder = {};
    for (final g in groups) {
      byOrder[g.order] = ListNode.group(g);
    }
    for (final iv in intervals) {
      if (!grouped.contains(iv.id)) {
        byOrder[iv.order] = ListNode.interval(iv);
      }
    }

    final sorted = byOrder.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sorted) {
      result.add(entry.value);
      // If it's a group and not collapsed, insert its member intervals
      if (entry.value.isGroup && !(entry.value.group!.collapsed)) {
        final members =
            intervals
                .where((iv) => entry.value.group!.intervalIds.contains(iv.id))
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));
        for (final m in members) {
          result.add(ListNode.interval(m));
        }
      }
    }
    return result;
  }

  // ── INIT ─────────────────────────────────────────────────────────
  void init(String wId) {
    wellId.value = wId;
    fetchAll();
  }

  // ════════════════════════════════════════════════════════════════
  //  API — FETCH
  // ════════════════════════════════════════════════════════════════
  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      final previousSelectedId = selected.value?.id;
      final res = await http.get(
        Uri.parse('${baseUrl}intervals/${wellId.value}'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List data = body['data'] ?? [];

        final List<IntervalItem> ivList = [];
        final List<IntervalGroup> grList = [];

        for (final item in data) {
          if (item['_type'] == 'group') {
            grList.add(IntervalGroup.fromJson(item));
          } else {
            ivList.add(IntervalItem.fromJson(item));
          }
        }

        intervals.assignAll(ivList);
        groups.assignAll(grList);

        // If no intervals at all → create a default one
        if (intervals.isEmpty && groups.isEmpty) {
          await _createDefaultInterval();
        } else {
          IntervalItem? restored;
          if (previousSelectedId != null) {
            for (final interval in intervals) {
              if (interval.id == previousSelectedId) {
                restored = interval;
                break;
              }
            }
          }

          if (restored != null) {
            selectInterval(restored);
          } else if (intervals.isNotEmpty) {
            selectInterval(intervals.first);
          } else {
            selected.value = null;
          }
        }
      }
    } catch (e) {
      debugPrint('IntervalController fetchAll error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  SELECT
  // ════════════════════════════════════════════════════════════════
  void selectInterval(IntervalItem iv) {
    selected.value = iv;
    _populateControllers(iv);
  }

  void _populateControllers(IntervalItem iv) {
    _isHydratingControllers = true;
    formationCtrl.text = iv.formation;
    bitSizeCtrl.text = iv.bitSize;
    casingCtrl.text = iv.casing;
    intervalFITCtrl.text = iv.intervalFIT;
    mudDescCtrl.text = iv.mudDescription;
    mudTypeCtrl.text = iv.mudType;
    intervalSummaryCtrl.text = iv.intervalSummary;
    solidControlCtrl.text = iv.solidControl;
    intervalConclusionCtrl.text = iv.intervalConclusion;
    sweepsCtrl.text = iv.sweeps;
    labTestingCtrl.text = iv.labTesting;
    endOfIntervalCtrl.text = iv.endOfIntervalConclusion;
    _isHydratingControllers = false;
  }

  // ════════════════════════════════════════════════════════════════
  //  CREATE
  // ════════════════════════════════════════════════════════════════
  Future<void> _createDefaultInterval() async {
    await _postInterval('New Interval', null);
  }

  Future<void> insertBefore() async {
    if (selected.value == null) {
      await _postInterval('New Interval', null);
      return;
    }
    // insertAfterOrder = selected.order - 1 (i.e., just before selected)
    final insertAfterOrder = selected.value!.order - 1;
    await _postInterval(
      'New Interval',
      insertAfterOrder < 0 ? null : insertAfterOrder,
    );
  }

  Future<void> insertAfter() async {
    final insertAfterOrder = selected.value?.order;
    await _postInterval('New Interval', insertAfterOrder);
  }

  Future<void> _postInterval(String name, int? insertAfterOrder) async {
    isSaving.value = true;
    try {
      final body = <String, dynamic>{'wellId': wellId.value, 'name': name};
      if (insertAfterOrder != null) {
        body['insertAfterOrder'] = insertAfterOrder;
      }

      final res = await http.post(
        Uri.parse('${baseUrl}intervals/'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (res.statusCode == 201) {
        await fetchAll();
      }
    } catch (e) {
      debugPrint('IntervalController insertInterval error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  RENAME
  // ════════════════════════════════════════════════════════════════
  Future<void> renameInterval(IntervalItem iv, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) return;
    isSaving.value = true;
    try {
      final res = await http.put(
        Uri.parse('${baseUrl}intervals/${iv.id}'),
        headers: _headers,
        body: jsonEncode({'name': trimmedName}),
      );
      if (res.statusCode == 200) {
        await fetchAll();
      } else {
        Get.snackbar(
          'Rename Failed',
          'Interval name could not be updated',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('IntervalController rename error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  DELETE
  // ════════════════════════════════════════════════════════════════
  Future<void> removeSelected() async {
    if (selected.value == null) return;
    final id = selected.value!.id;
    isSaving.value = true;
    try {
      final res = await http.delete(
        Uri.parse('${baseUrl}intervals/$id'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        selected.value = null;
        await fetchAll();
      }
    } catch (e) {
      debugPrint('IntervalController delete error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  SAVE GENERAL TAB DATA
  // ════════════════════════════════════════════════════════════════
  Future<void> saveGeneralData({
    IntervalItem? target,
    bool refreshAfterSave = false,
    bool showToast = false,
  }) async {
    final iv = target ?? selected.value;
    if (iv == null) return;
    isSaving.value = true;
    try {
      if (selected.value?.id == iv.id) {
        _syncIntervalFromControllers(iv);
      }

      final res = await http.put(
        Uri.parse('${baseUrl}intervals/${iv.id}'),
        headers: _headers,
        body: jsonEncode(iv.toJson()),
      );
      if (res.statusCode == 200) {
        if (refreshAfterSave) {
          await fetchAll();
        } else {
          intervals.refresh();
          if (selected.value?.id == iv.id) {
            selected.refresh();
          }
        }
        if (showToast) {
          Get.snackbar(
            'Saved',
            'Interval data saved',
            duration: const Duration(seconds: 1),
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      debugPrint('IntervalController saveGeneralData error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  GROUPS
  // ════════════════════════════════════════════════════════════════
  Future<void> createGroup(String groupName, List<String> intervalIds) async {
    if (groupName.isEmpty || intervalIds.isEmpty) return;
    isSaving.value = true;
    try {
      final res = await http.post(
        Uri.parse('${baseUrl}intervals/groups'),
        headers: _headers,
        body: jsonEncode({
          'wellId': wellId.value,
          'name': groupName,
          'intervalIds': intervalIds,
        }),
      );
      if (res.statusCode == 201) {
        await fetchAll();
      }
    } catch (e) {
      debugPrint('IntervalController createGroup error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    isSaving.value = true;
    try {
      final res = await http.delete(
        Uri.parse('${baseUrl}intervals/groups/$groupId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        await fetchAll();
      }
    } catch (e) {
      debugPrint('IntervalController deleteGroup error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleGroupCollapse(IntervalGroup group) async {
    group.collapsed = !group.collapsed;
    groups.refresh();
    try {
      await http.patch(
        Uri.parse('${baseUrl}intervals/groups/${group.id}/collapse'),
        headers: _headers,
        body: jsonEncode({'collapsed': group.collapsed}),
      );
    } catch (e) {
      debugPrint('IntervalController toggleCollapse error: $e');
    }
  }
}
