import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/sce/controller/recap_sce_controller.dart';

const Color _sceOuterBorder = Color(0xFFB8D0EA);
const Color _sceCanvas = Color(0xFFF4F6FA);
const Color _scePanelBorder = Color(0xFFB8D0EA);
const Color _sceHeaderFill = Color(0xFFEAF3FC);
const Color _sceText = Color(0xFF1C1C1C);
const Color _sceTabFill = Color(0xFFEAF3FC);
const Color _sceShakerChip = Color(0xFFDFEDF9);
const Color _sceOtherChip = Color(0xFFE8F0DD);

class RecapSceTabView extends StatefulWidget {
  const RecapSceTabView({super.key});

  @override
  State<RecapSceTabView> createState() => _RecapSceTabViewState();
}

class _RecapSceTabViewState extends State<RecapSceTabView> {
  int _selectedTab = 0;

  RecapSceController get _controller =>
      Get.isRegistered<RecapSceController>()
      ? Get.find<RecapSceController>()
      : Get.put(RecapSceController());

  static const _tabs = [
    _SceTabMeta(title: 'Graph'),
    _SceTabMeta(title: 'Table'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _sceCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _sceOuterBorder, width: 1.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: Obx(() => _buildContent(controller))),
            _buildVerticalTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RecapSceController controller) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _SceMessageState(
        title: 'Solid Control Equipment',
        message: controller.errorMessage.value,
      );
    }

    final hasData = controller.shakers.any((item) => item.hasData) ||
        controller.otherSce.any((item) => item.hasData);

    if (!hasData && controller.emptyMessage.value.isNotEmpty) {
      return _SceMessageState(
        title: 'Solid Control Equipment',
        message: controller.emptyMessage.value,
      );
    }

    switch (_selectedTab) {
      case 0:
        return _SceGraphTab(controller: controller);
      case 1:
        return _SceTableTab(controller: controller);
      default:
        return _SceGraphTab(controller: controller);
    }
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 32,
      decoration: const BoxDecoration(
        color: _sceCanvas,
        border: Border(left: BorderSide(color: _scePanelBorder)),
      ),
      child: Column(
        children: List.generate(_tabs.length, (index) {
          final selected = index == _selectedTab;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? Colors.white : _sceTabFill,
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: _scePanelBorder),
                    left: BorderSide(
                      color: selected ? _sceOuterBorder : _scePanelBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    right: const BorderSide(color: _scePanelBorder),
                    bottom: index == _tabs.length - 1
                        ? const BorderSide(color: _scePanelBorder)
                        : BorderSide.none,
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      _tabs[index].title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _sceText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SceGraphTab extends StatelessWidget {
  final RecapSceController controller;

  const _SceGraphTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final plottedItems = controller.plottedItems.toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _scePanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 8),
              child: Text(
                'Solid Control Equipment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _sceText,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _scePanelBorder),
                  ),
                  child: plottedItems.isEmpty
                      ? const SizedBox.expand()
                      : Padding(
                          padding: const EdgeInsets.all(14),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: plottedItems.map((item) {
                              return Container(
                                constraints: const BoxConstraints(
                                  minWidth: 180,
                                  maxWidth: 260,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: item.isOtherSce
                                      ? _sceOtherChip
                                      : _sceShakerChip,
                                  border: Border.all(color: _scePanelBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: _sceText,
                                      ),
                                    ),
                                    if (item.subtitle.trim().isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        item.subtitle,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: _sceText,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(growable: false),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceTableTab extends StatelessWidget {
  final RecapSceController controller;

  const _SceTableTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ScePanel(
              title: 'Shaker Equipment',
              child: _SceShakerTable(
                rows: controller.shakers.toList(growable: false),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ScePanel(
              title: 'Other SCE Equipment',
              child: _SceOtherTable(
                rows: controller.otherSce.toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScePanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _ScePanel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _scePanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _sceHeaderFill,
              border: Border(bottom: BorderSide(color: _scePanelBorder)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _sceText,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SceShakerTable extends StatelessWidget {
  final List<RecapSceShakerRow> rows;

  const _SceShakerTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 30,
          color: _sceHeaderFill,
          child: const Row(
            children: [
              _SceHeaderCell('Shaker', flex: 22),
              _SceHeaderCell('Model', flex: 30),
              _SceHeaderCell('Screen', flex: 16),
              _SceHeaderCell('Time', flex: 16),
              _SceHeaderCell('Plot', flex: 12),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return Container(
                height: 30,
                color: index.isOdd ? const Color(0xFFF9F9F9) : Colors.white,
                child: Row(
                  children: [
                    _SceDataCell(row.label, flex: 22, strong: true),
                    _SceDataCell(row.model, flex: 30),
                    _SceDataCell(row.screens, flex: 16),
                    _SceDataCell(row.time, flex: 16),
                    _ScePlotCell(value: row.plot, flex: 12),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SceOtherTable extends StatelessWidget {
  final List<RecapSceOtherRow> rows;

  const _SceOtherTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 30,
          color: _sceHeaderFill,
          child: const Row(
            children: [
              _SceHeaderCell('SCE', flex: 18),
              _SceHeaderCell('Model 1', flex: 18),
              _SceHeaderCell('Model 2', flex: 18),
              _SceHeaderCell('Model 3', flex: 18),
              _SceHeaderCell('UF', flex: 10),
              _SceHeaderCell('OF', flex: 10),
              _SceHeaderCell('Time', flex: 12),
              _SceHeaderCell('Plot', flex: 10),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return Container(
                height: 30,
                color: index.isOdd ? const Color(0xFFF9F9F9) : Colors.white,
                child: Row(
                  children: [
                    _SceDataCell(row.label, flex: 18, strong: true),
                    _SceDataCell(row.model1, flex: 18),
                    _SceDataCell(row.model2, flex: 18),
                    _SceDataCell(row.model3, flex: 18),
                    _SceDataCell(row.uf, flex: 10),
                    _SceDataCell(row.of, flex: 10),
                    _SceDataCell(row.time, flex: 12),
                    _ScePlotCell(value: row.plot, flex: 10),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SceHeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _SceHeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: _scePanelBorder),
            bottom: BorderSide(color: _scePanelBorder),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: _sceText,
          ),
        ),
      ),
    );
  }
}

class _SceDataCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool strong;

  const _SceDataCell(
    this.text, {
    required this.flex,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: _scePanelBorder),
            bottom: BorderSide(color: _scePanelBorder),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text.trim().isEmpty ? '-' : text.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            color: text.trim().isEmpty ? const Color(0xFF8C8C8C) : _sceText,
          ),
        ),
      ),
    );
  }
}

class _ScePlotCell extends StatelessWidget {
  final bool value;
  final int flex;

  const _ScePlotCell({
    required this.value,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: _scePanelBorder),
            bottom: BorderSide(color: _scePanelBorder),
          ),
        ),
        child: Icon(
          value ? Icons.check_box : Icons.check_box_outline_blank,
          size: 15,
          color: value ? const Color(0xFF1F77C8) : const Color(0xFF9A9A9A),
        ),
      ),
    );
  }
}

class _SceMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _SceMessageState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _scePanelBorder),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _sceText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _sceText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceTabMeta {
  final String title;

  const _SceTabMeta({required this.title});
}
