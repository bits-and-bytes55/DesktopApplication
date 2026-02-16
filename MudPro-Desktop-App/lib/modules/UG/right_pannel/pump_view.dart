import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/UG_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PumpView extends StatelessWidget {
  PumpView({super.key});
  final c = Get.find<UgController>();

  static const rowH = 32.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
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
        child: Column(
          children: [
            _headerRow(),
            Expanded(child: _tableBody()),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _headerRow() {
    return Column(
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            gradient: AppTheme.headerGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.precision_manufacturing, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text(
                "Pump Configuration",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      "${c.pumps.length} pumps",
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        
        // 主表头
        Container(
          height: rowH,
          decoration: BoxDecoration(
            color: const Color(0xfff0f9ff),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            children: _addDividers([
              const _HCell('#', flex: 1),
              const _HCell('Type', flex: 2),
              const _HCell('Model', flex: 3),
              const _HCell('Liner ID\n(in)', flex: 2),
              const _HCell('Rod OD\n(in)', flex: 2),
              const _HCell('Stk. Length\n(in)', flex: 2),
              const _HCell('Efficiency\n(%)', flex: 2),
              const _HCell('Disp.\n(bbl/stk)', flex: 2),
              const _HCell('Max. Pump P.\n(psi)', flex: 2),
              const _HCell('Max. HP\n(HP)', flex: 2),
              
              // Surface Line 主列（包含两个子列）
              Expanded(
                flex: 4, // 给这个组合列更多的空间
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      // Surface Line 主标题
                      Container(
                        height: rowH / 2,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                        child: const Text(
                          'Surface Line',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      // 两个子列
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.grey.shade300, width: 1),
                                  ),
                                ),
                                child: const Text(
                                  'Length\n(m)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'ID\n(in)',
                                  textAlign: TextAlign.center,
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
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ================= BODY =================
  Widget _tableBody() {
    return ListView.builder(
      itemCount: 12,
      itemBuilder: (_, i) {
        final hasData = i < c.pumps.length;
        final p = hasData ? c.pumps[i] : null;

        return Container(
          height: rowH,
          decoration: BoxDecoration(
            color: i.isEven ? Colors.white : const Color(0xfffafafa),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
          ),
          child: Row(
            children: _addDividers([
              _cellText('${i + 1}', flex: 1),
              _editable(p?.type, flex: 2),
              _editable(p?.model, flex: 3),
              _editable(p?.linerId, flex: 2),
              _editable(p?.rodOd, flex: 2),
              _editable(p?.strokeLength, flex: 2),
              _editable(p?.efficiency, flex: 2),
              _editable(p?.displacement, flex: 2),
              _editable(p?.maxPumpP, flex: 2),
              _editable(p?.maxHp, flex: 2),
              
              // Surface Line 数据单元格（分为两个子单元格）
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Length (m) 子单元格
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                          ),
                          child: _editable(p?.surfaceLen, flex: 1),
                        ),
                      ),
                      // ID (in) 子单元格
                      Expanded(
                        flex: 1,
                        child: _editable(p?.surfaceId, flex: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ================= HELPER =================
  List<Widget> _addDividers(List<Widget> widgets) {
    final List<Widget> result = [];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        // 检查当前widget是否是Surface Line列（通过检查是否是Expanded）
        if (widgets[i] is! Expanded || i < 9) { // 前9列加分隔线
          result.add(
            Container(
              width: 1,
              color: Colors.grey.shade200,
              height: double.infinity,
            ),
          );
        }
      }
    }
    return result;
  }

  // ================= CELLS =================
  Widget _cellText(String t, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          t,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _editable(RxString? value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Obx(() => c.isLocked.value || value == null
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  value?.value ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            : Container(
                decoration:  BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: TextField(
                  controller: TextEditingController(text: value.value),
                  onChanged: (v) => value.value = v,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
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

// ================= HEADER CELL =================
class _HCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}