import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/pickup_tabs/products_pickup_tab.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/pickup_tabs/services_pickup_tab.dart';

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
      backgroundColor: Colors.white,
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2F2F2F),
                  ),
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
                    border: Border.all(color: const Color(0xFFC7CBD2)),
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
          color: Colors.white,
          border: Border(
            left: const BorderSide(color: Color(0xFFC7CBD2)),
            right: const BorderSide(color: Color(0xFFC7CBD2)),
            top: const BorderSide(color: Color(0xFFC7CBD2)),
            bottom: BorderSide(
              color: active ? Colors.white : const Color(0xFFC7CBD2),
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF2F2F2F),
          ),
        ),
      ),
    );
  }
}
