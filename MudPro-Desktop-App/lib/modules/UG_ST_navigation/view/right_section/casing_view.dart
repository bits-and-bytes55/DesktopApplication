import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/controller/UG_ST_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class CasingView extends StatelessWidget {
  CasingView({super.key});
  final c = Get.find<UgStController>();

  static const rowH = 32.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= MAIN TABLE =================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // TABLE HEADER
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.headerGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.bubble_chart, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "Casing Configuration",
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${c.casings.length} casings",
                            style: AppTheme.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _tableBody(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ================= SIMPLE BUTTON =================
          Container(
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // BUTTON HEADER
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12), // Reduced padding
                  child: Row(
                    children: [
                      Icon(Icons.add_circle, size: 16, color: Colors.white), // Smaller icon
                      const SizedBox(width: 6), // Reduced spacing
                      Expanded( // Wrap text in Expanded
                        child: Text(
                          "Add Casing",
                          style: AppTheme.bodySmall.copyWith( // Use smaller font
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis, // Add ellipsis if needed
                        ),
                      ),
                    ],
                  ),
                ),

                // BUTTON CONTENT
                Padding(
                  padding: const EdgeInsets.all(12), // Reduced padding
                  child: Column(
                    children: [
                      Obx(() => ElevatedButton(
                        onPressed: c.isLocked.value ? null : () {
                          _showAddCasingDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), // Reduced padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 2,
                          minimumSize: const Size(double.infinity, 44), // Slightly smaller
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 16), // Smaller icon
                            const SizedBox(width: 6), // Reduced spacing
                            Expanded( // Wrap text in Expanded
                              child: Text(
                                "Add Casing", // Shorter text
                                textAlign: TextAlign.center,
                                style: AppTheme.caption.copyWith( // Use caption font size
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),

                      const SizedBox(height: 12),

                      // INFO
                      Container(
                        padding: const EdgeInsets.all(10), // Reduced padding
                        decoration: BoxDecoration(
                          color: AppTheme.infoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 12, color: AppTheme.infoColor), // Smaller icon
                                const SizedBox(width: 6),
                                Text(
                                  "Note",
                                  style: AppTheme.caption.copyWith( // Use caption font
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.infoColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4), // Reduced spacing
                            Text(
                              "Add new casing configurations",
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 9, // Smaller font
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TABLE BODY =================
  Widget _tableBody() {
    final ScrollController horizontalController = ScrollController();
    final ScrollController verticalController = ScrollController();

    return Scrollbar(
      thumbVisibility: true,
      controller: verticalController,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        controller: verticalController,
        child: Scrollbar(
          thumbVisibility: true,
          controller: horizontalController,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: horizontalController,
            child: SizedBox(
              width: 1100,
              child: Obx(() {
                final casingsLength = c.casings.length;
                return Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(50),
                    1: FixedColumnWidth(200),
                    2: FixedColumnWidth(120),
                    3: FixedColumnWidth(90),
                    4: FixedColumnWidth(100),
                    5: FixedColumnWidth(90),
                    6: FixedColumnWidth(90),
                    7: FixedColumnWidth(90),
                    8: FixedColumnWidth(90),
                    9: FixedColumnWidth(90),
                  },
                  children: [
                    _headerRow(),
                    ...List.generate(20, (index) {
                      final row = index < casingsLength ? c.casings[index] : null;
                      return _dataRow(index, row);
                    }),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ================= HEADER ROW =================
  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      children: [
        _headerCell('#'),
        _headerCell('Description'),
        _headerCell('Type'),
        _headerCell('OD\n(in)'),
        _headerCell('Wt.\n(lb/ft)'),
        _headerCell('ID\n(in)'),
        _headerCell('Top\n(m)'),
        _headerCell('Shoe\n(m)'),
        _headerCell('Bit\n(in)'),
        _headerCell('TOC\n(m)'),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  // ================= DATA ROW =================
  TableRow _dataRow(int index, dynamic row) {
    return TableRow(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : AppTheme.cardColor,
      ),
      children: [
        _indexCell(index + 1),
        _editableCell(row?.description, width: 200),
        _editableCell(row?.type, width: 120),
        _editableCell(row?.od, width: 90),
        _editableCell(row?.wt, width: 100),
        _editableCell(row?.id, width: 90),
        _editableCell(row?.top, width: 90),
        _editableCell(row?.shoe, width: 90),
        _editableCell(row?.bit, width: 90),
        _editableCell(row?.toc, width: 90),
      ],
    );
  }

  Widget _indexCell(int index) {
    return Container(
      height: rowH,
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: AppTheme.caption.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _editableCell(RxString? value, {double? width}) {
    return SizedBox(
      width: width,
      height: rowH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Obx(() => c.isLocked.value || value == null
            ? Center(
                child: Text(
                  value?.value ?? '',
                  style: AppTheme.caption.copyWith(
                    color: value?.value?.isEmpty == true 
                        ? Colors.grey.shade400 
                        : AppTheme.textPrimary,
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: TextEditingController(text: value.value),
                  onChanged: (text) => value.value = text,
                  textAlign: TextAlign.center,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    border: InputBorder.none,
                  ),
                ),
              )),
      ),
    );
  }

  // ================= ADD CASING DIALOG =================
  void _showAddCasingDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(
          "Add New Casing",
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogField("Description", "Conductor, Surface, etc."),
              const SizedBox(height: 12),
              _dialogField("Type", "Casing, Liner, etc."),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField("OD (in)", "13.375")),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField("Weight (lb/ft)", "68")),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField("ID (in)", "12.415")),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField("Bit Size (in)", "17.5")),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField("Top (m)", "0")),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField("Shoe (m)", "500")),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField("TOC (m)", "0")),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel",
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Add casing logic here
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              "Add Casing",
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.caption.copyWith(
              color: Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }
}