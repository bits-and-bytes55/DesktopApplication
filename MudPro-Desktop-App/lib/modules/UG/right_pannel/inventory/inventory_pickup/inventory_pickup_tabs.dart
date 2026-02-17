import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/pickup_tabs/products_pickup_tab.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/pickup_tabs/services_pickup_tab.dart';
import 'package:mudpro_desktop_app/modules/company_setup/tabs/products_page.dart';
import 'package:mudpro_desktop_app/modules/company_setup/tabs/service_page.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryPickupTabs extends StatefulWidget {
  const InventoryPickupTabs({super.key});

  @override
  State<InventoryPickupTabs> createState() => _InventoryPickupTabsState();
}

class _InventoryPickupTabsState extends State<InventoryPickupTabs> {
  final c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Pickup'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ================= TOP SUB TABS =================
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                _tabButton('Products'),
                _tabButton('Services'),
              ],
            ),
          ),

          // ================= MIDDLE CONTENT =================
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: Obx(() {
                return c.inventoryTab.value == 'Products'
                    ? ProductsPickupPage()
                    : ServicesPickupPage();
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TAB BUTTON ----------------
  Widget _tabButton(String title) {
    return Obx(() {
      final active = c.inventoryTab.value == title;
      return Expanded(
        child: InkWell(
          onTap: () => c.inventoryTab.value = title,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: BoxDecoration(
              gradient: active ? AppTheme.primaryGradient : null,
              color: active ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: active ? Colors.transparent : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}