import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/report/recap_tabs/drilling_data/tabs/engineer/controller/recap_engineer_controller.dart';

const Color _engineerOuterBorder = Color(0xFF2F92E8);
const Color _engineerCanvas = Color(0xFFF4F4F4);
const Color _engineerPanelBorder = Color(0xFFC8C8C8);
const Color _engineerHeaderFill = Color(0xFFF7F7F7);
const Color _engineerText = Color(0xFF1C1C1C);

class RecapEngineerTabView extends StatelessWidget {
  const RecapEngineerTabView({super.key});

  RecapEngineerController get _controller =>
      Get.isRegistered<RecapEngineerController>()
      ? Get.find<RecapEngineerController>()
      : Get.put(RecapEngineerController());

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Container(
      color: _engineerCanvas,
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _engineerOuterBorder, width: 1.4),
        ),
        child: Obx(() => _EngineerContent(controller: controller)),
      ),
    );
  }
}

class _EngineerContent extends StatelessWidget {
  final RecapEngineerController controller;

  const _EngineerContent({required this.controller});

  static const _columns = [
    _EngineerColumn(title: '', width: 42),
    _EngineerColumn(title: 'First Name', width: 200),
    _EngineerColumn(title: 'Last Name', width: 200),
    _EngineerColumn(title: 'Cell', width: 200),
    _EngineerColumn(title: 'Office', width: 200),
    _EngineerColumn(title: 'E-mail', width: 200),
    _EngineerColumn(title: 'Photo', width: 170),
    _EngineerColumn(title: 'Days', width: 110),
    _EngineerColumn(title: '%', width: 110),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = controller.rows.toList(growable: false);
    final baseTableWidth = _columns.fold<double>(
      0,
      (sum, column) => sum + column.width,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Text(
            'Engineer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: _engineerText,
            ),
          ),
        ),
        if (controller.isLoading.value)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (controller.errorMessage.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Text(
              controller.errorMessage.value,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8B2E2E)),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _engineerPanelBorder),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = math.max(
                    baseTableWidth,
                    constraints.maxWidth,
                  );
                  final scale = baseTableWidth <= 0
                      ? 1.0
                      : tableWidth / baseTableWidth;
                  final columns = _columns
                      .map(
                        (column) => _EngineerColumn(
                          title: column.title,
                          width: column.width * scale,
                        ),
                      )
                      .toList(growable: false);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: _EngineerHeader(columns: columns),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: tableWidth,
                                  height: constraints.maxHeight,
                                  child: rows.isEmpty
                                      ? const SizedBox()
                                      : ListView.builder(
                                          itemCount: rows.length,
                                          itemBuilder: (context, index) {
                                            return _EngineerDataRow(
                                              index: index,
                                              row: rows[index],
                                              columns: columns,
                                            );
                                          },
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EngineerHeader extends StatelessWidget {
  final List<_EngineerColumn> columns;

  const _EngineerHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: columns
            .map(
              (column) => Container(
                width: column.width,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _engineerHeaderFill,
                  border: Border.all(color: _engineerPanelBorder),
                ),
                child: Text(
                  column.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _engineerText,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _EngineerDataRow extends StatelessWidget {
  final int index;
  final RecapEngineerRow row;
  final List<_EngineerColumn> columns;

  const _EngineerDataRow({
    required this.index,
    required this.row,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          _cell('${index + 1}', columns[0].width, Alignment.center),
          _cell(row.firstName, columns[1].width, Alignment.centerLeft),
          _cell(row.lastName, columns[2].width, Alignment.centerLeft),
          _cell(row.cell, columns[3].width, Alignment.centerLeft),
          _cell(row.office, columns[4].width, Alignment.centerLeft),
          _cell(row.email, columns[5].width, Alignment.centerLeft),
          _photoCell(row.photo, columns[6].width),
          _cell('${row.days}', columns[7].width, Alignment.centerRight),
          _cell(
            row.percentage.toStringAsFixed(1),
            columns[8].width,
            Alignment.centerRight,
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, double width, Alignment alignment) {
    return Container(
      width: width,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _engineerPanelBorder),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: _engineerText),
      ),
    );
  }

  Widget _photoCell(String photo, double width) {
    final memory = _tryDecodePhoto(photo);

    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _engineerPanelBorder),
      ),
      child: memory == null
          ? const SizedBox.shrink()
          : Container(
              width: 28,
              height: 28,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _engineerPanelBorder),
              ),
              child: Image.memory(memory, fit: BoxFit.cover),
            ),
    );
  }

  Uint8List? _tryDecodePhoto(String value) {
    final source = value.trim();
    if (source.isEmpty) return null;

    final normalized = source.contains(',')
        ? source.substring(source.indexOf(',') + 1)
        : source;
    try {
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }
}

class _EngineerColumn {
  final String title;
  final double width;

  const _EngineerColumn({required this.title, required this.width});
}
