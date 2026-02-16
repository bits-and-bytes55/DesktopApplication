import 'package:get/get.dart';

enum UnitSystem { us, si, customized }

class OptionsController extends GetxController {
  // Left tab index
  var selectedTab = 0.obs;

  // Unit system
  var unitSystem = UnitSystem.us.obs;

  // Customized dropdown
  var selectedCustomSystem = 'Pegasus Default 1'.obs;

  RxList<String> unitSystems = <String>[
  'Pegasus Default 1',
  'SI',
  'US',
  'Pegasus Default 3',
].obs;

RxInt selectedLeftIndex = 0.obs;

final List<String> allUnits = [
  'ft', 'm', 'in', 'mm', 'in²', 'mm²', 'bbl', 'm³',
  'ft/min', 'm/min', 'psi', 'kPa',
  'ppg', 'kg/m³', '°F', '°C', 'lb/min', 'kg/min',
  'lb/ft', 'kg/m', 'lb/ft³', 'kg/m³',
  '°F/100ft', '°C/100m', '°/100ft', '°/100m',
  'lb/bbl', 'kg/m³', 'gal/bbl', 'L/m³', 'sk', 'bag',
  'lb/sk', 'kg/bag', 'ft³/sk', 'm³/bag', 'gal/sk', 'L/bag',
  '\$/bbl', '\$/m³', 'mph', 'km/h', 'Btu/lb/°F', 'J/kg/°C',
  'Mpa', 'GPa', 'Btu/hr/ft/°F', 'W/m/K', '10⁻⁶/°F', '10⁻⁶/°C',
  'gal', 'L', 'sec/qt', 'sec/L', 'rev', 'US ton/h', 'tonne/h',
  'ft/day', 'm/day', '(f1)', '(m)', '(n1)', '(n2)', '(bbl)', '(m³)',
  '(bbl./f1)', '(m³/m)', '(f1/bbl)', '(m/m³)', '(f13)', '(m³)',
  '(n3)', '(bbl./aik)', '(m³/day)', '(acf)', '(f1/min)', '(m/min)',
  '(f1/a)', '(m/year)', '(f1/hr)', '(m/hr)', '(rpm)', '(lbf)', '(N)',
  '(fbf/ft)', '(N/m)', '(ft-lb)', '(J)', '(psi)', '(kPa)', '(psi/ft)', '(kPa/m)',
]; // same list

void insertBefore() {
  unitSystems.insert(selectedLeftIndex.value, 'New Unit System');
}

void insertAfter() {
  unitSystems.insert(selectedLeftIndex.value + 1, 'New Unit System');
}

void deleteSystem() {
  if (unitSystems.length > 1) {
    unitSystems.removeAt(selectedLeftIndex.value);
    selectedLeftIndex.value = 0;
  }
}


