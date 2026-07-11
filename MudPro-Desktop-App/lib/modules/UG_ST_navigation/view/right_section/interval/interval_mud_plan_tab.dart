import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/well_setup_ui_pattern.dart';

const Color _impBorder = wellSetupBorder;
const Color _impHeader = wellSetupReadOnlyFill;
const Color _impCell = wellSetupLockedEditable;

String _formatIntervalPlanCellText(String value) {
  final text = value.trim();
  if (text.isEmpty) return value;
  final parsed = double.tryParse(text.replaceAll(',', ''));
  if (parsed == null) return value;
  return formatOperationNumber(
    parsed,
    fallbackDecimals: 4,
    trimFallback: true,
  );
}

class IntervalMudPlanTab extends StatefulWidget {
  const IntervalMudPlanTab({super.key});

  @override
  State<IntervalMudPlanTab> createState() => _IntervalMudPlanTabState();
}

class _IntervalMudPlanTabState extends State<IntervalMudPlanTab> {
  late final MudController c;
  late final DashboardController dashboard;
  late final IntervalController intervalController;
  final ScrollController _propertyScrollCtrl = ScrollController();
  final ScrollController _rheologyScrollCtrl = ScrollController();
  Worker? _intervalSelectionWorker;
  String _activeScopeKey = '';
  Future<void> _scopeUpdate = Future.value();

