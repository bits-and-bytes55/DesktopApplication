import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/tabular_database.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// ── Column widths ─────────────────────────────────────────────
const double _wIdx = 36.0;
const double _wDesc = 150.0;
const double _wType = 90.0;
const double _wStd = 76.0; // OD, Wt, ID, Top, Shoe, Bit, TOC  (7 cols)
const double _wAct = 90.0;
const double _totalW = _wIdx + _wDesc + _wType + (_wStd * 7) + _wAct + 12;

const double _rowH = 30.0;
const double _headH = 36.0;
const int _emptyRows = 10;

// ── No-border input decoration ────────────────────────────────
const InputDecoration _noBorder = InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
);

class CasingView extends StatefulWidget {
  const CasingView({super.key});

  @override
  State<CasingView> createState() => _CasingViewState();
}

class _CasingViewState extends State<CasingView> {
  late final UgStController c;
  final _vScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    c = Get.find<UgStController>();
  }

  @override
  void dispose() {
    _vScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolbar(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              primary: false,
              child: SizedBox(
                width: _totalW,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: [
                        _headerRow(),
                        Expanded(child: _body()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOOLBAR ────────────────────────────────────────────────
  Widget _toolbar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppTheme.headerGradient,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.bubble_chart, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                "Casing Configuration",
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${c.casings.length} casings",
                    style: AppTheme.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Tooltip(
          message: "Tubular Database",
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => Get.to(() => TabularDatabaseView()),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.table_chart_outlined,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── HEADER ─────────────────────────────────────────────────
  Widget _headerRow() {
    return Container(
      height: _headH,
      decoration: BoxDecoration(gradient: AppTheme.headerGradient),
      child: Row(
        children: [
          _hc('#', _wIdx),
          _hDiv(),
          _hc('Description', _wDesc),
          _hDiv(),
          _hc('Type', _wType),
          _hDiv(),
          _hc('OD\n(in)', _wStd),
          _hDiv(),
          _hc('Wt.\n(lb/ft)', _wStd),
          _hDiv(),
          _hc('ID\n(in)', _wStd),
          _hDiv(),
          _hc('Top\n(m)', _wStd),
          _hDiv(),
          _hc('Shoe\n(m)', _wStd),
          _hDiv(),
          _hc('Bit\n(in)', _wStd),
          _hDiv(),
          _hc('TOC\n(m)', _wStd),
          _hDiv(),
          _hc('Actions', _wAct),
        ],
      ),
    );
  }

  Widget _hc(String label, double w) => SizedBox(
    width: w,
    child: Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTheme.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          height: 1.3,
        ),
      ),
    ),
  );

  Widget _hDiv() => Container(
    width: 1,
    height: _headH,
    color: Colors.white.withOpacity(0.25),
  );

  // ── BODY ───────────────────────────────────────────────────
  Widget _body() {
    return Scrollbar(
      controller: _vScroll,
      thumbVisibility: true,
      child: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final db = c.casings;
        final dbLen = db.length;
        final total = dbLen + _emptyRows;

        return ListView.builder(
          controller: _vScroll,
          itemCount: total,
          itemExtent: _rowH,
          itemBuilder: (context, i) {
            if (i < dbLen) {
              return _DataRow(
                key: ValueKey(db[i].dbId ?? 'db_$i'),
                index: i,
                row: db[i],
                isEven: i.isEven,
                ctrl: c,
              );
            }
            return _EmptyRow(
              key: ValueKey('empty_$i'),
              index: i,
              isEven: i.isEven,
              ctrl: c,
            );
          },
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared cell helpers
// ─────────────────────────────────────────────────────────────

Widget _vDiv() =>
    Container(width: 1, height: _rowH, color: Colors.grey.shade200);

Widget _textCell(String text, double w, {bool grey = false}) => SizedBox(
  width: w,
  height: _rowH,
  child: Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTheme.caption.copyWith(
        fontSize: 11,
        color: grey ? Colors.grey.shade400 : AppTheme.textPrimary,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  ),
);

Widget _lockedCell(double w) =>
    Container(width: w, height: _rowH, color: const Color(0xFFF0F0F0));

Widget _inputCell(
  TextEditingController ctrl,
  double w,
  RxString rx, {
  VoidCallback? onEdited,
}) => SizedBox(
  width: w,
  height: _rowH,
  child: TextField(
    controller: ctrl,
    onChanged: (v) {
      rx.value = v;
      onEdited?.call();
    },
    textAlign: TextAlign.center,
    style: AppTheme.caption.copyWith(fontSize: 11, color: AppTheme.textPrimary),
    decoration: _noBorder,
  ),
);

Widget _inputCellPlain(TextEditingController ctrl, double w) => SizedBox(
  width: w,
  height: _rowH,
  child: TextField(
    controller: ctrl,
    textAlign: TextAlign.center,
    style: AppTheme.caption.copyWith(fontSize: 11, color: AppTheme.textPrimary),
    decoration: _noBorder,
  ),
);

// ─────────────────────────────────────────────────────────────
//  _DataRow
// ─────────────────────────────────────────────────────────────
class _DataRow extends StatefulWidget {
  final int index;
  final CasingRow row;
  final bool isEven;
  final UgStController ctrl;

  const _DataRow({
    super.key,
    required this.index,
    required this.row,
    required this.isEven,
    required this.ctrl,
  });

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  late final TextEditingController _desc,
      _od,
      _wt,
      _id,
      _top,
      _shoe,
      _bit,
      _toc;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    _desc = TextEditingController(text: r.description.value);
    _od = TextEditingController(text: r.od.value);
    _wt = TextEditingController(text: r.wt.value);
    _id = TextEditingController(text: r.id.value);
    _top = TextEditingController(text: r.top.value);
    _shoe = TextEditingController(text: r.shoe.value);
    _bit = TextEditingController(text: r.bit.value);
    _toc = TextEditingController(text: r.toc.value);
  }

  @override
  void dispose() {
    for (final c in [_desc, _od, _wt, _id, _top, _shoe, _bit, _toc]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final c = widget.ctrl;
    final bg = widget.isEven ? Colors.white : const Color(0xFFF7F9FC);

    return Obx(() {
      final locked = c.isLocked.value;
      final isLiner = r.type.value == 'Liner';

      return Container(
        height: _rowH,
        color: bg,
        foregroundDecoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
          ),
        ),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => c.selectCasingForDelete(r),
          child: Row(
            children: [
              // #
              SizedBox(
                width: _wIdx,
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: AppTheme.caption.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _vDiv(),
              locked
                  ? _textCell(r.description.value, _wDesc)
                  : _inputCell(
                      _desc,
                      _wDesc,
                      r.description,
                      onEdited: () => c.scheduleCasingAutoSave(r),
                    ),
              _vDiv(),
              _typeCell(r, locked),
              _vDiv(),
              locked
                  ? _textCell(r.od.value, _wStd)
                  : _inputCell(
                      _od,
                      _wStd,
                      r.od,
                      onEdited: () => c.scheduleCasingAutoSave(r),
                    ),
              _vDiv(),
              locked
                  ? _textCell(r.wt.value, _wStd)
                  : _inputCell(
                      _wt,
                      _wStd,
                      r.wt,
                      onEdited: () => c.scheduleCasingAutoSave(r),
                    ),
              _vDiv(),
              locked
                  ? _textCell(r.id.value, _wStd)
                  : _inputCell(
                      _id,
                      _wStd,
                      r.id,
                      onEdited: () => c.scheduleCasingAutoSave(r),
                    ),
              _vDiv(),
              // Top — editable only for Liner
              if (locked)
                _textCell(isLiner ? r.top.value : '', _wStd, grey: !isLiner)
              else if (isLiner)
                _inputCell(
                  _top,
                  _wStd,
                  r.top,
                  onEdited: () => c.scheduleCasingAutoSave(r),
                )
              else
                _lockedCell(_wStd),
              _vDiv(),
              locked
                  ? _textCell(r.shoe.value, _wStd)
                  : _inputCell(
                      _shoe,
                      _wStd,
                      r.shoe,
                      onEdited: () => c.scheduleCasingAutoSave(r),
                    ),
              _vDiv(),
              locked
                  ? _textCell(r.bit.value, _wStd)
                  : _inputCell(
                      _bit,
                      _wStd,
                      r.bit,
                      onEdited: () => c.scheduleCasingAutoSave(r),
                    ),
              _vDiv(),
              locked
                  ? _textCell(r.toc.value, _wStd)
                  : _inputCell(
                      _toc,
                      _wStd,
                      r.toc,
                      onEdited: () => c.scheduleCasingAutoSave(r),
                    ),
              _vDiv(),
              SizedBox(width: _wAct, child: _actionsCell(r, c)),
            ],
          ),
        ),
      );
    });
  }

  Widget _typeCell(CasingRow r, bool locked) {
    const opts = ['', 'Casing', 'Liner'];
    final val = opts.contains(r.type.value) ? r.type.value : '';

    if (locked) return _textCell(val, _wType);

    return SizedBox(
      width: _wType,
      height: _rowH,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          style: AppTheme.caption.copyWith(
            fontSize: 11,
            color: AppTheme.textPrimary,
          ),
          alignment: Alignment.center,
          items: [
            const DropdownMenuItem(value: '', child: SizedBox.shrink()),
            ...['Casing', 'Liner'].map(
              (o) => DropdownMenuItem(
                value: o,
                child: Center(
                  child: Text(
                    o,
                    style: AppTheme.caption.copyWith(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          onChanged: (v) {
            r.type.value = v ?? '';
            if (v == 'Casing') {
              r.top.value = '';
              _top.clear();
            }
            widget.ctrl.scheduleCasingAutoSave(r);
          },
        ),
      ),
    );
  }

  Widget _actionsCell(CasingRow row, UgStController c) {
    return Obx(() {
      final selected = c.selectedCasingDeleteKey.value == c.casingRowKey(row);
      if (!selected) return const SizedBox.shrink();

      return Center(
        child: Tooltip(
          message: 'Delete',
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => row.dbId != null
                ? c.deleteCasing(row.dbId!)
                : c.casings.remove(row),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                size: 15,
                color: Colors.red.shade400,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  _EmptyRow
// ─────────────────────────────────────────────────────────────
class _EmptyRow extends StatefulWidget {
  final int index;
  final bool isEven;
  final UgStController ctrl;

  const _EmptyRow({
    super.key,
    required this.index,
    required this.isEven,
    required this.ctrl,
  });

  @override
  State<_EmptyRow> createState() => _EmptyRowState();
}

class _EmptyRowState extends State<_EmptyRow> {
  late final TextEditingController _desc,
      _od,
      _wt,
      _id,
      _top,
      _shoe,
      _bit,
      _toc;
  String _selType = '';
  Timer? _autoSaveTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController();
    _od = TextEditingController();
    _wt = TextEditingController();
    _id = TextEditingController();
    _top = TextEditingController();
    _shoe = TextEditingController();
    _bit = TextEditingController();
    _toc = TextEditingController();
    for (final c in [_desc, _od, _wt, _id, _top, _shoe, _bit, _toc]) {
      c.addListener(_scheduleAutoSave);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    for (final c in [_desc, _od, _wt, _id, _top, _shoe, _bit, _toc]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasData =>
      [_desc, _od, _wt, _id, _shoe, _bit, _toc].any((c) => c.text.isNotEmpty) ||
      (_selType == 'Liner' && _top.text.isNotEmpty) ||
      _selType.isNotEmpty;

  void _scheduleAutoSave() {
    if (widget.ctrl.isLocked.value || !_hasData) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 850), _save);
  }

  Future<void> _save() async {
    if (!_hasData || _isSaving || widget.ctrl.isLocked.value) return;
    _isSaving = true;
    final saved = await widget.ctrl.addCasing(
      CasingRow(
        description: _desc.text,
        type: _selType,
        od: _od.text,
        wt: _wt.text,
        id: _id.text,
        top: _selType == 'Liner' ? _top.text : '',
        shoe: _shoe.text,
        bit: _bit.text,
        toc: _toc.text,
      ),
    );
    _isSaving = false;
    if (saved && mounted) {
      _clearInputs();
    }
  }

  void _clearInputs() {
    _autoSaveTimer?.cancel();
    for (final c in [_desc, _od, _wt, _id, _top, _shoe, _bit, _toc]) {
      c.clear();
    }
    setState(() => _selType = '');
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.ctrl;
    final bg = widget.isEven ? Colors.white : const Color(0xFFF7F9FC);

    return Obx(() {
      final locked = c.isLocked.value;
      final isLiner = _selType == 'Liner';

      return Container(
        height: _rowH,
        color: bg,
        foregroundDecoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _wIdx,
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: AppTheme.caption.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            _vDiv(),
            locked ? SizedBox(width: _wDesc) : _inputCellPlain(_desc, _wDesc),
            _vDiv(),
            _emptyTypeCell(locked),
            _vDiv(),
            locked ? SizedBox(width: _wStd) : _inputCellPlain(_od, _wStd),
            _vDiv(),
            locked ? SizedBox(width: _wStd) : _inputCellPlain(_wt, _wStd),
            _vDiv(),
            locked ? SizedBox(width: _wStd) : _inputCellPlain(_id, _wStd),
            _vDiv(),
            if (locked)
              SizedBox(width: _wStd)
            else if (isLiner)
              _inputCellPlain(_top, _wStd)
            else
              _lockedCell(_wStd),
            _vDiv(),
            locked ? SizedBox(width: _wStd) : _inputCellPlain(_shoe, _wStd),
            _vDiv(),
            locked ? SizedBox(width: _wStd) : _inputCellPlain(_bit, _wStd),
            _vDiv(),
            locked ? SizedBox(width: _wStd) : _inputCellPlain(_toc, _wStd),
            _vDiv(),
            SizedBox(width: _wAct, child: const SizedBox.shrink()),
          ],
        ),
      );
    });
  }

  Widget _emptyTypeCell(bool locked) {
    if (locked) return SizedBox(width: _wType);

    return SizedBox(
      width: _wType,
      height: _rowH,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selType,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          alignment: Alignment.center,
          style: AppTheme.caption.copyWith(
            fontSize: 11,
            color: AppTheme.textPrimary,
          ),
          items: [
            const DropdownMenuItem(value: '', child: SizedBox.shrink()),
            ...['Casing', 'Liner'].map(
              (o) => DropdownMenuItem(
                value: o,
                child: Center(
                  child: Text(
                    o,
                    style: AppTheme.caption.copyWith(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() {
            _selType = v ?? '';
            if (_selType == 'Casing') _top.clear();
            _scheduleAutoSave();
          }),
        ),
      ),
    );
  }
}
