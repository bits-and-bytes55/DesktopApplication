import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/add_water_save_bridge.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import '../../controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AddWaterView extends StatefulWidget {
  const AddWaterView({super.key, required this.instanceKey});

  final String instanceKey;

  @override
  State<AddWaterView> createState() => _AddWaterViewState();
}

class _AddWaterViewState extends State<AddWaterView> {
  late final DashboardController dashboardController;
  late final PitController pitController;
  late final AddWaterSaveBridge _saveBridge;
  final AuthRepository _repository = AuthRepository();
  final RxString _selectedTo = "Active System".obs;
  final RxString _mainVol = "".obs;
  final RxList<String> _extraRows = <String>["", ""].obs;
  final RxList<String> _recordIds = <String>[].obs;
  final RxBool _isLoading = false.obs;
  late final TextEditingController _mainVolController;
  final List<TextEditingController> _extraVolControllers = [];
  final List<Worker> _workers = [];
  Timer? _autoSaveTimer;
  bool _isApplyingState = false;
  String _loadedWellId = '';
  String _loadedReportId = '';

  @override
  void initState() {
    super.initState();
    dashboardController = Get.find<DashboardController>();
    pitController = Get.isRegistered<PitController>()
        ? Get.find<PitController>()
        : Get.put(PitController());
    _saveBridge = Get.isRegistered<AddWaterSaveBridge>()
        ? Get.find<AddWaterSaveBridge>()
        : Get.put(AddWaterSaveBridge(), permanent: true);
    _saveBridge.register(widget.instanceKey, _saveForToolbar);
    _mainVolController = TextEditingController(text: _mainVol.value);
    _syncExtraControllers();
    _workers.addAll([
      ever<String>(_mainVol, (value) {
        _setControllerText(_mainVolController, value);
        _scheduleAutoSave();
      }),
      ever<String>(_selectedTo, (_) => _scheduleAutoSave()),
      ever<List<String>>(_extraRows, (_) {
        _syncExtraControllers(notify: true);
        _scheduleAutoSave();
      }),
      ever<String>(padWellContext.selectedWellId, (_) => _load(force: true)),
      ever<String>(reportContext.selectedReportId, (_) => _load(force: true)),
    ]);
    pitController.fetchAllPits();
    _load(force: true);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _saveBridge.unregister(widget.instanceKey);
    for (final worker in _workers) {
      worker.dispose();
    }
    _mainVolController.dispose();
    for (final textController in _extraVolControllers) {
      textController.dispose();
    }
    super.dispose();
  }

