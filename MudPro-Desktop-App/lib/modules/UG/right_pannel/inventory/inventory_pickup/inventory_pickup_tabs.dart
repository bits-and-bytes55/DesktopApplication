import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/pickup_tabs/products_pickup_tab.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/pickup_tabs/services_pickup_tab.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryPickupTabs extends StatefulWidget {
  const InventoryPickupTabs({super.key});

  @override
  State<InventoryPickupTabs> createState() => _InventoryPickupTabsState();
}

class _InventoryPickupTabsState extends State<InventoryPickupTabs> {
  final UgController c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Inventory Pickup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2F2F2F),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tabButton(label: 'Product', value: 'Products'),
                    _tabButton(label: 'Services', value: 'Services'),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      right: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Obx(
                    () => c.inventoryTab.value == 'Products'
                        ? ProductsPickupPage()
                        : const ServicesPickupPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton({required String label, required String value}) {
    return Obx(() {
      final active = c.inventoryTab.value == value;
      return InkWell(
        onTap: () => c.inventoryTab.value = value,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active ? AppTheme.primaryGradient : null,
            color: active ? null : Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
              bottom: active
                  ? BorderSide.none
                  : BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      );
    });
  }
}
