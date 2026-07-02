import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/pickup_tabs/products_pickup_tab.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/pickup_tabs/services_pickup_tab.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/ug_ui_pattern.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryPickupTabs extends StatefulWidget {
  const InventoryPickupTabs({super.key, this.applyProductsToMainInventory = true});

  final bool applyProductsToMainInventory;

  @override
  State<InventoryPickupTabs> createState() => _InventoryPickupTabsState();
}

class _InventoryPickupTabsState extends State<InventoryPickupTabs> {
  String _activeTab = 'Products';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ugPageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 6),
                child: Text(
                  'Inventory Pickup',
                  style: AppTheme.wellLikeBodyText,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tabButton(label: 'Products', value: 'Products'),
                  const SizedBox(width: 2),
                  _tabButton(label: 'Services', value: 'Services'),
                ],
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: ugBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _activeTab == 'Products'
                      ? ProductsPickupPage(
                          applyToMainInventory:
                              widget.applyProductsToMainInventory,
                        )
                      : const ServicesPickupPage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton({required String label, required String value}) {
    final active = _activeTab == value;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = value),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? ugSectionHeader : ugColumnHeader,
          border: Border(
            left: const BorderSide(color: ugBorder),
            right: const BorderSide(color: ugBorder),
            top: const BorderSide(color: ugBorder),
            bottom: BorderSide(
              color: active ? ugSectionHeader : ugBorder,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
