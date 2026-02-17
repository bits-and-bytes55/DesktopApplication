import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/UG_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PadView extends StatelessWidget {
  PadView({super.key});

  final c = Get.find<UgController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= LEFT TABLE =================
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.headerGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Location Details",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // TABLE CONTENT
                  Expanded(
                    child: SingleChildScrollView(
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                          verticalInside: BorderSide(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                          left: BorderSide(color: Colors.transparent),
                          right: BorderSide(color: Colors.transparent),
                          top: BorderSide(color: Colors.transparent),
                          bottom: BorderSide(color: Colors.transparent),
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(200),
                        },
                        children: [
                          // LOCATION (RADIO BUTTONS ROW)
                          TableRow(
                            decoration: BoxDecoration(
                              color: Color(0xfff8f9fa),
                            ),
                            children: [
                              _labelCell('Location'),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Obx(() => Row(
                                      children: [
                                        _radio('Land'),
                                        const SizedBox(width: 20),
                                        _radio('Offshore'),
                                      ],
                                    )),
                              ),
                            ],
                          ),
                          
                          _row('Field/Block', 'Umm Gudair (UG)'),
                          _row('Rig', 'SP-175'),
                          _row('County/Parish/Offshore Area', 'Kuwait'),
                          _row('State/Province', 'West Kuwait'),
                          _row('Country', 'Kuwait'),
                          _row('Stock Point', 'Burgan'),
                          _row('Operator', 'Kuwait Oil Company'),
                          _row('Operator Rep.', 'Chandra Shekhar'),
                          _row('Contractor', 'Sinopec'),
                          _row('Contractor Rep.', 'Yin'),
                          _row('Air Gap', ''),
                          _row('Water Depth', ''),
                          _row('Riser OD', ''),
                          _row('Riser ID', ''),
                          _row('Choke Line ID', ''),
                          _row('Kill Line ID', ''),
                          _row('Boost Line ID', ''),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ================= RIGHT SIDE =================
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // LOGO BOX
                Container(
                  height: 220,
                  width: double.infinity,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Kuwait Oil Company',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'LOGO',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // MEMO BOX
                Expanded(
                  child: Container(
                    width: double.infinity,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xff6C9BCF), Color(0xff8BB8E8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notes, color: Colors.white, size: 14),
                              SizedBox(width: 8),
                              Text(
                                "Memo",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Obx(() => TextField(
                                  enabled: !c.isLocked.value,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: InputDecoration(
                                    hintText: 'Enter memo here...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textPrimary,
                                  ),
                                )),
                          ),
                        ),
                      ],
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

  // ================= HELPERS =================

  TableRow _row(String label, String value) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      children: [
        _labelCell(label),
        _valueCell(value),
      ],
    );
  }

  Widget _labelCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xfff8f9fa),
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _valueCell(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Obx(() => c.isLocked.value
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          : TextFormField(
              initialValue: value,
              style: TextStyle(fontSize: 11, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                border: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                ),
              ),
            )),
    );
  }

  Widget _radio(String text) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.shade100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: text,
            groupValue: c.location.value,
            onChanged: c.isLocked.value ? null : (v) => c.location.value = v!,
            visualDensity: VisualDensity.compact,
            activeColor: AppTheme.primaryColor,
          ),
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}