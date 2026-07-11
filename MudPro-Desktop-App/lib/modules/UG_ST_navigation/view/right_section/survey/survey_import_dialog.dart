import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/survey_model.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SurveyImportDialog extends StatefulWidget {
  const SurveyImportDialog({super.key});

  @override
  State<SurveyImportDialog> createState() => _SurveyImportDialogState();
}
class _SurveyImportDialogState extends State<SurveyImportDialog>
    with SingleTickerProviderStateMixin {
  final SurveyController controller = Get.find<SurveyController>();
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController startRowController = TextEditingController(
    text: '1',
  );
  final TextEditingController endRowController = TextEditingController(
    text: '1',
  );

  late final TabController tabController = TabController(
    length: 2,
    vsync: this,
  );

  bool decimalPoint = true;
  bool delimiterTab = true;
  bool delimiterSpace = true;
  bool delimiterSemicolon = true;
  bool delimiterComma = true;

  int mdColumn = 1;
  int incColumn = 2;
  int aziColumn = 3;
  String mdUnit = '(ft)';

  List<List<String>> extractedRows = [];

  @override
  void dispose() {
    sourceController.dispose();
    startRowController.dispose();
    endRowController.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: Container(
        width: 1330,
        height: 970,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.tableBorderBlue),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _titleBar(context),
            TabBar(
              controller: tabController,
              isScrollable: true,
              labelColor: Colors.black,
              tabs: const [
                Tab(text: 'Import Text File'),
                Tab(text: 'Import PDF File'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [_body(context), _body(context, pdfMode: true)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleBar(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.tableHeaderBlue,
        border: Border(bottom: BorderSide(color: AppTheme.tableBorderBlue)),
      ),
      child: Row(
        children: [
          Text(
            'Survey Import',
            style: AppTheme.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, {bool pdfMode = false}) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pdfMode
                      ? 'Step 1: Paste extracted PDF text.'
                      : 'Step 1: Open text file or paste copied data.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _smallIconButton(Icons.folder_open, () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        sourceController.text = data!.text!;
                      }
                    }),
                    const SizedBox(width: 6),
                    _smallIconButton(Icons.cleaning_services, () {
                      sourceController.clear();
                      setState(() => extractedRows = []);
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.tableBorderBlue),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 32,
                          color: AppTheme.readOnlyCell,
                          alignment: Alignment.center,
                          child: const Text('Data'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: sourceController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 28),
          SizedBox(width: 260, child: _extractPanel()),
          const SizedBox(width: 28),
          SizedBox(width: 430, child: _previewPanel(context)),
        ],
      ),
    );
  }

  Widget _extractPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 2: Extract', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 12),
        const Text('In the Original Data', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 12),
        _group(
          'Decimal',
          Column(
            children: [
              RadioListTile<bool>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: true,
                groupValue: decimalPoint,
                title: const Text('Decimal Point ( . )'),
                onChanged: (value) =>
                    setState(() => decimalPoint = value ?? true),
              ),
              RadioListTile<bool>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: false,
                groupValue: decimalPoint,
                title: const Text('Decimal Comma ( , )'),
                onChanged: (value) =>
                    setState(() => decimalPoint = value ?? true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const SizedBox(width: 64, child: Text('MD')),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: mdUnit,
                items: const ['(ft)', '(m)']
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => mdUnit = value ?? '(ft)'),
                decoration: const InputDecoration(isDense: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _labeledField('Starting Row', startRowController),
        const SizedBox(height: 10),
        _labeledField('Ending Row', endRowController),
        const SizedBox(height: 12),
        _group(
          'Delimiters',
          Column(
            children: [
              CheckboxListTile(
                dense: true,
                value: delimiterTab,
                title: const Text('Tab'),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => delimiterTab = v ?? true),
              ),
              CheckboxListTile(
                dense: true,
                value: delimiterSpace,
                title: const Text('Space'),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => delimiterSpace = v ?? true),
              ),
              CheckboxListTile(
                dense: true,
                value: delimiterSemicolon,
                title: const Text('Semicolon'),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) =>
                    setState(() => delimiterSemicolon = v ?? true),
              ),
              CheckboxListTile(
                dense: true,
                value: delimiterComma,
                title: const Text('Comma'),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => delimiterComma = v ?? true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _group(
          'Column Index',
          Column(
            children: [
              _indexRow('MD', mdColumn, (v) => setState(() => mdColumn = v)),
              _indexRow('Inc', incColumn, (v) => setState(() => incColumn = v)),
              _indexRow('Azi', aziColumn, (v) => setState(() => aziColumn = v)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: _extractData,
            child: const Text('Extract'),
          ),
        ),
      ],
    );
  }

  Widget _previewPanel(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _actionButton('Accept', extractedRows.isNotEmpty ? _accept : null),
            const SizedBox(width: 10),
            _actionButton('Close', () => Navigator.of(context).pop()),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.tableBorderBlue),
            ),
            child: Column(
              children: [
                Container(
                  height: 32,
                  color: AppTheme.readOnlyCell,
                  child: const Row(
                    children: [
                      SizedBox(width: 46),
                      _HeadCell(width: 120, label: 'MD (ft)'),
                      _HeadCell(width: 120, label: 'Inc (°)'),
                      _HeadCell(width: 120, label: 'Azi (°)'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: extractedRows.length,
                    itemBuilder: (context, index) {
                      final row = extractedRows[index];
                      return SizedBox(
                        height: 34,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 46,
                              child: Center(child: Text('${index + 1}')),
                            ),
                            _BodyCell(width: 120, text: row[0]),
                            _BodyCell(width: 120, text: row[1]),
                            _BodyCell(width: 120, text: row[2]),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _group(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.tableGridBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController field) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(
          child: TextField(
            controller: field,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _indexRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label)),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: value,
            items: List.generate(
              10,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1}'),
              ),
            ),
            onChanged: (selected) => onChanged(selected ?? value),
            decoration: const InputDecoration(isDense: true),
          ),
        ),
      ],
    );
  }

  Widget _smallIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.tableBorderBlue),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF2780E3)),
      ),
    );
  }

  Widget _actionButton(String text, VoidCallback? onTap) {
    return SizedBox(
      width: 118,
      height: 42,
      child: OutlinedButton(onPressed: onTap, child: Text(text)),
    );
  }

  void _extractData() {
    final raw = sourceController.text;
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final start = (int.tryParse(startRowController.text.trim()) ?? 1).clamp(
      1,
      lines.isEmpty ? 1 : lines.length,
    );
    final end = (int.tryParse(endRowController.text.trim()) ?? lines.length)
        .clamp(start, lines.isEmpty ? start : lines.length);

    final delimiters = <String>[
      if (delimiterTab) '\t',
      if (delimiterSpace) ' ',
      if (delimiterSemicolon) ';',
      if (delimiterComma) ',',
    ];
    final pattern = '[${RegExp.escape(delimiters.join())}]+';
    final regex = RegExp(pattern);

    final next = <List<String>>[];
    for (var i = start - 1; i < end; i++) {
      final parts = lines[i]
          .split(regex)
          .where((part) => part.trim().isNotEmpty)
          .toList();
      if (parts.length <
          [mdColumn, incColumn, aziColumn].reduce((a, b) => a > b ? a : b)) {
        continue;
      }
      String normalize(String value) =>
          decimalPoint ? value.trim() : value.trim().replaceAll(',', '.');
      next.add([
        normalize(parts[mdColumn - 1]),
        normalize(parts[incColumn - 1]),
        normalize(parts[aziColumn - 1]),
      ]);
    }

    setState(() => extractedRows = next);
  }

  void _accept() {
    final rows = extractedRows.map((row) {
      return SurveyStationRow(
        md: _convertMdToActiveUnit(row[0]),
        inc: row[1],
        azi: row[2],
      );
    }).toList();
    controller.importSurveyRows(rows);
    Navigator.of(context).pop();
  }

  String _convertMdToActiveUnit(String value) {
    final raw = value.trim();
    if (raw.isEmpty || mdUnit == AppUnits.length) return value;
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null) return value;
    final converted = AppUnits.convertValue(parsed, mdUnit, AppUnits.length);
    if (converted == null) return value;
    return formatOperationNumber(
      converted,
      fallbackDecimals: 4,
      trimFallback: true,
    );
  }
}

class _HeadCell extends StatelessWidget {
  const _HeadCell({required this.width, required this.label});

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.tableBorderBlue)),
      ),
      child: Text(label),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.width, required this.text});

  final double width;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppTheme.tableBorderBlue),
          top: BorderSide(color: AppTheme.tableBorderBlue),
        ),
      ),
      child: Text(text),
    );
  }
}
