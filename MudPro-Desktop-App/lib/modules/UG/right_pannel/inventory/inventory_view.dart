import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_pickup/inventory_pickup_tabs.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_products_view.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_service.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/model/ug_inventory_product_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/controller/ug_inventory_product_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class InventoryView extends StatelessWidget {
  InventoryView({super.key});
  final c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ================= TOP SUB TABS — UNCHANGED =================
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [_tabButton('Products'), _tabButton('Services')],
          ),
        ),

        // ================= MIDDLE CONTENT — UNCHANGED =================
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: Obx(() {
              return c.inventoryTab.value == 'Products'
                  ? const InventoryProductsView()
                  : const InventoryServicesView();
            }),
          ),
        ),

        // ================= FIXED BOTTOM FOOTER =================
        _inventoryFooter(context),
      ],
    );
  }

  // ---------------- TAB BUTTON — UNCHANGED ----------------
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

  // ================= FOOTER — only Apply button changed =================
  Widget _inventoryFooter(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          if (constraints.maxWidth < 800) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _feesBox(),
                  const SizedBox(height: 12),
                  _applyPricesBox(),
                  const SizedBox(height: 12),
                  _inventoryPickupBox(context),
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _feesBox()),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _applyPricesBox()),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: _inventoryPickupBox(context)),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // ── Fees box — UNCHANGED ──────────────────────────────────
  Widget _feesBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        color: AppTheme.cardColor,
      ),
      child: Column(
        children: [
          _footerRow('Bulk Tank Setup Fee (Kwd)', enabled: !c.isLocked.value),
          const SizedBox(height: 8),
          _footerRow('Tax Rate (%)', enabled: !c.isLocked.value),
        ],
      ),
    );
  }

  // ── Apply Changed Prices box — UNCHANGED ──────────────────
  Widget _applyPricesBox() {
    return Container(
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
                  child: Obx(
                    () => TextField(
                      controller: TextEditingController(text: c.fromDate.value),
                      enabled: !c.isLocked.value,
                      onChanged: (value) => c.fromDate.value = value,
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Inventory Pickup + Apply button — Apply now calls API ─
  Widget _inventoryPickupBox(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Get.to(() => const InventoryPickupTabs());
          },
          icon: Icon(Icons.launch, size: 14, color: AppTheme.primaryColor),
          label: Text(
            'Inventory Pickup',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ✅ Apply button — now calls _applyAll
        SizedBox(
          height: 32,
          child: Obx(
            () => ElevatedButton(
              onPressed: c.isLocked.value ? null : () => _applyAll(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Apply', style: TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Apply logic — sends all three tables to backend ───────
  Future<void> _applyAll(BuildContext context) async {
    final store = Get.find<InventoryProductsStore>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(width: 20),
                const Text(
                  'Saving inventory...',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final servicesStore = Get.find<InventoryServicesStore>();

      if (c.wellId.trim().isNotEmpty &&
          servicesStore.selectedPackages.isEmpty &&
          servicesStore.selectedEngineering.isEmpty &&
          servicesStore.selectedServices.isEmpty) {
        final fetchedPackages = await InventoryProductsService.fetchPackages(
          c.wellId,
        );
        final fetchedEngineering =
            await InventoryProductsService.fetchEngineering(c.wellId);
        final fetchedServices = await InventoryProductsService.fetchServices(
          c.wellId,
        );

        servicesStore.setSelectedServices(
          packages: fetchedPackages,
          engineering: fetchedEngineering,
          services: fetchedServices,
        );
      }

      // Map InventoryProductsStore products → ProductInventoryModel list
      final productsList = store.selectedProducts.map((p) {
        return ProductInventoryModel(
          id: p.id,
          product: p.product,
          code: p.code,
          sg: p.sg,
          unit: p.formattedUnit,
          price: p.price,
          initial: p.initial,
          group: p.group,
          volAdd: p.volAdd,
          calculate: p.calculate,
          plot: p.plot,
          tax: p.tax,
        );
      }).toList();

      // Collect from services store
      final packages = servicesStore.selectedPackages.toList();
      final engineering = servicesStore.selectedEngineering.toList();
      final services = servicesStore.selectedServices.toList();

      await InventoryProductsService.applyInventoryData(
        wellId: c.wellId,
        products: productsList,
        premixed: c.premixed.toList(),
        obm: c.obm.toList(),
        packages: packages,
        engineering: engineering,
        services: services,
        bulkTankSetupFee: c.bulkTankSetupFee.value,
        taxRate: c.taxRate.value,
        applyPricesOption: c.applyChangedPricesOption.value,
        fromDate: c.fromDate.value,
      );

      // Close dialog
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      // Success toast
      _showToast(context, 'Inventory saved successfully');
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      _showToast(context, 'Failed to save: ${e.toString()}', isError: true);
    }
  }

  void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 80,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade600 : Colors.green.shade600,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), entry.remove);
  }

  // ── Footer helpers — UNCHANGED ────────────────────────────

  Widget _footerRow(String label, {required bool enabled}) {
    final c = Get.find<UgController>();
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ),
        SizedBox(
          width: 90,
          height: 24,
          child: Obx(
            () => TextField(
              controller: TextEditingController(
                text: label.contains('Bulk Tank')
                    ? c.bulkTankSetupFee.value
                    : c.taxRate.value,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _radioRow(String text) {
    final c = Get.find<UgController>();
    return Row(
      children: [
        Obx(
          () => Radio<String>(
            value: text,
            groupValue: c.applyChangedPricesOption.value,
            onChanged: c.isLocked.value
                ? null
                : (value) => c.applyChangedPricesOption.value = value!,
            visualDensity: VisualDensity.compact,
            activeColor: AppTheme.primaryColor,
          ),
        ),
        Text(text, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
