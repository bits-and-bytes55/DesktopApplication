import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/other_vol_addition_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class OtherVolAdditionActiveSystemView extends StatelessWidget {
  OtherVolAdditionActiveSystemView({super.key});

  final OtherVolAdditionController controller =
      Get.put(OtherVolAdditionController());
  final DashboardController dashboardController = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Other Vol. Addition - Active System',
            style: AppTheme.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 380,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Container(
                      height: 216,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  }

                  return Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                    columnWidths: const {
                      0: FixedColumnWidth(226),
                      1: FixedColumnWidth(152),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _headerRow(),
                      _inputRow(
                        'Formation',
                        controller.formationController,
                      ),
                      _inputRow(
                        'Cuttings',
                        controller.cuttingsController,
                      ),
                      _inputRow(
                        'Volume Not Fluid',
                        controller.volumeNotFluidController,
                      ),
                      _blankRow(),
                      _blankRow(),
                    ],
                  );
                }),
              ),
              const SizedBox(width: 8),
              _helpButton(context),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: const [
        _HeaderCell('Addition'),
        _HeaderCell('Vol.\n(bbl)'),
      ],
    );
  }

  TableRow _inputRow(String label, TextEditingController textController) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 11,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: Obx(
            () => TextField(
              controller: textController,
              enabled: !dashboardController.isLocked.value,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                filled: true,
                fillColor: dashboardController.isLocked.value
                    ? Colors.grey.shade100
                    : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _blankRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        const SizedBox(height: 32),
        Container(height: 32, color: Colors.white),
      ],
    );
  }

  Widget _helpButton(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          side: BorderSide(color: Colors.grey.shade400),
          backgroundColor: Colors.grey.shade100,
        ),
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Other Vol. Addition'),
              content: const Text(
                'Formation, Cuttings, and Volume Not Fluid are added to Active System end volume in bbl.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        child: Icon(
          Icons.question_mark,
          size: 16,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
