import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:mudpro_desktop_app/modules/UG/model/formation_row_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/producst_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pump_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/sce_model.dart';

class UgController extends GetxController {
  // Right panel main tab
  final activeRightTab = 'pad'.obs;
   final location = 'Land'.obs;

  // Lock / Unlock
  final isLocked = true.obs;

   final inventoryTab = 'Products'.obs;

  // Apply Changed Prices option
  final applyChangedPricesOption = 'To All'.obs;
  final fromDate = ''.obs;

  // Footer fields
  final bulkTankSetupFee = ''.obs;
  final taxRate = ''.obs;

  // REPORT TAB STATE
final considerROP = true.obs;
final considerRPM = true.obs;
final considerEccentricity = false.obs;

final multiRheology = false.obs;

final safetyMargin = '80.0'.obs;



 // ================= FORMATION =================
  final poreFromTop = true.obs;

  /// Dropdown value (Density / Gradient / Pressure)
  final formationMode = 'Density'.obs;

  /// Formation table rows
  final formations = <FormationRow>[
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
    FormationRow(),
  ].obs;


  // SAMPLE DATA (static for now)
 var products = <ProductModel>[
  ProductModel(
    id: 1,
    product: 'BARITE 4.1 - BIG BAG',
    code: '',
    sg: '4.10',
    unit: '1.50 Ton',
    price: '90.00',
    initial: '',
    group: 'Weight Material',
    volAdd: true,
    calculate: true,
    tax: false,
  ),
  ProductModel(
    id: 2,
    product: 'BENTONITE - TON',
    code: '',
    sg: '2.60',
    unit: '1.00 Ton',
    price: '42.00',
    initial: '',
    group: 'Viscosifier',
    volAdd: true,
    calculate: true,
  ),
  ProductModel(
    id: 3,
    product: 'CALCIUM CHLORIDE',
    code: '',
    sg: '2.16',
    unit: '1.00 Ton',
    price: '124.00',
    initial: '',
    group: 'Common Chemical',
    volAdd: true,
    calculate: true,
  ),
  ProductModel(
    id: 4,
    product: 'CAUSTIC SODA',
    code: '',
    sg: '2.16',
    unit: '25.00 kg',
    price: '5.92',
    initial: '',
    group: 'Common Chemical',
    volAdd: true,
    calculate: true,
  ),
  ProductModel(
    id: 5,
    product: 'CHROME FREE LIGNO SULPH.',
    code: '',
    sg: '1.40',
    unit: '50.00 lb',
    price: '10.00',
    initial: '',
    group: 'WBM Thinner',
    volAdd: true,
    calculate: true,
  ),
  ProductModel(
    id: 6,
    product: 'CITRIC ACID',
    code: '',
    sg: '1.54',
    unit: '25.00 kg',
    price: '12.54',
    initial: '',
    group: 'Common Chemical',
    volAdd: true,
    calculate: true,
  ),
  ProductModel(
    id: 7,
    product: 'DRILLING DETERGENT',
    code: '',
    sg: '1.04',
    unit: '55.00 gal',
    price: '75.00',
    initial: '',
    group: 'Lubricant / Surfactant',
    volAdd: true,
    calculate: true,
  ),
  ProductModel(
    id: 8,
    product: 'GILSONITE AQUASOL 300',
    code: '',
    sg: '1.06',
    unit: '50.00 lb',
    price: '20.00',
    initial: '',
    group: 'Others',
    volAdd: true,
    calculate: true,
  ),
  ProductModel(
    id: 9,
    product: 'GS SEAL',
    code: '',
    sg: '2.25',
    unit: '25.00 kg',
    price: '15.00',
    initial: '',
    group: 'Wellbore Strength',
    volAdd: true,
    calculate: true,
  ),
  ProductModel(
    id: 10,
    product: 'HEC',
    code: '',
    sg: '1.60',
    unit: '25.00 kg',
    price: '88.00',
    initial: '',
    group: 'Viscosifier',
    volAdd: true,
    calculate: true,
  ),
].obs;