  // All 53 parameters from images with proper structure
  final List<Map<String, String>> parameters = [
    {'number': '1', 'name': 'Length', 'us': 'ft', 'si': 'm', 'custom': 'ft'},
    {'number': '2', 'name': 'Pipe diameter', 'us': 'in', 'si': 'mm', 'custom': 'in'},
    {'number': '3', 'name': 'Cross section', 'us': 'in²', 'si': 'mm²', 'custom': 'in²'},
    {'number': '4', 'name': 'Fluid volume', 'us': 'bbl', 'si': 'm³', 'custom': 'bbl'},
    {'number': '5', 'name': 'Velocity', 'us': 'ft/min', 'si': 'm/min', 'custom': 'ft/min'},
    {'number': '6', 'name': 'Pressure', 'us': 'psi', 'si': 'kPa', 'custom': 'psi'},
    {'number': '7', 'name': 'Mass rate', 'us': 'lb/min', 'si': 'kg/min', 'custom': 'lb/min'},
    {'number': '8', 'name': 'Line density', 'us': 'lb/ft', 'si': 'kg/m', 'custom': 'lb/ft'},
    {'number': '9', 'name': 'Density', 'us': 'lb/ft³', 'si': 'kg/m³', 'custom': 'lb/ft³'},
    {'number': '10', 'name': 'Mud weight', 'us': 'ppg', 'si': 'kg/m³', 'custom': 'ppg'},
    {'number': '11', 'name': 'ECD', 'us': 'ppg', 'si': 'kg/m³', 'custom': 'ppg'},
    {'number': '12', 'name': 'Temperature', 'us': '°F', 'si': '°C', 'custom': '°F'},
    {'number': '13', 'name': 'Temperature gradient', 'us': '°F/100ft', 'si': '°C/100m', 'custom': '°F/100ft'},
    {'number': '14', 'name': 'Dogleg', 'us': '°/100ft', 'si': '°/100m', 'custom': '°/100ft'},
    {'number': '15', 'name': 'Spacer additive concentration - solid', 'us': 'lb/bbl', 'si': 'kg/m³', 'custom': 'lb/bbl'},
    {'number': '16', 'name': 'Mass - volume ratio', 'us': 'lb/bbl', 'si': 'kg/m³', 'custom': 'lb/bbl'},
    {'number': '17', 'name': 'Volume - volume ratio', 'us': 'gal/bbl', 'si': 'L/m³', 'custom': 'gal/bbl'},
    {'number': '18', 'name': 'Sack of Cement', 'us': 'sk', 'si': 'bag', 'custom': 'sk'},
    {'number': '19', 'name': 'Cement/solid additive Wt/sk', 'us': 'lb/sk', 'si': 'kg/bag', 'custom': 'lb/sk'},
    {'number': '20', 'name': 'Spacer additive concentration - liquid', 'us': 'gal/bbl', 'si': 'L/m³', 'custom': 'gal/bbl'},
    {'number': '21', 'name': 'Cement slurry yield', 'us': 'ft³/sk', 'si': 'm³/bag', 'custom': 'ft³/sk'},
    {'number': '22', 'name': 'Cement liquid additive/water requirement', 'us': 'gal/sk', 'si': 'L/bag', 'custom': 'gal/sk'},
    {'number': '23', 'name': 'Leasing Fee', 'us': '\$/bbl', 'si': '\$/m³', 'custom': '\$/bbl'},
    {'number': '24', 'name': 'Sea current', 'us': 'mph', 'si': 'km/h', 'custom': 'mph'},
    {'number': '25', 'name': 'Heat Capacity', 'us': 'Btu/lb/°F', 'si': 'J/kg/°C', 'custom': 'Btu/lb/°F'},
    {'number': '26', 'name': 'Temperature change', 'us': '°F', 'si': '°C', 'custom': '°F'},
    {'number': '27', 'name': 'Young\'s modulus', 'us': 'Mpa', 'si': 'GPa', 'custom': 'Mpa'},
    {'number': '28', 'name': 'Thermal conductivity', 'us': 'Btu/hr/ft/°F', 'si': 'W/m/K', 'custom': 'Btu/hr/ft/°F'},
    {'number': '29', 'name': 'Thermal expansion factor', 'us': '10⁻⁶/°F', 'si': '10⁻⁶/°C', 'custom': '10⁻⁶/°F'},
    {'number': '30', 'name': 'Additive Volume', 'us': 'gal', 'si': 'L', 'custom': 'gal'},
    {'number': '31', 'name': 'Funnel viscosity', 'us': 'sec/qt', 'si': 'sec/L', 'custom': 'sec/qt'},
    {'number': '32', 'name': 'Twist', 'us': 'rev', 'si': 'rev', 'custom': 'rev'},
    {'number': '33', 'name': 'Mass large rate', 'us': 'US ton/h', 'si': 'tonne/h', 'custom': 'US ton/h'},
    {'number': '34', 'name': 'Daily Footage', 'us': 'ft/day', 'si': 'm/day', 'custom': 'ft/day'},
    {'number': '35', 'name': 'Parameter 35', 'us': '(f1)', 'si': '(m)', 'custom': '(f1)'},
    {'number': '36', 'name': 'Parameter 36', 'us': '(n1)', 'si': '(n1)', 'custom': '(n1)'},
    {'number': '37', 'name': 'Parameter 37', 'us': '(n2)', 'si': '(n2)', 'custom': '(n2)'},
    {'number': '38', 'name': 'Parameter 38', 'us': '(bbl)', 'si': '(m³)', 'custom': '(bbl)'},
    {'number': '39', 'name': 'Parameter 39', 'us': '(bbl./f1)', 'si': '(m³/m)', 'custom': '(bbl./f1)'},
    {'number': '40', 'name': 'Parameter 40', 'us': '(f1/bbl)', 'si': '(m/m³)', 'custom': '(f1/bbl)'},
    {'number': '41', 'name': 'Parameter 41', 'us': '(f13)', 'si': '(m³)', 'custom': '(f13)'},
    {'number': '42', 'name': 'Parameter 42', 'us': '(n3)', 'si': '(n3)', 'custom': '(n3)'},
    {'number': '43', 'name': 'Parameter 43', 'us': '(bbl./aik)', 'si': '(m³/day)', 'custom': '(bbl./aik)'},
    {'number': '44', 'name': 'Parameter 44', 'us': '(acf)', 'si': '(m³)', 'custom': '(acf)'},
    {'number': '45', 'name': 'Parameter 45', 'us': '(f1/min)', 'si': '(m/min)', 'custom': '(f1/min)'},
    {'number': '46', 'name': 'Parameter 46', 'us': '(f1/a)', 'si': '(m/year)', 'custom': '(f1/a)'},
    {'number': '47', 'name': 'Parameter 47', 'us': '(f1/hr)', 'si': '(m/hr)', 'custom': '(f1/hr)'},
    {'number': '48', 'name': 'Parameter 48', 'us': '(rpm)', 'si': '(rpm)', 'custom': '(rpm)'},
    {'number': '49', 'name': 'Parameter 49', 'us': '(lbf)', 'si': '(N)', 'custom': '(lbf)'},
    {'number': '50', 'name': 'Parameter 50', 'us': '(fbf/ft)', 'si': '(N/m)', 'custom': '(fbf/ft)'},
    {'number': '51', 'name': 'Parameter 51', 'us': '(ft-lb)', 'si': '(J)', 'custom': '(ft-lb)'},
    {'number': '52', 'name': 'Parameter 52', 'us': '(psi)', 'si': '(kPa)', 'custom': '(psi)'},
    {'number': '53', 'name': 'Parameter 53', 'us': '(psi/ft)', 'si': '(kPa/m)', 'custom': '(psi/ft)'},
  ];

  // Customized unit selection per row
  RxList<String> customUnits = RxList<String>();

  @override
  void onInit() {
    super.onInit();
    // Initialize custom units with US values
    customUnits.value = parameters.map((p) => p['us']!).toList();
  }

  String getUnit(int index) {
    if (unitSystem.value == UnitSystem.us) {
      return parameters[index]['us']!;
    } else if (unitSystem.value == UnitSystem.si) {
      return parameters[index]['si']!;
    } else {
      return customUnits[index];
    }
  }

  String getUnitName(int index) {
    return parameters[index]['name']!;
  }

  String getUnitNumber(int index) {
    return parameters[index]['number']!;
  }
}