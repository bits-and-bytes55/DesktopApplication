import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import '../../controller/dashboard_controller.dart';

class SwitchPitView extends StatefulWidget {
  const SwitchPitView({super.key, required this.instanceKey});

  final String instanceKey;

  @override
  State<SwitchPitView> createState() => _SwitchPitViewState();
}

class _SwitchPitViewState extends State<SwitchPitView> {
  final PitController pitController = Get.put(PitController());
  final DashboardController dashboardController =
      Get.find<DashboardController>();

  final ScrollController activePitScrollController = ScrollController();
  final ScrollController storagePitScrollController = ScrollController();
  final RxBool notTreatedMud = false.obs;
  final Map<String, TextEditingController> _activeVolumeControllers = {};
  final Set<String> _checkedActionKeys = {};
  int selectedActiveIndex = 0;
  int selectedStorageIndex = 0;

  static const Color _gridBorder = AppTheme.tableGridBlue;
  static const Color _editableFill = Color(0xFFFFF8C6);
  static const double _rowHeight = 28;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await pitController.fetchSelectedPits();
    await pitController.fetchUnselectedPits();
  }

  @override
  void dispose() {
    for (final controller in _activeVolumeControllers.values) {
      controller.dispose();
    }
    activePitScrollController.dispose();
    storagePitScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActivePitsSection(),
          const SizedBox(height: 10),
          _buildStoragePitsSection(),
        ],
      ),
    );
  }

  // ===================================================
  // ACTIVE PITS SECTION
  // ===================================================
  Widget _buildActivePitsSection() {
    return _sectionFrame(
      title: 'Active Pit - Uncheck to Move to Storage',
      child: _buildActivePitsTable(),
    );
  }

  Widget _sectionFrame({
    required String title,
    required Widget child,
    Widget? titleBottom,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppTheme.primaryColor,
            child: Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (titleBottom != null) titleBottom,
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _gridBorder),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  // ===================================================
  // STORAGE PITS SECTION
  // ===================================================
  Widget _buildStoragePitsSection() {
    return _sectionFrame(
      title: 'Storage - to Move to Active Pit',
      titleBottom: _buildNotTreatedMudCheckbox(),
      child: _buildStoragePitsTable(),
    );
  }

  Widget _buildNotTreatedMudCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 4),
      child: Obx(
        () => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: notTreatedMud.value,
                onChanged: dashboardController.isLocked.value
                    ? null
                    : (value) => notTreatedMud.value = value ?? false,
                activeColor: AppTheme.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Not Treated Mud',
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // ACTIVE PITS TABLE (4 COLUMNS)
  // ===================================================
  Widget _buildActivePitsTable() {
    return Column(
      children: [
        Container(
          color: AppTheme.tableHeaderBlue,
          child: Table(
            border: _tableBorder,
            columnWidths: _activeColumnWidths,
            children: [
              TableRow(
                children: [
                  _buildHeaderCell(''),
                  _buildHeaderCell("#"),
                  _buildHeaderCell("Pit"),
                  _buildHeaderCell("Checked"),
                  _buildHeaderCell("Measured Vol.\n(bbl)"),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Body
        Obx(() {
          if (pitController.isLoading.value) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            );
          }

          if (pitController.selectedPits.isEmpty) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                "No active pits",
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            );
          }

          return Container(
            constraints: const BoxConstraints(maxHeight: 168),
            child: Scrollbar(
              controller: activePitScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: activePitScrollController,
                shrinkWrap: true,
                itemCount: pitController.selectedPits.length,
                itemBuilder: (context, index) {
                  final pit = pitController.selectedPits[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => selectedActiveIndex = index),
                    onSecondaryTapDown: (details) {
                      setState(() => selectedActiveIndex = index);
                      _showPitRowMenu(
                        position: details.globalPosition,
                        pit: pit,
                        isActive: true,
                      );
                    },
                    child: Table(
                      border: _tableBorder,
                      columnWidths: _activeColumnWidths,
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? Colors.white
                                : Colors.grey.shade50,
                          ),
                          children: [
                            _buildSelectorCell(index == selectedActiveIndex),
                            _buildDataCell("${index + 1}"),
                            _buildDataCell(
                              pit.pitName,
                              isLeft: true,
                              fill: _editableFill,
                            ),
                            _buildCheckboxCell(pit, true),
                            _buildEditableVolumeCell(pit),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===================================================
  // STORAGE PITS TABLE (3 COLUMNS)
  // ===================================================
  Widget _buildStoragePitsTable() {
    return Column(
      children: [
        Container(
          color: AppTheme.tableHeaderBlue,
          child: Table(
            border: _tableBorder,
            columnWidths: _storageColumnWidths,
            children: [
              TableRow(
                children: [
                  _buildHeaderCell(''),
                  _buildHeaderCell("#"),
                  _buildHeaderCell("Pit"),
                  _buildHeaderCell("Checked"),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Body
        Obx(() {
          if (pitController.isLoading.value) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            );
          }

          if (pitController.unselectedPits.isEmpty) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                "No storage pits",
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            );
          }

          return Container(
            constraints: const BoxConstraints(maxHeight: 196),
            child: Scrollbar(
              controller: storagePitScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: storagePitScrollController,
                shrinkWrap: true,
                itemCount: pitController.unselectedPits.length,
                itemBuilder: (context, index) {
                  final pit = pitController.unselectedPits[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => selectedStorageIndex = index),
                    onSecondaryTapDown: (details) {
                      setState(() => selectedStorageIndex = index);
                      _showPitRowMenu(
                        position: details.globalPosition,
                        pit: pit,
                        isActive: false,
                      );
                    },
                    child: Table(
                      border: _tableBorder,
                      columnWidths: _storageColumnWidths,
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? Colors.white
                                : Colors.grey.shade50,
                          ),
                          children: [
                            _buildSelectorCell(index == selectedStorageIndex),
                            _buildDataCell("${index + 1}"),
                            _buildDataCell(
                              pit.pitName,
                              isLeft: true,
                              fill: _editableFill,
                            ),
                            _buildCheckboxCell(pit, false),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===================================================
  // HELPER WIDGETS
  // ===================================================

  TableBorder get _tableBorder => const TableBorder(
    horizontalInside: BorderSide(color: _gridBorder),
    verticalInside: BorderSide(color: _gridBorder),
    bottom: BorderSide(color: _gridBorder),
  );

  Map<int, TableColumnWidth> get _activeColumnWidths => const {
    0: FixedColumnWidth(24),
    1: FixedColumnWidth(34),
    2: FlexColumnWidth(1.85),
    3: FixedColumnWidth(62),
    4: FixedColumnWidth(108),
  };

  Map<int, TableColumnWidth> get _storageColumnWidths => const {
    0: FixedColumnWidth(24),
    1: FixedColumnWidth(34),
    2: FlexColumnWidth(1.85),
    3: FixedColumnWidth(62),
  };

  Widget _buildHeaderCell(String text) {
    return Container(
      height: 34,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Obx(
        () => Text(
          AppUnits.label(text),
          style: AppTheme.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSelectorCell(bool selected) {
    return Container(
      height: _rowHeight,
      alignment: Alignment.center,
      child: selected
          ? const Icon(Icons.arrow_right, size: 15, color: Color(0xFF5F6C7A))
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDataCell(
    String text, {
    bool isLeft = false,
    bool isRight = false,
    Color? fill,
  }) {
    return Container(
      height: _rowHeight,
      alignment: isLeft
          ? Alignment.centerLeft
          : isRight
          ? Alignment.centerRight
          : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: fill,
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        textAlign: isLeft
            ? TextAlign.left
            : isRight
            ? TextAlign.right
            : TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEditableVolumeCell(PitModel pit) {
    final controller = _controllerForPit(pit);
    return Container(
      height: _rowHeight,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: dashboardController.isLocked.value
          ? operationLockedEditableColor
          : Colors.white,
      child: TextField(
        controller: controller,
        enabled: !dashboardController.isLocked.value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        ),
      ),
    );
  }

  Widget _buildCheckboxCell(PitModel pit, bool isActive) {
    return Container(
      height: _rowHeight,
      alignment: Alignment.center,
      child: Obx(() {
        final checkboxValue = _checkedActionKeys.contains(_pitKey(pit));

        return Transform.scale(
          scale: 0.82,
          child: Checkbox(
            value: checkboxValue,
            onChanged: dashboardController.isLocked.value
                ? null
                : (value) => _handleSwitchAction(pit, isActive),
            activeColor: AppTheme.primaryColor,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        );
      }),
    );
  }

  TextEditingController _controllerForPit(PitModel pit) {
    final key = _pitKey(pit);
    final existing = _activeVolumeControllers[key];
    if (existing != null) return existing;

    final controller = TextEditingController(
      text: _formatVolume(_availableVolume(pit)),
    );
    _activeVolumeControllers[key] = controller;
    return controller;
  }

  String _pitKey(PitModel pit) {
    final id = pit.id?.trim() ?? '';
    return id.isNotEmpty ? id : pit.pitName.trim();
  }

  double _availableVolume(PitModel pit) {
    return pit.volume?.value ?? 0.0;
  }

  double _parseVolume(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0.0;
  }

  String _formatVolume(double value) {
    if (value <= 0 || value.isNaN) return '';
    return formatOperationNumber(value);
  }

  void _showSwitchError(String message) {
    Get.snackbar(
      'Switch Pit',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _handleSwitchAction(PitModel pit, bool isActive) async {
    if (dashboardController.isLocked.value) return;

    final key = _pitKey(pit);
    _checkedActionKeys.add(key);
    setState(() {});

    final available = _availableVolume(pit);
    double transferVolume = available;

    if (isActive) {
      transferVolume = _parseVolume(_controllerForPit(pit).text);
      if (transferVolume <= 0) {
        _checkedActionKeys.remove(key);
        setState(() {});
        _showSwitchError('Enter transfer volume greater than 0');
        return;
      }
      if (available <= 0) {
        _checkedActionKeys.remove(key);
        setState(() {});
        _showSwitchError('${pit.pitName} has no measured volume');
        return;
      }
      if (transferVolume > available + 0.005) {
        _checkedActionKeys.remove(key);
        setState(() {});
        _showSwitchError(
          'Transfer volume cannot exceed ${_formatVolume(available)} bbl',
        );
        return;
      }
    }

    final result = await pitController.switchPitStatusWithVolume(
      pit: pit,
      initialActive: !isActive,
      volume: transferVolume,
    );

    _checkedActionKeys.remove(key);
    _activeVolumeControllers.remove(key)?.dispose();
    setState(() {});

    if (result['success'] == true) {
      await _loadData();
    }
  }

  Future<void> _showPitRowMenu({
    required Offset position,
    required PitModel pit,
    required bool isActive,
  }) async {
    final canEdit = !dashboardController.isLocked.value;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          child: Text(
            'Copy',
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        PopupMenuItem<String>(
          value: canEdit ? 'move' : null,
          enabled: canEdit,
          child: Text(
            isActive ? 'Move to Storage' : 'Move to Active Pit',
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        PopupMenuItem<String>(
          value: canEdit ? 'delete' : null,
          enabled: canEdit,
          child: Text(
            'Delete',
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        PopupMenuItem<String>(
          value: 'refresh',
          child: Text(
            'Refresh',
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: pit.pitName.toString()));
        break;
      case 'move':
        await _handleSwitchAction(pit, isActive);
        break;
      case 'delete':
        await pitController.deletePit(pit);
        await _loadData();
        break;
      case 'refresh':
        await _loadData();
        break;
    }
  }
}
