import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/tabs/operation/operation_ui_pattern.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/ug_ui_pattern.dart';

class PitView extends StatefulWidget {
  const PitView({super.key});

  @override
  State<PitView> createState() => _PitViewState();
}

class _PitViewState extends State<PitView> {
  static const double _indexWidth = 60;
  static const double _pitWidth = 180;
  static const double _capacityWidth = 150;
  static const double _activeWidth = 150;
  static const double _rowHeight = 29;
  static const Color _gridBorder = ugGrid;
  static const Color _headerColor = ugColumnHeader;
  static const Color _inputColor = ugLockedEditable;

  final PitController controller = Get.isRegistered<PitController>()
      ? Get.find<PitController>()
      : Get.put(PitController());
  final UgController ugController = Get.find<UgController>();
  final ScrollController _bodyScrollController = ScrollController();

  @override
  void dispose() {
    _bodyScrollController.dispose();
    super.dispose();
  }

  bool _hasAnyContent(PitModel pit) {
    return pit.pitName.trim().isNotEmpty ||
        pit.capacity.value > 0 ||
        pit.initialActive.value;
  }

  Future<void> _showRowMenu(
    TapDownDetails details,
    PitModel pit,
    int index,
  ) async {
    final isLocked = ugController.isLocked.value || pit.isLocked;
    if (isLocked) return;

    final canAdd = pit.id == null && controller.isRowFilled(pit);
    final canDelete = pit.id != null || _hasAnyContent(pit);

    if (!canAdd && !canDelete) return;

    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        if (canAdd)
          const PopupMenuItem<String>(
            value: 'add',
            child: Text('Add', style: TextStyle(fontSize: 11)),
          ),
        if (canDelete)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('Delete', style: TextStyle(fontSize: 11)),
          ),
      ],
    );

    if (!mounted || action == null) return;
    if (action == 'add') {
      await controller.saveDraftPit(pit);
      return;
    }
    if (pit.id != null) {
      await controller.deletePit(pit);
    } else {
      controller.removeDraftPit(pit);
    }
  }

  void _onPitNameChanged(PitModel pit, int index, String value) {
    pit.pitName = value;
    if (pit.id != null) {
      controller.schedulePitConfigSave(pit);
      return;
    }
    controller.onRowFilled(index);
    controller.schedulePitAutoSave();
  }

  void _onCapacityChanged(PitModel pit, int index, String value) {
    pit.capacity.value = double.tryParse(value.trim()) ?? 0.0;
    if (pit.id != null) {
      controller.schedulePitConfigSave(pit);
      return;
    }
    controller.onRowFilled(index);
    controller.schedulePitAutoSave();
  }

  void _onInitialActiveChanged(PitModel pit, int index, bool? value) {
    pit.initialActive.value = value ?? false;
    controller.pits.refresh();
    if (pit.id != null) {
      controller.schedulePitConfigSave(pit);
      return;
    }
    controller.onRowFilled(index);
    controller.schedulePitAutoSave();
  }

  String _capacityText(PitModel pit) {
    if (pit.capacity.value <= 0) return '';
    return formatOperationNumber(
      pit.capacity.value,
      fallbackDecimals: 2,
      trimFallback: true,
    );
  }

  Widget _headerCell(
    String text,
    double width, {
    TextAlign textAlign = TextAlign.left,
  }) {
    return Container(
      width: width,
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: _headerColor,
        border: Border(
          right: BorderSide(color: _gridBorder),
          bottom: BorderSide(color: _gridBorder),
        ),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _frameCell({
    required double width,
    required Widget child,
    Alignment alignment = Alignment.centerLeft,
    Color? color,
  }) {
    return Container(
      width: width,
      height: _rowHeight,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: const Border(
          right: BorderSide(color: _gridBorder),
          bottom: BorderSide(color: _gridBorder),
        ),
      ),
      child: child,
    );
  }

  Widget _rowNumberCell(PitModel pit, int index) {
    final hasContent = _hasAnyContent(pit);
    return _frameCell(
      width: _indexWidth,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: Text(
              hasContent ? '▸' : '',
              style: const TextStyle(fontSize: 9, color: Color(0xFF5B6470)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text('${index + 1}', style: AppTheme.wellLikeBodyText),
          ),
        ],
      ),
    );
  }

  Widget _pitNameCell(PitModel pit, int index) {
    final isLocked = ugController.isLocked.value || pit.isLocked;
    return _frameCell(
      width: _pitWidth,
      color: isLocked ? _inputColor : Colors.white,
      child: TextFormField(
        key: ValueKey('pit-name-${pit.id ?? 'draft-$index'}'),
        initialValue: pit.pitName,
        readOnly: isLocked,
        style: AppTheme.wellLikeBodyText,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        ),
        onChanged: (value) => _onPitNameChanged(pit, index, value),
      ),
    );
  }

  Widget _capacityCell(PitModel pit, int index) {
    final isLocked = ugController.isLocked.value || pit.isLocked;
    return _frameCell(
      width: _capacityWidth,
      color: isLocked ? _inputColor : Colors.white,
      alignment: Alignment.centerLeft,
      child: TextFormField(
        key: ValueKey('pit-capacity-${pit.id ?? 'draft-$index'}'),
        initialValue: _capacityText(pit),
        readOnly: isLocked,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
        ],
        textAlign: TextAlign.left,
        style: AppTheme.wellLikeBodyText,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        ),
        onChanged: (value) => _onCapacityChanged(pit, index, value),
      ),
    );
  }

  Widget _activeCell(PitModel pit, int index) {
    final isLocked = ugController.isLocked.value || pit.isLocked;
    return _frameCell(
      width: _activeWidth,
      alignment: Alignment.center,
      child: Checkbox(
        value: pit.initialActive.value,
        onChanged: isLocked
            ? null
            : (value) => _onInitialActiveChanged(pit, index, value),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        side: const BorderSide(color: Color(0xFF9EA4AD)),
      ),
    );
  }

  Widget _buildRow(PitModel pit, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => _showRowMenu(details, pit, index),
      child: Row(
        children: [
          _rowNumberCell(pit, index),
          _pitNameCell(pit, index),
          _capacityCell(pit, index),
          _activeCell(pit, index),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      width: _indexWidth + _pitWidth + _capacityWidth + _activeWidth + 2,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _gridBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerCell('', _indexWidth),
              _headerCell('Pit', _pitWidth),
              _headerCell('Capacity\n(bbl)', _capacityWidth),
              _headerCell('Initial Active', _activeWidth),
            ],
          ),
          Expanded(
            child: Obx(
              () => Scrollbar(
                controller: _bodyScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: ListView.builder(
                  controller: _bodyScrollController,
                  itemCount: controller.pits.length,
                  itemBuilder: (context, index) {
                    return _buildRow(controller.pits[index], index);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ugPageBackground,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _indexWidth + _pitWidth + _capacityWidth + _activeWidth + 2,
            child: _buildTable(),
          ),
        ],
      ),
    );
  }
}
