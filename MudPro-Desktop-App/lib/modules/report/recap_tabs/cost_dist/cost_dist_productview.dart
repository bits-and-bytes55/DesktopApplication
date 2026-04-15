import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/controller/inventory_snapshot_controller.dart';
import 'package:mudpro_desktop_app/modules/daily_report/model/cost_model.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/widget/horizontal_bar.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class CostDistProductview extends StatefulWidget {
  const CostDistProductview({super.key});

  @override
  State<CostDistProductview> createState() => _CostDistProductviewState();
}

class _CostDistProductviewState extends State<CostDistProductview> {
  final InventorySnapshotController _inventoryController =
      InventorySnapshotController();

  List<CostData> _productData = const [];
  List<CostData> _groupData = const [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchSnapshot();
  }

  Future<void> _fetchSnapshot() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _inventoryController.getInventorySnapshot();
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to load inventory snapshot');
      }

      final items = (result['items'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final totalsByCategory = <String, double>{};
      final totalsByProduct = <String, double>{};

      for (final item in items) {
        final category = (item['category'] ?? 'Unknown').toString();
        final name = (item['itemName'] ?? '').toString();
        final subtotal = _toDouble(item['subtotal']);

        totalsByCategory[category] =
            (totalsByCategory[category] ?? 0) + subtotal;

        if (category == 'Product' && name.isNotEmpty) {
          totalsByProduct[name] = (totalsByProduct[name] ?? 0) + subtotal;
        }
      }

      final productData = totalsByProduct.entries
          .where((e) => e.value > 0)
          .map((e) => CostData(e.key, e.value))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final groupData = totalsByCategory.entries
          .where((e) => e.value > 0)
          .map((e) => CostData(e.key, e.value))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _productData = productData;
        _groupData = groupData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    final productData = _productData;
    final groupData = _groupData;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundColor,
            AppTheme.backgroundColor.withOpacity(0.95),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          return isDesktop
              ? _buildDesktopLayout(productData, groupData, constraints)
              : _buildMobileLayout(productData, groupData, constraints);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    List<CostData> productData,
    List<CostData> groupData,
    BoxConstraints constraints,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Section
       

          // Charts Section - Full Page Height
          SizedBox(
            height: constraints.maxHeight - 50, // Full height minus minimal padding
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Chart
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: HorizontalCostChart(
                      title: ' Cost Distribution - Products',
                      data: productData,
                      maxValue: 100,
                      showValues: false, // Legend hidden to save space
                    ),
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  color: Colors.grey.shade200,
                ),

                // Right Chart
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: HorizontalCostChart(
                      title: 'Cost Distribution - Group',
                      data: groupData,
                      maxValue: 100,
                      showValues: false, // Legend hidden to save space
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    List<CostData> productData,
    List<CostData> groupData,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header Section for Mobile
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daily Cost Analysis",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Product-wise cost distribution analysis",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          "Current Operation Data",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // First Chart - Fixed Height
            SizedBox(
              height: constraints.maxHeight * 0.4, // Reduced height
              child: HorizontalCostChart(
                title: 'Product Cost Distribution',
                data: productData,
                maxValue: 100,
                showValues: true,
              ),
            ),

            // Spacing
            const SizedBox(height: 16),

            // Second Chart - Fixed Height
            SizedBox(
              height: constraints.maxHeight * 0.4, // Reduced height
              child: HorizontalCostChart(
                title: 'Category Distribution',
                data: groupData,
                maxValue: 100,
                showValues: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
