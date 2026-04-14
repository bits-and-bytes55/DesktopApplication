// Controller for managing graph data
import 'package:get/get.dart';

class DailyCostGraphController extends GetxController {
  final RxInt hoveredIndex = (-1).obs;
  final RxString hoveredSection = ''.obs;

  // Sample data for Product graph
  final List<double> productData = [
    200, 150, 180, 220, 190, 210, 500, 3000, 700, 900, 1200, 5000, 2200, 5500, 1300, 300
  ];

  // Sample data for Premix/Mud graph
  final List<double> premixData = [
    0, 0, 0, 0, 0, 0, 0, 20000, 2000, 0, 0, 0, 0, 1000, 0, 0
  ];

  // Sample data for Rig2dx graph
  final List<double> rig2dxData = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  // Sample data for Service graph
  final List<double> serviceData = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  ];

  // Sample data for Engineering graph
  final List<double> engineeringData = [
    500, 180, 170, 165, 170, 165, 170, 165, 170, 165, 170, 165, 170, 165, 170, 165
  ];

  void setHoveredBar(int index, String section) {
    hoveredIndex.value = index;
    hoveredSection.value = section;
  }

  void clearHovered() {
    hoveredIndex.value = -1;
    hoveredSection.value = '';
  }
}