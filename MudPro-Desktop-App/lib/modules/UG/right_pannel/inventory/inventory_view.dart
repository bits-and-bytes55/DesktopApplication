import 'package:flutter/gestures.dart';
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

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final c = Get.find<UgController>();
  late final TextEditingController _bulkTankSetupFeeController;
  late final TextEditingController _taxRateController;
  late final FocusNode _bulkTankSetupFeeFocusNode;
  late final FocusNode _taxRateFocusNode;
  late final Worker _bulkTankSetupFeeWorker;
  late final Worker _taxRateWorker;

  @override
  void initState() {
    super.initState();
    _bulkTankSetupFeeController = TextEditingController(
      text: c.bulkTankSetupFee.value,
    );
    _taxRateController = TextEditingController(text: c.taxRate.value);
    _bulkTankSetupFeeFocusNode = FocusNode();
    _taxRateFocusNode = FocusNode();
    _bulkTankSetupFeeWorker = ever<String>(c.bulkTankSetupFee, (value) {
      _syncFooterController(
        _bulkTankSetupFeeController,
        _bulkTankSetupFeeFocusNode,
        value,
      );
    });
    _taxRateWorker = ever<String>(c.taxRate, (value) {
      _syncFooterController(_taxRateController, _taxRateFocusNode, value);
    });
  }

  @override
  void dispose() {
    _bulkTankSetupFeeWorker.dispose();
    _taxRateWorker.dispose();
    _bulkTankSetupFeeController.dispose();
    _taxRateController.dispose();
    _bulkTankSetupFeeFocusNode.dispose();
    _taxRateFocusNode.dispose();
    super.dispose();
  }

  void _syncFooterController(
    TextEditingController controller,
    FocusNode focusNode,
    String value,
  ) {
    if (focusNode.hasFocus || controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

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
      height: 180,
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
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
                  _applyPricesBox(context),
                  const SizedBox(height: 12),
                  _inventoryPickupBox(context),
                ],
              ),
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 330, child: _feesBox()),
                const SizedBox(width: 16),
                SizedBox(width: 370, child: _applyPricesBox(context)),
                const SizedBox(width: 8),
                SizedBox(width: 230, child: _inventoryPickupBox(context)),
              ],
            );
          }
        },
      ),
    );
  }

  // ── Fees box — UNCHANGED ──────────────────────────────────
  Widget _feesBox() {
    return Obx(() {
      final enabled = !c.isLocked.value;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _footerRow('Bulk Tank Setup Fee (Kwd)', enabled: enabled),
            const SizedBox(height: 12),
            _footerRow('Tax Rate (%)', enabled: enabled),
          ],
        ),
      );
    });
  }

  // ── Apply Changed Prices box — UNCHANGED ──────────────────
  Widget _applyPricesBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC7C7C7)),
        color: const Color(0xFFF3F3F3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply Changed Prices',
            style: TextStyle(
              fontSize: 14,
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
                    () => InkWell(
                      onTap: c.isLocked.value
                          ? null
                          : () => _pickFromDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: c.isLocked.value
                              ? Colors.grey.shade100
                              : Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.fromDate.value,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: c.fromDate.value.trim().isEmpty
                                      ? Colors.grey.shade500
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 14,
                              color: c.isLocked.value
                                  ? Colors.grey.shade400
                                  : AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
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
        SizedBox(
          width: 225,
          height: 34,
          child: OutlinedButton(
            onPressed: () {
              Get.to(() => const InventoryPickupTabs());
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFBEBEBE)),
              foregroundColor: const Color(0xFF3B3B3B),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Text(
              'Inventory Pickup',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 68),

        // ✅ Apply button — now calls _applyAll
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 122,
            height: 34,
            child: Obx(
              () => ElevatedButton(
                onPressed: c.isLocked.value ? null : () => _applyAll(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                child: const Text('Apply', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Apply logic — sends all three tables to backend ───────
  Future<void> _applyAll(BuildContext context) async {
    final store = Get.find<InventoryProductsStore>();
    if (c.applyChangedPricesOption.value == 'From' &&
        c.fromDate.value.trim().isEmpty) {
      _showToast(context, 'Please select a date for changed prices', isError: true);
      return;
    }

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
    final isBulkTank = label.contains('Bulk Tank');
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        SizedBox(
          width: 90,
          height: 24,
          child: Listener(
            onPointerSignal: enabled
                ? (event) {
                    if (event is PointerScrollEvent) {
                      _adjustFooterValue(isBulkTank, event.scrollDelta.dy < 0);
                    }
                  }
                : null,
            child: TextField(
              controller: isBulkTank
                  ? _bulkTankSetupFeeController
                  : _taxRateController,
              focusNode: isBulkTank
                  ? _bulkTankSetupFeeFocusNode
                  : _taxRateFocusNode,
              enabled: enabled,
              onChanged: (value) {
                if (isBulkTank) {
                  c.bulkTankSetupFee.value = value;
                } else {
                  c.taxRate.value = value;
                }
              },
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  void _adjustFooterValue(bool isBulkTank, bool increase) {
    final currentText = isBulkTank ? c.bulkTankSetupFee.value : c.taxRate.value;
    final current = double.tryParse(currentText.trim()) ?? 0;
    final next = (current + (increase ? 1 : -1)).clamp(0, double.infinity);
    final nextText = next % 1 == 0
        ? next.toInt().toString()
        : next.toStringAsFixed(2);
    if (isBulkTank) {
      c.bulkTankSetupFee.value = nextText;
    } else {
      c.taxRate.value = nextText;
    }
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
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Future<void> _pickFromDate(BuildContext context) async {
    final initialDate = _parseInventoryDate(c.fromDate.value) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    c.applyChangedPricesOption.value = 'From';
    c.fromDate.value = _formatInventoryDate(picked);
  }

  DateTime? _parseInventoryDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;
    final parts = text.split(RegExp(r'[/-]'));
    if (parts.length != 3) return null;
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (first == null || second == null || year == null) return null;
    final month = first > 12 ? second : first;
    final day = first > 12 ? first : second;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  String _formatInventoryDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
