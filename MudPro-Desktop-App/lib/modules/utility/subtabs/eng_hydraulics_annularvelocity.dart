import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/options/widgets/unit_context_banner.dart';
import 'package:mudpro_desktop_app/modules/utility/controller/engineering_tools_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class HydraulicsAnnularVelocity extends StatelessWidget {
  const HydraulicsAnnularVelocity({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EngineeringToolsController>();
    final optionsController = Get.find<OptionsController>();

    return Obx(
      () {
        final unitKey = optionsController.activeUnitSystemLabel;
        return KeyedSubtree(
          key: ValueKey(unitKey),
          child: LayoutBuilder(
            builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 800;

          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.infoColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.infoColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Annular velocity is calculated in the active Unit settings and converted before the result is shown.',
                        style: AppTheme.caption.copyWith(color: AppTheme.infoColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const UnitContextBanner(
                title: 'Annular velocity',
                entries: [
                  UnitContextEntry(label: 'Pump output', paramNumber: '18'),
                  UnitContextEntry(label: 'Hole size', paramNumber: '2'),
                  UnitContextEntry(label: 'Pipe OD', paramNumber: '2'),
                  UnitContextEntry(label: 'Result', paramNumber: '13'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isSmallScreen
                    ? _buildMobileLayout(controller)
                    : _buildDesktopLayout(controller),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formula Used',
                      style: AppTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AV = (24.51 x Pump Output) / (Hole Size^2 - Pipe OD^2)',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Base formula units: Pump Output (bpm), Hole Size and Pipe OD (in), AV (ft/min).',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Displayed values follow the active units above.',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildDesktopLayout(EngineeringToolsController controller) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 450,
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                _inputFieldWithRow(
                  'Pump Output',
                  AppUnits.stripBrackets(AppUnits.displayUnit('18')),
                  controller.pumpOutput,
                  'Enter value',
                ),
                const SizedBox(height: 16),
                _inputFieldWithRow(
                  'Hole Size',
                  AppUnits.stripBrackets(AppUnits.displayUnit('2')),
                  controller.holeSize,
                  'Enter value',
                ),
                const SizedBox(height: 16),
                _inputFieldWithRow(
                  'Pipe OD',
                  AppUnits.stripBrackets(AppUnits.displayUnit('2')),
                  controller.pipeOD,
                  'Enter value',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
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
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: controller.resetAnnularVelocity,
                      style: AppTheme.secondaryButtonStyle,
                      child: Text('Reset', style: AppTheme.caption),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
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
              child: Obx(() {
                final result = controller.annularVelocity.value;
                final hasResult = result != null;
                final resultUnit = AppUnits.stripBrackets(AppUnits.displayUnit('13'));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculation Result',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!hasResult)
                      _emptyState(300)
                    else
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.successColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Annular Velocity',
                                  style: AppTheme.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${AppUnits.formatNumber(result, precision: 2)} $resultUnit',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info, size: 14, color: AppTheme.infoColor),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Calculated using the current Unit settings.',
                                          style: AppTheme.caption.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Input Summary',
                                  style: AppTheme.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _inputSummaryRow(
                                  'Pump Output',
                                  '${controller.pumpOutput.value} ${AppUnits.stripBrackets(AppUnits.displayUnit('18'))}',
                                ),
                                const SizedBox(height: 8),
                                _inputSummaryRow(
                                  'Hole Size',
                                  '${controller.holeSize.value} ${AppUnits.stripBrackets(AppUnits.displayUnit('2'))}',
                                ),
                                const SizedBox(height: 8),
                                _inputSummaryRow(
                                  'Pipe OD',
                                  '${controller.pipeOD.value} ${AppUnits.stripBrackets(AppUnits.displayUnit('2'))}',
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildMobileLayout(EngineeringToolsController controller) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                _inputFieldWithRow(
                  'Pump Output',
                  AppUnits.stripBrackets(AppUnits.displayUnit('18')),
                  controller.pumpOutput,
                  'Enter value',
                ),
                const SizedBox(height: 16),
                _inputFieldWithRow(
                  'Hole Size',
                  AppUnits.stripBrackets(AppUnits.displayUnit('2')),
                  controller.holeSize,
                  'Enter value',
                ),
                const SizedBox(height: 16),
                _inputFieldWithRow(
                  'Pipe OD',
                  AppUnits.stripBrackets(AppUnits.displayUnit('2')),
                  controller.pipeOD,
                  'Enter value',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
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
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: controller.resetAnnularVelocity,
                      style: AppTheme.secondaryButtonStyle,
                      child: Text('Reset', style: AppTheme.caption),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
            child: Obx(() {
              final result = controller.annularVelocity.value;
              final hasResult = result != null;
              final resultUnit = AppUnits.stripBrackets(AppUnits.displayUnit('13'));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculation Result',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!hasResult)
                    _emptyState(220)
                  else
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.successColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Annular Velocity',
                                style: AppTheme.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${AppUnits.formatNumber(result, precision: 2)} $resultUnit',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Input Summary',
                                style: AppTheme.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _inputSummaryRow(
                                'Pump Output',
                                '${controller.pumpOutput.value} ${AppUnits.stripBrackets(AppUnits.displayUnit('18'))}',
                              ),
                              const SizedBox(height: 8),
                              _inputSummaryRow(
                                'Hole Size',
                                '${controller.holeSize.value} ${AppUnits.stripBrackets(AppUnits.displayUnit('2'))}',
                              ),
                              const SizedBox(height: 8),
                              _inputSummaryRow(
                                'Pipe OD',
                                '${controller.pipeOD.value} ${AppUnits.stripBrackets(AppUnits.displayUnit('2'))}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(double height) {
    return Container(
      height: height,
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
            'Enter values and click Calculate',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputFieldWithRow(
    String label,
    String unit,
    RxString value,
    String placeholder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                unit,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: TextEditingController(text: value.value),
              onChanged: (newValue) => value.value = newValue,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTheme.caption.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                hintText: placeholder,
                hintStyle: AppTheme.caption.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputSummaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndCalculate(EngineeringToolsController controller) {
    if (controller.pumpOutput.value.isEmpty ||
        controller.holeSize.value.isEmpty ||
        controller.pipeOD.value.isEmpty) {
      _showRequiredFieldsAlert();
      return;
    }

    controller.calculateAnnularVelocity();
  }

  void _showRequiredFieldsAlert() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 280,
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
                'Required Fields',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please fill all the input fields to calculate annular velocity.',
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
