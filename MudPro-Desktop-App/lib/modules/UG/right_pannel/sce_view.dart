import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/UG_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SceView extends StatelessWidget {
  SceView({super.key});
  final c = Get.find<UgController>();

  static const rowH = 32.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= SHAKER =================
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
                children: [
                  _sectionTitle('Shaker Equipment'),
                  Expanded(
                    child: SingleChildScrollView(
                      primary: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headerRow(['Shaker', 'Model', 'No. of Screen', 'Plot']),
                          ..._shakerBodyRows(),
                          if (c.shakers.isEmpty)
                            Container(
                              height: 100,
                              alignment: Alignment.center,
                              child: Text(
                                'No shakers configured',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ================= OTHER SCE =================
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
              child: Column(
                children: [
                  _sectionTitle('Other SCE Equipment'),
                  Expanded(
                    child: SingleChildScrollView(
                      primary: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _headerRow(['Type', 'Model 1', 'Model 2', 'Model 3', 'Plot']),
                          ..._otherSceBodyRows(),
                          if (c.otherSce.isEmpty)
                            Container(
                              height: 100,
                              alignment: Alignment.center,
                              child: Text(
                                'No other SCE configured',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _sectionTitle(String title) {
    return Container(
      height: 36,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            title.contains('Shaker') ? Icons.vibration : Icons.build,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER ROW =================
  Widget _headerRow(List<String> headers) {
    return Container(
      height: rowH,
      decoration: BoxDecoration(
        color: Color(0xfff0f9ff),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: headers
            .map(
              (h) => Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Text(
                    h,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ================= SHAKER BODY ROWS =================
  List<Widget> _shakerBodyRows() {
    return List.generate(25, (i) {
      final hasData = i < c.shakers.length;
      final s = hasData ? c.shakers[i] : null;
      
      return Container(
        height: rowH,
        decoration: BoxDecoration(
          color: i.isEven ? Colors.white : Color(0xfffafafa),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: Row(
          children: [
            _shakerCell(hasData ? s!.shaker : '', flex: 1),
            _shakerCell(hasData ? s!.model.value : '', flex: 3),
            _shakerCell(hasData ? s!.screens.value : '', flex: 2),
            _checkCell(hasData ? s!.plot : RxBool(false), flex: 1),
          ],
        ),
      );
    });
  }

  // ================= OTHER SCE BODY ROWS =================
  List<Widget> _otherSceBodyRows() {
    return List.generate(12, (i) {
      final hasData = i < c.otherSce.length;
      final o = hasData ? c.otherSce[i] : null;
      
      return Container(
        height: rowH,
        decoration: BoxDecoration(
          color: i.isEven ? Colors.white : Color(0xfffafafa),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: Row(
          children: [
            _otherSceCell(hasData ? o!.type : '', flex: 1),
            _otherSceCell(hasData ? o!.model1.value : '', flex: 1),
            _otherSceCell(hasData ? o!.model2.value : '', flex: 1),
            _otherSceCell(hasData ? o!.model3.value : '', flex: 1),
            _checkCell(hasData ? o!.plot : RxBool(false), flex: 1),
          ],
        ),
      );
    });
  }

  // ================= CELL WIDGETS =================
  Widget _shakerCell(String value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: value.isEmpty ? Colors.grey.shade400 : AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _otherSceCell(String value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Obx(() => c.isLocked.value
            ? Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: value.isEmpty ? Colors.grey.shade400 : AppTheme.textSecondary,
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: TextField(
                  controller: TextEditingController(text: value),
                  onChanged: (v) {
                    if (value.isNotEmpty) {
                      // Update logic here
                    }
                  },
                  style: TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              )),
      ),
    );
  }

  Widget _checkCell(RxBool value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Obx(() => Container(
              decoration: BoxDecoration(
                color: value.value ? Color(0xffe8f5e9) : Color(0xfff5f5f5),
                borderRadius: BorderRadius.circular(4),
              ),
              margin: EdgeInsets.symmetric(horizontal: 12),
              child: Checkbox(
                value: value.value,
                onChanged: c.isLocked.value ? null : (x) => value.value = x!,
                activeColor: AppTheme.successColor,
                checkColor: Colors.white,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
      ),
    );
  }
}