  double _parseVolume(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0.0;

  String _formatVolume(double value) {
    if (value <= 0 || value.isNaN) return '';
    return value
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Map<String, dynamic>? _extractEntity(dynamic value) {
    if (value is Map && value['data'] is Map) {
      return Map<String, dynamic>.from(value['data'] as Map);
    }
    if (value is Map && value['data'] is List) {
      final items = value['data'] as List;
      if (items.isNotEmpty && items.first is Map) {
        return Map<String, dynamic>.from(items.first as Map);
      }
    }
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  void _resetState() {
    _selectedTo.value = "Active System";
    _mainVol.value = "";
    _extraRows.assignAll(["", ""]);
    _recordIds.clear();
  }

  List<String> _collectVolumes() {
    final values = <String>[];
    final main = _mainVol.value.trim();
    if (_parseVolume(main) > 0) {
      values.add(main);
    }
    for (final row in _extraRows) {
      final trimmed = row.trim();
      if (_parseVolume(trimmed) > 0) {
        values.add(trimmed);
      }
    }
    return values;
  }

  bool get _hasData => _recordIds.isNotEmpty || _collectVolumes().isNotEmpty;

  bool _belongsToThisInstance(Map<String, dynamic> item) {
    final key = (item['operationInstanceKey'] ?? '').toString().trim();
    if (key == widget.instanceKey) return true;
    return key.isEmpty && widget.instanceKey == 'addWater::legacy0';
  }

  Future<void> _refreshPitState() async {
    await pitController.fetchAllPits();
    await pitController.fetchSelectedPits();
    await pitController.fetchUnselectedPits();
    await pitController.fetchVolumeNameData();
  }

  Future<void> _load({bool force = false}) async {
    _autoSaveTimer?.cancel();
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();
    if (wellId.isEmpty || reportId.isEmpty) {
      _isApplyingState = true;
      _loadedWellId = '';
      _loadedReportId = '';
      _resetState();
      _isApplyingState = false;
      return;
    }
    if (!force &&
        _loadedWellId == wellId &&
        _loadedReportId == reportId &&
        !_isLoading.value) {
      return;
    }

    _isLoading.value = true;
    _isApplyingState = true;
    try {
      final result = await _repository.getAddWaterList(wellId);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load Add Water');
      }

      final envelope = result['data'];
      final data = envelope is Map<String, dynamic>
          ? envelope['data']
          : envelope is Map
          ? Map<String, dynamic>.from(envelope)['data']
          : null;
      final allItems = data is List
          ? List<Map<String, dynamic>>.from(data)
          : const <Map<String, dynamic>>[];
      final chronologicalItems = allItems
          .where(_belongsToThisInstance)
          .toList()
          .reversed
          .toList();

      if (chronologicalItems.isEmpty) {
        _resetState();
        _loadedWellId = wellId;
        _loadedReportId = reportId;
        return;
      }

      final volumes = chronologicalItems
          .map(
            (item) =>
                _formatVolume(_parseVolume((item['volume'] ?? '').toString())),
          )
          .toList();
      final recordIds = chronologicalItems
          .map((item) => (item['_id'] ?? item['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      final target = (chronologicalItems.first['to'] ?? 'Active System')
          .toString()
          .trim();
      _selectedTo.value = target.isEmpty ? 'Active System' : target;
      _mainVol.value = volumes.isNotEmpty ? volumes.first : "";

      final extras = volumes.length > 1 ? volumes.skip(1).toList() : <String>[];
      while (extras.length < 2) {
        extras.add("");
      }
      if (extras.isNotEmpty && extras.last.trim().isNotEmpty) {
        extras.add("");
      }
      _extraRows.assignAll(extras);
      _recordIds.assignAll(recordIds);
      _loadedWellId = wellId;
      _loadedReportId = reportId;
    } catch (_) {
      _resetState();
    } finally {
      _isApplyingState = false;
      _isLoading.value = false;
    }
  }

  Future<void> _save() async {
    _autoSaveTimer?.cancel();
    final wellId = currentBackendWellId.trim();
    final reportId = reportContext.selectedReportId.value.trim();
    if (wellId.isEmpty || reportId.isEmpty) return;

    final enteredTo = _selectedTo.value.trim().isEmpty
        ? 'Active System'
        : _selectedTo.value.trim();
    final enteredVolumes = _collectVolumes();

    if (_loadedWellId != wellId || _loadedReportId != reportId) {
      if (enteredVolumes.isEmpty && _recordIds.isEmpty) {
        await _load(force: true);
      } else {
        _loadedWellId = wellId;
        _loadedReportId = reportId;
      }
    }

    final currentIds = _recordIds.toList();
    if (enteredVolumes.isEmpty) {
      for (final id in currentIds) {
        await _repository.deleteAddWater(wellId, id);
      }
      _isApplyingState = true;
      _resetState();
      _loadedWellId = wellId;
      _loadedReportId = reportId;
      _isApplyingState = false;
      await _refreshPitState();
      return;
    }

    for (var index = 0; index < enteredVolumes.length; index++) {
      final body = {
        'to': enteredTo,
        'volume': _parseVolume(enteredVolumes[index]),
        'operationInstanceKey': widget.instanceKey,
      };
      final existingId = index < currentIds.length ? currentIds[index] : '';
      final result = existingId.isNotEmpty
          ? await _repository.updateAddWater(wellId, existingId, body)
          : await _repository.createAddWater(wellId, body);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to save Add Water');
      }
      if (result['success'] == true && existingId.isEmpty) {
        final savedData = _extractEntity(result['data']);
        final savedId = (savedData?['_id'] ?? savedData?['id'])?.toString();
        if (savedId != null && savedId.isNotEmpty) {
          currentIds.add(savedId);
        }
      }
    }

    for (
      var index = enteredVolumes.length;
      index < currentIds.length;
      index++
    ) {
      await _repository.deleteAddWater(wellId, currentIds[index]);
    }

    _recordIds.assignAll(
      currentIds.take(enteredVolumes.length).where((id) => id.isNotEmpty),
    );
    _loadedWellId = wellId;
    _loadedReportId = reportId;
    await _refreshPitState();
  }

  Future<void> _saveSafely() async {
    try {
      await _save();
    } catch (e) {
      debugPrint('Add Water save error: $e');
    }
  }

  Future<Map<String, dynamic>> _saveForToolbar() async {
    try {
      await _save();
      return {'success': true, 'message': 'Add Water saved successfully'};
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      debugPrint('Add Water save error: $message');
      return {'success': false, 'message': message};
    }
  }

  void _scheduleAutoSave() {
    if (_isApplyingState || _isLoading.value || !_hasData) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 850), () async {
      if (_isApplyingState || _isLoading.value || !_hasData) return;
      await _saveSafely();
    });
  }

  void _setControllerText(TextEditingController textController, String value) {
    if (textController.text == value) return;
    textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _syncExtraControllers({bool notify = false}) {
    final values = _extraRows;
    while (_extraVolControllers.length < values.length) {
      _extraVolControllers.add(TextEditingController());
    }
    while (_extraVolControllers.length > values.length) {
      _extraVolControllers.removeLast().dispose();
    }
    for (var index = 0; index < values.length; index++) {
      _setControllerText(_extraVolControllers[index], values[index]);
    }
    if (notify && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Add Water",
            style: AppTheme.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.tableGridBlue),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() {
                  _syncExtraControllers();
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                ),
                                border: Border(
                                  right: BorderSide(
                                    color: AppTheme.tableGridBlue,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "To",
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: PopupMenuButton<String>(
                                  enabled: !dashboardController.isLocked.value,
                                  offset: const Offset(0, 0),
                                  constraints: const BoxConstraints(
                                    maxHeight: 180,
                                    minWidth: 200,
                                  ),
                                  child: Container(
                                    height: 24,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppTheme.tableGridBlue,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedTo.value,
                                            textAlign: TextAlign.center,
                                            style: AppTheme.bodySmall.copyWith(
                                              fontSize: 11,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down_rounded,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),
                                  onSelected: (String value) {
                                    _selectedTo.value = value;
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final items = <PopupMenuItem<String>>[
                                      PopupMenuItem<String>(
                                        value: "Active System",
                                        height: 32,
                                        child: Text(
                                          "Active System",
                                          style: AppTheme.bodySmall.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ];

                                    if (pitController.pits.isNotEmpty) {
                                      items.add(
                                        const PopupMenuItem<String>(
                                          enabled: false,
                                          height: 1,
                                          child: Divider(height: 1),
                                        ),
                                      );
                                    }

                                    items.addAll(
                                      pitController.pits.map((pit) {
                                        return PopupMenuItem<String>(
                                          value: pit.pitName,
                                          height: 32,
                                          child: Text(
                                            pit.pitName,
                                            style: AppTheme.bodySmall.copyWith(
                                              fontSize: 11,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );

                                    return items;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: AppTheme.tableGridBlue),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                border: Border(
                                  right: BorderSide(
                                    color: AppTheme.tableGridBlue,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Vol. (bbl)",
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: TextField(
                                  enabled: !dashboardController.isLocked.value,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintText: "Enter value...",
                                    hintStyle: AppTheme.caption.copyWith(
                                      color: Colors.grey.shade400,
                                      fontSize: 10,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  controller: _mainVolController,
                                  onChanged: (val) {
                                    _mainVol.value = val;
                                  },
                                  onSubmitted: (_) => _saveSafely(),
                                  onEditingComplete: _saveSafely,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(
                        _extraRows.length,
                        (index) => Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: index % 2 == 0
                                ? Colors.white
                                : Colors.grey.shade50,
                            border: Border(
                              bottom: index == _extraRows.length - 1
                                  ? BorderSide.none
                                  : BorderSide(color: Colors.grey.shade200),
                            ),
                            borderRadius: index == _extraRows.length - 1
                                ? const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: AppTheme.tableGridBlue,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: TextField(
                                    controller: _extraVolControllers[index],
                                    enabled:
                                        !dashboardController.isLocked.value,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintText: "",
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                    style: AppTheme.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      _extraRows[index] = val;
                                      if (index == _extraRows.length - 1 &&
                                          val.isNotEmpty) {
                                        _extraRows.add("");
                                      }
                                    },
                                    onSubmitted: (_) => _saveSafely(),
                                    onEditingComplete: _saveSafely,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
