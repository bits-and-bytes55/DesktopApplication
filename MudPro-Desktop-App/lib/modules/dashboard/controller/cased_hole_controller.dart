import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart' show kControllerWellId;
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class CasedHoleEntry {
  final String? id;
  TextEditingController description;
  TextEditingController od;
  TextEditingController wt;
  TextEditingController idCtrl;
  TextEditingController top;
  TextEditingController shoe;
  TextEditingController length;

  CasedHoleEntry({
    this.id,
    String desc = '',
    String odVal = '',
    String wtVal = '',
    String idVal = '',
    String topVal = '',
    String shoeVal = '',
    String lenVal = '',
  })  : description = TextEditingController(text: desc),
        od = TextEditingController(text: odVal),
        wt = TextEditingController(text: wtVal),
        idCtrl = TextEditingController(text: idVal),
        top = TextEditingController(text: topVal),
        shoe = TextEditingController(text: shoeVal),
        length = TextEditingController(text: lenVal);

  void dispose() {
    description.dispose();
    od.dispose();
    wt.dispose();
    idCtrl.dispose();
    top.dispose();
    shoe.dispose();
    length.dispose();
  }

  bool get hasContent =>
      description.text.trim().isNotEmpty ||
      od.text.trim().isNotEmpty ||
      wt.text.trim().isNotEmpty ||
      idCtrl.text.trim().isNotEmpty ||
      top.text.trim().isNotEmpty ||
      shoe.text.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'recordId': id,
        'description': description.text,
        'od': od.text,
        'wt': wt.text,
        'id': idCtrl.text,
        'top': top.text,
        'shoe': shoe.text,
        'type': '',
        'bit': '',
        'toc': '',
      };
}

