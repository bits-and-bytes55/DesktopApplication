import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/options/widgets/unit_context_banner.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/bit_hydra_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class BitHydraulicsPage extends StatelessWidget {
  const BitHydraulicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<BitHydraulicsController>()
        ? Get.find<BitHydraulicsController>()
        : Get.put(BitHydraulicsController());
    final optionsController = Get.find<OptionsController>();

    return Obx(
      () {
        final unitKey = optionsController.activeUnitSystemLabel;
        return KeyedSubtree(
          key: ValueKey(unitKey),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 1024;
              final isVerySmallScreen = constraints.maxWidth < 768;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const UnitContextBanner(
                      title: 'Bit hydraulics',
                      entries: [
                        UnitContextEntry(label: 'MW', paramNumber: '33'),
                        UnitContextEntry(label: 'Pump output', paramNumber: '17'),
                        UnitContextEntry(label: 'Pressure', paramNumber: '22'),
                        UnitContextEntry(label: 'Bit size', paramNumber: '2'),
                        UnitContextEntry(label: 'Nozzle', paramNumber: '3'),
                        UnitContextEntry(label: 'Force', paramNumber: '20'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isSmallScreen
                          ? _buildMobileLayout(controller, isVerySmallScreen)
                          : _buildDesktopLayout(controller),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BitHydraulicsController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                  Text(
                    'Input Parameters',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All inputs are interpreted in the active unit system shown above.',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _requiredRow(
                    AppUnits.label('MW', '33'),
                    controller.mw,
                    'Enter',
                  ),
                  _row(
                    AppUnits.label('Pump output', '17'),
                    controller.pumpOutput,
                    'Enter',
                  ),
                  _row(
                    AppUnits.label('Standpipe pressure', '22'),
                    controller.standpipePressure,
                    'Enter',
                  ),
                  _row(
                    AppUnits.label('Bit size', '2'),
                    controller.bitSize,
                    'Enter',
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    AppUnits.label('Jet Nozzles', '3'),
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
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
                      itemBuilder: (context, index) {
                        return _jetNozzleRow(
                          'Jet ${index + 1}',
                          controller.jetNozzles[index],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _validateAndCalculate(controller),
                    style: AppTheme.primaryButtonStyle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calculate, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Calculate',
                          style: AppTheme.caption.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                      Text(
                        'Calculation Results',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Results are converted to the selected report units before display.',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_hasResults(controller))
                        _buildResultsGrid(controller)
                      else
                        _emptyState(380),
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

  Widget _buildMobileLayout(
    BitHydraulicsController controller,
    bool isVerySmallScreen,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                    'Input Parameters',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the current Unit settings for all inputs on this screen.',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _requiredRow(AppUnits.label('MW', '33'), controller.mw, 'Enter'),
                  _row(
                    AppUnits.label('Pump output', '17'),
                    controller.pumpOutput,
                    'Enter',
                  ),
                  _row(
                    AppUnits.label('Standpipe pressure', '22'),
                    controller.standpipePressure,
                    'Enter',
                  ),
                  _row(AppUnits.label('Bit size', '2'), controller.bitSize, 'Enter'),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    AppUnits.label('Jet Nozzles', '3'),
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    itemBuilder: (context, index) {
                      return _jetNozzleRow(
                        'Jet ${index + 1}',
                        controller.jetNozzles[index],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _validateAndCalculate(controller),
                    style: AppTheme.primaryButtonStyle.copyWith(
                      minimumSize: WidgetStateProperty.all(
                        const Size(double.infinity, 40),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calculate, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Calculate',
                          style: AppTheme.caption.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                      'Calculation Results',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculated values are shown in the currently selected units.',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_hasResults(controller))
                      _buildResultsGrid(controller)
                    else
                      _emptyState(220),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requiredRow(String label, RxString controller, String placeholder) {
    return _inputRow(
      label: label,
      controller: controller,
      placeholder: placeholder,
      required: true,
    );
  }

  Widget _row(String label, RxString controller, String placeholder) {
    return _inputRow(
      label: label,
      controller: controller,
      placeholder: placeholder,
    );
  }

  Widget _inputRow({
    required String label,
    required RxString controller,
    required String placeholder,
    bool required = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (required)
                Text(
                  'Required',
                  style: AppTheme.caption.copyWith(
                    color: Colors.red.shade600,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: TextEditingController(text: controller.value),
              onChanged: (value) => controller.value = value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTheme.caption.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                hintText: placeholder,
                hintStyle: AppTheme.caption.copyWith(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _jetNozzleRow(String label, RxString controller) {
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
              onChanged: (value) => controller.value = value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTheme.caption.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                hintText: 'Enter',
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

  Widget _buildResultsGrid(BitHydraulicsController controller) {
    final resultCards = [
      {
        'label': AppUnits.label('Nozzle area', '5'),
        'value': controller.nozzleArea.value,
      },
      {
        'label': AppUnits.label('Nozzle velocity', '14'),
        'value': controller.nozzleVelocity.value,
      },
      {
        'label': AppUnits.label('Bit P. drop', '22'),
        'value': controller.bitPressureDrop.value,
      },
      {
        'label': AppUnits.label('Hydraulic horsepower', '26'),
        'value': controller.hydraulicHP.value,
      },
      {
        'label': 'Bit HHP / unit area (${controller.hhpPerAreaUnit})',
        'value': controller.hhpPerArea.value,
      },
      {
        'label': 'P. drop (%)',
        'value': controller.pressureDropPercent.value,
      },
      {
        'label': AppUnits.label('Jet impact force', '20'),
        'value': controller.jetImpactForce.value,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: resultCards.length,
      itemBuilder: (context, index) {
        final result = resultCards[index];
        final value = result['value'] as double?;

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
                result['label']! as String,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value == null ? '0.00' : AppUnits.formatNumber(value, precision: 2),
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

  Widget _emptyState(double height) {
    return SizedBox(
      height: height,
      child: Center(
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
              'Enter values and click Calculate',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasResults(BitHydraulicsController controller) {
    return controller.nozzleArea.value != null ||
        controller.nozzleVelocity.value != null ||
        controller.bitPressureDrop.value != null ||
        controller.hydraulicHP.value != null ||
        controller.hhpPerArea.value != null ||
        controller.pressureDropPercent.value != null ||
        controller.jetImpactForce.value != null;
  }

  void _validateAndCalculate(BitHydraulicsController controller) {
    final missingFields = <String>[];
    final zeroFields = <String>[];

    if (controller.mw.value.isEmpty) {
      missingFields.add(AppUnits.label('MW', '33'));
    }
    if (controller.pumpOutput.value.isEmpty) {
      missingFields.add(AppUnits.label('Pump output', '17'));
    }
    if (controller.standpipePressure.value.isEmpty) {
      missingFields.add(AppUnits.label('Standpipe pressure', '22'));
    }
    if (controller.bitSize.value.isEmpty) {
      missingFields.add(AppUnits.label('Bit size', '2'));
    }

    try {
      if (controller.mw.value.isNotEmpty && double.parse(controller.mw.value) <= 0) {
        zeroFields.add(AppUnits.label('MW', '33'));
      }
      if (controller.pumpOutput.value.isNotEmpty &&
          double.parse(controller.pumpOutput.value) <= 0) {
        zeroFields.add(AppUnits.label('Pump output', '17'));
      }
      if (controller.standpipePressure.value.isNotEmpty &&
          double.parse(controller.standpipePressure.value) <= 0) {
        zeroFields.add(AppUnits.label('Standpipe pressure', '22'));
      }
      if (controller.bitSize.value.isNotEmpty &&
          double.parse(controller.bitSize.value) <= 0) {
        zeroFields.add(AppUnits.label('Bit size', '2'));
      }
    } catch (_) {
      _showValidationAlert(
        'Invalid Input',
        'Please enter valid numeric values in all fields.',
      );
      return;
    }

    if (missingFields.isNotEmpty) {
      _showValidationAlert(
        'Required Fields Missing',
        'Please fill the following required fields:\n\n${missingFields.join(', ')}',
      );
      return;
    }

    if (zeroFields.isNotEmpty) {
      _showValidationAlert(
        'Invalid Values',
        'The following fields must be greater than 0:\n\n${zeroFields.join(', ')}',
      );
      return;
    }

    controller.calculateBitHydraulics();
  }

  void _showValidationAlert(String title, String message) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Text(
                message,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: Get.back,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'OK',
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
