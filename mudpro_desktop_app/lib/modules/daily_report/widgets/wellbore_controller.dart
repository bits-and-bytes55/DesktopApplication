
// Controller for managing state
import 'package:get/get.dart';

class WellboreController extends GetxController {
  var depthKPI = 96.0.obs;
  var maxDepthKPI = 3969.0.obs;
  var costKPI = 3655.70.obs;
  var maxCostKPI = 697037.72.obs;
  var dayKPI = 1.0.obs;
  var maxDayKPI = 47.0.obs;
  
  var topProducts = <Map<String, dynamic>>[
    {'name': 'BARITE + J - Dis Barite', 'percentage': 77.3},
    {'name': 'BENTONITE - TON', 'percentage': 18.8},
    {'name': 'CAUSTIC SODA', 'percentage': 1.9},
    {'name': 'SODA ASH', 'percentage': 1.9},
  ].obs;

  var categories = <Map<String, dynamic>>[
    {'name': 'Product', 'percentage': 85.8},
    {'name': 'Engineering', 'percentage': 14.2},
  ].obs;
}