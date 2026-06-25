import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class TitrationDialog extends StatefulWidget {
  const TitrationDialog({super.key});

  @override
  State<TitrationDialog> createState() => _TitrationDialogState();
}

class _TitrationDialogState extends State<TitrationDialog> {
  static const _rows = [
    'EDTA (ml)',
    'Silver Nitrate 10k (ml)',
    'Whole Mud Ca (CaOM) (mg/L)',
    'Chlorides Whole Mud (mg/L)',
  ];

  late final List<List<TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _rows.length,
      (_) => List.generate(3, (_) => TextEditingController()),
    );
  }

  @override
  void dispose() {
    for (final row in _controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _titleBar(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: _table(),
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _titleBar(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.tableHeaderBlue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
        border: const Border(bottom: BorderSide(color: AppTheme.tableBorderBlue)),
      ),
      child: Row(
        children: [
          Text(
            'Titration',
            style: AppTheme.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _table() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppTheme.tableBorderBlue)),
      child: Column(
        children: [
          _headerRow(),
          ...List.generate(_rows.length, (index) => _dataRow(index)),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Column(
      children: [
        SizedBox(
          height: 26,
          child: Row(
            children: [
              _cell('', width: 190, header: true),
              Expanded(
                child: _cell('Sample', header: true, center: true),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24,
          child: Row(
            children: [
              _cell('', width: 190, header: true),
              ...List.generate(
                3,
                (i) => Expanded(
                  child: _cell('${i + 1}', header: true, center: true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dataRow(int rowIndex) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          _cell(_rows[rowIndex], width: 190),
          ...List.generate(
            3,
            (sampleIndex) => Expanded(
              child: _inputCell(_controllers[rowIndex][sampleIndex]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    double? width,
    bool header = false,
    bool center = false,
  }) {
    final child = Container(
      alignment: center ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: header ? AppTheme.tableHeaderBlue : AppTheme.readOnlyCell,
        border: Border(
          right: BorderSide(color: AppTheme.tableGridBlue),
          bottom: BorderSide(color: AppTheme.tableGridBlue),
        ),
      ),
      child: Text(
        text,
        style: AppTheme.caption.copyWith(
          fontSize: 11,
          color: AppTheme.textPrimary,
          fontWeight: header ? FontWeight.w700 : FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
    return width == null ? child : SizedBox(width: width, child: child);
  }

  Widget _inputCell(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.calculatedCell,
        border: Border(
          right: BorderSide(color: AppTheme.tableGridBlue),
          bottom: BorderSide(color: AppTheme.tableGridBlue),
        ),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: AppTheme.caption.copyWith(fontSize: 11),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Row(
        children: [
          _button('Calculate', () {}),
          const Spacer(),
          _button('Accept', () => Navigator.of(context).pop()),
          const SizedBox(width: 8),
          _button('Cancel', () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 84,
      height: 28,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: AppTheme.tableBorderBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          foregroundColor: AppTheme.textPrimary,
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
