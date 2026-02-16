import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PercentCostController extends GetxController {
  final rows = <CostRow>[].obs;

  @override
  void onInit() {
    super.onInit();
    rows.addAll([
      CostRow("Weight Material", 2430),
      CostRow("Viscosifier", 588),
      CostRow("Common Chemical", 117.7),
      CostRow("LCM", 0),
      CostRow("Defoamer", 0),
      CostRow("Filtration Control", 0),
      CostRow("Others", 0),
       CostRow("Alkalinity", 0),
        CostRow("Wellbore strengthening", 0),
         CostRow("OBM Viscosifier", 0),
          CostRow("Emulsifier", 0),
           CostRow("Wetting Agent", 0),
            CostRow("WBM Thinner", 0),
             CostRow("Lubricant/Surfactant", 0),
              CostRow("Corrosion Inhabitor", 0),
               CostRow("Surfactant/Solvent", 0),
                CostRow("OBM Thinner", 0),
                 CostRow("Biocide", 0),
                  CostRow("Premixed Mud", 0),
           
    ]);
    calculatePercentages();
  }

  double get total =>
      rows.fold(0, (sum, item) => sum + item.amount.value);

  void calculatePercentages() {
    final t = total;
    for (var r in rows) {
      r.percent.value = t == 0 ? 0 : (r.amount.value / t) * 100;
    }
  }
}

class CostRow {
  final String group;
  RxDouble amount = 0.0.obs;
  RxDouble percent = 0.0.obs;

  CostRow(this.group, double amt) {
    amount.value = amt;
  }
}

class PercentCostPage extends StatelessWidget {
  final controller = Get.put(PercentCostController());

  PercentCostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
     
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: AppTheme.cardDecoration.copyWith(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Table Header
                  Container(
                    decoration: AppTheme.tableHeaderDecoration.copyWith(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        // No. Column
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Text(
                            "No.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        
                        // Group Column
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Text(
                              "Group",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        
                        // Cost Header with sub-columns
                        SizedBox(
                          width: 200,
                          child: Column(
                            children: [
                              // Main Cost Header
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Text(
                                  "Cost",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              
                              // Sub-headers Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: Text(
                                        "₹",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        "%",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Scrollable Table Body
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: controller.rows.length + 1, // +1 for total row
                          itemBuilder: (context, index) {
                            if (index < controller.rows.length) {
                              final row = controller.rows[index];
                              return Container(
                                height: 36, // Reduced row height
                                decoration: BoxDecoration(
                                  color: index.isEven 
                                    ? AppTheme.surfaceColor 
                                    : AppTheme.cardColor,
                                  border: Border(
                                    bottom: index == controller.rows.length - 1
                                      ? BorderSide.none
                                      : BorderSide(color: Colors.grey.shade100),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // No. Cell
                                    Container(
                                      width: 60,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${index + 1}",
                                          style: AppTheme.bodyLarge.copyWith(
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Group Cell
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(color: Colors.grey.shade200),
                                          ),
                                        ),
                                        child: Text(
                                          row.group,
                                          style: AppTheme.bodyLarge.copyWith(
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Cost Cells
                                    SizedBox(
                                      width: 200,
                                      child: Row(
                                        children: [
                                          // Amount Cell (Editable)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(color: Colors.grey.shade200),
                                                ),
                                              ),
                                              child: TextField(
                                                controller: TextEditingController(
                                                  text: row.amount.value.toStringAsFixed(2),
                                                ),
                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                textAlign: TextAlign.right,
                                                style: AppTheme.bodyLarge.copyWith(
                                                  color: AppTheme.textPrimary,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                                  border: InputBorder.none,
                                                  focusedBorder: InputBorder.none,
                                                  enabledBorder: InputBorder.none,
                                                  hintText: "0.00",
                                                  hintStyle: AppTheme.bodyLarge.copyWith(
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                                onChanged: (val) {
                                                  row.amount.value = double.tryParse(val) ?? 0;
                                                  controller.calculatePercentages();
                                                },
                                              ),
                                            ),
                                          ),
                                          
                                          // Percentage Cell (Editable)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: TextField(
                                                controller: TextEditingController(
                                                  text: row.percent.value.toStringAsFixed(1),
                                                ),
                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                textAlign: TextAlign.right,
                                                style: AppTheme.bodyLarge.copyWith(
                                                  color: index % 3 == 0
                                                    ? AppTheme.successColor
                                                    : AppTheme.textPrimary,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                                  border: InputBorder.none,
                                                  focusedBorder: InputBorder.none,
                                                  enabledBorder: InputBorder.none,
                                                  hintText: "0.0",
                                                  hintStyle: AppTheme.bodyLarge.copyWith(
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                                onChanged: (val) {
                                                  row.percent.value = double.tryParse(val) ?? 0;
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              // Total Row
                              return Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.1),
                                      AppTheme.secondaryColor.withOpacity(0.05),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  border: Border(
                                    top: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Empty No. cell
                                    Container(
                                      width: 60,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(color: Colors.grey.shade200),
                                        ),
                                      ),
                                    ),
                                    
                                    // Total Label
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(color: Colors.grey.shade200),
                                          ),
                                        ),
                                        child: Text(
                                          "Total",
                                          style: AppTheme.titleMedium.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Total Cost Cells
                                    SizedBox(
                                      width: 200,
                                      child: Row(
                                        children: [
                                          // Total Amount (Editable)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(color: Colors.grey.shade200),
                                                ),
                                              ),
                                              child: TextField(
                                                controller: TextEditingController(
                                                  text: controller.total.toStringAsFixed(2),
                                                ),
                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                textAlign: TextAlign.right,
                                                style: AppTheme.titleMedium.copyWith(
                                                  color: AppTheme.primaryColor,
                                                  fontSize: 14,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                                  border: InputBorder.none,
                                                  focusedBorder: InputBorder.none,
                                                  enabledBorder: InputBorder.none,
                                                  hintText: "0.00",
                                                  hintStyle: AppTheme.titleMedium.copyWith(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                onChanged: (val) {
                                                  // Optional: Handle changes if needed, e.g., update a separate total variable
                                                },
                                              ),
                                            ),
                                          ),
                                          
                                          // Total Percentage (Editable)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: TextField(
                                                controller: TextEditingController(
                                                  text: "100.0",
                                                ),
                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                textAlign: TextAlign.right,
                                                style: AppTheme.titleMedium.copyWith(
                                                  color: AppTheme.primaryColor,
                                                  fontSize: 14,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                                  border: InputBorder.none,
                                                  focusedBorder: InputBorder.none,
                                                  enabledBorder: InputBorder.none,
                                                  hintText: "100.0",
                                                  hintStyle: AppTheme.titleMedium.copyWith(
                                                    color: Colors.grey.shade400,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                onChanged: (val) {
                                                  // Optional: Handle changes if needed
                                                },
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
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}