 var premixed = <PremixModel>[
  PremixModel(
    id: '1',
    description: '8.0 ppg OBM (70/30) with Bar',
    mw: '8.00',
    leasingFee: '8.64',
    mudType: 'Oil-based',
  ),
  PremixModel(
    id: '2',
    description: '10.6 ppg OBM (70/30) with Bar',
    mw: '10.60',
    leasingFee: '11.59',
    mudType: 'Oil-based',
  ),
  PremixModel(
    id: '3',
    description: '11.0 ppg OBM (70/30) with Bar',
    mw: '11.00',
    leasingFee: '12.17',
    mudType: 'Oil-based',
  ),
  PremixModel(
    id: '4',
    description: '11.5 ppg OBM (80/20) with Bar',
    mw: '11.50',
    leasingFee: '13.58',
    mudType: 'Oil-based',
  ),
  PremixModel(
    id: '5',
    description: '12.8 ppg OBM (80/20) with Bar',
    mw: '12.80',
    leasingFee: '15.27',
    mudType: 'Oil-based',
  ),
].obs;


var obm = <ObmModel>[
  ObmModel(id: '1', product: '', code: '', sg: '', conc: ''),
  ObmModel(id: '2', product: '', code: '', sg: '', conc: ''),
  ObmModel(id: '3', product: '', code: '', sg: '', conc: ''),
  ObmModel(id: '4', product: '', code: '', sg: '', conc: ''),
  ObmModel(id: '5', product: '', code: '', sg: '', conc: ''),
].obs;

final packages = <PackageModel>[
  PackageModel('1', '', '', '', '', '', false),
].obs;

final engineering = <EngineeringModel>[
  EngineeringModel('1', 'Mud Supervisor-1', '1', '1', '173.33', false),
  EngineeringModel('2', 'Mud Supervisor-2', '1', '1', '167.74', false),
  EngineeringModel('3', 'Mud Supervisor-3', '1', '1', '185.72', false),
  EngineeringModel('4', 'Mud Supervisor-4', '1', '1', '179.31', false),
].obs;

final services = <ServiceModel>[
  ServiceModel('1', '', '', '', '', false),
].obs;


final pumps = <PumpModel>[
  PumpModel(
    type: 'Triplex'.obs,
    model: 'BOMCO-F16'.obs,
    linerId: '6.500'.obs,
    rodOd: ''.obs,
    strokeLength: '12.000'.obs,
    efficiency: '95.0'.obs,
    displacement: '0.1170'.obs,
    maxPumpP: ''.obs,
    maxHp: ''.obs,
    surfaceLen: ''.obs,
    surfaceId: ''.obs,
  ),
  PumpModel(
    type: 'Triplex'.obs,
    model: 'BOMCO-F16'.obs,
    linerId: '6.000'.obs,
    rodOd: ''.obs,
    strokeLength: '12.000'.obs,
    efficiency: '97.0'.obs,
    displacement: '0.1018'.obs,
    maxPumpP: ''.obs,
    maxHp: ''.obs,
    surfaceLen: ''.obs,
    surfaceId: ''.obs,
  ),
];


// ================= SCE =================
final shakers = <ShakerModel>[
  ShakerModel(id: 1, shaker: '1', model: 'DERRICK # 1', screens: '4', plot: true),
  ShakerModel(id: 2, shaker: '2', model: 'DERRICK # 2', screens: '4', plot: true),
  ShakerModel(id: 10, shaker: 'Mud Cleaner', model: 'DERRICK # 3', screens: '4', plot: true),
].obs;

final otherSce = <OtherSceModel>[
  OtherSceModel(type: 'Degasser', model1: 'CHENGDU', plot: true),
  OtherSceModel(type: 'Desander', model1: 'DERRICK', plot: true),
  OtherSceModel(type: 'Desilter', model1: 'DERRICK', plot: true),
  OtherSceModel(type: 'Centrifuge', model1: 'KEMTRON', plot: true),
  OtherSceModel(type: 'Barite Rec.', plot: false),
];



  // ---------------- PIT DATA ----------------
  
