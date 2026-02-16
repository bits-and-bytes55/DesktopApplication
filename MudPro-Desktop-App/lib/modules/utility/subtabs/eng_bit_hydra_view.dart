import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/bit_hydra_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class BitHydraulicsPage extends StatelessWidget {
  const BitHydraulicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(BitHydraulicsController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 1024;
        final isVerySmallScreen = constraints.maxWidth < 768;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: isSmallScreen ? _buildMobileLayout(c, isVerySmallScreen) : _buildDesktopLayout(c),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BitHydraulicsController c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= LEFT INPUT PANEL =================
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    "Input Parameters",
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Required fields: MW, Pump output, Standpipe pressure, Bit size",
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Input Fields
                  _requiredRow("MW (ppg)", c.mw, "10.5"),
                  _row("Pump output (gpm)", c.pumpOutput, "500"),
                  _row("Standpipe pressure (psi)", c.standpipePressure, "3000"),
                  _row("Bit size (in)", c.bitSize, "8.5"),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Jet Nozzles Section Title
                  Text(
                    "Jet Nozzles (1/32 in)",
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Jet Nozzles Grid
                  Container(
                    height: 200,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 4,
                      ),
                      itemCount: 10,
                      itemBuilder: (context, i) {
                        return _jetNozzleRow("Jet ${i + 1}", c.jetNozzles[i], i == 0 ? "14" : "");
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Calculate Button
                  ElevatedButton(
                    onPressed: () => _validateAndCalculate(c),
                    style: AppTheme.primaryButtonStyle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calculate, size: 14),
                        const SizedBox(width: 6),
                        Text("Calculate", style: AppTheme.caption.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 20),

        // ================= RIGHT RESULTS PANEL =================
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        "Calculation Results",
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Results based on input parameters",
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Check if we have results
                      if (_hasResults(c))
                        _buildResultsGrid(c)
                      else
                        Container(
                          height: 400,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calculate_outlined,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Enter values and click Calculate",
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BitHydraulicsController c, bool isVerySmallScreen) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Input Panel
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Input Parameters",
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Required fields: MW, Pump output, Standpipe pressure, Bit size",
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Required Fields
                  _requiredRow("MW (ppg)", c.mw, "10.5"),
                  _row("Pump output (gpm)", c.pumpOutput, "500"),
                  _row("Standpipe pressure (psi)", c.standpipePressure, "3000"),
                  _row("Bit size (in)", c.bitSize, "8.5"),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Jet Nozzles
                  Text(
                    "Jet Nozzles (1/32 in)",
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Jet Nozzles Grid - Adjust columns based on screen size
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isVerySmallScreen ? 2 : 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 3,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, i) {
                      return _jetNozzleRow("Jet ${i + 1}", c.jetNozzles[i], i == 0 ? "14" : "");
                    },
                  ),

                  const SizedBox(height: 20),

                  // Calculate Button
                  ElevatedButton(
                    onPressed: () => _validateAndCalculate(c),
                    style: AppTheme.primaryButtonStyle.copyWith(
                      minimumSize: MaterialStateProperty.all(const Size(double.infinity, 40)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calculate, size: 14),
                        const SizedBox(width: 6),
                        Text("Calculate", style: AppTheme.caption.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Results Panel
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Calculation Results",
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Results based on input parameters",
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_hasResults(c))
                      _buildResultsGrid(c)
                    else
                      Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calculate_outlined,
                              size: 36,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Enter values and click Calculate",
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requiredRow(String label, RxString controller, String example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Required",
                  style: AppTheme.caption.copyWith(
                    color: Colors.red.shade600,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: controller.value),
                    onChanged: (v) => controller.value = v,
                    keyboardType: TextInputType.number,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      hintText: "Enter",
                      hintStyle: AppTheme.caption.copyWith(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    "e.g. $example",
                    style: AppTheme.caption.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, RxString controller, String example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: controller.value),
                    onChanged: (v) => controller.value = v,
                    keyboardType: TextInputType.number,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      hintText: "Enter",
                      hintStyle: AppTheme.caption.copyWith(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    "e.g. $example",
                    style: AppTheme.caption.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _jetNozzleRow(String label, RxString controller, String example) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: controller.value),
              onChanged: (v) => controller.value = v,
              keyboardType: TextInputType.number,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                hintText: example.isNotEmpty ? "e.g. $example" : "Enter",
                hintStyle: AppTheme.caption.copyWith(
                  color: Colors.grey.shade400,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(BitHydraulicsController c) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        List<Map<String, dynamic>> results = [
          {"label": "Nozzle area (in²)", "value": c.nozzleArea.value},
          {"label": "Nozzle velocity (ft/s)", "value": c.nozzleVelocity.value},
          {"label": "Bit P. drop (psi)", "value": c.bitPressureDrop.value},
          {"label": "Hydraulic horsepower (HP)", "value": c.hydraulicHP.value},
          {"label": "Bit HHP / unit bit area", "value": c.hhpPerArea.value},
          {"label": "P. drop (%)", "value": c.pressureDropPercent.value},
          {"label": "Jet impact force (lb)", "value": c.jetImpactForce.value},
        ];

        final result = results[index];
        final value = result["value"];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                result["label"],
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value == null ? "0.00" : value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasResults(BitHydraulicsController c) {
    return c.nozzleArea.value != null ||
        c.nozzleVelocity.value != null ||
        c.bitPressureDrop.value != null ||
        c.hydraulicHP.value != null ||
        c.hhpPerArea.value != null ||
        c.pressureDropPercent.value != null ||
        c.jetImpactForce.value != null;
  }

  // Validation method
  void _validateAndCalculate(BitHydraulicsController c) {
    List<String> requiredFields = [];
    List<String> fieldNames = [];

    // Check required fields
    if (c.mw.value.isEmpty) {
      requiredFields.add(c.mw.value);
      fieldNames.add("MW (ppg)");
    }
    if (c.pumpOutput.value.isEmpty) {
      requiredFields.add(c.pumpOutput.value);
      fieldNames.add("Pump output (gpm)");
    }
    if (c.standpipePressure.value.isEmpty) {
      requiredFields.add(c.standpipePressure.value);
      fieldNames.add("Standpipe pressure (psi)");
    }
    if (c.bitSize.value.isEmpty) {
      requiredFields.add(c.bitSize.value);
      fieldNames.add("Bit size (in)");
    }

    // Check if fields are greater than 0
    List<String> zeroFields = [];
    try {
      if (c.mw.value.isNotEmpty && double.parse(c.mw.value) <= 0) {
        zeroFields.add("MW (ppg)");
      }
      if (c.pumpOutput.value.isNotEmpty && double.parse(c.pumpOutput.value) <= 0) {
        zeroFields.add("Pump output (gpm)");
      }
      if (c.standpipePressure.value.isNotEmpty && double.parse(c.standpipePressure.value) <= 0) {
        zeroFields.add("Standpipe pressure (psi)");
      }
      if (c.bitSize.value.isNotEmpty && double.parse(c.bitSize.value) <= 0) {
        zeroFields.add("Bit size (in)");
      }
    } catch (e) {
      // If parsing fails, show validation error
      _showValidationAlert("Invalid Input", "Please enter valid numeric values in all fields.");
      return;
    }

    if (requiredFields.isNotEmpty) {
      // Show missing fields alert
      final fieldList = fieldNames.join(", ");
      _showValidationAlert(
        "Required Fields Missing",
        "Please fill the following required fields:\n\n$fieldList",
      );
      return;
    }

    if (zeroFields.isNotEmpty) {
      // Show zero value alert
      final zeroFieldList = zeroFields.join(", ");
      _showValidationAlert(
        "Invalid Values",
        "The following fields must be greater than 0:\n\n$zeroFieldList",
      );
      return;
    }

    // If all validations pass, proceed with calculation
    c.calculateBitHydraulics();
  }

  void _showValidationAlert(String title, String message) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.all(16),
        content: Container(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                title,
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                message,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // OK button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    "OK",
                    style: AppTheme.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}