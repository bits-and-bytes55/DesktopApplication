import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart' show kControllerWellId;

class WellGeneralController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;

  var isLoading = false.obs;
  var isSaving = false.obs;
  var savedId = ''.obs; // ID of currently loaded report record

  // Dynamic IDs
  final currentPadId = ''.obs;
  final currentWellId = ''.obs;
  final wellIdForReport = ''.obs; // The _id of the 'Well' from /api/wells

  // All field values as Rx strings so UI can react
  var wellNameNo = 'UG-0293 ST'.obs;
  var apiWellNo = ''.obs;
  var spudDate = ''.obs;
  var sectionTownshipRange = 'UMM Gudair (UG)'.obs;
  var longitude = ''.obs;
  var latitude = ''.obs;
  var kop = ''.obs;
  var lp = ''.obs;
  var bulkTankSetupFee = ''.obs;
  var memo = ''.obs;

  var reportNo = ''.obs;
  var userReportNo = ''.obs;
  var date = ''.obs;
  var time = ''.obs;
  var engineer = ''.obs;
  var engineer2 = ''.obs;
  var operatorRep = ''.obs;
  var contractorRep = ''.obs;
  var activity = ''.obs;
  var md = ''.obs;
  var tvd = ''.obs;
  var inc = ''.obs;
  var azi = ''.obs;
  var wob = ''.obs;
  var rotWt = ''.obs;
  var soWt = ''.obs;
  var puWt = ''.obs;
  var rpm = ''.obs;
  var rop = ''.obs;
  var offBottomTq = ''.obs;
  var onBottomTq = ''.obs;
  var suctionT = ''.obs;
  var bottomT = ''.obs;
  var interval = ''.obs;
  var fit = ''.obs;
  var formation = ''.obs;
  var additionalFootage = ''.obs;
  var nptTime = ''.obs;
  var nptCost = ''.obs;
  var depthDrilled = ''.obs;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _toJson() => {
        'reportNo': reportNo.value,
        'userReportNo': userReportNo.value,
        'date': date.value,
        'time': time.value,
        'engineer': engineer.value,
        'engineer2': engineer2.value,
        'operatorRep': operatorRep.value,
        'contractorRep': contractorRep.value,
        'activity': activity.value,
        'md': double.tryParse(md.value) ?? 0,
        'tvd': double.tryParse(tvd.value) ?? 0,
        'inc': double.tryParse(inc.value) ?? 0,
        'azi': double.tryParse(azi.value) ?? 0,
        'wob': double.tryParse(wob.value) ?? 0,
        'rotWt': double.tryParse(rotWt.value) ?? 0,
        'soWt': double.tryParse(soWt.value) ?? 0,
        'puWt': double.tryParse(puWt.value) ?? 0,
        'rpm': double.tryParse(rpm.value) ?? 0,
        'rop': double.tryParse(rop.value) ?? 0,
        'offBottomTq': double.tryParse(offBottomTq.value) ?? 0,
        'onBottomTq': double.tryParse(onBottomTq.value) ?? 0,
        'suctionT': double.tryParse(suctionT.value) ?? 0,
        'bottomT': double.tryParse(bottomT.value) ?? 0,
        'interval': interval.value,
        'fit': fit.value,
        'formation': formation.value,
        'additionalFootage': double.tryParse(additionalFootage.value) ?? 0,
        'nptTime': double.tryParse(nptTime.value) ?? 0,
        'nptCost': double.tryParse(nptCost.value) ?? 0,
        'depthDrilled': double.tryParse(depthDrilled.value) ?? 0,
      };

  void _fromJson(Map<String, dynamic> d) {
    savedId.value = d['_id'] ?? '';
    reportNo.value = d['reportNo']?.toString() ?? '';
    userReportNo.value = d['userReportNo']?.toString() ?? '';
    date.value = d['date']?.toString() ?? '';
    time.value = d['time']?.toString() ?? '';
    engineer.value = d['engineer']?.toString() ?? '';
    engineer2.value = d['engineer2']?.toString() ?? '';
    operatorRep.value = d['operatorRep']?.toString() ?? '';
    contractorRep.value = d['contractorRep']?.toString() ?? '';
    activity.value = d['activity']?.toString() ?? '';
    md.value = (d['md'] ?? '').toString();
    tvd.value = (d['tvd'] ?? '').toString();
    inc.value = (d['inc'] ?? '').toString();
    azi.value = (d['azi'] ?? '').toString();
    wob.value = (d['wob'] ?? '').toString();
    rotWt.value = (d['rotWt'] ?? '').toString();
    soWt.value = (d['soWt'] ?? '').toString();
    puWt.value = (d['puWt'] ?? '').toString();
    rpm.value = (d['rpm'] ?? '').toString();
    rop.value = (d['rop'] ?? '').toString();
    offBottomTq.value = (d['offBottomTq'] ?? '').toString();
    onBottomTq.value = (d['onBottomTq'] ?? '').toString();
    suctionT.value = (d['suctionT'] ?? '').toString();
    bottomT.value = (d['bottomT'] ?? '').toString();
    interval.value = d['interval']?.toString() ?? '';
    fit.value = d['fit']?.toString() ?? '';
    formation.value = d['formation']?.toString() ?? '';
    additionalFootage.value = (d['additionalFootage'] ?? '').toString();
    nptTime.value = (d['nptTime'] ?? '').toString();
    nptCost.value = (d['nptCost'] ?? '').toString();
    depthDrilled.value = (d['depthDrilled'] ?? '').toString();
  }

  // ─── FETCH latest record ───────────────────────
  Future<void> fetchLatest() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}well-general/$kControllerWellId'),
        headers: _headers,
      );


