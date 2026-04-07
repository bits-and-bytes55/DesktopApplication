import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class UnitContextEntry {
  const UnitContextEntry({
    required this.label,
    required this.paramNumber,
  });

  final String label;
  final String paramNumber;
}

class UnitContextBanner extends StatelessWidget {
  const UnitContextBanner({
    super.key,
    required this.title,
    required this.entries,
  });

  final String title;
  final List<UnitContextEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OptionsController>()) {
      return const SizedBox.shrink();
    }

    final controller = Get.find<OptionsController>();

    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.straighten,
                  size: 15,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$title units: ${controller.activeUnitSystemLabel}',
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries
                  .map(
                    (entry) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        '${entry.label}: ${AppUnits.stripBrackets(AppUnits.displayUnit(entry.paramNumber))}',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}
