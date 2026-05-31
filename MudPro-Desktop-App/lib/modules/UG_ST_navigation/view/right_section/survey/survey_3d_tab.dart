import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/survey_model.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/survey/controller/survey_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';

class Survey3DTab extends StatelessWidget {
  Survey3DTab({super.key});

  final SurveyController controller = Get.find<SurveyController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return WellPath3DViewer(
        surveyPoints: controller.plotPoints.map(SurveyPoint.fromPlot).toList(),
        rotationX: controller.rotationX.value,
        rotationY: controller.rotationY.value,
        zoom: controller.zoom.value,
        backgroundColor: controller.graph3DBackgroundColor.value,
        gridLegendColor: controller.graph3DGridLegendColor.value,
        showGrid: controller.show3DGrid.value,
        cylinderScale: controller.graph3DCylinderScale.value,
        isAutoRotating: controller.is3DAutoRotating.value,
        onRotateLeft: controller.rotateLeft,
        onRotateRight: controller.rotateRight,
        onTiltDown: controller.rotateDown,
        onTiltUp: controller.rotateUp,
        onZoomIn: controller.zoomIn,
        onZoomOut: controller.zoomOut,
        onReset: controller.reset3DView,
        onCapture: () => debugPrint('3D capture screen requested'),
        onSettings: () => _show3DViewSettings(context),
        onStartRotate: controller.toggle3DAutoRotate,
        onTopToBottom: () {
          controller.rotationX.value = 1.15;
          controller.rotationY.value = 0.75;
        },
        onBottomToTop: () {
          controller.rotationX.value = -0.55;
          controller.rotationY.value = 0.75;
        },
        onNorthToSouth: () {
          controller.rotationX.value = 0.55;
          controller.rotationY.value = 1.45;
        },
        onSouthToNorth: () {
          controller.rotationX.value = 0.55;
          controller.rotationY.value = 0.05;
        },
        onPanUpdate: (details) {
          controller.rotationY.value += details.delta.dx * 0.01;
          controller.rotationX.value += details.delta.dy * 0.01;
        },
      );
    });
  }

  Future<void> _show3DViewSettings(BuildContext context) async {
    var showGrid = controller.show3DGrid.value;
    var showAllQuadrants = controller.show3DAllQuadrants.value;
    var backgroundColor = controller.graph3DBackgroundColor.value;
    var gridLegendColor = controller.graph3DGridLegendColor.value;
    var cylinderScale = controller.graph3DCylinderScale.value;
    var moveInterval = controller.graph3DMoveRotateZoomInterval.value;
    var angle = controller.graph3DAngle.value;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DialogTitleBar(
                      title: '3D View Setting',
                      onClose: () => Navigator.of(dialogContext).pop(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SettingsCheckbox(
                            label: 'Grid',
                            value: showGrid,
                            onChanged: (value) {
                              setState(() => showGrid = value ?? false);
                            },
                          ),
                          _SettingsCheckbox(
                            label: 'All Quadrants',
                            value: showAllQuadrants,
                            onChanged: (value) {
                              setState(
                                () => showAllQuadrants = value ?? false,
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          _ColorGroup(
                            backgroundColor: backgroundColor,
                            gridLegendColor: gridLegendColor,
                            onPickBackground: () async {
                              final picked = await _showColorDialog(
                                dialogContext,
                                initialColor: backgroundColor,
                              );
                              if (picked != null) {
                                setState(() => backgroundColor = picked);
                              }
                            },
                            onPickGridLegend: () async {
                              final picked = await _showColorDialog(
                                dialogContext,
                                initialColor: gridLegendColor,
                              );
                              if (picked != null) {
                                setState(() => gridLegendColor = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          _SettingsDropdownRow(
                            label: 'Cylinder Scale',
                            value: cylinderScale,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => cylinderScale = value);
                              }
                            },
                          ),
                          _SettingsDropdownRow(
                            label: 'Move/Rotate/Zoom Interval',
                            value: moveInterval,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => moveInterval = value);
                              }
                            },
                          ),
                          _AngleRow(
                            value: angle,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => angle = value);
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _DialogButton(
                                label: 'Default',
                                onPressed: () {
                                  setState(() {
                                    showGrid = true;
                                    showAllQuadrants = false;
                                    backgroundColor = const Color(0xFFE5E5E5);
                                    gridLegendColor = Colors.black;
                                    cylinderScale = 3;
                                    moveInterval = 5;
                                    angle = 150;
                                  });
                                },
                              ),
                              const Spacer(),
                              _DialogButton(
                                label: 'OK',
                                onPressed: () {
                                  controller.apply3DViewSettings(
                                    showGrid: showGrid,
                                    showAllQuadrants: showAllQuadrants,
                                    backgroundColor: backgroundColor,
                                    gridLegendColor: gridLegendColor,
                                    cylinderScale: cylinderScale,
                                    moveRotateZoomInterval: moveInterval,
                                    angle: angle,
                                  );
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                              const SizedBox(width: 8),
                              _DialogButton(
                                label: 'Cancel',
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Color?> _showColorDialog(
    BuildContext context, {
    required Color initialColor,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(initialColor: initialColor),
    );
  }
}

class WellPath3DViewer extends StatelessWidget {
  const WellPath3DViewer({
    super.key,
    required this.surveyPoints,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.backgroundColor,
    required this.gridLegendColor,
    required this.showGrid,
    required this.cylinderScale,
    required this.isAutoRotating,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onTiltDown,
    required this.onTiltUp,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onCapture,
    required this.onSettings,
    required this.onStartRotate,
    required this.onTopToBottom,
    required this.onBottomToTop,
    required this.onNorthToSouth,
    required this.onSouthToNorth,
    required this.onPanUpdate,
  });

  final List<SurveyPoint> surveyPoints;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final Color backgroundColor;
  final Color gridLegendColor;
  final bool showGrid;
  final int cylinderScale;
  final bool isAutoRotating;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onTiltDown;
  final VoidCallback onTiltUp;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onCapture;
  final VoidCallback onSettings;
  final VoidCallback onStartRotate;
  final VoidCallback onTopToBottom;
  final VoidCallback onBottomToTop;
  final VoidCallback onNorthToSouth;
  final VoidCallback onSouthToNorth;
  final GestureDragUpdateCallback onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final bounds = _Survey3DBounds.fromPoints(surveyPoints);

    return Container(
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: onPanUpdate,
              child: CustomPaint(
                painter: WellPath3DPainter(
                  points: surveyPoints,
                  rotationX: rotationX,
                  rotationY: rotationY,
                  zoom: zoom,
                  showGrid: showGrid,
                  gridLegendColor: gridLegendColor,
                  cylinderScale: cylinderScale,
                  minEastWest: bounds.minEastWest,
                  maxEastWest: bounds.maxEastWest,
                  eastWestAxisMax: bounds.eastWestAxisMax,
                  minNorthSouth: bounds.minNorthSouth,
                  maxNorthSouth: bounds.maxNorthSouth,
                  northSouthAxisMax: bounds.northSouthAxisMax,
                  maxTvd: bounds.maxTvd,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          _Survey3DTools(
            onRotateLeft: onRotateLeft,
            onRotateRight: onRotateRight,
            onTiltDown: onTiltDown,
            onTiltUp: onTiltUp,
            onZoomIn: onZoomIn,
            onZoomOut: onZoomOut,
            onReset: onReset,
            onCapture: onCapture,
            onSettings: onSettings,
            onStartRotate: onStartRotate,
            isAutoRotating: isAutoRotating,
            onTopToBottom: onTopToBottom,
            onBottomToTop: onBottomToTop,
            onNorthToSouth: onNorthToSouth,
            onSouthToNorth: onSouthToNorth,
          ),
        ],
      ),
    );
  }
}

class _Survey3DTools extends StatelessWidget {
  const _Survey3DTools({
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onTiltDown,
    required this.onTiltUp,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onCapture,
    required this.onSettings,
    required this.onStartRotate,
    required this.isAutoRotating,
    required this.onTopToBottom,
    required this.onBottomToTop,
    required this.onNorthToSouth,
    required this.onSouthToNorth,
  });

  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onTiltDown;
  final VoidCallback onTiltUp;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onCapture;
  final VoidCallback onSettings;
  final VoidCallback onStartRotate;
  final bool isAutoRotating;
  final VoidCallback onTopToBottom;
  final VoidCallback onBottomToTop;
  final VoidCallback onNorthToSouth;
  final VoidCallback onSouthToNorth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      margin: const EdgeInsets.only(right: 4),
      color: const Color(0xFFEFEFEF),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _tool(Icons.rotate_left, 'Rotate Left', onRotateLeft),
            _tool(Icons.rotate_right, 'Rotate Right', onRotateRight),
            _tool(Icons.keyboard_double_arrow_down, 'Rotate Down', onTiltDown),
            _tool(Icons.keyboard_double_arrow_up, 'Rotate Up', onTiltUp),
            const _ToolDivider(),
            _tool(Icons.arrow_upward, 'Move Up', onTiltUp),
            _tool(Icons.arrow_downward, 'Move Down', onTiltDown),
            _tool(Icons.arrow_back, 'Move Left', onRotateLeft),
            _tool(Icons.arrow_forward, 'Move Right', onRotateRight),
            const _ToolDivider(),
            _tool(Icons.zoom_in, 'Zoom In', onZoomIn),
            _tool(Icons.zoom_out, 'Zoom Out', onZoomOut),
            const _ToolDivider(),
            _tool(
              Icons.camera_alt_outlined,
              'Capture Screen to Clipboard',
              onCapture,
            ),
            _tool(Icons.settings, '3D View Settings', onSettings),
            _tool(
              isAutoRotating ? Icons.pause : Icons.play_arrow,
              isAutoRotating ? 'Stop Rotate' : 'Start Rotate',
              onStartRotate,
            ),
            _tool(Icons.home, 'Default View', onReset),
            const _ToolDivider(),
            _tool(Icons.vertical_align_bottom, 'Top to Bottom', onTopToBottom),
            _tool(Icons.vertical_align_top, 'Bottom to Top', onBottomToTop),
            _tool(Icons.south, 'North to South', onNorthToSouth),
            _tool(Icons.north, 'South to North', onSouthToNorth),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tool(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 25,
          child: Icon(icon, size: 19, color: const Color(0xFF2C9FE7)),
        ),
      ),
    );
  }
}

class _ToolDivider extends StatelessWidget {
  const _ToolDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFD4D4D4),
    );
  }
}

