import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'modules/dashboard/view/dashboard_view.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(OptionsController(), permanent: true);
  Get.put(InventoryProductsStore(), permanent: true);
  Get.put(InventoryServicesStore(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MudPro Desktop',
      theme: ThemeData(fontFamily: 'Segoe UI', useMaterial3: false),
      home: home ?? DashboardView(),
    );
  }
}