  static const _planSamples = ['L', 'H'];
  static const _planIndices = [3, 4];

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<MudController>()
        ? Get.find<MudController>()
        : Get.put(MudController());
    dashboard = Get.find<DashboardController>();
    intervalController = Get.find<IntervalController>();
    _intervalSelectionWorker = ever<IntervalItem?>(
      intervalController.selected,
      _applyIntervalScope,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyIntervalScope(intervalController.selected.value),
    );
  }

  @override
  void deactivate() {
    c.saveMudReportState(force: true);
    super.deactivate();
  }

  @override
  void dispose() {
    c.saveMudReportState(force: true);
    _intervalSelectionWorker?.dispose();
    _propertyScrollCtrl.dispose();
    _rheologyScrollCtrl.dispose();
    super.dispose();
  }

  void _applyIntervalScope(IntervalItem? interval) {
    final scopeKey = interval?.id.trim().isNotEmpty == true
        ? 'interval:${interval!.id.trim()}'
        : 'interval:none';
    if (_activeScopeKey == scopeKey) return;
    _activeScopeKey = scopeKey;
    _scopeUpdate = _scopeUpdate.then((_) => c.useMudStateScope(scopeKey));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final locked = dashboard.isLocked.value;

      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Mud Properties',
                style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
              ),
            ),
            Row(
              children: [
                Text(
                  'Fluid Type',
                  style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 8),
                _dropdownShell(
                  width: 128,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: c.selectedFluidType.value,
                      isDense: true,
                      items: [
                        DropdownMenuItem(
                          value: 'Water-based',
                          child: Text(
                            'Water-based',
                            style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Oil-based',
                          child: Text(
                            'Oil-based',
                            style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Synthetic',
                          child: Text(
                            'Synthetic',
                            style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      onChanged: locked ? null : (v) => c.changeFluidType(v!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (c.selectedFluidType.value == 'Oil-based' ||
                    c.selectedFluidType.value == 'Synthetic') ...[
                  Text(
                    'Salt Type',
                    style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  _dropdownShell(
                    width: 148,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: c.selectedSaltType.value,
                        isDense: true,
                        items: [
                          DropdownMenuItem(
                            value: 'CaCl2',
                            child: Text(
                              'CaCl2',
                              style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'NaCl',
                            child: Text(
                              'NaCl',
                              style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'NaCl + CaCl2',
                            child: Text(
                              'NaCl + CaCl2',
                              style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Sodium Formate',
                            child: Text(
                              'Sodium Formate',
                              style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                        onChanged: locked
                            ? null
                            : (v) {
                                if (v != null) {
                                  c.changeSaltType(v);
                                }
                              },
                      ),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Checkbox(
                        value: c.isWeightedMud.value,
                        onChanged: locked
                            ? null
                            : (v) {
                                c.isWeightedMud.value = v ?? false;
                                c.fetchSolidAnalysis();
                              },
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        'Weighted Mud',
                        style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                const Spacer(),
                Text(
                  'Model',
                  style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 8),
                _dropdownShell(
                  width: 148,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: c.rheologyModel.value,
                      isDense: true,
                      items: [
                        DropdownMenuItem(
                          value: 'Bingham',
                          child: Text(
                            'Bingham',
                            style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Power Law',
                          child: Text(
                            'Power Law',
                            style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'HB',
                          child: Text(
                            'HB',
                            style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      onChanged: locked ? null : (v) => c.changeModel(v!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _propertyTable(locked)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _rheologyTable(locked)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _dropdownShell({required double width, required Widget child}) {
    return Container(
      width: width,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _impBorder),
      ),
      child: child,
    );
  }

  Widget _propertyTable(bool locked) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _impBorder),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.primaryColor,
            child: Row(
              children: [
                _headerCell('Property', flex: 4),
                for (final sample in _planSamples)
                  _headerCell(sample, flex: 1, center: true),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              final entries = c.propertyTable.entries.toList();
              return Scrollbar(
                controller: _propertyScrollCtrl,
                thumbVisibility: true,
                child: ListView(
                  controller: _propertyScrollCtrl,
                  children: [
                    ...entries.map((entry) {
                      final label = _propertyLabel(
                        entry.key,
                        c.propertyUnits[entry.key] ?? '',
                      );
                      return _PropertyRow(
                        label: label,
                        rawKey: entry.key,
                        values: entry.value,
                        removable: c.isPropertyRemovable(entry.key),
                        locked: locked,
                        onRemove: () => c.removeAddedPropertyRow(entry.key),
                      );
                    }),
                    _AddPropertyRow(controller: c, locked: locked),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _propertyLabel(String name, String unit) {
    if (unit.trim().isEmpty) return name;
    return '$name (${unit.trim()})';
  }

  Widget _rheologyTable(bool locked) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _impBorder),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.primaryColor,
            child: Row(
              children: [
                _headerCell('Rheology', flex: 2),
                _headerCell('L', flex: 1, center: true),
                _headerCell('H', flex: 1, center: true),
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () => Scrollbar(
                controller: _rheologyScrollCtrl,
                thumbVisibility: true,
                child: ListView(
                  controller: _rheologyScrollCtrl,
                  children: c.rheologyTable.entries.map((entry) {
                    final isCalculated = double.tryParse(entry.key) == null;
                    return Container(
                      height: 28,
                      decoration: BoxDecoration(
                        border: const Border(
                          bottom: BorderSide(color: _impBorder),
                        ),
                        color: isCalculated ? _impCell : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: const BoxDecoration(
                                color: _impHeader,
                                border: Border(
                                  right: BorderSide(color: _impBorder),
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                entry.key,
                                style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          ..._planIndices.map((index) {
                            return Expanded(
                              child: _RheoCell(
                                value: entry.value[index],
                                readOnly: locked || isCalculated,
                                align: TextAlign.left,
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: _impBorder)),
        ),
        alignment: center ? Alignment.center : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: const TextStyle(
fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  static const Set<String> _mergedPropertyKeys = {
    'Description',
    'Sample from',
    'Time Sample Taken (hh:mm)',
  };

  final String label;
  final String rawKey;
  final List<RxString> values;
  final bool removable;
  final bool locked;
  final VoidCallback onRemove;

  const _PropertyRow({
    required this.label,
    required this.rawKey,
    required this.values,
    required this.removable,
    required this.locked,
    required this.onRemove,
  });

  Future<void> _showMenu(BuildContext context, TapDownDetails details) async {
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _mudMenuItem('delete', 'Delete', enabled: removable && !locked),
        const PopupMenuDivider(),
        _mudMenuItem('copy', 'Copy', enabled: false),
        _mudMenuItem('paste', 'Paste', enabled: false),
        _mudMenuItem('top', 'To the Top', enabled: false),
        _mudMenuItem('bottom', 'To the Bottom', enabled: false),
      ],
    );

    if (action == 'delete') {
      onRemove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mergePlanCells = _mergedPropertyKeys.contains(rawKey);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => _showMenu(context, details),
      child: Container(
        height: 28,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _impBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  color: _impHeader,
                  border: Border(right: BorderSide(color: _impBorder)),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (mergePlanCells)
              Expanded(
                flex: 2,
                child: _MergedMudCell(
                  primary: values[_IntervalMudPlanTabState._planIndices.first],
                  secondary: values[_IntervalMudPlanTabState._planIndices.last],
                  readOnly: locked,
                ),
              )
            else
              ..._IntervalMudPlanTabState._planIndices.map((index) {
                return Expanded(
                  child: _MudCell(
                    value: values[index],
                    readOnly: locked,
                    align: TextAlign.left,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MergedMudCell extends StatefulWidget {
  final RxString primary;
  final RxString secondary;
  final bool readOnly;

  const _MergedMudCell({
    required this.primary,
    required this.secondary,
    required this.readOnly,
  });

  @override
  State<_MergedMudCell> createState() => _MergedMudCellState();
}

class _MergedMudCellState extends State<_MergedMudCell> {
  late final TextEditingController _controller;

  String get _displayValue {
    final primaryValue = widget.primary.value;
    if (primaryValue.trim().isNotEmpty) return primaryValue;
    return widget.secondary.value;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayValue);
  }

  @override
  void didUpdateWidget(covariant _MergedMudCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllerText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncControllerText() {
    final next = _displayValue;
    if (_controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  void _mirrorValue(String value) {
    widget.primary.value = value;
    widget.secondary.value = value;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _syncControllerText();

      return Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: widget.readOnly ? _impCell : Colors.white,
          border: const Border(right: BorderSide(color: _impBorder)),
        ),
        child: TextField(
          controller: _controller,
          readOnly: widget.readOnly,
          textAlign: TextAlign.left,
          onChanged: _mirrorValue,
          style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    });
  }
}

class _AddPropertyRow extends StatefulWidget {
  final MudController controller;
  final bool locked;

  const _AddPropertyRow({required this.controller, required this.locked});

  @override
  State<_AddPropertyRow> createState() => _AddPropertyRowState();
}

class _AddPropertyRowState extends State<_AddPropertyRow> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.locked) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final options = widget.controller.availableProperties.toList();
      if (options.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 30,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _impBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(
                  color: _impHeader,
                  border: Border(right: BorderSide(color: _impBorder)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selected,
                    hint: Text(
                      'Add property',
                      style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
                    ),
                    isExpanded: true,
                    isDense: true,
                    items: options
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              style: AppTheme.wellLikeBodyText.copyWith(
fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      widget.controller.addPropertyRow(value);
                      setState(() => _selected = null);
                    },
                  ),
                ),
              ),
            ),
            const Expanded(
              child: SizedBox(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _impCell,
                    border: Border(right: BorderSide(color: _impBorder)),
                  ),
                ),
              ),
            ),
            const Expanded(
              child: DecoratedBox(decoration: BoxDecoration(color: _impCell)),
            ),
          ],
        ),
      );
    });
  }
}

class _MudCell extends StatefulWidget {
  final RxString value;
  final bool readOnly;
  final TextAlign align;

  const _MudCell({
    required this.value,
    required this.readOnly,
    this.align = TextAlign.left,
  });

  @override
  State<_MudCell> createState() => _MudCellState();
}

class _MudCellState extends State<_MudCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String get _displayValue => _formatIntervalPlanCellText(widget.value.value);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayValue);
    _focusNode = FocusNode()
      ..addListener(() {
        if (!_focusNode.hasFocus) {
          _syncControllerText(forceFormatted: true);
        }
      });
  }

  @override
  void didUpdateWidget(covariant _MudCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllerText();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncControllerText({bool forceFormatted = false}) {
    if (_focusNode.hasFocus && !forceFormatted) return;
    final next = _displayValue;
    if (_controller.text == next) return;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _syncControllerText();

      return Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: widget.readOnly ? _impCell : Colors.white,
          border: const Border(right: BorderSide(color: _impBorder)),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          textAlign: widget.align,
          onChanged: (value) => widget.value.value = value,
          style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    });
  }
}

class _RheoCell extends _MudCell {
  const _RheoCell({required super.value, required super.readOnly, super.align});
}

PopupMenuItem<String> _mudMenuItem(
  String value,
  String label, {
  required bool enabled,
}) {
  return PopupMenuItem<String>(
    value: value,
    enabled: enabled,
    height: 28,
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: enabled ? Colors.black : const Color(0xFF9EA4AD),
      ),
    ),
  );
}
