import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

class WellGeneralController extends GetxController {
  final String baseUrl = ApiEndpoint.baseUrl;

  var isLoading = false.obs;
  var isSaving = false.obs;
  var savedId = ''.obs; // ID of currently loaded record

  // All field values as Rx strings so UI can react
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
        Uri.parse('${baseUrl}well-general'),
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
  Future<void> save() async {
    isSaving.value = true;
    try {
      http.Response response;
      if (savedId.value.isNotEmpty) {
        response = await http.put(
          Uri.parse('${baseUrl}well-general/${savedId.value}'),
          headers: _headers,
          body: jsonEncode(_toJson()),
        );
      } else {
        response = await http.post(
          Uri.parse('${baseUrl}well-general'),
          headers: _headers,
          body: jsonEncode(_toJson()),
        );
      }
print('WellGeneral save response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        _fromJson(json['data']);
        Get.snackbar(
          'Saved',
          'Well General data saved successfully',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('WellGeneral save error: $e');
    } finally {
      isSaving.value = false;
    }
  }
}