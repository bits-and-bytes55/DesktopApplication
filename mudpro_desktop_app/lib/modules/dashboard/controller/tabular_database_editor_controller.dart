import 'package:get/get.dart';

class TabularDatabaseEditorController extends GetxController {
  // ---------------- LEFT TABLE STATE ----------------
  var selectedTypeIndex = 0.obs;
  var selectedCatalogIndex = 0.obs;

  RxList<String> types = <String>[
    'CWS',
    'CWS w/ FICD',
    'ECL',
    'Drill Pipe Premium',
    'Heavy Weight DP',
    'Tubing',
    'Casing',
  ].obs;

  RxList<String> catalogs = <String>[
    'Weatherford',
  ].obs;

  // ---------------- RIGHT TABLE DATA ----------------
  final RxMap<String, List<Map<String, RxString>>> tableData =
      <String, List<Map<String, RxString>>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _seedInitialData();
  }

  void _seedInitialData() {
    for (final t in types) {
      tableData[t] = _generateRows();
    }
  }

  List<Map<String, RxString>> _generateRows() {
    return List.generate(25, (i) => {
          // BODY (13)
          'od': RxString('2.720'),
          'id': RxString('1.995'),
          'nomWt': RxString('0.000'),
          'wall': RxString(''),
          'drift': RxString(''),
          'grade': RxString('Super Weld'),
          'yield': RxString('227761'),
          'fatigue': RxString(''),
          'uts': RxString(''),
          'collapse': RxString(''),
          'burst': RxString(''),
          'tensile': RxString(''),
          'torsional': RxString(''),

          // CONNECTION (11)
          'cType': RxString('25CR'),
          'cOd': RxString('0.000'),
          'cId': RxString('0.000'),
          'cGrade': RxString('ECL 316L'),
          'cYield': RxString('104283'),
          'cUts': RxString(''),
          'cBurst': RxString(''),
          'cTensile': RxString(''),
          'cComp': RxString(''),
          'cTorsion': RxString(''),
          'makeup': RxString('500'),

          // ASSEMBLY
          'adjWt': RxString('8.500'),
        });
  }

  List<Map<String, RxString>> get currentRows =>
      tableData[types[selectedTypeIndex.value]] ?? [];

  // ---------------- TYPE CRUD ----------------
  void addType(String name) {
    types.add(name);
    tableData[name] = _generateRows();
  }

  void deleteSelectedType() {
    if (types.isEmpty) return;
    final removed = types.removeAt(selectedTypeIndex.value);
    tableData.remove(removed);
    selectedTypeIndex.value = 0;
  }

  // ---------------- CATALOG CRUD ----------------
  void addCatalog(String name) {
    catalogs.add(name);
  }

  void deleteSelectedCatalog() {
    if (catalogs.isEmpty) return;
    catalogs.removeAt(selectedCatalogIndex.value);
    selectedCatalogIndex.value = 0;
  }
}
