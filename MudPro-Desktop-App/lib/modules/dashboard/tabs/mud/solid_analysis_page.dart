import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SolidAnalysisDialog extends StatefulWidget {
  const SolidAnalysisDialog({super.key});

  @override
  State<SolidAnalysisDialog> createState() => _SolidAnalysisDialogState();
}

class _SolidAnalysisDialogState extends State<SolidAnalysisDialog> {
  late MudController c;

  @override
  void initState() {
    super.initState();
    c = Get.find<MudController>();
    // Trigger a fresh save+fetch for all 3 samples when dialog opens.
    // If values already exist (auto-saved in background), this is a no-op for
    // samples whose debounce timer already fired. For samples where MW is still
    // blank, it skips automatically.
    WidgetsBinding.instance.addPostFrameCallback((_) => c.fetchSolidAnalysis());
  }

  // ─── Row definitions ───────────────────────────────────────────────────────

  static const _wbmRows = [
    _RowCfg('LGS (%)',              highlight: true,  lgsCheck: true),
    _RowCfg('LGS (lb/bbl)',         highlight: false),
    _RowCfg('HGS (%)',              highlight: false),
    _RowCfg('Diss Solids (%)',      highlight: false),
    _RowCfg('Corr. Solids (%)',     highlight: false),
    _RowCfg('Brine SG',            highlight: false),
    _RowCfg('HGS (lb/bbl)',        highlight: false),
    _RowCfg('Bentonite (%)',        highlight: false),
    _RowCfg('Bentonite (lb/bbl)',   highlight: false),
    _RowCfg('Drill Solids (%)',     highlight: true),
    _RowCfg('Drill Solids (lb/bbl)', highlight: false),
    _RowCfg('DS/Bent Ratio',        highlight: true,  dsCheck: true),
    _RowCfg('Avg. SG of Solids',   highlight: false),
  ];

  static const _obmRows = [
    _RowCfg('LGS (%)', highlight: false),
    _RowCfg('LGS (lb/bbl)', highlight: false),
    _RowCfg('HGS (%)', highlight: false),
    _RowCfg('HGS (lb/bbl)', highlight: false),
    _RowCfg('OBM Chemicals (%)', highlight: false),
    _RowCfg('OBM Chemicals (lb/bbl)', highlight: false),
    _RowCfg('Drill Solids (%)', highlight: false),
    _RowCfg('Drill Solids (lb/bbl)', highlight: false),
    _RowCfg('DS/Bent Ratio', highlight: false),
    _RowCfg('Avg. SG of Solids', highlight: false),
  ];