class _DialogTitleBar extends StatelessWidget {
  const _DialogTitleBar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD8D8D8))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, color: Color(0xFF222222)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _SettingsCheckbox extends StatelessWidget {
  const _SettingsCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _ColorGroup extends StatelessWidget {
  const _ColorGroup({
    required this.backgroundColor,
    required this.gridLegendColor,
    required this.onPickBackground,
    required this.onPickGridLegend,
  });

  final Color backgroundColor;
  final Color gridLegendColor;
  final VoidCallback onPickBackground;
  final VoidCallback onPickGridLegend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-4, -22),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Text('Color', style: TextStyle(fontSize: 13)),
            ),
          ),
          _ColorRow(
            label: 'Well',
            color: const Color(0xFF777777),
            enabled: false,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ColorRow(
            label: 'Background',
            color: backgroundColor,
            enabled: true,
            onTap: onPickBackground,
          ),
          const SizedBox(height: 10),
          _ColorRow(
            label: 'Grid + Legend',
            color: gridLegendColor,
            enabled: true,
            onTap: onPickGridLegend,
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 170,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: enabled ? const Color(0xFF333333) : Colors.grey,
            ),
          ),
        ),
        InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: enabled ? color : Colors.white,
              border: Border.all(color: const Color(0xFFC8C8C8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: enabled
                ? null
                : const Center(
                    child: Text('...', style: TextStyle(color: Colors.grey)),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SettingsDropdownRow extends StatelessWidget {
  const _SettingsDropdownRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          SizedBox(
            width: 108,
            height: 28,
            child: DropdownButtonFormField<int>(
              value: value,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                5,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}'),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _AngleRow extends StatelessWidget {
  const _AngleRow({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = [
      0,
      30,
      60,
      90,
      120,
      150,
      180,
      210,
      240,
      270,
      300,
      330,
      360,
    ];
    final selected = values.contains(value) ? value : 150;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Angle',
              style: TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 108,
            height: 28,
            child: DropdownButtonFormField<int>(
              value: selected,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                border: OutlineInputBorder(),
              ),
              items: values
                  .map(
                    (item) => DropdownMenuItem<int>(
                      value: item,
                      child: Text('$item'),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 30,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  static const List<Color> _basicColors = [
    Color(0xFFFF8080),
    Color(0xFFFFFF80),
    Color(0xFF80FF80),
    Color(0xFF00FF80),
    Color(0xFF80FFFF),
    Color(0xFF0080FF),
    Color(0xFFFF80C0),
    Color(0xFFFF80FF),
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF80FF00),
    Color(0xFF00FF40),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFC080FF),
    Color(0xFFFF00FF),
    Color(0xFFC00000),
    Color(0xFFFF8000),
    Color(0xFF00C000),
    Color(0xFF008080),
    Color(0xFF0080C0),
    Color(0xFF8080FF),
    Color(0xFF800080),
    Color(0xFFFF0080),
    Color(0xFF800000),
    Color(0xFF804000),
    Color(0xFF008000),
    Color(0xFF004040),
    Color(0xFF0000A0),
    Color(0xFF000080),
    Color(0xFF800040),
    Color(0xFF8000FF),
    Color(0xFF400000),
    Color(0xFF804000),
    Color(0xFF808000),
    Color(0xFF004000),
    Color(0xFF004040),
    Color(0xFF808080),
    Color(0xFF400040),
    Color(0xFFFFFFFF),
  ];

  late Color _selectedColor;
  late HSVColor _selectedHsv;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _selectedHsv = HSVColor.fromColor(_selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: _expanded ? 486.0 : 250.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogTitleBar(
              title: 'Color',
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPaletteColumn(),
                  if (_expanded) ...[
                    const SizedBox(width: 16),
                    _buildCustomColumn(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteColumn() {
    return SizedBox(
      width: 226,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic colors:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _basicColors.map(_colorCell).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Custom colors:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: List.generate(
              16,
              (_) => Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFBEBEBE)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 226,
            height: 28,
            child: OutlinedButton(
              onPressed: () => setState(() => _expanded = true),
              style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Define Custom Colors >>',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _DialogButton(
                label: 'OK',
                onPressed: () => Navigator.of(context).pop(_selectedColor),
              ),
              const SizedBox(width: 8),
              _DialogButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomColumn() {
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onPanDown: (details) => _pickCustomColor(details.localPosition),
                onPanUpdate: (details) =>
                    _pickCustomColor(details.localPosition),
                child: Container(
                  width: 188,
                  height: 188,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFB8B8B8)),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment(
                      (_selectedHsv.hue / 180) - 1,
                      (1 - _selectedHsv.saturation * 2),
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 18,
                height: 188,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFB8B8B8)),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.black],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 60,
                height: 44,
                color: _selectedColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _ColorValueRow(label: 'Hue:', value: _selectedHsv.hue),
                    _ColorValueRow(
                      label: 'Sat:',
                      value: _selectedHsv.saturation * 100,
                    ),
                    _ColorValueRow(
                      label: 'Lum:',
                      value: _selectedHsv.value * 100,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _ColorValueRow(label: 'Red:', value: _selectedColor.red),
                    _ColorValueRow(
                      label: 'Green:',
                      value: _selectedColor.green,
                    ),
                    _ColorValueRow(label: 'Blue:', value: _selectedColor.blue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Add to Custom Colors',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorCell(Color color) {
    final selected = color.value == _selectedColor.value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _selectedHsv = HSVColor.fromColor(color);
        });
      },
      child: Container(
        width: 18,
        height: 18,
        padding: selected ? const EdgeInsets.all(2) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFBEBEBE),
            width: selected ? 2 : 1,
          ),
        ),
        child: Container(color: color),
      ),
    );
  }

  void _pickCustomColor(Offset position) {
    final hue = ((position.dx.clamp(0, 188) / 188) * 360).toDouble();
    final saturation = (1 - (position.dy.clamp(0, 188) / 188)).toDouble();
    setState(() {
      _selectedHsv = HSVColor.fromAHSV(1, hue, saturation, 1);
      _selectedColor = _selectedHsv.toColor();
    });
  }
}

class _ColorValueRow extends StatelessWidget {
  const _ColorValueRow({required this.label, required this.value});

  final String label;
  final num value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            child: Container(
              height: 18,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFC8C8C8)),
              ),
              child: Text(
                value.round().toString(),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SurveyPoint {
  const SurveyPoint({
    required this.md,
    required this.inclination,
    required this.azimuth,
    required this.tvd,
    required this.northing,
    required this.easting,
  });

  factory SurveyPoint.fromPlot(SurveyPlotPoint point) {
    return SurveyPoint(
      md: point.md,
      inclination: point.inc,
      azimuth: point.azi,
      tvd: point.tvd,
      northing: point.northSouth,
      easting: point.eastWest,
    );
  }

  final double md;
  final double inclination;
  final double azimuth;
  final double tvd;
  final double northing;
  final double easting;
}

class WellPath3DPainter extends CustomPainter {
  WellPath3DPainter({
    required this.points,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.showGrid,
    required this.gridLegendColor,
    required this.cylinderScale,
    required this.minEastWest,
    required this.maxEastWest,
    required this.eastWestAxisMax,
    required this.minNorthSouth,
    required this.maxNorthSouth,
    required this.northSouthAxisMax,
    required this.maxTvd,
  });

  final List<SurveyPoint> points;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final bool showGrid;
  final Color gridLegendColor;
  final int cylinderScale;
  final double minEastWest;
  final double maxEastWest;
  final double eastWestAxisMax;
  final double minNorthSouth;
  final double maxNorthSouth;
  final double northSouthAxisMax;
  final double maxTvd;

  static const int _gridDivisions = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = _buildProjection(size);

    if (showGrid) {
      _drawGrid(canvas, projection);
    }
    _drawBoundingBox(canvas, projection);

    if (points.isNotEmpty) {
      _drawWellPath(canvas, projection);
      _drawTvdLabels(canvas, projection);
      _drawNorthSouthLabels(canvas, projection);
      _drawEastWestLabels(canvas, projection);
    }
  }

  _Projection _buildProjection(Size size) {
    final side = math.min(size.width * 0.56, size.height * 0.66) * zoom;
    final xVec = Offset(-side * 0.47, side * 0.09);
    final yVec = Offset(side * 0.47, side * 0.09);
    final zVec = Offset(0, side * 0.50);
    final baseProjection = _Projection(
      origin: Offset.zero,
      x: xVec,
      y: yVec,
      z: zVec,
    );
    final projectedCorners = const [
      _V3(0, 0, 0),
      _V3(1, 0, 0),
      _V3(1, 1, 0),
      _V3(0, 1, 0),
      _V3(0, 0, 1),
      _V3(1, 0, 1),
      _V3(1, 1, 1),
      _V3(0, 1, 1),
    ].map((point) => _project(point, baseProjection)).toList();
    var minX = projectedCorners.first.dx;
    var maxX = projectedCorners.first.dx;
    var minY = projectedCorners.first.dy;
    var maxY = projectedCorners.first.dy;
    for (final point in projectedCorners) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    final graphCenter = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    final origin = Offset(size.width * 0.5, size.height * 0.5) - graphCenter;
    return _Projection(origin: origin, x: xVec, y: yVec, z: zVec);
  }

  void _drawGrid(Canvas canvas, _Projection projection) {
    final gridPaint = Paint()
      ..color = gridLegendColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final eastWestStepCount = _eastWestGridStepCount();
    final tvdStepCount = _tvdGridStepCount();
    final northSouthStepCount = _northSouthGridStepCount();

    for (var i = 0; i <= eastWestStepCount; i++) {
      final t = i / eastWestStepCount;

      _draw3DLine(canvas, _V3(t, 0, 1), _V3(t, 1, 1), projection, gridPaint);
      if (i > 0) {
        _draw3DLine(
          canvas,
          _V3(t, 0, 0),
          _V3(t, 0, 1),
          projection,
          gridPaint,
        );
      }
    }

    for (var i = 0; i <= northSouthStepCount; i++) {
      final t = i / northSouthStepCount;

      _draw3DLine(canvas, _V3(0, t, 1), _V3(1, t, 1), projection, gridPaint);
      if (i > 0) {
        _draw3DLine(
          canvas,
          _V3(0, t, 0),
          _V3(0, t, 1),
          projection,
          gridPaint,
        );
      }
    }

    for (var i = 0; i <= tvdStepCount; i++) {
      final t = i / tvdStepCount;
      _draw3DLine(
        canvas,
        _V3(0, 0, t),
        _V3(1, 0, t),
        projection,
        gridPaint,
      );
      _draw3DLine(
        canvas,
        _V3(0, 0, t),
        _V3(0, 1, t),
        projection,
        gridPaint,
      );
    }
  }

  void _drawBoundingBox(Canvas canvas, _Projection projection) {
    final boxPaint = Paint()
      ..color = gridLegendColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    _draw3DLine(canvas, _V3(0, 0, 1), _V3(1, 0, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(1, 0, 1), _V3(1, 1, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(1, 1, 1), _V3(0, 1, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(0, 1, 1), _V3(0, 0, 1), projection, boxPaint);

    _draw3DLine(canvas, _V3(0, 0, 0), _V3(1, 0, 0), projection, boxPaint);
    _draw3DLine(canvas, _V3(0, 1, 0), _V3(0, 0, 0), projection, boxPaint);

    _draw3DLine(canvas, _V3(0, 0, 0), _V3(0, 0, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(1, 0, 0), _V3(1, 0, 1), projection, boxPaint);
    _draw3DLine(canvas, _V3(0, 1, 0), _V3(0, 1, 1), projection, boxPaint);
  }

  void _drawWellPath(Canvas canvas, _Projection projection) {
    final pathPaint = Paint()
      ..color = const Color(0xFF4D4D4D)
      ..strokeWidth = 2.5 + (cylinderScale.clamp(1, 5).toDouble() * 2.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final shadowPaint = Paint()
      ..color = const Color(0xFF777777)
      ..strokeWidth = 5.5 + (cylinderScale.clamp(1, 5).toDouble() * 2.6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final shadowPath = Path();
    final normalPoints = _centeredNormalPoints();

    for (var i = 0; i < normalPoints.length; i++) {
      final projected = _project(normalPoints[i], projection);

      if (i == 0) {
        path.moveTo(projected.dx, projected.dy);
        shadowPath.moveTo(projected.dx, projected.dy);
      } else {
        path.lineTo(projected.dx, projected.dy);
        shadowPath.lineTo(projected.dx, projected.dy);
      }
    }

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(path, pathPaint);
  }

  void _drawNorthSouthLabels(Canvas canvas, _Projection projection) {
    final labelStyle = const TextStyle(
      fontSize: 10,
    ).copyWith(color: gridLegendColor);
    final titleStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ).copyWith(color: gridLegendColor);
    final eastWestGridStepCount = _eastWestGridStepCount();
    final stepCount = _northSouthStepCount();
    final rowY = (_northSouthGridStepCount() + 0.5) / _northSouthGridStepCount();
    final firstValueX = 0.5 / eastWestGridStepCount;
    final lastValueX = (eastWestGridStepCount - 0.5) / eastWestGridStepCount;
    final axisStart = _project(_V3(firstValueX, rowY, 1), projection);
    final axisEnd = _project(
      _V3(lastValueX, rowY, 1),
      projection,
    );
    final axisAngle = _readableAxisAngle(axisStart, axisEnd);
    final valueAngle = axisAngle + 0.50;

    for (var i = 1; i <= stepCount; i++) {
      final value = i * 2000;
      final ratio = stepCount == 1 ? 0.0 : (i - 1) / (stepCount - 1);
      final valueX = firstValueX + ((lastValueX - firstValueX) * ratio);
      final position = _project(
        _V3(valueX, rowY, 1),
        projection,
      );
      _drawRotatedCenteredText(
        canvas,
        _formatAxisValue(value),
        position + const Offset(0, 5),
        valueAngle,
        labelStyle,
      );
    }

    final firstTitleX = firstValueX;
    final lastTitleX = lastValueX;
    final titleStart = _project(_V3(firstTitleX, rowY, 1), projection);
    final titleEnd = _project(_V3(lastTitleX, rowY, 1), projection);
    final titleBase = (titleStart + titleEnd) / 2;
    final titlePosition = titleBase + const Offset(0, 42);
    _drawRotatedCenteredText(
      canvas,
      'N+/S ${AppUnits.unitText('(ft)')}',
      titlePosition,
      axisAngle,
      titleStyle,
    );
  }

  void _drawEastWestLabels(Canvas canvas, _Projection projection) {
    final labelStyle = const TextStyle(
      fontSize: 10,
    ).copyWith(color: gridLegendColor);
    final titleStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ).copyWith(color: gridLegendColor);
    final eastWestStepCount = _eastWestStepCount();
    final northSouthGridStepCount = _northSouthGridStepCount();
    final labelX = (_eastWestGridStepCount() + 0.5) / _eastWestGridStepCount();
    final firstValueY = 0.5 / northSouthGridStepCount;
    final lastValueY = (northSouthGridStepCount - 0.5) / northSouthGridStepCount;
    final axisStart = _project(
      _V3(labelX, firstValueY, 1),
      projection,
    );
    final axisEnd = _project(
      _V3(labelX, lastValueY, 1),
      projection,
    );
    final axisAngle = _readableAxisAngle(axisStart, axisEnd);
    final eastWestValueSign = minEastWest >= 0 && maxEastWest > 0 ? 1 : -1;

    for (var i = 0; i <= eastWestStepCount; i++) {
      final value = eastWestValueSign * i * 2000;
      final ratio = eastWestStepCount == 0 ? 0.0 : i / eastWestStepCount;
      final y = firstValueY + ((lastValueY - firstValueY) * ratio);
      final edgePosition = _project(_V3(labelX, y, 1), projection);
      _drawRotatedCenteredText(
        canvas,
        _formatAxisValue(value),
        edgePosition + const Offset(0, 5),
        axisAngle - 0.50,
        labelStyle,
      );
    }

    final firstTitleY = firstValueY;
    final lastTitleY = lastValueY;
    final titleStart = _project(_V3(labelX, firstTitleY, 1), projection);
    final titleEnd = _project(_V3(labelX, lastTitleY, 1), projection);
    final titleBase = (titleStart + titleEnd) / 2;
    final titlePosition = titleBase + const Offset(0, 42);
    _drawRotatedCenteredText(
      canvas,
      'E+/W ${AppUnits.unitText('(ft)')}',
      titlePosition,
      axisAngle,
      titleStyle,
    );
  }

  void _drawTvdLabels(Canvas canvas, _Projection projection) {
    final labelStyle = const TextStyle(
      fontSize: 10,
    ).copyWith(color: gridLegendColor);
    final titleStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ).copyWith(color: gridLegendColor);
    final stepCount = _tvdStepCount();

    for (var i = 0; i <= stepCount; i++) {
      final value = i * 2000;
      final t = value / maxTvd;
      final position = _project(_V3(0, 1, t), projection);
      _drawText(
        canvas,
        _formatAxisValue(value),
        position + const Offset(10, -6),
        labelStyle,
      );
    }

    final titlePosition = _project(const _V3(0, 1, 0.5), projection);
    _drawRotatedCenteredText(
      canvas,
      'TVD ${AppUnits.unitText('(ft)')}',
      titlePosition + const Offset(58, 0),
      -math.pi / 2,
      titleStyle,
    );
  }

  void _draw3DLine(
    Canvas canvas,
    _V3 start,
    _V3 end,
    _Projection projection,
    Paint paint,
  ) {
    canvas.drawLine(
      _project(start, projection),
      _project(end, projection),
      paint,
    );
  }

  List<_V3> _centeredNormalPoints() {
    final normalPoints = points.map(_normalPoint).toList();
    if (normalPoints.isEmpty) return normalPoints;

    var minX = normalPoints.first.x;
    var maxX = normalPoints.first.x;
    var minY = normalPoints.first.y;
    var maxY = normalPoints.first.y;

    for (final point in normalPoints) {
      minX = math.min(minX, point.x);
      maxX = math.max(maxX, point.x);
      minY = math.min(minY, point.y);
      maxY = math.max(maxY, point.y);
    }

    final offsetX = 0.5 - ((minX + maxX) / 2);
    final offsetY = 0.42 - ((minY + maxY) / 2);

    return normalPoints.map((point) {
      return _V3(
        (point.x + offsetX).clamp(0.0, 1.0).toDouble(),
        (point.y + offsetY).clamp(0.0, 1.0).toDouble(),
        point.z,
      );
    }).toList();
  }

  _V3 _normalPoint(SurveyPoint point) {
    return _V3(
      _normalize(point.easting, minEastWest, maxEastWest),
      _normalize(point.northing, minNorthSouth, maxNorthSouth),
      _normalize(point.tvd, 0, maxTvd),
    );
  }

  double _normalize(double value, double min, double max) {
    if ((max - min).abs() < 0.0001) return 0.5;
    return ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
  }

  int _tvdStepCount() {
    return math.max(1, (maxTvd / 2000).round());
  }

  int _tvdGridStepCount() {
    return math.max(_gridDivisions, _tvdStepCount());
  }

  int _northSouthStepCount() {
    return math.max(1, (northSouthAxisMax / 2000).round());
  }

  int _northSouthGridStepCount() {
    return math.max(_gridDivisions, _northSouthStepCount());
  }

  int _eastWestStepCount() {
    return math.max(1, (eastWestAxisMax / 2000).round());
  }

  int _eastWestGridStepCount() {
    return math.max(_gridDivisions, _eastWestStepCount());
  }

  Offset _project(_V3 point, _Projection projection) {
    final yaw = rotationY - 0.75;
    final pitch = rotationX - 0.55;
    final centeredX = point.x - 0.5;
    final centeredY = point.y - 0.5;
    final centeredZ = point.z - 0.5;
    final cosYaw = math.cos(yaw);
    final sinYaw = math.sin(yaw);
    final yawX = (centeredX * cosYaw) - (centeredY * sinYaw);
    final yawY = (centeredX * sinYaw) + (centeredY * cosYaw);
    final cosPitch = math.cos(pitch);
    final sinPitch = math.sin(pitch);
    final pitchedY = (yawY * cosPitch) - (centeredZ * sinPitch);
    final pitchedZ = (yawY * sinPitch) + (centeredZ * cosPitch);

    return projection.origin +
        (projection.x * (yawX + 0.5)) +
        (projection.y * (pitchedY + 0.5)) +
        (projection.z * (pitchedZ + 0.5));
  }

  Offset _outsideFromCenterOffset(Offset edge, Offset center, double distance) {
    final delta = edge - center;
    if (delta.distance < 0.001) return Offset(0, distance);
    return Offset(
      (delta.dx / delta.distance) * distance,
      (delta.dy / delta.distance) * distance,
    );
  }

  Offset _frontOutsideOffset(Offset edge, Offset center, double distance) {
    var offset = _outsideFromCenterOffset(edge, center, distance);
    if (offset.dy < 0) {
      offset = -offset;
    }
    return offset + const Offset(0, 10);
  }

  double _readableAxisAngle(Offset start, Offset end) {
    var angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    if (math.cos(angle) < 0) {
      angle += math.pi;
    }
    if (angle > math.pi) {
      angle -= math.pi * 2;
    }
    return angle;
  }

  String _formatAxisValue(int value) {
    final prefix = value < 0 ? '-' : '';
    final absolute = value.abs();
    if (absolute < 10000) return '$prefix$absolute';
    final text = absolute.toString();
    return '$prefix${text.substring(0, text.length - 3)},${text.substring(text.length - 3)}';
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawRotatedCenteredText(
    Canvas canvas,
    String text,
    Offset offset,
    double angle,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    painter.paint(
      canvas,
      Offset(-(painter.width / 2), -(painter.height / 2)),
    );
    canvas.restore();
  }

  void _drawRotatedText(
    Canvas canvas,
    String text,
    Offset offset,
    double angle,
    TextStyle style,
  ) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle);
    _drawText(canvas, text, Offset.zero, style);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WellPath3DPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.gridLegendColor != gridLegendColor ||
        oldDelegate.cylinderScale != cylinderScale ||
        oldDelegate.minEastWest != minEastWest ||
        oldDelegate.maxEastWest != maxEastWest ||
        oldDelegate.eastWestAxisMax != eastWestAxisMax ||
        oldDelegate.minNorthSouth != minNorthSouth ||
        oldDelegate.maxNorthSouth != maxNorthSouth ||
        oldDelegate.northSouthAxisMax != northSouthAxisMax ||
        oldDelegate.maxTvd != maxTvd;
  }
}

class _Survey3DBounds {
  const _Survey3DBounds({
    required this.minEastWest,
    required this.maxEastWest,
    required this.eastWestAxisMax,
    required this.minNorthSouth,
    required this.maxNorthSouth,
    required this.northSouthAxisMax,
    required this.maxTvd,
  });

  factory _Survey3DBounds.fromPoints(List<SurveyPoint> points) {
    if (points.isEmpty) {
      return const _Survey3DBounds(
        minEastWest: -12000,
        maxEastWest: 0,
        eastWestAxisMax: 12000,
        minNorthSouth: 0,
        maxNorthSouth: 3000,
        northSouthAxisMax: 12000,
        maxTvd: 12000,
      );
    }

    var minEastWest = 0.0;
    var maxEastWest = 0.0;
    var minNorthSouth = 0.0;
    var maxNorthSouth = 0.0;
    var maxTvd = 0.0;

    for (final point in points) {
      minEastWest = math.min(minEastWest, point.easting);
      maxEastWest = math.max(maxEastWest, point.easting);
      minNorthSouth = math.min(minNorthSouth, point.northing);
      maxNorthSouth = math.max(maxNorthSouth, point.northing);
      maxTvd = math.max(maxTvd, point.tvd);
    }

    final northSouthPadding =
        math.max((maxNorthSouth - minNorthSouth).abs() * 0.2, 100.0)
            .toDouble();
    final northSouthAxisMax = _roundedAxisMax(
      math.max(maxNorthSouth.abs(), minNorthSouth.abs()).toDouble(),
    );
    final eastWestAxisMax = _roundedAxisMax(
      math.max(maxEastWest.abs(), minEastWest.abs()).toDouble(),
    );
    final hasEastValues = maxEastWest > 0;
    final hasWestValues = minEastWest < 0;

    return _Survey3DBounds(
      minEastWest: hasEastValues && !hasWestValues ? 0 : -eastWestAxisMax,
      maxEastWest: hasEastValues ? eastWestAxisMax : 0,
      eastWestAxisMax: eastWestAxisMax,
      minNorthSouth:
          minNorthSouth < 0 ? minNorthSouth - northSouthPadding : 0,
      maxNorthSouth: northSouthAxisMax,
      northSouthAxisMax: northSouthAxisMax,
      maxTvd: _roundedAxisMax(maxTvd),
    );
  }

  static double _roundedAxisMax(double value) {
    const axisStep = 2000.0;
    if (value <= 0) return axisStep;
    final paddedValue = value + axisStep;
    return ((paddedValue / axisStep).ceil() * axisStep).toDouble();
  }

  final double minEastWest;
  final double maxEastWest;
  final double eastWestAxisMax;
  final double minNorthSouth;
  final double maxNorthSouth;
  final double northSouthAxisMax;
  final double maxTvd;
}

class _V3 {
  const _V3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class _Projection {
  const _Projection({
    required this.origin,
    required this.x,
    required this.y,
    required this.z,
  });

  final Offset origin;
  final Offset x;
  final Offset y;
  final Offset z;
}
