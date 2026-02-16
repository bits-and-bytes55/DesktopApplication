import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'modules/dashboard/view/dashboard_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  
  Get.put(InventoryProductsStore(), permanent: true);
  Get.put(InventoryServicesStore(), permanent: true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MudPro Desktop',
      theme: ThemeData(
        fontFamily: 'Segoe UI',
        useMaterial3: false,
      ),
      home: DashboardView(), 
    );
  }
}