class CasedHoleUIController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;

  var entries = <CasedHoleEntry>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  Worker? _wellWorker;
  final List<Worker> _unitWorkers = <Worker>[];
  late String _lengthUnit;
  late String _diameterUnit;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  void onInit() {
    super.onInit();
    _initEmptyRows();
    _lengthUnit = AppUnits.length;
    _diameterUnit = AppUnits.diameter;
    _unitWorkers.addAll([
      ever(AppUnits.controller.unitSystem, (_) => _handleUnitChange()),
      ever(
        AppUnits.controller.selectedCustomSystemId,
        (_) => _handleUnitChange(),
      ),
      ever(AppUnits.controller.customUnits, (_) => _handleUnitChange()),
    ]);
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      fetchTableCasings();
    });
  }

  @override
  void onClose() {
    _wellWorker?.dispose();
    for (final worker in _unitWorkers) {
      worker.dispose();
    }
    for (final e in entries) {
      e.dispose();
    }
    super.onClose();
  }

  void _handleUnitChange() {
    final nextLengthUnit = AppUnits.length;
    final nextDiameterUnit = AppUnits.diameter;
    if (_lengthUnit == nextLengthUnit && _diameterUnit == nextDiameterUnit) {
      return;
    }

    for (final entry in entries) {
      entry.od.text = _convertText(entry.od.text, _diameterUnit, nextDiameterUnit);
      entry.idCtrl.text =
          _convertText(entry.idCtrl.text, _diameterUnit, nextDiameterUnit);
      entry.top.text = _convertText(entry.top.text, _lengthUnit, nextLengthUnit);
      entry.shoe.text = _convertText(entry.shoe.text, _lengthUnit, nextLengthUnit);
      recalcLength(entry);
    }
    entries.refresh();

    _lengthUnit = nextLengthUnit;
    _diameterUnit = nextDiameterUnit;
  }

  String _convertText(String rawValue, String fromUnit, String toUnit) {
    if (rawValue.trim().isEmpty || fromUnit == toUnit) {
      return rawValue;
    }
    final parsed = double.tryParse(rawValue.replaceAll(',', ''));
    if (parsed == null) {
      return rawValue;
    }
    final result = AppUnits.convertValue(parsed, fromUnit, toUnit);
    if (result == null) {
      return rawValue;
    }
    return result
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _initEmptyRows() {
    for (int i = 0; i < 3; i++) {
      final entry = CasedHoleEntry();
      _attachListeners(entry);
      entries.add(entry);
    }
  }

  void _attachListeners(CasedHoleEntry entry) {
    entry.top.addListener(() => recalcLength(entry));
    entry.shoe.addListener(() => recalcLength(entry));
  }

  void recalcLength(CasedHoleEntry e) {
    final topStr = e.top.text.trim().replaceAll(',', '');
    final shoeStr = e.shoe.text.trim().replaceAll(',', '');

    final t = double.tryParse(topStr);
    final s = double.tryParse(shoeStr);

    if (t != null && s != null) {
      final len = (s - t).abs();
      e.length.text = len.toStringAsFixed(1);
    } else {
      e.length.text = '';
    }
    entries.refresh();
  }

  void checkAndAddRow(int rowIndex) {
    if (rowIndex == entries.length - 1) {
      final last = entries[rowIndex];
      final hasContent = last.description.text.isNotEmpty ||
          last.od.text.isNotEmpty ||
          last.wt.text.isNotEmpty ||
          last.idCtrl.text.isNotEmpty ||
          last.top.text.isNotEmpty ||
          last.shoe.text.isNotEmpty;
      if (hasContent) {
        final e = CasedHoleEntry();
        _attachListeners(e);
        entries.add(e);
      }
    }
    entries.refresh();
  }

  void addRowFromCasing(CasingRow casing) {
    final entry = CasedHoleEntry(
      desc: casing.description.value,
      odVal: casing.od.value,
      wtVal: casing.wt.value,
      idVal: casing.id.value,
      topVal: casing.top.value,
      shoeVal: '',
    );

    final emptyIndex = entries.indexWhere((e) =>
        e.description.text.isEmpty &&
        e.od.text.isEmpty &&
        e.wt.text.isEmpty &&
        e.idCtrl.text.isEmpty &&
        e.top.text.isEmpty &&
        e.shoe.text.isEmpty);

    _attachListeners(entry);
    recalcLength(entry);

    if (emptyIndex != -1) {
      entries[emptyIndex].dispose();
      entries[emptyIndex] = entry;
    } else {
      entries.add(entry);
    }

    if (entries.last.hasContent) {
      final empty = CasedHoleEntry();
      _attachListeners(empty);
      entries.add(empty);
    }
    entries.refresh();
  }

  Future<void> fetchTableCasings() async {
    if (kControllerWellId.isEmpty) return;
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('${baseUrl}casing'), headers: _headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];

        if (data.isNotEmpty) {
          for (final e in entries) {
            e.dispose();
          }
          entries.clear();
          for (final item in data) {
            if (item['wellId'] != kControllerWellId) continue;

            final entry = CasedHoleEntry(
              id: item['_id'],
              desc: item['description']?.toString() ?? '',
              odVal: item['od']?.toString() ?? '',
              wtVal: item['wt']?.toString() ?? '',
              idVal: item['id']?.toString() ?? '',
              topVal: item['top']?.toString() ?? '',
              shoeVal: item['shoe']?.toString() ?? '',
            );
            final t = double.tryParse(entry.top.text);
            final s = double.tryParse(entry.shoe.text);
            if (t != null && s != null) {
              entry.length.text = (s - t).toStringAsFixed(1);
            }

            _attachListeners(entry);
            entries.add(entry);
          }
          if (entries.isEmpty) _initEmptyRows();
          if (entries.last.hasContent) {
            final e = CasedHoleEntry();
            _attachListeners(e);
            entries.add(e);
          }
        }
      }
    } catch (e) {
      print('CasedHole fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> saveAll() async {
    if (kControllerWellId.isEmpty) {
      return {'success': false, 'message': 'No backend well selected'};
    }
    isSaving.value = true;
    final List<String> errors = [];
    int successCount = 0;
    try {
      final authRepo = AuthRepository();
      final List<CasedHoleEntry> allRows =
          entries.where((e) => e.hasContent && e.idCtrl.text.trim().isNotEmpty).toList();

      for (final entry in allRows) {
        final payload = entry.toJson();
        payload['wellId'] = kControllerWellId;

        final result = await authRepo.saveCasing(payload);

        if (result['success'] == true) {
          successCount++;
          final data = result['data']?['data'];
          if (data != null && entry.id == null) {
            final newId = data['_id'];
            final rowIndex = entries.indexOf(entry);

            final updated = CasedHoleEntry(
              id: newId,
              desc: entry.description.text,
              odVal: entry.od.text,
              wtVal: entry.wt.text,
              idVal: entry.idCtrl.text,
              topVal: entry.top.text,
              shoeVal: entry.shoe.text,
            );
            final t = double.tryParse(updated.top.text);
            final s = double.tryParse(updated.shoe.text);
            if (t != null && s != null) updated.length.text = (s - t).toStringAsFixed(1);

            _attachListeners(updated);
            entry.dispose();
            if (rowIndex != -1) entries[rowIndex] = updated;
          }
        } else {
          final rowLabel = entry.description.text.trim().isNotEmpty
              ? entry.description.text.trim()
              : 'ID ${entry.idCtrl.text.trim()}';
          errors.add('Failed to save row $rowLabel: ${result['message']}');
        }
      }

      entries.refresh();

      if (errors.isEmpty) {
        return {'success': true, 'message': 'Casing data saved successfully ($successCount items)'};
      } else {
        return {
          'success': successCount > 0,
          'message': 'Casing: $successCount saved, ${errors.length} failed',
          'errors': errors
        };
      }
    } catch (e) {
      print('CasedHole saveAll error: $e');
      return {'success': false, 'message': 'Error saving casing: $e'};
    } finally {
      isSaving.value = false;
    }
  }

}
