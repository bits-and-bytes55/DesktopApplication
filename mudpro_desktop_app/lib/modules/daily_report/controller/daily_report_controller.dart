import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  // Active tabs management
  var activeMainTab = "Home".obs;
  var activeSubTab = "Summary".obs;
  
  // Data for charts
  final List<double> depthProgress = [0, 20, 40, 60, 80, 100];
  final List<double> costProgress = [0, 15000, 28000, 42000, 58000, 75000];
  final List<double> mudWeightData = [18.6, 19.2, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 100.0];
  
  // KPI data
  final kpiDepth = 0.96;
  final kpiCost = 0.38;
  final kpiDay = 0.21;
  
  // Cost distribution data
  final List<Map<String, dynamic>> topProducts = [
    {'name': 'BASITE 4.1 - BBS BAG', 'percentage': 77.5, 'color': Colors.blue},
    {'name': 'ROBOTINE - TOM', 'percentage': 18.9, 'color': Colors.green},
    {'name': 'PLASTIC SODA', 'percentage': 1.9, 'color': Colors.orange},
    {'name': 'DOG ASH', 'percentage': 1.9, 'color': Colors.red},
  ];
  
  final List<Map<String, dynamic>> categories = [
    {'name': 'Product', 'percentage': 66.8, 'color': Colors.blue},
    {'name': 'Dangering', 'percentage': 14.2, 'color': Colors.green},
    {'name': 'Others', 'percentage': 19.0, 'color': Colors.grey},
  ];
  
  // Navigation functions
  void setActiveMainTab(String tab) {
    activeMainTab.value = tab;
    // Navigate to respective page based on tab
    switch(tab) {
      case "Report":
        Get.toNamed('/daily-report');
        break;
      case "Utilities":
        Get.toNamed('/utilities');
        break;
      case "Help":
        Get.toNamed('/help');
        break;
      default:
        Get.toNamed('/');
    }
  }
  
  void setActiveSubTab(String tab) {
    activeSubTab.value = tab;
  }
}