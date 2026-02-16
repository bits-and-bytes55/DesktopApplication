import 'package:get/get.dart';

class PitSnapshotController extends GetxController {
  // Volume Summary Data
  var volumeSummaryData = <Map<String, dynamic>>[
    {'name': 'Hole Vol. Difference', 'volume': '0.00'},
    {'name': 'Hole', 'volume': '0.00'},
    {'name': 'Active Pits', 'volume': '466.79'},
    {'name': 'CKB', 'volume': '0.00'},
    {'name': 'Active System', 'volume': '466.79'},
    {'name': 'End Vol.', 'volume': '0.00'},
    {'name': 'End Vol. - Active System', 'volume': '-466.79'},
    {'name': 'Total Storage', 'volume': '360.00'},
    {'name': 'Total on Location', 'volume': '826.79'},
  ].obs;

  // Pit Concentration Data
  final pitConcentrationData = <Map<String, dynamic>>[
    {'id': 1, 'product': 'BARITE 4.1 - BIG BAG (...', 'unit': '1.50 Ton', 'startConc': '', 'endConc': ''},
    {'id': 2, 'product': 'BENTONITE - TON (lb/bbl)', 'unit': '1.00 Ton', 'startConc': '', 'endConc': ''},
    {'id': 3, 'product': 'CALCIUM CHLORIDE (b...', 'unit': '1.00 Ton', 'startConc': '', 'endConc': ''},
    {'id': 4, 'product': 'CAUSTIC SODA (lb/bbl)', 'unit': '25.00 kg', 'startConc': '', 'endConc': ''},
    {'id': 5, 'product': 'CHROME FREE LIGNO S...', 'unit': '50.00 lb', 'startConc': '', 'endConc': ''},
    {'id': 6, 'product': 'CITRIC ACID (lb/bbl)', 'unit': '25.00 kg', 'startConc': '', 'endConc': ''},
    {'id': 7, 'product': 'DRILLING DETERGENT (...', 'unit': '55.00 gal', 'startConc': '', 'endConc': ''},
    {'id': 8, 'product': 'GILSONITE AQUASOL 3...', 'unit': '50.00 lb', 'startConc': '', 'endConc': ''},
    {'id': 9, 'product': 'GS SEAL (lb/bbl)', 'unit': '25.00 kg', 'startConc': '', 'endConc': ''},
    {'id': 10, 'product': 'HEC (lb/bbl)', 'unit': '25.00 kg', 'startConc': '', 'endConc': ''},
    {'id': 11, 'product': 'LCM MIX COARSE (lb/bbl)', 'unit': '25.00 kg', 'startConc': '', 'endConc': ''},
    {'id': 12, 'product': 'LCM MIX FINE (lb/bbl)', 'unit': '25.00 kg', 'startConc': '', 'endConc': ''},
    {'id': 13, 'product': 'LCM MIX MEDIUM (lb/bbl)', 'unit': '25.00 kg', 'startConc': '', 'endConc': ''},
  ].obs;

  // Active Pits Data
  final activePits = <Map<String, dynamic>>[
    {'name': 'TRIP TANK', 'type': 'active', 'volume': 0.0},
    {'name': 'SANDTRAP # 1A', 'type': 'active', 'volume': 0.0},
    {'name': 'SETTLING # 1B', 'type': 'active', 'volume': 0.0},
    {'name': 'DEGASSER # 1C', 'type': 'active', 'volume': 0.0},
    {'name': 'DESANDER # 2A, 100.00 bbl, Brackish Water', 'type': 'active', 'volume': 100.0},
    {'name': 'DESILTER # 2B, 100.00 bbl, Brackish Water', 'type': 'active', 'volume': 100.0},
    {'name': 'SUCT # 4A, 266.79 bbl, Brackish Water', 'type': 'active', 'volume': 266.79},
  ].obs;

  // Storage Pits Data
  final storagePits = <Map<String, dynamic>>[
    {'name': 'INT # 2C, 110.00 bbl, Brackish Water', 'type': 'storage', 'volume': 110.0},
    {'name': 'INT # 3A', 'type': 'storage', 'volume': 0.0},
    {'name': 'INT # 3B', 'type': 'storage', 'volume': 0.0},
    {'name': 'INT # 3C', 'type': 'storage', 'volume': 0.0},
    {'name': 'SUCT # 4B, 250.00 bbl, Brackish Water', 'type': 'storage', 'volume': 250.0},
  ].obs;

  // Hole Volume Data
  final holeVolumeData = <Map<String, dynamic>>[
    {'name': 'String above ML', 'volume': '0.00'},
    {'name': 'Annulus above ML', 'volume': '0.00'},
    {'name': 'String below ML', 'volume': '0.00'},
    {'name': 'Annulus below ML', 'volume': '0.00'},
    {'name': 'Below bit', 'volume': '0.00'},
    {'name': 'Hole', 'volume': '0.00'},
    {'name': 'Displacement', 'volume': '0.00'},
  ].obs;

  // CKB Volume Data
  final ckbVolumeData = <Map<String, dynamic>>[
    {'name': 'Choke line', 'volume': '0.00'},
    {'name': 'Kill line', 'volume': '0.00'},
    {'name': 'Boost line', 'volume': '0.00'},
  ].obs;

  // Selected dropdown value
  final selectedSystem = 'Active System'.obs;
  final systemOptions = ['Active System', 'INT # 2C', 'INT # 3A', 'INT # 3B', 'INT # 3C', 'SUCT # 4A', 'RES # 5A', 'RES # 5B', 'RES # 6A', 'RES # 6B'].obs;

  // Update methods
  void updateVolumeSummary(int index, String value) {
    volumeSummaryData[index]['volume'] = value;
    volumeSummaryData.refresh();
  }

  void updatePitConcentration(int index, String field, String value) {
    pitConcentrationData[index][field] = value;
    pitConcentrationData.refresh();
  }

  void updateHoleVolume(int index, String value) {
    holeVolumeData[index]['volume'] = value;
    holeVolumeData.refresh();
  }

  void updateCkbVolume(int index, String value) {
    ckbVolumeData[index]['volume'] = value;
    ckbVolumeData.refresh();
  }

  void changeSystem(String value) {
    selectedSystem.value = value;
  }

  // Calculate total active pits volume
  double get totalActivePitsVolume {
    return activePits.fold(0.0, (sum, pit) => sum + (pit['volume'] as double));
  }

  // Calculate total storage volume
  double get totalStorageVolume {
    return storagePits.fold(0.0, (sum, pit) => sum + (pit['volume'] as double));
  }
}