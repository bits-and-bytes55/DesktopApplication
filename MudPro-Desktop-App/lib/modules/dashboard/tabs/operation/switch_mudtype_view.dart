import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/switch_mudtype_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class SwitchMudTypeView extends StatefulWidget {
  const SwitchMudTypeView({super.key, required this.instanceKey});

  final String instanceKey;

  @override
  State<SwitchMudTypeView> createState() => _SwitchMudTypeViewState();
}

class _SwitchMudTypeViewState extends State<SwitchMudTypeView> {
  late final SwitchMudTypeController controller;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  static const Color _gridColor = Color(0xFFE2E2E2);
  static const double _sectionWidth = 960;
  static const double _tableWidth = 440;
  static const double _singleTableWidth = 920;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SwitchMudTypeController>(
      tag: widget.instanceKey,
    )
        ? Get.find<SwitchMudTypeController>(tag: widget.instanceKey)
        : Get.put(SwitchMudTypeController(), tag: widget.instanceKey);
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Scrollbar(
        controller: _verticalScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.vertical,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1000,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _twoTableSection(
                        title: '1. Remove Mud from Active Pits',
                        selected: controller.section1Selected,
                        leftLabel: 'Transfer',
                        rightLabel: 'Make Storage',
                        leftList: controller.section1Left,
                        rightList: controller.section1Right,
                      ),
                      const SizedBox(height: 20),
                      _twoTableSection(
                        title: '2. Fill Active Pits',
                        selected: controller.section2Selected,
                        leftLabel: 'Transfer',
                        rightLabel: 'Make Storage',
                        leftList: controller.section2Left,
                        rightList: controller.section2Right,
                      ),
                      const SizedBox(height: 20),
                      _singleTableSection(
                        title: '3. Displace Fluid in Hole to Storage',
                        list: controller.section3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _twoTableSection({
    required String title,
    required RxInt selected,
    required String leftLabel,
    required String rightLabel,
    required RxList<String?> leftList,
    required RxList<String?> rightList,
  }) {
    return _sectionShell(
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(title),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _radioTable(
                  label: leftLabel,
                  active: selected.value == 0,
                  onTap: () => selected.value = 0,
                  list: leftList,
                  enabled: selected.value == 0,
                ),
                const SizedBox(width: 28),
                _radioTable(
                  label: rightLabel,
                  active: selected.value == 1,
                  onTap: () => selected.value = 1,
                  list: rightList,
                  enabled: selected.value == 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _singleTableSection({
    required String title,
    required RxList<String?> list,
  }) {
    return _sectionShell(
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(title),
            const SizedBox(height: 14),
            _dataTable(list: list, enabled: true, width: _singleTableWidth),
          ],
        ),
      ),
    );
  }

  Widget _sectionShell({required Widget child}) {
    return Container(
      width: _sectionWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gridColor),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _selectionDot(bool active) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? AppTheme.primaryColor : Colors.grey.shade500,
        ),
      ),
      child: active
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
              ),
            )
          : null,
    );
  }

  Widget _radioTable({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required RxList<String?> list,
    required bool enabled,
  }) {
    return SizedBox(
      width: _tableWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primaryColor.withOpacity(0.12)
                    : Colors.white,
                border: Border.all(
                  color: active ? AppTheme.primaryColor : _gridColor,
                ),
              ),
              child: Row(
                children: [
                  _selectionDot(active),
                  const SizedBox(width: 10),
                  Text(label, style: _inputTextStyle),
                ],
              ),
            ),
          ),
          _dataTable(list: list, enabled: enabled, width: _tableWidth),
        ],
      ),
    );
  }

  Widget _dataTable({
    required RxList<String?> list,
    required bool enabled,
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: _gridColor),
      ),
      child: Column(
        children: [
          _tableHeader(width),
          ...List.generate(
            list.length,
            (index) => _tableRow(
              list: list,
              index: index,
              enabled: enabled,
              width: width,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(double width) {
    return Container(
      height: 42,
      color: AppTheme.primaryColor,
      child: Row(
        children: [
          _cell(
            width: width - 120,
            child: const Text('Pit', style: _headerTextStyle),
          ),
          _cell(
            width: 120,
            child: Text(
              AppUnits.label('Volume (bbl)'),
              textAlign: TextAlign.right,
              style: _headerTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableRow({
    required RxList<String?> list,
    required int index,
    required bool enabled,
    required double width,
  }) {
    final selectedValue =
        controller.pitList.contains(list[index]) ? list[index] : null;
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _gridColor)),
      ),
      child: Row(
        children: [
          _cell(
            width: width - 120,
            child: enabled
                ? DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue,
                      isExpanded: true,
                      hint: const Text('Select pit', style: _inputTextStyle),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      items: controller.pitList
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: _inputTextStyle),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        list[index] = value;
                      },
                    ),
                  )
                : Text(
                    selectedValue ?? 'Select pit',
                    style: _inputTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          _cell(
            width: 120,
            child: enabled
                ? TextFormField(
                    key: ValueKey(
                      'switch-mud-volume-${widget.instanceKey}-$index',
                    ),
                    initialValue: '',
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '0.00',
                    ),
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    style: _inputTextStyle,
                  )
                : const Text(
                    '0.00',
                    textAlign: TextAlign.right,
                    style: _inputTextStyle,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _cell({required double width, required Widget child}) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _gridColor)),
      ),
      child: child,
    );
  }
}

const TextStyle _headerTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

const TextStyle _inputTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);
