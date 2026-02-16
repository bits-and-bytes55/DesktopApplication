import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/daily_report/model/cost_model.dart';
import 'package:mudpro_desktop_app/modules/daily_report/tabs/daily_cost/widget/horizontal_bar.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class CostDistProductview extends StatelessWidget {
  const CostDistProductview({super.key});

  @override
  Widget build(BuildContext context) {
    final productData = [
      CostData('BARITE 4.1 - BIG BAG', 77.5),
      CostData('BENTONITE - TON', 18.8),
      CostData('CAUSTIC SODA', 1.9),
      CostData('SODA ASH', 1.9),
    ];

    final groupData = [
      CostData('Weight Material', 77.5),
      CostData('Viscosifier', 18.8),
      CostData('Common Chemical', 3.8),
    ];

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
      )
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