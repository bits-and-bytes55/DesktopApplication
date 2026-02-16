import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SurveyDataTab extends StatelessWidget {
  SurveyDataTab({super.key});

  final RxBool isLocked = true.obs;
  final ScrollController _horizontalScrollController = ScrollController();

  final headers = const [
    "#",
    "MD\n(ft)",
    "Inc\n(°)",
    "Azi\n(°)",
    "TVD\n(ft)",
    "Vsec\n(ft)",
    "N+/S-\n(ft)",
    "E+/W-\n(ft)",
    "Dogleg\n(°/100ft)",
  ];

  final List<List<String>> data = [
    ["1", "0.0", "0.00", "0.00", "0.0", "0.0", "0.0", "0.0", "0.06"],
    ["2", "1090.0", "0.63", "239.27", "1090.0", "6.0", "-3.1", "-5.2", "0.06"],
    ["3", "1167.0", "2.17", "245.94", "1167.0", "7.9", "-3.9", "-6.8", "2.01"],
    ["4", "1271.0", "4.31", "247.65", "1270.8", "13.7", "-6.2", "-12.3", "2.06"],
    ["5", "1369.0", "5.36", "250.22", "1368.4", "22.0", "-9.1", "-20.0", "1.09"],
    ["6", "1462.0", "6.32", "252.93", "1460.9", "31.4", "-12.1", "-29.0", "1.07"],
    ["7", "1565.0", "7.25", "255.78", "1559.8", "41.8", "-15.2", "-40.0", "1.06"],
    ["8", "1668.0", "8.17", "258.77", "1658.7", "53.2", "-18.5", "-52.1", "1.05"],
    ["9", "1771.0", "9.08", "261.90", "1757.6", "65.4", "-22.0", "-65.3", "1.04"],
    ["10", "1874.0", "9.98", "265.16", "1856.5", "78.5", "-25.6", "-79.5", "1.03"],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              _headerSection(),
              Expanded(child: _table()),
              const SizedBox(height: 12),
              _sidePanel(),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _table()),
              _toolButtons(),
              _annotationPanel(),
            ],
          );
        }
      },
    );
  }

  Widget _headerSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.table_chart, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            "Survey Data",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLocked.value 
                  ? AppTheme.errorColor.withOpacity(0.1)
                  : AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isLocked.value 
                    ? AppTheme.errorColor.withOpacity(0.3)
                    : AppTheme.successColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isLocked.value ? Icons.lock : Icons.lock_open,
                  size: 14,
                  color: isLocked.value ? AppTheme.errorColor : AppTheme.successColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isLocked.value ? "Locked" : "Editing",
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isLocked.value ? AppTheme.errorColor : AppTheme.successColor,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(width: 12),
          Obx(() => ElevatedButton(
            onPressed: () => isLocked.value = !isLocked.value,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLocked.value ? AppTheme.primaryColor : Colors.grey.shade300,
              foregroundColor: isLocked.value ? Colors.white : AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              isLocked.value ? "Unlock" : "Lock",
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ================= TABLE =================
  Widget _table() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // TABLE HEADER
          Scrollbar(
            thumbVisibility: true,
            controller: _horizontalScrollController,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _horizontalScrollController,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.headerGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: headers.map(_headerCell).toList(),
                ),
              ),
            ),
          ),

          // TABLE CONTENT
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalScrollController,
                  child: Column(
                    children: List.generate(
                      data.length,
                      (i) => _dataRow(data[i], i),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(List<String> row, int rowIndex) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: rowIndex.isEven ? Colors.white : AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: List.generate(row.length, (i) {
          return _cell(row[i], index: i);
        }),
      ),
    );
  }

  // ================= CELLS =================
  Widget _headerCell(String t) {
    return Container(
      width: 100,
      alignment: Alignment.center,
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: AppTheme.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _cell(String value, {required int index}) {
    return Container(
      width: index == 0 ? 60 : 100,
      alignment: Alignment.center,
      child: Obx(
        () => isLocked.value
            ? Text(
                value,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textPrimary,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: TextEditingController(text: value),
                  textAlign: TextAlign.center,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
      ),
    );
  }

  // ================= TOOL BUTTONS =================
  Widget _toolButtons() {
    return Container(
      width: 48,
      margin: const EdgeInsets.only(top: 12, bottom: 12, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _ToolIcon(Icons.arrow_upward, "Move Up"),
          const SizedBox(height: 8),
          _ToolIcon(Icons.arrow_downward, "Move Down"),
          const SizedBox(height: 8),
          _ToolIcon(Icons.add, "Add Row"),
          const SizedBox(height: 8),
          _ToolIcon(Icons.remove, "Remove Row"),
          const SizedBox(height: 8),
          _ToolIcon(Icons.copy, "Duplicate"),
          const Spacer(),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 8),
          _ToolIcon(Icons.save, "Save"),
        ],
      ),
    );
  }

  // ================= ANNOTATION PANEL =================
  Widget _annotationPanel() {
    return Container(
      width: 280,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.secondaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.note_add, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "Annotations",
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Survey Point Notes",
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Expanded(
                    child: isLocked.value
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Center(
                              child: Text(
                                "Unlock to add annotations",
                                style: AppTheme.caption.copyWith(
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextField(
                              maxLines: null,
                              expands: true,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(12),
                                hintText: 'Add notes about survey points...\n• Well trajectory\n• Formation changes\n• Survey quality\n• Additional observations',
                                hintStyle: AppTheme.caption.copyWith(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                  )),
                  const SizedBox(height: 16),
                  Text(
                    "Selected Point: Row 1",
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
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

  Widget _sidePanel() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tools & Annotations",
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToolIcon(Icons.arrow_upward, "Up"),
              _ToolIcon(Icons.arrow_downward, "Down"),
              _ToolIcon(Icons.add, "Add"),
              _ToolIcon(Icons.remove, "Remove"),
              _ToolIcon(Icons.copy, "Copy"),
              _ToolIcon(Icons.save, "Save"),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= TOOL ICON =================
class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;

  const _ToolIcon(this.icon, this.tooltip);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, size: 18, color: AppTheme.textSecondary),
      ),
    );
  }
}
