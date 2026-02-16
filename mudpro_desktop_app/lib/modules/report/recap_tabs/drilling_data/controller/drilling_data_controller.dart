import 'package:get/get.dart';

class RecapDrillingDataController extends GetxController {
  // Hover state management
  RxInt hoveredIndex = (-1).obs;
  RxString hoveredSection = ''.obs;

  // Sample data - replace with actual data from your API
  List<double> get productData => [1200.0, 1800.0, 1500.0, 2200.0, 1900.0, 2100.0, 2400.0];
  List<double> get premixData => [800.0, 950.0, 1100.0, 850.0, 1200.0, 1000.0, 1150.0];
  List<double> get rig2dxData => [500.0, 600.0, 750.0, 900.0, 650.0, 800.0, 700.0];
  List<double> get serviceData => [300.0, 400.0, 350.0, 450.0, 500.0, 400.0, 550.0];
  List<double> get engineeringData => [200.0, 250.0, 300.0, 350.0, 280.0, 320.0, 380.0];

  void setHoveredBar(int index, String section) {
    hoveredIndex.value = index;
    hoveredSection.value = section;
  }

  void clearHovered() {
    hoveredIndex.value = -1;
    hoveredSection.value = '';
  }

  double getTotalForSection(String section) {
    List<double> data;
    switch (section) {
      case 'Product':
        data = productData;
        break;
      case 'Premix/Mud':
        data = premixData;
        break;
      case 'Rig2dx':
        data = rig2dxData;
        break;
      case 'Service':
        data = serviceData;
        break;
      case 'Engineering':
        data = engineeringData;
        break;
      default:
        return 0.0;
    }
    return data.reduce((value, element) => value + element);
  }

  // Method to load data (can be called from your API)
  Future<void> loadDrillingData({
    DateTime? startDate,
    DateTime? endDate,
    String? rigId,
  }) async {
    // TODO: Implement API call to fetch drilling data
    // Update the data lists with fetched data
    // Example:
    // productData.value = await apiService.getProductData(startDate, endDate, rigId);
    // premixData.value = await apiService.getPremixData(startDate, endDate, rigId);
    // etc...
  }

  // Additional methods for data processing
  Map<String, dynamic> getDailySummary(int dayIndex) {
    return {
      'product': productData[dayIndex],
      'premix': premixData[dayIndex],
      'rig2dx': rig2dxData[dayIndex],
      'service': serviceData[dayIndex],
      'engineering': engineeringData[dayIndex],
      'total': productData[dayIndex] +
          premixData[dayIndex] +
          rig2dxData[dayIndex] +
          serviceData[dayIndex] +
          engineeringData[dayIndex],
    };
  }

  List<Map<String, dynamic>> getWeeklyTrend() {
    List<Map<String, dynamic>> trends = [];
    for (int i = 0; i < productData.length; i++) {
      trends.add({
        'day': i + 1,
        'total': getDailySummary(i)['total'],
        'highest': getHighestSection(i),
        'lowest': getLowestSection(i),
      });
    }
    return trends;
  }

  String getHighestSection(int dayIndex) {
    final data = {
      'Product': productData[dayIndex],
      'Premix': premixData[dayIndex],
      'Rig2dx': rig2dxData[dayIndex],
      'Service': serviceData[dayIndex],
      'Engineering': engineeringData[dayIndex],
    };
    
    var highest = data.entries.reduce((a, b) => a.value > b.value ? a : b);
    return highest.key;
  }

  String getLowestSection(int dayIndex) {
    final data = {
      'Product': productData[dayIndex],
      'Premix': premixData[dayIndex],
      'Rig2dx': rig2dxData[dayIndex],
      'Service': serviceData[dayIndex],
      'Engineering': engineeringData[dayIndex],
    };
    
    var lowest = data.entries.reduce((a, b) => a.value < b.value ? a : b);
    return lowest.key;
  }
}