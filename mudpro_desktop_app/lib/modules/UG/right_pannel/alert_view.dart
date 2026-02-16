import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/UG_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AlertView extends StatelessWidget {
  AlertView({super.key});
  final c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
        child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width / 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            
                // HEADER
                Row(
                  children: [
                    const Icon(Icons.security, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Safety Configuration',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Obx(() => Text(
                        '${double.tryParse(c.safetyMargin.value)?.toStringAsFixed(1) ?? '0.0'}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      )),
                    ),
                  ],
                ),
                
                const Divider(height: 20, color: Colors.grey),
            
                // ---------- SAFETY MARGIN INPUT ----------
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xfff8f9fa),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.margin, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'Safety Margin',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Obx(() => Text(
                              '${double.tryParse(c.safetyMargin.value)?.toStringAsFixed(1) ?? '0.0'}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            )),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Obx(() => Container(
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade300),
                                color: Colors.white,
                              ),
                              child: TextField(
                                enabled: !c.isLocked.value,
                                controller: TextEditingController(
                                  text: c.safetyMargin.value,
                                ),
                                onChanged: (v) => c.safetyMargin.value = v,
                                style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: InputBorder.none,
                                  hintText: 'Enter value',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                ),
                              ),
                            )),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            
                const SizedBox(height: 20),
            
                // ---------- DYNAMIC BAR ----------
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xfff8f9fa),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safety Status Indicator',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Obx(() {
                        final value = double.tryParse(c.safetyMargin.value) ?? 0;
                        final green = value.clamp(0, 80);
                        final yellow = value > 80 ? (value.clamp(80, 100) - 80) : 0;
                        final red = value > 100 ? value - 100 : 0;
            
                        return Container(
                          height: 24,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              if (green > 0)
                                Expanded(
                                  flex: (green * 10).toInt(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [const Color(0xff1E7F3F), const Color(0xff2E8B57)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${green.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (yellow > 0)
                                Expanded(
                                  flex: (yellow * 10).toInt(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [const Color(0xffE6C300), const Color(0xffFFD700)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${yellow.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (red > 0)
                                Expanded(
                                  flex: (red * 10).toInt(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [const Color(0xffC62828), const Color(0xffE53935)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${red.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // remaining empty
                              Expanded(
                                flex: ((100 - value.clamp(0, 100)) * 10).toInt(),
                                child: Container(),
                              ),
                            ],
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xff1E7F3F), const Color(0xff2E8B57)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Safe',
                            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xffE6C300), const Color(0xffFFD700)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Warning',
                            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xffC62828), const Color(0xffE53935)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Critical',
                            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            
                const SizedBox(height: 20),
            
                // ---------- LEGEND ----------
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xfff8f9fa),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.legend_toggle, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Safety Levels',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _legendRow(const Color(0xff1E7F3F), 'Safe Zone', '0 - 80%: Normal operating conditions'),
                      const SizedBox(height: 8),
                      _legendRow(const Color(0xffE6C300), 'Warning Zone', '80 - 100%: Monitor closely'),
                      const SizedBox(height: 8),
                      _legendRow(const Color(0xffC62828), 'Critical Zone', '> 100%: Immediate action required'),
                    ],
                  ),
                ),
            
                const SizedBox(height: 20),
            
                // ---------- ACTION BUTTONS ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: c.isLocked.value ? null : () {
                        // Save configuration
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Save Settings',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: c.isLocked.value ? null : () {
                        // Reset to defaults
                        c.safetyMargin.value = '80.0';
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
    );
  }

  Widget _legendRow(Color color, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
