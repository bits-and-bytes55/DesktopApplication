import 'package:get/get.dart';

class TabularDatabaseController extends GetxController {
  // Selected values
  var selectedTypeIndex = 0.obs;

  // LEFT TABLE DATA
  final types = [
    'CWS',
    'CWS w/ FICD',
    'ECL',
    'Drill Pipe Premium',
    'Heavy Weight DP',
    'Drill Collar',
    'Tubing',
    'Casing',
  ];

  final catalogs = ['Weatherford'];
  final ods = ['2.720', '2.730', '3.080', '3.220'];
  final weights = ['0.000'];
  final grades = ['Super weld'];

  // RIGHT TABLE DATA BASED ON TYPE
  final Map<String, List<Map<String, RxString>>> tableData = {
    'CWS': List.generate(20, (i) => {
          'bodyId': '1.995'.obs,
          'yield': '227761'.obs,
          'connType': 'Various'.obs,
          'connOd': '2.820'.obs,
          'connId': '1.995'.obs,
          'adjWt': '7.900'.obs,
        }),
    'Tubing': List.generate(10, (i) => {
          'bodyId': '2.100'.obs,
          'yield': '198000'.obs,
          'connType': 'Premium'.obs,
          'connOd': '3.000'.obs,
          'connId': '2.100'.obs,
          'adjWt': '8.200'.obs,
        }),
  };

  List<Map<String, RxString>> get currentTable =>
      tableData[types[selectedTypeIndex.value]] ?? [];
}
