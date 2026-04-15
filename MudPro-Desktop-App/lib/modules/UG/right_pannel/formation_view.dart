import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/UG_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class FormationView extends StatelessWidget {
  FormationView({super.key});
  final c = Get.find<UgController>();

  static const rowH = 32.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ================= TOP BAR =================
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
            child: Row(
              children: [
                // CHECKBOX
                Obx(() => Container(
                      decoration: BoxDecoration(
                        color: c.poreFromTop.value
                            ? AppTheme.successColor.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: c.poreFromTop.value
                              ? AppTheme.successColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Checkbox(
                        value: c.poreFromTop.value,
                        onChanged: c.isLocked.value
                            ? null
                            : (v) => c.poreFromTop.value = v!,
                        activeColor: AppTheme.successColor,
                        checkColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    )),
                SizedBox(width: 8),
                Text(
                  'Pore and Fracture (from top down)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),

                SizedBox(width: 20),

                // DROPDOWN
                Obx(() => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButton<String>(
                        value: c.formationMode.value,
                        items: const [
                          DropdownMenuItem(
                            value: 'Density',
                            child: Text('Density',
                                style: TextStyle(fontSize: 11)),
                          ),
                          DropdownMenuItem(
                            value: 'Gradient',
                            child: Text('Gradient',
                                style: TextStyle(fontSize: 11)),
                          ),
                          DropdownMenuItem(
                            value: 'Pressure',
                            child: Text('Pressure',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ],
                        onChanged: c.isLocked.value
                            ? null
                            : (v) => c.formationMode.value = v!,
                        isDense: true,
                        underline: SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, size: 16),
                      ),
                    )),

                Spacer(),

                // WARNING BUTTON
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xfffff3cd),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Color(0xffffeaa7)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.warning_amber_rounded,
                        size: 18, color: Color(0xff856404)),
                    onPressed: () => _showFormationWarning(context),
                    tooltip: 'View warnings',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ================= TABLE =================
          Expanded(
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
                  _header(),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Column(
      children: [
        Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: AppTheme.headerGradient,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.layers, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                "Formation Data",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  "${c.formations.length} formations",
                  style: TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: rowH,
          color: Color(0xfff0f9ff),
          child: Row(
            children: [
              _h('#', 1),
              _h('Description', 3),
              _h('Btm TVD\n(m)', 2),
              _group('Pore', ['ppg', 'psi/ft', 'psi']),
              _group('Frac.', ['ppg', 'psi/ft', 'psi']),
              _h('Lithology', 3),
            ],
          ),
        ),
        Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }

  // ================= BODY =================
  Widget _body() {
    return ListView.builder(
      itemCount: 25,
      itemBuilder: (_, i) {
        final row = i < c.formations.length ? c.formations[i] : null;

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
              _text('${i + 1}', 1),
              _edit(row?.description, 3),
              _edit(row?.tvd, 2),
              _edit(row?.porePpg, 1),
              _edit(row?.poreGrad, 1),
              _edit(row?.porePsi, 1),
              _edit(row?.fracPpg, 1),
              _edit(row?.fracGrad, 1),
              _edit(row?.fracPsi, 1),
              _text('No image data', 3),
            ],
          ),
        );
      },
    );
  }

  // ================= HELPERS =================
  List<Widget> _cells(List<Widget> w) {
    final r = <Widget>[];
    for (int i = 0; i < w.length; i++) {
      r.add(w[i]);
      if (i < w.length - 1) {
        r.add(
          Container(
            width: 1,
            color: Colors.grey.shade200,
            height: double.infinity,
          ),
        );
      }
    }
    return r;
  }

  Widget _h(String t, int flex) => Expanded(
        flex: flex,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Text(
            t,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      );

  Widget _group(String title, List<String> subs) {
    return Expanded(
      flex: subs.length,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: rowH / 2,
              alignment: Alignment.center,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Container(
              height: rowH / 2,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: subs
                    .map((e) => Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                    color: Colors.grey.shade200, width: 1),
                              ),
                            ),
                            child: Text(
                              e,
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFormationWarning(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 520,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xffDC2626), Color(0xffEF4444)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Warning',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // TABLE
              Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    // TABLE HEADER
                    Container(
                      height: 32,
                      color: Color(0xfff0f9ff),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                      color: Colors.grey.shade200, width: 1),
                                ),
                              ),
                              child: Text(
                                'Title',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Message',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ROWS
                    _warningRow(
                      'Pad - Formation',
                      'Formation table should not be empty.',
                    ),
                    _warningRow(
                      'Pad - Formation',
                      'Reservoir Pressure table should not be empty.',
                    ),
                  ],
                ),
              ),

              // FOOTER
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xfff8f9fa),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _warningRow(String title, String msg) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                msg,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _text(String t, int flex) => Expanded(
        flex: flex,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Text(
            t,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _edit(RxString? v, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Obx(() => c.isLocked.value || v == null
            ? Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  v?.value ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
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
                  controller: TextEditingController(text: v.value),
                  onChanged: (x) => v.value = x,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
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
}