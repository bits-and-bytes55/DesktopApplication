import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pit/pit_concentration.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/pit/pit_snapshot.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// Static well ID
const String kPitWellId = '67f1a2b3c4d5e6f7890a1111';

// Row heights and filler
const double kRowHeight = 22.0;
const double kHeaderHeight = 26.0;
const int kEmptyFillRows = 8; // filler rows to fill height if needed

String _pitUnitPlain(String paramNumber, String fallback) {
  return AppUnits.stripBrackets(
    AppUnits.displayUnit(
      paramNumber,
      fallback: fallback.startsWith('(') ? fallback : '($fallback)',
    ),
  );
}

class PitPage extends StatefulWidget {
  PitPage({super.key});

  @override
  State<PitPage> createState() => _PitPageState();
}

class _PitPageState extends State<PitPage> {
  final PitController controller = Get.put(PitController());
  final dashboard = Get.find<DashboardController>();

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

  // Save active pit volume/density/fluidType then refresh volume name
  Future<void> _saveActivePitData(String pitId) async {
    final ctrls = controller.activePitControllers[pitId];
    if (ctrls == null) return;
    try {
      // Use the controller's update method instead of direct repository call
      // to ensure wellId and pitNames are resolved correctly.
      await controller.updatePitVolumeData(
        pitId: pitId,
        volume: double.tryParse(ctrls['volume']!.text) ?? 0,
        density: double.tryParse(ctrls['density']!.text) ?? 0,
        fluidType: ctrls['fluidType']!.text,
      );
      // Refresh volume name table after save
      await controller.fetchVolumeNameData();
    } catch (e) {
      debugPrint('Error saving pit data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final optionsController = Get.find<OptionsController>();
    return Obx(
      () {
        final unitKey = optionsController.activeUnitSystemLabel;
        return KeyedSubtree(
          key: ValueKey(unitKey),
          child: Container(
            color: Colors.white,
            child: Obx(() {
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
          ),
        );
      },
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
                Row(children: [
                  const Icon(Icons.water_damage, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  const Text("Active Pits",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ]),
                Tooltip(
                  message: "View Concentration",
                  child: InkWell(
                    onTap: () => Get.to(() => PitConcentrationPage()),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.bar_chart,
                            size: 14, color: Colors.white)),
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
                        child: const Icon(Icons.save,
                            size: 14, color: Colors.white)),
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
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Obx(() {
              final apiRows = controller.volumeNameData['activePitsTable'];
              return SingleChildScrollView(
                child: _buildActivePitsTableBody(apiRows),
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
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        left: BorderSide(color: Colors.grey.shade300, width: 1),
        right: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _headerCell("Pit"),
            _headerCell("Measured Vol\n(${_pitUnitPlain('6', 'bbl')})"),
            _headerCell("MW\n(${_pitUnitPlain('33', 'ppg')})"),
            _headerCell("Mud"),
          ],
        ),
      ],
    );
  }

  Widget _buildActivePitsTableBody(dynamic apiRows) {
    final dataRows = (apiRows != null && apiRows is List && apiRows.isNotEmpty)
        ? apiRows
        : controller.selectedPits.map((p) => {
            '_id': p.id ?? '',
            'pitName': p.pitName,
            'measuredVol': p.volume?.value ?? 0,
            'mw': p.density?.value ?? 0,
            'mud': p.fluidType?.value ?? '',
          }).toList();

    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2),
      },
      children: [
        ...dataRows.map<TableRow>((row) {
          final pitId = row['_id']?.toString() ?? '';
          final pitName = row['pitName']?.toString() ?? '';
          final measuredVol = (row['measuredVol'] ?? 0).toString();
          final mw = (row['mw'] ?? 0).toString();
          final mud = row['mud']?.toString() ?? '';
          final ctrls = controller.getPitCtrl(
            pitId,
            vol: double.tryParse(measuredVol) ?? 0,
            density: double.tryParse(mw) ?? 0,
            fluid: mud,
          );
          return TableRow(children: [
            _readOnlyCell(pitName),
            _editableCellWithSave(ctrls, pitId, 'volume'),
            _editableCellWithSave(ctrls, pitId, 'density'),
            _editableCellWithSave(ctrls, pitId, 'fluidType'),
          ]);
        }).toList(),
        ...List.generate(kEmptyFillRows, (_) => TableRow(children: [
          _emptyCell(), _emptyCell(), _emptyCell(), _emptyCell(),
        ])),
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
            child: Row(children: [
              const Icon(Icons.warehouse, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              const Text("Storage",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ]),
          ),
        ),
        _buildStorageTableHeader(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Obx(() {
              final apiRows = controller.volumeNameData['storageTable'];
              return SingleChildScrollView(
                child: _buildStorageTableBody(apiRows),
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
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        left: BorderSide(color: Colors.grey.shade300, width: 1),
        right: BorderSide(color: Colors.grey.shade300, width: 1),
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
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _headerCell("Pit"),
            _headerCell("Calculated Vol\n(${_pitUnitPlain('6', 'bbl')})"),
            _headerCell("Measured Vol\n(${_pitUnitPlain('6', 'bbl')})"),
            _headerCell("MW\n(${_pitUnitPlain('33', 'ppg')})"),
            _headerCell("Fluid Type"),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageTableBody(dynamic apiRows) {
    final dataRows = (apiRows != null && apiRows is List && apiRows.isNotEmpty)
        ? apiRows
        : controller.unselectedPits.map((p) => {
            'pitName': p.pitName,
            'calculatedVol': 0,
            'measuredVol': p.capacity.value,
            'mw': 0,
            'fluidType': '',
          }).toList();

    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
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
        ...dataRows.map<TableRow>((row) {
          final pitId = row['_id']?.toString() ?? '';
          final pitName = row['pitName']?.toString() ?? '';
          final calculatedVol = (row['calculatedVol'] ?? 0).toString();
          final measuredVol = (row['measuredVol'] ?? 0).toString();
          final mw = (row['mw'] ?? 0).toString();
          final fluid = row['fluidType']?.toString() ?? '';
          
          final ctrls = controller.getPitCtrl(
            pitId,
            vol: double.tryParse(measuredVol) ?? 0,
            density: double.tryParse(mw) ?? 0,
            fluid: fluid,
          );

          return TableRow(children: [
            _readOnlyCell(pitName),
            _readOnlyCell(double.tryParse(calculatedVol)?.toStringAsFixed(2) ?? '0.00'),
            _editableCellWithSave(ctrls, pitId, 'volume'),
            _editableCellWithSave(ctrls, pitId, 'density'),
            _editableCellWithSave(ctrls, pitId, 'fluidType'),
          ]);
        }).toList(),
        ...List.generate(kEmptyFillRows, (_) => TableRow(children: [
          _emptyCell(), _emptyCell(), _emptyCell(), _emptyCell(), _emptyCell(),
        ])),
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
            child: Row(children: [
              const Icon(Icons.summarize, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text("Volume Name",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ]),
          ),
        ),
        // Volume Name header row
        _buildVolumeNameHeader(),
        // Table Body
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Obx(() {
              if (controller.isLoadingVolume.value) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ));
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
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        left: BorderSide(color: Colors.grey.shade300, width: 1),
        right: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _headerCell("Volume Name"),
            _headerCell("Volume\n(${_pitUnitPlain('6', 'bbl')})"),
          ],
        ),
      ],
    );
  }

  Widget _buildVolumeNameTableBody(dynamic vn) {
    double _d(String key) {
      if (vn == null) return 0.0;
      final v = vn[key];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    String _fmt(double v) => v.toStringAsFixed(2);

    final rows = [
      ['Hole Vol. Difference', _fmt(_d('heldVolDifference'))],
      ['Hole', _fmt(_d('hole'))],
      ['Active Pits', _fmt(_d('activePits'))],
      ['Active System', _fmt(_d('activeSystem'))],
      ['End Vol.', _fmt(_d('endVol'))],
      ['End Vol. - Active System', _fmt(_d('endVolMinusActiveSystem'))],
      ['Total Storage', _fmt(_d('totalStorage'))],
      ['Total on Location', _fmt(_d('totalOnLocation'))],
      ['Previous Total on Location', '0.00'],
    ];

    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.5),
      },
      children: rows.map((row) {
        final label = row[0];
        final value = row[1];
        final numVal = double.tryParse(value) ?? 0.0;
        final isNegativeWarning = label == 'End Vol. - Active System';
        final isRed = isNegativeWarning && numVal < 0;

        return TableRow(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isRed ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ]);
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
            child: Row(children: [
              const Icon(Icons.local_shipping, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text("Haul Off",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ]),
          ),
        ),
        // Table Column Header (Sticky)
        _buildHaulOffTableHeader(),
        // Table Body (Scrollable)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: SingleChildScrollView(
              child: _buildHaulOffTableBody(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHaulOffTableHeader() {
    return Table(
      border: TableBorder(
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        left: BorderSide(color: Colors.grey.shade300, width: 1),
        right: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
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
      ["Vol.", "0.00", AppUnits.displayUnit('6', fallback: '(bbl)')],
      ["Weight", "0", AppUnits.displayUnit('29', fallback: '(lbm)')],
      ["Oil", "0", "(%)"],
      ["Water", "0", "(%)"],
      ["Solids", "0", "(%)"],
      ["OOC Wt.", "0", "(%)"],
    ];

    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
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
    return TableRow(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Obx(() {
          if (dashboard.isLocked.value) {
            return Text(value,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                textAlign: TextAlign.right);
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
                focusedBorder: InputBorder.none),
          );
        }),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(unit,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
      ),
    ]);
  }

  // ================= PIT SNAPSHOT BUTTON =================
  Widget _pitSnapshotButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Get.to(() => PitSnapshotPage()),
        icon: const Icon(Icons.camera_alt, size: 16),
        label: const Text("Pit Snapshot",
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          minimumSize: const Size(double.infinity, 40),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  // ================= SHARED CELL BUILDERS =================

  Widget _headerCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black87),
          textAlign: TextAlign.center),
    );
  }

  Widget _readOnlyCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Text(text,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
          textAlign: TextAlign.center),
    );
  }

  Widget _emptyCell() {
    return const SizedBox(height: kRowHeight);
  }

  // Editable cell — on save button hit from secondary tabbar,
  // also allows inline edit and triggers save + volume name refresh
  Widget _editableCellWithSave(
      Map<String, TextEditingController> ctrls, String pitId, String field) {
    final ctrl = ctrls[field]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Obx(() {
        if (dashboard.isLocked.value) {
          return Text(ctrl.text,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
              textAlign: TextAlign.center);
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
              contentPadding:
                  EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none),
          onChanged: (val) {
            if (pitId.isNotEmpty) {
              controller.onPitFieldChanged(
                pitId: pitId,
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
}
