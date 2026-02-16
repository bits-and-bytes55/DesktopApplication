import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_products_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_service.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryView extends StatelessWidget {
  InventoryView({super.key});
  final c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  ? InventoryProductsView()
                  : InventoryServicesView();
            }),
          ),
        ),

        // ================= FIXED BOTTOM FOOTER =================
        _inventoryFooter(),
      ],
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

  // ================= FIXED FOOTER =================
  Widget _inventoryFooter() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            // Small screens: Stack vertically
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ================= LEFT : FEES =================
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      color: AppTheme.cardColor,
                    ),
                    child: Column(
                      children: [
                        _footerRow(
                          'Bulk Tank Setup Fee (\$)',
                          enabled: !c.isLocked.value,
                        ),
                        const SizedBox(height: 8),
                        _footerRow(
                          'Tax Rate (%)',
                          enabled: !c.isLocked.value,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ================= MIDDLE : APPLY CHANGED PRICES =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      color: AppTheme.cardColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply Changed Prices',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _radioRow('To All'),
                        _radioRow('From Now On'),
                        Row(
                          children: [
                            _radioRow('From'),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 24,
                                child: Obx(() => TextField(
                                  controller: TextEditingController(text: c.fromDate.value),
                                  enabled: !c.isLocked.value,
                                  onChanged: (value) => c.fromDate.value = value,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  style: const TextStyle(fontSize: 10),
                                )),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ================= RIGHT : INVENTORY PICKUP =================
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Inventory Pickup',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: Obx(() => ElevatedButton(
                          onPressed: c.isLocked.value ? null : () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(fontSize: 11),
                          ),
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            // Large screens: Row layout
            return SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= LEFT : FEES =================
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                        color: AppTheme.cardColor,
                      ),
                      child: Column(
                        children: [
                          _footerRow(
                            'Bulk Tank Setup Fee (\$)',
                            enabled: !c.isLocked.value,
                          ),
                          const SizedBox(height: 8),
                          _footerRow(
                            'Tax Rate (%)',
                            enabled: !c.isLocked.value,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ================= MIDDLE : APPLY CHANGED PRICES =================
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                        color: AppTheme.cardColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apply Changed Prices',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _radioRow('To All'),
                          _radioRow('From Now On'),
                          Row(
                            children: [
                              _radioRow('From'),
                              const SizedBox(width: 6),
                              Expanded(
                                child: SizedBox(
                                  height: 24,
                                  child: Obx(() => TextField(
                                    controller: TextEditingController(text: c.fromDate.value),
                                    enabled: !c.isLocked.value,
                                    onChanged: (value) => c.fromDate.value = value,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    style: const TextStyle(fontSize: 10),
                                  )),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ================= RIGHT : INVENTORY PICKUP =================
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Inventory Pickup',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: Obx(() => ElevatedButton(
                            onPressed: c.isLocked.value ? null : () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(fontSize: 11),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _footerRow(String label, {required bool enabled}) {
    final c = Get.find<UgController>();
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        SizedBox(
          width: 90,
          height: 24,
          child: Obx(() => TextField(
            controller: TextEditingController(
              text: label.contains('Bulk Tank') ? c.bulkTankSetupFee.value : c.taxRate.value,
            ),
            enabled: enabled,
            onChanged: (value) {
              if (label.contains('Bulk Tank')) {
                c.bulkTankSetupFee.value = value;
              } else {
                c.taxRate.value = value;
              }
            },
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            style: const TextStyle(fontSize: 10),
          )),
        ),
      ],
    );
  }

  Widget _radioRow(String text) {
    final c = Get.find<UgController>();

    return Row(
      children: [
        Obx(() => Radio<String>(
          value: text,
          groupValue: c.applyChangedPricesOption.value,
          onChanged: c.isLocked.value ? null : (value) => c.applyChangedPricesOption.value = value!,
          visualDensity: VisualDensity.compact,
          activeColor: AppTheme.primaryColor,
        )),
        Text(
          text,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}