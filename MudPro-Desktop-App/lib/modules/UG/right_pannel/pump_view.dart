import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pump_model.dart';
import '../controller/pump_controller.dart';
import '../controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class PumpView extends StatefulWidget {
  const PumpView({super.key});

  @override
  State<PumpView> createState() => _PumpViewState();
}

class _PumpViewState extends State<PumpView> {
  late final UgController ugController;
  late final PumpController pumpController;
  late final DashboardController dashCtrl;

  @override
  void initState() {
    super.initState();
    ugController = Get.find<UgController>();
    pumpController = Get.put(PumpController());
    dashCtrl = Get.find<DashboardController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPumpsIfNeeded();
    });
  }

  void _loadPumpsIfNeeded() {
    const String wellId = '507f1f77bcf86cd799439011';
    if (wellId.isNotEmpty) {
      pumpController.setWellId(wellId);
    } else {
      Get.snackbar('Error', 'No well selected.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  void _showAlert(String message, {bool isSuccess = true}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isSuccess ? Icons.check_circle : Icons.error,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  static const rowH = 32.0;

  final List<String> pumpTypes = [
    '',
    'Triplex',
    'Duplex',
    'Quintuplex',
    'Quadplex',
  ];

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
                offset: const Offset(0, 2))
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          children: [
            _headerRow(),
            Expanded(child: _tableBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

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
              const SizedBox(width: 12),
              const Icon(Icons.precision_manufacturing,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text("Pump Configuration",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const Spacer(),
              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text("${pumpController.pumpCount} pumps",
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white)),
                      ],
                    ),
                  )),
              const SizedBox(width: 12),
            ],
          ),
        ),
        Container(
          height: rowH,
          decoration: BoxDecoration(
            color: const Color(0xfff0f9ff),
            border:
                Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
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
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: Colors.grey.shade300, width: 1)),
                  child: Column(
                    children: [
                      Container(
                        height: rowH / 2,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade300, width: 1))),
                        child: const Text('Surface Line',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    border: Border(
                                        right: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1))),
                                child: const Text('Length\n(m)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text('ID\n(in)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _HCell('Actions', flex: 2),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _tableBody() {
    return Obx(() {
      if (pumpController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        itemCount: pumpController.pumps.length,
        itemBuilder: (_, i) {
          final p = pumpController.pumps[i];

          return Container(
            height: rowH,
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xfffafafa),
              border:
                  Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
            ),
            child: Row(
              children: _addDividers([
                _cellText('${i + 1}', flex: 1),

                // Type dropdown
                _typeDropdown(p, i, flex: 2),

                // Model
                _editableField(p.model, i, (val) {
                  p.model.value = val;
                  pumpController.onFieldChanged(i);
                }, flex: 3),

                // Liner ID — triggers displacement calc
                _editableField(p.linerId, i, (val) {
                  p.linerId.value = val;
                  p.recalculateDisplacement();
                  pumpController.onFieldChanged(i);
                }, flex: 2),

     // AFTER — Rod OD locked for all except Duplex
Expanded(
  flex: 2,
  child: Obx(() {
    final isDuplex = p.type.value == 'Duplex';
    final isLocked = dashCtrl.isLocked.value || !isDuplex; // ✅ locked if app is locked OR not Duplex

    return GestureDetector(
      onTap: dashCtrl.isLocked.value ? () => dashCtrl.showLockedPopup() : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        color: !isDuplex ? const Color(0xfff5f5f5) : null, // grey bg for non-Duplex
        child: isLocked
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  isDuplex ? p.rodOd.value : '', // non-Duplex shows empty
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              )
            : TextField(
                controller: TextEditingController(text: p.rodOd.value)
                  ..selection = TextSelection.fromPosition(
                      TextPosition(offset: p.rodOd.value.length)),
                onChanged: (val) {
                  p.rodOd.value = val;
                  p.recalculateDisplacement(); // always safe, only Duplex reaches here
                  pumpController.onFieldChanged(i);
                },
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  border: InputBorder.none,
                ),
              ),
      ),
    );
  }),
),

                // Stroke Length — triggers displacement calc
                _editableField(p.strokeLength, i, (val) {
                  p.strokeLength.value = val;
                  p.recalculateDisplacement();
                  pumpController.onFieldChanged(i);
                }, flex: 2),

                // Efficiency
                _editableField(p.efficiency, i, (val) {
                  p.efficiency.value = val;
                  p.recalculateDisplacement();
                  pumpController.onFieldChanged(i);
                }, flex: 2),

                // Displacement — READ ONLY, auto-calculated
                _displacementCell(p, flex: 2),

                // Max Pump Pressure
                _editableField(p.maxPumpP, i, (val) {
                  p.maxPumpP.value = val;
                  pumpController.onFieldChanged(i);
                }, flex: 2),

                // Max HP
                _editableField(p.maxHp, i, (val) {
                  p.maxHp.value = val;
                  pumpController.onFieldChanged(i);
                }, flex: 2),

                // Surface Line (Length + ID)
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1)),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                                border: Border(
                                    right: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1))),
                            child: Obx(() => dashCtrl.isLocked.value
                                ? GestureDetector(
                                    onTap: () => dashCtrl.showLockedPopup(),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        alignment: Alignment.center,
                                        child: Text(p.surfaceLen.value,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary))),
                                  )
                                : TextField(
                                    controller: TextEditingController(
                                        text: p.surfaceLen.value)
                                      ..selection =
                                          TextSelection.fromPosition(
                                              TextPosition(
                                                  offset: p
                                                      .surfaceLen
                                                      .value
                                                      .length)),
                                    onChanged: (v) {
                                      p.surfaceLen.value = v;
                                      pumpController.onFieldChanged(i);
                                    },
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textPrimary),
                                    decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 4),
                                        border: InputBorder.none))),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Obx(() => dashCtrl.isLocked.value
                                ? GestureDetector(
                                    onTap: () => dashCtrl.showLockedPopup(),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        alignment: Alignment.center,
                                        child: Text(p.surfaceId.value,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary))),
                                  )
                                : TextField(
                                    controller: TextEditingController(
                                        text: p.surfaceId.value)
                                      ..selection =
                                          TextSelection.fromPosition(
                                              TextPosition(
                                                  offset: p
                                                      .surfaceId
                                                      .value
                                                      .length)),
                                    onChanged: (v) {
                                      p.surfaceId.value = v;
                                      pumpController.onFieldChanged(i);
                                    },
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textPrimary),
                                    decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 4),
                                        border: InputBorder.none))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _actionButtons(p, i, flex: 2),
              ]),
            ),
          );
        },
      );
    });
  }

  /// Displacement cell — read-only, green background when calculated
  Widget _displacementCell(PumpModel pump, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Obx(() {
        final val = pump.displacement.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: val.isNotEmpty
              ? const Color(0xffe8f5e9)
              : const Color(0xfff5f5f5),
          alignment: Alignment.center,
          child: Text(
            val.isEmpty ? '-' : val,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  val.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
              color: val.isNotEmpty ? Colors.green.shade700 : Colors.grey,
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _addDividers(List<Widget> widgets) {
    final List<Widget> result = [];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(Container(
            width: 1,
            color: Colors.grey.shade200,
            height: double.infinity));
      }
    }
    return result;
  }

  Widget _cellText(String t, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(t,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textPrimary)),
      ),
    );
  }

  Widget _typeDropdown(PumpModel pump, int index, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Obx(() => dashCtrl.isLocked.value
            ? GestureDetector(
                onTap: () => dashCtrl.showLockedPopup(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Text(pump.type.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary))),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: pumpTypes.contains(pump.type.value)
                      ? pump.type.value
                      : '',
                  isExpanded: true,
                  isDense: true,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textPrimary),
                  items: pumpTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type.isEmpty ? 'Select' : type,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: type.isEmpty
                                ? Colors.grey
                                : AppTheme.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      pump.type.value = newValue;
                      pump.recalculateDisplacement();
                      pumpController.onFieldChanged(index);
                    }
                  },
                ),
              )),
      ),
    );
  }

  Widget _editableField(
    RxString value,
    int index,
    Function(String) onChanged, {
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Obx(() => dashCtrl.isLocked.value
            ? GestureDetector(
                onTap: () => dashCtrl.showLockedPopup(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Text(value.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary))),
              )
            : TextField(
                controller: TextEditingController(text: value.value)
                  ..selection = TextSelection.fromPosition(
                      TextPosition(offset: value.value.length)),
                onChanged: (v) => onChanged(v),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    border: InputBorder.none))),
      ),
    );
  }

  Widget _actionButtons(PumpModel pump, int index, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Obx(() {
        if (dashCtrl.isLocked.value) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.lock, size: 16, color: Colors.grey),
                onPressed: () => dashCtrl.showLockedPopup(),
                tooltip: 'Locked',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          );
        }

        final isSyncing = pumpController.updatingRows.contains(index);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // NEW pump — show Save button
            if (pump.hasData && pump.id == null)
              IconButton(
                icon: const Icon(Icons.save, size: 16),
                onPressed: () async {
                  try {
                    await pumpController.savePump(index);
                    if (mounted) {
                      _showAlert('Pump saved successfully', isSuccess: true);
                    }
                  } catch (e) {
                    if (mounted) {
                      _showAlert('Failed to save: $e', isSuccess: false);
                    }
                  }
                },
                tooltip: 'Save',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.green,
              ),

            // SAVED pump — show sync/check indicator
            if (pump.id != null)
              SizedBox(
                width: 18,
                height: 18,
                child: isSyncing
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      )
                    : const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
              ),

            const SizedBox(width: 4),

            // Delete button
            if (pump.hasData)
              IconButton(
                icon: const Icon(Icons.delete, size: 16),
                onPressed: () async {
                  try {
                    final confirmed = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Delete Pump'),
                        content: const Text(
                            'Are you sure you want to delete this pump?'),
                        actions: [
                          TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Get.back(result: true),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await pumpController.deletePump(index);
                      if (mounted) {
                        _showAlert('Pump deleted successfully',
                            isSuccess: true);
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      _showAlert('Failed to delete: $e', isSuccess: false);
                    }
                  }
                },
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.red,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() => ElevatedButton.icon(
                onPressed: dashCtrl.isLocked.value
                    ? () => dashCtrl.showLockedPopup()
                    : (pumpController.isLoading.value ? null : () => _bulkSavePumps()),
                icon: pumpController.isLoading.value
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 16),
                label: Text(
                    pumpController.isLoading.value
                        ? 'Saving...'
                        : 'Save All Pumps',
                    style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dashCtrl.isLocked.value ? Colors.grey : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _bulkSavePumps() async {
    final pumpsWithData =
        pumpController.pumps.where((pump) => pump.hasData).toList();

    if (pumpsWithData.isEmpty) {
      _showAlert('No pumps to save', isSuccess: false);
      return;
    }

    try {
      pumpController.isLoading.value = true;

      for (int i = 0; i < pumpController.pumps.length; i++) {
        if (pumpController.pumps[i].hasData) {
          await pumpController.savePump(i);
        }
      }

      await pumpController.loadPumps(pumpController.currentWellId);

      if (mounted) _showAlert('All pumps saved successfully', isSuccess: true);
    } catch (e) {
      if (mounted) _showAlert('Failed to save pumps: $e', isSuccess: false);
    } finally {
      pumpController.isLoading.value = false;
    }
  }
}

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
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
      ),
    );
  }
}