print('WellGeneral fetch response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        if (data.isNotEmpty) {
          _fromJson(data.first);
        }
      }
    } catch (e) {
      print('WellGeneral fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── SAVE (create or update) ───────────────────
  Future<Map<String, dynamic>> save() async {
    isSaving.value = true;
    try {
      final authRepo = AuthRepository();
      
      // 1. Ensure we have a Well ID. If not, we might need to create one.
      // Note: In this architecture, usually the Well creation happens when saving 
      // the Well tab for the first time or via a separate 'Create Well' action.
      // For now, we'll ensure we have a wellId before saving the report.
      
      if (currentWellId.value.isEmpty) {
        if (currentPadId.value.isNotEmpty) {
          // Auto-create well if it doesn't exist
          final wellRes = await saveWell(); 
          if (!wellRes['success']) {
            return wellRes;
          }
        } else {
          return {'success': false, 'message': 'No Well ID available. Please create/select a well first.'};
        }
      } else {
        // Update existing well info (longitude, latitude, etc.) to keep it dynamic
        await updateWellStaticInfo();
      }
      final payload = _toJson();
      payload['wellId'] = currentWellId.value;

      final result = await authRepo.saveWellGeneral(payload);

      if (result['success'] == true) {
        final data = result['data']?['data'];
        if (data != null) {
          _fromJson(data);
        }
        return {'success': true, 'message': 'Well General data saved successfully'};
      } else {
        return {
          'success': false, 
          'message': result['message'] ?? 'Failed to save Well General data'
        };
      }
    } catch (e) {
      print('WellGeneral save error: $e');
      return {'success': false, 'message': 'Error saving Well General: $e'};
    } finally {
      isSaving.value = false;
    }
  }

  // ─── SAVE WELL ───────────────────
  Future<Map<String, dynamic>> saveWell() async {
    final authRepo = AuthRepository();
    try {
      if (currentPadId.value.isEmpty) {
        return {'success': false, 'message': 'Cannot create well: Missing Pad ID'};
      }

      final payload = {
        'padId': currentPadId.value,
        'wellNameNo': wellNameNo.value,
        'apiWellNo': apiWellNo.value,
        'spudDate': spudDate.value,
        'sectionTownshipRange': sectionTownshipRange.value,
        'longitude': longitude.value,
        'latitude': latitude.value,
        'kop': double.tryParse(kop.value) ?? 0,
        'lp': double.tryParse(lp.value) ?? 0,
        'bulkTankSetupFee': double.tryParse(bulkTankSetupFee.value) ?? 0,
      };

      final res = await authRepo.createWell(payload);
      if (res['success']) {
        if (res['data'] != null && res['data']['_id'] != null) {
          currentWellId.value = res['data']['_id'];
        }
        return {'success': true, 'message': 'Well created successfully'};
      }
      return {'success': false, 'message': res['message'] ?? 'Failed to create well'};
    } catch (e) {
      return {'success': false, 'message': 'Error creating well: $e'};
    }
  }

  // ─── UPDATE WELL STATIC INFO ───────────────────
  Future<Map<String, dynamic>> updateWellStaticInfo() async {
    final authRepo = AuthRepository();
    try {
      if (currentWellId.value.isEmpty) return {'success': false};

      final payload = {
        'wellNameNo': wellNameNo.value,
        'apiWellNo': apiWellNo.value,
        'spudDate': spudDate.value,
        'sectionTownshipRange': sectionTownshipRange.value,
        'longitude': longitude.value,
        'latitude': latitude.value,
        'kop': double.tryParse(kop.value) ?? 0,
        'lp': double.tryParse(lp.value) ?? 0,
        'bulkTankSetupFee': double.tryParse(bulkTankSetupFee.value) ?? 0,
      };

      return await authRepo.updateWell(currentWellId.value, payload);
    } catch (e) {
      print('Error updating well info: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}