import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/sce_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/sce_model.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

class SceView extends StatefulWidget {
  const SceView({super.key});

  @override
  State<SceView> createState() => _SceViewState();
}

class _SceViewState extends State<SceView> {
  static const double _rowHeight = 31;
  static const double _titleHeight = 28;
  static const double _headerHeight = 30;
  static const Color _borderColor = Color(0xFFC9CED6);
  static const Color _headerColor = Color(0xFFF3F3F3);
  static const Color _labelColor = Color(0xFFF7F7F7);
  static const Color _editColor = Color(0xFFFFF6C7);

  late final UgController ugController;
  late final SceController sceController;
  late final PadWellController padWellController;
  Worker? _wellWorker;
  Worker? _reportWorker;

  ShakerModel? _shakerClipboard;
  OtherSceModel? _otherSceClipboard;

  @override
  void initState() {
    super.initState();
    ugController = Get.find<UgController>();
    sceController = Get.isRegistered<SceController>()
        ? Get.find<SceController>()
        : Get.put(SceController());
    padWellController = padWellContext;

    _wellWorker = ever<String>(padWellController.selectedWellId, (wellId) {
      if (wellId.isNotEmpty) {
        sceController.loadSceData(wellId);
      }
    });
    _reportWorker = ever<String>(reportContext.selectedReportId, (_) {
      final wellId = padWellController.selectedWellId.value;
      if (wellId.isNotEmpty) {
        sceController.loadSceData(wellId);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wellId = padWellController.selectedWellId.value;
      if (wellId.isNotEmpty) {
        sceController.loadSceData(wellId);
      }
    });
  }

  @override
  void dispose() {
    _wellWorker?.dispose();
    _reportWorker?.dispose();
    super.dispose();
  }

  bool get _isLocked => ugController.isLocked.value;

  PopupMenuItem<String> _rowMenuItem(
    String value,
    String label,
    String shortcut, {
    required bool enabled,
  }) {
    final color = enabled ? const Color(0xFF2F2F2F) : const Color(0xFF9EA4AD);
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(width: 20),
          Text(shortcut, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Future<void> _showShakerMenu(TapDownDetails details, int index) async {
    final shaker = sceController.shakers[index];
    final hasData = shaker.hasData;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _rowMenuItem('cut', 'Cut', 'Ctrl+X', enabled: !_isLocked && hasData),
        _rowMenuItem('copy', 'Copy', 'Ctrl+C', enabled: hasData),
        _rowMenuItem(
          'paste',
          'Paste',
          'Ctrl+V',
          enabled: !_isLocked && _shakerClipboard != null,
        ),
        _rowMenuItem(
          'delete',
          'Delete',
          'Delete',
          enabled: !_isLocked && hasData,
        ),
        const PopupMenuDivider(),
        _rowMenuItem('top', 'To the Top', 'Ctrl+Up', enabled: false),
        _rowMenuItem('bottom', 'To the Bottom', 'Ctrl+Down', enabled: false),
      ],
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'cut':
        _shakerClipboard = shaker.clone();
        await sceController.deleteShaker(index);
        break;
      case 'copy':
        _shakerClipboard = shaker.clone();
        break;
      case 'paste':
        _pasteShaker(index);
        break;
      case 'delete':
        await sceController.deleteShaker(index);
        break;
    }
  }

  Future<void> _showOtherSceMenu(TapDownDetails details, int index) async {
    final row = sceController.otherSce[index];
    final hasData = row.hasData;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _rowMenuItem('cut', 'Cut', 'Ctrl+X', enabled: !_isLocked && hasData),
        _rowMenuItem('copy', 'Copy', 'Ctrl+C', enabled: hasData),
        _rowMenuItem(
          'paste',
          'Paste',
          'Ctrl+V',
          enabled: !_isLocked && _otherSceClipboard != null,
        ),
        _rowMenuItem(
          'delete',
          'Delete',
          'Delete',
          enabled: !_isLocked && hasData,
        ),
        const PopupMenuDivider(),
        _rowMenuItem('top', 'To the Top', 'Ctrl+Up', enabled: false),
        _rowMenuItem('bottom', 'To the Bottom', 'Ctrl+Down', enabled: false),
      ],
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'cut':
        _otherSceClipboard = row.clone();
        await sceController.deleteOtherSce(index);
        break;
      case 'copy':
        _otherSceClipboard = row.clone();
        break;
      case 'paste':
        _pasteOtherSce(index);
        break;
      case 'delete':
        await sceController.deleteOtherSce(index);
        break;
    }
  }

  void _pasteShaker(int index) {
    final clip = _shakerClipboard;
    if (clip == null) return;
    final target = sceController.shakers[index];
    target.model.value = clip.model.value;
    target.screens.value = clip.screens.value;
    target.plot.value = clip.plot.value;
    target.screen1.value = clip.screen1.value;
    target.screen2.value = clip.screen2.value;
    target.screen3.value = clip.screen3.value;
    target.screen4.value = clip.screen4.value;
    target.screen5.value = clip.screen5.value;
    target.screen6.value = clip.screen6.value;
    target.screen7.value = clip.screen7.value;
    target.screen8.value = clip.screen8.value;
    target.time.value = clip.time.value;
    target.oocWt.value = clip.oocWt.value;
    sceController.shakers.refresh();
    sceController.scheduleShakerAutosave(index);
  }

  void _pasteOtherSce(int index) {
    final clip = _otherSceClipboard;
    if (clip == null) return;
    final target = sceController.otherSce[index];
    target.model1.value = clip.model1.value;
    target.model2.value = clip.model2.value;
    target.model3.value = clip.model3.value;
    target.plot.value = clip.plot.value;
    target.uf.value = clip.uf.value;
    target.of.value = clip.of.value;
    target.time.value = clip.time.value;
    target.oocWt.value = clip.oocWt.value;
    sceController.otherSce.refresh();
    sceController.scheduleOtherSceAutosave(index);
  }

  void _toggleAllShakerPlots(bool? value) {
    final newValue = value ?? false;
    for (int i = 0; i < sceController.shakers.length; i++) {
      final row = sceController.shakers[i];
      if (!row.hasData) continue;
      row.plot.value = newValue;
      sceController.scheduleShakerAutosave(i);
    }
    sceController.shakers.refresh();
  }

  void _toggleAllOtherPlots(bool? value) {
    final newValue = value ?? false;
    for (int i = 0; i < sceController.otherSce.length; i++) {
      final row = sceController.otherSce[i];
      if (!row.hasData) continue;
      row.plot.value = newValue;
      sceController.scheduleOtherSceAutosave(i);
    }
    sceController.otherSce.refresh();
  }

  bool _allShakerPlotsChecked() {
    final rows = sceController.shakers.where((row) => row.hasData).toList();
    if (rows.isEmpty) return false;
    return rows.every((row) => row.plot.value);
  }

  bool _allOtherPlotsChecked() {
    final rows = sceController.otherSce.where((row) => row.hasData).toList();
    if (rows.isEmpty) return false;
    return rows.every((row) => row.plot.value);
  }

  Widget _sectionTitle({
    required String title,
    required bool allChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      height: _titleHeight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const Spacer(),
          Checkbox(
            value: allChecked,
            onChanged: _isLocked ? null : onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            side: const BorderSide(color: Color(0xFF9EA4AD)),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(
    String text, {
    required int flex,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: _headerHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: const BoxDecoration(
          color: _headerColor,
          border: Border(
            right: BorderSide(color: _borderColor),
            bottom: BorderSide(color: _borderColor),
          ),
        ),
        child: Text(
          text,
          textAlign: textAlign,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2F2F2F),
          ),
        ),
      ),
    );
  }

  Widget _labelCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: _rowHeight,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: _labelColor,
          border: Border(
            right: BorderSide(color: _borderColor),
            bottom: BorderSide(color: _borderColor),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF2F2F2F),
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _editableTextCell({
    required String value,
    required ValueChanged<String> onChanged,
    required int flex,
    TextAlign textAlign = TextAlign.center,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: _rowHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: _isLocked ? Colors.white : _editColor,
          border: const Border(
            right: BorderSide(color: _borderColor),
            bottom: BorderSide(color: _borderColor),
          ),
        ),
        child: _isLocked
            ? Text(
                value,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 11,
                  color: value.isEmpty
                      ? const Color(0xFFB1B5BC)
                      : const Color(0xFF2F2F2F),
                ),
              )
            : TextField(
                controller: TextEditingController(text: value)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: value.length),
                  ),
                onChanged: onChanged,
                textAlign: textAlign,
                inputFormatters: inputFormatters,
                style: const TextStyle(fontSize: 11, color: Color(0xFF2F2F2F)),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 7),
                ),
              ),
      ),
    );
  }

  Widget _screensCell(ShakerModel row, int index) {
    final current = row.screens.value;
    return Expanded(
      flex: 2,
      child: Container(
        height: _rowHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: _isLocked ? Colors.white : _editColor,
          border: const Border(
            right: BorderSide(color: _borderColor),
            bottom: BorderSide(color: _borderColor),
          ),
        ),
        child: _isLocked
            ? Text(
                current,
                style: TextStyle(
                  fontSize: 11,
                  color: current.isEmpty
                      ? const Color(0xFFB1B5BC)
                      : const Color(0xFF2F2F2F),
                ),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: current.isEmpty ? '' : current,
                  items: const ['', '1', '2', '3', '4', '5', '6', '7', '8']
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    row.screens.value = value ?? '';
                    sceController.shakers.refresh();
                    sceController.scheduleShakerAutosave(index);
                  },
                ),
              ),
      ),
    );
  }

  Widget _plotCell({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: _rowHeight,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: _borderColor),
            bottom: BorderSide(color: _borderColor),
          ),
        ),
        child: Checkbox(
          value: value,
          onChanged: _isLocked ? null : onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          side: const BorderSide(color: Color(0xFF9EA4AD)),
        ),
      ),
    );
  }

  Widget _shakerRow(int index) {
    final row = sceController.shakers[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => _showShakerMenu(details, index),
      child: Row(
        children: [
          _labelCell(row.shaker.value, flex: 3),
          _editableTextCell(
            value: row.model.value,
            flex: 3,
            onChanged: (value) {
              row.model.value = value;
              sceController.shakers.refresh();
              sceController.scheduleShakerAutosave(index);
            },
          ),
          _screensCell(row, index),
          _plotCell(
            value: row.plot.value,
            flex: 2,
            onChanged: (value) {
              row.plot.value = value ?? false;
              sceController.shakers.refresh();
              sceController.scheduleShakerAutosave(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _otherSceRow(int index) {
    final row = sceController.otherSce[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => _showOtherSceMenu(details, index),
      child: Row(
        children: [
          _labelCell(row.type.value, flex: 3),
          _editableTextCell(
            value: row.model1.value,
            flex: 3,
            onChanged: (value) {
              row.model1.value = value;
              sceController.otherSce.refresh();
              sceController.scheduleOtherSceAutosave(index);
            },
          ),
          _editableTextCell(
            value: row.model2.value,
            flex: 3,
            onChanged: (value) {
              row.model2.value = value;
              sceController.otherSce.refresh();
              sceController.scheduleOtherSceAutosave(index);
            },
          ),
          _editableTextCell(
            value: row.model3.value,
            flex: 3,
            onChanged: (value) {
              row.model3.value = value;
              sceController.otherSce.refresh();
              sceController.scheduleOtherSceAutosave(index);
            },
          ),
          _plotCell(
            value: row.plot.value,
            flex: 2,
            onChanged: (value) {
              row.plot.value = value ?? false;
              sceController.otherSce.refresh();
              sceController.scheduleOtherSceAutosave(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _shakerTable() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            _sectionTitle(
              title: 'Shaker',
              allChecked: _allShakerPlotsChecked(),
              onChanged: _toggleAllShakerPlots,
            ),
            Row(
              children: [
                _headerCell('Shaker', flex: 3, textAlign: TextAlign.left),
                _headerCell('Model', flex: 3),
                _headerCell('No. of Screen', flex: 2),
                _headerCell('Plot', flex: 2),
              ],
            ),
            for (int i = 0; i < SceController.shakerLabels.length; i++)
              _shakerRow(i),
          ],
        ),
      ),
    );
  }

  Widget _otherSceTable() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            _sectionTitle(
              title: 'Other SCE',
              allChecked: _allOtherPlotsChecked(),
              onChanged: _toggleAllOtherPlots,
            ),
            Row(
              children: [
                _headerCell('Type', flex: 3, textAlign: TextAlign.left),
                _headerCell('Model 1', flex: 3),
                _headerCell('Model 2', flex: 3),
                _headerCell('Model 3', flex: 3),
                _headerCell('Plot', flex: 2),
              ],
            ),
            for (int i = 0; i < SceController.otherSceLabels.length; i++)
              _otherSceRow(i),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Obx(() {
        if (sceController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 9, child: _shakerTable()),
            const SizedBox(width: 14),
            Expanded(flex: 11, child: _otherSceTable()),
          ],
        );
      }),
    );
  }
}
