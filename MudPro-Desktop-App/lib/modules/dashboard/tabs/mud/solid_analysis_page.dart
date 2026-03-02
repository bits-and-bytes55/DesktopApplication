import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SolidAnalysisDialog extends StatelessWidget {
  const SolidAnalysisDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MudController>();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: 620,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Solids Analysis',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
            ]),
          ),

          // Table
          Obx(() {
            final analysisData = _computeSolidAnalysis(c);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Header
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                  ),
                  child: Row(children: [
                    _headerCell('Property', flex: 3),
                    ...c.samples.take(3).map((s) => _headerCell(s)),
                  ]),
                ),
                // Rows
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
                  ),
                  child: Column(
                    children: analysisData.entries.toList().asMap().entries.map((e) {
                      final idx   = e.key;
                      final entry = e.value;
                      final isLast = idx == analysisData.length - 1;
                      return Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: idx % 2 == 0 ? Colors.white : Colors.grey.shade50,
                          border: Border(bottom: BorderSide(
                            color: isLast ? Colors.transparent : Colors.grey.shade200)),
                        ),
                        child: Row(children: [
                          _dataCell(entry.key, flex: 3),
                          ...entry.value.take(3).map((v) => _dataCell(v)),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              ]),
            );
          }),

          // Close button
          Padding(
            padding: const EdgeInsets.only(bottom: 16, right: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
          ),
        ]),
      ),
    );
  }

  Map<String, List<String>> _computeSolidAnalysis(MudController c) {
    final result = <String, List<String>>{
      'LGS (%)': [],
      'LGS (lb/bbl)': [],
      'HGS (%)': [],
      'Diss Solids (%)': [],
      'Corr. Solids (%)': [],
      'Brine SG': [],
      'HGS (lb/bbl)': [],
      'Bentonite (%)': [],
      'Bentonite (lb/bbl)': [],
      'Drill Solids (%)': [],
      'Drill Solids (lb/bbl)': [],
      'DS/Bent Ratio': [],
      'Avg. SG of Solids': [],
    };

    final oilSg   = double.tryParse(c.oilSgController.text)    ?? 0.80;
    final hgsSg   = double.tryParse(c.hgsSgController.text)    ?? 4.20;
    final lgsSg   = double.tryParse(c.lgsSgController.text)    ?? 2.60;
    final shaleCec = double.tryParse(c.shaleCecController.text) ?? 15.0;
    final bentCec  = double.tryParse(c.bentCecController.text)  ?? 65.0;

    for (int i = 0; i < 3; i++) {
      // Read values from propertyTable Map
      double mw = 0, solids = 0, oil = 0, water = 0, mbtCap = 0;

      for (final entry in c.propertyTable.entries) {
        final name = entry.key.toLowerCase().replaceAll('*', '').trim();
        final vals = entry.value;
        if (i >= vals.length) continue;
        final val = double.tryParse(vals[i].value) ?? 0;

        if (name.contains('mw') || name == 'mud weight') mw = val;
        if (name.contains('solids') && !name.contains('salt') &&
            !name.contains('drill') && !name.contains('adj')) solids = val;
        if (name.contains('oil') && !name.contains('ratio')) oil = val;
        if (name.contains('water') && !name.contains('activity')) water = val;
        if (name.contains('mbt')) mbtCap = val;
      }

      if (mw <= 0) {
        for (var key in result.keys) { result[key]!.add('-'); }
        continue;
      }

      final mwSg      = mw / 8.33;
      final waterFrac = water / 100;
      final oilFrac   = oil / 100;
      final solidsFrac = solids / 100;

      final brineSg   = waterFrac > 0
          ? (mwSg - oilFrac * oilSg - solidsFrac * lgsSg) / waterFrac
          : 1.00;
      final bentonite = bentCec > shaleCec ? (mbtCap / bentCec) * 100 : 0.0;
      final lgs       = solidsFrac * 100;
      final hgsRaw    = (mwSg - waterFrac * brineSg - oilFrac * oilSg - lgs / 100 * lgsSg)
                        / (hgsSg - lgsSg) * 100;
      final hgs       = hgsRaw.clamp(0.0, 100.0);
      final lgsBbl    = lgs * 14.7;
      final hgsBbl    = hgs * 14.7;
      final dissS     = (brineSg - 1) * waterFrac * 100;
      final corrS     = lgs + (dissS > 0 ? dissS : 0);
      final drillS    = (lgs - bentonite).clamp(0.0, 100.0);
      final drillBbl  = drillS * 14.7;
      final bentBbl   = bentonite * 14.7;
      final dsBentR   = bentonite > 0 ? drillS / bentonite : 0.0;
      final avgSg     = (lgs + hgs) > 0
          ? (lgs * lgsSg + hgs * hgsSg) / (lgs + hgs) : 0.0;

      result['LGS (%)']!.add(lgs.toStringAsFixed(1));
      result['LGS (lb/bbl)']!.add(lgsBbl.toStringAsFixed(2));
      result['HGS (%)']!.add(hgs.toStringAsFixed(1));
      result['Diss Solids (%)']!.add(dissS.toStringAsFixed(1));
      result['Corr. Solids (%)']!.add(corrS.toStringAsFixed(1));
      result['Brine SG']!.add(brineSg.toStringAsFixed(2));
      result['HGS (lb/bbl)']!.add(hgsBbl.toStringAsFixed(2));
      result['Bentonite (%)']!.add(bentonite.toStringAsFixed(1));
      result['Bentonite (lb/bbl)']!.add(bentBbl.toStringAsFixed(2));
      result['Drill Solids (%)']!.add(drillS.toStringAsFixed(1));
      result['Drill Solids (lb/bbl)']!.add(drillBbl.toStringAsFixed(2));
      result['DS/Bent Ratio']!.add(dsBentR.toStringAsFixed(2));
      result['Avg. SG of Solids']!.add(avgSg.toStringAsFixed(2));
    }
    return result;
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
        child: Text(text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _dataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
        child: Text(text,
            style: TextStyle(
              fontSize: 10,
              color: text == '-' ? Colors.grey.shade400 : AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }
}