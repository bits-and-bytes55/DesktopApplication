import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart' show kControllerWellId;
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

double _convertCasedDisplayToBase(
  String rawValue, {
  required String displayUnit,
  required String baseUnit,
}) {
  final parsed = double.tryParse(rawValue.trim());
  if (parsed == null) {
    return 0;
  }
  return AppUnits.convertValue(parsed, displayUnit, baseUnit) ?? parsed;
}

String _convertCasedBaseToDisplay(
  dynamic rawValue, {
  required String baseUnit,
  required String displayUnit,
}) {
  if (rawValue == null || rawValue.toString().trim().isEmpty) {
    return '';
  }
  final parsed = double.tryParse(rawValue.toString().trim());
  if (parsed == null) {
    return rawValue.toString();
  }
  final converted =
      AppUnits.convertValue(parsed, baseUnit, displayUnit) ?? parsed;
  if (converted == converted.truncateToDouble()) {
    return converted.truncate().toString();
  }
  return converted
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'\.?0+$'), '');
}

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
        'od': _convertCasedDisplayToBase(
          od.text,
          displayUnit: AppUnits.diameter,
          baseUnit: '(in)',
        ),
        'wt': wt.text,
        'id': _convertCasedDisplayToBase(
          idCtrl.text,
          displayUnit: AppUnits.diameter,
          baseUnit: '(in)',
        ),
        'top': _convertCasedDisplayToBase(
          top.text,
          displayUnit: AppUnits.length,
          baseUnit: '(ft)',
        ),
        'shoe': _convertCasedDisplayToBase(
          shoe.text,
          displayUnit: AppUnits.length,
          baseUnit: '(ft)',
        ),
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
  Worker? _unitMapWorker;
  Worker? _unitSystemWorker;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  void onInit() {
    super.onInit();
    _initEmptyRows();
    _wellWorker = ever<String>(padWellContext.selectedWellId, (_) {
      fetchTableCasings();
    });
    final options = AppUnits.controller;
    _unitMapWorker = ever<dynamic>(options.customUnits, (_) {
      if (kControllerWellId.isNotEmpty) {
        fetchTableCasings();
      }
    });
    _unitSystemWorker = ever<dynamic>(options.unitSystem, (_) {
      if (kControllerWellId.isNotEmpty) {
        fetchTableCasings();
      }
    });
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
    // Trim and remove any commas for safer parsing
    final topStr = e.top.text.trim().replaceAll(',', '');
    final shoeStr = e.shoe.text.trim().replaceAll(',', '');

    final t = double.tryParse(topStr);
    final s = double.tryParse(shoeStr);

    if (t != null && s != null) {
      // Length = Absolute difference between Shoe and Top
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
      final hasContent = last.hasContent;
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
      shoeVal: '', // 🔥 Keep Shoe empty for manual entry
    );
     
    final emptyIndex = entries.indexWhere((e) => 
        e.description.text.isEmpty && e.od.text.isEmpty && e.wt.text.isEmpty &&
        e.idCtrl.text.isEmpty && e.top.text.isEmpty && e.shoe.text.isEmpty);
        
    _attachListeners(entry);
    recalcLength(entry);
    
    if (emptyIndex != -1) {
      entries[emptyIndex].dispose();
      entries[emptyIndex] = entry;
    } else {
      entries.add(entry);
    }
    
    if (entries.isNotEmpty && entries.last.hasContent) {
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
             for (final e in entries) e.dispose();
             entries.clear();
             for (final item in data) {
                // 🔥 ONLY add items that belong to the current Well
                if (item['wellId'] != kControllerWellId) continue;
                
                final entry = CasedHoleEntry(
                  id: item['_id'],
                  desc: item['description']?.toString() ?? '',
                  odVal: _convertCasedBaseToDisplay(
                    item['od'],
                    baseUnit: '(in)',
                    displayUnit: AppUnits.diameter,
                  ),
                  wtVal: item['wt']?.toString() ?? '',
                  idVal: _convertCasedBaseToDisplay(
                    item['id'],
                    baseUnit: '(in)',
                    displayUnit: AppUnits.diameter,
                  ),
                  topVal: _convertCasedBaseToDisplay(
                    item['top'],
                    baseUnit: '(ft)',
                    displayUnit: AppUnits.length,
                  ),
                  shoeVal: _convertCasedBaseToDisplay(
                    item['shoe'],
                    baseUnit: '(ft)',
                    displayUnit: AppUnits.length,
                  ),
                );
                final t = double.tryParse(entry.top.text);
                final s = double.tryParse(entry.shoe.text);
                if (t != null && s != null) entry.length.text = (s - t).toStringAsFixed(1);
                
                _attachListeners(entry);
                entries.add(entry);
             }
             if (entries.isEmpty) _initEmptyRows();
             if (entries.isNotEmpty && entries.last.hasContent) {
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
      // For the Volume Name calculation, we send all rows to the unified POST endpoint
      final List<CasedHoleEntry> allRows =
          entries.where((e) => e.hasContent).toList();
      
      for (final entry in allRows) {
        final payload = entry.toJson();
        payload['wellId'] = kControllerWellId;
        
        final result = await authRepo.saveCasing(payload);
        
        if (result['success'] == true) {
          successCount++;
          // auth_repo returns {success, data: {success, data, message}}
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

  @override
  void onClose() {
    _wellWorker?.dispose();
    _unitMapWorker?.dispose();
    _unitSystemWorker?.dispose();
    for (final e in entries) e.dispose();
    super.onClose();
  }
}
