import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/UG_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class ReportView extends StatelessWidget {
  ReportView({super.key});

  final c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ================= LEFT SECTION =================
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // HEADER
                    Row(
                      children: [
                        Icon(Icons.calculate, size: 16, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Hydraulics Calculation Factors',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_getSelectedCount()} selected',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Divider(height: 20, color: Colors.grey.shade200),

                    const Text(
                      'Factors Considered in Hydraulics Calculation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    SizedBox(height: 16),

                    _check('ROP', c.considerROP, 
                      description: 'Rate of Penetration influences hydraulic efficiency'),
                    SizedBox(height: 12),
                    _check('RPM', c.considerRPM,
                      description: 'Revolutions Per Minute affect cuttings transport'),
                    SizedBox(height: 12),
                    _check('Eccentricity', c.considerEccentricity,
                      description: 'Pipe eccentricity in annulus calculations'),
                    
                    SizedBox(height: 20),
                    
                    // FOOTER NOTE
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Color(0xfff0f9ff),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: AppTheme.infoColor),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected factors will be included in hydraulic calculations and reports',
                              style: TextStyle(
                                fontSize: 11,
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
            ),
          ),

          SizedBox(width: 12),

          // ================= RIGHT SECTION =================
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // HEADER
                    Row(
                      children: [
                        Icon(Icons.science, size: 16, color: AppTheme.secondaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Rheology Settings',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    Divider(height: 20, color: Colors.grey.shade200),

                    const Text(
                      'Rheology Model Configuration',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    SizedBox(height: 16),

                    _check('Multi-rheology', c.multiRheology,
                      description: 'Use multiple rheology models for different flow regimes'),
                    
                    SizedBox(height: 20),
                    
                    // ADDITIONAL OPTIONS
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Color(0xfff8f9fa),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Advanced Options',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.model_training, size: 12, color: AppTheme.textSecondary),
                              SizedBox(width: 8),
                              Text(
                                'Power Law Model',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.tune, size: 12, color: AppTheme.textSecondary),
                              SizedBox(width: 8),
                              Text(
                                'Bingham Plastic',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    Spacer(),
                    
                    // ACTION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: c.isLocked.value ? null : () {
                              // Save configuration
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: c.isLocked.value ? null : () {
                              // Reset to defaults
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Reset',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CHECK ROW =================
  Widget _check(String text, RxBool value, {String? description}) {
    return Obx(() => Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: value.value ? Color(0xffe8f5e9) : Color(0xfff8f9fa),
            border: Border.all(
              color: value.value ? AppTheme.successColor : Colors.grey.shade200,
              width: value.value ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: description != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: value.value ? AppTheme.successColor : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: value.value ? AppTheme.successColor : Colors.grey.shade400,
                  ),
                ),
                child: Checkbox(
                  value: value.value,
                  onChanged: c.isLocked.value
                      ? null
                      : (v) => value.value = v!,
                  activeColor: AppTheme.successColor,
                  checkColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (description != null) ...[
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value.value)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppTheme.successColor,
                ),
            ],
          ),
        ));
  }

  int _getSelectedCount() {
    int count = 0;
    if (c.considerROP.value) count++;
    if (c.considerRPM.value) count++;
    if (c.considerEccentricity.value) count++;
    if (c.multiRheology.value) count++;
    return count;
  }
}