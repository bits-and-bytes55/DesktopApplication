import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pit/pit_concentration.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pit/pit_snapshot.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// Row heights and filler
const double kRowHeight = 22.0;
const double kHeaderHeight = 26.0;
const int kEmptyFillRows = 8; // filler rows to fill height if needed

class PitPage extends StatefulWidget {
  const PitPage({super.key});

  @override
  State<PitPage> createState() => _PitPageState();
}

class _PitPageState extends State<PitPage> {
  final PitController controller = Get.put(PitController());
  final dashboard = Get.find<DashboardController>();
  final Map<String, String> _lastValidMeasuredVolByPit = {};

  @override
  void initState() {
    super.initState();
    controller.fetchAllPits();
    controller.fetchVolumeNameData();
  }

  @override
  void dispose() {
    // Only clear if navigating completely away, keeping the values in the controller
    // allows for switching tabs without losing data if they haven't saved.
    super.dispose();
  }

  String _volumeValidationKey(PitModel pit) => pit.id?.trim().isNotEmpty == true
      ? pit.id!
      : identityHashCode(pit).toString();

  double _parseVolumeText(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0.0;
  }

  bool _validateMeasuredVolume(
    TextEditingController ctrl,
    PitModel pit,
    String value,
  ) {
    final capacity = pit.capacity.value;
    if (capacity <= 0 || value.trim().isEmpty) {
      _lastValidMeasuredVolByPit[_volumeValidationKey(pit)] = value;
      return true;
    }

    final volume = _parseVolumeText(value);
    if (volume <= capacity + 0.005) {
      _lastValidMeasuredVolByPit[_volumeValidationKey(pit)] = value;
      return true;
    }

    final key = _volumeValidationKey(pit);
    final previous = _lastValidMeasuredVolByPit[key] ?? '';
    ctrl.value = TextEditingValue(
      text: previous,
      selection: TextSelection.collapsed(offset: previous.length),
    );
    Get.snackbar(
      'Invalid measured volume',
      'Measured Vol. cannot exceed pit capacity (${capacity.toStringAsFixed(2)} bbl).',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Obx(() {
        AppUnits.signature;
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return _buildMobileLayout(context);
            } else {
              return _buildDesktopLayout(context);
            }
          },
        );
      }),
    );
  }

  // ================= MOBILE LAYOUT =================
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _activePitsSection(),
            const SizedBox(height: 12),
            _storageSection(),
            const SizedBox(height: 12),
            _volumeSummarySection(),
            const SizedBox(height: 12),
            _haulOffSection(context),
            const SizedBox(height: 12),
            _pitSnapshotButton(),
          ],
        ),
      ),
    );
  }

  // ================= DESKTOP LAYOUT =================
  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _activePitsSection()),
                const SizedBox(height: 12),
                Expanded(child: _volumeSummarySection()),
                const SizedBox(height: 12),
                _pitSnapshotButton(),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // RIGHT COLUMN
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(child: _storageSection()),
                const SizedBox(height: 12),
                Expanded(child: _haulOffSection(context)),
                const SizedBox(height: 12),
                // Aligns with Pit Snapshot button
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTIVE PITS SECTION =================
  Widget _activePitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Blue Header
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.water_damage,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Active Pits",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Tooltip(
                  message: "View Concentration",
                  child: InkWell(
                    onTap: () => Get.to(() => PitConcentrationPage()),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.bar_chart,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: "Save & Calculate",
                  child: InkWell(
                    onTap: () async {
                      await controller.saveAllActivePits();
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.save,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Table Column Header (Sticky)
        _buildActivePitsTableHeader(),
        // Table Body (Scrollable)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.tableGridBlue, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Obx(() {
              final dataRows = controller.activePitRows;
              final volumeNameData = Map<String, dynamic>.from(
                controller.volumeNameData,
              );
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: _buildActivePitsTableBody(
                      constraints.maxHeight,
                      dataRows,
                      volumeNameData,
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildActivePitsTableHeader() {
    return Table(
      border: TableBorder(
        verticalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        left: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        right: BorderSide(color: AppTheme.tableGridBlue, width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppTheme.tableHeaderBlue),
          children: [
            _headerCell("Pit"),
            _headerCell("Measured Vol\n(bbl)"),
            _headerCell("MW\n(ppg)"),
            _headerCell("Mud"),
          ],
        ),
      ],
    );
  }

  Widget _buildActivePitsTableBody(
    double availableHeight,
    List<PitModel> dataRows,
    Map<String, dynamic> volumeNameData,
  ) {
    final fillerRows = _fillerRowCount(
      availableHeight: availableHeight,
      dataRows: dataRows.length,
    );
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        verticalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2),
      },
      children: [
        ...List.generate(dataRows.length, (index) {
          final pit = dataRows[index];
          final pitKey = controller.controllerKeyForPit(pit, 'active', index);
          final ctrls = controller.getPitCtrl(
            pitKey,
            pitName: pit.pitName,
            vol: controller.activeMeasuredVolumeForPit(
              pit,
              volumeNameData: volumeNameData,
            ),
            density: controller.activeMwForPit(
              pit,
              volumeNameData: volumeNameData,
            ),
            fluid: controller.activeMudForPit(
              pit,
              volumeNameData: volumeNameData,
            ),
            syncExisting: true,
          );
          return TableRow(
            children: [
              _pitNameCell(ctrls, pit),
              _editableCellWithSave(ctrls, pit, 'volume'),
              _editableCellWithSave(ctrls, pit, 'density'),
              _editableCellWithSave(ctrls, pit, 'fluidType'),
            ],
          );
        }),
        ...List.generate(
          fillerRows,
          (_) => TableRow(
            children: [_emptyCell(), _emptyCell(), _emptyCell(), _emptyCell()],
          ),
        ),
      ],
    );
  }

  // ================= STORAGE SECTION =================
  Widget _storageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.warehouse, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                const Text(
                  "Storage",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildStorageTableHeader(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.tableGridBlue, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Obx(() {
              final dataRows = controller.storagePitRows;
              final volumeNameData = Map<String, dynamic>.from(
                controller.volumeNameData,
              );
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: _buildStorageTableBody(
                      constraints.maxHeight,
                      dataRows,
                      volumeNameData,
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageTableHeader() {
    return Table(
      border: TableBorder(
        verticalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        left: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        right: BorderSide(color: AppTheme.tableGridBlue, width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppTheme.tableHeaderBlue),
          children: [
            _headerCell("Pit"),
            _headerCell("Calculated Vol\n(bbl)"),
            _headerCell("Measured Vol\n(bbl)"),
            _headerCell("MW\n(ppg)"),
            _headerCell("Fluid Type"),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageTableBody(
    double availableHeight,
    List<PitModel> dataRows,
    Map<String, dynamic> volumeNameData,
  ) {
    final fillerRows = _fillerRowCount(
      availableHeight: availableHeight,
      dataRows: dataRows.length,
    );
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        verticalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(2),
      },
      children: [
        ...List.generate(dataRows.length, (index) {
          final pit = dataRows[index];
          final pitKey = controller.controllerKeyForPit(pit, 'storage', index);

          final ctrls = controller.getPitCtrl(
            pitKey,
            pitName: pit.pitName,
            vol: pit.volume?.value ?? 0,
            density: pit.density?.value ?? 0,
            fluid: pit.fluidType?.value ?? '',
          );

          return TableRow(
            children: [
              _pitNameCell(ctrls, pit),
              _readOnlyCell(_storageCalculatedVol(pit, volumeNameData)),
              _editableCellWithSave(ctrls, pit, 'volume'),
              _editableCellWithSave(ctrls, pit, 'density'),
              _editableCellWithSave(ctrls, pit, 'fluidType'),
            ],
          );
        }),
        ...List.generate(
          fillerRows,
          (_) => TableRow(
            children: [
              _emptyCell(),
              _emptyCell(),
              _emptyCell(),
              _emptyCell(),
              _emptyCell(),
            ],
          ),
        ),
      ],
    );
  }

  // ================= VOLUME SUMMARY SECTION =================
  Widget _volumeSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.summarize, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "Volume Name",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Volume Name header row
        _buildVolumeNameHeader(),
        // Table Body
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.tableGridBlue, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Obx(() {
              if (controller.isLoadingVolume.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final vn = controller.volumeNameData['volumeName'];
              return SingleChildScrollView(
                child: _buildVolumeNameTableBody(vn),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeNameHeader() {
    return Table(
      border: TableBorder(
        verticalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        left: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        right: BorderSide(color: AppTheme.tableGridBlue, width: 1),
      ),
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1.5)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppTheme.tableHeaderBlue),
          children: [_headerCell("Volume Name"), _headerCell("Volume\n(bbl)")],
        ),
      ],
    );
  }

  Widget _buildVolumeNameTableBody(dynamic vn) {
    double getValue(String key) {
      if (vn == null) return 0.0;
      final v = vn[key];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    String formatValue(double v) => v.abs() <= 0.005 ? '' : v.toStringAsFixed(2);
    String formatSignedValue(double v) {
      if (v.abs() <= 0.005) return '';
      return v > 0 ? '+${v.toStringAsFixed(2)}' : v.toStringAsFixed(2);
    }

    final rows = [
      ['Hole Vol. Difference', formatValue(getValue('heldVolDifference'))],
      ['Hole', formatValue(getValue('hole'))],
      ['Active Pits', formatValue(getValue('activePits'))],
      ['Active System', formatValue(getValue('activeSystem'))],
      ['End Vol.', formatValue(getValue('endVol'))],
      [
        'End Vol. - Active System',
        formatSignedValue(getValue('endVolMinusActiveSystem')),
      ],
      ['Total Storage', formatValue(getValue('totalStorage'))],
      ['Total on Location', formatValue(getValue('totalOnLocation'))],
      [
        'Previous Total on Location',
        formatValue(getValue('previousTotalOnLocation')),
      ],
    ];

    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        verticalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1.5)},
      children: rows.map((row) {
        final label = row[0];
        final value = row[1];
        final numVal = double.tryParse(value.replaceFirst('+', '')) ?? 0.0;
        final isNegativeWarning = label == 'End Vol. - Active System';
        final isRed = isNegativeWarning && numVal.abs() > 0.005;
        final rowBg = isRed ? Colors.red.shade50 : Colors.transparent;
        final rowTextColor = isRed ? Colors.red : Colors.black87;

        return TableRow(
          children: [
            Container(
              color: rowBg,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: rowTextColor,
                ),
              ),
            ),
            Container(
              color: rowBg,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: rowTextColor,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ================= HAUL OFF SECTION =================
  Widget _haulOffSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Blue Header
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "Haul Off",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Table Column Header (Sticky)
        _buildHaulOffTableHeader(),
        // Table Body (Scrollable)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.tableGridBlue, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: SingleChildScrollView(child: _buildHaulOffTableBody()),
          ),
        ),
      ],
    );
  }

  Widget _buildHaulOffTableHeader() {
    return Table(
      border: TableBorder(
        verticalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        left: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        right: BorderSide(color: AppTheme.tableGridBlue, width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppTheme.tableHeaderBlue),
          children: [
            _headerCell("Item"),
            _headerCell("Value"),
            _headerCell("Unit"),
          ],
        ),
      ],
    );
  }

  Widget _buildHaulOffTableBody() {
    final rows = [
      ["No. of Loads", "0", ""],
      ["Vol.", "0.00", "(bbl)"],
      ["Weight", "0", "(lbm)"],
      ["Oil", "0", "(%)"],
      ["Water", "0", "(%)"],
      ["Solids", "0", "(%)"],
      ["OOC Wt.", "0", "(%)"],
    ];

    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        verticalInside: BorderSide(color: AppTheme.tableGridBlue, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
      },
      children: rows
          .map((row) => _buildHaulOffRow(row[0], row[1], row[2]))
          .toList(),
    );
  }

  TableRow _buildHaulOffRow(String label, String value, String unit) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Obx(() {
            if (dashboard.isLocked.value) {
              return Text(
                value,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.right,
              );
            }
            return TextFormField(
              initialValue: value,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            );
          }),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            AppUnits.unitText(unit),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  // ================= PIT SNAPSHOT BUTTON =================
  Widget _pitSnapshotButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Get.to(() => PitSnapshotPage()),
        icon: const Icon(Icons.camera_alt, size: 16),
        label: const Text(
          "Pit Snapshot",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  // ================= SHARED CELL BUILDERS =================

  Widget _headerCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        AppUnits.label(text),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _readOnlyCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.black87),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _pitNameCell(Map<String, TextEditingController> ctrls, PitModel pit) {
    final ctrl = ctrls['pitName']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Obx(() {
        if (dashboard.isLocked.value || !controller.isDraftPit(pit)) {
          return Text(
            ctrl.text,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
            textAlign: TextAlign.center,
          );
        }
        return TextFormField(
          controller: ctrl,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: 'Pit',
          ),
          onChanged: (val) => controller.updateDraftPit(pit: pit, pitName: val),
        );
      }),
    );
  }

  Widget _emptyCell() {
    return const SizedBox(height: kRowHeight);
  }

  // Editable cell — on save button hit from secondary tabbar,
  // also allows inline edit and triggers save + volume name refresh
  int _fillerRowCount({
    required double availableHeight,
    required int dataRows,
  }) {
    if (!availableHeight.isFinite || availableHeight <= 0) {
      return kEmptyFillRows;
    }
    final remainingHeight = availableHeight - (dataRows * kRowHeight);
    final neededRows = (remainingHeight / kRowHeight).ceil();
    return neededRows < kEmptyFillRows ? kEmptyFillRows : neededRows;
  }

  Widget _editableCellWithSave(
    Map<String, TextEditingController> ctrls,
    PitModel pit,
    String field,
  ) {
    final ctrl = ctrls[field]!;
    if (field == 'volume') {
      _lastValidMeasuredVolByPit.putIfAbsent(
        _volumeValidationKey(pit),
        () => ctrl.text,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Obx(() {
        if (dashboard.isLocked.value) {
          return Text(
            ctrl.text,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
            textAlign: TextAlign.center,
          );
        }
        return TextFormField(
          controller: ctrl,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
          keyboardType: field == 'fluidType'
              ? TextInputType.text
              : const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (val) {
            if (field == 'volume' && !_validateMeasuredVolume(ctrl, pit, val)) {
              return;
            }
            if (pit.id != null && pit.id!.isNotEmpty) {
              controller.onPitFieldChanged(
                pitId: pit.id!,
                volume: double.tryParse(ctrls['volume']!.text) ?? 0,
                density: double.tryParse(ctrls['density']!.text) ?? 0,
                fluidType: ctrls['fluidType']!.text,
              );
            } else {
              controller.updateDraftPit(
                pit: pit,
                volume: double.tryParse(ctrls['volume']!.text) ?? 0,
                density: double.tryParse(ctrls['density']!.text) ?? 0,
                fluidType: ctrls['fluidType']!.text,
              );
            }
          },
          onEditingComplete: () {
            // Manual Save is now handled by the header save icon to prevents duplicate records creation
          },
        );
      }),
    );
  }

  String _storageCalculatedVol(
    PitModel pit,
    Map<String, dynamic> volumeNameData,
  ) {
    return controller
        .storageCalculatedVolumeForPit(pit, volumeNameData: volumeNameData)
        .toStringAsFixed(2);
  }
}