  List<_RowCfg> get _rows {
    final fluid = c.selectedFluidType.value.toLowerCase();
    return fluid.contains('oil') ? _obmRows : _wbmRows;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: SizedBox(
        width: 660,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _header(context),
          _body(),
          _footer(context),
        ]),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6), topRight: Radius.circular(6)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          const Icon(Icons.science_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text('Solids Analysis',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        Row(children: [
          // Save-status dots — one per sample
          ...List.generate(3, (i) => Obx(() {
                final status = c.solidSaveStatus['$i']?.value ?? 'idle';
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: 'Sample ${i + 1}: $status',
                    child: _statusDot(status),
                  ),
                );
              })),
          const SizedBox(width: 4),
          // Manual refresh
          Obx(() => c.isSolidAnalysisLoading.value
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Tooltip(
                  message: 'Recalculate',
                  child: InkWell(
                    onTap: () => c.fetchSolidAnalysis(),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.refresh, color: Colors.white, size: 15),
                    ),
                  ),
                )),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ]),
      ]),
    );
  }

  Widget _statusDot(String status) {
    final color = switch (status) {
      'saving' => Colors.amber,
      'saved'  => Colors.greenAccent,
      'error'  => Colors.redAccent,
      _        => Colors.white38,
    };
    return Container(
      width: 7, height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _body() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Obx(() {
        if (c.solidAnalysisError.isNotEmpty && !c.isSolidAnalysisLoading.value) {
          return _errorState();
        }
        if (c.isSolidAnalysisLoading.value && c.solidAnalysisResult.isEmpty) {
          return _skeleton();
        }
        return Obx(() => _table());
      }),
    );
  }

  Widget _errorState() {
    return Column(children: [
      Icon(Icons.error_outline, color: Colors.red.shade400, size: 36),
      const SizedBox(height: 6),
      Text('Calculation failed',
          style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600, fontSize: 12)),
      const SizedBox(height: 4),
      Text(c.solidAnalysisError.value,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10), textAlign: TextAlign.center),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: c.fetchSolidAnalysis,
        icon: const Icon(Icons.refresh, size: 14),
        label: const Text('Retry', style: TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: Size.zero,
        ),
      ),
    ]);
  }

  Widget _skeleton() {
    return Column(children: [
      _tableHeader(),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
        ),
        child: Column(children: List.generate(13, (i) => Container(
          height: 30,
          decoration: BoxDecoration(
            color: i % 2 == 0 ? Colors.white : Colors.grey.shade50,
            border: Border(bottom: BorderSide(
                color: i < 12 ? Colors.grey.shade200 : Colors.transparent)),
          ),
          child: Row(children: [
            _skel(width: 170), _skel(), _skel(), _skel(),
          ]),
        ))),
      ),
    ]);
  }

  Widget _skel({double? width}) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        height: 10,
        decoration: BoxDecoration(
            color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
      ),
    );
    return width != null ? SizedBox(width: width, child: child) : Expanded(child: child);
  }

  Widget _table() {
    return Column(children: [
      _tableHeader(),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
        ),
        child: Column(
          children: _rows.asMap().entries.map((e) {
            final idx  = e.key;
            final row  = e.value;
            final isLast = idx == _rows.length - 1;
            final vals = c.solidAnalysisResult[row.name] ?? ['-', '-', '-'];

            return Container(
              height: 30,
              decoration: BoxDecoration(
                color: row.highlight
                    ? AppTheme.primaryColor.withOpacity(0.04)
                    : (idx % 2 == 0 ? Colors.white : Colors.grey.shade50),
                border: Border(bottom: BorderSide(
                    color: isLast ? Colors.transparent : Colors.grey.shade200)),
              ),
              child: Row(children: [
                // Property name
                SizedBox(
                  width: 170,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey.shade300))),
                    child: Row(children: [
                      if (row.highlight)
                        Container(
                          width: 3, height: 14,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Expanded(
                        child: Text(row.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: row.highlight ? FontWeight.w600 : FontWeight.normal,
                              color: row.highlight ? AppTheme.textPrimary : AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                ),

                // Value cells
                ...List.generate(3, (si) {
                  final raw     = si < vals.length ? vals[si] : '-';
                  final isEmpty = raw == '-';
                  final isErr   = raw == 'Err';
                  final isLast2 = si == 2;

                  Color? textColor;
                  if (!isEmpty && !isErr) {
                    final v = double.tryParse(raw);
                    if (v != null) {
                      if (row.lgsCheck)  textColor = v > 6  ? Colors.red.shade500 : Colors.green.shade600;
                      if (row.dsCheck)   textColor = v > 1  ? Colors.red.shade500 : Colors.green.shade600;
                    }
                  }

                  return Expanded(
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                          border: Border(right: BorderSide(
                              color: isLast2 ? Colors.transparent : Colors.grey.shade200))),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(raw,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: row.highlight ? FontWeight.w600 : FontWeight.normal,
                              color: isErr   ? Colors.red.shade400
                                  : isEmpty ? Colors.grey.shade400
                                  : textColor ?? AppTheme.textPrimary,
                            )),
                      ),
                    ),
                  );
                }),
              ]),
            );
          }).toList(),
        ),
      ),

      // Legend
      if (c.solidAnalysisResult.isNotEmpty &&
          !c.selectedFluidType.value.toLowerCase().contains('oil'))
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            _dot(Colors.green.shade600), const SizedBox(width: 4),
            Text('Within limits', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            const SizedBox(width: 12),
            _dot(Colors.red.shade400), const SizedBox(width: 4),
            Text('Exceeds limit (LGS>6%, DS/Bent>1)',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          ]),
        ),
    ]);
  }

  Widget _tableHeader() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4), topRight: Radius.circular(4)),
      ),
      child: Row(children: [
        SizedBox(
          width: 170,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
            child: Text('Property',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ),
        ),
        ...['1', '2', '3'].asMap().entries.map((e) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                    border: Border(right: BorderSide(
                        color: e.key == 2 ? Colors.transparent : Colors.grey.shade300))),
                child: Text('Sample ${e.value}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ),
            )),
      ]),
    );
  }

  Widget _dot(Color c) =>
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _footer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Text(
            'Auto-calculated from Sample 1–3 inputs (MW, Solids, Oil, Water, Barite, Bentonite). '
            'Updates automatically as values change.',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(width: 12),
        Obx(
          () => c.selectedFluidType.value.toLowerCase().contains('oil')
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: c.fetchSolidAnalysis,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Calculate',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            minimumSize: Size.zero,
          ),
          child: const Text('Close', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ]),
    );
  }
}

// ─── Row config ───────────────────────────────────────────────────────────────

class _RowCfg {
  final String name;
  final bool highlight;
  final bool lgsCheck;
  final bool dsCheck;
  const _RowCfg(this.name, {required this.highlight, this.lgsCheck = false, this.dsCheck = false});
}