  final pits = <PitModel>[
    PitModel(id: 1, pit: 'TRIP TANK', capacity: '120.00', active: true),
    PitModel(id: 2, pit: 'SANDTRAP # 1A', capacity: '150.00', active: true),
    PitModel(id: 3, pit: 'SETTLING # 1B', capacity: '150.00', active: true),
    PitModel(id: 4, pit: 'DEGASSER # 1C', capacity: '150.00', active: true),
    PitModel(id: 5, pit: 'DESANDER # 2A', capacity: '170.00', active: true),
    PitModel(id: 6, pit: 'DESILTER # 2B', capacity: '170.00', active: true),
    PitModel(id: 7, pit: 'INT # 2C', capacity: '190.00', active: false),
    PitModel(id: 8, pit: 'INT # 3A', capacity: '190.00', active: false),
    PitModel(id: 9, pit: 'INT # 3B', capacity: '190.00', active: false),
    PitModel(id: 10, pit: 'INT # 3C', capacity: '100.00', active: false),
    PitModel(id: 11, pit: 'SUCTION # 4A', capacity: '315.00', active: true),
    PitModel(id: 12, pit: 'SUCTION # 4B', capacity: '315.00', active: true),
    PitModel(id: 13, pit: 'RES # 5A', capacity: '315.00', active: false),
    PitModel(id: 14, pit: 'RES # 5B', capacity: '315.00', active: false),
    PitModel(id: 15, pit: 'RES # 6A', capacity: '315.00', active: false),
    PitModel(id: 16, pit: 'RES # 6B', capacity: '315.00', active: false),
  ].obs;

  // 添加总容量响应式变量
  final totalCapacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // 初始化时计算总容量
    updateTotalCapacity();
  }

  // ================= 计算总容量方法 =================
  void updateTotalCapacity() {
    double sum = 0.0;
    
    for (var pit in pits) {
      // 解析容量字符串为数字
      final capacityStr = pit.capacity;
      if (capacityStr != null && capacityStr.isNotEmpty) {
        try {
          final capacityValue = double.tryParse(capacityStr);
          if (capacityValue != null) {
            sum += capacityValue;
          }
        } catch (e) {
          print('解析容量时出错: ${pit.pit} - $capacityStr');
        }
      }
    }
    
    totalCapacity.value = sum;
  }

  // ================= 更新单个坑的容量 =================
  void updatePitCapacity(int pitId, String newCapacity) {
    final pit = pits.firstWhereOrNull((p) => p.id == pitId);
    if (pit != null) {
      pit.capacity = newCapacity;
      updateTotalCapacity(); // 更新总容量
    }
  }

  // ================= 切换坑的激活状态 =================
  void togglePitActive(int pitId) {
    final pit = pits.firstWhereOrNull((p) => p.id == pitId);
    if (pit != null) {
      pit.active.value = !pit.active.value;
      // 如果需要，可以根据激活状态更新总容量
      updateTotalCapacity();
    }
  }

  // ================= 获取激活坑的总容量 =================
  double getActivePitsTotalCapacity() {
    double sum = 0.0;
    
    for (var pit in pits) {
      if (pit.active.value) {
        final capacityStr = pit.capacity;
        if (capacityStr != null && capacityStr.isNotEmpty) {
          try {
            final capacityValue = double.tryParse(capacityStr);
            if (capacityValue != null) {
              sum += capacityValue;
            }
          } catch (e) {
            print('解析容量时出错: ${pit.pit} - $capacityStr');
          }
        }
      }
    }
    
    return sum;
  }

  // ================= 获取激活坑的数量 =================
  int getActivePitsCount() {
    return pits.where((pit) => pit.active.value).length;
  }

  // ================= 添加新坑 =================
  void addNewPit(String pitName, String capacity, bool isActive) {
    final newId = pits.isNotEmpty ? pits.last.id! + 1 : 1;
    pits.add(PitModel(
      id: newId,
      pit: pitName,
      capacity: capacity,
      active: isActive,
    ));
    updateTotalCapacity();
  }

  // ================= 删除坑 =================
  void removePit(int pitId) {
    pits.removeWhere((pit) => pit.id == pitId);
    updateTotalCapacity();
  }


  void switchRightTab(String tab) {
    activeRightTab.value = tab;
  }

  void toggleLock() {
    isLocked.toggle();
  }
}
