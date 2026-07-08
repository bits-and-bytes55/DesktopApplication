import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/compact_tabular_database_dialog.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_setup_ui_pattern.dart';

const double _cIdx = 52.0;
const double _cDesc = 180.0;
const double _cType = 148.0;
const double _cStd = 112.0;
const double _cRowH = 31.0;
const double _cHeadTopH = 34.0;
const int _minVisibleRows = 20;

const Color _cBorder = wellSetupBorder;
const Color _cHeader = wellSetupSectionHeader;
const Color _cLocked = wellSetupLockedEditable;
const String _casingDiameterBaseUnit = '(mm)';
const String _casingLineDensityBaseUnit = '(lb/ft)';
const String _casingLengthBaseUnit = '(ft)';

double get _casingTableWidth => _cIdx + _cDesc + _cType + (_cStd * 7) + 4;

int? _decimalPlacesFromText(String value) {
  final text = value.trim().replaceAll(',', '');
  final decimalIndex = text.indexOf('.');
  if (decimalIndex < 0) return null;
  return (text.length - decimalIndex - 1).clamp(0, 12).toInt();
}

String _formatCasingNumber(double value, {String? sourceText}) {
  final sourceDecimals = sourceText == null
      ? null
      : _decimalPlacesFromText(sourceText);
  if (sourceDecimals != null) {
    return value.toStringAsFixed(sourceDecimals);
  }
  return value
      .toStringAsFixed(4)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

String _convertCasingText(String rawValue, String fromUnit, String toUnit) {
  final raw = rawValue.trim();
  if (raw.isEmpty || fromUnit == toUnit) return rawValue;
  final parsed = double.tryParse(raw.replaceAll(',', ''));
  if (parsed == null) return rawValue;
  final converted = AppUnits.convertValue(parsed, fromUnit, toUnit);
  if (converted == null) return rawValue;
  return _formatCasingNumber(converted, sourceText: rawValue);
}

String _displayDiameter(String value) =>
    _convertCasingText(value, _casingDiameterBaseUnit, AppUnits.diameter);

String _displayLineDensity(String value) =>
    _convertCasingText(value, _casingLineDensityBaseUnit, AppUnits.lineDensity);

String _displayLength(String value) =>
    _convertCasingText(value, _casingLengthBaseUnit, AppUnits.length);

String _storeDiameter(String value) =>
    _convertCasingText(value, AppUnits.diameter, _casingDiameterBaseUnit);

String _storeLineDensity(String value) =>
    _convertCasingText(value, AppUnits.lineDensity, _casingLineDensityBaseUnit);

String _storeLength(String value) =>
    _convertCasingText(value, AppUnits.length, _casingLengthBaseUnit);

class CasingView extends StatefulWidget {
  const CasingView({super.key});

  @override
  State<CasingView> createState() => _CasingViewState();
}

class _CasingViewState extends State<CasingView> with WidgetsBindingObserver {
  late final UgStController c;
  final ScrollController _vScroll = ScrollController();
  Map<String, String>? _clipboard;
  int _selectedEmptyIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c = Get.find<UgStController>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(c.flushPendingCasingSave());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(c.flushPendingCasingSave());
    _vScroll.dispose();
    super.dispose();
  }

  bool get _isLocked => c.isLocked.value;

  CasingRow? get _selectedSavedRow {
    final selectedKey = c.selectedCasingDeleteKey.value.trim();
    if (selectedKey.isEmpty) return null;
    return _firstWhereOrNull<CasingRow>(
      c.casings,
      (row) => c.casingRowKey(row) == selectedKey,
    );
  }

  void _selectSavedRow(CasingRow row) {
    c.selectCasingForDelete(row);
    if (_selectedEmptyIndex != -1) {
      setState(() => _selectedEmptyIndex = -1);
    }
  }

  void _selectEmptyRow(int index) {
    c.selectedCasingDeleteKey.value = '';
    setState(() => _selectedEmptyIndex = index);
  }

  Future<void> _openTubularDatabase() async {
    if (_isLocked) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CompactTabularDatabaseDialog(),
    );

    if (result == null) return;

    final selectedRow = _selectedSavedRow;
    if (selectedRow != null) {
      selectedRow.description.value = selectedRow.description.value.isEmpty
          ? (result['type'] ?? '')
          : selectedRow.description.value;
      selectedRow.od.value = result['odMm'] ?? selectedRow.od.value;
      selectedRow.wt.value = result['weightLbFt'] ?? selectedRow.wt.value;
      selectedRow.id.value = result['idMm'] ?? selectedRow.id.value;
      c.casings.refresh();
      c.scheduleCasingAutoSave(selectedRow);
      return;
    }

    final newRow = CasingRow(
      description: result['type'] ?? '',
      od: result['odMm'] ?? '',
      wt: result['weightLbFt'] ?? '',
      id: result['idMm'] ?? '',
    );
    final saved = await c.addCasing(newRow, refresh: false);
    if (saved) {
      c.casings.add(newRow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: ColoredBox(
          color: wellSetupPageBackground,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 28,
              color: _cHeader,
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'Casing',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _iconButton(
                    tooltip: 'Tabular Database',
                    onTap: _isLocked ? null : _openTubularDatabase,
                    icon: Icons.table_chart_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _casingTableWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _cBorder),
                    ),
                    child: Column(
                      children: [
                        _header(),
                        Expanded(child: _body()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required String tooltip,
    required VoidCallback? onTap,
    required IconData icon,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _cBorder),
          ),
          child: Icon(
            icon,
            size: 14,
            color: onTap == null
                ? const Color(0xFF9EA4AD)
                : const Color(0xFF1976D2),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final unitSignature = AppUnits.signature;
    return Column(
      key: ValueKey(unitSignature),
      children: [
        Row(
          children: [
            _headCell('', _cIdx, _cHeadTopH),
            _headCell('Description', _cDesc, _cHeadTopH),
            _headCell('Type', _cType, _cHeadTopH),
            _headCell(
              'OD\n${AppUnits.unitText(_casingDiameterBaseUnit)}',
              _cStd,
              _cHeadTopH,
            ),
            _headCell(
              'Wt.\n${AppUnits.unitText(_casingLineDensityBaseUnit)}',
              _cStd,
              _cHeadTopH,
            ),
            _headCell(
              'ID\n${AppUnits.unitText(_casingDiameterBaseUnit)}',
              _cStd,
              _cHeadTopH,
            ),
            _headCell(
              'Top\n${AppUnits.unitText(_casingLengthBaseUnit)}',
              _cStd,
              _cHeadTopH,
            ),
            _headCell(
              'Shoe\n${AppUnits.unitText(_casingLengthBaseUnit)}',
              _cStd,
              _cHeadTopH,
            ),
            _headCell(
              'Bit\n${AppUnits.unitText(_casingDiameterBaseUnit)}',
              _cStd,
              _cHeadTopH,
            ),
            _headCell(
              'TOC\n${AppUnits.unitText(_casingLengthBaseUnit)}',
              _cStd,
              _cHeadTopH,
            ),
          ],
        ),
      ],
    );
  }

  Widget _headCell(String text, double width, double height) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: wellSetupColumnHeader,
        border: Border(
          right: BorderSide(color: _cBorder),
          bottom: BorderSide(color: _cBorder),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _body() {
    return Scrollbar(
      controller: _vScroll,
      thumbVisibility: true,
      child: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final totalRows = c.casings.length > _minVisibleRows
            ? c.casings.length
            : _minVisibleRows;

        return ListView.builder(
          controller: _vScroll,
          itemCount: totalRows,
          itemExtent: _cRowH,
          itemBuilder: (context, index) {
            if (index < c.casings.length) {
              final row = c.casings[index];
              return _SavedCasingRow(
                key: ValueKey(row.dbId ?? 'saved_$index'),
                row: row,
                index: index,
                ctrl: c,
                locked: _isLocked,
                selected:
                    c.selectedCasingDeleteKey.value == c.casingRowKey(row),
                clipboard: _clipboard,
                onCopied: (data) => _clipboard = data,
                onSelected: () => _selectSavedRow(row),
              );
            }
            return _DraftCasingRow(
              key: ValueKey('draft_$index'),
              index: index,
              ctrl: c,
              locked: _isLocked,
              selected: _selectedEmptyIndex == index,
              clipboard: _clipboard,
              onCopied: (data) => _clipboard = data,
              onSelected: () => _selectEmptyRow(index),
            );
          },
        );
      }),
    );
  }
}

class _SavedCasingRow extends StatefulWidget {
  final CasingRow row;
  final int index;
  final UgStController ctrl;
  final bool locked;
  final bool selected;
  final Map<String, String>? clipboard;
  final ValueChanged<Map<String, String>> onCopied;
  final VoidCallback onSelected;

  const _SavedCasingRow({
    super.key,
    required this.row,
    required this.index,
    required this.ctrl,
    required this.locked,
    required this.selected,
    required this.clipboard,
    required this.onCopied,
    required this.onSelected,
  });

  @override
  State<_SavedCasingRow> createState() => _SavedCasingRowState();
}

class _SavedCasingRowState extends State<_SavedCasingRow> {
  late final TextEditingController _desc;
  late final TextEditingController _od;
  late final TextEditingController _wt;
  late final TextEditingController _id;
  late final TextEditingController _top;
  late final TextEditingController _shoe;
  late final TextEditingController _bit;
  late final TextEditingController _toc;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.row.description.value);
    _od = TextEditingController(text: _displayDiameter(widget.row.od.value));
    _wt = TextEditingController(text: _displayLineDensity(widget.row.wt.value));
    _id = TextEditingController(text: _displayDiameter(widget.row.id.value));
    _top = TextEditingController(text: _displayLength(widget.row.top.value));
    _shoe = TextEditingController(text: _displayLength(widget.row.shoe.value));
    _bit = TextEditingController(text: _displayDiameter(widget.row.bit.value));
    _toc = TextEditingController(text: _displayLength(widget.row.toc.value));
  }

  @override
  void didUpdateWidget(covariant _SavedCasingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_desc, widget.row.description.value);
    _syncController(_od, _displayDiameter(widget.row.od.value));
    _syncController(_wt, _displayLineDensity(widget.row.wt.value));
    _syncController(_id, _displayDiameter(widget.row.id.value));
    _syncController(_top, _displayLength(widget.row.top.value));
    _syncController(_shoe, _displayLength(widget.row.shoe.value));
    _syncController(_bit, _displayDiameter(widget.row.bit.value));
    _syncController(_toc, _displayLength(widget.row.toc.value));
  }

  @override
  void dispose() {
    _desc.dispose();
    _od.dispose();
    _wt.dispose();
    _id.dispose();
    _top.dispose();
    _shoe.dispose();
    _bit.dispose();
    _toc.dispose();
    super.dispose();
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Map<String, String> _rowMap() => {
    'description': _desc.text.trim(),
    'type': widget.row.type.value.trim(),
    'od': _od.text.trim(),
    'wt': _wt.text.trim(),
    'id': _id.text.trim(),
    'top': _top.text.trim(),
    'shoe': _shoe.text.trim(),
    'bit': _bit.text.trim(),
    'toc': _toc.text.trim(),
  };

  void _applyMap(Map<String, String> data) {
    _desc.text = data['description'] ?? '';
    widget.row.description.value = _desc.text;
    widget.row.type.value = data['type'] ?? '';
    _od.text = data['od'] ?? '';
    widget.row.od.value = _storeDiameter(_od.text);
    _wt.text = data['wt'] ?? '';
    widget.row.wt.value = _storeLineDensity(_wt.text);
    _id.text = data['id'] ?? '';
    widget.row.id.value = _storeDiameter(_id.text);
    _top.text = data['top'] ?? '';
    widget.row.top.value = _storeLength(_top.text);
    _shoe.text = data['shoe'] ?? '';
    widget.row.shoe.value = _storeLength(_shoe.text);
    _bit.text = data['bit'] ?? '';
    widget.row.bit.value = _storeDiameter(_bit.text);
    _toc.text = data['toc'] ?? '';
    widget.row.toc.value = _storeLength(_toc.text);
    widget.ctrl.scheduleCasingAutoSave(widget.row);
    setState(() {});
  }

  Future<void> _showMenu(TapDownDetails details) async {
    widget.onSelected();
    final hasData = _rowMap().values.any((value) => value.isNotEmpty);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _menuItem('cut', 'Cut', 'Ctrl+X', enabled: !widget.locked && hasData),
        _menuItem('copy', 'Copy', 'Ctrl+C', enabled: hasData),
        _menuItem(
          'paste',
          'Paste',
          'Ctrl+V',
          enabled: !widget.locked && widget.clipboard != null,
        ),
        _menuItem(
          'delete',
          'Delete',
          'Delete',
          enabled: !widget.locked && hasData,
        ),
        const PopupMenuDivider(),
        _menuItem('top', 'To the Top', 'Ctrl+Up', enabled: false),
        _menuItem('bottom', 'To the Bottom', 'Ctrl+Down', enabled: false),
      ],
    );

    if (action == null) return;
    switch (action) {
      case 'cut':
        widget.onCopied(_rowMap());
        await Clipboard.setData(
          ClipboardData(text: _rowMap().values.join('\n')),
        );
        if (widget.row.dbId != null && widget.row.dbId!.isNotEmpty) {
          await widget.ctrl.deleteCasing(widget.row.dbId!);
        }
        break;
      case 'copy':
        widget.onCopied(_rowMap());
        await Clipboard.setData(
          ClipboardData(text: _rowMap().values.join('\n')),
        );
        break;
      case 'paste':
        if (widget.clipboard != null) {
          _applyMap(widget.clipboard!);
        }
        break;
      case 'delete':
        if (widget.row.dbId != null && widget.row.dbId!.isNotEmpty) {
          await widget.ctrl.deleteCasing(widget.row.dbId!);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.locked ? _cLocked : Colors.white;
    final topReadOnly = widget.locked || _isCasingType(widget.row.type.value);
    final topBg = topReadOnly ? _cLocked : Colors.white;
    return Container(
      color: Colors.white,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelected,
        onSecondaryTapDown: _showMenu,
        child: Row(
          children: [
            _indexCell(widget.index, widget.selected),
            _editCell(
              controller: _desc,
              width: _cDesc,
              readOnly: widget.locked,
              bg: bg,
              onTap: widget.onSelected,
              onEditingComplete: () =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onSubmitted: (_) =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onChanged: (value) {
                widget.row.description.value = value;
                widget.ctrl.scheduleCasingAutoSave(widget.row);
              },
            ),
            _typeCell(
              width: _cType,
              value: widget.row.type.value,
              readOnly: widget.locked,
              bg: bg,
              onTap: widget.onSelected,
              onChanged: (value) {
                widget.row.type.value = value ?? '';
                widget.ctrl.scheduleCasingAutoSave(widget.row);
                setState(() {});
              },
            ),
            _editCell(
              controller: _od,
              width: _cStd,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: () =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onSubmitted: (_) =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onChanged: (value) {
                widget.row.od.value = _storeDiameter(value);
                widget.ctrl.scheduleCasingAutoSave(widget.row);
              },
            ),
            _editCell(
              controller: _wt,
              width: _cStd,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: () =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onSubmitted: (_) =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onChanged: (value) {
                widget.row.wt.value = _storeLineDensity(value);
                widget.ctrl.scheduleCasingAutoSave(widget.row);
              },
            ),
            _editCell(
              controller: _id,
              width: _cStd,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: () =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onSubmitted: (_) =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onChanged: (value) {
                widget.row.id.value = _storeDiameter(value);
                widget.ctrl.scheduleCasingAutoSave(widget.row);
              },
            ),
            _editCell(
              controller: _top,
              width: _cStd,
              readOnly: topReadOnly,
              bg: topBg,

              onTap: widget.onSelected,
              onEditingComplete: () =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onSubmitted: (_) =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onChanged: (value) {
                widget.row.top.value = _storeLength(value);
                widget.ctrl.scheduleCasingAutoSave(widget.row);
              },
            ),
            _editCell(
              controller: _shoe,
              width: _cStd,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: () =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onSubmitted: (_) =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onChanged: (value) {
                widget.row.shoe.value = _storeLength(value);
                widget.ctrl.scheduleCasingAutoSave(widget.row);
              },
            ),
            _editCell(
              controller: _bit,
              width: _cStd,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: () =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onSubmitted: (_) =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onChanged: (value) {
                widget.row.bit.value = _storeDiameter(value);
                widget.ctrl.scheduleCasingAutoSave(widget.row);
              },
            ),
            _editCell(
              controller: _toc,
              width: _cStd,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: () =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onSubmitted: (_) =>
                  unawaited(widget.ctrl.flushPendingCasingSave()),
              onChanged: (value) {
                widget.row.toc.value = _storeLength(value);
                widget.ctrl.scheduleCasingAutoSave(widget.row);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCasingRow extends StatefulWidget {
  final int index;
  final UgStController ctrl;
  final bool locked;
  final bool selected;
  final Map<String, String>? clipboard;
  final ValueChanged<Map<String, String>> onCopied;
  final VoidCallback onSelected;

  const _DraftCasingRow({
    super.key,
    required this.index,
    required this.ctrl,
    required this.locked,
    required this.selected,
    required this.clipboard,
    required this.onCopied,
    required this.onSelected,
  });

  @override
  State<_DraftCasingRow> createState() => _DraftCasingRowState();
}

class _DraftCasingRowState extends State<_DraftCasingRow>
    with WidgetsBindingObserver {
  late final TextEditingController _desc;
  late final TextEditingController _od;
  late final TextEditingController _wt;
  late final TextEditingController _id;
  late final TextEditingController _top;
  late final TextEditingController _shoe;
  late final TextEditingController _bit;
  late final TextEditingController _toc;
  late final FocusNode _descFocus;
  late final FocusNode _odFocus;
  late final FocusNode _wtFocus;
  late final FocusNode _idFocus;
  late final FocusNode _topFocus;
  late final FocusNode _shoeFocus;
  late final FocusNode _bitFocus;
  late final FocusNode _tocFocus;
  String _type = '';
  Timer? _timer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _desc = TextEditingController();
    _od = TextEditingController();
    _wt = TextEditingController();
    _id = TextEditingController();
    _top = TextEditingController();
    _shoe = TextEditingController();
    _bit = TextEditingController();
    _toc = TextEditingController();
    _descFocus = FocusNode();
    _odFocus = FocusNode();
    _wtFocus = FocusNode();
    _idFocus = FocusNode();
    _topFocus = FocusNode();
    _shoeFocus = FocusNode();
    _bitFocus = FocusNode();
    _tocFocus = FocusNode();
    for (final focusNode in [
      _descFocus,
      _odFocus,
      _wtFocus,
      _idFocus,
      _topFocus,
      _shoeFocus,
      _bitFocus,
      _tocFocus,
    ]) {
      focusNode.addListener(() {
        if (!focusNode.hasFocus) {
          _flushPendingSave();
        }
      });
    }
  }

  void _flushPendingSave() {
    _timer?.cancel();
    _timer = null;
    if (_hasData && !_isSaving) {
      unawaited(_save());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _flushPendingSave();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushPendingSave();
    _descFocus.dispose();
    _odFocus.dispose();
    _wtFocus.dispose();
    _idFocus.dispose();
    _topFocus.dispose();
    _shoeFocus.dispose();
    _bitFocus.dispose();
    _tocFocus.dispose();
    _desc.dispose();
    _od.dispose();
    _wt.dispose();
    _id.dispose();
    _top.dispose();
    _shoe.dispose();
    _bit.dispose();
    _toc.dispose();
    super.dispose();
  }

  bool get _hasData =>
      _desc.text.trim().isNotEmpty ||
      _type.trim().isNotEmpty ||
      _od.text.trim().isNotEmpty ||
      _wt.text.trim().isNotEmpty ||
      _id.text.trim().isNotEmpty ||
      _top.text.trim().isNotEmpty ||
      _shoe.text.trim().isNotEmpty ||
      _bit.text.trim().isNotEmpty ||
      _toc.text.trim().isNotEmpty;

  Map<String, String> _draftMap() => {
    'description': _desc.text.trim(),
    'type': _type.trim(),
    'od': _od.text.trim(),
    'wt': _wt.text.trim(),
    'id': _id.text.trim(),
    'top': _top.text.trim(),
    'shoe': _shoe.text.trim(),
    'bit': _bit.text.trim(),
    'toc': _toc.text.trim(),
  };

  void _applyMap(Map<String, String> data) {
    _desc.text = data['description'] ?? '';
    _type = data['type'] ?? '';
    _od.text = data['od'] ?? '';
    _wt.text = data['wt'] ?? '';
    _id.text = data['id'] ?? '';
    _top.text = data['top'] ?? '';
    _shoe.text = data['shoe'] ?? '';
    _bit.text = data['bit'] ?? '';
    _toc.text = data['toc'] ?? '';
    setState(() {});
    _scheduleSave();
  }

  void _scheduleSave() {
    if (widget.locked || !_hasData || _isSaving) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), _save);
  }

  Future<void> _save() async {
    if (widget.locked || !_hasData || _isSaving) return;
    _isSaving = true;
    final row = CasingRow(
      description: _desc.text.trim(),
      type: _type.trim(),
      od: _storeDiameter(_od.text),
      wt: _storeLineDensity(_wt.text),
      id: _storeDiameter(_id.text),
      top: _storeLength(_top.text),
      shoe: _storeLength(_shoe.text),
      bit: _storeDiameter(_bit.text),
      toc: _storeLength(_toc.text),
    );
    final saved = await widget.ctrl.addCasing(row, refresh: false);
    _isSaving = false;
    if (saved && mounted) {
      _clear();
      widget.ctrl.casings.add(row);
    }
  }

  void _clear() {
    _timer?.cancel();
    _desc.clear();
    _od.clear();
    _wt.clear();
    _id.clear();
    _top.clear();
    _shoe.clear();
    _bit.clear();
    _toc.clear();
    setState(() => _type = '');
  }

  Future<void> _showMenu(TapDownDetails details) async {
    widget.onSelected();
    final hasData = _hasData;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _menuItem('cut', 'Cut', 'Ctrl+X', enabled: !widget.locked && hasData),
        _menuItem('copy', 'Copy', 'Ctrl+C', enabled: hasData),
        _menuItem(
          'paste',
          'Paste',
          'Ctrl+V',
          enabled: !widget.locked && widget.clipboard != null,
        ),
        _menuItem(
          'delete',
          'Delete',
          'Delete',
          enabled: !widget.locked && hasData,
        ),
        const PopupMenuDivider(),
        _menuItem('top', 'To the Top', 'Ctrl+Up', enabled: false),
        _menuItem('bottom', 'To the Bottom', 'Ctrl+Down', enabled: false),
      ],
    );

    if (action == null) return;
    switch (action) {
      case 'cut':
        widget.onCopied(_draftMap());
        await Clipboard.setData(
          ClipboardData(text: _draftMap().values.join('\n')),
        );
        _clear();
        break;
      case 'copy':
        widget.onCopied(_draftMap());
        await Clipboard.setData(
          ClipboardData(text: _draftMap().values.join('\n')),
        );
        break;
      case 'paste':
        if (widget.clipboard != null) {
          _applyMap(widget.clipboard!);
        }
        break;
      case 'delete':
        _clear();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.locked ? _cLocked : Colors.white;
    final topReadOnly = widget.locked || _isCasingType(_type);
    final topBg = topReadOnly ? _cLocked : Colors.white;
    return Container(
      color: Colors.white,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelected,
        onSecondaryTapDown: _showMenu,
        child: Row(
          children: [
            _indexCell(widget.index, widget.selected),
            _editCell(
              controller: _desc,
              width: _cDesc,
              focusNode: _descFocus,
              readOnly: widget.locked,
              bg: bg,
              onTap: widget.onSelected,
              onEditingComplete: _flushPendingSave,
              onSubmitted: (_) => _flushPendingSave(),
              onChanged: (_) => _scheduleSave(),
            ),
            _typeCell(
              width: _cType,
              value: _type,
              readOnly: widget.locked,
              bg: bg,
              onTap: widget.onSelected,
              onChanged: (value) {
                _type = value ?? '';
                _scheduleSave();
                setState(() {});
              },
            ),
            _editCell(
              controller: _od,
              width: _cStd,
              focusNode: _odFocus,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: _flushPendingSave,
              onSubmitted: (_) => _flushPendingSave(),
              onChanged: (_) => _scheduleSave(),
            ),
            _editCell(
              controller: _wt,
              width: _cStd,
              focusNode: _wtFocus,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: _flushPendingSave,
              onSubmitted: (_) => _flushPendingSave(),
              onChanged: (_) => _scheduleSave(),
            ),
            _editCell(
              controller: _id,
              width: _cStd,
              focusNode: _idFocus,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: _flushPendingSave,
              onSubmitted: (_) => _flushPendingSave(),
              onChanged: (_) => _scheduleSave(),
            ),
            _editCell(
              controller: _top,
              width: _cStd,
              focusNode: _topFocus,
              readOnly: topReadOnly,
              bg: topBg,

              onTap: widget.onSelected,
              onEditingComplete: _flushPendingSave,
              onSubmitted: (_) => _flushPendingSave(),
              onChanged: (_) => _scheduleSave(),
            ),
            _editCell(
              controller: _shoe,
              width: _cStd,
              focusNode: _shoeFocus,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: _flushPendingSave,
              onSubmitted: (_) => _flushPendingSave(),
              onChanged: (_) => _scheduleSave(),
            ),
            _editCell(
              controller: _bit,
              width: _cStd,
              focusNode: _bitFocus,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: _flushPendingSave,
              onSubmitted: (_) => _flushPendingSave(),
              onChanged: (_) => _scheduleSave(),
            ),
            _editCell(
              controller: _toc,
              width: _cStd,
              focusNode: _tocFocus,
              readOnly: widget.locked,
              bg: bg,

              onTap: widget.onSelected,
              onEditingComplete: _flushPendingSave,
              onSubmitted: (_) => _flushPendingSave(),
              onChanged: (_) => _scheduleSave(),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isCasingType(String value) => value.trim().toLowerCase() == 'casing';

PopupMenuItem<String> _menuItem(
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
        Text(
          label,
          style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11, color: color),
        ),
        const SizedBox(width: 20),
        Text(
          shortcut,
          style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11, color: color),
        ),
      ],
    ),
  );
}

Widget _indexCell(int index, bool selected) {
  return Container(
    width: _cIdx,
    height: _cRowH,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(
        right: BorderSide(color: _cBorder),
        bottom: BorderSide(color: _cBorder),
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 12,
          child: selected
              ? const Icon(
                  Icons.play_arrow_rounded,
                  size: 11,
                  color: Color(0xFF5B6470),
                )
              : null,
        ),
        Expanded(
          child: Text(
            '${index + 1}',
            textAlign: TextAlign.center,
            style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

Widget _editCell({
  required TextEditingController controller,
  required double width,
  required bool readOnly,
  required Color bg,
  required VoidCallback onTap,
  required ValueChanged<String> onChanged,
  FocusNode? focusNode,
  VoidCallback? onEditingComplete,
  ValueChanged<String>? onSubmitted,
  TextAlign align = TextAlign.left,
}) {
  return Container(
    width: width,
    height: _cRowH,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      border: const Border(
        right: BorderSide(color: _cBorder),
        bottom: BorderSide(color: _cBorder),
      ),
    ),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      textAlign: align,
      style: const TextStyle(
fontSize: 11,
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
    ),
  );
}

Widget _typeCell({
  required double width,
  required String value,
  required bool readOnly,
  required Color bg,
  required VoidCallback onTap,
  required ValueChanged<String?> onChanged,
}) {
  const options = ['', 'Casing', 'Liner'];
  final selectedValue = options.contains(value) ? value : '';

  return Container(
    width: width,
    height: _cRowH,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: bg,
      border: const Border(
        right: BorderSide(color: _cBorder),
        bottom: BorderSide(color: _cBorder),
      ),
    ),
    child: readOnly
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              selectedValue,
              style: const TextStyle(
fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isDense: true,
              isExpanded: true,
              onTap: onTap,
              icon: const Icon(Icons.arrow_drop_down, size: 16),
              style: const TextStyle(
fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
              items: options
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
fontSize: 11,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
  );
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
