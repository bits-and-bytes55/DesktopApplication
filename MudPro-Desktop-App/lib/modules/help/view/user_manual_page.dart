import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class UserManualPage extends StatefulWidget {
  const UserManualPage({super.key});

  static const _contents = <_ManualNode>[
    _ManualNode(
      'MSR2_DMR',
      children: [
        _ManualNode(
          'Introduction',
          children: [
            _ManualNode('Background'),
            _ManualNode('Engineering Features'),
            _ManualNode('Copyright and Disclaimer'),
            _ManualNode('Technical Support'),
          ],
        ),
        _ManualNode(
          'MSR2_DMR Structure',
          children: [
            _ManualNode('Main Structure'),
            _ManualNode('Pad (Well)/Report Management'),
          ],
        ),
        _ManualNode(
          'Getting Started',
          children: [
            _ManualNode('Hardware and System Requirements'),
            _ManualNode('Installing the Software'),
            _ManualNode('Licensing the Software'),
            _ManualNode('Quick Tour'),
          ],
        ),
        _ManualNode(
          'Input Windows',
          children: [
            _ManualNode(
              'Menu/Toolbar',
              children: [
                _ManualNode('Home'),
                _ManualNode('Report', topic: 'Toolbar Report'),
                _ManualNode('Utility & Help'),
              ],
            ),
            _ManualNode(
              'Pad',
              children: [
                _ManualNode('Pad', topic: 'Pad Detail'),
                _ManualNode('Inventory'),
                _ManualNode('Pit'),
                _ManualNode('Pump'),
                _ManualNode('SCE'),
                _ManualNode('Formation'),
                _ManualNode('Report', topic: 'Pad Report'),
              ],
            ),
            _ManualNode(
              'Well',
              children: [
                _ManualNode('Well', topic: 'Well Detail'),
                _ManualNode('Casing'),
                _ManualNode('Interval'),
                _ManualNode('Plan'),
                _ManualNode('Survey'),
              ],
            ),
            _ManualNode(
              'Report',
              topic: 'Input Report',
              children: [
                _ManualNode('Well', topic: 'Report Well'),
                _ManualNode('Mud', topic: 'Report Mud'),
                _ManualNode('Pump', topic: 'Report Pump'),
                _ManualNode(
                  'Operation',
                  topic: 'Report Operation',
                  children: [
                    _ManualNode('Consume Product'),
                    _ManualNode('Consume Services'),
                    _ManualNode('Receive Product'),
                    _ManualNode('Return Product'),
                    _ManualNode('Transfer Mud'),
                    _ManualNode('Receive Mud'),
                    _ManualNode('Return/Lost Mud'),
                    _ManualNode('Add Water'),
                    _ManualNode('Switch Pits'),
                    _ManualNode('Switch Mud Type'),
                    _ManualNode('Other Volume Addition-Active System'),
                    _ManualNode('Mud Loss-Active System'),
                    _ManualNode('Mud Loss-Reserve Pits'),
                  ],
                ),
                _ManualNode(
                  'Snapshots',
                  topic: 'Report Snapshots',
                  children: [
                    _ManualNode('Inventory Snapshot'),
                    _ManualNode('Volume Snapshot'),
                    _ManualNode('Mud Treated'),
                  ],
                ),
                _ManualNode(
                  'Pits',
                  topic: 'Report Pits',
                  children: [
                    _ManualNode('Active Pits'),
                    _ManualNode('Reserve Pits'),
                  ],
                ),
                _ManualNode('Remarks', topic: 'Report Remarks'),
              ],
            ),
          ],
        ),
        _ManualNode(
          'Output Windows',
          children: [
            _ManualNode(
              'Toolbar',
              topic: 'Output Toolbar',
              children: [
                _ManualNode('Home', topic: 'Output Home'),
                _ManualNode('Report'),
                _ManualNode('Options', topic: 'Output Options'),
                _ManualNode('Utility & Help'),
              ],
            ),
            _ManualNode(
              'Output Job Explorer',
              topic: 'Output Job Explorer',
              children: [
                _ManualNode('Summary', topic: 'Output Summary'),
                _ManualNode('Detail', topic: 'Output Detail'),
                _ManualNode('Daily Cost', topic: 'Output Daily Cost'),
                _ManualNode('Total Cost', topic: 'Output Total Cost'),
                _ManualNode('Concentration', topic: 'Output Concentration'),
                _ManualNode(
                  'Time Distribution',
                  topic: 'Output Time Distribution',
                ),
                _ManualNode('Survey', topic: 'Output Survey'),
              ],
            ),
          ],
        ),
        _ManualNode(
          'Recap Windows',
          children: [
            _ManualNode(
              'Toolbar',
              topic: 'Recap Toolbar',
              children: [
                _ManualNode('Home & Report', topic: 'Recap Home & Report'),
                _ManualNode('Options', topic: 'Recap Options'),
              ],
            ),
            _ManualNode(
              'Recap Job Explorer',
              topic: 'Recap Job Explorer',
              children: [
                _ManualNode('Summary', topic: 'Recap Summary'),
                _ManualNode(
                  'Cost Distribution',
                  topic: 'Recap Cost Distribution',
                ),
                _ManualNode('Daily Cost', topic: 'Recap Daily Cost'),
                _ManualNode('Depth Cost', topic: 'Recap Depth Cost'),
                _ManualNode('Cumulative Cost', topic: 'Recap Cumulative Cost'),
                _ManualNode('Drilling Data', topic: 'Recap Drilling Data'),
                _ManualNode('Mud Properties', topic: 'Recap Mud Properties'),
                _ManualNode('Hydraulics', topic: 'Recap Hydraulics'),
                _ManualNode('Solid Analysis', topic: 'Recap Solid Analysis'),
                _ManualNode('Volume', topic: 'Recap Volume'),
                _ManualNode('Usage', topic: 'Recap Usage'),
                _ManualNode('Concentration', topic: 'Recap Concentration'),
                _ManualNode(
                  'Time Distribution',
                  topic: 'Recap Time Distribution',
                ),
                _ManualNode(
                  'Solid Control Equipment',
                  topic: 'Recap Solid Control Equipment',
                ),
                _ManualNode('Bit', topic: 'Recap Bit'),
                _ManualNode('Remarks', topic: 'Recap Remarks'),
                _ManualNode('Interval', topic: 'Recap Interval'),
                _ManualNode('Survey', topic: 'Recap Survey'),
                _ManualNode('Customized', topic: 'Recap Customized'),
                _ManualNode('Engineer', topic: 'Recap Engineer'),
              ],
            ),
          ],
        ),
        _ManualNode(
          'Well Comparison Windows',
          topic: 'Well Comparison Windows',
          children: [
            _ManualNode('Toolbar', topic: 'Comparison Toolbar'),
            _ManualNode(
              'Comparison Job Explorer',
              topic: 'Comparison Job Explorer',
              children: [
                _ManualNode('Summary', topic: 'Comparison Summary'),
                _ManualNode('Cost', topic: 'Comparison Cost'),
                _ManualNode('Drilling Data', topic: 'Comparison Drilling Data'),
                _ManualNode('Mud Properties', topic: 'Comparison Mud Properties'),
                _ManualNode('Hydraulics', topic: 'Comparison Hydraulics'),
                _ManualNode('Solids', topic: 'Comparison Solids'),
                _ManualNode('Volume', topic: 'Comparison Volume'),
                _ManualNode(
                  'Time Distribution',
                  topic: 'Comparison Time Distribution',
                ),
                _ManualNode('Bit', topic: 'Comparison Bit'),
                _ManualNode('Remarks', topic: 'Comparison Remarks'),
                _ManualNode('Survey', topic: 'Comparison Survey'),
                _ManualNode('Engineer', topic: 'Comparison Engineer'),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  State<UserManualPage> createState() => _UserManualPageState();
}

class _UserManualPageState extends State<UserManualPage> {
  final _contentScrollController = ScrollController();
  final _printBoundaryKey = GlobalKey();
  var _sidebarVisible = true;
  var _searchHighlightOn = true;
  var _refreshKey = 0;
  String? _selectedManualTopic;

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  void _goHome() {
    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
    }
    setState(() {
      _sidebarVisible = true;
      _refreshKey++;
      _selectedManualTopic = null;
    });
  }

  void _refresh() {
    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
    }
    setState(() {
      _refreshKey++;
      _selectedManualTopic = null;
    });
  }

  void _selectManualTopic(String topic) {
    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
    }
    setState(() => _selectedManualTopic = topic.isEmpty ? null : topic);
  }

  String get _currentManualTopicLabel {
    final topic = _selectedManualTopic;
    if (topic == null) return 'MSR2_DMR';
    return _findManualNode(UserManualPage._contents, topic)?.title ?? topic;
  }

  void _toggleSidebar() {
    setState(() => _sidebarVisible = !_sidebarVisible);
  }

  void _toggleSearchHighlight() {
    setState(() => _searchHighlightOn = !_searchHighlightOn);
  }

  void _goForward() {
    if (!_contentScrollController.hasClients) return;
    _contentScrollController.jumpTo(
      _contentScrollController.position.maxScrollExtent,
    );
  }

  Future<void> _openInternetOptions() async {
    try {
      await Process.start('rundll32.exe', const [
        'shell32.dll,Control_RunDLL',
        'inetcpl.cpl',
      ]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Internet Options could not be opened.')),
      );
    }
  }

  Future<void> _showPrintTopicsDialog() async {
    final selection = await showDialog<_PrintTopicSelection>(
      context: context,
      builder: (context) => const _PrintTopicsDialog(),
    );
    if (selection == null || !mounted) return;
    await _printManualTopics(selection);
  }

  Future<void> _printManualTopics(_PrintTopicSelection selection) async {
    final selectedTopic = _selectedManualTopic;
    final selectedNode = selectedTopic == null
        ? null
        : _findManualNode(UserManualPage._contents, selectedTopic);
    final nodes = <_ManualNode>[];

    if (selection == _PrintTopicSelection.headingAndSubtopics) {
      if (selectedNode == null) {
        for (final node in UserManualPage._contents) {
          _collectManualNodes(node, nodes);
        }
      } else {
        _collectManualNodes(selectedNode, nodes);
      }
    } else if (selectedNode != null) {
      nodes.add(selectedNode);
    }

    final topics = nodes
        .where((node) => _ManualTopicPage.supports(node.topic))
        .toList();
    if (topics.isEmpty && selectedTopic != null) {
      topics.add(_ManualNode(selectedTopic, topic: selectedTopic));
    }

    try {
      final originalTopic = _selectedManualTopic;
      final screenshots = <Uint8List>[];
      if (topics.isEmpty && selectedTopic == null) {
        screenshots.addAll(await _captureManualTopic(null));
      } else {
        for (final node in topics) {
          screenshots.addAll(await _captureManualTopic(node.topic));
        }
      }
      if (mounted) {
        setState(() => _selectedManualTopic = originalTopic);
        await WidgetsBinding.instance.endOfFrame;
      }

      final pdfBytes = await _buildScreenshotPdf(
        screenshots,
        PdfPageFormat.a4,
      );
      try {
        await Printing.layoutPdf(
          name: 'MSR2_DMR_User_Manual.pdf',
          format: PdfPageFormat.a4,
          dynamicLayout: false,
          onLayout: (_) async => pdfBytes,
        );
      } on MissingPluginException {
        await _openPrintablePdf(pdfBytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF opened in the default viewer. Restart the rebuilt app to use the native print dialog directly.',
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('User manual PDF print failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF print failed: $error')),
      );
    }
  }

  Future<List<Uint8List>> _captureManualTopic(String? topic) async {
    if (!mounted) return const [];
    setState(() => _selectedManualTopic = topic);
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
      await WidgetsBinding.instance.endOfFrame;
    }

    final captures = <Uint8List>[];
    final positions = <double>[0];
    if (_contentScrollController.hasClients) {
      final position = _contentScrollController.position;
      final maxExtent = position.maxScrollExtent;
      final step = math.max(1.0, position.viewportDimension - 24);
      var offset = step;
      while (offset < maxExtent) {
        positions.add(offset);
        offset += step;
      }
      if (maxExtent > 0 && positions.last != maxExtent) {
        positions.add(maxExtent);
      }
    }

    for (final offset in positions) {
      if (_contentScrollController.hasClients) {
        _contentScrollController.jumpTo(
          offset
              .clamp(0, _contentScrollController.position.maxScrollExtent)
              .toDouble(),
        );
        await WidgetsBinding.instance.endOfFrame;
      }
      final boundary = _printBoundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) continue;
      final image = await boundary.toImage(pixelRatio: 1.25);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes != null) {
        captures.add(bytes.buffer.asUint8List());
      }
    }
    return captures;
  }

  Future<Uint8List> _buildScreenshotPdf(
    List<Uint8List> screenshots,
    PdfPageFormat pageFormat,
  ) async {
    if (screenshots.isEmpty) {
      throw StateError('No manual content was available to print.');
    }
    final document = pw.Document(title: 'MSR2_DMR User Manual');
    for (final screenshot in screenshots) {
      final image = pw.MemoryImage(screenshot);
      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(18),
          build: (_) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return document.save();
  }

  _ManualNode? _findManualNode(List<_ManualNode> nodes, String topic) {
    for (final node in nodes) {
      if (node.topic == topic) return node;
      final child = _findManualNode(node.children, topic);
      if (child != null) return child;
    }
    return null;
  }

  void _collectManualNodes(_ManualNode node, List<_ManualNode> result) {
    result.add(node);
    for (final child in node.children) {
      _collectManualNodes(child, result);
    }
  }

  void _collectPrintableText(Widget widget, List<String> lines) {
    if (widget is Text) {
      final value = widget.data ?? widget.textSpan?.toPlainText() ?? '';
      final text = value.trim();
      if (text.isNotEmpty && (lines.isEmpty || lines.last != text)) {
        lines.add(text);
      }
      return;
    }
    if (widget is RichText) {
      final text = widget.text.toPlainText().trim();
      if (text.isNotEmpty && (lines.isEmpty || lines.last != text)) {
        lines.add(text);
      }
      return;
    }
    if (widget is Flex) {
      for (final child in widget.children) {
        _collectPrintableText(child, lines);
      }
      return;
    }
    if (widget is Wrap) {
      for (final child in widget.children) {
        _collectPrintableText(child, lines);
      }
      return;
    }
    if (widget is Stack) {
      for (final child in widget.children) {
        _collectPrintableText(child, lines);
      }
      return;
    }
    if (widget is Container && widget.child != null) {
      _collectPrintableText(widget.child!, lines);
      return;
    }
    if (widget is SingleChildScrollView && widget.child != null) {
      _collectPrintableText(widget.child!, lines);
      return;
    }
    if (widget is InkWell && widget.child != null) {
      _collectPrintableText(widget.child!, lines);
      return;
    }
    if (widget is Tooltip && widget.child != null) {
      _collectPrintableText(widget.child!, lines);
      return;
    }
    if (widget is SingleChildRenderObjectWidget && widget.child != null) {
      _collectPrintableText(widget.child!, lines);
      return;
    }
    if (widget is ProxyWidget && widget.child != null) {
      _collectPrintableText(widget.child!, lines);
    }
  }

  Future<Uint8List> _buildPrintablePdf(
    List<({String title, String breadcrumb, List<String> lines})> sections,
    PdfPageFormat pageFormat,
  ) async {
    final document = pw.Document(title: 'MSR2_DMR User Manual');
    late final pw.ThemeData theme;
    try {
      final regular = await File(
        r'C:\Windows\Fonts\segoeui.ttf',
      ).readAsBytes();
      final bold = await File(
        r'C:\Windows\Fonts\segoeuib.ttf',
      ).readAsBytes();
      theme = pw.ThemeData.withFont(
        base: pw.Font.ttf(ByteData.sublistView(regular)),
        bold: pw.Font.ttf(ByteData.sublistView(bold)),
      );
    } catch (_) {
      theme = pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
    }

    for (final section in sections) {
      document.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          maxPages: 200,
          theme: theme,
          margin: const pw.EdgeInsets.all(42),
          build: (_) => [
            pw.Text(
              section.title,
              style: pw.TextStyle(
                color: PdfColor.fromHex('#3F73AA'),
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColor.fromHex('#6D9DCC'), thickness: 1.5),
            pw.SizedBox(height: 5),
            pw.Text(
              section.breadcrumb,
              style: pw.TextStyle(
                color: PdfColor.fromHex('#60758D'),
                fontSize: 10,
              ),
            ),
            pw.SizedBox(height: 16),
            for (final line in section.lines)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  line,
                  style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2),
                ),
              ),
          ],
        ),
      );
    }
    return document.save();
  }

  Future<void> _openPrintablePdf(Uint8List pdfBytes) async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'MSR2_DMR_User_Manual.pdf',
    );
    await file.writeAsBytes(pdfBytes, flush: true);
    await Process.start('rundll32.exe', [
      'url.dll,FileProtocolHandler',
      file.path,
    ]);
  }

  void _handleOption(_ManualOptionAction action) {
    switch (action) {
      case _ManualOptionAction.hideTabs:
        _toggleSidebar();
        break;
      case _ManualOptionAction.back:
        _goHome();
        break;
      case _ManualOptionAction.forward:
        _goForward();
        break;
      case _ManualOptionAction.stop:
        break;
      case _ManualOptionAction.home:
        _goHome();
        break;
      case _ManualOptionAction.refresh:
        _refresh();
        break;
      case _ManualOptionAction.internetOptions:
        _openInternetOptions();
        break;
      case _ManualOptionAction.print:
        _showPrintTopicsDialog();
        break;
      case _ManualOptionAction.searchHighlight:
        _toggleSearchHighlight();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          _ManualToolbar(
            sidebarVisible: _sidebarVisible,
            searchHighlightOn: _searchHighlightOn,
            onOptionSelected: _handleOption,
          ),
          Expanded(
            child: Row(
              children: [
                if (_sidebarVisible) ...[
                  SizedBox(
                    width: 270,
                    child: _ManualSidebar(
                      key: ValueKey(_refreshKey),
                      nodes: UserManualPage._contents,
                      currentTopic: _selectedManualTopic ?? '',
                      currentTopicLabel: _currentManualTopicLabel,
                      onTopicSelected: _selectManualTopic,
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: AppTheme.tableBorderBlue,
                  ),
                ],
                Expanded(
                  child: RepaintBoundary(
                    key: _printBoundaryKey,
                    child: _ManualHomeContent(
                      key: ValueKey('manual-content-$_refreshKey'),
                      scrollController: _contentScrollController,
                      searchHighlightOn: _searchHighlightOn,
                      selectedTopic: _selectedManualTopic,
                      onNavigate: _selectManualTopic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualToolbar extends StatelessWidget {
  const _ManualToolbar({
    required this.sidebarVisible,
    required this.searchHighlightOn,
    required this.onOptionSelected,
  });

  final bool sidebarVisible;
  final bool searchHighlightOn;
  final ValueChanged<_ManualOptionAction> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _ToolbarAction(
        Icons.visibility_off_outlined,
        sidebarVisible ? 'Hide' : 'Show',
        true,
        _ManualOptionAction.hideTabs,
      ),
      const _ToolbarAction(
        Icons.arrow_back,
        'Back',
        true,
        _ManualOptionAction.back,
      ),
      const _ToolbarAction(
        Icons.arrow_forward,
        'Forward',
        true,
        _ManualOptionAction.forward,
      ),
      const _ToolbarAction(
        Icons.home_outlined,
        'Home',
        true,
        _ManualOptionAction.home,
      ),
      const _ToolbarAction(
        Icons.print_outlined,
        'Print',
        true,
        _ManualOptionAction.print,
      ),
      const _ToolbarAction(Icons.settings_outlined, 'Options', true, null),
    ];

    return Container(
      height: 38,
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(bottom: BorderSide(color: AppTheme.tableBorderBlue)),
      ),
      child: Row(
        children: [
          for (final item in buttons)
            SizedBox(
              width: _toolbarTabWidth(item.label),
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: item.label == 'Options'
                    ? _OptionsToolbarButton(
                        item: item,
                        sidebarVisible: sidebarVisible,
                        searchHighlightOn: searchHighlightOn,
                        onSelected: onOptionSelected,
                      )
                    : _ToolbarButton(
                        item: item,
                        active: item.action == _ManualOptionAction.hideTabs,
                        onTap: item.action == null
                            ? null
                            : () => onOptionSelected(item.action!),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  double _toolbarTabWidth(String label) {
    if (label == 'Forward' || label == 'Options') return 92;
    return 74;
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.item, this.onTap, this.active = false});

  final _ToolbarAction item;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.enabled ? onTap : null,
      child: Opacity(
        opacity: item.enabled ? 1 : 0.55,
        child: Container(
          height: 35,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryColor : AppTheme.tableHeaderBlue,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            border: Border.all(color: AppTheme.tableBorderBlue),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 14,
                color: active ? Colors.white : AppTheme.textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                item.label,
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionsToolbarButton extends StatelessWidget {
  const _OptionsToolbarButton({
    required this.item,
    required this.sidebarVisible,
    required this.searchHighlightOn,
    required this.onSelected,
  });

  final _ToolbarAction item;
  final bool sidebarVisible;
  final bool searchHighlightOn;
  final ValueChanged<_ManualOptionAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _ManualOptionItem(
        sidebarVisible ? 'Hide Tabs' : 'Show Tabs',
        _ManualOptionAction.hideTabs,
      ),
      const _ManualOptionItem('Back', _ManualOptionAction.back),
      const _ManualOptionItem('Forward', _ManualOptionAction.forward),
      const _ManualOptionItem('Home', _ManualOptionAction.home),
      const _ManualOptionItem('Stop', _ManualOptionAction.stop),
      const _ManualOptionItem('Refresh', _ManualOptionAction.refresh),
      const _ManualOptionItem(
        'Internet Options...',
        _ManualOptionAction.internetOptions,
      ),
      const _ManualOptionItem.divider(),
      const _ManualOptionItem('Print...', _ManualOptionAction.print),
      _ManualOptionItem(
        searchHighlightOn ? 'Search Highlight Off' : 'Search Highlight On',
        _ManualOptionAction.searchHighlight,
      ),
    ];

    return PopupMenuButton<_ManualOptionAction>(
      tooltip: '',
      offset: const Offset(0, 28),
      color: AppTheme.surfaceColor,
      elevation: 4,
      constraints: const BoxConstraints(minWidth: 290),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          for (final item in menuItems)
            if (item.isDivider)
              const PopupMenuDivider(height: 1)
            else
              PopupMenuItem<_ManualOptionAction>(
                value: item.action,
                enabled: true,
                height: 34,
                child: Text(
                  item.label,
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
        ];
      },
      child: _ToolbarButton(item: item),
    );
  }
}

class _ManualOptionItem {
  const _ManualOptionItem(this.label, this.action) : isDivider = false;
  const _ManualOptionItem.divider()
    : label = '',
      action = _ManualOptionAction.stop,
      isDivider = true;

  final String label;
  final _ManualOptionAction action;
  final bool isDivider;
}

enum _ManualOptionAction {
  hideTabs,
  back,
  forward,
  home,
  stop,
  refresh,
  internetOptions,
  print,
  searchHighlight,
}

class _ToolbarAction {
  const _ToolbarAction(this.icon, this.label, this.enabled, this.action);

  final IconData icon;
  final String label;
  final bool enabled;
  final _ManualOptionAction? action;
}

class _ManualSidebar extends StatefulWidget {
  const _ManualSidebar({
    super.key,
    required this.nodes,
    required this.currentTopic,
    required this.currentTopicLabel,
    required this.onTopicSelected,
  });

  final List<_ManualNode> nodes;
  final String currentTopic;
  final String currentTopicLabel;
  final ValueChanged<String> onTopicSelected;

  @override
  State<_ManualSidebar> createState() => _ManualSidebarState();
}

class _ManualSidebarState extends State<_ManualSidebar> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardColor,
      child: Column(
        children: [
          SizedBox(
            height: 38,
            child: Row(
              children: [
                _sideTab('Contents', 0),
                _sideTab('Search', 1),
                _sideTab('Favorites', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.tableBorderBlue),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _ContentsTree(
                  nodes: widget.nodes,
                  onTopicSelected: widget.onTopicSelected,
                ),
                _ManualSearchPanel(
                  nodes: widget.nodes,
                  onTopicSelected: widget.onTopicSelected,
                ),
                _ManualFavoritesPanel(
                  currentTopic: widget.currentTopic,
                  currentTopicLabel: widget.currentTopicLabel,
                  onTopicSelected: widget.onTopicSelected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideTab(String text, int index) {
    final active = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      child: SizedBox(
        width: 84,
        child: Padding(
          padding: const EdgeInsets.only(right: 3, top: 3),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryColor : AppTheme.tableHeaderBlue,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
              border: Border.all(color: AppTheme.tableBorderBlue),
            ),
            child: Text(
              text,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualSearchPanel extends StatefulWidget {
  const _ManualSearchPanel({
    required this.nodes,
    required this.onTopicSelected,
  });

  final List<_ManualNode> nodes;
  final ValueChanged<String> onTopicSelected;

  @override
  State<_ManualSearchPanel> createState() => _ManualSearchPanelState();
}

class _ManualSearchPanelState extends State<_ManualSearchPanel> {
  final _searchController = TextEditingController();
  var _searchPreviousResults = true;
  var _matchSimilarWords = true;
  var _searchTitlesOnly = true;
  var _operator = 'AND';
  var _results = <({String title, String topic, String location})>[];
  int? _selectedIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _listTopics() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _selectedIndex = null;
      });
      return;
    }

    final terms = query
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    final candidates = _searchPreviousResults && _results.isNotEmpty
        ? _results
        : _allTopics();
    final matches = candidates.where((entry) {
      final text = (_searchTitlesOnly
              ? entry.title
              : '${entry.title} ${entry.topic} ${entry.location}')
          .toLowerCase();
      return _matchesSearch(text, terms);
    }).toList();

    setState(() {
      _results = matches;
      _selectedIndex = matches.isEmpty ? null : 0;
    });
  }

  void _displayTopic() {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _results.length) return;
    widget.onTopicSelected(_results[index].topic);
  }

  List<({String title, String topic, String location})> _allTopics() {
    final topics = <({String title, String topic, String location})>[];

    void addNodes(List<_ManualNode> nodes, List<String> parents) {
      for (final node in nodes) {
        topics.add((
          title: node.title,
          topic: node.topic,
          location: parents.isEmpty ? 'MSR2_DMR' : parents.join(' > '),
        ));
        addNodes(node.children, [...parents, node.title]);
      }
    }

    addNodes(widget.nodes, const []);
    return topics;
  }

  bool _matchesSearch(String text, List<String> terms) {
    bool contains(String term) {
      if (_matchSimilarWords) return text.contains(term);
      return RegExp(
        '(^|[^a-z0-9])${RegExp.escape(term)}(?=[^a-z0-9]|\$)',
      ).hasMatch(text);
    }

    switch (_operator) {
      case 'OR':
        return terms.any(contains);
      case 'NOT':
        return terms.length == 1
            ? !contains(terms.first)
            : contains(terms.first) &&
                  terms.skip(1).every((term) => !contains(term));
      case 'NEAR':
        if (!terms.every(contains)) return false;
        final positions = terms.map(text.indexOf).toList()..sort();
        return positions.last - positions.first <= 40;
      default:
        return terms.every(contains);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Type in the word(s) to search for:',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: TextField(
                    controller: _searchController,
                    style: AppTheme.bodyLarge.copyWith(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 7,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    onSubmitted: (_) => _listTopics(),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              SizedBox(
                width: 72,
                height: 28,
                child: PopupMenuButton<String>(
                  tooltip: 'Select search operator',
                  onSelected: (value) {
                    setState(() => _operator = value);
                    if (_searchController.text.trim().isNotEmpty) {
                      _listTopics();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'AND', child: Text('AND')),
                    PopupMenuItem(value: 'OR', child: Text('OR')),
                    PopupMenuItem(value: 'NEAR', child: Text('NEAR')),
                    PopupMenuItem(value: 'NOT', child: Text('NOT')),
                  ],
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _operator,
                          style: AppTheme.bodyLarge.copyWith(fontSize: 11),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 17),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: _listTopics,
                    child: Text(
                      'List Topics',
                      style: AppTheme.bodyLarge.copyWith(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: _selectedIndex == null ? null : _displayTopic,
                    child: Text(
                      'Display',
                      style: AppTheme.bodyLarge.copyWith(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select topic:',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Found: ${_results.length}',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Expanded(child: _resultsTable()),
          const SizedBox(height: 6),
          _searchCheck(
            'Search previous results',
            _searchPreviousResults,
            (value) => setState(() => _searchPreviousResults = value),
          ),
          _searchCheck(
            'Match similar words',
            _matchSimilarWords,
            (value) => setState(() => _matchSimilarWords = value),
          ),
          _searchCheck(
            'Search titles only',
            _searchTitlesOnly,
            (value) => setState(() => _searchTitlesOnly = value),
          ),
        ],
      ),
    );
  }

  Widget _resultsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _tableHeader('Title', flex: 5),
              _tableHeader('Location', flex: 4),
              _tableHeader('Rank', width: 54),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                final selected = _selectedIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedIndex = index),
                  onDoubleTap: () {
                    setState(() => _selectedIndex = index);
                    widget.onTopicSelected(result.topic);
                  },
                  child: Row(
                    children: [
                      _resultCell(result.title, flex: 5, selected: selected),
                      _resultCell(
                        result.location,
                        flex: 4,
                        selected: selected,
                      ),
                      _resultCell(
                        '${index + 1}',
                        width: 54,
                        selected: selected,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {int? flex, double? width}) {
    final cell = Container(
      width: width,
      height: 30,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.tableHeaderBlue,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    if (width != null) return cell;
    return Expanded(flex: flex ?? 1, child: cell);
  }

  Widget _resultCell(
    String text, {
    int? flex,
    double? width,
    bool selected = false,
  }) {
    final cell = Container(
      width: width,
      height: 26,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryColor : AppTheme.surfaceColor,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 12,
          color: selected ? Colors.white : AppTheme.textPrimary,
        ),
      ),
    );
    if (width != null) return cell;
    return Expanded(flex: flex ?? 1, child: cell);
  }

  Widget _searchCheck(String label, bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: (next) => onChanged(next ?? false),
              activeColor: Colors.blue.shade700,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualFavoritesPanel extends StatefulWidget {
  const _ManualFavoritesPanel({
    required this.currentTopic,
    required this.currentTopicLabel,
    required this.onTopicSelected,
  });

  final String currentTopic;
  final String currentTopicLabel;
  final ValueChanged<String> onTopicSelected;

  @override
  State<_ManualFavoritesPanel> createState() => _ManualFavoritesPanelState();
}

class _ManualFavoritesPanelState extends State<_ManualFavoritesPanel> {
  late final TextEditingController _currentTopicController;
  final _favorites = <({String topic, String label})>[];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _currentTopicController = TextEditingController(
      text: widget.currentTopicLabel,
    );
  }

  @override
  void didUpdateWidget(covariant _ManualFavoritesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTopicLabel != widget.currentTopicLabel) {
      _currentTopicController.text = widget.currentTopicLabel;
    }
  }

  @override
  void dispose() {
    _currentTopicController.dispose();
    super.dispose();
  }

  void _addFavorite() {
    final topic = widget.currentTopic;
    final label = widget.currentTopicLabel.trim();
    if (label.isEmpty) return;
    setState(() {
      var index = _favorites.indexWhere((favorite) => favorite.topic == topic);
      if (index == -1) {
        _favorites.add((topic: topic, label: label));
        index = _favorites.length - 1;
      }
      _selectedIndex = index;
    });
  }

  void _removeFavorite() {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _favorites.length) return;
    setState(() {
      _favorites.removeAt(index);
      _selectedIndex = _favorites.isEmpty ? null : 0;
    });
  }

  void _displayFavorite() {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _favorites.length) return;
    widget.onTopicSelected(_favorites[index].topic);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Topics:',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: _topicsBox()),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 86,
                height: 34,
                child: OutlinedButton(
                  onPressed: _selectedIndex == null ? null : _removeFavorite,
                  child: Text(
                    'Remove',
                    style: AppTheme.bodyLarge.copyWith(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 84,
                height: 34,
                child: OutlinedButton(
                  onPressed: _selectedIndex == null ? null : _displayFavorite,
                  child: Text(
                    'Display',
                    style: AppTheme.bodyLarge.copyWith(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current topic:',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: TextField(
              controller: _currentTopicController,
              readOnly: true,
              style: AppTheme.bodyLarge.copyWith(fontSize: 12),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 7,
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 86,
              height: 34,
              child: OutlinedButton(
                onPressed: _addFavorite,
                child: Text(
                  'Add',
                  style: AppTheme.bodyLarge.copyWith(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicsBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final selected = _selectedIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    height: 26,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    color: selected ? Colors.blue.shade700 : Colors.white,
                    child: Text(
                      _favorites[index].label,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 12,
                        color: selected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 24,
            alignment: Alignment.centerLeft,
            color: AppTheme.readOnlyCell,
            padding: const EdgeInsets.only(left: 28),
            child: Container(
              width: 136,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentsTree extends StatelessWidget {
  const _ContentsTree({required this.nodes, required this.onTopicSelected});

  final List<_ManualNode> nodes;
  final ValueChanged<String> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(3, 5, 3, 10),
      children: [
        for (final node in nodes)
          _ManualTreeNode(node: node, onTopicSelected: onTopicSelected),
      ],
    );
  }
}

class _ManualTreeNode extends StatefulWidget {
  const _ManualTreeNode({
    required this.node,
    required this.onTopicSelected,
    this.depth = 0,
  });

  final _ManualNode node;
  final ValueChanged<String> onTopicSelected;
  final int depth;

  @override
  State<_ManualTreeNode> createState() => _ManualTreeNodeState();
}

class _ManualTreeNodeState extends State<_ManualTreeNode> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final children = node.children;
    if (children.isEmpty) {
      return _ManualLeaf(
        node: node,
        depth: widget.depth,
        onTopicSelected: widget.onTopicSelected,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 20,
          child: Row(
            children: [
              SizedBox(width: 3.0 + widget.depth * 10),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Icon(
                  _expanded
                      ? Icons.indeterminate_check_box_outlined
                      : Icons.add_box_outlined,
                  size: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                widget.depth == 0
                    ? Icons.menu_book_outlined
                    : Icons.folder_open_outlined,
                size: 13,
                color: widget.depth == 0
                    ? AppTheme.primaryColor
                    : AppTheme.warningColor,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: InkWell(
                  onTap: () => widget.onTopicSelected(node.topic),
                  child: Text(
                    node.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: widget.depth == 0 ? 11 : 10,
                      fontWeight: widget.depth == 0
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: widget.depth == 0
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
            ],
          ),
        ),
        if (_expanded)
          for (final child in children)
            _ManualTreeNode(
              node: child,
              depth: widget.depth + 1,
              onTopicSelected: widget.onTopicSelected,
            ),
      ],
    );
  }
}

class _ManualLeaf extends StatelessWidget {
  const _ManualLeaf({
    required this.node,
    required this.depth,
    required this.onTopicSelected,
  });

  final _ManualNode node;
  final int depth;
  final ValueChanged<String> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTopicSelected(node.topic),
      child: Padding(
        padding: EdgeInsets.only(left: 21.0 + depth * 10, right: 3),
        child: SizedBox(
          height: 18,
          child: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 12,
                color: AppTheme.infoColor,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  node.title,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 10,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualHomeContent extends StatelessWidget {
  const _ManualHomeContent({
    super.key,
    required this.scrollController,
    required this.searchHighlightOn,
    required this.selectedTopic,
    required this.onNavigate,
  });

  final ScrollController scrollController;
  final bool searchHighlightOn;
  final String? selectedTopic;
  final ValueChanged<String> onNavigate;

  static const links = <String, String>{
    'INTRODUCTION': 'Introduction',
    'MSR2_DMR STRUCTURE': 'MSR2_DMR Structure',
    'GETTING STARTED': 'Getting Started',
    'INPUT WINDOWS': 'Input Windows',
    'OUTPUT WINDOWS': 'Output Toolbar',
    'RECAP WINDOWS': 'Recap Windows',
    'WELL COMPARISON WINDOWS': 'Well Comparison Windows',
  };

  @override
  Widget build(BuildContext context) {
    final topic = selectedTopic;
    if (topic != null && _ManualTopicPage.supports(topic)) {
      return _ManualTopicPage(
        topic: topic,
        scrollController: scrollController,
        onNavigate: onNavigate,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: AppTheme.panelHeaderBlue,
            border: Border(bottom: BorderSide(color: AppTheme.tableBorderBlue)),
          ),
          child: Text(
            'MSR2_DMR',
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
            child: Column(
              children: [
                Text(
                  'MSR2_DMR',
                  style: AppTheme.titleLarge.copyWith(
                    fontSize: 58,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        offset: Offset(2, 3),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Advanced Drilling Mud Reporting',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                for (final link in links.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: InkWell(
                      onTap: () => onNavigate(link.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: searchHighlightOn
                              ? AppTheme.calculatedCell
                              : Colors.transparent,
                        ),
                        child: Text(
                          link.key,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyLarge.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualTopicPage extends StatelessWidget {
  const _ManualTopicPage({
    required this.topic,
    required this.scrollController,
    required this.onNavigate,
  });

  final String topic;
  final ScrollController scrollController;
  final ValueChanged<String> onNavigate;

  static const _introLinks = [
    'Background',
    'Engineering Features',
    'Copyright and Disclaimer',
    'Technical Support',
  ];

  static const _structureLinks = [
    'Main Structure',
    'Pad (Well)/Report Management',
  ];

  static const _gettingStartedLinks = [
    'Hardware and System Requirements',
    'Installing the Software',
    'Licensing the Software',
    'Quick Tour',
  ];

  static const _inputWindowLinks = ['Menu/Toolbar', 'Pad', 'Well', 'Report'];

  static const _padLevelLinks = [
    'Pad',
    'Inventory',
    'Pit',
    'Pump',
    'SCE',
    'Formation',
    'Report',
    'Alert',
  ];

  static const _wellLevelLinks = [
    'Well',
    'Casing',
    'Interval',
    'Plan',
    'Survey',
  ];

  static const _reportLevelLinks = [
    'Well',
    'Mud',
    'Pump',
    'Operation',
    'Snapshots',
    'Pits',
    'Safety',
    'Remarks',
  ];

  static const _snapshotLinks = [
    'Inventory Snapshot',
    'Volume Snapshot',
    'Mud Treated',
  ];

  static const _reportPitsLinks = ['Active Pits', 'Reserve Pits'];

  static const _menuToolbarLinks = ['Home', 'Toolbar Report', 'Utility & Help'];

  static const _outputJobExplorerLinks = <String, String>{
    'Summary': 'Output Summary',
    'Detail': 'Output Detail',
    'Daily Cost': 'Output Daily Cost',
    'Total Cost': 'Output Total Cost',
    'Concentration': 'Output Concentration',
    'Time Distribution': 'Output Time Distribution',
    'Survey': 'Output Survey',
    'Alert': 'Output Alert',
  };

  static const _recapJobExplorerLinks = <String, String>{
    'Summary': 'Recap Summary',
    'Cost Distribution': 'Recap Cost Distribution',
    'Daily Cost': 'Recap Daily Cost',
    'Depth Cost': 'Recap Depth Cost',
    'Cumulative Cost': 'Recap Cumulative Cost',
    'Drilling Data': 'Recap Drilling Data',
    'Mud Properties': 'Recap Mud Properties',
    'Hydraulics': 'Recap Hydraulics',
    'Solid Analysis': 'Recap Solid Analysis',
    'Volume': 'Recap Volume',
    'Usage': 'Recap Usage',
    'Concentration': 'Recap Concentration',
    'Time Distribution': 'Recap Time Distribution',
    'Solid Control Equipment': 'Recap Solid Control Equipment',
    'Bit': 'Recap Bit',
    'Remarks': 'Recap Remarks',
    'Interval': 'Recap Interval',
    'Survey': 'Recap Survey',
    'Customized': 'Recap Customized',
    'Engineer': 'Recap Engineer',
  };

  static const _comparisonJobExplorerLinks = <String, String>{
    'Summary': 'Comparison Summary',
    'Cost': 'Comparison Cost',
    'Drilling Data': 'Comparison Drilling Data',
    'Mud Properties': 'Comparison Mud Properties',
    'Hydraulics': 'Comparison Hydraulics',
    'Solids': 'Comparison Solids',
    'Volume': 'Comparison Volume',
    'Time Distribution': 'Comparison Time Distribution',
    'Bit': 'Comparison Bit',
    'Remarks': 'Comparison Remarks',
    'Survey': 'Comparison Survey',
    'Engineer': 'Comparison Engineer',
  };

  static bool supports(String topic) {
    return topic == 'Introduction' ||
        topic == 'MSR2_DMR Structure' ||
        topic == 'Getting Started' ||
        topic == 'Input Windows' ||
        _introLinks.contains(topic) ||
        _structureLinks.contains(topic) ||
        _gettingStartedLinks.contains(topic) ||
        _inputWindowLinks.contains(topic) ||
        _padLevelLinks.contains(topic) ||
        _wellLevelLinks.contains(topic) ||
        _reportLevelLinks.contains(topic) ||
        topic == 'Pad Report' ||
        topic == 'Pad Detail' ||
        topic == 'Well Detail' ||
        topic == 'Input Report' ||
        topic == 'Report Well' ||
        topic == 'Report Mud' ||
        topic == 'Report Pump' ||
        topic == 'Report Operation' ||
        _operationLinkLabels.contains(topic) ||
        topic == 'Report Snapshots' ||
        _snapshotLinks.contains(topic) ||
        topic == 'Report Pits' ||
        _reportPitsLinks.contains(topic) ||
        topic == 'Report Safety' ||
        topic == 'Report Remarks' ||
        topic == 'Output Toolbar' ||
        topic == 'Output Home' ||
        topic == 'Output Options' ||
        topic == 'Output Job Explorer' ||
        topic == 'Output Summary' ||
        topic == 'Output Detail' ||
        topic == 'Output Daily Cost' ||
        topic == 'Output Total Cost' ||
        topic == 'Output Concentration' ||
        topic == 'Output Time Distribution' ||
        topic == 'Output Survey' ||
        topic == 'Recap Windows' ||
        topic == 'Recap Toolbar' ||
        topic == 'Recap Home & Report' ||
        topic == 'Recap Options' ||
        topic == 'Recap Job Explorer' ||
        _recapJobExplorerLinks.containsValue(topic) ||
        topic == 'Well Comparison Windows' ||
        topic == 'Comparison Toolbar' ||
        topic == 'Comparison Job Explorer' ||
        _comparisonJobExplorerLinks.containsValue(topic) ||
        _menuToolbarLinks.contains(topic);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _topicHeader(),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
            child: topic == 'Introduction' ? _introduction() : _detailPage(),
          ),
        ),
      ],
    );
  }

  Widget _topicHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.panelHeaderBlue,
        border: Border(bottom: BorderSide(color: AppTheme.tableBorderBlue)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _displayTitle,
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _breadcrumb,
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _headerIcon(Icons.home_outlined, () => onNavigate('Introduction')),
          _headerIcon(Icons.arrow_back, _goBack),
          _headerIcon(Icons.arrow_forward, _goNext),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Icon(icon, size: 22, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }

  Widget _introduction() {
    return _linkList(_introLinks);
  }

  Widget _structure() {
    return _linkList(_structureLinks);
  }

  Widget _gettingStarted() {
    return _linkList(_gettingStartedLinks);
  }

  Widget _inputWindows() {
    return _linkList(_inputWindowLinks);
  }

  Widget _linkList(List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: InkWell(
              onTap: () => onNavigate(
                _inputWindowLinks.contains(link)
                    ? _inputWindowTopic(link)
                    : link,
              ),
              child: Text(
                link,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailPage() {
    if (topic == 'MSR2_DMR Structure') {
      return _structure();
    }
    if (topic == 'Getting Started') {
      return _gettingStarted();
    }
    if (topic == 'Input Windows') {
      return _inputWindowsPage();
    }
    if (topic == 'Pad') {
      return _padLevelPage();
    }
    if (topic == 'Well') {
      return _wellLevelPage();
    }
    if (topic == 'Well Detail') {
      return _wellDetailPage();
    }
    if (topic == 'Casing') {
      return _casingPage();
    }
    if (topic == 'Interval') {
      return _intervalPage();
    }
    if (topic == 'Plan') {
      return _planPage();
    }
    if (topic == 'Survey') {
      return _surveyPage();
    }
    if (topic == 'Input Report') {
      return _reportLevelPage();
    }
    if (topic == 'Report Well') {
      return _reportWellPage();
    }
    if (topic == 'Report Mud') {
      return _reportMudPage();
    }
    if (topic == 'Report Pump') {
      return _reportPumpPage();
    }
    if (topic == 'Report Operation') {
      return _reportOperationPage();
    }
    if (topic == 'Consume Product') {
      return _consumeProductPage();
    }
    if (topic == 'Consume Services') {
      return _consumeServicesPage();
    }
    if (topic == 'Receive Product') {
      return _receiveProductPage();
    }
    if (topic == 'Return Product') {
      return _returnProductPage();
    }
    if (topic == 'Transfer Mud') {
      return _transferMudPage();
    }
    if (topic == 'Receive Mud') {
      return _receiveMudPage();
    }
    if (topic == 'Return/Lost Mud') {
      return _returnLostMudPage();
    }
    if (topic == 'Add Water') {
      return _addWaterPage();
    }
    if (topic == 'Switch Pits') {
      return _switchPitsPage();
    }
    if (topic == 'Switch Mud Type') {
      return _switchMudTypePage();
    }
    if (topic == 'Other Volume Addition-Active System') {
      return _otherVolumeAdditionPage();
    }
    if (topic == 'Mud Loss-Active System') {
      return _mudLossActivePage();
    }
    if (topic == 'Mud Loss-Reserve Pits') {
      return _mudLossReservePage();
    }
    if (topic == 'Report Snapshots') {
      return _snapshotsPage();
    }
    if (_snapshotLinks.contains(topic)) {
      return _snapshotDetailPage(topic);
    }
    if (topic == 'Report Pits') {
      return _reportPitsPage();
    }
    if (_reportPitsLinks.contains(topic)) {
      return _reportPitsDetailPage(topic);
    }
    if (topic == 'Report Safety') {
      return _reportSafetyPage();
    }
    if (topic == 'Report Remarks') {
      return _reportRemarksPage();
    }
    if (topic == 'Output Toolbar') {
      return _outputToolbarPage();
    }
    if (topic == 'Output Home') {
      return _outputHomePage();
    }
    if (topic == 'Output Options') {
      return _outputOptionsPage();
    }
    if (topic == 'Output Job Explorer') {
      return _outputJobExplorerPage();
    }
    if (topic == 'Output Summary') {
      return _outputSummaryPage();
    }
    if (topic == 'Output Detail') {
      return _outputDetailPage();
    }
    if (topic == 'Output Daily Cost') {
      return _outputDailyCostPage();
    }
    if (topic == 'Output Total Cost') {
      return _outputTotalCostPage();
    }
    if (topic == 'Output Concentration') {
      return _outputConcentrationPage();
    }
    if (topic == 'Output Time Distribution') {
      return _outputTimeDistributionPage();
    }
    if (topic == 'Output Survey') {
      return _outputSurveyPage();
    }
    if (topic == 'Recap Windows') {
      return _recapWindowsPage();
    }
    if (topic == 'Recap Toolbar') {
      return _recapToolbarPage();
    }
    if (topic == 'Recap Home & Report') {
      return _recapHomeReportPage();
    }
    if (topic == 'Recap Options') {
      return _recapOptionsPage();
    }
    if (topic == 'Recap Job Explorer') {
      return _recapJobExplorerPage();
    }
    if (topic == 'Recap Summary') {
      return _recapSummaryPage();
    }
    if (topic == 'Recap Cost Distribution') {
      return _recapCostDistributionPage();
    }
    if (topic == 'Recap Daily Cost') {
      return _recapDailyCostPage();
    }
    if (topic == 'Recap Depth Cost') {
      return _recapDepthCostPage();
    }
    if (topic == 'Recap Cumulative Cost') {
      return _recapCumulativeCostPage();
    }
    if (topic == 'Recap Drilling Data') {
      return _recapDrillingDataPage();
    }
    if (topic == 'Recap Mud Properties') {
      return _recapMudPropertiesPage();
    }
    if (topic == 'Recap Hydraulics') {
      return _recapHydraulicsPage();
    }
    if (topic == 'Recap Solid Analysis') {
      return _recapSolidAnalysisPage();
    }
    if (topic == 'Recap Volume') {
      return _recapVolumePage();
    }
    if (topic == 'Recap Usage') {
      return _recapUsagePage();
    }
    if (topic == 'Recap Concentration') {
      return _recapConcentrationPage();
    }
    if (topic == 'Recap Time Distribution') {
      return _recapTimeDistributionPage();
    }
    if (topic == 'Recap Solid Control Equipment') {
      return _recapSolidControlEquipmentPage();
    }
    if (topic == 'Recap Bit') {
      return _recapBitPage();
    }
    if (topic == 'Recap Remarks') {
      return _recapRemarksPage();
    }
    if (topic == 'Recap Interval') {
      return _recapIntervalPage();
    }
    if (topic == 'Recap Survey') {
      return _recapSurveyPage();
    }
    if (topic == 'Recap Customized') {
      return _recapCustomizedPage();
    }
    if (topic == 'Recap Engineer') {
      return _recapEngineerPage();
    }
    if (topic == 'Well Comparison Windows') {
      return _wellComparisonWindowsPage();
    }
    if (topic == 'Comparison Toolbar') {
      return _comparisonToolbarPage();
    }
    if (topic == 'Comparison Job Explorer') {
      return _comparisonJobExplorerPage();
    }
    if (topic == 'Comparison Summary') {
      return _comparisonSummaryPage();
    }
    if (topic == 'Comparison Cost') {
      return _comparisonCostPage();
    }
    if (topic == 'Comparison Drilling Data') {
      return _comparisonDrillingDataPage();
    }
    if (topic == 'Comparison Mud Properties') {
      return _comparisonMudPropertiesPage();
    }
    if (topic == 'Comparison Hydraulics') {
      return _comparisonHydraulicsPage();
    }
    if (topic == 'Comparison Solids') {
      return _comparisonSolidsPage();
    }
    if (topic == 'Comparison Volume') {
      return _comparisonVolumePage();
    }
    if (topic == 'Comparison Time Distribution') {
      return _comparisonTimeDistributionPage();
    }
    if (topic == 'Comparison Bit') {
      return _comparisonBitPage();
    }
    if (topic == 'Comparison Remarks') {
      return _comparisonRemarksPage();
    }
    if (topic == 'Comparison Survey') {
      return _comparisonSurveyPage();
    }
    if (topic == 'Comparison Engineer') {
      return _comparisonEngineerPage();
    }
    if (topic == 'Pad Detail') {
      return _padDetailPage();
    }
    if (topic == 'Inventory') {
      return _inventoryPage();
    }
    if (topic == 'Pit') {
      return _pitPage();
    }
    if (topic == 'Pump') {
      return _pumpPage();
    }
    if (topic == 'SCE') {
      return _scePage();
    }
    if (topic == 'Formation') {
      return _formationPage();
    }
    if (topic == 'Pad Report') {
      return _padReportPage();
    }
    if (topic == 'Alert') {
      return _alertPage();
    }
    if (topic == 'Menu/Toolbar') {
      return _menuToolbarPage();
    }
    if (topic == 'Home') {
      return _homeToolbarPage();
    }
    if (topic == 'Report' || topic == 'Toolbar Report') {
      return _reportToolbarPage();
    }
    if (topic == 'Utility & Help') {
      return _utilityHelpPage();
    }
    if (topic == 'Main Structure') {
      return _mainStructureDiagram();
    }
    if (topic == 'Pad (Well)/Report Management') {
      return _padReportManagementDiagram();
    }
    if (topic == 'Quick Tour') {
      return _quickTourPage();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topic == 'Engineering Features')
          _featureList()
        else ...[
          Text(
            topic,
            style: AppTheme.titleMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _topicBody(topic),
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 15,
              height: 1.42,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _mainStructureDiagram() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 760,
        height: 560,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _MainStructureArrowPainter()),
            ),
            _diagramWindow(
              left: 24,
              top: 16,
              width: 160,
              height: 118,
              title: 'Mud Company',
              lines: const ['Company setup', 'Contacts', 'Defaults'],
            ),
            _diagramWindow(
              left: 270,
              top: 16,
              width: 170,
              height: 118,
              title: 'Master Product List',
              lines: const ['Products', 'Services', 'Others'],
              badge: 'Product\nDatabase',
            ),
            _diagramWindow(
              left: 24,
              top: 190,
              width: 220,
              height: 150,
              title: 'Input Window',
              lines: const [
                'Pad',
                '  Well 1',
                '    Report 1',
                '  Well 2',
                '    Report 1',
              ],
              menu: const ['Report', 'DMR', 'Recap'],
            ),
            _diagramWindow(
              left: 292,
              top: 212,
              width: 170,
              height: 118,
              title: 'Output Window',
              lines: const ['Report preview', 'Tables', 'Summary'],
            ),
            _diagramWindow(
              left: 292,
              top: 378,
              width: 170,
              height: 118,
              title: 'Recap',
              lines: const ['Summary', 'Cost', 'Usage'],
            ),
            _diagramWindow(
              left: 24,
              top: 444,
              width: 170,
              height: 118,
              title: 'Well Comparison',
              lines: const ['Compare wells', 'Planned vs actual'],
            ),
            _reportIcon(
              left: 505,
              top: 242,
              label: 'Daily Report',
              accent: Colors.green,
            ),
            _reportIcon(
              left: 508,
              top: 408,
              label: 'Recap',
              accent: Colors.purple,
            ),
            _reportIcon(
              left: 232,
              top: 504,
              label: 'Well Comparison Report',
              accent: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _padReportManagementDiagram() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 760,
        height: 560,
        child: Stack(
          children: [
            Text(
              'Each pad contains wells and daily reports. MSR2_DMR keeps these records together so they can be opened, shared, reviewed, deleted, and reported from the same project structure.',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
            const Positioned.fill(
              child: CustomPaint(painter: _PadReportArrowPainter()),
            ),
            _diagramWindow(
              left: 12,
              top: 138,
              width: 160,
              height: 118,
              title: 'Project Folder',
              lines: const ['Pad files', 'Well data', 'Reports'],
            ),
            _fileBadge(left: 214, top: 174),
            _diagramWindow(
              left: 308,
              top: 102,
              width: 252,
              height: 185,
              title: 'Input Window',
              lines: const ['File', 'New', 'Open...', 'Save'],
              menu: const ['Report', 'Select Report', 'Report Manager'],
            ),
            _diagramWindow(
              left: 366,
              top: 408,
              width: 168,
              height: 110,
              title: 'Report Manager',
              lines: const ['Report list', 'Report details', 'Delete'],
            ),
            Positioned(
              left: 240,
              top: 250,
              child: Text(
                'Share',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 145,
              top: 310,
              child: Text(
                'Other MSR2_DMR User',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              left: 412,
              top: 360,
              child: Text(
                'Delete',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileBadge({required double left, required double top}) {
    return Positioned(
      left: left,
      top: top,
      width: 34,
      height: 42,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blueGrey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.description_outlined,
          color: Colors.blue.shade600,
          size: 24,
        ),
      ),
    );
  }

  Widget _diagramWindow({
    required double left,
    required double top,
    required double width,
    required double height,
    required String title,
    required List<String> lines,
    List<String>? menu,
    String? badge,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1D7),
          border: Border.all(color: const Color(0xFF7F9A63), width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 17,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: const Color(0xFF9CB47A),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (final color in const [
                    Color(0xFFC8D8B0),
                    Color(0xFFC8D8B0),
                    Color(0xFFD84E36),
                  ])
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 2),
                      color: color,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                line,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (menu != null)
                    Positioned(
                      left: width - 116,
                      top: 19,
                      width: 58,
                      child: Column(
                        children: [
                          for (final item in menu)
                            Container(
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey.shade500,
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                item,
                                style: AppTheme.bodyLarge.copyWith(fontSize: 9),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (badge != null)
                    Positioned(
                      right: 18,
                      top: 28,
                      child: Container(
                        width: 62,
                        height: 62,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF35A23B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(2, 2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          badge,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportIcon({
    required double left,
    required double top,
    required String label,
    required Color accent,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blueGrey.shade100),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.table_chart_outlined, color: accent, size: 34),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.blue.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickTourPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tourStep(
          '1.',
          'Start MSR2_DMR from the desktop shortcut or from the Windows Start menu.',
        ),
        _tourStep(
          '2.',
          'Open an existing project or create a new pad/well project from the Home area.',
        ),
        _tourStep(
          '3.',
          'Review the pad, well, and report structure from the navigation tree. Pad-level information contains inventory, pits, pumps, SCE, formation, reports, and alerts. Well-level information contains casing, interval, plan, and survey data.',
        ),
        const SizedBox(height: 10),
        _mockAppScreenshot(
          title: 'MSR2_DMR - Input',
          leftMenu: const ['Pad', 'Well', 'Report 1', 'Report 2', 'Report 3'],
          tabs: const ['Well', 'Mud', 'Pump', 'Operation', 'Pit', 'Remarks'],
          panels: const [
            'General',
            'Casing',
            'Open Hole',
            'Bit Data',
            'Drilling String',
            'Time Distribution',
          ],
        ),
        const SizedBox(height: 18),
        _tourStep(
          '4.',
          'Enter or review daily report information such as well details, mud properties, pump data, pits, operations, safety, and remarks.',
        ),
        _tourStep(
          '5.',
          'Use calculate/report actions to refresh output values and review the output dashboard, charts, tables, and wellbore-related views.',
        ),
        const SizedBox(height: 10),
        _mockAppScreenshot(
          title: 'MSR2_DMR - Daily Report',
          leftMenu: const [
            'Summary',
            'Detail',
            'Daily Cost',
            'Total Cost',
            'Survey',
            'Alert',
          ],
          tabs: const ['Report Output'],
          panels: const [
            'Wellbore Schematic',
            'KPI Dashboard',
            'Cost Distribution',
            'Progress',
          ],
        ),
        const SizedBox(height: 18),
        _tourStep(
          '6.',
          'Export the daily report to Excel when the report data has been reviewed.',
        ),
        _tourStep(
          '7.',
          'Return to the input area when updates are needed, then recalculate and export again.',
        ),
        _tourStep(
          '8.',
          'Open Recap from the report workflow to review summary, cost, usage, concentration, hydraulics, solids, volume, bit, remarks, interval, survey, and safety information.',
        ),
        const SizedBox(height: 10),
        _mockAppScreenshot(
          title: 'MSR2_DMR - Recap',
          leftMenu: const [
            'Summary',
            'Cost',
            'Usage',
            'Concentration',
            'Hydraulics',
            'Solids',
            'Survey',
          ],
          tabs: const ['Home', 'Report'],
          panels: const [
            'Wellbore Schematic',
            'KPI Dashboard',
            'Top Products',
            'Progress Charts',
          ],
        ),
        const SizedBox(height: 18),
        _tourStep(
          '9.',
          'Use Well Comparison to compare planned and actual data across selected wells and reports.',
        ),
        _tourStep(
          '10.',
          'Close the active windows after the project data has been saved and reports have been exported.',
        ),
      ],
    );
  }

  Widget _inputWindowsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'The Input window includes: ',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
            for (var i = 0; i < _inputWindowLinks.length; i++) ...[
              InkWell(
                onTap: () =>
                    onNavigate(_inputWindowTopic(_inputWindowLinks[i])),
                child: Text(
                  _inputWindowLinks[i],
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.blue.shade700,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (i < _inputWindowLinks.length - 1)
                Text(', ', style: AppTheme.bodyLarge.copyWith(fontSize: 15)),
            ],
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mockAppScreenshot(
                title: 'MSR2_DMR - Input',
                leftMenu: const [
                  'New Pad',
                  'Well 1',
                  'Report 1',
                  'Report 2',
                  'Well 2',
                ],
                tabs: const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ],
                panels: const [
                  'General',
                  'Cased Hole',
                  'Open Hole',
                  'Bit',
                  'Drill String',
                  'Time Distribution',
                ],
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _calloutNumber('1', 'Menu'),
                  _calloutNumber('2', 'Toolbar'),
                  _calloutNumber('3', 'Job Explorer'),
                  const SizedBox(height: 18),
                  Container(
                    width: 190,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F3FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'The selected item in the Job Explorer controls which input tabs and fields are shown on the right side of the screen.',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 13,
                        height: 1.28,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _mockTreeStructure(),
        const SizedBox(height: 20),
        Text(
          'In the Job Explorer, there is a three-level structure:',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _manualBullet(
          'Pad Level: includes shared pad information such as inventory, pit, pump, SCE, formation, reports, and alerts.',
        ),
        _manualBullet(
          'Well Level: contains well-specific setup such as casing, interval, plan, and survey information.',
        ),
        _manualBullet(
          'Report Level: contains the daily mud reporting data entered under each well.',
        ),
      ],
    );
  }

  Widget _padLevelPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'The Pad level includes: ',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
            for (var i = 0; i < _padLevelLinks.length; i++) ...[
              InkWell(
                onTap: () => onNavigate(_padLevelTopic(_padLevelLinks[i])),
                child: Text(
                  _padLevelLinks[i],
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.blue.shade700,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (i < _padLevelLinks.length - 1)
                Text(', ', style: AppTheme.bodyLarge.copyWith(fontSize: 15)),
            ],
          ],
        ),
        const SizedBox(height: 18),
        _manualBullet('Add and manage wells under the selected pad.'),
        _manualBullet(
          'Define pad information that is shared by wells and daily reports.',
        ),
        _manualBullet('Select inventory from the mud company database.'),
        _manualBullet('List pits available at the pad location.'),
        _manualBullet('List pumps to be used for pad drilling.'),
        _manualBullet('List shakers and solids control equipment.'),
        const SizedBox(height: 20),
        Text(
          'MSR2_DMR uses a three-level structure, and Pad is the top level. A pad can contain multiple wells. Use the Job Explorer context menu to add wells, rename the pad, expand the tree, or collapse the tree.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        _padContextMenuMock(),
        const SizedBox(height: 24),
        Text(
          'All wells and reports can use data entered at pad level. If pad-level data is changed after it has already been selected in existing reports, related report values may also change. Review existing reports carefully after changing shared pad data.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _padLevelTopic(String label) {
    if (label == 'Pad') {
      return 'Pad Detail';
    }
    if (label == 'Report') {
      return 'Pad Report';
    }
    return label;
  }

  String _inputWindowTopic(String label) {
    if (label == 'Report') {
      return 'Input Report';
    }
    return label;
  }

  Widget _wellLevelPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'The Well level includes: ',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
            for (var i = 0; i < _wellLevelLinks.length; i++) ...[
              InkWell(
                onTap: () => onNavigate(_wellLevelTopic(_wellLevelLinks[i])),
                child: Text(
                  _wellLevelLinks[i],
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.blue.shade700,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (i < _wellLevelLinks.length - 1)
                Text(', ', style: AppTheme.bodyLarge.copyWith(fontSize: 15)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Up to 40 wells can be added to a pad. Activate a well to make it the current working well; the active well is marked in the well node and its data is shown in the input area.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'A new report can be added only under the current working well. If well-level data is changed after reports already exist, related daily report data can also change, so existing reports should be reviewed after editing well information.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _wellMock(),
      ],
    );
  }

  String _wellLevelTopic(String label) {
    if (label == 'Well') {
      return 'Well Detail';
    }
    return label;
  }

  Widget _wellDetailPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The information entered at the Well level is used in reports. The well name shown in the job explorer and the Well Name/No. field are kept in sync. If either value is changed, the matching value is updated automatically so the report and well tree stay consistent.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 52),
        const Divider(height: 1, color: AppTheme.tableBorderBlue),
        const SizedBox(height: 14),
        Text(
          'Copyright (C) 2026 Bits and Bytes IT Solution. All Rights Reserved.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 12.5,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _casingPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Casings should be predefined for each well. If a casing is not entered in this table, it will not be available for selection in the daily report. Casing weight, shoe, bit, and TOC values are optional.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        _casingSetupMock(),
        const SizedBox(height: 24),
        Text(
          'The casings entered at the Well level are shown in the daily report for selection, as shown below.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        _casingReportSelectionMock(),
      ],
    );
  }

  Widget _casingSetupMock() {
    final headers = const [
      'Description',
      'Type',
      'OD\n(in)',
      'Wt.\n(lb/ft)',
      'ID\n(in)',
      'Top\n(ft)',
      'Shoe\n(ft)',
      'Bit\n(in)',
      'TOC\n(ft)',
    ];
    final rows = const [
      [
        'Conductor',
        'Casing',
        '20.000',
        '94.000',
        '18.000',
        '0.0',
        '80.0',
        '',
        '',
      ],
      [
        'Surface',
        'Casing',
        '13.375',
        '54.000',
        '12.615',
        '0.0',
        '1965.0',
        '',
        '',
      ],
      [
        'Intermediate',
        'Casing',
        '9.625',
        '40.000',
        '8.681',
        '0.0',
        '10870.0',
        '',
        '',
      ],
      ['Production', 'Casing', '5.500', '', '5.000', '0.0', '10845.0', '', ''],
      [
        'Production 5',
        'Casing',
        '5.000',
        '',
        '4.000',
        '0.0',
        '22482.0',
        '',
        '',
      ],
    ];

    return _wellInputFrame(
      activeTab: 'Casing',
      height: 525,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: _casingGrid(headers: headers, rows: rows, minRows: 20),
      ),
    );
  }

  Widget _casingReportSelectionMock() {
    final casingRows = const [
      ['Conductor', '20.000', '94.000', '18.000'],
      ['Surface', '13.375', '54.000', '12.615'],
      ['', '', '', ''],
      ['', '', '', ''],
    ];
    final drillRows = const [
      ['BHA', '6.500', '4.778', '40.0'],
      ['HWDP', '5.500', '3.250', '155.0'],
      ['JARS', '6.688', '3.375', '30.0'],
      ['DC', '6.500', '2.812', '124.0'],
      ['XO', '8.250', '2.812', '40.0'],
      ['HWDC', '7.812', '3.500', '30.0'],
      ['MWD', '7.875', '3.750', '33.0'],
    ];

    return _wellInputFrame(
      activeTab: 'Well',
      height: 410,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 132,
              child: Column(
                children: [
                  for (final item in const [
                    ['Report #', '1'],
                    ['User Report #', ''],
                    ['Date', '4/12/2022'],
                    ['Time', '19:00'],
                    ['Engineer', 'Bill Lee'],
                    ['MD', '1965.0'],
                    ['TVD', '1965.0'],
                    ['Interval', '2 - Int.'],
                    ['FIT', '12.50'],
                  ])
                    _reportSideField(item[0], item[1]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _reportCasingTable(casingRows)),
                      const SizedBox(width: 8),
                      _casingDropdownMock(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _drillStringMock(drillRows)),
                      const SizedBox(width: 8),
                      _smallBitPanelMock(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intervalPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intervals let users group several reports together and keep a summary or plan for that group. An interval may represent a casing interval. If an interval has subintervals, the subintervals should be added first and then grouped. If there are no subintervals, the group itself is counted as the interval. Up to 10 intervals can be added to a well, and a daily report can be assigned to the required interval.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        _intervalMock(),
        const SizedBox(height: 24),
        Text(
          'The Interval Summary report can be generated from the Recap window.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _intervalMock() {
    return _wellInputFrame(
      activeTab: 'Interval',
      height: 495,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _intervalTreeMock(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _intervalTabsMock(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 205,
                            child: Column(
                              children: [
                                _intervalInfoRow('Formation', 'Booster'),
                                _intervalInfoRow(
                                  'Bit Size',
                                  '12.250',
                                  unit: '(in)',
                                ),
                                _intervalInfoRow(
                                  'Casing',
                                  '9.625',
                                  unit: '(in)',
                                ),
                                _intervalInfoRow(
                                  'Interval FIT',
                                  '12.50',
                                  unit: '(ppg)',
                                ),
                                _intervalInfoRow('Mud Description', ''),
                                _intervalInfoRow('Mud Type', ''),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _intervalTextBox(
                              'Interval Conclusion and Recommendations',
                              height: 66,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _intervalTextBox(
                              'Interval Summary',
                              height: 78,
                              text:
                                  'Drilled shoe out and formation to 1375 ft. Formation was circulated clean and sweep material was used as required. Hole condition remained stable during the interval.',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _intervalTextBox('Sweeps', height: 78),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _intervalTextBox(
                              'Solid Control',
                              height: 58,
                              text:
                                  'Shakers operated with API screens. Dumped and cleaned sand traps as needed.',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _intervalTextBox('Lab Testing', height: 58),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _intervalTextBox(
              'End of Well Conclusion and Recommendations',
              height: 54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _intervalTreeMock() {
    final items = const [
      '* TEST WELL 1',
      'Mud - Interval',
      '1 - Surface',
      '2 - Int.',
      '3 - Prod. Vertical',
      '4 - Curve',
      '5 - Lateral',
      '5.5 - Prod. Casing',
    ];

    return Container(
      width: 120,
      height: 218,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            Container(
              height: 20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: i == 0 ? 2 : 12),
              color: items[i] == '2 - Int.'
                  ? const Color(0xFFB7C8DA)
                  : Colors.transparent,
              child: Text(
                items[i],
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _intervalTabsMock() {
    return Row(
      children: [
        for (final tab in const ['General', 'Mud Plan'])
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tab == 'General' ? Colors.white : AppTheme.tableHeaderBlue,
              border: Border.all(color: Colors.grey.shade300, width: 0.6),
            ),
            child: Text(
              tab,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _intervalInfoRow(String label, String value, {String unit = ''}) {
    return Row(
      children: [
        _gridCell(label, width: 92, yellow: false),
        _gridCell(value, width: 78, yellow: true, alignRight: true),
        if (unit.isNotEmpty) _gridCell(unit, width: 35, yellow: false),
      ],
    );
  }

  Widget _intervalTextBox(
    String title, {
    required double height,
    String text = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 0.6),
          ),
          child: Text(
            text,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 8.5,
              height: 1.15,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _planPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _planMock(),
        const SizedBox(height: 24),
        Text(
          'The planned TD, days, and total cost are set for the well. In the detailed table, the preferred mud-property range can be entered for different depths. If the daily report values are outside the range defined here, warnings are shown in the Output window alert table.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _planMock() {
    return _wellInputFrame(
      activeTab: 'Plan',
      height: 530,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 205,
              child: Column(
                children: [
                  _planSummaryRow('TD', '22482.0', '(ft)'),
                  _planSummaryRow('Days', '27', '(-)'),
                  _planSummaryRow('Total Cost', '150000.00', r'($)'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _planRangeTable(),
            const SizedBox(height: 5),
            Text(
              'L: Low, H: High',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 8.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planSummaryRow(String label, String value, String unit) {
    return Row(
      children: [
        _gridCell(label, width: 72, yellow: false),
        _gridCell(value, width: 90, yellow: true, alignRight: true),
        _gridCell(unit, width: 43, yellow: false),
      ],
    );
  }

  Widget _planRangeTable() {
    final rows = const [
      ['1000.0', '3', '10000.00', '10.00', '12.00', '10.0', '15.0'],
      ['2000.0', '5', '15000.00', '12.00', '13.00', '15.0', '18.0'],
      ['3000.0', '7', '20000.00', '12.00', '13.00', '12.0', '13.0'],
      ['5000.0', '8', '30000.00', '13.00', '13.50', '10.0', '12.0'],
      ['8000.0', '12', '35000.00', '11.00', '13.00', '12.0', '13.0'],
      ['10000.0', '15', '80000.00', '10.00', '12.00', '12.0', '13.0'],
      ['15000.0', '18', '90000.00', '12.00', '13.00', '13.0', '13.5'],
      ['18000.0', '20', '100000.00', '12.00', '13.00', '11.0', '13.0'],
      ['20000.0', '22', '120000.00', '13.00', '13.50', '17.0', '22.0'],
      ['22482.0', '27', '150000.00', '11.00', '13.00', '18.0', '20.0'],
    ];

    final headers = const [
      'MD\n(ft)',
      'Days\n(-)',
      'Cost\n(\$)',
      'MW\nL',
      'MW\nH',
      'Viscosity\nL',
      'Viscosity\nH',
      'PV\nL',
      'PV\nH',
      'YP\nL',
      'YP\nH',
      'API Filtrate\nL',
      'API Filtrate\nH',
      'HTHP Filtrate\nL',
      'HTHP Filtrate\nH',
      'pH\nL',
      'pH\nH',
    ];

    const widths = [
      50.0,
      34.0,
      62.0,
      35.0,
      35.0,
      40.0,
      40.0,
      32.0,
      32.0,
      32.0,
      32.0,
      42.0,
      42.0,
      42.0,
      42.0,
      28.0,
      28.0,
    ];

    return SizedBox(
      height: 350,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < headers.length; i++)
                  _gridCell(
                    headers[i],
                    width: widths[i],
                    header: true,
                    alignCenter: true,
                  ),
              ],
            ),
            for (var rowIndex = 0; rowIndex < 16; rowIndex++)
              Row(
                children: [
                  for (var col = 0; col < headers.length; col++)
                    _gridCell(
                      rowIndex < rows.length
                          ? col < rows[rowIndex].length
                                ? rows[rowIndex][col]
                                : ''
                          : '',
                      width: widths[col],
                      yellow: col >= 3 && col <= 6,
                      alignRight: col > 0,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _surveyPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planned survey data is optional. When planned survey data is provided here, MSR2_DMR can plot it with the actual survey data in daily report output and recap views.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        _surveyInputMock(),
        const SizedBox(height: 28),
        _surveyOutputMock(),
        const SizedBox(height: 18),
        Text(
          'Users may enter up to 1,000 survey stations. The first survey depth should start at 0 feet or 0 meters, and survey depths must remain in ascending order.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The first three columns are entered survey data: measured depth, inclination, and azimuth. The remaining columns are calculated values. Yellow cells indicate calculated fields that cannot be edited manually.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'The Survey section includes ',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            _inlineManualLink('Survey Data Input'),
            _inlineComma(),
            _inlineManualLink('Survey Data Calculation'),
            _inlineComma(),
            Text(
              ' and ',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            _inlineManualLink('Point Calculation'),
            Text(
              '.',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _surveyInputMock() {
    return _wellInputFrame(
      activeTab: 'Survey',
      height: 510,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _checkboxMock('Planned Survey', true),
                      const SizedBox(width: 10),
                      _surveySmallTab('Data', active: true),
                      _surveySmallTab('Section'),
                      _surveySmallTab('Plan'),
                      _surveySmallTab('Dogleg'),
                      _surveySmallTab('3D'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _surveyStationTable(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _checkboxMock('Project Azi', false),
                      const SizedBox(width: 8),
                      _gridCell('', width: 68, yellow: true),
                      const SizedBox(width: 8),
                      _gridCell('', width: 24, yellow: false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 185,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [_checkboxMock('Annotation', true)]),
                  const SizedBox(height: 8),
                  _surveyAnnotationTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _surveyStationTable() {
    final rows = const [
      ['0.0', '0.00', '0.00', '0.0', '0.0', '0.0', '0.0', '0.00'],
      ['100.0', '0.20', '88.11', '100.0', '0.2', '0.0', '0.2', '0.23'],
      ['150.0', '0.30', '88.83', '150.0', '0.3', '0.0', '0.3', '0.25'],
      ['200.0', '0.04', '85.18', '200.0', '0.4', '0.1', '0.4', '0.12'],
      ['250.0', '0.04', '255.09', '250.0', '0.3', '0.1', '0.4', '0.02'],
      ['300.0', '0.13', '236.17', '300.0', '0.3', '0.1', '0.3', '0.16'],
      ['350.0', '0.23', '218.15', '350.0', '0.3', '0.0', '0.3', '0.23'],
      ['400.0', '0.29', '219.87', '400.0', '0.3', '-0.1', '0.3', '0.20'],
      ['450.0', '0.18', '197.02', '450.0', '0.4', '-0.1', '-0.1', '0.18'],
      ['500.0', '0.38', '63.62', '500.0', '0.4', '-0.1', '0.1', '1.05'],
      ['550.0', '0.29', '78.62', '550.0', '0.7', '0.0', '0.6', '1.28'],
      ['600.0', '1.70', '65.81', '600.0', '1.3', '0.1', '1.8', '1.63'],
      ['700.0', '2.52', '56.13', '699.9', '3.1', '1.2', '3.3', '1.21'],
      ['800.0', '3.86', '332.17', '799.8', '8.8', '5.6', '6.7', '3.70'],
      ['900.0', '8.80', '305.46', '899.4', '24.1', '25.1', '4.1', '2.03'],
      ['1000.0', '8.59', '341.75', '998.7', '25.1', '25.1', '-0.5', '3.04'],
    ];

    final headers = const [
      'MD\n(ft)',
      'Inc\n( )',
      'Azi\n( )',
      'TVD\n(ft)',
      'N/S\n(ft)',
      'E/W\n(ft)',
      'Vertical\nSection',
      'DLS\n( /100ft)',
    ];
    const widths = [44.0, 34.0, 38.0, 44.0, 34.0, 34.0, 42.0, 48.0];

    return SizedBox(
      height: 350,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < headers.length; i++)
                  _gridCell(
                    headers[i],
                    width: widths[i],
                    header: true,
                    alignCenter: true,
                  ),
              ],
            ),
            for (final row in rows)
              Row(
                children: [
                  for (var i = 0; i < headers.length; i++)
                    _gridCell(
                      row[i],
                      width: widths[i],
                      yellow: i >= 3,
                      alignRight: true,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _surveyAnnotationTable() {
    final headers = const ['MD (ft)', 'Annotation', 'Symbol'];
    const widths = [52.0, 84.0, 46.0];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              _gridCell(
                headers[i],
                width: widths[i],
                header: true,
                alignCenter: true,
              ),
          ],
        ),
        for (var row = 0; row < 10; row++)
          Row(
            children: [
              for (var col = 0; col < headers.length; col++)
                _gridCell(
                  row == 0 && col == 0 ? '1000.0' : '',
                  width: widths[col],
                  yellow: col == 0,
                ),
            ],
          ),
      ],
    );
  }

  Widget _surveyOutputMock() {
    return Container(
      width: 630,
      height: 355,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Daily Report',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 92,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _outputNavRow('Summary', false),
                      _outputNavRow('Detail', false),
                      _outputNavRow('Daily Cost', false),
                      _outputNavRow('Total Cost', false),
                      _outputNavRow('Concentration', false),
                      _outputNavRow('Time Distr.', false),
                      _outputNavRow('Survey', true),
                      _outputNavRow('Alert', false),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF7F7F7),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _surveyPlotMock(
                                'Section View',
                                verticalLabel: 'TVD (ft)',
                                horizontalLabel: 'Horizontal Displacement (ft)',
                              ),
                              const SizedBox(width: 28),
                              _surveyPlotMock(
                                'Plan View',
                                verticalLabel: 'N/S (ft)',
                                horizontalLabel: 'E/W (ft)',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(child: _doglegPlotMock()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _surveySmallTab(String text, {bool active = false}) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white : AppTheme.tableHeaderBlue,
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: Text(
        text,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _outputNavRow(String label, bool active) {
    return Container(
      height: 24,
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      color: active ? const Color(0xFFD7E9FF) : Colors.transparent,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _surveyPlotMock(
    String title, {
    required String verticalLabel,
    required String horizontalLabel,
  }) {
    return SizedBox(
      width: 135,
      height: 118,
      child: CustomPaint(
        painter: _SurveyMiniPlotPainter(title, verticalLabel, horizontalLabel),
      ),
    );
  }

  Widget _doglegPlotMock() {
    return SizedBox(
      width: 480,
      child: CustomPaint(painter: const _DoglegPlotPainter()),
    );
  }

  Widget _inlineManualLink(String text) {
    return Text(
      text,
      style: AppTheme.bodyLarge.copyWith(
        color: Colors.blue.shade700,
        fontSize: 15,
        decoration: TextDecoration.underline,
      ),
    );
  }

  Widget _inlineManualLinkTo(String text, {String? target}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onNavigate(target ?? text),
      child: _inlineManualLink(text),
    );
  }

  Widget _inlineComma() {
    return Text(
      ', ',
      style: AppTheme.bodyLarge.copyWith(
        fontSize: 15,
        color: AppTheme.textPrimary,
      ),
    );
  }

  String _reportLevelTopic(String label) {
    switch (label) {
      case 'Well':
        return 'Report Well';
      case 'Mud':
        return 'Report Mud';
      case 'Pump':
        return 'Report Pump';
      case 'Operation':
        return 'Report Operation';
      case 'Snapshots':
        return 'Report Snapshots';
      case 'Pits':
        return 'Report Pits';
      case 'Safety':
        return 'Report Safety';
      case 'Remarks':
        return 'Report Remarks';
    }
    return label;
  }

  Widget _reportLevelPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'The Report level includes: ',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
            for (var i = 0; i < _reportLevelLinks.length; i++) ...[
              InkWell(
                onTap: () =>
                    onNavigate(_reportLevelTopic(_reportLevelLinks[i])),
                child: Text(
                  _reportLevelLinks[i],
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.blue.shade700,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (i < _reportLevelLinks.length - 1)
                Text(', ', style: AppTheme.bodyLarge.copyWith(fontSize: 15)),
            ],
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'After completing Pad and Well level setup data, users can start creating daily mud reports.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        _reportInputMock(),
        const SizedBox(height: 14),
        Text(
          '* Some parameters in the daily report can only be selected from Pad and Well level data. Complete the Pad and Well setup before starting the daily report so those selections are available.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _reportInputMock() {
    return Container(
      width: 655,
      height: 525,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Well'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('3/25/2022', 2),
                      _treeLine('# 6 7863.0 ft', 2),
                      _treeLine('3/26/2022', 2),
                      _treeLine('# 7 7944.0 ft', 2),
                      _treeLine('3/27/2022', 2),
                      _treeLine('# 8 8120.0 ft', 2),
                      _treeLine('3/28/2022', 2),
                      _treeLine('# 9 8250.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
                          child: Column(
                            children: [
                              for (final item in const [
                                ['Report #', '6'],
                                ['User Report #', ''],
                                ['Date', '3/25/2022'],
                                ['Time', '00:30'],
                                ['Engineer', 'Lucy Lindley'],
                                ['Activity', 'Drilling 1/2'],
                                ['MD', '7863.0'],
                                ['TVD', '7944.0'],
                                ['Inc', '3.01'],
                                ['Azi', '340.92'],
                                ['WOB', '25'],
                                ['RPM', '48.0'],
                                ['ROP', '67'],
                                ['Interval', '2 - Int.'],
                              ])
                                _reportSideField(item[0], item[1]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _reportCasingTable(const [
                                      ['Casing', '20.000', '94.000', '19.124'],
                                      ['Casing', '10.750', '45.500', '10.050'],
                                      ['', '', '', ''],
                                    ]),
                                  ),
                                  const SizedBox(width: 8),
                                  _smallBitPanelMock(),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _openHoleMock()),
                                  const SizedBox(width: 8),
                                  Expanded(child: _timeDistributionMock()),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _drillStringMock(const [
                                ['VAM DP New', '5.500', '4.778', '7746.0'],
                                ['VAM DC', '8.000', '3.375', '62.0'],
                                ['Directional', '8.000', '3.250', '55.0'],
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _openHoleMock() {
    const rows = [
      ['Surface', '8.375', '7863.0', ''],
      ['', '', '', ''],
      ['', '', '', ''],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open Hole',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            for (final h in const [
              'Description',
              'ID\n(in)',
              'MD\n(ft)',
              'Washout\n(%)',
            ])
              _gridCell(h, width: 55, header: true, alignCenter: true),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (final cell in row)
                _gridCell(
                  cell,
                  width: 55,
                  yellow: true,
                  alignRight: cell != row[0],
                ),
            ],
          ),
      ],
    );
  }

  Widget _timeDistributionMock() {
    const rows = [
      ['Rig-up/Serv.', '1.00'],
      ['Drilling', '23.00'],
      ['Circulating', ''],
      ['Tripping', ''],
      ['Survey', ''],
      ['Logging', ''],
      ['Run casing', ''],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Distribution',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            for (final h in const ['Activity', 'Time\n(hr)'])
              _gridCell(h, width: 72, header: true, alignCenter: true),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (final cell in row)
                _gridCell(
                  cell,
                  width: 72,
                  yellow: cell == row[1],
                  alignRight: cell == row[1],
                ),
            ],
          ),
      ],
    );
  }

  Widget _reportWellPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualHeading('1. General'),
        _manualParagraph(
          'Report # is generated automatically and increases when a new report is created. If the report date or time is changed later, report numbers are reassigned by date and time order within the pad, with the earliest report becoming number 1.',
        ),
        _manualParagraph(
          'User report No. is entered by the user and can be different from the generated report number when a separate field report reference is required.',
        ),
        _manualParagraph(
          'Date and Time identify when the report was created. When multiple reports are created in the same day, the time separates those reports and controls their order.',
        ),
        _manualNote(
          'Mud reports are listed on the left side in date and time sequence.',
        ),
        _manualParagraph(
          'Engineer and Activity are selected from dropdown values defined in the company setup. If those entries are not available in the company database, the dropdown list will be empty.',
        ),
        _manualParagraph(
          'MD, Inc., and Azi represent measured depth, inclination, and azimuth. These values define the wellbore trajectory and are required in the daily report. They are used to calculate TVD, which is then used in ECD calculations.',
        ),
        _manualParagraph(
          'TVD is displayed as true vertical depth. It can be entered for reference, but the calculated TVD from survey/deviation data is the value used for ECD workflow consistency.',
        ),
        _manualParagraph(
          'Interval is selected from the intervals defined at the Well level. After an interval has been used in a report, later reports should stay in the same interval or move forward to a later interval.',
        ),
        _manualParagraph(
          'FIT can be auto-filled from the selected interval. If the checkbox beside the row is enabled, the user can enter a custom value instead.',
        ),
        _manualParagraph(
          'Formation can be filled from Pad-level formation data by MD when formation information has been configured.',
        ),
        _manualParagraph(
          'Depth drilled is calculated from the current MD minus the previous report MD for the current well. For the first report in a well, it equals the current MD.',
        ),
        const SizedBox(height: 18),
        _manualHeading('Offshore Connection (offshore only)'),
        _offshoreConnectionMock(),
        const SizedBox(height: 14),
        _manualParagraph(
          'When offshore drilling is selected at Pad level, offshore connection options are shown at the bottom of the report well table. If Riser is enabled, it indicates that the riser is installed and remains selected in later reports. Kill line, choke line, and boost line are available only when a riser is installed.',
        ),
        _manualParagraph(
          'If the kill line or choke line is selected, fluid returns through that line instead of the riser. If the boost line is selected, fluid is pumped down through the boost line and returns to surface through the riser.',
        ),
        _manualParagraph(
          'ML, or mudline, is calculated as air gap plus water depth. The wellbore deviation above the mudline is ignored for this connection setup.',
        ),
        const SizedBox(height: 16),
        _manualHeading('2. Cased hole'),
        _manualParagraph(
          'Up to 10 casing sections can be added to the cased-hole table. Casing sections are selected from the casing entries predefined at the Well level.',
        ),
        _reportCasedHoleDropdownMock(),
        const SizedBox(height: 10),
        _manualParagraph(
          'For land wells, casing top is normally 0. For offshore wells, casing top is 0 or mudline depending on whether the riser is installed.',
        ),
        _manualNote(
          'Casing sections are selected from the predefined Well-level casing list.',
        ),
        const SizedBox(height: 16),
        _manualHeading('3. Open hole'),
        _manualParagraph(
          'Open-hole volume calculation includes the washout value. Open-hole MD should be greater than the last casing shoe when an open-hole section exists.',
        ),
        const SizedBox(height: 16),
        _manualHeading('4. Drill string'),
        _manualParagraph(
          'Drill string data can be entered manually or selected from the tubular database. When OD and weight are available, the ID can be calculated automatically.',
        ),
        _manualParagraph(
          'After the drill string is entered, total string length is calculated and displayed below the table. The total string length should be less than or equal to the well depth.',
        ),
        _manualNote('Drill string rows are entered from top down.'),
        const SizedBox(height: 16),
        _manualHeading('5. Bit'),
        _manualParagraph(
          'Bit size and depth drilled are used to calculate drilled volume. Bit depth should be less than or equal to total drill-string length.',
        ),
        const SizedBox(height: 16),
        _manualHeading('6. Nozzle'),
        _manualParagraph(
          'Total flow area (TFA) is calculated automatically from the nozzle table. Bit size and nozzle sizes are used in bit hydraulic calculations.',
        ),
        const SizedBox(height: 16),
        _manualHeading('7. Time Distribution'),
        _manualParagraph(
          'Time distribution records hours spent on each drilling activity. MSR2_DMR summarizes operation time for each day and for the whole well.',
        ),
      ],
    );
  }

  Widget _reportMudPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Mud properties can be recorded for up to four samples collected from different sources or at different times during the daily report.',
        ),
        _reportMudInputMock(),
        const SizedBox(height: 22),
        _manualHeading('1. Mud type'),
        _manualParagraph(
          'MSR2_DMR supports water-based, oil-based, and synthetic mud systems. The selected mud type controls which mud property fields are shown and which solids-analysis method is used.',
        ),
        _manualNote(
          'The default mud type is water-based. Select oil-based or synthetic before entering mud data when the report is for an invert or synthetic system.',
        ),
        const SizedBox(height: 10),
        _manualHeading('2. Mud properties'),
        _manualParagraph(
          'For water-based mud, Weighted Mud can be enabled when weighting material is part of the calculation. That selection changes the solids calculation path.',
        ),
        _mudTypeSelectorMock(),
        const SizedBox(height: 12),
        _manualParagraph(
          'For oil-based and synthetic mud, the salt system can be selected as NaCl, CaCl2, or dual salt. Dual salt means NaCl and CaCl2 are both present, so salinity-related fields are calculated with that combined system.',
        ),
        _manualParagraph(
          'The mud properties table stores the main circulating mud measurements. Four sample columns are available, and required calculation inputs are marked with an asterisk.',
        ),
        _mudIconNotes(),
        const SizedBox(height: 12),
        _mudTitrationAndSolidsMock(),
        const SizedBox(height: 18),
        _manualHeading('3. Solids and SG'),
        _manualParagraph(
          'Shale CEC, Bent CEC, HGS SG, and LGS SG are used in solids-analysis calculations. HGS means high-gravity solids, and LGS means low-gravity solids. The default-values button can populate standard values, but the values remain editable for the actual mud system.',
        ),
        const SizedBox(height: 8),
        _manualHeading('4. Rheology'),
        _manualParagraph(
          'The rheology model can be Bingham, Power-law, or HB. Fann viscometer readings describe the mud rheology and are used to calculate parameters such as PV, YP, n, and K.',
        ),
        _rheologyTableMock(),
        const SizedBox(height: 12),
        _manualParagraph(
          'The API RP13D calculation uses 600 and 300 rpm readings for Bingham and Power-law models, and 600, 300, 6, and 3 rpm readings for the HB model. Use All Readings applies a curve-fit method across the available readings.',
        ),
        _rheologyWindowMock(),
        const SizedBox(height: 12),
        _manualParagraph(
          'The Rheology window opens the graph view for the selected sample. Apply Rheology to Samples fills the calculated rheology results back into the Mud Properties table.',
        ),
      ],
    );
  }

  Widget _reportMudInputMock() {
    const properties = [
      ['Description', 'ND OBM 95/5', '', '', ''],
      ['Sample from', 'Active', '', '', ''],
      ['Time Sample Taken', '22:00', '', '', ''],
      ['Depth (ft)', '9848.0', '', '', ''],
      ['*MW (ppg)', '8.00', '', '', ''],
      ['*PV (cP)', '11.0', '', '', ''],
      ['*YP (lbf/100ft2)', '6.0', '', '', ''],
      ['Solids (%)', '8.0', '', '', ''],
      ['*Oil (%)', '87.0', '', '', ''],
      ['*Water (%)', '5.0', '', '', ''],
      ['Brine Density (ppg)', '10.86', '', '', ''],
    ];
    const rheology = [
      ['600', '28', '', '', ''],
      ['300', '17', '', '', ''],
      ['200', '13', '', '', ''],
      ['100', '10', '', '', ''],
      ['6', '6', '', '', ''],
      ['3', '5', '', '', ''],
      ['PV (cP)', '11.0', '', '', ''],
      ['YP (lbf/100ft2)', '6.0', '', '', ''],
    ];

    return Container(
      width: 655,
      height: 410,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Mud'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('3/25/2022', 2),
                      _treeLine('# 6 7863.0 ft', 2),
                      _treeLine('3/26/2022', 2),
                      _treeLine('# 7 7944.0 ft', 2),
                      _treeLine('3/27/2022', 2),
                      _treeLine('# 8 8120.0 ft', 2),
                      _treeLine('3/28/2022', 2),
                      _treeLine('# 9 8250.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Fluid Type',
                              style: AppTheme.bodyLarge.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            _mudDropdownMock('Oil-based', 82),
                            const SizedBox(width: 8),
                            _checkboxMock('Completion Fluid', false),
                            const SizedBox(width: 8),
                            Text(
                              'Salt Type',
                              style: AppTheme.bodyLarge.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            _mudDropdownMock('CaCl2', 70),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _mudPropertiesTableMock(properties),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _mudRheologyTableMock(rheology),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _specificGravityMock(),
                                    const SizedBox(width: 8),
                                    _solidsCecMock(),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mudDropdownMock(String value, double width) {
    return Container(
      width: width,
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 0.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade700),
        ],
      ),
    );
  }

  Widget _mudPropertiesTableMock(List<List<String>> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mud Properties',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            _gridCell('Property', width: 112, header: true, alignCenter: true),
            for (final sample in const ['1', '2', '3', '4'])
              _gridCell(sample, width: 40, header: true, alignCenter: true),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              _gridCell(row[0], width: 112),
              for (var i = 1; i < row.length; i++)
                _gridCell(row[i], width: 40, yellow: true, alignRight: true),
            ],
          ),
      ],
    );
  }

  Widget _mudRheologyTableMock(List<List<String>> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Rheology',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            Text('Model', style: AppTheme.bodyLarge.copyWith(fontSize: 9)),
            const SizedBox(width: 4),
            _mudDropdownMock('Bingham', 70),
          ],
        ),
        Row(
          children: [
            _gridCell('', width: 76, header: true),
            for (final sample in const ['1', '2', '3', '4'])
              _gridCell(sample, width: 38, header: true, alignCenter: true),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              _gridCell(row[0], width: 76),
              for (var i = 1; i < row.length; i++)
                _gridCell(row[i], width: 38, yellow: true, alignRight: true),
            ],
          ),
      ],
    );
  }

  Widget _specificGravityMock() {
    const rows = [
      ['Oil (SG)', '0.84'],
      ['HGS (SG)', '4.20'],
      ['LGS (SG)', '2.60'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specific Gravity',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        for (final row in rows)
          Row(
            children: [
              _gridCell(row[0], width: 74),
              _gridCell(row[1], width: 44, yellow: true, alignRight: true),
            ],
          ),
      ],
    );
  }

  Widget _solidsCecMock() {
    const rows = [
      ['Shale CEC', '15.00'],
      ['Bent CEC', '65.00'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solids',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        for (final row in rows)
          Row(
            children: [
              _gridCell(row[0], width: 74),
              _gridCell(row[1], width: 44, yellow: true, alignRight: true),
            ],
          ),
      ],
    );
  }

  Widget _mudTypeSelectorMock() {
    return Container(
      width: 330,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(
            'Fluid Type',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          _mudDropdownMock('Water-based', 100),
          const SizedBox(width: 12),
          _checkboxMock('Weighted Mud', true),
        ],
      ),
    );
  }

  Widget _mudIconNotes() {
    const notes = [
      'Sample for calculation selects which sample is used for hydraulics.',
      'Titration is available for oil-based and synthetic mud to calculate whole-mud calcium and chloride values.',
      'Auto calculation fills parameters that can be derived from the entered mud measurements.',
      'Solids Analysis opens the solids calculation window for the selected mud data.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < notes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _manualNumberBubble('${i + 1}'),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    notes[i],
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _manualNumberBubble(String text) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: AppTheme.bodyLarge.copyWith(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _mudTitrationAndSolidsMock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _simpleDialogMock(
          'Titration',
          width: 260,
          rows: const [
            ['EDTA (ml)', ''],
            ['Silver Nitrate 10k (ml)', ''],
            ['Whole Mud Ca (Caom)', ''],
            ['Chlorides Whole Mud', ''],
          ],
          actions: const ['Calculate', 'Accept', 'Cancel'],
        ),
        const SizedBox(width: 12),
        _simpleDialogMock(
          'Solids Analysis',
          width: 280,
          rows: const [
            ['LGS (%)', '9.7'],
            ['LGS (lb/bbl)', '88.62'],
            ['HGS (%)', '0.0'],
            ['HGS (lb/bbl)', '0.00'],
            ['Drill Solids (%)', '9.7'],
            ['Avg. SG of Solids', '2.09'],
          ],
          actions: const ['Calculate', 'Close'],
        ),
      ],
    );
  }

  Widget _simpleDialogMock(
    String title, {
    required double width,
    required List<List<String>> rows,
    required List<String> actions,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade500),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Row(
              children: [
                _gridCell(row[0], width: width - 92),
                _gridCell(row[1], width: 60, yellow: true, alignRight: true),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final action in actions) ...[
                _smallButton(action),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _rheologyTableMock() {
    const rows = [
      ['600', '28'],
      ['300', '17'],
      ['200', '13'],
      ['100', '10'],
      ['6', '6'],
      ['3', '5'],
      ['PV (cP)', '11.0'],
      ['YP (lbf/100ft2)', '6.0'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _gridCell('Rheology', width: 120, header: true),
            _gridCell('Sample 1', width: 70, header: true, alignCenter: true),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              _gridCell(row[0], width: 120),
              _gridCell(row[1], width: 70, yellow: true, alignRight: true),
            ],
          ),
      ],
    );
  }

  Widget _rheologyWindowMock() {
    return Container(
      width: 575,
      height: 260,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rheologyTableMock(),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const CustomPaint(painter: _RheologyCurvePainter()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportPumpPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportPumpInputMock(),
        const SizedBox(height: 24),
        _manualParagraph(
          'The Pump tab records the daily pump setup and the solids-control equipment usage for the report. Pump rows are selected from the pumps defined at Pad level, then daily operating values such as stroke rate, rate, and pressure can be entered for the report.',
        ),
        _dailyPumpSummaryMock(),
        const SizedBox(height: 14),
        _manualParagraph(
          'For offshore wells with a boost line selected, an additional boost pump rate can be entered. The return rate is calculated from the main pump rate plus the boost pump rate. The boost pump sends fluid through the boost line, and the fluid returns to surface through the riser.',
        ),
        _manualParagraph(
          'For the Shaker and SCE tables, equipment is selected from the dropdown lists already configured in the Pad SCE section. The quick-fill control helps populate screen size or common equipment details so the report stays consistent with the Pad setup.',
        ),
      ],
    );
  }

  Widget _reportPumpInputMock() {
    return Container(
      width: 655,
      height: 510,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Pump'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('3/25/2022', 2),
                      _treeLine('# 6 7863.0 ft', 2),
                      _treeLine('3/26/2022', 2),
                      _treeLine('# 7 7944.0 ft', 2),
                      _treeLine('3/27/2022', 2),
                      _treeLine('# 8 8120.0 ft', 2),
                      _treeLine('3/28/2022', 2),
                      _treeLine('# 9 8250.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _reportPumpTableMock(),
                            const SizedBox(width: 10),
                            _dailyPumpPanelMock(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _shakerUsageMock(),
                        const SizedBox(height: 10),
                        _sceUsageMock(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportPumpTableMock() {
    const headers = [
      'Model',
      'Type',
      'Liner ID\n(in)',
      'Rod OD\n(in)',
      'Stk. Length\n(ft)',
      'Efficiency\n(%)',
      'Disp.\n(bbl/stk)',
      'Stroke\n(stk/min)',
      'Rate\n(gpm)',
    ];
    const widths = [48.0, 42.0, 38.0, 34.0, 44.0, 42.0, 44.0, 36.0, 36.0];
    const rows = [
      [
        'HHF-1600L-1',
        'Triplex',
        '6.500',
        '',
        '12.000',
        '97.0',
        '0.1195',
        '15',
        '75.3',
      ],
      [
        'HHF-1600L-2',
        'Triplex',
        '6.500',
        '',
        '12.000',
        '97.0',
        '0.1195',
        '15',
        '75.3',
      ],
      ['', '', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', '', ''],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pump',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              _gridCell(
                headers[i],
                width: widths[i],
                header: true,
                alignCenter: true,
              ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (var i = 0; i < row.length; i++)
                _gridCell(
                  row[i],
                  width: widths[i],
                  yellow: i <= 8 && row[i].isNotEmpty,
                  alignRight: i >= 2,
                ),
            ],
          ),
      ],
    );
  }

  Widget _dailyPumpPanelMock() {
    const rows = [
      ['Pump Rate', '150.6', '(gpm)'],
      ['Pump Pressure', '0', '(psi)'],
      ['DH Tools P. Loss', '50', '(psi)'],
      ['Motor P. Loss', '40', '(psi)'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Row(
            children: [
              _gridCell(row[0], width: 72),
              _gridCell(row[1], width: 42, yellow: true, alignRight: true),
              _gridCell(row[2], width: 34),
            ],
          ),
      ],
    );
  }

  Widget _shakerUsageMock() {
    const headers = ['Shaker', 'Model', 'Screen', 'Time\n(hr)', 'OOC Wt.\n(%)'];
    const widths = [70.0, 92.0, 145.0, 48.0, 50.0];
    const rows = [
      ['Shaker', 'SWACO # 1', '80/80/80/80', '24.00', ''],
      ['Shaker', 'SWACO # 2', '80/80/80/80', '24.00', ''],
      ['Shaker', 'SWACO # 3', '80/80/80/80', '24.00', ''],
      ['', '', '', '', ''],
      ['', '', '', '', ''],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shaker',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              _gridCell(
                headers[i],
                width: widths[i],
                header: true,
                alignCenter: true,
              ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (var i = 0; i < row.length; i++)
                _gridCell(
                  row[i],
                  width: widths[i],
                  yellow: row[i].isNotEmpty && i != 0,
                  alignRight: i >= 3,
                ),
            ],
          ),
      ],
    );
  }

  Widget _sceUsageMock() {
    const headers = [
      'SCE',
      'Model',
      'U/F\n(ppg)',
      'O/F\n(ppg)',
      'Time\n(hr)',
      'OOC Wt.\n(%)',
    ];
    const widths = [68.0, 110.0, 48.0, 48.0, 48.0, 50.0];
    const rows = [
      ['Degasser', 'BURGESS', '', '', '', ''],
      ['Desander', 'DERRICK', '', '', '', ''],
      ['Desilter', 'DERRICK', '', '', '', ''],
      ['Centrifuge', 'TNS', '', '', '', ''],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solids Control Equipment',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              _gridCell(
                headers[i],
                width: widths[i],
                header: true,
                alignCenter: true,
              ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (var i = 0; i < row.length; i++)
                _gridCell(
                  row[i],
                  width: widths[i],
                  yellow: row[i].isNotEmpty && i != 0,
                  alignRight: i >= 2,
                ),
            ],
          ),
      ],
    );
  }

  Widget _dailyPumpSummaryMock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in const [
          ['Pump Rate', '150.6', '(gpm)'],
          ['Pump Pressure', '0', '(psi)'],
          ['DH Tools P. Loss', '50', '(psi)'],
          ['Motor P. Loss', '40', '(psi)'],
        ])
          Row(
            children: [
              _gridCell(row[0], width: 132),
              _gridCell(row[1], width: 70, yellow: true, alignRight: true),
              _gridCell(row[2], width: 48),
            ],
          ),
      ],
    );
  }

  Widget _reportOperationPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          runSpacing: 4,
          children: [
            Text(
              'The Operation tab includes: ',
              style: AppTheme.bodyLarge.copyWith(fontSize: 15, height: 1.35),
            ),
            for (var i = 0; i < _operationLinkLabels.length; i++) ...[
              _inlineManualLinkTo(_operationLinkLabels[i]),
              if (i != _operationLinkLabels.length - 1) _inlineComma(),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _manualParagraph(
          'The Operation tab is the main daily-report entry point for material movement, mud volume changes, services, and product consumption. These entries affect inventory, product concentration, daily cost, and active or reserve mud volume.',
        ),
        _manualParagraph(
          'Operations should be entered in the same order as the actual work on site. The order can affect product concentration and volume balances, especially when mud is transferred, received, returned, or lost during the report period.',
        ),
        _manualParagraph(
          'Operations are grouped into two calculation categories.',
        ),
        _reportOperationInputMock(),
        const SizedBox(height: 18),
        _manualParagraph(
          'Product operations affect product usage, inventory, cost, and concentration. Examples include consuming products or services, receiving products, returning products, and transferring material between inventory locations.',
        ),
        _manualParagraph(
          'Mud operations affect active-system volume, reserve pit volume, whole-mud cost, and concentration. Examples include receiving mud, returning or losing mud, adding water, switching pits, switching mud type, and recording mud losses.',
        ),
      ],
    );
  }

  static const List<String> _operationLinkLabels = [
    'Consume Product',
    'Consume Services',
    'Receive Product',
    'Return Product',
    'Transfer Mud',
    'Receive Mud',
    'Return/Lost Mud',
    'Add Water',
    'Switch Pits',
    'Switch Mud Type',
    'Other Volume Addition-Active System',
    'Mud Loss-Active System',
    'Mud Loss-Reserve Pits',
  ];

  Widget _reportOperationInputMock() {
    return Container(
      width: 655,
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Operation'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('5/6/2022', 2),
                      _treeLine('# 24 22482.0 ft', 2),
                      _treeLine('5/7/2022', 2),
                      _treeLine('# 25 22482.0 ft', 2),
                      _treeLine('5/8/2022', 2),
                      _treeLine('# 26 22482.0 ft', 2),
                      _treeLine('5/9/2022', 2),
                      _treeLine('# 27 22482.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _operationRowsTableMock(
                          activeOperation: 'Consume Product',
                        ),
                        const SizedBox(width: 14),
                        _operationCategoryMock(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _operationRowsTableMock({String? activeOperation}) {
    const defaultRows = [
      'Return/Lost Mud',
      'Transfer Mud',
      'Add Water - Active System',
      'Transfer Mud',
      'Consume Product',
      'Receive Mud',
      'Return/Lost Mud',
      'Transfer Mud',
      'Return/Lost Mud',
      'Return/Lost Mud',
      'Return/Lost Mud',
      'Consume Services',
      '',
      '',
      '',
    ];
    final rows = activeOperation == null
        ? defaultRows.take(12).toList()
        : [
            activeOperation,
            ...defaultRows.where((row) => row != activeOperation).take(11),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operation',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            _gridCell('#', width: 28, header: true, alignCenter: true),
            _gridCell('Description', width: 120, header: true),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          Row(
            children: [
              _gridCell('${i + 1}', width: 28, alignRight: true),
              _gridCell(rows[i], width: 120, yellow: rows[i].isNotEmpty),
            ],
          ),
      ],
    );
  }

  Widget _operationCategoryMock() {
    const productRows = [
      'Consume Product',
      'Consume Services',
      'Receive Product',
      'Return Product',
    ];
    const mudRows = [
      'Transfer Mud',
      'Receive Mud',
      'Return/Lost Mud',
      'Switch Mud Type',
      'Empty Active System',
      'Add Water',
      'Switch Pit',
      'Other Vol. Addition - Active System',
      'Mud Loss - Active System',
      'Mud Loss - Reserve Pit',
    ];

    return Container(
      width: 340,
      height: 300,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          for (final item in productRows)
            Text(
              item,
              style: AppTheme.bodyLarge.copyWith(fontSize: 10, height: 1.25),
            ),
          const SizedBox(height: 12),
          Text(
            'Mud',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          for (final item in mudRows)
            Text(
              item,
              style: AppTheme.bodyLarge.copyWith(fontSize: 10, height: 1.25),
            ),
        ],
      ),
    );
  }

  Widget _consumeProductPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _consumeProductInputMock(),
        const SizedBox(height: 24),
        _manualParagraph(
          'The products in the dropdown list are preselected in Pad - Inventory.',
        ),
        _numberedManualParagraph(
          '1',
          'Initial is the value at the beginning of the day and keeps the same starting value before this selected operation.',
        ),
        _numberedManualParagraph(
          '2',
          'Final is the value after the current operation. If consume, receive, return, or adjust operations happened earlier, final includes those movements and is not simply initial minus used.',
        ),
        _numberedManualParagraph(
          '3',
          'Vol. Addition is the additional volume added to the mixing fluid because of the product. If volume addition is enabled for the product, this volume is calculated; otherwise it is ignored.',
        ),
        _manualParagraph(
          'If negative inventory warning is enabled in Options, the program can warn when product final inventory becomes negative after the operation.',
        ),
        _manualParagraph(
          'MSR2_DMR provides two quick ways to choose consumed products.',
        ),
        _numberedManualParagraph(
          '4',
          'Select Products lets the user select products and accept them into the consume table at one time.',
        ),
        _numberedManualParagraph(
          '5',
          'Load Previous Products duplicates the last consumed products, including adjust and used values, into the current table.',
        ),
        _numberedManualParagraph(
          '6',
          'After product consumption is entered, the mixed fluid can be distributed into the active system or reserve pits.',
        ),
        _numberedManualParagraph(
          '7',
          'The total distributed volume should equal the total volume of products and water. If the total volume is zero and multiple pits are selected, the consumed products are distributed evenly.',
        ),
      ],
    );
  }

  Widget _consumeProductInputMock() {
    return Container(
      width: 720,
      height: 455,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Operation'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('5/6/2022', 2),
                      _treeLine('# 24 22482.0 ft', 2),
                      _treeLine('5/7/2022', 2),
                      _treeLine('# 25 22482.0 ft', 2),
                      _treeLine('5/8/2022', 2),
                      _treeLine('# 26 22482.0 ft', 2),
                      _treeLine('5/9/2022', 2),
                      _treeLine('# 27 22482.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _operationRowsTableMock(
                          activeOperation: 'Consume Services',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _consumeProductTableMock(),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _consumeDistributionMock(),
                                  const SizedBox(width: 10),
                                  _volumeByGroupMock(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consumeProductTableMock() {
    const headers = [
      'Product',
      'Code',
      'SG',
      'Unit',
      'Price\n(\$)',
      'Initial',
      'Adjust',
      'Used',
      'Final',
      'Cost\n(\$)',
      'Vol.\n(bbl)',
    ];
    const widths = [
      42.0,
      38.0,
      24.0,
      34.0,
      31.0,
      31.0,
      30.0,
      30.0,
      30.0,
      34.0,
      30.0,
    ];
    const rows = [
      [
        'PARAGON MUD',
        'P001232',
        '0.86',
        '1.00 gal',
        '100.00',
        '100.00',
        '',
        '15.00',
        '85.00',
        '250.00',
        '',
      ],
      [
        'PARAGON MLP',
        'P001217',
        '0.96',
        '1.00 gal',
        '9.70',
        '100.00',
        '',
        '25.00',
        '75.00',
        '242.50',
        '',
      ],
      [
        'OIL BASED MUD',
        'P000537',
        '1.40',
        '30.00 bbl',
        '10.00',
        '100.00',
        '',
        '20.00',
        '80.00',
        '200.00',
        '',
      ],
      [
        'HYDRATED LIME',
        'P000300',
        '2.20',
        '50.00 lb',
        '4.00',
        '100.00',
        '',
        '10.00',
        '90.00',
        '40.00',
        '',
      ],
      [
        'TEQHA LUB',
        'P001110',
        '1.10',
        '1.00 gal',
        '8.00',
        '100.00',
        '',
        '10.00',
        '90.00',
        '80.00',
        '',
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _manualActionButton('Select Products...', width: 88),
            const SizedBox(width: 8),
            _manualActionButton('Load Previous Products', width: 126),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              _gridCell(
                headers[i],
                width: widths[i],
                header: true,
                alignCenter: true,
              ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (var i = 0; i < row.length; i++)
                _gridCell(
                  row[i],
                  width: widths[i],
                  yellow: i >= 2,
                  alignRight: i >= 2,
                ),
            ],
          ),
      ],
    );
  }

  Widget _consumeDistributionMock() {
    const rows = [
      ['Active System', '1.00'],
      ['Frac 6', '0.50'],
      ['Frac 1', '1.50'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribute to',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            _gridCell('Pit', width: 110, header: true),
            _gridCell(
              'Vol.\n(bbl)',
              width: 54,
              header: true,
              alignCenter: true,
            ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              _gridCell(row[0], width: 110, yellow: true),
              _gridCell(row[1], width: 54, yellow: true, alignRight: true),
            ],
          ),
      ],
    );
  }

  Widget _volumeByGroupMock() {
    const rows = [
      ['Base Fluid', ''],
      ['Weight Material', ''],
      ['Products', ''],
      ['Water', ''],
      ['Total', '0.00'],
    ];

    return Container(
      width: 175,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume By Group',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _gridCell('', width: 95, header: true),
              _gridCell(
                'Vol. (bbl)',
                width: 62,
                header: true,
                alignCenter: true,
              ),
            ],
          ),
          for (final row in rows)
            Row(
              children: [
                _gridCell(row[0], width: 95),
                _gridCell(row[1], width: 62, yellow: true, alignRight: true),
              ],
            ),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: _smallButton('OK')),
        ],
      ),
    );
  }

  Widget _manualActionButton(String label, {required double width}) {
    return Container(
      width: width,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyLarge.copyWith(fontSize: 10),
      ),
    );
  }

  Widget _numberedManualParagraph(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _manualNumberBubble(number),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consumeServicesPage() {
    return _operationDetailPage(
      operation: 'Consume Services',
      screenshot: _consumeServicesInputMock(),
      paragraphs: const [
        'For Package, Services, and Engineering tables, the user can select each item from the dropdown list based on Pad - Inventory, input the used amounts directly, and the program will calculate the costs instantly.',
      ],
    );
  }

  Widget _consumeServicesInputMock() {
    return Container(
      width: 720,
      height: 480,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Operation'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('5/6/2022', 2),
                      _treeLine('# 24 22482.0 ft', 2),
                      _treeLine('5/7/2022', 2),
                      _treeLine('# 25 22482.0 ft', 2),
                      _treeLine('5/8/2022', 2),
                      _treeLine('# 26 22482.0 ft', 2),
                      _treeLine('5/9/2022', 2),
                      _treeLine('# 27 22482.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _operationRowsTableMock(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _consumeServiceTableMock('Package', const [
                                [
                                  'PALLETS, EA',
                                  '1',
                                  '0.00',
                                  '12.00',
                                  '10.00',
                                  '2.00',
                                  '0.00',
                                ],
                                [
                                  'SHRINK WRAP, EA',
                                  '1',
                                  '0.00',
                                  '5.00',
                                  '3.00',
                                  '3.00',
                                  '0.00',
                                ],
                                [
                                  'SHARED SERVICES, EA',
                                  '1',
                                  '260.00',
                                  '5.00',
                                  '2.00',
                                  '3.00',
                                  '780.00',
                                ],
                              ]),
                              const SizedBox(height: 8),
                              _consumeServiceTableMock('Services', const [
                                [
                                  'BULK TRUCKING',
                                  '1',
                                  '0.00',
                                  '30.00',
                                  '10.00',
                                  '20.00',
                                ],
                                [
                                  'SACK TRUCKING',
                                  '1',
                                  '0.00',
                                  '20.00',
                                  '3.00',
                                  '0.00',
                                ],
                                [
                                  'BULK FREIGHT - C',
                                  '1',
                                  '1250.00',
                                  '30.00',
                                  '10.00',
                                  '12500.00',
                                ],
                                [
                                  'WIMI qft',
                                  '1',
                                  '3.50',
                                  '5.00',
                                  '2.00',
                                  '17.50',
                                ],
                                [
                                  'GOM qft',
                                  '1',
                                  '10.00',
                                  '20.00',
                                  '10.00',
                                  '100.00',
                                ],
                              ]),
                              const SizedBox(height: 8),
                              _consumeServiceTableMock('Engineering', const [
                                ['24 HR ENG.', '1', '600.00', '1.00', '600.00'],
                                [
                                  '12 HR ENG.',
                                  '1',
                                  '300.00',
                                  '12.00',
                                  '3600.00',
                                ],
                                ['Discount', '1', '1.00', '100.00', '100.00'],
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consumeServiceTableMock(String title, List<List<String>> rows) {
    final headers = title == 'Package'
        ? const [
            'Package',
            'Code',
            'Unit',
            'Price\n(\$)',
            'Initial',
            'Used',
            'Final',
            'Cost\n(\$)',
          ]
        : const ['Item', 'Code', 'Unit', 'Price\n(\$)', 'Usage', 'Cost\n(\$)'];
    final widths = title == 'Package'
        ? const [78.0, 36.0, 30.0, 42.0, 38.0, 38.0, 38.0, 44.0]
        : const [92.0, 38.0, 34.0, 48.0, 48.0, 54.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              _gridCell(
                headers[i],
                width: widths[i],
                header: true,
                alignCenter: true,
              ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (var i = 0; i < headers.length; i++)
                _gridCell(
                  i < row.length ? row[i] : '',
                  width: widths[i],
                  yellow: i > 0,
                  alignRight: i > 1,
                ),
            ],
          ),
      ],
    );
  }

  Widget _receiveProductPage() {
    return _operationDetailPage(
      operation: 'Receive Product',
      body: _receiveProductBodyMock(),
      paragraphs: const [
        'The user needs to input the bill of lading number received.',
      ],
      numberedParagraphs: const [
        [
          '1',
          'Product and package rows are selected from the Pad - Inventory setup.',
        ],
        [
          '2',
          'The select-product icon helps the user select multiple products at one time.',
        ],
        [
          '3',
          'After amounts are entered, received quantities are added to inventory for the report sequence.',
        ],
      ],
    );
  }

  Widget _returnProductPage() {
    return _operationDetailPage(
      operation: 'Return Product',
      body: _returnProductBodyMock(),
      paragraphs: const [
        'The user needs to input BOL No. for product or package returns.',
      ],
      numberedParagraphs: const [
        [
          '1',
          'Products and packages are selected from the current inventory list.',
        ],
        [
          '2',
          'Return All Inventory fills the current inventory into the table for a full return.',
        ],
        [
          '3',
          'Returned quantities reduce the final inventory from the current operation onward.',
        ],
      ],
    );
  }

  Widget _transferMudPage() {
    return _operationDetailPage(
      operation: 'Transfer Mud',
      body: _transferMudBodyMock(),
      paragraphs: const [
        'Transfer refers to moving a certain amount of mud from reserve pits to the active system or from the active system to reserve pits.',
      ],
      numberedParagraphs: const [
        ['1', 'Select the source pit or active system in the From field.'],
        [
          '2',
          'Enter the volume for each destination pit or active system row.',
        ],
        [
          '3',
          'The total transferred amount must be less than or equal to the calculated available volume.',
        ],
      ],
    );
  }

  Widget _receiveMudPage() {
    return _operationDetailPage(
      operation: 'Receive Mud',
      body: _receiveMudBodyMock(),
      paragraphs: const [
        'The user needs to input the BOL No. The pre-mixed mud is defined in Pad - Inventory.',
      ],
      numberedParagraphs: const [
        [
          '1',
          'Select the pre-mixed mud entry and confirm MW, mud type, leasing fee, and target pit.',
        ],
        ['2', 'The composition icon displays the selected mud composition.'],
        [
          '3',
          'If the Leased checkbox is selected, the leasing fee is added to the daily cost.',
        ],
      ],
    );
  }

  Widget _returnLostMudPage() {
    return _operationDetailPage(
      operation: 'Return/Lost Mud',
      body: _returnLostMudBodyMock(),
      paragraphs: const [
        'The returned mud could be the fluid mixed on-site or the pre-mixed mud.',
      ],
      numberedParagraphs: const [
        [
          '1',
          'Select the source pit and destination or returned mud location.',
        ],
        ['2', 'Lost mud can only be handled as pre-mixed mud.'],
        [
          '3',
          'The cost of lost mud is entered here and added to the daily cost.',
        ],
      ],
    );
  }

  Widget _addWaterPage() {
    return _operationDetailPage(
      operation: 'Add Water',
      body: _addWaterBodyMock(),
      paragraphs: const [
        'The user can add a certain amount of water into the active system or into reserve pits.',
      ],
      numberedParagraphs: const [
        ['1', 'Select the destination in the To field.'],
        ['2', 'Enter the water volume in bbl.'],
        [
          '3',
          'The volume is included in the mud volume balance for the current report.',
        ],
      ],
    );
  }

  Widget _switchPitsPage() {
    return _operationDetailPage(
      operation: 'Switch Pits',
      body: _switchPitsBodyMock(),
      paragraphs: const [
        'If an active pit is checked, it is disconnected from the circulating system and becomes a reserve pit or storage pit.',
      ],
      numberedParagraphs: const [
        ['1', 'Check active pits that should be moved to reserve.'],
        [
          '2',
          'Check reserve pits that should be connected to the active circulating system.',
        ],
        [
          '3',
          'The active/reserve status affects circulation, mud volume, and later report calculations.',
        ],
      ],
    );
  }

  Widget _switchMudTypePage() {
    return _operationDetailPage(
      operation: 'Switch Mud Type',
      body: _switchMudTypeBodyMock(),
      paragraphs: const [
        'This operation is specially designed to help the user switch mud types for the whole circulating system.',
        'The first two steps are to switch the mud type in active pits.',
      ],
      numberedParagraphs: const [
        [
          '1',
          'Remove Mud from Active Pits: mud in active pits is transferred to reserve pits, or active pits are moved away and become reserve pits.',
        ],
        [
          '2',
          'Fill Active Pits: fluid is filled to the active pits from reserve pits, or one or more reserve pits are connected to the circulating system.',
        ],
        [
          '3',
          'Displace Fluid in Hole: displace the hole fluid using active pits or reserve pits. The total displaced volume should be greater than or equal to hole volume.',
        ],
      ],
    );
  }

  Widget _otherVolumeAdditionPage() {
    return _operationDetailPage(
      operation: 'Other Volume Addition-Active System',
      body: _otherVolumeAdditionBodyMock(),
      paragraphs: const [
        'Other things that increase the amount of volume in the active system are formation, cuttings, and other user-defined items.',
      ],
      numberedParagraphs: const [
        [
          '1',
          'Enter the added volume for the related active-system addition row.',
        ],
        [
          '2',
          'The help icon can help calculate the amount of cuttings left in the active system.',
        ],
        [
          '3',
          'These additions are included in the active-system mud volume balance.',
        ],
      ],
    );
  }

  Widget _mudLossActivePage() {
    return _operationDetailPage(
      operation: 'Mud Loss-Active System',
      body: _mudLossActiveBodyMock(),
      paragraphs: const [
        'The Loss table shows the main types of mud losses for the active system. The user can enter mud loss volumes in this window.',
      ],
      numberedParagraphs: const [
        [
          '1',
          'Cuttings loss and evaporation loss can be calculated with the help icons.',
        ],
        ['2', 'The balance icon helps the user balance mud volumes quickly.'],
        [
          '3',
          'The last user-defined loss rows are controlled from Pad - Others.',
        ],
      ],
    );
  }

  Widget _mudLossReservePage() {
    return _operationDetailPage(
      operation: 'Mud Loss-Reserve Pits',
      body: _mudLossReserveBodyMock(),
      paragraphs: const [
        'The Reserve pit loss section is used to input the mud loss volume for reserve pits.',
      ],
      numberedParagraphs: const [
        ['1', 'Select a reserve pit from the dropdown list.'],
        ['2', 'Enter dump, evaporation, and pit-cleaning volumes as required.'],
        [
          '3',
          'Reserve pit loss affects reserve mud volume and later report balances.',
        ],
      ],
    );
  }

  Widget _snapshotsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'After the daily operation entries are complete, users can review the inventory snapshot and volume snapshot from the buttons below the operation table.',
        ),
        const SizedBox(height: 4),
        for (final link in _snapshotLinks)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () => onNavigate(link),
              child: Text(
                link,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _snapshotDetailPage(String title) {
    if (title == 'Inventory Snapshot') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _manualParagraph(
            'The inventory snapshot is the summarization of product usage and cost.',
          ),
          _inventorySnapshotMock(),
        ],
      );
    }
    if (title == 'Volume Snapshot') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _volumeSnapshotMock(),
          const SizedBox(height: 24),
          _manualParagraph('1. Active System Volume'),
          _manualParagraph(
            'This section tracks mud added to and lost from the active circulating system, including volume transferred between the active system and reserve pits. Users can review the active-system Start Vol. and End Vol. for the current report. End Vol. is the calculated volume added to the active system. Circulating volume is the calculated hole volume plus measured active-pit volume. The difference between End Vol. and Circulating Vol. should be zero or very small.',
          ),
          _manualParagraph(
            'Mud additions include receive mud, base fluid, water, products, weight materials, formation, cuttings, and user-defined items. The related operation mapping is shown below.',
          ),
          _additionOperationsTableMock(),
          const SizedBox(height: 18),
          _manualParagraph('2. Loss'),
          _manualParagraph(
            'This section represents active-system loss entered through the Mud Loss - Active System operation.',
          ),
          _manualParagraph('3. Transfer'),
          _manualParagraph(
            'From storage is mud transferred from reserve/storage to the active system. To storage is mud transferred from the active system to storage. Return is mud shipped out from the rig location.',
          ),
          _manualParagraph('4. Reserve Pit Loss'),
          _manualParagraph(
            'This section represents reserve-pit mud loss for the current report, entered through the Mud Loss - Reserve Pits operation.',
          ),
          _manualParagraph('5. Premixed Mud'),
          _manualParagraph(
            'This section shows leased and non-leased premixed mud status, including cumulative leased mud up to the current report.',
          ),
          const SizedBox(height: 18),
          _manualParagraph('6. Volume Summary'),
          _manualParagraph(
            'Volume Summary shows the current report volume summary: hole volume, active pit volume, circulating volume, storage volume, and total volume on location.',
          ),
          _volumeSummaryMock(),
          const SizedBox(height: 14),
          _manualParagraph(
            'Hole means the wellbore configuration volume. The question icon opens a detail popup with the calculated hole-volume values. For offshore wells with a riser, the section can also include CKB volume for choke, kill, and boost lines.',
          ),
        ],
      );
    }
    if (title == 'Mud Treated') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _manualParagraph(
            'The definition of Mud Treated is the total volume of additions added to the active system by operations such as Consume Product, Receive Mud, Add Water, and Other Vol. Addition - Active System. It also includes mud transferred to the active system from reserve pits.',
          ),
          _mudTreatedSnapshotMock(),
        ],
      );
    }

    final description = switch (title) {
      'Inventory Snapshot' =>
        'Inventory Snapshot shows the product, package, service, and engineering quantities after the selected report operations are applied.',
      'Volume Snapshot' =>
        'Volume Snapshot shows active-system and reserve-pit volumes after the report operations are applied.',
      'Mud Treated' =>
        'Mud Treated summarizes the mud volume affected by the selected operation sequence for the current report.',
      _ =>
        'Snapshot information is calculated from the current report operations.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(description),
        _manualParagraph(
          'These snapshot views are review screens. They help confirm that report operations have updated inventory and mud volumes before the report is finalized.',
        ),
      ],
    );
  }

  Widget _reportPitsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportPitsInputMock(),
        const SizedBox(height: 24),
        for (final link in _reportPitsLinks)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () => onNavigate(link),
              child: Text(
                link,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _reportPitsDetailPage(String title) {
    final active = title == 'Active Pits';
    if (active) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _manualParagraph(
            'The active pits in the first report are preset at the pad level. The pit active status can change when Switch Pit or Switch Mud Type operations are processed. Users should measure the active-pit volume daily and record it in this table. The lightning button is used to quick-fill the MW column.',
          ),
          _manualParagraph(
            'The Concentration button on the upper-left corner opens the Pit Concentration window shown below. The window shows product concentration in the active circulating system by default. Users can select a reserve pit from the dropdown menu, then MSR2_DMR displays the product concentration in the selected pit.',
          ),
          _pitConcentrationMock(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reservePitsLargeMock(),
        const SizedBox(height: 24),
        _manualParagraph(
          'This table shows information about all reserve pits. The Pit column shows the names of reserve pits.',
        ),
        _manualBullet(
          'Calculated vol. is the volume of fluid/products added to the pit calculated through operations user input.',
        ),
        _manualBullet(
          'Measured vol. is the volume measured for the pit. It usually is equal to the calculated volume.',
        ),
        const SizedBox(height: 14),
        _manualParagraph(
          'To review product concentrations in a reserve pit, click the Concentration icon on the corner of the table to open the Concentration window. Select the pit from the drop-down list, and the table shows concentrations for the selected pit.',
        ),
        _manualParagraph(
          'The Pit Snapshot shows each pit or active system connection status and concentration table.',
        ),
        _pitSnapshotMock(),
      ],
    );
  }

  Widget _reportSafetyPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportSafetyInputMock(),
        const SizedBox(height: 24),
        _manualParagraph(
          'In the safety window, users can edit the Safety Card, review the checklist, and record any safety issue for the current daily report. The safety checklist is defined in the company database, so the available checklist items come from the configured setup.',
        ),
        _manualParagraph(
          'The Safety Issue Description and Action Taken fields are used to document the observed issue and the response completed by the crew.',
        ),
        _manualParagraph(
          'All safety information entered here will be reflected in the Safety Card report.',
        ),
      ],
    );
  }

  Widget _reportRemarksPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportRemarksInputMock(),
        const SizedBox(height: 24),
        _manualParagraph('There are four text boxes on the Remarks page.'),
        _manualParagraph(
          'These text boxes are used to enter the corresponding remarks for the current daily report. The entered content is shown in the daily report and recap report, and the four sections include spell-check support for report writing.',
        ),
        _manualParagraph(
          'A picture can also be uploaded for the remarks section. The selected image is saved with the project/case file and can be used as part of the report record.',
        ),
        _manualNote(
          'The internal notes will not be shown in any reports. They are kept only for internal reference.',
        ),
      ],
    );
  }

  Widget _outputOptionsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _outputSummaryOptionsMock(),
        const SizedBox(height: 22),
        _manualParagraph(
          'Options lets the user control which dashboard charts and report sections are included in the Output window.',
        ),
        _manualHeading('1. Summary'),
        _manualParagraph(
          'Summary settings control the panels shown on the output dashboard. Up to three KPI panels, progress charts, and cost-distribution views can be selected. Product groups and other cost categories can also be chosen for comparison charts.',
        ),
        _manualBullet(
          'Dashboard choices include depth, cost, day, average cost, daily footage, mud weight, rheology, ECD, and solids values.',
        ),
        _manualBullet(
          'Cost Distribution can show top products, individual products, selected product groups, packages, services, premixed mud, engineering, or all categories.',
        ),
        const SizedBox(height: 12),
        _outputDashboardPreview(),
        const SizedBox(height: 24),
        _manualHeading('2. Report'),
        _outputReportOptionsMock(),
        const SizedBox(height: 14),
        _manualParagraph(
          'Report settings control the daily report layout and the information printed in exported reports.',
        ),
        _manualBullet(
          'Daily Report Page selects a one-page, two-page, or three-page layout according to the required level of detail.',
        ),
        _manualBullet(
          'Report Page Size selects Legal, Letter, or A4 based on the available printer and export requirements.',
        ),
        _manualBullet(
          'Daily Report options control product price, product cost, total-cost basis, consumption basis, CCI visibility, and detailed pit information.',
        ),
        _manualNote(
          'Multi-rheology output requires a report format and page size that provide enough space for the additional result columns.',
        ),
        const SizedBox(height: 24),
        _manualHeading('3. Detail Report'),
        _outputDetailOptionsMock(),
        const SizedBox(height: 14),
        _manualParagraph(
          'Detail Report settings select the sections included in the detailed output package. Each section can expose its relevant graph, current table, history table, planned survey table, usage view, inventory view, or summary view.',
        ),
        _manualParagraph(
          'Use Default to restore the standard selections, OK to apply the current choices, or Cancel to close the window without applying the latest changes.',
        ),
      ],
    );
  }

  Widget _outputToolbarPage() {
    const links = <String, String>{
      'Home': 'Output Home',
      'Report': 'Toolbar Report',
      'Options': 'Output Options',
      'Utility & Help': 'Utility & Help',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph('The output toolbar includes:'),
        const SizedBox(height: 4),
        for (final link in links.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () => onNavigate(link.value),
              child: Text(
                link.key,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _outputHomePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapToolbarPreview(
          activeTab: 'Home',
          actions: const [
            (Icons.arrow_back_outlined, 'Go to Input'),
            (Icons.settings_outlined, 'Options'),
          ],
        ),
        const SizedBox(height: 18),
        _numberedHelp(
          '1.',
          'Go to Input returns to the main MSR2_DMR input window without changing the current output selection.',
        ),
        _numberedHelp(
          '2.',
          'Options opens the Output configuration used to customize dashboard panels and report contents.',
        ),
      ],
    );
  }

  Widget _outputJobExplorerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph('Output Job Explorer includes:'),
        const SizedBox(height: 4),
        for (final entry in _outputJobExplorerLinks.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () => onNavigate(entry.value),
              child: Text(
                entry.key,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _recapJobExplorerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph('The Recap Job Explorer includes:'),
        const SizedBox(height: 4),
        for (final entry in _recapJobExplorerLinks.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: () => onNavigate(entry.value),
              child: Text(
                entry.key,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _recapSummaryPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'The Summary tab provides a combined view of the selected recap range, including the wellbore schematic, KPI gauges, cost distribution, and drilling progress.',
        ),
        const SizedBox(height: 10),
        _outputSummaryWindowMock(),
        const SizedBox(height: 18),
        _manualParagraph(
          'The visible summary sections can be selected from Recap Options - Summary.',
        ),
      ],
    );
  }

  Widget _recapCostDistributionPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Cost Distribution groups the selected recap cost by product, inventory group, package, service, engineering, and overall category.',
        ),
        const SizedBox(height: 10),
        _recapExplorerPreview(
          selectedItem: 'Cost Distribution',
          height: 410,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _dailyCostChart('Product', const [
                        MapEntry('BARITE', 46),
                        MapEntry('BASE FLUID', 29),
                        MapEntry('LIME', 18),
                        MapEntry('LCM', 9),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dailyCostChart('Group', const [
                        MapEntry('Base Fluid', 44),
                        MapEntry('Weight Material', 37),
                        MapEntry('Other', 13),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _dailyCostChart('Service', const [
                        MapEntry('Rig service', 38),
                        MapEntry('Transport', 24),
                        MapEntry('Testing', 12),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dailyCostChart('All Categories', const [
                        MapEntry('Product', 48),
                        MapEntry('Service', 32),
                        MapEntry('Engineering', 15),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Use the view selector to compare individual product costs with totals for each configured category.',
        ),
      ],
    );
  }

  Widget _recapDailyCostPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _outputDailyCostWindowMock(tableView: false),
        const SizedBox(height: 18),
        _manualParagraph(
          'Daily Cost shows Product, Service, Engineering, Package, and Pre-mixed Mud costs for every report in the selected recap range. Graph and table views present the same dynamic report data.',
        ),
        const SizedBox(height: 10),
        _outputDailyCostWindowMock(tableView: true),
      ],
    );
  }

  Widget _recapDepthCostPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Depth Cost',
          height: 390,
          child: Column(
            children: [
              Expanded(
                child: _recapDataTable(
                  const ['MD', 'Product', 'Service', 'Engineering', 'Total'],
                  const [
                    ['1,250', '320', '80', '120', '520'],
                    ['3,100', '460', '95', '120', '675'],
                    ['5,900', '710', '140', '180', '1,030'],
                    ['8,450', '920', '210', '240', '1,370'],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: _totalCostMiniChart(
                  '2D Well Path - Cost by Depth',
                  AppTheme.panelHeaderBlue,
                  const [
                    Offset(0.08, 0.08),
                    Offset(0.10, 0.48),
                    Offset(0.20, 0.75),
                    Offset(0.58, 0.86),
                    Offset(0.92, 0.88),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Depth Cost compares category totals at different measured depths. The graph can follow either vertical depth or the calculated 2D well path selected in Recap Options.',
        ),
      ],
    );
  }

  Widget _recapCumulativeCostPage() {
    const colors = [
      Color(0xFF6EA7E8),
      Color(0xFF69C6DF),
      Color(0xFFF0B45A),
      Color(0xFF9BC66B),
      Color(0xFF9B7BC3),
    ];
    const names = [
      'Product',
      'Pre-mixed Mud',
      'Package',
      'Service',
      'Engineering',
    ];
    const points = [
      Offset(0.00, 0.94),
      Offset(0.38, 0.90),
      Offset(0.62, 0.70),
      Offset(0.78, 0.32),
      Offset(1.00, 0.12),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Cumulative Cost',
          height: 330,
          child: Row(
            children: [
              for (var index = 0; index < names.length; index++) ...[
                Expanded(
                  child: _totalCostMiniChart(
                    names[index],
                    colors[index],
                    points,
                  ),
                ),
                if (index != names.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Cumulative Cost tracks the running cost of each category across the recap range. Switch between graphs and tables to review both trends and report-level values.',
        ),
      ],
    );
  }

  Widget _recapDrillingDataPage() {
    const chartNames = [
      'Measured Depth',
      'ROP',
      'Rotary Speed',
      'Weight on Bit',
    ];
    const chartColors = [
      Color(0xFF6EA7E8),
      Color(0xFF69C6DF),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Drilling Data',
          height: 430,
          child: Column(
            children: [
              for (var index = 0; index < chartNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalCostMiniChart(
                      chartNames[index],
                      chartColors[index],
                      const [
                        Offset(0.00, 0.85),
                        Offset(0.22, 0.72),
                        Offset(0.45, 0.74),
                        Offset(0.62, 0.42),
                        Offset(0.82, 0.28),
                        Offset(1.00, 0.18),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Drilling Data plots measured depth, ROP, rotary speed, weight on bit, and other selected drilling parameters across the recap range.',
        ),
        const SizedBox(height: 8),
        _manualOptionRow('Plot planned data range', checked: true),
        _manualOptionRow('Show mud type indication', checked: true),
      ],
    );
  }

  Widget _recapMudPropertiesPage() {
    const chartNames = [
      'Mud Weight (ppg)',
      'Plastic Viscosity (cP)',
      'Yield Point (lbf/100ft2)',
      'Funnel Viscosity (sec/qt)',
    ];
    const chartColors = [
      Color(0xFF6EA7E8),
      Color(0xFF69C6DF),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
    ];
    const chartPoints = [
      [
        Offset(0.00, 0.78),
        Offset(0.18, 0.73),
        Offset(0.36, 0.66),
        Offset(0.55, 0.66),
        Offset(0.76, 0.47),
        Offset(1.00, 0.43),
      ],
      [
        Offset(0.00, 0.78),
        Offset(0.22, 0.70),
        Offset(0.40, 0.50),
        Offset(0.61, 0.58),
        Offset(0.82, 0.39),
        Offset(1.00, 0.46),
      ],
      [
        Offset(0.00, 0.58),
        Offset(0.17, 0.70),
        Offset(0.34, 0.30),
        Offset(0.53, 0.48),
        Offset(0.74, 0.38),
        Offset(1.00, 0.53),
      ],
      [
        Offset(0.00, 0.74),
        Offset(0.18, 0.52),
        Offset(0.36, 0.40),
        Offset(0.55, 0.56),
        Offset(0.77, 0.27),
        Offset(1.00, 0.35),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Mud Properties',
          height: 470,
          child: Column(
            children: [
              SizedBox(
                height: 25,
                child: Row(
                  children: [
                    _manualLegendItem('Water-based', const Color(0xFF6EA7E8)),
                    const SizedBox(width: 18),
                    _manualLegendItem('Oil-based', const Color(0xFF7DB56A)),
                    const Spacer(),
                    Text(
                      'Sample 1',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < chartNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalCostMiniChart(
                      chartNames[index],
                      chartColors[index],
                      chartPoints[index],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Mud Properties shows how the selected fluid properties change through the recap period. The plotted sample, property lines, limits, and planned ranges can be configured from Recap Options.',
        ),
        const SizedBox(height: 14),
        _recapMudPropertiesOptionsPreview(),
        const SizedBox(height: 14),
        _manualParagraph(
          'Use the Graph page to select the mud-property lines and sample displayed in the recap. Limits and planned ranges can be enabled independently without changing the report data.',
        ),
      ],
    );
  }

  Widget _recapSolidAnalysisPage() {
    const chartNames = [
      'Oil Phase (% vol)',
      'Water Phase (% vol)',
      'Low Gravity Solids (% vol)',
      'High Gravity Solids (% vol)',
      'Total Solids (% vol)',
    ];
    const chartColors = [
      Color(0xFF6EA7E8),
      Color(0xFF69C6DF),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
      Color(0xFF9B7BC3),
    ];
    const chartPoints = [
      [
        Offset(0.00, 0.66),
        Offset(0.18, 0.52),
        Offset(0.38, 0.56),
        Offset(0.58, 0.46),
        Offset(0.78, 0.55),
        Offset(0.94, 0.35),
        Offset(1.00, 0.42),
      ],
      [
        Offset(0.00, 0.72),
        Offset(0.18, 0.58),
        Offset(0.38, 0.60),
        Offset(0.58, 0.48),
        Offset(0.78, 0.57),
        Offset(0.94, 0.38),
        Offset(1.00, 0.44),
      ],
      [
        Offset(0.00, 0.80),
        Offset(0.22, 0.72),
        Offset(0.40, 0.70),
        Offset(0.40, 0.30),
        Offset(0.68, 0.28),
        Offset(0.92, 0.36),
        Offset(1.00, 0.48),
      ],
      [
        Offset(0.00, 0.82),
        Offset(0.20, 0.65),
        Offset(0.40, 0.64),
        Offset(0.40, 0.24),
        Offset(0.68, 0.22),
        Offset(0.92, 0.31),
        Offset(1.00, 0.45),
      ],
      [
        Offset(0.00, 0.76),
        Offset(0.18, 0.58),
        Offset(0.40, 0.55),
        Offset(0.40, 0.33),
        Offset(0.68, 0.34),
        Offset(0.92, 0.40),
        Offset(1.00, 0.50),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Solid Analysis',
          height: 430,
          child: Column(
            children: [
              for (var index = 0; index < chartNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalCostMiniChart(
                      chartNames[index],
                      chartColors[index],
                      chartPoints[index],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Solid Analysis tracks the calculated liquid phases, low- and high-gravity solids, and total solids through the selected recap period.',
        ),
      ],
    );
  }

  Widget _recapHydraulicsPage() {
    const chartNames = [
      'Flow Rate (gpm)',
      'Pump Pressure (psi)',
      'Bit Impact Force (lbf)',
      'Hydraulic Horsepower per Area',
      'Bottom-Hole ECD (ppg)',
    ];
    const chartColors = [
      Color(0xFF6EA7E8),
      Color(0xFF69C6DF),
      Color(0xFF6EA7E8),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
    ];
    const chartPoints = [
      [
        Offset(0.00, 0.12),
        Offset(0.08, 0.72),
        Offset(0.23, 0.40),
        Offset(0.42, 0.42),
        Offset(0.47, 0.82),
        Offset(0.57, 0.52),
        Offset(0.78, 0.50),
        Offset(1.00, 0.58),
      ],
      [
        Offset(0.00, 0.88),
        Offset(0.09, 0.48),
        Offset(0.28, 0.48),
        Offset(0.45, 0.78),
        Offset(0.58, 0.32),
        Offset(0.78, 0.26),
        Offset(1.00, 0.28),
      ],
      [
        Offset(0.00, 0.20),
        Offset(0.08, 0.74),
        Offset(0.22, 0.40),
        Offset(0.42, 0.43),
        Offset(0.49, 0.80),
        Offset(0.60, 0.46),
        Offset(0.84, 0.50),
        Offset(1.00, 0.62),
      ],
      [
        Offset(0.00, 0.22),
        Offset(0.08, 0.82),
        Offset(0.22, 0.58),
        Offset(0.42, 0.59),
        Offset(0.48, 0.86),
        Offset(0.58, 0.60),
        Offset(0.82, 0.60),
        Offset(1.00, 0.72),
      ],
      [
        Offset(0.00, 0.62),
        Offset(0.18, 0.54),
        Offset(0.38, 0.48),
        Offset(0.58, 0.43),
        Offset(0.78, 0.45),
        Offset(1.00, 0.46),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Hydraulics',
          height: 430,
          child: Column(
            children: [
              for (var index = 0; index < chartNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalCostMiniChart(
                      chartNames[index],
                      chartColors[index],
                      chartPoints[index],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Hydraulics presents the calculated circulation response, including flow rate, pump pressure, bit hydraulics, and bottom-hole ECD across the recap range. Limits can be enabled from Recap Options - Graph.',
        ),
        const SizedBox(height: 14),
        _recapMudPropertiesOptionsPreview(),
        const SizedBox(height: 14),
        _manualParagraph(
          'When limit display is enabled, the graph highlights conditions where a calculated value moves outside its configured operating boundary, such as ECD approaching the pore-pressure or fracture-gradient range.',
        ),
      ],
    );
  }

  Widget _recapVolumePage() {
    const chartNames = [
      'Daily Volume Change (bbl)',
      'Active System Volume (bbl)',
      'Reserve Volume (bbl)',
      'Transferred Volume (bbl)',
      'Unaccounted Volume (bbl)',
    ];
    const chartColors = [
      Color(0xFF6EA7E8),
      Color(0xFF69C6DF),
      Color(0xFF6EA7E8),
      Color(0xFFE9A84A),
      Color(0xFF9B7BC3),
    ];
    const chartPoints = [
      [
        Offset(0.00, 0.82),
        Offset(0.12, 0.38),
        Offset(0.24, 0.62),
        Offset(0.42, 0.68),
        Offset(0.62, 0.48),
        Offset(0.82, 0.58),
        Offset(1.00, 0.45),
      ],
      [
        Offset(0.00, 0.46),
        Offset(0.18, 0.47),
        Offset(0.38, 0.40),
        Offset(0.58, 0.55),
        Offset(0.78, 0.52),
        Offset(1.00, 0.64),
      ],
      [
        Offset(0.00, 0.18),
        Offset(0.12, 0.68),
        Offset(0.30, 0.50),
        Offset(0.48, 0.73),
        Offset(0.72, 0.74),
        Offset(0.90, 0.45),
        Offset(1.00, 0.70),
      ],
      [
        Offset(0.00, 0.25),
        Offset(0.14, 0.80),
        Offset(0.36, 0.79),
        Offset(0.58, 0.72),
        Offset(0.80, 0.76),
        Offset(0.92, 0.48),
        Offset(1.00, 0.74),
      ],
      [
        Offset(0.00, 0.64),
        Offset(0.22, 0.62),
        Offset(0.44, 0.66),
        Offset(0.66, 0.59),
        Offset(0.84, 0.63),
        Offset(1.00, 0.60),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Volume',
          height: 430,
          child: Column(
            children: [
              for (var index = 0; index < chartNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalCostMiniChart(
                      chartNames[index],
                      chartColors[index],
                      chartPoints[index],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Volume follows additions, losses, transfers, reserve movement, and active-system balance through the selected recap range. Use the detail view to review the values behind each plotted change.',
        ),
        const SizedBox(height: 14),
        _recapExplorerPreview(
          selectedItem: 'Volume',
          height: 340,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 730,
              child: _recapDataTable(
                const [
                  'Report',
                  'Start',
                  'Daily Add.',
                  'Daily Loss',
                  'Transfer In',
                  'Transfer Out',
                  'End',
                  'Unaccounted',
                ],
                const [
                  ['12', '1,245', '82', '18', '0', '35', '1,274', '0.5'],
                  ['13', '1,274', '45', '22', '60', '0', '1,357', '-1.0'],
                  ['14', '1,357', '38', '16', '0', '42', '1,337', '0.0'],
                  ['15', '1,337', '70', '28', '25', '0', '1,404', '1.5'],
                  ['16', '1,404', '32', '19', '0', '55', '1,362', '0.0'],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recapUsagePage() {
    const productNames = [
      'Barite Usage (sacks)',
      'Base Fluid Usage (bbl)',
      'Viscosifier Usage (sacks)',
      'Fluid-Loss Additive Usage (sacks)',
      'Shale Inhibitor Usage (drums)',
    ];
    const productColors = [
      Color(0xFF69C6DF),
      Color(0xFF6EA7E8),
      Color(0xFF7DB56A),
      Color(0xFFE9A84A),
      Color(0xFF9B7BC3),
    ];
    const usagePoints = [
      [
        Offset(0.00, 0.28),
        Offset(0.18, 0.42),
        Offset(0.36, 0.54),
        Offset(0.52, 0.32),
        Offset(0.68, 0.48),
        Offset(0.84, 0.36),
        Offset(1.00, 0.40),
      ],
      [
        Offset(0.00, 0.34),
        Offset(0.18, 0.30),
        Offset(0.36, 0.38),
        Offset(0.52, 0.44),
        Offset(0.68, 0.28),
        Offset(0.84, 0.46),
        Offset(1.00, 0.35),
      ],
      [
        Offset(0.00, 0.42),
        Offset(0.20, 0.43),
        Offset(0.40, 0.40),
        Offset(0.60, 0.45),
        Offset(0.80, 0.41),
        Offset(1.00, 0.44),
      ],
      [
        Offset(0.00, 0.72),
        Offset(0.18, 0.70),
        Offset(0.36, 0.68),
        Offset(0.52, 0.30),
        Offset(0.68, 0.42),
        Offset(0.84, 0.34),
        Offset(1.00, 0.46),
      ],
      [
        Offset(0.00, 0.48),
        Offset(0.20, 0.46),
        Offset(0.40, 0.50),
        Offset(0.60, 0.44),
        Offset(0.80, 0.47),
        Offset(1.00, 0.45),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Usage',
          height: 430,
          child: Column(
            children: [
              for (var index = 0; index < productNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalCostMiniChart(
                      productNames[index],
                      productColors[index],
                      usagePoints[index],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Usage compares daily received, consumed, and returned quantities for the products selected in Pad Inventory plotting. Up to five configured products can be reviewed together across the recap period.',
        ),
      ],
    );
  }

  Widget _recapConcentrationPage() {
    const productNames = [
      'Weighting Agent (lb/bbl)',
      'Primary Emulsifier (lb/bbl)',
      'Shale Inhibitor (% vol)',
      'Fluid-Loss Additive (lb/bbl)',
      'Lime Concentration (lb/bbl)',
    ];
    const productColors = [
      Color(0xFF69C6DF),
      Color(0xFF6EA7E8),
      Color(0xFF9B7BC3),
      Color(0xFF7DB56A),
      Color(0xFFE9A84A),
    ];
    const concentrationPoints = [
      [
        Offset(0.00, 0.78),
        Offset(0.22, 0.72),
        Offset(0.42, 0.70),
        Offset(0.58, 0.48),
        Offset(0.72, 0.32),
        Offset(0.86, 0.26),
        Offset(1.00, 0.20),
      ],
      [
        Offset(0.00, 0.74),
        Offset(0.18, 0.70),
        Offset(0.34, 0.56),
        Offset(0.48, 0.68),
        Offset(0.66, 0.44),
        Offset(0.82, 0.22),
        Offset(1.00, 0.30),
      ],
      [
        Offset(0.00, 0.82),
        Offset(0.10, 0.38),
        Offset(0.30, 0.40),
        Offset(0.48, 0.74),
        Offset(0.66, 0.78),
        Offset(0.84, 0.62),
        Offset(1.00, 0.68),
      ],
      [
        Offset(0.00, 0.82),
        Offset(0.32, 0.80),
        Offset(0.48, 0.48),
        Offset(0.62, 0.56),
        Offset(0.76, 0.34),
        Offset(0.90, 0.26),
        Offset(1.00, 0.18),
      ],
      [
        Offset(0.00, 0.58),
        Offset(0.20, 0.54),
        Offset(0.40, 0.57),
        Offset(0.60, 0.50),
        Offset(0.80, 0.46),
        Offset(1.00, 0.48),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Concentration',
          height: 450,
          child: Column(
            children: [
              Container(
                height: 30,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Row(
                  children: [
                    Text(
                      'Product Concentration - Active System',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 118,
                      height: 21,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.tableBorderBlue),
                      ),
                      child: Text(
                        'Active System',
                        style: AppTheme.bodyLarge.copyWith(fontSize: 8),
                      ),
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < productNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalCostMiniChart(
                      productNames[index],
                      productColors[index],
                      concentrationPoints[index],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Concentration displays the calculated history of up to five inventory products selected for concentration tracking. Choose the active system or an available pit to review how each product level changes during the recap period.',
        ),
        const SizedBox(height: 8),
        _manualParagraph(
          'Use the Concentration table view when report-by-report values are required instead of the graphical trend.',
        ),
      ],
    );
  }

  Widget _recapTimeDistributionPage() {
    const activities = [
      ('Drilling', 10.8, 45.0),
      ('Tripping', 4.2, 17.5),
      ('Rig-up / Service', 2.7, 11.3),
      ('Circulating', 2.1, 8.8),
      ('Running Casing', 1.5, 6.3),
      ('Testing', 1.1, 4.6),
      ('Cementing', 0.9, 3.8),
      ('Other', 0.7, 2.9),
    ];
    const timelineSegments = [
      [[0.03, 0.08], [0.18, 0.10], [0.40, 0.08], [0.62, 0.13], [0.84, 0.10]],
      [[0.12, 0.04], [0.32, 0.07], [0.55, 0.06], [0.76, 0.08]],
      [[0.06, 0.03], [0.25, 0.04], [0.48, 0.03], [0.70, 0.05], [0.91, 0.04]],
      [[0.19, 0.05], [0.43, 0.08], [0.66, 0.04], [0.82, 0.07]],
      [[0.35, 0.05], [0.72, 0.06]],
      [[0.08, 0.04], [0.50, 0.06], [0.88, 0.04]],
      [[0.46, 0.05], [0.78, 0.04]],
      [[0.27, 0.04], [0.59, 0.05], [0.93, 0.03]],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Time Distribution',
          height: 430,
          child: Column(
            children: [
              Text(
                'Operational Time Distribution',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppTheme.tableBorderBlue),
                        ),
                        child: Column(
                          children: [
                            for (var index = 0; index < activities.length; index++)
                              Expanded(
                                child: _recapActivityTimelineRow(
                                  activities[index].$1,
                                  timelineSegments[index],
                                ),
                              ),
                            Text(
                              'Report Day',
                              style: AppTheme.bodyLarge.copyWith(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 10, 10, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppTheme.tableBorderBlue),
                        ),
                        child: Column(
                          children: [
                            for (final activity in activities) ...[
                              _timeDistributionBar(
                                activity.$1,
                                activity.$2,
                                activity.$3,
                              ),
                              if (activity != activities.last)
                                const SizedBox(height: 10),
                            ],
                            const Spacer(),
                            _timeDistributionAxis(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Time Distribution compares the duration of recorded operations by report day and summarizes each activity as a share of the selected recap period.',
        ),
      ],
    );
  }

  Widget _recapActivityTimelineRow(
    String label,
    List<List<double>> segments,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(fontSize: 8),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  border: Border.all(color: const Color(0xFFD8E1EC)),
                ),
                child: Stack(
                  children: [
                    for (final segment in segments)
                      Positioned(
                        left: constraints.maxWidth * segment[0],
                        top: 3,
                        width: constraints.maxWidth * segment[1],
                        height: 14,
                        child: Container(color: const Color(0xFF76C5E3)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _recapSolidControlEquipmentPage() {
    const equipmentNames = [
      'Shale Shakers - Operating Time (hr)',
      'Mud Cleaner - Operating Time (hr)',
      'Centrifuge - Operating Time (hr)',
      'Vacuum Degasser - Operating Time (hr)',
    ];
    const equipmentColors = [
      Color(0xFF69C6DF),
      Color(0xFF6EA7E8),
      Color(0xFF7DB56A),
      Color(0xFFE9A84A),
    ];
    const equipmentPoints = [
      [
        Offset(0.00, 0.24),
        Offset(0.30, 0.25),
        Offset(0.42, 0.82),
        Offset(0.63, 0.84),
        Offset(0.66, 0.72),
        Offset(0.82, 0.86),
        Offset(1.00, 0.86),
      ],
      [
        Offset(0.00, 0.84),
        Offset(0.30, 0.84),
        Offset(0.42, 0.24),
        Offset(0.55, 0.64),
        Offset(0.64, 0.46),
        Offset(0.66, 0.86),
        Offset(1.00, 0.86),
      ],
      [
        Offset(0.00, 0.86),
        Offset(0.46, 0.86),
        Offset(0.52, 0.40),
        Offset(0.82, 0.40),
        Offset(0.86, 0.86),
        Offset(1.00, 0.86),
      ],
      [
        Offset(0.00, 0.86),
        Offset(0.82, 0.86),
        Offset(0.88, 0.28),
        Offset(1.00, 0.26),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Solid Control Equipment',
          height: 430,
          child: Column(
            children: [
              Container(
                height: 26,
                margin: const EdgeInsets.only(bottom: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Text(
                  'Solid Control Equipment Utilization',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (var index = 0; index < equipmentNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _totalCostMiniChart(
                      equipmentNames[index],
                      equipmentColors[index],
                      equipmentPoints[index],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Solid Control Equipment summarizes the recorded operating hours of each configured unit across the recap range, making equipment usage and inactive periods easy to compare.',
        ),
      ],
    );
  }

  Widget _recapBitPage() {
    const parameterNames = [
      'Bit Number',
      'Bit Size (in.)',
      'Total Flow Area (in2)',
      'Depth In / Depth Out (ft)',
      'Cumulative Bit Depth (ft)',
    ];
    const parameterColors = [
      Color(0xFF69C6DF),
      Color(0xFF6EA7E8),
      Color(0xFF7DB56A),
      Color(0xFFE9A84A),
      Color(0xFF9B7BC3),
    ];
    const parameterPoints = [
      [
        Offset(0.00, 0.74),
        Offset(0.28, 0.74),
        Offset(0.36, 0.56),
        Offset(0.42, 0.38),
        Offset(0.65, 0.38),
        Offset(0.72, 0.22),
        Offset(0.94, 0.22),
        Offset(1.00, 0.12),
      ],
      [
        Offset(0.00, 0.30),
        Offset(0.42, 0.30),
        Offset(0.42, 0.58),
        Offset(1.00, 0.58),
      ],
      [
        Offset(0.00, 0.25),
        Offset(0.30, 0.25),
        Offset(0.36, 0.32),
        Offset(0.42, 0.78),
        Offset(0.86, 0.78),
        Offset(0.96, 0.18),
        Offset(1.00, 0.70),
      ],
      [
        Offset(0.00, 0.82),
        Offset(0.30, 0.82),
        Offset(0.36, 0.54),
        Offset(0.42, 0.54),
        Offset(0.68, 0.54),
        Offset(0.74, 0.32),
        Offset(0.94, 0.32),
        Offset(1.00, 0.18),
      ],
      [
        Offset(0.00, 0.88),
        Offset(0.32, 0.68),
        Offset(0.38, 0.82),
        Offset(0.42, 0.60),
        Offset(0.66, 0.42),
        Offset(0.84, 0.26),
        Offset(1.00, 0.14),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Bit',
          height: 430,
          child: Column(
            children: [
              Container(
                height: 26,
                margin: const EdgeInsets.only(bottom: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Text(
                  'Bit Performance and Geometry',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (var index = 0; index < parameterNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalCostMiniChart(
                      parameterNames[index],
                      parameterColors[index],
                      parameterPoints[index],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Bit summarizes bit changes, geometry, total flow area, and drilled-depth progression across the selected recap period.',
        ),
      ],
    );
  }

  Widget _recapRemarksPage() {
    const remarkGroups = [
      ('Daily Remarks', [48.0, 62.0, 74.0, 68.0, 82.0, 55.0, 72.0, 44.0, 60.0, 76.0, 52.0, 66.0]),
      ('Operational Notes', [35.0, 58.0, 42.0, 28.0, 50.0, 46.0, 64.0, 70.0, 55.0, 38.0, 62.0, 48.0]),
      ('Safety Observations', [22.0, 52.0, 18.0, 44.0, 48.0, 36.0, 58.0, 32.0, 60.0, 42.0, 30.0, 54.0]),
      ('Keyword Matches', [14.0, 24.0, 18.0, 28.0, 22.0, 34.0, 26.0, 20.0, 30.0, 24.0, 32.0, 18.0]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Remarks',
          height: 420,
          child: Column(
            children: [
              Text(
                'Remark Activity by Report Day',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final group in remarkGroups)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _recapRemarksBarPanel(group.$1, group.$2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Remarks summarizes the amount of narrative entered for each report and separates operational notes, safety observations, and tracked keyword activity for easier review.',
        ),
        const SizedBox(height: 14),
        _recapExplorerPreview(
          selectedItem: 'Remarks',
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Text(
                  'Keyword Review - Manual Selection',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _recapDataTable(
                  const [
                    'Keyword',
                    'Recommended Treatment',
                    'Remarks',
                    'Recap Remarks',
                    'Overall',
                  ],
                  const [
                    ['pressure', 'Review circulation', '3', '4', '7'],
                    ['loss', 'Check loss response', '2', '3', '5'],
                    ['return', 'Verify flow balance', '4', '2', '6'],
                    ['safety', 'Review observation', '3', '3', '6'],
                    ['gas', 'Check monitoring notes', '1', '2', '3'],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _manualParagraph(
          'Keyword review helps locate repeated subjects across daily remarks so the user can investigate operational patterns and recurring safety concerns.',
        ),
      ],
    );
  }

  Widget _recapRemarksBarPanel(String title, List<double> values) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              title,
              maxLines: 2,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final value in values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FractionallySizedBox(
                        heightFactor: (value / 100)
                            .clamp(0.12, 1.0)
                            .toDouble(),
                        alignment: Alignment.bottomCenter,
                        child: Container(color: const Color(0xFF9EB7CC)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recapIntervalPage() {
    const overviewNames = [
      'Mud Treated',
      'Mud Usage',
      'Product Cost',
      'Service Cost',
      'Engineering Cost',
      'Total Cost',
    ];
    const overviewColors = [
      Color(0xFF69C6DF),
      Color(0xFF6EA7E8),
      Color(0xFF7DB56A),
      Color(0xFFE9A84A),
      Color(0xFF9B7BC3),
      Color(0xFF4F91C7),
    ];
    const overviewPoints = [
      [Offset(0.00, 0.18), Offset(0.36, 0.18), Offset(0.36, 0.52), Offset(0.72, 0.52), Offset(0.72, 0.84), Offset(1.00, 0.84)],
      [Offset(0.00, 0.26), Offset(0.42, 0.26), Offset(0.42, 0.48), Offset(0.76, 0.48), Offset(0.76, 0.76), Offset(1.00, 0.76)],
      [Offset(0.00, 0.22), Offset(0.30, 0.22), Offset(0.30, 0.44), Offset(0.68, 0.44), Offset(0.68, 0.82), Offset(1.00, 0.82)],
      [Offset(0.00, 0.32), Offset(0.38, 0.32), Offset(0.38, 0.58), Offset(0.72, 0.58), Offset(0.72, 0.78), Offset(1.00, 0.78)],
      [Offset(0.00, 0.20), Offset(0.28, 0.20), Offset(0.28, 0.46), Offset(0.66, 0.46), Offset(0.66, 0.80), Offset(1.00, 0.80)],
      [Offset(0.00, 0.16), Offset(0.34, 0.16), Offset(0.34, 0.40), Offset(0.70, 0.40), Offset(0.70, 0.74), Offset(1.00, 0.74)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Interval',
          height: 410,
          child: Column(
            children: [
              Text(
                'Interval Performance Overview',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var index = 0; index < overviewNames.length; index++) ...[
                      Expanded(
                        child: _totalCostMiniChart(
                          overviewNames[index],
                          overviewColors[index],
                          overviewPoints[index],
                        ),
                      ),
                      if (index != overviewNames.length - 1)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Interval provides a compact comparison of treated volume, mud usage, and cost performance for each completed well section.',
        ),
        const SizedBox(height: 10),
        _manualParagraph(
          'The detail view breaks the same interval totals into dates, depths, fluid movement, product usage, and cost categories.',
        ),
        const SizedBox(height: 14),
        _recapExplorerPreview(
          selectedItem: 'Interval',
          height: 390,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Interval Summary',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              _recapDataTable(
                const ['Interval', 'Start', 'End', 'MD In', 'MD Out', 'Total Cost'],
                const [
                  ['Surface', '04/02', '04/05', '0', '3,120', '18,450'],
                  ['Intermediate', '04/06', '04/12', '3,120', '8,640', '36,780'],
                  ['Build', '04/13', '04/18', '8,640', '12,450', '28,960'],
                  ['Lateral', '04/19', '04/27', '12,450', '21,800', '47,320'],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Mud Movement and Product Usage',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _recapDataTable(
                  const ['Interval', 'Start Vol.', 'Added', 'Lost', 'Transferred', 'Mud Treated'],
                  const [
                    ['Surface', '620', '340', '22', '0', '938'],
                    ['Intermediate', '938', '510', '48', '75', '1,325'],
                    ['Build', '1,325', '280', '35', '120', '1,450'],
                    ['Lateral', '1,450', '620', '96', '180', '1,794'],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recapSurveyPage() {
    const actualColor = Color(0xFF4F91C7);
    const plannedColor = Color(0xFFE45B52);
    const sectionPoints = [
      Offset(0.02, 0.08),
      Offset(0.04, 0.26),
      Offset(0.08, 0.42),
      Offset(0.18, 0.55),
      Offset(0.42, 0.60),
      Offset(0.72, 0.61),
      Offset(1.00, 0.62),
    ];
    const planPoints = [
      Offset(0.08, 0.80),
      Offset(0.38, 0.80),
      Offset(0.62, 0.78),
      Offset(0.78, 0.62),
      Offset(0.82, 0.40),
      Offset(0.84, 0.18),
    ];
    const doglegPoints = [
      Offset(0.00, 0.22),
      Offset(0.08, 0.34),
      Offset(0.14, 0.28),
      Offset(0.22, 0.46),
      Offset(0.34, 0.32),
      Offset(0.44, 0.52),
      Offset(0.58, 0.44),
      Offset(0.72, 0.64),
      Offset(0.86, 0.58),
      Offset(1.00, 0.76),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Survey',
          height: 430,
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: _totalCostMiniChart(
                        'Section View - TVD vs. Displacement',
                        actualColor,
                        sectionPoints,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _totalCostMiniChart(
                        'Plan View - North / East',
                        plannedColor,
                        planPoints,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: _totalCostMiniChart(
                  'Dogleg Severity vs. Measured Depth',
                  actualColor,
                  doglegPoints,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _manualLegendItem('Actual survey', actualColor),
                  const SizedBox(width: 22),
                  _manualLegendItem('Planned survey', plannedColor),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Survey compares the reported well path with the planned trajectory from Well - Survey. Section, plan, and dogleg views make directional departure and trajectory changes easier to review across the recap range.',
        ),
      ],
    );
  }

  Widget _recapCustomizedPage() {
    const plotNames = [
      'Mud Weight (ppg)',
      'Cumulative Product Cost',
      'Pump Pressure (psi)',
      'Rotary Speed (rpm)',
      'Rate of Penetration (ft/hr)',
    ];
    const plotColors = [
      Color(0xFF69C6DF),
      Color(0xFF6EA7E8),
      Color(0xFF7DB56A),
      Color(0xFFE9A84A),
      Color(0xFF9B7BC3),
    ];
    const plotPoints = [
      [Offset(0.00, 0.52), Offset(0.20, 0.50), Offset(0.40, 0.54), Offset(0.60, 0.48), Offset(0.80, 0.46), Offset(1.00, 0.44)],
      [Offset(0.00, 0.84), Offset(0.30, 0.80), Offset(0.52, 0.70), Offset(0.62, 0.34), Offset(0.82, 0.24), Offset(1.00, 0.18)],
      [Offset(0.00, 0.82), Offset(0.10, 0.48), Offset(0.22, 0.36), Offset(0.30, 0.78), Offset(0.38, 0.28), Offset(0.48, 0.76), Offset(0.62, 0.42), Offset(0.78, 0.30), Offset(1.00, 0.46)],
      [Offset(0.00, 0.78), Offset(0.12, 0.28), Offset(0.26, 0.30), Offset(0.36, 0.72), Offset(0.48, 0.38), Offset(0.62, 0.70), Offset(0.76, 0.24), Offset(0.90, 0.32), Offset(1.00, 0.74)],
      [Offset(0.00, 0.70), Offset(0.10, 0.20), Offset(0.24, 0.48), Offset(0.38, 0.56), Offset(0.52, 0.46), Offset(0.66, 0.82), Offset(0.78, 0.30), Offset(0.90, 0.62), Offset(1.00, 0.38)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Customized',
          height: 440,
          child: Column(
            children: [
              Container(
                height: 28,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Row(
                  children: [
                    Text(
                      'Customized Graph Set',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '5 selected plots',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < plotNames.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _totalCostMiniChart(
                      plotNames[index],
                      plotColors[index],
                      plotPoints[index],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Customized combines up to five user-selected recap parameters in one view. The series can mix drilling, fluid, cost, hydraulics, or calculated results for focused comparison.',
        ),
        const SizedBox(height: 14),
        _recapMudPropertiesOptionsPreview(),
        const SizedBox(height: 14),
        _manualParagraph(
          'Configure the Customized row in Recap Options - Graph to choose the plotted parameters and their display order.',
        ),
      ],
    );
  }

  Widget _recapEngineerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapExplorerPreview(
          selectedItem: 'Engineer',
          height: 370,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Row(
                  children: [
                    Text(
                      'Engineer Assignment Summary',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _manualLegendItem('On-well coverage', const Color(0xFF69C6DF)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _recapDataTable(
                  const [
                    'Engineer',
                    'Role',
                    'Office',
                    'Contact',
                    'Rotation',
                    'Days',
                    'Coverage',
                  ],
                  const [
                    ['A. Morgan', 'Lead Engineer', 'Houston', 'Ext. 214', 'Day', '6', '24%'],
                    ['R. Patel', 'Mud Engineer', 'Field', 'Ext. 328', 'Night', '5', '20%'],
                    ['J. Rivera', 'Mud Engineer', 'Field', 'Ext. 196', 'Day', '7', '28%'],
                    ['S. Chen', 'Support Engineer', 'Calgary', 'Ext. 407', 'Remote', '4', '16%'],
                    ['D. Walker', 'Relief Engineer', 'Field', 'Ext. 253', 'Relief', '3', '12%'],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Row(
                  children: [
                    Text(
                      'Total covered period',
                      style: AppTheme.bodyLarge.copyWith(fontSize: 9),
                    ),
                    const Spacer(),
                    Text(
                      '25 engineer-days  |  100% assigned coverage',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.panelHeaderBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Engineer summarizes the personnel assigned during the selected recap period, including role, rotation, days on the well, and each engineer\'s share of the recorded coverage.',
        ),
      ],
    );
  }

  Widget _wellComparisonWindowsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Well Comparison Windows provides two areas for configuring and reviewing multi-well results:',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 12,
          children: [
            InkWell(
              onTap: () => onNavigate('Comparison Toolbar'),
              child: Text(
                'Toolbar',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            InkWell(
              onTap: () => onNavigate('Comparison Job Explorer'),
              child: Text(
                'Comparison Job Explorer',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: 640,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFD),
            border: Border.all(color: AppTheme.tableBorderBlue),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.compare_arrows,
                size: 30,
                color: AppTheme.panelHeaderBlue,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Use the toolbar to manage the comparison workspace, then select a result category from Comparison Job Explorer to review wells side by side.',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonToolbarPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _comparisonToolbarPreview(
          activeTab: 'Home',
          actions: const [
            (Icons.arrow_back_outlined, 'Return to Input'),
            (Icons.tune_outlined, 'Comparison Options'),
          ],
        ),
        const SizedBox(height: 16),
        _numberedHelp(
          '1.',
          'Return to Input closes the comparison workspace and returns to the main well and report input area.',
        ),
        _numberedHelp(
          '2.',
          'Comparison Options selects the result sections included in the comparison workspace and exported report.',
        ),
        const SizedBox(height: 18),
        _comparisonOptionsPreview(),
        const SizedBox(height: 24),
        _comparisonToolbarPreview(
          activeTab: 'Report',
          actions: const [
            (Icons.table_view_outlined, 'Well Comparison Report'),
          ],
        ),
        const SizedBox(height: 16),
        _manualParagraph(
          'Well Comparison Report creates a spreadsheet containing the selected wells and enabled comparison sections. Page size and output layout follow the current report-format settings.',
        ),
        const SizedBox(height: 14),
        _comparisonReportPreview(),
        const SizedBox(height: 24),
        _comparisonToolbarPreview(
          activeTab: 'Utilities',
          actions: const [
            (Icons.engineering_outlined, 'Engineering Tools'),
            (Icons.swap_horiz_outlined, 'Unit Conversion'),
            (Icons.calculate_outlined, 'Calculator'),
            (Icons.note_alt_outlined, 'Notepad'),
          ],
        ),
        const SizedBox(height: 14),
        _manualParagraph(
          'Utilities provides engineering calculations, unit conversion, the system calculator, and quick notepad access without leaving the comparison workflow.',
        ),
        const SizedBox(height: 22),
        _comparisonToolbarPreview(
          activeTab: 'Help',
          actions: const [
            (Icons.menu_book_outlined, 'User Manual'),
            (Icons.info_outline, 'About'),
            (Icons.sort_by_alpha_outlined, 'Abbreviations'),
          ],
        ),
        const SizedBox(height: 14),
        _manualParagraph(
          'Help opens the user manual, application information, and abbreviation reference.',
        ),
      ],
    );
  }

  Widget _comparisonJobExplorerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Comparison Job Explorer provides the following side-by-side well analysis pages:',
        ),
        const SizedBox(height: 8),
        for (final entry in _comparisonJobExplorerLinks.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: () => onNavigate(entry.value),
              child: Text(
                entry.key,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _comparisonSummaryPage() {
    const wells = [
      ('North-01', '10,850 ft', Color(0xFF8B5A2B), false),
      ('North-02', '9,640 ft', Color(0xFFB06D32), true),
      ('West-03', '8,920 ft', Color(0xFF93613A), false),
      ('Central-04', '12,420 ft', Color(0xFFA05A2C), true),
      ('East-05', '15,760 ft', Color(0xFF7C4A25), true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Summary presents the selected well profiles together so casing programs, total depths, and trajectory differences can be reviewed at a glance.',
        ),
        const SizedBox(height: 14),
        _comparisonExplorerPreview(
          selectedItem: 'Summary',
          height: 440,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < wells.length; index++) ...[
                Expanded(
                  child: _comparisonWellSchematic(
                    wells[index].$1,
                    wells[index].$2,
                    wells[index].$3,
                    wells[index].$4,
                  ),
                ),
                if (index != wells.length - 1) const SizedBox(width: 7),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonCostPage() {
    const wells = [
      ('North-01', 10850.0, 25.0, 68400.0, 18750.0, 8.03, 3486.0),
      ('North-02', 9640.0, 22.0, 55200.0, 16400.0, 7.43, 3255.0),
      ('West-03', 8920.0, 19.0, 47100.0, 13950.0, 6.84, 3213.0),
      ('Central-04', 12420.0, 28.0, 79300.0, 22400.0, 8.19, 3632.0),
      ('East-05', 15760.0, 31.0, 94600.0, 26800.0, 7.70, 3916.0),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Cost compares total and normalized expenditure for each selected well. Category and mud-system costs can be reviewed together to identify the main cost differences.',
        ),
        const SizedBox(height: 14),
        _comparisonExplorerPreview(
          selectedItem: 'Cost',
          height: 400,
          child: Column(
            children: [
              Container(
                height: 34,
                color: const Color(0xFFE7F1FB),
                child: Row(
                  children: [
                    _comparisonCostHeader('Well', flex: 2),
                    _comparisonCostHeader('MD (ft)'),
                    _comparisonCostHeader('Days'),
                    _comparisonCostHeader('Product Cost', flex: 2),
                    _comparisonCostHeader('Service Cost', flex: 2),
                    _comparisonCostHeader(r'$/ft'),
                    _comparisonCostHeader(r'$/day'),
                  ],
                ),
              ),
              for (final well in wells)
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFD5E0EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _comparisonCostTextCell(well.$1, flex: 2),
                        _comparisonCostBarCell(well.$2, 16000, const Color(0xFF82AFE0)),
                        _comparisonCostBarCell(well.$3, 32, const Color(0xFF8FC3E0)),
                        _comparisonCostBarCell(well.$4, 100000, const Color(0xFF78A8D8), flex: 2),
                        _comparisonCostBarCell(well.$5, 30000, const Color(0xFF8CCB96), flex: 2),
                        _comparisonCostBarCell(well.$6, 10, const Color(0xFFE4B36A)),
                        _comparisonCostBarCell(well.$7, 4200, const Color(0xFF9A87C2)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  _manualLegendItem('Product', const Color(0xFF78A8D8)),
                  _manualLegendItem('Service', const Color(0xFF8CCB96)),
                  _manualLegendItem('Daily rate', const Color(0xFF9A87C2)),
                  _manualLegendItem('Normalized cost', const Color(0xFFE4B36A)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonDrillingDataPage() {
    const parameterNames = [
      'Weight on Bit (klbf)',
      'Surface Weight (klbf)',
      'Pump Pressure (psi)',
      'Rotary Speed (rpm)',
      'ROP (ft/hr)',
    ];
    const parameterColors = [
      Color(0xFF4F91C7),
      Color(0xFF69C6DF),
      Color(0xFF7B86C8),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
    ];
    const parameterPoints = [
      [Offset(0.08, 0.05), Offset(0.12, 0.22), Offset(0.18, 0.36), Offset(0.42, 0.55), Offset(0.64, 0.68), Offset(0.80, 0.86), Offset(0.96, 0.92)],
      [Offset(0.18, 0.06), Offset(0.24, 0.24), Offset(0.38, 0.40), Offset(0.48, 0.58), Offset(0.30, 0.72), Offset(0.12, 0.88)],
      [Offset(0.10, 0.08), Offset(0.22, 0.26), Offset(0.38, 0.42), Offset(0.56, 0.58), Offset(0.36, 0.76), Offset(0.18, 0.90)],
      [Offset(0.24, 0.06), Offset(0.66, 0.20), Offset(0.72, 0.34), Offset(0.38, 0.46), Offset(0.64, 0.62), Offset(0.46, 0.78), Offset(0.70, 0.92)],
      [Offset(0.18, 0.06), Offset(0.24, 0.24), Offset(0.20, 0.40), Offset(0.16, 0.55), Offset(0.28, 0.70), Offset(0.82, 0.84), Offset(0.92, 0.92)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _comparisonExplorerPreview(
          selectedItem: 'Drilling Data',
          height: 430,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Drilling Parameters vs. Measured Depth',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          for (var index = 0; index < parameterNames.length; index++) ...[
                            Expanded(
                              child: _totalCostMiniChart(
                                parameterNames[index],
                                parameterColors[index],
                                parameterPoints[index],
                              ),
                            ),
                            if (index != parameterNames.length - 1)
                              const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 5,
                      alignment: WrapAlignment.center,
                      children: [
                        _manualLegendItem('North-01', const Color(0xFF4F91C7)),
                        _manualLegendItem('North-02', const Color(0xFF69C6DF)),
                        _manualLegendItem('West-03', const Color(0xFFE45B52)),
                        _manualLegendItem('Central-04', const Color(0xFF7DB56A)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                color: const Color(0xFFF1F5FA),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _concentrationViewTab('Graph', true),
                    const SizedBox(height: 5),
                    _concentrationViewTab('Table', false),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Drilling Data compares key operating parameters over the measured-depth range of each selected well, making changes in loading, pressure, rotation, and penetration rate easier to identify.',
        ),
        const SizedBox(height: 8),
        _manualParagraph(
          'Use the view tabs to switch between the combined graph and the underlying well-by-well values.',
        ),
      ],
    );
  }

  Widget _comparisonMudPropertiesPage() {
    const propertyNames = [
      'Mud Weight (ppg)',
      'Plastic Viscosity (cP)',
      'Yield Point (lbf/100ft2)',
      'Gel Strength 10s / 10m',
      'Water Content (%)',
    ];
    const propertyColors = [
      Color(0xFF4F91C7),
      Color(0xFF69C6DF),
      Color(0xFF7B86C8),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
    ];
    const propertyPoints = [
      [Offset(0.20, 0.06), Offset(0.30, 0.22), Offset(0.24, 0.38), Offset(0.52, 0.54), Offset(0.78, 0.62), Offset(0.82, 0.82), Offset(0.88, 0.94)],
      [Offset(0.22, 0.06), Offset(0.42, 0.20), Offset(0.34, 0.34), Offset(0.64, 0.48), Offset(0.48, 0.64), Offset(0.78, 0.78), Offset(0.66, 0.94)],
      [Offset(0.28, 0.06), Offset(0.18, 0.22), Offset(0.42, 0.38), Offset(0.62, 0.52), Offset(0.38, 0.66), Offset(0.74, 0.80), Offset(0.52, 0.94)],
      [Offset(0.16, 0.06), Offset(0.38, 0.20), Offset(0.30, 0.36), Offset(0.54, 0.50), Offset(0.44, 0.66), Offset(0.76, 0.80), Offset(0.58, 0.94)],
      [Offset(0.82, 0.06), Offset(0.86, 0.24), Offset(0.78, 0.40), Offset(0.42, 0.52), Offset(0.46, 0.68), Offset(0.36, 0.82), Offset(0.32, 0.94)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _comparisonExplorerPreview(
          selectedItem: 'Mud Properties',
          height: 430,
          child: Column(
            children: [
              Container(
                height: 30,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Row(
                  children: [
                    Text(
                      'Mud Properties vs. Measured Depth',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 92,
                      height: 21,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.tableBorderBlue),
                      ),
                      child: Text(
                        'Sample 1',
                        style: AppTheme.bodyLarge.copyWith(fontSize: 8),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    for (var index = 0; index < propertyNames.length; index++) ...[
                      Expanded(
                        child: _totalCostMiniChart(
                          propertyNames[index],
                          propertyColors[index],
                          propertyPoints[index],
                        ),
                      ),
                      if (index != propertyNames.length - 1)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  _manualLegendItem('North-01', const Color(0xFF4F91C7)),
                  _manualLegendItem('North-02', const Color(0xFF69C6DF)),
                  _manualLegendItem('West-03', const Color(0xFFE45B52)),
                  _manualLegendItem('Central-04', const Color(0xFF7DB56A)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Mud Properties compares the selected fluid measurements over the drilled-depth range of each well. Use the sample selector to review equivalent test samples across the comparison set.',
        ),
      ],
    );
  }

  Widget _comparisonHydraulicsPage() {
    const resultNames = [
      'Flow Rate (gpm)',
      'Pump Pressure (psi)',
      'Impact Force (lbf)',
      'Hydraulic Horsepower / in2',
      'Bottom-Hole ECD (ppg)',
    ];
    const resultColors = [
      Color(0xFF4F91C7),
      Color(0xFF69C6DF),
      Color(0xFF7B86C8),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
    ];
    const resultPoints = [
      [Offset(0.12, 0.06), Offset(0.68, 0.22), Offset(0.62, 0.36), Offset(0.34, 0.52), Offset(0.72, 0.64), Offset(0.48, 0.80), Offset(0.42, 0.94)],
      [Offset(0.18, 0.06), Offset(0.48, 0.22), Offset(0.42, 0.38), Offset(0.68, 0.54), Offset(0.38, 0.66), Offset(0.78, 0.82), Offset(0.84, 0.94)],
      [Offset(0.62, 0.06), Offset(0.48, 0.20), Offset(0.30, 0.36), Offset(0.70, 0.50), Offset(0.36, 0.66), Offset(0.28, 0.82), Offset(0.32, 0.94)],
      [Offset(0.20, 0.06), Offset(0.54, 0.22), Offset(0.30, 0.38), Offset(0.68, 0.52), Offset(0.40, 0.66), Offset(0.22, 0.82), Offset(0.30, 0.94)],
      [Offset(0.20, 0.06), Offset(0.26, 0.24), Offset(0.22, 0.40), Offset(0.46, 0.54), Offset(0.66, 0.68), Offset(0.72, 0.84), Offset(0.76, 0.94)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Hydraulics compares the calculated circulation and bit-performance results of each selected well over their measured-depth ranges.',
        ),
        const SizedBox(height: 14),
        _comparisonExplorerPreview(
          selectedItem: 'Hydraulics',
          height: 420,
          child: Column(
            children: [
              Text(
                'Hydraulics Results vs. Measured Depth',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var index = 0; index < resultNames.length; index++) ...[
                      Expanded(
                        child: _totalCostMiniChart(
                          resultNames[index],
                          resultColors[index],
                          resultPoints[index],
                        ),
                      ),
                      if (index != resultNames.length - 1)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  _manualLegendItem('North-01', const Color(0xFF4F91C7)),
                  _manualLegendItem('North-02', const Color(0xFF69C6DF)),
                  _manualLegendItem('West-03', const Color(0xFFE45B52)),
                  _manualLegendItem('Central-04', const Color(0xFF7DB56A)),
                  _manualLegendItem('East-05', const Color(0xFF9B7BC3)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonSolidsPage() {
    const resultNames = [
      'LGS (% vol)',
      'LGS (lb/bbl)',
      'HGS (% vol)',
      'HGS (lb/bbl)',
      'Average Solids SG',
    ];
    const resultColors = [
      Color(0xFF4F91C7),
      Color(0xFF69C6DF),
      Color(0xFF7B86C8),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
    ];
    const resultPoints = [
      [Offset(0.62, 0.06), Offset(0.28, 0.20), Offset(0.54, 0.36), Offset(0.40, 0.50), Offset(0.74, 0.64), Offset(0.68, 0.80), Offset(0.82, 0.94)],
      [Offset(0.58, 0.06), Offset(0.24, 0.22), Offset(0.52, 0.38), Offset(0.36, 0.52), Offset(0.72, 0.66), Offset(0.64, 0.82), Offset(0.78, 0.94)],
      [Offset(0.20, 0.06), Offset(0.38, 0.20), Offset(0.24, 0.36), Offset(0.58, 0.52), Offset(0.70, 0.68), Offset(0.68, 0.82), Offset(0.74, 0.94)],
      [Offset(0.18, 0.06), Offset(0.36, 0.22), Offset(0.22, 0.38), Offset(0.56, 0.52), Offset(0.68, 0.68), Offset(0.66, 0.82), Offset(0.72, 0.94)],
      [Offset(0.16, 0.06), Offset(0.24, 0.22), Offset(0.20, 0.38), Offset(0.82, 0.50), Offset(0.28, 0.66), Offset(0.30, 0.82), Offset(0.34, 0.94)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Solids compares calculated low- and high-gravity solids results for each selected well over the measured-depth range.',
        ),
        const SizedBox(height: 14),
        _comparisonExplorerPreview(
          selectedItem: 'Solids',
          height: 420,
          child: Column(
            children: [
              Text(
                'Solids Analysis vs. Measured Depth',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var index = 0; index < resultNames.length; index++) ...[
                      Expanded(
                        child: _totalCostMiniChart(
                          resultNames[index],
                          resultColors[index],
                          resultPoints[index],
                        ),
                      ),
                      if (index != resultNames.length - 1)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  _manualLegendItem('North-01', const Color(0xFF4F91C7)),
                  _manualLegendItem('North-02', const Color(0xFF69C6DF)),
                  _manualLegendItem('West-03', const Color(0xFFE45B52)),
                  _manualLegendItem('Central-04', const Color(0xFF7DB56A)),
                  _manualLegendItem('East-05', const Color(0xFF9B7BC3)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonVolumePage() {
    const resultNames = [
      'Starting Volume (bbl)',
      'Total Additions (bbl)',
      'Total Losses (bbl)',
      'Net Transfers (bbl)',
      'Ending Volume (bbl)',
    ];
    const resultColors = [
      Color(0xFF4F91C7),
      Color(0xFF69C6DF),
      Color(0xFF7B86C8),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
    ];
    const resultPoints = [
      [Offset(0.18, 0.06), Offset(0.62, 0.22), Offset(0.36, 0.38), Offset(0.70, 0.52), Offset(0.48, 0.68), Offset(0.76, 0.84), Offset(0.84, 0.94)],
      [Offset(0.20, 0.06), Offset(0.56, 0.20), Offset(0.30, 0.36), Offset(0.68, 0.52), Offset(0.40, 0.68), Offset(0.24, 0.82), Offset(0.28, 0.94)],
      [Offset(0.38, 0.06), Offset(0.58, 0.22), Offset(0.24, 0.38), Offset(0.72, 0.50), Offset(0.30, 0.66), Offset(0.20, 0.82), Offset(0.24, 0.94)],
      [Offset(0.22, 0.06), Offset(0.58, 0.22), Offset(0.36, 0.38), Offset(0.30, 0.54), Offset(0.66, 0.68), Offset(0.42, 0.82), Offset(0.50, 0.94)],
      [Offset(0.24, 0.06), Offset(0.30, 0.22), Offset(0.46, 0.38), Offset(0.74, 0.52), Offset(0.62, 0.68), Offset(0.82, 0.82), Offset(0.90, 0.94)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Volume compares fluid movement and system balances for the selected wells over their measured-depth ranges. Detailed values remain available through the table view.',
        ),
        const SizedBox(height: 14),
        _comparisonExplorerPreview(
          selectedItem: 'Volume',
          height: 420,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Volume Movement vs. Measured Depth',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          for (var index = 0; index < resultNames.length; index++) ...[
                            Expanded(
                              child: _totalCostMiniChart(
                                resultNames[index],
                                resultColors[index],
                                resultPoints[index],
                              ),
                            ),
                            if (index != resultNames.length - 1)
                              const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 5,
                      alignment: WrapAlignment.center,
                      children: [
                        _manualLegendItem('North-01', const Color(0xFF4F91C7)),
                        _manualLegendItem('North-02', const Color(0xFF69C6DF)),
                        _manualLegendItem('West-03', const Color(0xFFE45B52)),
                        _manualLegendItem('Central-04', const Color(0xFF7DB56A)),
                        _manualLegendItem('East-05', const Color(0xFF9B7BC3)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                color: const Color(0xFFF1F5FA),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _concentrationViewTab('Graph', true),
                    const SizedBox(height: 5),
                    _concentrationViewTab('Table', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonTimeDistributionPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Time Distribution compares the percentage of reported time assigned to each operational activity for every selected well.',
        ),
        const SizedBox(height: 14),
        _comparisonExplorerPreview(
          selectedItem: 'Time Distribution',
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Text(
                  'Operational Time Share by Well (%)',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.tableBorderBlue),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1120,
                      child: _recapDataTable(
                        const [
                          'Well',
                          'Rig-up',
                          'Circulating',
                          'Service',
                          'BOP Test',
                          'Run Casing',
                          'Cementing',
                          'Drill Out',
                          'Drilling',
                          'Tripping',
                          'Other',
                        ],
                        const [
                          ['North-01', '4.8%', '8.2%', '3.4%', '2.1%', '5.6%', '3.8%', '4.1%', '45.6%', '17.2%', '5.2%'],
                          ['North-02', '5.2%', '7.6%', '4.0%', '1.8%', '6.3%', '4.2%', '3.6%', '42.8%', '18.4%', '6.1%'],
                          ['West-03', '4.4%', '9.1%', '3.2%', '2.4%', '4.8%', '3.6%', '5.0%', '47.2%', '15.8%', '4.5%'],
                          ['Central-04', '5.0%', '8.4%', '3.8%', '2.0%', '5.2%', '4.0%', '4.6%', '44.1%', '17.5%', '5.4%'],
                          ['East-05', '4.6%', '7.9%', '3.6%', '2.2%', '5.8%', '4.4%', '4.2%', '46.0%', '16.3%', '5.0%'],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _manualLegendItem('Primary activity', const Color(0xFF78A8D8)),
                  const SizedBox(width: 18),
                  Text(
                    'Scroll horizontally to review all activity categories.',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonBitPage() {
    const resultNames = [
      'Bit Number',
      'Bit Size (in.)',
      'Total Flow Area (in2)',
      'Depth In / Out (ft)',
      'Cumulative Bit Depth (ft)',
    ];
    const resultColors = [
      Color(0xFF4F91C7),
      Color(0xFF69C6DF),
      Color(0xFF7B86C8),
      Color(0xFFE9A84A),
      Color(0xFF7DB56A),
    ];
    const resultPoints = [
      [Offset(0.16, 0.06), Offset(0.16, 0.24), Offset(0.36, 0.24), Offset(0.36, 0.48), Offset(0.62, 0.48), Offset(0.62, 0.72), Offset(0.86, 0.72), Offset(0.86, 0.94)],
      [Offset(0.78, 0.06), Offset(0.78, 0.34), Offset(0.56, 0.34), Offset(0.56, 0.66), Offset(0.32, 0.66), Offset(0.32, 0.94)],
      [Offset(0.28, 0.06), Offset(0.32, 0.24), Offset(0.24, 0.42), Offset(0.58, 0.56), Offset(0.44, 0.72), Offset(0.70, 0.86), Offset(0.54, 0.94)],
      [Offset(0.12, 0.06), Offset(0.28, 0.24), Offset(0.40, 0.42), Offset(0.54, 0.58), Offset(0.68, 0.74), Offset(0.84, 0.94)],
      [Offset(0.08, 0.06), Offset(0.24, 0.24), Offset(0.40, 0.42), Offset(0.56, 0.58), Offset(0.72, 0.76), Offset(0.92, 0.94)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Bit compares bit selection, geometry, hydraulic area, and drilled-depth progression across the selected wells.',
        ),
        const SizedBox(height: 14),
        _comparisonExplorerPreview(
          selectedItem: 'Bit',
          height: 420,
          child: Column(
            children: [
              Text(
                'Bit Parameters vs. Measured Depth',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var index = 0; index < resultNames.length; index++) ...[
                      Expanded(
                        child: _totalCostMiniChart(
                          resultNames[index],
                          resultColors[index],
                          resultPoints[index],
                        ),
                      ),
                      if (index != resultNames.length - 1)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  _manualLegendItem('North-01', const Color(0xFF4F91C7)),
                  _manualLegendItem('North-02', const Color(0xFF69C6DF)),
                  _manualLegendItem('West-03', const Color(0xFFE45B52)),
                  _manualLegendItem('Central-04', const Color(0xFF7DB56A)),
                  _manualLegendItem('East-05', const Color(0xFF9B7BC3)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonRemarksPage() {
    const wells = [
      ('North-01', 620.0, 1280.0, 940.0, 84.0),
      ('North-02', 410.0, 860.0, 720.0, 56.0),
      ('West-03', 780.0, 1540.0, 1120.0, 102.0),
      ('Central-04', 930.0, 1860.0, 1340.0, 118.0),
      ('East-05', 860.0, 1720.0, 1490.0, 96.0),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Remarks compares the amount of narrative and review content recorded for each selected well.',
        ),
        const SizedBox(height: 14),
        _comparisonExplorerPreview(
          selectedItem: 'Remarks',
          height: 380,
          child: Column(
            children: [
              Container(
                height: 34,
                color: const Color(0xFFE7F1FB),
                child: Row(
                  children: [
                    _comparisonCostHeader('Well', flex: 2),
                    _comparisonCostHeader('Treatment Notes', flex: 2),
                    _comparisonCostHeader('Daily Remarks', flex: 2),
                    _comparisonCostHeader('Recap Remarks', flex: 2),
                    _comparisonCostHeader('Internal Notes', flex: 2),
                  ],
                ),
              ),
              for (final well in wells)
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFD5E0EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _comparisonCostTextCell(well.$1, flex: 2),
                        _comparisonCostBarCell(
                          well.$2,
                          1000,
                          const Color(0xFF8CB5DE),
                          flex: 2,
                        ),
                        _comparisonCostBarCell(
                          well.$3,
                          2000,
                          const Color(0xFF78A8D8),
                          flex: 2,
                        ),
                        _comparisonCostBarCell(
                          well.$4,
                          1600,
                          const Color(0xFF8CCB96),
                          flex: 2,
                        ),
                        _comparisonCostBarCell(
                          well.$5,
                          140,
                          const Color(0xFFE4B36A),
                          flex: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _manualLegendItem('Treatment', const Color(0xFF8CB5DE)),
                  _manualLegendItem('Daily remarks', const Color(0xFF78A8D8)),
                  _manualLegendItem('Recap remarks', const Color(0xFF8CCB96)),
                  _manualLegendItem('Internal notes', const Color(0xFFE4B36A)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _manualParagraph(
          'Longer bars indicate more recorded text in that category, helping the user identify wells that may require deeper operational or safety review.',
        ),
      ],
    );
  }

  Widget _comparisonSurveyPage() {
    const sectionPoints = [
      Offset(0.08, 0.06),
      Offset(0.10, 0.22),
      Offset(0.14, 0.40),
      Offset(0.26, 0.58),
      Offset(0.54, 0.72),
      Offset(0.82, 0.84),
      Offset(0.94, 0.92),
    ];
    const planPoints = [
      Offset(0.18, 0.78),
      Offset(0.36, 0.76),
      Offset(0.54, 0.72),
      Offset(0.68, 0.58),
      Offset(0.72, 0.36),
      Offset(0.76, 0.16),
    ];
    const doglegPoints = [
      Offset(0.04, 0.10),
      Offset(0.22, 0.18),
      Offset(0.10, 0.28),
      Offset(0.36, 0.40),
      Offset(0.18, 0.52),
      Offset(0.52, 0.64),
      Offset(0.28, 0.76),
      Offset(0.64, 0.88),
      Offset(0.42, 0.94),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Survey compares the recorded directional profiles of the selected wells using section, plan, and dogleg views.',
        ),
        const SizedBox(height: 14),
        _comparisonExplorerPreview(
          selectedItem: 'Survey',
          height: 440,
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: _totalCostMiniChart(
                        'Section View - TVD vs. Displacement',
                        const Color(0xFF4F91C7),
                        sectionPoints,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _totalCostMiniChart(
                        'Plan View - North / East',
                        const Color(0xFF69C6DF),
                        planPoints,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: _totalCostMiniChart(
                  'Dogleg Severity vs. Measured Depth',
                  const Color(0xFF7B86C8),
                  doglegPoints,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  _manualLegendItem('North-01', const Color(0xFF4F91C7)),
                  _manualLegendItem('North-02', const Color(0xFF69C6DF)),
                  _manualLegendItem('West-03', const Color(0xFFE45B52)),
                  _manualLegendItem('Central-04', const Color(0xFF7DB56A)),
                  _manualLegendItem('East-05', const Color(0xFF9B7BC3)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _manualParagraph(
          'The common views make trajectory displacement and dogleg differences easier to identify without changing the underlying survey records.',
        ),
      ],
    );
  }

  Widget _comparisonEngineerPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _comparisonExplorerPreview(
          selectedItem: 'Engineer',
          height: 390,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FA),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Row(
                  children: [
                    Text(
                      'Engineer Coverage by Well',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Selected comparison period',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _recapDataTable(
                  const [
                    'Well',
                    'Lead Engineer',
                    'Day Rotation',
                    'Night Rotation',
                    'Relief / Support',
                    'Engineer-Days',
                    'Coverage',
                  ],
                  const [
                    ['North-01', 'A. Morgan', 'J. Rivera', 'R. Patel', 'S. Chen', '25', '100%'],
                    ['North-02', 'R. Patel', 'D. Walker', 'M. Lewis', 'A. Morgan', '22', '100%'],
                    ['West-03', 'J. Rivera', 'S. Chen', 'D. Walker', 'M. Lewis', '19', '98%'],
                    ['Central-04', 'S. Chen', 'A. Morgan', 'R. Patel', 'J. Rivera', '28', '100%'],
                    ['East-05', 'D. Walker', 'M. Lewis', 'J. Rivera', 'S. Chen', '31', '100%'],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  border: Border.all(color: AppTheme.tableBorderBlue),
                ),
                child: Row(
                  children: [
                    _manualLegendItem('Lead assignment', const Color(0xFF4F91C7)),
                    const SizedBox(width: 18),
                    _manualLegendItem('Rotation coverage', const Color(0xFF69C6DF)),
                    const Spacer(),
                    Text(
                      '125 engineer-days across 5 wells',
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.panelHeaderBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _manualParagraph(
          'Engineer compares personnel assignments and working coverage across the selected wells, including lead responsibility, shift rotations, support coverage, and total engineer-days.',
        ),
      ],
    );
  }

  Widget _comparisonCostHeader(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _comparisonCostTextCell(String value, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _comparisonCostBarCell(
    double value,
    double maximum,
    Color color, {
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 18, color: const Color(0xFFF1F5FA)),
                Container(
                  width: constraints.maxWidth *
                      (value / maximum).clamp(0.0, 1.0).toDouble(),
                  height: 18,
                  color: color.withOpacity(0.78),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      value >= 1000
                          ? value.toStringAsFixed(0)
                          : value.toStringAsFixed(1),
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _comparisonExplorerPreview({
    required String selectedItem,
    required Widget child,
    required double height,
  }) {
    final items = _comparisonJobExplorerLinks.keys.toList();
    return Container(
      width: 900,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            color: AppTheme.panelHeaderBlue,
            child: Text(
              'MSR2_DMR - Well Comparison',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 130,
                  padding: const EdgeInsets.all(7),
                  color: const Color(0xFFF1F5FA),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final item in items)
                          Container(
                            height: 27,
                            margin: const EdgeInsets.only(bottom: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            alignment: Alignment.centerLeft,
                            color: item == selectedItem
                                ? AppTheme.panelHeaderBlue
                                : Colors.transparent,
                            child: Text(
                              item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyLarge.copyWith(
                                color: item == selectedItem
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonWellSchematic(
    String wellName,
    String totalDepth,
    Color casingColor,
    bool deviated,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 36,
            alignment: Alignment.center,
            color: const Color(0xFFF1F5FA),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  wellName,
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'TD $totalDepth',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 7,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final center = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    Positioned(
                      left: center - 22,
                      top: 15,
                      width: 44,
                      height: constraints.maxHeight * 0.25,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            vertical: BorderSide(
                              color: casingColor,
                              width: 6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: center - 12,
                      top: constraints.maxHeight * 0.23,
                      width: 24,
                      height: constraints.maxHeight * 0.30,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            vertical: BorderSide(
                              color: casingColor.withOpacity(0.75),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: center - 2,
                      top: constraints.maxHeight * 0.48,
                      child: Transform.rotate(
                        angle: deviated ? -0.20 : 0,
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 4,
                          height: constraints.maxHeight * 0.42,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 5,
                      bottom: 5,
                      right: 5,
                      child: Text(
                        deviated ? 'Directional profile' : 'Vertical profile',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyLarge.copyWith(fontSize: 7),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonToolbarPreview({
    required String activeTab,
    required List<(IconData, String)> actions,
  }) {
    const tabs = ['Home', 'Report', 'Utilities', 'Help'];
    return Container(
      width: 620,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (final tab in tabs)
                Container(
                  width: 105,
                  height: 31,
                  alignment: Alignment.center,
                  color: tab == activeTab
                      ? AppTheme.panelHeaderBlue
                      : AppTheme.tableHeaderBlue,
                  child: Text(
                    tab,
                    style: AppTheme.bodyLarge.copyWith(
                      color: tab == activeTab
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
            ],
          ),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: AppTheme.tableHeaderBlue.withOpacity(0.45),
            child: Row(
              children: [
                for (final action in actions)
                  Container(
                    width: 112,
                    margin: const EdgeInsets.only(right: 6),
                    child: Row(
                      children: [
                        Icon(action.$1, size: 20, color: AppTheme.textPrimary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            action.$2,
                            maxLines: 2,
                            style: AppTheme.bodyLarge.copyWith(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonOptionsPreview() {
    const options = [
      'Well Schematic',
      'Cost',
      'Drilling Data',
      'Mud Properties',
      'Hydraulics',
      'Solids',
      'Volume',
      'Bit',
      'Remarks',
      'Survey',
    ];
    return Container(
      width: 650,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            color: AppTheme.panelHeaderBlue,
            child: Text(
              'Well Comparison Options',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 110,
                  color: const Color(0xFFF1F5FA),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    'Report',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (final option in options)
                          SizedBox(
                            width: 155,
                            child: _manualOptionRow(option, checked: true),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonReportPreview() {
    return Container(
      width: 650,
      height: 330,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MUDPRO - Well Comparison',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _recapDataTable(
            const ['Well', 'Field', 'Country', 'Start', 'End', 'Engineer'],
            const [
              ['North-01', 'Falcon', 'USA', '04/02', '04/27', 'A. Morgan'],
              ['North-02', 'Falcon', 'USA', '05/01', '05/24', 'R. Patel'],
              ['West-03', 'Orion', 'Canada', '05/08', '06/02', 'J. Rivera'],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                for (final well in const ['North-01', 'North-02', 'West-03']) ...[
                  Expanded(
                    child: _totalCostMiniChart(
                      '$well - Schematic',
                      AppTheme.panelHeaderBlue,
                      const [
                        Offset(0.08, 0.08),
                        Offset(0.12, 0.42),
                        Offset(0.28, 0.68),
                        Offset(0.72, 0.82),
                        Offset(0.94, 0.88),
                      ],
                    ),
                  ),
                  if (well != 'West-03') const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _manualLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 4, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _recapMudPropertiesOptionsPreview() {
    const navigationItems = [
      'Group',
      'Summary',
      'Range',
      'Report',
      'Sample',
      'Graph',
    ];
    const headers = [
      'Explorer Item',
      'Orientation',
      'Line 1',
      'Line 2',
      'Line 3',
      'Line 4',
      'Line 5',
      'Limits',
      'Sample',
    ];
    const rows = [
      ['Cum. Cost', 'vs. Day', 'Product', 'Package', 'Service', 'Engineering', 'Total', '', ''],
      ['Drilling Data', 'vs. Depth', 'WOB', 'ROP', 'RPM', '', '', '', ''],
      ['Mud Prop. 1', 'vs. Depth', 'MW', 'PV', 'YP', 'API Filtrate', 'pH', 'On', '1'],
      ['Mud Prop. 2', 'vs. Depth', 'Flowline T.', 'Funnel Visc.', 'Gel 10s', 'Oil', 'Water', 'On', '1'],
      ['Hydraulics', 'vs. Depth', 'Flow Rate', 'Pump P.', 'Impact F.', 'HSI', 'BH ECD', '', ''],
      ['Solids Analysis', 'vs. Depth', 'LGS (%)', 'LGS (lb/bbl)', 'HGS (%)', 'HGS (lb/bbl)', 'Avg. SG', '', ''],
      ['Volume', 'vs. Depth', 'Start', 'Daily Add.', 'Daily Loss', 'Daily Transfer', 'End', '', ''],
      ['SCE', 'vs. Depth', '', '', '', '', '', '', ''],
      ['Bit', 'vs. Depth', 'Bit', 'Size', 'TFA', 'Depth-in', 'Depth', '', ''],
      ['Customized', 'vs. Depth', 'MW', 'Total', 'WOB', 'RPM', 'ROP', '', 'For Calculation'],
    ];

    return Container(
      width: 900,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 30,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              'Recap Options - Graph',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 112,
                  color: const Color(0xFFF1F5FA),
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    children: [
                      for (final item in navigationItems)
                        Container(
                          height: 36,
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          alignment: Alignment.centerLeft,
                          color: item == 'Graph'
                              ? AppTheme.panelHeaderBlue
                              : Colors.transparent,
                          child: Text(
                            item,
                            style: AppTheme.bodyLarge.copyWith(
                              color: item == 'Graph'
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _manualOptionGroup(
                                'Line Graph',
                                const ['Minor grid', 'Minor tick'],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _manualOptionGroup(
                                'Depth Cost Graph',
                                const ['2D well path'],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _manualOptionGroup(
                                'Mud Properties',
                                const [
                                  'Plot planned data range',
                                  'Mud type indication',
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ClipRect(
                            child: Table(
                              border: TableBorder.all(
                                color: AppTheme.tableBorderBlue,
                              ),
                              columnWidths: const {
                                0: FlexColumnWidth(1.35),
                                1: FlexColumnWidth(1.05),
                                2: FlexColumnWidth(1.05),
                                3: FlexColumnWidth(1.05),
                                4: FlexColumnWidth(1.05),
                                5: FlexColumnWidth(1.05),
                                6: FlexColumnWidth(1.05),
                                7: FlexColumnWidth(0.68),
                                8: FlexColumnWidth(0.92),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE7F1FB),
                                  ),
                                  children: [
                                    for (final header in headers)
                                      _manualCompactTableCell(
                                        header,
                                        header: true,
                                      ),
                                  ],
                                ),
                                for (var index = 0; index < rows.length; index++)
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: index == 2 || index == 3
                                          ? const Color(0xFFFFF9D7)
                                          : Colors.white,
                                    ),
                                    children: [
                                      for (final value in rows[index])
                                        _manualCompactTableCell(value),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _manualOptionGroup(String title, List<String> options) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          for (final option in options)
            Row(
              children: [
                Icon(
                  Icons.check_box,
                  size: 12,
                  color: AppTheme.panelHeaderBlue,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    option,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyLarge.copyWith(fontSize: 8),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _manualCompactTableCell(String value, {bool header = false}) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 7,
          fontWeight: header ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _recapExplorerPreview({
    required String selectedItem,
    required Widget child,
    required double height,
  }) {
    const standardItems = [
      'Summary',
      'Cost Distribution',
      'Daily Cost',
      'Depth Cost',
      'Cumulative Cost',
      'Drilling Data',
      'Mud Properties',
      'Hydraulics',
    ];
    final items = selectedItem == 'Engineer'
        ? [
            ...standardItems,
            'Solid Analysis',
            'Volume',
            'Usage',
            'Concentration',
            'Time Distribution',
            'Solid Control Equipment',
            'Bit',
            'Remarks',
            'Interval',
            'Survey',
            'Customized',
            'Engineer',
          ]
        : selectedItem == 'Customized'
        ? [
            ...standardItems,
            'Solid Analysis',
            'Volume',
            'Usage',
            'Concentration',
            'Time Distribution',
            'Solid Control Equipment',
            'Bit',
            'Remarks',
            'Interval',
            'Survey',
            'Customized',
          ]
        : selectedItem == 'Survey'
        ? [
            ...standardItems,
            'Solid Analysis',
            'Volume',
            'Usage',
            'Concentration',
            'Time Distribution',
            'Solid Control Equipment',
            'Bit',
            'Remarks',
            'Interval',
            'Survey',
          ]
        : selectedItem == 'Interval'
        ? [
            ...standardItems,
            'Solid Analysis',
            'Volume',
            'Usage',
            'Concentration',
            'Time Distribution',
            'Solid Control Equipment',
            'Bit',
            'Remarks',
            'Interval',
          ]
        : selectedItem == 'Remarks'
        ? [
            ...standardItems,
            'Solid Analysis',
            'Volume',
            'Usage',
            'Concentration',
            'Time Distribution',
            'Solid Control Equipment',
            'Bit',
            'Remarks',
          ]
        : selectedItem == 'Bit'
        ? [
            ...standardItems,
            'Solid Analysis',
            'Volume',
            'Usage',
            'Concentration',
            'Time Distribution',
            'Solid Control Equipment',
            'Bit',
          ]
        : selectedItem == 'Solid Control Equipment'
        ? [
            ...standardItems,
            'Solid Analysis',
            'Volume',
            'Usage',
            'Concentration',
            'Time Distribution',
            'Solid Control Equipment',
          ]
        : selectedItem == 'Time Distribution'
        ? [
            ...standardItems,
            'Solid Analysis',
            'Volume',
            'Usage',
            'Concentration',
            'Time Distribution',
          ]
        : selectedItem == 'Concentration'
        ? [
            ...standardItems,
            'Solid Analysis',
            'Volume',
            'Usage',
            'Concentration',
          ]
        : selectedItem == 'Usage'
        ? [...standardItems, 'Solid Analysis', 'Volume', 'Usage']
        : selectedItem == 'Volume'
        ? [...standardItems, 'Solid Analysis', 'Volume']
        : selectedItem == 'Solid Analysis'
        ? [...standardItems, 'Solid Analysis']
        : standardItems;
    return Container(
      width: 900,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Recap',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 126,
                  color: const Color(0xFFF1F5FA),
                  padding: const EdgeInsets.all(7),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final item in items)
                          Container(
                            height: 29,
                            margin: const EdgeInsets.only(bottom: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            alignment: Alignment.centerLeft,
                            color: item == selectedItem
                                ? AppTheme.panelHeaderBlue
                                : Colors.transparent,
                            child: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyLarge.copyWith(
                                color: item == selectedItem
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recapDataTable(List<String> headers, List<List<String>> rows) {
    return Table(
      border: TableBorder.all(color: AppTheme.tableBorderBlue),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFE7F1FB)),
          children: [
            for (final header in headers)
              Padding(
                padding: const EdgeInsets.all(7),
                child: Text(
                  header,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              for (final value in row)
                Padding(
                  padding: const EdgeInsets.all(7),
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyLarge.copyWith(fontSize: 10),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _manualOptionRow(String label, {required bool checked}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
            color: AppTheme.panelHeaderBlue,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputSummaryPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'The Summary tab brings the current report overview into one place. It shows the wellbore schematic, KPI dashboard, cost distribution, and progress charts for quick review.',
        ),
        const SizedBox(height: 8),
        _outputSummaryWindowMock(),
        const SizedBox(height: 20),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'The sections displayed on this page can be customized from ',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
            _inlineManualLinkTo(
              'Output Options - Summary',
              target: 'Output Options',
            ),
            Text(
              '.',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _outputSummaryWindowMock() {
    const explorerItems = [
      'Summary',
      'Detail',
      'Daily Cost',
      'Total Cost',
      'Concentration',
      'Time Distribution',
      'Survey',
      'Alert',
    ];

    return Container(
      width: 760,
      height: 310,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Daily Output',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 112,
                  color: const Color(0xFFF1F5FA),
                  padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
                  child: Column(
                    children: [
                      for (final item in explorerItems)
                        Container(
                          height: 28,
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: item == 'Summary'
                                ? AppTheme.panelHeaderBlue
                                : Colors.transparent,
                            border: Border.all(
                              color: item == 'Summary'
                                  ? AppTheme.panelHeaderBlue
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyLarge.copyWith(
                              color: item == 'Summary'
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: item == 'Summary'
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: FittedBox(
                      alignment: Alignment.topLeft,
                      fit: BoxFit.contain,
                      child: _outputDashboardPreview(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputDetailPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _outputDetailWindowMock(),
        const SizedBox(height: 20),
        _manualParagraph(
          'The Detail tab presents the calculated hydraulics and volume information for the current report.',
        ),
        _manualHeading('1. Geometry'),
        _manualParagraph(
          'Geometry lists the drill string and annular sections with their start depth, end depth, volume, and volume per unit length.',
        ),
        _manualHeading('2. Circulation'),
        _manualParagraph(
          'Circulation shows the estimated time and pump strokes required for each circulation path.',
        ),
        _manualHeading('3. Annular Hydraulics'),
        _manualParagraph(
          'Annular Hydraulics summarizes fluid velocity, Reynolds number, critical velocity, critical Reynolds number, flow regime, and ECD by section.',
        ),
        _manualHeading('4. Solids Analysis'),
        _manualParagraph(
          'Solids Analysis displays the calculated solids results for the selected mud sample and its configured fluid properties.',
        ),
        _manualHeading('5. Bit Hydraulics'),
        _manualParagraph(
          'Bit Hydraulics displays nozzle and bit performance results. The section remains empty when required pump, bit, or nozzle inputs are incomplete.',
        ),
        _manualHeading('6. Volume'),
        _manualParagraph(
          'Volume summarizes displacement, string, annulus, below-bit, hole, pit, and total circulating volumes.',
        ),
      ],
    );
  }

  Widget _outputDetailWindowMock() {
    const explorerItems = [
      'Summary',
      'Detail',
      'Daily Cost',
      'Total Cost',
      'Concentration',
      'Time Distribution',
      'Survey',
      'Alert',
    ];

    return Container(
      width: 780,
      height: 390,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Daily Output',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 112,
                  color: const Color(0xFFF1F5FA),
                  padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
                  child: Column(
                    children: [
                      for (final item in explorerItems)
                        Container(
                          height: 28,
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          color: item == 'Detail'
                              ? AppTheme.panelHeaderBlue
                              : Colors.transparent,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyLarge.copyWith(
                              color: item == 'Detail'
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: item == 'Detail'
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _outputDetailTable(
                                  'Geometry',
                                  const ['Description', 'Start', 'End', 'Vol.'],
                                  const [
                                    ['Casing', '0', '2800', '426.4'],
                                    ['Open hole', '2800', '9848', '471.8'],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: _outputDetailTable(
                                  'Circulation',
                                  const ['Path', 'Min.', 'Strokes'],
                                  const [
                                    ['Surface - Bit', '22', '656'],
                                    ['Bottom up', '52', '1574'],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          flex: 3,
                          child: _outputDetailTable(
                            'Annular Hydraulics',
                            const [
                              'Section',
                              'Length',
                              'Velocity',
                              'Re',
                              'Flow',
                              'ECD',
                            ],
                            const [
                              [
                                'Casing / pipe',
                                '5913',
                                '157.8',
                                '5455',
                                'Turbulent',
                                '8.72',
                              ],
                              [
                                'Open hole / BHA',
                                '2349',
                                '330.6',
                                '4605',
                                'Turbulent',
                                '9.35',
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Expanded(
                                child: _outputDetailTable(
                                  'Solids Analysis',
                                  const ['Property', 'Sample'],
                                  const [
                                    ['LGS (%)', '9.7'],
                                    ['HGS (%)', '0.0'],
                                    ['Avg. SG', '2.09'],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _outputDetailTable(
                                  'Bit Hydraulics',
                                  const ['Property', 'Result'],
                                  const [
                                    ['TFA', '0.55'],
                                    ['Jet velocity', '88.0'],
                                    ['Bit HHP', '4.8'],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _outputDetailTable(
                                  'Volume',
                                  const ['Description', 'bbl'],
                                  const [
                                    ['Hole', '898.1'],
                                    ['Active pits', '403.0'],
                                    ['Circulating', '1301.1'],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputDetailTable(
    String title,
    List<String> columns,
    List<List<String>> rows,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            alignment: Alignment.centerLeft,
            color: AppTheme.panelHeaderBlue,
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 21,
            child: Row(
              children: [
                for (final column in columns)
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppTheme.tableHeaderBlue,
                        border: Border(
                          right: BorderSide(color: AppTheme.tableBorderBlue),
                          bottom: BorderSide(color: AppTheme.tableBorderBlue),
                        ),
                      ),
                      child: Text(
                        column,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyLarge.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final row in rows)
            Expanded(
              child: Row(
                children: [
                  for (var index = 0; index < columns.length; index++)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: index == 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? Colors.white
                              : const Color(0xFFFFFDE7),
                          border: const Border(
                            right: BorderSide(color: AppTheme.tableBorderBlue),
                            bottom: BorderSide(color: AppTheme.tableBorderBlue),
                          ),
                        ),
                        child: Text(
                          index < row.length ? row[index] : '',
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyLarge.copyWith(fontSize: 8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _outputDailyCostPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _outputDailyCostWindowMock(tableView: false),
        const SizedBox(height: 20),
        _manualParagraph(
          'Daily Cost includes Product, Service, Engineering, Package, and Pre-mixed Mud cost details. Use the view tabs to switch between distribution charts and tabular data.',
        ),
        const SizedBox(height: 8),
        _outputDailyCostWindowMock(tableView: true),
      ],
    );
  }

  Widget _outputDailyCostWindowMock({required bool tableView}) {
    const explorerItems = [
      'Summary',
      'Detail',
      'Daily Cost',
      'Total Cost',
      'Concentration',
      'Time Distribution',
      'Survey',
      'Alert',
    ];

    return Container(
      width: 780,
      height: tableView ? 350 : 330,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Daily Output',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 112,
                  color: const Color(0xFFF1F5FA),
                  padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
                  child: Column(
                    children: [
                      for (final item in explorerItems)
                        Container(
                          height: 28,
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          color: item == 'Daily Cost'
                              ? AppTheme.panelHeaderBlue
                              : Colors.transparent,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyLarge.copyWith(
                              color: item == 'Daily Cost'
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: item == 'Daily Cost'
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: tableView
                        ? _outputDetailTable(
                            'Daily Cost - All Categories',
                            const [
                              'Category',
                              'Item',
                              'Price',
                              'Initial',
                              'Received',
                              'Returned',
                              'Used',
                              'Final',
                              'Cost',
                              '%',
                            ],
                            const [
                              [
                                'Product',
                                'Base fluid',
                                '100',
                                '100',
                                '0',
                                '0',
                                '15',
                                '85',
                                '1500',
                                '72.7',
                              ],
                              [
                                'Product',
                                'Weight material',
                                '35',
                                '80',
                                '10',
                                '0',
                                '20',
                                '70',
                                '700',
                                '17.8',
                              ],
                              [
                                'Service',
                                'Bulk trucking',
                                '30',
                                '0',
                                '0',
                                '0',
                                '10',
                                '0',
                                '300',
                                '5.8',
                              ],
                              [
                                'Engineering',
                                'Mud engineer',
                                '600',
                                '0',
                                '0',
                                '0',
                                '1',
                                '0',
                                '600',
                                '3.7',
                              ],
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _dailyCostChart(
                                  'Daily Cost Distribution - Product',
                                  const [
                                    MapEntry('Base fluid', 0.78),
                                    MapEntry('Weight material', 0.24),
                                    MapEntry('Oil mud', 0.15),
                                    MapEntry('Chemical', 0.10),
                                    MapEntry('LCM', 0.07),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dailyCostChart(
                                  'Daily Cost Distribution - Group',
                                  const [
                                    MapEntry('Weight material', 0.82),
                                    MapEntry('Emulsifier', 0.18),
                                    MapEntry('Base fluid', 0.14),
                                    MapEntry('Thinner', 0.09),
                                    MapEntry('Common chemical', 0.07),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                Container(
                  width: 34,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFFF1F5FA),
                  child: Column(
                    children: [
                      _dailyCostViewTab('Graph', !tableView),
                      const SizedBox(height: 5),
                      _dailyCostViewTab('Table', tableView),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyCostChart(String title, List<MapEntry<String, double>> values) {
    final maxValue = values.isEmpty
        ? 0.0
        : values
              .map((entry) => entry.value.abs())
              .reduce((first, second) => first > second ? first : second);
    final scale = maxValue <= 1.0
        ? 1.0
        : maxValue <= 100.0
        ? 100.0
        : maxValue;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            alignment: Alignment.center,
            color: AppTheme.tableHeaderBlue,
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                children: [
                  for (final value in values)
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 78,
                            child: Text(
                              value.key,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyLarge.copyWith(fontSize: 8),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: (value.value / scale).clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: Container(
                                  height: 13,
                                  color: AppTheme.panelHeaderBlue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyCostViewTab(String label, bool selected) {
    return Container(
      width: 25,
      height: 72,
      alignment: Alignment.center,
      color: selected ? AppTheme.panelHeaderBlue : AppTheme.tableHeaderBlue,
      child: RotatedBox(
        quarterTurns: 1,
        child: Text(
          label,
          style: AppTheme.bodyLarge.copyWith(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _outputTotalCostPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _outputTotalCostWindowMock(),
        const SizedBox(height: 20),
        _manualParagraph(
          'Total Cost shows the cumulative daily cost for Products, Pre-mixed Mud, Packages, Services, and Engineering. Use the view controls on the right to review cumulative trends as graphs or detailed tabular data.',
        ),
      ],
    );
  }

  Widget _outputTotalCostWindowMock() {
    const explorerItems = [
      'Summary',
      'Detail',
      'Daily Cost',
      'Total Cost',
      'Concentration',
      'Time Distribution',
      'Survey',
      'Alert',
    ];
    const charts = [
      MapEntry('Product', Color(0xFF6EA7E8)),
      MapEntry('Pre-mixed Mud', Color(0xFF69C6DF)),
      MapEntry('Package', Color(0xFFF0B45A)),
      MapEntry('Service', Color(0xFF9BC66B)),
      MapEntry('Engineering', Color(0xFF9B7BC3)),
    ];
    const chartPoints = [
      <Offset>[
        Offset(0.00, 0.94),
        Offset(0.52, 0.94),
        Offset(0.58, 0.08),
        Offset(0.64, 0.90),
        Offset(0.73, 0.82),
        Offset(0.80, 0.89),
        Offset(1.00, 0.94),
      ],
      <Offset>[
        Offset(0.00, 0.96),
        Offset(0.48, 0.96),
        Offset(0.55, 0.18),
        Offset(0.61, 0.96),
        Offset(1.00, 0.96),
      ],
      <Offset>[Offset(0.00, 0.96), Offset(1.00, 0.96)],
      <Offset>[
        Offset(0.00, 0.92),
        Offset(0.10, 0.77),
        Offset(0.20, 0.91),
        Offset(0.35, 0.83),
        Offset(0.48, 0.90),
        Offset(0.58, 0.42),
        Offset(0.68, 0.88),
        Offset(0.78, 0.33),
        Offset(0.88, 0.84),
        Offset(0.96, 0.70),
      ],
      <Offset>[
        Offset(0.00, 0.78),
        Offset(0.72, 0.78),
        Offset(0.78, 0.30),
        Offset(1.00, 0.30),
      ],
    ];

    return Container(
      width: 900,
      height: 390,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Daily Output',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 112,
                  color: const Color(0xFFF1F5FA),
                  padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
                  child: Column(
                    children: [
                      for (final item in explorerItems)
                        Container(
                          height: 28,
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          color: item == 'Total Cost'
                              ? AppTheme.panelHeaderBlue
                              : Colors.transparent,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyLarge.copyWith(
                              color: item == 'Total Cost'
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: item == 'Total Cost'
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
                    child: Column(
                      children: [
                        Text(
                          'Daily Total Cost',
                          style: AppTheme.bodyLarge.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              for (
                                var index = 0;
                                index < charts.length;
                                index++
                              ) ...[
                                Expanded(
                                  child: _totalCostMiniChart(
                                    charts[index].key,
                                    charts[index].value,
                                    chartPoints[index],
                                  ),
                                ),
                                if (index < charts.length - 1)
                                  const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFFF1F5FA),
                  child: Column(
                    children: [
                      _dailyCostViewTab('Graph', true),
                      const SizedBox(height: 5),
                      _dailyCostViewTab('Table', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCostMiniChart(String title, Color color, List<Offset> points) {
    return Column(
      children: [
        SizedBox(
          height: 24,
          child: Text(
            title,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.tableBorderBlue),
            ),
            padding: const EdgeInsets.fromLTRB(5, 6, 5, 4),
            child: CustomPaint(
              painter: _TotalCostMiniChartPainter(
                points: points,
                lineColor: color,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text('Day', style: AppTheme.bodyLarge.copyWith(fontSize: 8)),
      ],
    );
  }

  Widget _outputConcentrationPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _outputConcentrationWindowMock(historyTable: false),
        const SizedBox(height: 20),
        _manualParagraph(
          'Concentration graphs track up to five products selected in Pad > Inventory for concentration calculation. Each line shows how the selected product concentration changes through the report sequence.',
        ),
        const SizedBox(height: 10),
        _manualParagraph(
          'Use the pit selector in the upper-right corner to review the active system or a reserve pit. The Current Table view shows the latest concentrations, while the History Table view lists the values recorded across reports.',
        ),
        const SizedBox(height: 18),
        _outputConcentrationWindowMock(historyTable: true),
        const SizedBox(height: 18),
        _manualParagraph(
          'The concentration history table displays report date, measured depth, report number, and product concentrations for the selected active system or reserve pit.',
        ),
      ],
    );
  }

  Widget _outputTimeDistributionPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _outputTimeDistributionWindowMock(),
        const SizedBox(height: 20),
        _manualParagraph(
          'Time Distribution summarizes how the current report day is divided among recorded drilling activities. Each horizontal bar shows the activity duration and its percentage of the total reported time.',
        ),
      ],
    );
  }

  Widget _outputSurveyPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _surveyOutputMock(),
        const SizedBox(height: 20),
        _manualParagraph(
          'Survey compares the actual directional survey recorded through daily reports with the planned survey entered in Well > Survey. Section View, Plan View, and Dogleg charts use separate colors so the actual and planned well paths can be reviewed together.',
        ),
      ],
    );
  }

  Widget _recapWindowsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Recap includes ',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            _inlineManualLinkTo('Toolbar', target: 'Recap Toolbar'),
            Text(
              ', ',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            _inlineManualLinkTo(
              'Recap Job Explorer',
              target: 'Recap Job Explorer',
            ),
          ],
        ),
      ],
    );
  }

  Widget _recapToolbarPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph('The recap toolbar includes:'),
        const SizedBox(height: 12),
        _inlineManualLinkTo('Home & Report', target: 'Recap Home & Report'),
        const SizedBox(height: 18),
        _inlineManualLinkTo('Options', target: 'Recap Options'),
      ],
    );
  }

  Widget _recapHomeReportPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _recapToolbarPreview(
          activeTab: 'Home',
          actions: const [
            (Icons.arrow_back_outlined, 'Go to Input'),
            (Icons.settings_outlined, 'Options'),
          ],
        ),
        const SizedBox(height: 18),
        _numberedHelp(
          '1.',
          'Go to Input returns from the Recap output to the main MSR2_DMR input workspace without changing the current report data.',
        ),
        _numberedHelp(
          '2.',
          'Options opens the Recap configuration used to control summary panels, report content, and export preferences.',
        ),
        const SizedBox(height: 22),
        _recapToolbarPreview(
          activeTab: 'Report',
          actions: const [
            (Icons.description_outlined, 'Recap Detail Report'),
            (Icons.summarize_outlined, 'Recap Summary'),
            (Icons.table_chart_outlined, 'Interval Detail Report'),
            (Icons.view_list_outlined, 'Interval Summary Report'),
            (Icons.water_drop_outlined, 'Mud Volume Accounting'),
            (Icons.payments_outlined, 'Cost Summary'),
            (Icons.analytics_outlined, 'Concentration Report'),
          ],
        ),
        const SizedBox(height: 18),
        _numberedHelp(
          '1.',
          'Recap Detail Report generates the complete recap detail for the selected well using the configured report and export settings.',
        ),
        _numberedHelp(
          '2.',
          'Recap Summary generates a concise summary of the selected well and its available daily report data.',
        ),
        _numberedHelp(
          '3.',
          'Interval Detail Report generates detailed results for each configured drilling interval.',
        ),
        _numberedHelp(
          '4.',
          'Interval Summary Report generates a summarized view of the configured drilling intervals.',
        ),
        _numberedHelp(
          '5.',
          'Mud Volume Accounting generates the available water-based and oil-based mud volume accounting sheets from report data.',
        ),
        _numberedHelp(
          '6.',
          'Cost Summary generates the current well cost summary from product, service, engineering, package, and other recorded costs.',
        ),
        _numberedHelp(
          '7.',
          'Concentration Report generates product concentration results for the active system and available reserve pits.',
        ),
      ],
    );
  }

  Widget _recapOptionsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _manualParagraph(
          'Recap Options controls which information appears in recap dashboards, tables, graphs, and exported recap reports.',
        ),
        _manualHeading('1. Group'),
        _manualParagraph(
          'Group settings select the result categories available in the Recap window. Clear a category to remove it from the recap workspace and its related output choices.',
        ),
        _recapOptionsMock('Group'),
        const SizedBox(height: 24),
        _manualHeading('2. Summary'),
        _manualParagraph(
          'Summary settings configure the KPI dashboard, cost-distribution panels, and progress charts shown on the Recap Summary page.',
        ),
        _recapOptionsMock('Summary'),
        const SizedBox(height: 24),
        _manualHeading('3. Range'),
        _manualParagraph(
          'Range settings define the reports included in the recap. The scope can include all reports or a selected date, report-number, or drilling-interval range.',
        ),
        _recapOptionsMock('Range'),
        const SizedBox(height: 24),
        _manualHeading('4. Report'),
        _manualParagraph(
          'Report settings control which graphs, tables, summaries, and usage details are included when a recap report is generated.',
        ),
        _recapOptionsMock('Report'),
        const SizedBox(height: 24),
        _manualHeading('5. Sample'),
        _manualParagraph(
          'Sample settings select the mud-check samples displayed in Recap Mud Properties tables. Any combination of Samples 1 through 4 can be included.',
        ),
        _recapOptionsMock('Sample'),
        const SizedBox(height: 24),
        _manualHeading('6. Graph'),
        _manualParagraph(
          'Graph settings control chart guides, depth-cost orientation, mud-property indicators, and the data series assigned to recap graphs.',
        ),
        _recapOptionsMock('Graph'),
      ],
    );
  }

  Widget _recapOptionsMock(String activeSection) {
    final height = activeSection == 'Graph' ? 360.0 : 310.0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.tableBorderBlue),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              color: AppTheme.panelHeaderBlue,
              child: Text(
                'Recap Options',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 108,
                    color: const Color(0xFFF4F7FA),
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        for (final section in const [
                          'Group',
                          'Summary',
                          'Range',
                          'Report',
                          'Sample',
                          'Graph',
                        ])
                          _recapOptionNav(section, section == activeSection),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _recapOptionsContent(activeSection),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (activeSection == 'Summary' ||
                      activeSection == 'Sample' ||
                      activeSection == 'Graph') ...[
                    _smallButton('Default'),
                    const SizedBox(width: 8),
                  ],
                  _smallButton('OK'),
                  const SizedBox(width: 8),
                  _smallButton('Cancel'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recapOptionNav(String label, bool active) {
    return Container(
      height: 34,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      color: active ? AppTheme.tableHeaderBlue : Colors.transparent,
      child: Text(
        label,
        style: AppTheme.bodyLarge.copyWith(
          color: AppTheme.textPrimary,
          fontSize: 11,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _recapOptionsContent(String section) {
    switch (section) {
      case 'Group':
        return _recapGroupOptions();
      case 'Summary':
        return _recapSummaryOptions();
      case 'Range':
        return _recapRangeOptions();
      case 'Report':
        return _recapReportOptions();
      case 'Sample':
        return _recapSampleOptions();
      default:
        return _recapGraphOptions();
    }
  }

  Widget _recapGroupOptions() {
    const groups = [
      'Summary',
      'Cost Distribution',
      'Daily Cost',
      'Depth Cost',
      'Cumulative Cost',
      'Drilling Data',
      'Mud Properties',
      'Hydraulics',
      'Solids',
      'Volume',
      'Usage',
      'Concentration',
      'Time Distribution',
      'SCE',
      'Bit',
      'Remarks',
      'Interval',
      'Survey',
      'Customized',
      'Engineer',
      'Safety',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Groups displayed in Recap'),
        Expanded(child: _recapCheckWrap(groups)),
      ],
    );
  }

  Widget _recapSummaryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Dashboard (up to 3)'),
        _recapCheckWrap(const [
          'Depth with Target',
          'Cost with Budget',
          'Day with Goal',
        ]),
        const SizedBox(height: 6),
        _sectionHeader('Cost Distribution (up to 2)'),
        _recapCheckWrap(const [
          'Top 10 Products',
          'Product',
          'Group',
          'Package',
          'Service',
          'Engineering',
          'All Categories',
        ]),
        const SizedBox(height: 6),
        _sectionHeader('Progress (up to 3)'),
        Expanded(
          child: _recapCheckWrap(const [
            'Depth',
            'Cumulative Product Cost',
            'Cumulative Service Cost',
            'Cumulative Total Cost',
            'Mud Weight',
            'Funnel Viscosity',
            'PV',
            'YP',
            'ROP',
            'RPM',
            'Bottom-hole ECD',
            'LGS',
            'HGS',
          ]),
        ),
      ],
    );
  }

  Widget _recapRangeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Recap Range'),
        _radioMock('All available reports', selected: true),
        _recapRangeRow('Date', 'From date', 'To date'),
        _recapRangeRow('Report number', 'From report', 'To report'),
        _recapRangeRow('Drilling interval', 'Select interval', ''),
      ],
    );
  }

  Widget _recapRangeRow(String label, String from, String to) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.radio_button_off, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: AppTheme.bodyLarge.copyWith(fontSize: 11),
            ),
          ),
          _recapInputMock(from),
          if (to.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('to'),
            ),
            _recapInputMock(to),
          ],
        ],
      ),
    );
  }

  Widget _recapReportOptions() {
    const sections = [
      'Cost Distribution',
      'Daily Cost',
      'Depth Cost',
      'Cumulative Cost',
      'Drilling Data',
      'Mud Properties',
      'Hydraulics',
      'Solids',
      'Volume',
      'Usage',
      'Concentration',
      'Time Distribution',
      'SCE',
      'Bit',
      'Remarks',
      'Interval',
      'Survey',
      'Customized',
      'Engineer',
      'Safety',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Content included in Recap reports'),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 5,
              children: [
                for (final label in sections)
                  SizedBox(
                    width: 198,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyLarge.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.check_box,
                          size: 13,
                          color: Colors.blue,
                        ),
                        Text(
                          ' Graph ',
                          style: AppTheme.bodyLarge.copyWith(fontSize: 9),
                        ),
                        const Icon(
                          Icons.check_box,
                          size: 13,
                          color: Colors.blue,
                        ),
                        Text(
                          ' Table',
                          style: AppTheme.bodyLarge.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _recapSampleOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Mud samples included in Recap'),
        const SizedBox(height: 8),
        _recapCheckWrap(const ['Sample 1', 'Sample 2', 'Sample 3', 'Sample 4']),
      ],
    );
  }

  Widget _recapGraphOptions() {
    const rows = [
      ['Cumulative Cost', 'vs. Day', 'Product', 'Service', 'Engineering'],
      ['Drilling Data', 'vs. Day', 'WOB', 'RPM', 'ROP'],
      ['Mud Properties 1', 'vs. Day', 'MW', 'PV', 'YP'],
      ['Mud Properties 2', 'vs. Day', 'Funnel Visc.', 'Gel 10 sec.', 'Oil'],
      ['Hydraulics', 'vs. Day', 'Pump Rate', 'Pump Pressure', 'ECD'],
      ['Solids Analysis', 'vs. Day', 'LGS', 'HGS', 'Avg. SG'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Line Graph'),
                  _checkboxMock('Show major grid', true),
                  _checkboxMock('Show minor tick marks', true),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Depth Cost Graph'),
                  _radioMock('Vertical Graph', selected: false),
                  _radioMock('2D Well Path', selected: true),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Mud Properties'),
                  _checkboxMock('Plot planned data range', true),
                  _checkboxMock('Show mud type', true),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _sectionHeader('Graph line definitions'),
        Expanded(
          child: Column(
            children: [
              _recapGraphRow(const [
                'Explorer Item',
                'Orientation',
                'Line 1',
                'Line 2',
                'Line 3',
              ], header: true),
              for (final row in rows) _recapGraphRow(row),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recapGraphRow(List<String> cells, {bool header = false}) {
    return Expanded(
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: i == 0 ? 3 : 2,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: header ? AppTheme.tableHeaderBlue : Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 0.6),
                ),
                child: Text(
                  cells[i],
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 9,
                    fontWeight: header ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recapCheckWrap(List<String> labels) {
    return Wrap(
      spacing: 12,
      runSpacing: 2,
      children: [
        for (var i = 0; i < labels.length; i++)
          SizedBox(width: 176, child: _checkboxMock(labels[i], i % 5 != 3)),
      ],
    );
  }

  Widget _recapInputMock(String hint) {
    return Container(
      width: 130,
      height: 25,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFDC),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        hint,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 10,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _recapToolbarPreview({
    required String activeTab,
    required List<(IconData, String)> actions,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final tab in const ['Home', 'Report'])
                Container(
                  width: 92,
                  height: 30,
                  alignment: Alignment.center,
                  color: tab == activeTab
                      ? AppTheme.panelHeaderBlue
                      : AppTheme.tableHeaderBlue,
                  child: Text(
                    tab,
                    style: AppTheme.bodyLarge.copyWith(
                      color: tab == activeTab
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: AppTheme.tableHeaderBlue.withOpacity(0.45),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final action in actions)
                  Tooltip(
                    message: action.$2,
                    child: SizedBox(
                      width: 48,
                      child: Icon(
                        action.$1,
                        size: 20,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputTimeDistributionWindowMock() {
    const explorerItems = [
      'Summary',
      'Detail',
      'Daily Cost',
      'Total Cost',
      'Concentration',
      'Time Distribution',
      'Survey',
      'Alert',
    ];
    const activities = [
      ('Tripping', 7.0, 29.2),
      ('Circulating', 5.0, 20.8),
      ('Run Casing', 4.0, 16.7),
      ('Coring/Reaming', 4.0, 16.7),
      ('Rig-up/Service', 2.0, 8.3),
      ('Drilling', 2.0, 8.3),
    ];

    return Container(
      width: 900,
      height: 430,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Daily Output',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 112,
                  color: const Color(0xFFF1F5FA),
                  padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
                  child: Column(
                    children: [
                      for (final item in explorerItems)
                        Container(
                          height: 28,
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          color: item == 'Time Distribution'
                              ? AppTheme.panelHeaderBlue
                              : Colors.transparent,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyLarge.copyWith(
                              color: item == 'Time Distribution'
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: item == 'Time Distribution'
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Time Distribution',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyLarge.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppTheme.tableBorderBlue,
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(8, 10, 12, 7),
                            child: Column(
                              children: [
                                for (final activity in activities) ...[
                                  _timeDistributionBar(
                                    activity.$1,
                                    activity.$2,
                                    activity.$3,
                                  ),
                                  if (activity != activities.last)
                                    const SizedBox(height: 13),
                                ],
                                const Spacer(),
                                _timeDistributionAxis(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  color: const Color(0xFFF1F5FA),
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      _concentrationViewTab('Graph', true),
                      const SizedBox(height: 4),
                      _concentrationViewTab('Table', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeDistributionBar(String label, double hours, double percent) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label, ${hours.toStringAsFixed(2)} hr, ${percent.toStringAsFixed(1)}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        7,
                        (_) =>
                            Container(width: 1, color: const Color(0xFFD8E1EC)),
                      ),
                    ),
                  ),
                  Container(
                    width:
                        constraints.maxWidth *
                        (percent / 32).clamp(0.0, 1.0).toDouble(),
                    height: 15,
                    color: const Color(0xFF82ACE0),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _timeDistributionAxis() {
    return Padding(
      padding: const EdgeInsets.only(left: 120),
      child: Column(
        children: [
          Container(height: 1, color: AppTheme.tableBorderBlue),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final value in const [
                '0',
                '5',
                '10',
                '15',
                '20',
                '25',
                '30',
              ])
                Text(value, style: AppTheme.bodyLarge.copyWith(fontSize: 8)),
            ],
          ),
          Text('%', style: AppTheme.bodyLarge.copyWith(fontSize: 8)),
        ],
      ),
    );
  }

  Widget _outputConcentrationWindowMock({required bool historyTable}) {
    const explorerItems = [
      'Summary',
      'Detail',
      'Daily Cost',
      'Total Cost',
      'Concentration',
      'Time Distribution',
      'Survey',
      'Alert',
    ];

    return Container(
      width: 900,
      height: historyTable ? 410 : 430,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Daily Output',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 112,
                  color: const Color(0xFFF1F5FA),
                  padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
                  child: Column(
                    children: [
                      for (final item in explorerItems)
                        Container(
                          height: 28,
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          color: item == 'Concentration'
                              ? AppTheme.panelHeaderBlue
                              : Colors.transparent,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyLarge.copyWith(
                              color: item == 'Concentration'
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: item == 'Concentration'
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Concentration - Active System',
                                style: AppTheme.bodyLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              width: 132,
                              height: 25,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDE7),
                                border: Border.all(
                                  color: AppTheme.tableBorderBlue,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Active System',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 17,
                                    color: AppTheme.textPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Expanded(
                          child: historyTable
                              ? _concentrationHistoryTable()
                              : _concentrationGraphs(),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFFF1F5FA),
                  child: Column(
                    children: [
                      _concentrationViewTab('Graph', !historyTable),
                      const SizedBox(height: 4),
                      _concentrationViewTab('Current', false),
                      const SizedBox(height: 4),
                      _concentrationViewTab('History', historyTable),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _concentrationGraphs() {
    const trends = [
      MapEntry('Diesel (gal/bbl)', <Offset>[
        Offset(0.00, 0.88),
        Offset(0.18, 0.88),
        Offset(0.34, 0.74),
        Offset(0.48, 0.82),
        Offset(0.62, 0.42),
        Offset(0.78, 0.22),
        Offset(1.00, 0.18),
      ]),
      MapEntry('Barite (lb/bbl)', <Offset>[
        Offset(0.00, 0.92),
        Offset(0.26, 0.91),
        Offset(0.42, 0.68),
        Offset(0.58, 0.72),
        Offset(0.72, 0.35),
        Offset(0.84, 0.16),
        Offset(1.00, 0.22),
      ]),
      MapEntry('CaCl2 (lb/bbl)', <Offset>[
        Offset(0.00, 0.94),
        Offset(0.20, 0.94),
        Offset(0.32, 0.24),
        Offset(0.46, 0.55),
        Offset(0.62, 0.55),
        Offset(0.76, 0.90),
        Offset(1.00, 0.90),
      ]),
      MapEntry('LGS (lb/bbl)', <Offset>[
        Offset(0.00, 0.92),
        Offset(0.50, 0.92),
        Offset(0.60, 0.48),
        Offset(0.70, 0.62),
        Offset(0.82, 0.30),
        Offset(0.94, 0.16),
        Offset(1.00, 0.18),
      ]),
      MapEntry('Viscosifier (lb/bbl)', <Offset>[
        Offset(0.00, 0.90),
        Offset(0.36, 0.90),
        Offset(0.52, 0.58),
        Offset(0.66, 0.66),
        Offset(0.80, 0.40),
        Offset(1.00, 0.32),
      ]),
    ];

    return Column(
      children: [
        for (var index = 0; index < trends.length; index++) ...[
          Expanded(child: _concentrationTrendRow(trends[index])),
          if (index < trends.length - 1) const SizedBox(height: 3),
        ],
        const SizedBox(height: 2),
        Text(
          'Report sequence',
          style: AppTheme.bodyLarge.copyWith(fontSize: 8),
        ),
      ],
    );
  }

  Widget _concentrationTrendRow(MapEntry<String, List<Offset>> trend) {
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            trend.key,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.tableBorderBlue),
            ),
            child: CustomPaint(
              painter: _ConcentrationTrendPainter(points: trend.value),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _concentrationHistoryTable() {
    const columns = [
      'Date',
      'MD (ft)',
      'Report #',
      'Diesel',
      'Base Fluid',
      'Barite',
      'Weight Mat.',
      'LGS',
    ];
    const rows = [
      [
        '05/01/2022',
        '7,940',
        '18',
        '8.10',
        '47.48',
        '136.53',
        '118.20',
        '1.72',
      ],
      [
        '05/02/2022',
        '9,048',
        '19',
        '11.07',
        '37.29',
        '147.73',
        '128.90',
        '1.94',
      ],
      [
        '05/03/2022',
        '10,882',
        '20',
        '12.43',
        '31.97',
        '181.62',
        '156.34',
        '2.06',
      ],
      [
        '05/04/2022',
        '12,313',
        '21',
        '12.98',
        '31.01',
        '183.81',
        '163.06',
        '2.18',
      ],
      [
        '05/05/2022',
        '15,940',
        '22',
        '13.28',
        '22.41',
        '196.36',
        '253.77',
        '2.42',
      ],
      [
        '05/06/2022',
        '18,567',
        '23',
        '14.38',
        '19.68',
        '205.64',
        '231.71',
        '2.66',
      ],
      [
        '05/07/2022',
        '21,162',
        '24',
        '14.38',
        '19.68',
        '205.64',
        '231.71',
        '2.82',
      ],
      [
        '05/08/2022',
        '22,482',
        '25',
        '14.31',
        '19.87',
        '205.10',
        '233.89',
        '2.91',
      ],
      [
        '05/09/2022',
        '22,482',
        '26',
        '14.30',
        '19.90',
        '205.00',
        '233.90',
        '3.00',
      ],
    ];
    return _outputDetailTable('Concentration History', columns, rows);
  }

  Widget _concentrationViewTab(String label, bool selected) {
    return Container(
      width: 27,
      height: 82,
      alignment: Alignment.center,
      color: selected ? AppTheme.panelHeaderBlue : AppTheme.tableHeaderBlue,
      child: RotatedBox(
        quarterTurns: 1,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _outputSummaryOptionsMock() {
    return _outputOptionsShell(
      selected: 'Summary',
      height: 550,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _optionsGroupTitle('Dashboard (up to 3)'),
                _checkboxMock('Depth with Target', true),
                _checkboxMock('Cost with Budget', true),
                _checkboxMock('Day with Goal', true),
                _checkboxMock('Depth', false),
                _checkboxMock('Cost', false),
                _checkboxMock('Day', false),
                _checkboxMock('Average Cost per Unit Length', false),
                _checkboxMock('Average Daily Cost', false),
                _checkboxMock('Cost vs. Mud Type', false),
                _checkboxMock('Daily Footage', false),
                _checkboxMock('Calendar', false),
                const SizedBox(height: 6),
                _optionsGroupTitle('Cost Distribution (up to 2)'),
                _checkboxMock('Top 10 Products', true),
                _checkboxMock('Product', false),
                _outputGroupChoice('Group', 'Base Fluid'),
                _outputGroupChoice('Group', 'Weight Material'),
                _checkboxMock('Package', false),
                _checkboxMock('Service', false),
                _checkboxMock('Premixed Mud', false),
                _checkboxMock('Engineering', false),
                _checkboxMock('All Categories', true),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _optionsGroupTitle('Progress (up to 3)'),
                _checkboxMock('Depth', true),
                _checkboxMock('Cumulative Product Cost', false),
                _checkboxMock('Cumulative Package Cost', false),
                _checkboxMock('Cumulative Service Cost', false),
                _checkboxMock('Cumulative Engineering Cost', false),
                _checkboxMock('Cumulative Premixed Mud Cost', false),
                _checkboxMock('Cumulative Total Cost', true),
                _checkboxMock('Mud Weight', true),
                _checkboxMock('Funnel Viscosity', false),
                _checkboxMock('PV', false),
                _checkboxMock('YP', false),
                _checkboxMock('ROP', false),
                _checkboxMock('RPM', false),
                _checkboxMock('Bottom Hole ECD', false),
                _checkboxMock('LGS percentage', false),
                _checkboxMock('LGS', false),
                _checkboxMock('HGS percentage', false),
                _checkboxMock('HGS', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputReportOptionsMock() {
    return _outputOptionsShell(
      selected: 'Report',
      height: 310,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _optionsGroupTitle('Daily Report Page'),
          Wrap(
            spacing: 18,
            children: [
              _radioMock('1 Page', selected: true),
              _radioMock('2 Page', selected: false),
              _radioMock('3 Page', selected: false),
            ],
          ),
          const SizedBox(height: 8),
          _optionsGroupTitle('Report Page Size'),
          Wrap(
            spacing: 18,
            children: [
              _radioMock('Legal', selected: true),
              _radioMock('Letter', selected: false),
              _radioMock('A4', selected: false),
            ],
          ),
          const SizedBox(height: 8),
          _optionsGroupTitle('Daily Report'),
          Wrap(
            spacing: 24,
            runSpacing: 2,
            children: [
              SizedBox(
                width: 180,
                child: _checkboxMock('Product Price', false),
              ),
              SizedBox(width: 180, child: _checkboxMock('Product Cost', true)),
              SizedBox(
                width: 180,
                child: _checkboxMock('CCI in Annular Hydraulics', true),
              ),
              SizedBox(
                width: 180,
                child: _checkboxMock('Detailed Pit Information', false),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Total Cost:',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              _radioMock('Previous Total Cost', selected: true),
              const SizedBox(width: 16),
              _radioMock('Interval Total Cost', selected: false),
            ],
          ),
          Row(
            children: [
              Text(
                'Consumption:',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              _radioMock('Total', selected: true),
              const SizedBox(width: 16),
              _radioMock('Interval', selected: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _outputDetailOptionsMock() {
    final left = <({String label, bool checked})>[
      (label: 'Summary', checked: true),
      (label: 'Detail', checked: false),
      (label: 'Daily Cost', checked: true),
      (label: 'Product Chart', checked: true),
      (label: 'Other Categories Chart', checked: true),
      (label: 'Usage Table', checked: false),
      (label: 'Total Cost', checked: true),
      (label: 'Cost Graph', checked: true),
      (label: 'Cost Table', checked: false),
      (label: 'Concentration', checked: true),
      (label: 'Current Table', checked: true),
      (label: 'History Table', checked: false),
      (label: 'Time Distribution', checked: true),
      (label: 'Time Graph', checked: true),
    ];
    final right = <({String label, bool checked})>[
      (label: 'Survey', checked: true),
      (label: 'Survey Graph', checked: true),
      (label: 'Actual Survey Table', checked: false),
      (label: 'Planned Survey Table', checked: false),
      (label: 'Alert', checked: true),
      (label: 'Alert Summary', checked: true),
      (label: 'Alert Usage', checked: true),
      (label: 'Alert Inventory', checked: true),
      (label: 'Alert Table', checked: false),
    ];

    return _outputOptionsShell(
      selected: 'Detail Report',
      height: 370,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in left)
                  _checkboxMock(item.label, item.checked),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in right)
                  _checkboxMock(item.label, item.checked),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputOptionsShell({
    required String selected,
    required double height,
    required Widget child,
  }) {
    return Container(
      width: 620,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: AppTheme.panelHeaderBlue,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Options',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 112,
                  color: const Color(0xFFF3F6FA),
                  child: Column(
                    children: [
                      for (final label in const [
                        'Summary',
                        'Report',
                        'Detail Report',
                      ])
                        _outputOptionNav(label, active: label == selected),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: child),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _smallButton('Default'),
                            const SizedBox(width: 8),
                            _smallButton('OK'),
                            const SizedBox(width: 8),
                            _smallButton('Cancel'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputOptionNav(String label, {required bool active}) {
    return Container(
      height: 34,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active ? AppTheme.tableHeaderBlue : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AppTheme.tableBorderBlue),
        ),
      ),
      child: Text(
        label,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _optionsGroupTitle(String label) {
    return Container(
      height: 22,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.centerLeft,
      color: AppTheme.tableHeaderBlue,
      child: Text(
        label,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _outputGroupChoice(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          const Icon(
            Icons.check_box_outline_blank,
            size: 14,
            color: AppTheme.panelHeaderBlue,
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 46,
            child: Text(
              label,
              style: AppTheme.bodyLarge.copyWith(fontSize: 11),
            ),
          ),
          Container(
            width: 92,
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.tableBorderBlue),
            ),
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outputDashboardPreview() {
    return Container(
      width: 620,
      height: 245,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          _dashboardWellborePreview(),
          const SizedBox(width: 8),
          for (final title in const [
            'KPI',
            'Cost Distribution',
            'Progress',
          ]) ...[
            Expanded(child: _dashboardColumnPreview(title)),
            if (title != 'Progress') const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _dashboardWellborePreview() {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _optionsGroupTitle('Wellbore'),
          Expanded(
            child: CustomPaint(
              painter: _ManualWellborePainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardColumnPreview(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _optionsGroupTitle(title),
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(7, 0, 7, 7),
                decoration: BoxDecoration(
                  color: i == 1
                      ? const Color(0xFFFFFDE7)
                      : const Color(0xFFF4F8FC),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Icon(
                    title == 'Progress'
                        ? Icons.show_chart
                        : (title == 'KPI' ? Icons.speed : Icons.bar_chart),
                    size: 24,
                    color: AppTheme.panelHeaderBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reportRemarksInputMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Remarks'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('5/6/2022', 2),
                      _treeLine('# 24 22482.0 ft', 2),
                      _treeLine('5/7/2022', 2),
                      _treeLine('# 25 22482.0 ft', 2),
                      _treeLine('5/8/2022', 2),
                      _treeLine('# 26 22482.0 ft', 2),
                      _treeLine('5/9/2022', 2),
                      _treeLine('# 27 22482.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _remarksLargeTextBox(
                          'Recommended Tour Treatments',
                          'Transferred out to FDF: 620 bbl of leased 15.2 ppg OBM\nTransferred in from Integrity: 584.9 bbl 15.3 ppg OBM\n\nScreens on location:\nNOV 140s - 16   Patriot 140s - 7\nNOV 170s - 22   Patriot 170s - 22',
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 230,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _remarksMediumTextBox(
                                'Remarks',
                                'Finished RIH before starting down, washed down from 7156.7 ft.\nLog sample temperature remained stable. Circulated and conditioned mud at report end.\n\nTotal Leased OBM: 2,295 bbls\nTotal OBM on Loc.: 3,114 bbls\nGain/Loss for well: +115 bbls',
                              ),
                              const SizedBox(height: 8),
                              _remarksMediumTextBox(
                                'Recap Remarks',
                                'Finished RIH and circulated bottoms up. Maintained mud properties and monitored solids control equipment.',
                              ),
                              const SizedBox(height: 8),
                              _remarksMediumTextBox(
                                'Internal Notes',
                                '',
                                height: 72,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 86,
                          child: Column(
                            children: [
                              _remarksLogoMock(),
                              const SizedBox(height: 6),
                              _smallButton('Upload'),
                              const SizedBox(height: 4),
                              _smallButton('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remarksLargeTextBox(String title, String text) {
    return SizedBox(
      width: 142,
      child: _remarksTextBox(title, text, height: 250),
    );
  }

  Widget _remarksMediumTextBox(
    String title,
    String text, {
    double height = 78,
  }) {
    return _remarksTextBox(title, text, height: height);
  }

  Widget _remarksTextBox(String title, String text, {required double height}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
        Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 0.7),
          ),
          child: Text(
            text,
            overflow: TextOverflow.fade,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 6.8,
              height: 1.18,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _remarksLogoMock() {
    return Container(
      width: 84,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.panelHeaderBlue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.panelHeaderBlue.withOpacity(0.45),
            ),
          ),
          child: Icon(
            Icons.image_outlined,
            color: AppTheme.panelHeaderBlue,
            size: 34,
          ),
        ),
      ),
    );
  }

  Widget _reportSafetyInputMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Safety'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('5/6/2022', 2),
                      _treeLine('# 24 22482.0 ft', 2),
                      _treeLine('5/7/2022', 2),
                      _treeLine('# 25 22482.0 ft', 2),
                      _treeLine('5/8/2022', 2),
                      _treeLine('# 26 22482.0 ft', 2),
                      _treeLine('5/9/2022', 2),
                      _treeLine('# 27 22482.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _smallButton('Add'),
                                const SizedBox(width: 8),
                                _smallButton('Delete'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _safetyCardTableMock(),
                          ],
                        ),
                        const SizedBox(width: 12),
                        _safetyChecklistMock(),
                        const SizedBox(width: 12),
                        _safetyIssueMock(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyCardTableMock() {
    const rows = ['A', 'B', '', '', '', '', '', ''];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _gridCell('', width: 26, header: true, alignCenter: true),
            _gridCell(
              'Safety Card',
              width: 116,
              header: true,
              alignCenter: true,
            ),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          Row(
            children: [
              _gridCell('${i + 1}', width: 26, alignRight: true),
              _gridCell(rows[i], width: 116, yellow: rows[i].isNotEmpty),
            ],
          ),
      ],
    );
  }

  Widget _safetyChecklistMock() {
    const rows = [
      ['Reaction of People', 'section'],
      ['Adjusting PPE', 'yes'],
      ['Changing Positions', 'yes'],
      ['Rearranging Job', 'yes'],
      ['Stopping Job', 'yes'],
      ['Other', 'na'],
      ['Tools and Equipment', 'section'],
      ['Wrong Tool for the Job', 'yes'],
      ['Used Incorrectly', 'yes'],
      ['In Unsafe Condition', 'yes'],
      ['Other', 'na'],
      ['Personal Protective Equipment', 'section'],
      ['Head', 'yes'],
      ['Eyes & Face', 'yes'],
      ['Ears', 'yes'],
      ['Respiratory System', 'na'],
      ['Arms & Hands', 'yes'],
      ['Trunk', 'yes'],
      ['Legs', 'yes'],
      ['Feet', 'no'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _safetyHeaderCell('Safety Checklist', width: 132),
            _safetyHeaderCell('Yes', width: 28),
            _safetyHeaderCell('No', width: 28),
            _safetyHeaderCell('N/A', width: 28),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              _safetyChecklistLabelCell(row[0], section: row[1] == 'section'),
              _safetyStatusCell(row[1] == 'yes', color: Colors.green.shade600),
              _safetyStatusCell(row[1] == 'no', color: Colors.red.shade600),
              _safetyStatusCell(row[1] == 'na', color: Colors.grey.shade500),
            ],
          ),
      ],
    );
  }

  Widget _safetyHeaderCell(String text, {required double width}) {
    return Container(
      width: width,
      height: 18,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: AppTheme.tableHeaderBlue,
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 7,
          height: 1.0,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _safetyChecklistLabelCell(String text, {required bool section}) {
    return Container(
      width: 132,
      height: 13,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: section ? const Color(0xFFD8D8D8) : Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 6.4,
          height: 1.0,
          fontWeight: section ? FontWeight.w800 : FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _safetyStatusCell(bool checked, {required Color color}) {
    return Container(
      width: 28,
      height: 13,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: checked
          ? Container(
              width: 10,
              height: 10,
              color: color,
              alignment: Alignment.center,
              child: const Icon(Icons.check, size: 8, color: Colors.white),
            )
          : null,
    );
  }

  Widget _safetyIssueMock() {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Issue',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          Container(
            width: 140,
            height: 84,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Stop before BBS\nObservation\nUnsafe\nIdentify Unsafe Behavior\nClarify Commitment\nObtain Agreement\nFollow-Up',
              style: AppTheme.bodyLarge.copyWith(fontSize: 7.2, height: 1.16),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Action Taken',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          Container(
            width: 140,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reservePitsLargeMock() {
    const headers = [
      'Pit',
      'Calculated Vol.\n(bbl)',
      'Measured Vol.\n(bbl)',
      'MW\n(ppg)',
      'Fluid Type',
    ];
    const widths = [86.0, 100.0, 100.0, 76.0, 122.0];
    const rows = [
      ['Frac 6', '0.00', '', '15.20', ''],
      ['Frac 1', '442.00', '442.00', '18.50', ''],
      ['Frac 2', '258.00', '258.00', '15.20', ''],
      ['Frac 3', '462.00', '462.00', '15.20', ''],
      ['Frac 4', '45.00', '45.00', '15.20', ''],
      ['Frac 5', '0.00', '', '15.20', ''],
      ['Gas Buster', '56.00', '56.00', '15.20', ''],
      ['WBM Disposal', '0.00', '', '', ''],
      ['Mixing Pits', '0.00', '', '', ''],
      ['Frac 7', '0.00', '', '15.20', ''],
    ];

    return Container(
      width: 502,
      height: 292,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            child: Row(
              children: [
                Text(
                  'Reserve Pits',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 7.4,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                _concentrationIconMock(),
                const SizedBox(width: 18),
              ],
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < headers.length; i++)
                _snapshotCell(
                  headers[i],
                  width: widths[i],
                  header: true,
                  alignCenter: true,
                  fill: AppTheme.tableHeaderBlue,
                ),
            ],
          ),
          for (final row in rows)
            Row(
              children: [
                for (var i = 0; i < widths.length; i++)
                  _snapshotCell(
                    row[i],
                    width: widths[i],
                    alignRight: i > 0 && i < 4,
                    fill: i == 0 || i == 1
                        ? const Color(0xFFFFFFCC)
                        : Colors.white,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _concentrationIconMock() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFFFB13B),
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(3),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          9,
          (_) =>
              Container(margin: const EdgeInsets.all(0.6), color: Colors.white),
        ),
      ),
    );
  }

  Widget _pitConcentrationMock() {
    const headers = ['', 'Product', 'Unit', 'Start Conc.', 'End Conc.'];
    const widths = [34.0, 212.0, 86.0, 84.0, 84.0];
    const rows = [
      ['1', 'DIESEL, GAL (gal/bbl)', '1.00 gal', '14.4', '14.3'],
      ['2', 'DIESEL, GAL - C (gal/bbl)', '1.00 gal', '19.7', '19.9'],
      ['3', 'BARITE 4.1, TON (lb/bbl)', '1.00 Ton', '205.6', '205.0'],
      ['4', 'BARITE 4.1, TON - C (lb/bbl)', '1.00 Ton', '231.7', '233.9'],
      ['5', 'BX, 5 GAL (lb/bbl)', '30.00 lb', '', ''],
      ['6', 'CACL, 50 # (lb/bbl)', '50.00 lb', '3.8', '3.8'],
      ['7', 'VG - PLUS, 50 # (lb/bbl)', '50.00 lb', '', ''],
      ['8', 'GEL, 100 # (lb/bbl)', '100.00 lb', '', ''],
      ['9', 'LIME, 50 # (lb/bbl)', '50.00 lb', '12.9', '12.8'],
      ['10', 'PAC LV, 50 # (lb/bbl)', '50.00 lb', '', ''],
      ['11', 'PRIMO PAC HV, 50 # (lb/bbl)', '50.00 lb', '', ''],
      ['12', 'SPA, 50 # (lb/bbl)', '50.00 lb', '', ''],
      ['13', 'SULFONATED ASPHALT, 50 # (lb/bbl)', '50.00 lb', '0.1', '0.1'],
      ['14', 'DESCO, 25 # (lb/bbl)', '25.00 lb', '', ''],
      ['15', 'DRILL VIS, 5 GAL (gal/bbl)', '5.00 gal', '', ''],
      ['16', 'SOAP STICKS, EA (lb/bbl)', 'each', '', ''],
      ['17', 'SAPP STICKS, EA (lb/bbl)', 'each', '', ''],
    ];

    return Container(
      width: 530,
      height: 406,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        border: Border.all(color: Colors.blue.shade500),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  'Pit Concentration',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.close, size: 14, color: Colors.grey.shade700),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 158,
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    'Active System',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 8.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 18,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < headers.length; i++)
                      _snapshotCell(
                        headers[i],
                        width: widths[i],
                        header: true,
                        alignCenter: true,
                        fill: AppTheme.tableHeaderBlue,
                      ),
                  ],
                ),
                for (final row in rows)
                  Row(
                    children: [
                      for (var i = 0; i < widths.length; i++)
                        _snapshotCell(
                          row[i],
                          width: widths[i],
                          alignRight: i == 0 || i > 2,
                          fill: i == 1 ? const Color(0xFFFFFFCC) : Colors.white,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: _smallButton('OK'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pitSnapshotMock() {
    return Container(
      width: 655,
      height: 388,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        border: Border.all(color: Colors.blue.shade400),
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  'Pit Snapshot',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 8,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.close, size: 14, color: Colors.grey.shade700),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 226,
                    child: Column(
                      children: [
                        Text(
                          '*TEST WELL 1, Daily Report 26',
                          style: AppTheme.bodyLarge.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 222,
                          height: 255,
                          child: CustomPaint(
                            painter: const _PitSnapshotSchematicPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _pitConnectionListMock(),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 225,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pitSnapshotVolumeSummaryMini(),
                        const SizedBox(height: 8),
                        _pitSnapshotConcentrationMini(),
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _smallButton('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pitConnectionListMock() {
    const rows = [
      ['Active System, 385.00 bbl, OBM', true],
      ['Slug Pit, 18.00 bbl, OBM', true],
      ['Trip Tank, bbl', true],
      ['Frac 6, bbl', false],
      ['Frac 1, 442.00 bbl', false],
      ['Frac 2, 258.00 bbl', false],
      ['Frac 3, 462.00 bbl', false],
      ['Frac 4, 45.00 bbl', false],
      ['Frac 5, bbl', false],
      ['Gas Buster, 56.00 bbl', false],
      ['WBM Disposal, bbl', false],
      ['Mixing Pits, bbl', false],
    ];
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7, color: const Color(0xFFE97B31)),
              const SizedBox(width: 4),
              Text(
                'Active Pits',
                style: AppTheme.bodyLarge.copyWith(fontSize: 6.2),
              ),
              const SizedBox(width: 8),
              Container(width: 7, height: 7, color: const Color(0xFF3E6FB7)),
              const SizedBox(width: 4),
              Text(
                'Reserve Pits',
                style: AppTheme.bodyLarge.copyWith(fontSize: 6.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final row in rows)
            Container(
              height: 18,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.centerLeft,
              color: row[1] as bool
                  ? const Color(0xFFE97B31)
                  : const Color(0xFF3E6FB7),
              child: Text(
                row[0] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 6.6,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pitSnapshotConcentrationMini() {
    const headers = ['Product', 'Unit', 'Start Conc.', 'End Conc.'];
    const widths = [86.0, 45.0, 45.0, 45.0];
    const rows = [
      ['DIESEL, GAL (gal/bbl)', '1.00 gal', '14.30', '14.30'],
      ['DIESEL, GAL - C (gal/bbl)', '1.00 gal', '19.70', '19.90'],
      ['BARITE 4.1, TON (lb/bbl)', '1.00 Ton', '205.60', '205.00'],
      ['BARITE 4.1, TON - C', '1.00 Ton', '231.70', '233.90'],
      ['BX, 5 GAL (lb/bbl)', '30.00 lb', '', ''],
      ['CACL, 50 # (lb/bbl)', '50.00 lb', '3.80', '3.80'],
      ['VG - PLUS, 50 # (lb/bbl)', '50.00 lb', '', ''],
      ['GEL, 100 # (lb/bbl)', '100.00 lb', '0.00', '0.00'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pit Concentration',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 6.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              width: 86,
              height: 17,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Active System',
                      style: AppTheme.bodyLarge.copyWith(fontSize: 6.2),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 10,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              _snapshotCell(
                headers[i],
                width: widths[i],
                header: true,
                alignCenter: true,
                fill: AppTheme.tableHeaderBlue,
              ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (var i = 0; i < widths.length; i++)
                _snapshotCell(
                  row[i],
                  width: widths[i],
                  alignRight: i > 1,
                  fill: i == 0 ? const Color(0xFFFFFFCC) : Colors.white,
                ),
            ],
          ),
      ],
    );
  }

  Widget _pitSnapshotVolumeSummaryMini() {
    const rows = [
      ['Active Pit(s)', '0.000'],
      ['Hole', '798.094'],
      ['Circulating', '798.094'],
      ['Total Storage', '10.946'],
      ['Total on Location', '809.040'],
      ['Cum. Leased', '100.000'],
      ['Volume Difference*', '709.040'],
      ['Previous Total on Location', '690.665'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume Summary',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 6.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            _snapshotCell(
              '',
              width: 150,
              header: true,
              fill: AppTheme.tableHeaderBlue,
            ),
            _snapshotCell(
              'Vol. (bbl)',
              width: 70,
              header: true,
              alignCenter: true,
              fill: AppTheme.tableHeaderBlue,
            ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              _snapshotCell(row[0], width: 150, fill: Colors.white),
              _snapshotCell(
                row[1],
                width: 70,
                alignRight: true,
                fill: const Color(0xFFFFFFCC),
              ),
            ],
          ),
      ],
    );
  }

  Widget _reportPitsInputMock({
    bool activeOnly = false,
    bool reserveOnly = false,
  }) {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Pit'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('5/6/2022', 2),
                      _treeLine('# 24 22482.0 ft', 2),
                      _treeLine('5/7/2022', 2),
                      _treeLine('# 25 22482.0 ft', 2),
                      _treeLine('5/8/2022', 2),
                      _treeLine('# 26 22482.0 ft', 2),
                      _treeLine('5/9/2022', 2),
                      _treeLine('# 27 22482.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!reserveOnly) _activePitsMock(),
                            if (!activeOnly && !reserveOnly)
                              const SizedBox(width: 12),
                            if (!activeOnly) _reservePitsMock(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _volumeNameMock(),
                            const SizedBox(width: 12),
                            _haulOffMock(),
                          ],
                        ),
                        const Spacer(),
                        _smallButton('Pit Snapshot'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activePitsMock() {
    const rows = [
      ['Active System', '385.00', '15.10', 'OBM'],
      ['Slug Pit', '18.00', '15.10', 'OBM'],
      ['Trip Tank', '', '', ''],
      ['', '', '', ''],
      ['', '', '', ''],
      ['', '', '', ''],
    ];
    return _snapshotWindowTable(
      title: 'Active Pits',
      headers: const ['Pit', 'Measured Vol.\n(bbl)', 'MW\n(ppg)', 'Mud'],
      rows: rows,
      widths: const [72, 58, 42, 48],
      width: 220,
      height: 122,
    );
  }

  Widget _reservePitsMock() {
    const rows = [
      ['Frac 6', '0.00', '', '15.20', ''],
      ['Frac 1', '442.00', '442.00', '18.50', ''],
      ['Frac 2', '258.00', '258.00', '15.20', ''],
      ['Frac 3', '462.00', '462.00', '15.20', ''],
      ['Frac 4', '45.00', '45.00', '15.20', ''],
      ['Frac 5', '0.00', '', '', ''],
      ['Gas Buster', '56.00', '56.00', '15.20', ''],
      ['WBM Disposal', '0.00', '', '', ''],
      ['Mixing Pits', '0.00', '', '', ''],
      ['Frac 7', '0.00', '', '15.20', ''],
    ];
    return _snapshotWindowTable(
      title: 'Reserve Pits',
      headers: const [
        'Pit',
        'Calculated Vol.\n(bbl)',
        'Measured Vol.\n(bbl)',
        'MW\n(ppg)',
        'Fluid Type',
      ],
      rows: rows,
      widths: const [66, 62, 62, 42, 76],
      width: 308,
      height: 146,
    );
  }

  Widget _volumeNameMock() {
    const rows = [
      ['Active Pits', '403.00'],
      ['Hole', '1448.29'],
      ['Active System', '1851.29'],
      ['End Vol.', '1839.47'],
      ['End Vol. - Active System', '-11.82'],
      ['Total Storage', '1263.00'],
      ['Total on Location', '3114.29'],
      ['Previous Total on Location', '3698.74'],
    ];
    return _snapshotWindowTable(
      title: '',
      headers: const ['Volume Name', 'Volume\n(bbl)'],
      rows: rows,
      widths: const [122, 54],
      width: 176,
      height: 128,
    );
  }

  Widget _haulOffMock() {
    const rows = [
      ['No. of Loads', ''],
      ['Vol.', ''],
      ['Weight', ''],
      ['Oil', ''],
      ['Water', ''],
      ['Solids', ''],
      ['OOC Wt.', ''],
    ];
    return _snapshotWindowTable(
      title: 'Haul Off',
      headers: const ['', ''],
      rows: rows,
      widths: const [78, 70],
      width: 148,
      height: 112,
      showHeader: false,
    );
  }

  Widget _snapshotWindowTable({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required List<double> widths,
    required double width,
    required double height,
    bool showHeader = true,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 6.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (showHeader)
            Row(
              children: [
                for (var i = 0; i < headers.length; i++)
                  _snapshotCell(
                    headers[i],
                    width: widths[i],
                    header: true,
                    alignCenter: true,
                    fill: AppTheme.tableHeaderBlue,
                  ),
              ],
            ),
          for (final row in rows)
            Row(
              children: [
                for (var i = 0; i < widths.length; i++)
                  _snapshotCell(
                    i < row.length ? row[i] : '',
                    width: widths[i],
                    alignRight: i > 0,
                    fill: i == 0 ? const Color(0xFFFFFFCC) : Colors.white,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _inventorySnapshotMock() {
    const headers = [
      'Category',
      '#',
      'Item',
      'Code',
      'Unit',
      'Price\n(\$)',
      'Initial',
      'Rec.',
      'Ret.',
      'Adj.',
      'Used',
      'Final',
      'Pre-tax\n(\$)',
      'Cost\n(\$)',
      'Total\n(\$)',
    ];
    const widths = [
      58.0,
      18.0,
      86.0,
      36.0,
      40.0,
      36.0,
      36.0,
      34.0,
      34.0,
      34.0,
      34.0,
      36.0,
      44.0,
      42.0,
      48.0,
    ];
    const rows = [
      [
        'Product',
        '43',
        'NON-LEASE OBM, bbl',
        '',
        '1.00 bbl',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      [
        '',
        '44',
        'VERSATHIN HF, 5 gal',
        '',
        '5.00 gal',
        '166.0',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '1575.8',
      ],
      [
        '',
        '45',
        'BLEND FORCE, 25#',
        '',
        '25.00 lb',
        '20.0',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      [
        'Pre-mixed Mud',
        '1',
        'Report 14 - Receive 1',
        '',
        '1.00 bbl',
        '',
        '',
        '100.0',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      [
        '',
        '2',
        'Report 14 - Receive 2',
        '',
        '1.00 bbl',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      [
        '',
        '3',
        'Report 14 - Receive 3',
        '',
        '1.00 bbl',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      [
        '',
        '4',
        'Report 14 - Receive 4',
        '',
        '1.00 bbl',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      [
        '',
        '5',
        'Report 14 - Receive 5',
        '',
        '1.00 bbl',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      [
        'Package',
        '1',
        'PALLETS, EA',
        '',
        '1',
        '15.0',
        '43.0',
        '',
        '',
        '',
        '',
        '43.0',
        '',
        '',
        '',
      ],
      [
        '',
        '2',
        'SHRINK WRAP, EA',
        '',
        '1',
        '15.0',
        '37.0',
        '',
        '',
        '',
        '',
        '37.0',
        '',
        '',
        '',
      ],
      [
        'Service',
        '1',
        'BULK TANK RENTAL',
        '',
        '1',
        '75.0',
        '',
        '',
        '',
        '',
        '1.0',
        '',
        '75.0',
        '75.0',
        '75.0',
      ],
      [
        '',
        '2',
        'BULK TRUCKING',
        '',
        '1',
        '100.0',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      [
        '',
        '3',
        'SACK TRUCKING',
        '',
        '1',
        '100.0',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      [
        'Engineering',
        '1',
        '24 HR ENG.',
        '',
        '1',
        '950.0',
        '',
        '',
        '',
        '',
        '1.0',
        '',
        '950.0',
        '950.0',
        '970.0',
      ],
      [
        '',
        '2',
        'PER-DIEM',
        '',
        '1',
        '20.0',
        '',
        '',
        '',
        '',
        '1.0',
        '',
        '20.0',
        '20.0',
        '',
      ],
    ];
    const totals = [
      ['Subtotal (\$)', '2498.0'],
      ['Tax (8.45%) (\$)', '122.8'],
      ['Daily Total (\$)', '2620.8'],
      ['Prev. Total (\$)', '28700.8'],
      ['Cum. Total (\$)', '31321.5'],
      ['Interval Total (\$)', '27109.6'],
      ['Stock Balance (\$)', '60158.0'],
      ['Bulk Tank Setup Fee (\$)', ''],
    ];

    Color categoryColor(String category) {
      switch (category) {
        case 'Product':
          return const Color(0xFF4F8ED6);
        case 'Pre-mixed Mud':
          return const Color(0xFF0E78B7);
        case 'Package':
          return const Color(0xFFF5B978);
        case 'Service':
          return const Color(0xFFBED89B);
        case 'Engineering':
          return const Color(0xFFC6B5E4);
      }
      return Colors.white;
    }

    return Container(
      width: 655,
      height: 405,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 22,
            color: const Color(0xFFF7F7F7),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Inventory Snapshot',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 8.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.close,
                  size: 11,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < headers.length; i++)
                _snapshotCell(
                  headers[i],
                  width: widths[i],
                  header: true,
                  alignCenter: i != 2,
                ),
            ],
          ),
          for (final row in rows)
            Row(
              children: [
                _snapshotCell(
                  row[0],
                  width: widths[0],
                  fill: row[0].isEmpty ? Colors.white : categoryColor(row[0]),
                  textColor: row[0].isEmpty
                      ? AppTheme.textPrimary
                      : Colors.white,
                  alignCenter: row[0].isNotEmpty,
                ),
                for (var i = 1; i < row.length; i++)
                  _snapshotCell(
                    row[i],
                    width: widths[i],
                    fill: i == 9 || i == 10
                        ? const Color(0xFFE6E6E6)
                        : Colors.white,
                    alignRight: i > 4,
                  ),
              ],
            ),
          for (final row in totals)
            Row(
              children: [
                _snapshotCell(
                  row[0],
                  width: widths
                      .take(14)
                      .fold<double>(0, (sum, value) => sum + value),
                  alignRight: false,
                ),
                _snapshotCell(row[1], width: widths.last, alignRight: true),
              ],
            ),
        ],
      ),
    );
  }

  Widget _volumeSnapshotMock() {
    return Container(
      width: 655,
      height: 432,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            color: const Color(0xFFF7F7F7),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Volume Snapshot',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 8.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.close,
                  size: 11,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _activeSystemVolumeMock(),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _compactVolumePanel('Reserve Pit Loss', const [
                        ['Dump', ''],
                        ['Evaporation', ''],
                        ['Pit Cleaning', ''],
                      ], width: 245),
                      const SizedBox(height: 8),
                      _compactVolumePanel('Premixed Mud', const [
                        ['Leased Mud Received', '100.000'],
                        ['Leased Mud Returned', ''],
                        ['Non-leased Mud Received', ''],
                        ['Non-leased Mud Returned', ''],
                        ['Cum. Leased', '100.000'],
                      ], width: 245),
                      const SizedBox(height: 8),
                      _volumeSummaryMock(compact: true),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 245,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _smallButton('OK'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeSystemVolumeMock() {
    const rows = [
      ['Start Vol.', '', '234.942'],
      ['Addition', 'Receive Mud', '100.000'],
      ['', 'Base Fluid', ''],
      ['', 'Weight Material', ''],
      ['', 'Products', '1.000'],
      ['', 'Water', '101.000'],
      ['', 'Formation', ''],
      ['', 'Cuttings', ''],
      ['Loss', 'Volume Not Fluid', ''],
      ['', 'Cuttings/Retention', ''],
      ['', 'Seepage', ''],
      ['', 'Dump', ''],
      ['', 'Shakers', ''],
      ['', 'Centrifuge', ''],
      ['', 'Evaporation', '0.000'],
      ['', 'Pit Cleaning', ''],
      ['', 'Formation', ''],
      ['', 'Abandon in Hole', ''],
      ['', 'Left behind Casing', ''],
      ['', 'Tripping', ''],
      ['Transfer', 'From Reserve Pits', ''],
      ['', 'To Reserve Pits', '10.000'],
      ['', 'Return', '-10.000'],
      ['End Vol.', '', '325.943'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active System Volume',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            _snapshotCell('', width: 96, header: true),
            _snapshotCell('', width: 130, header: true),
            _snapshotCell(
              'Vol. (bbl)',
              width: 65,
              header: true,
              alignCenter: true,
            ),
            _snapshotCell('', width: 62, header: true),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              _snapshotCell(row[0], width: 96),
              _snapshotCell(row[1], width: 130),
              _snapshotCell(
                row[2],
                width: 65,
                fill: const Color(0xFFFFFFD8),
                alignRight: true,
              ),
              _snapshotCell(
                row.length > 3 ? row[3] : '',
                width: 62,
                fill: const Color(0xFFFFFFD8),
                alignRight: true,
              ),
            ],
          ),
      ],
    );
  }

  Widget _compactVolumePanel(
    String title,
    List<List<String>> rows, {
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              _snapshotCell('', width: width - 98, header: true),
              _snapshotCell(
                'Vol. (bbl)',
                width: 98,
                header: true,
                alignCenter: true,
              ),
            ],
          ),
          for (final row in rows)
            Row(
              children: [
                _snapshotCell(row[0], width: width - 98),
                _snapshotCell(
                  row[1],
                  width: 98,
                  fill: const Color(0xFFFFFFD8),
                  alignRight: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _additionOperationsTableMock() {
    const rows = [
      ['Receive Mud', 'Receive Mud'],
      ['Base fluid', 'Consume Product'],
      ['Water', 'Consume Product, Add Water'],
      ['Products', 'Consume Product'],
      ['Weight materials', 'Consume Product'],
      ['Formation', 'Other Vol. Addition - Active System'],
      ['Cuttings', 'Other Vol. Addition - Active System'],
    ];
    return SizedBox(
      width: 505,
      child: Column(
        children: [
          Row(
            children: [
              _snapshotCell(
                'Addition',
                width: 245,
                header: true,
                alignCenter: true,
              ),
              _snapshotCell(
                'Operations',
                width: 260,
                header: true,
                alignCenter: true,
              ),
            ],
          ),
          for (final row in rows)
            Row(
              children: [
                _snapshotCell(row[0], width: 245),
                _snapshotCell(row[1], width: 260),
              ],
            ),
        ],
      ),
    );
  }

  Widget _volumeSummaryMock({bool compact = false}) {
    const rows = [
      ['Active Pit(s)', '0.000'],
      ['Hole', '798.094'],
      ['Circulating', '798.094'],
      ['Total Storage', '10.946'],
      ['Total on Location', '809.040'],
      ['Cum. Leased', '100.000'],
      ['Volume Difference*', '709.040'],
      ['Previous Total on Location', '690.665'],
    ];
    final width = compact ? 245.0 : 372.0;
    final labelWidth = compact ? 147.0 : 202.0;
    final valueWidth = compact ? 98.0 : 136.0;
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? 0 : 10),
      decoration: compact
          ? null
          : BoxDecoration(
              color: const Color(0xFFF6F6F6),
              border: Border.all(color: Colors.grey.shade400),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Volume Summary',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: compact ? 8 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              _snapshotCell('', width: labelWidth, header: true),
              _snapshotCell(
                'Vol. (bbl)',
                width: valueWidth,
                header: true,
                alignCenter: true,
              ),
            ],
          ),
          for (final row in rows)
            Row(
              children: [
                _snapshotCell(row[0], width: labelWidth),
                _snapshotCell(
                  row[1],
                  width: valueWidth,
                  fill: const Color(0xFFFFFFD8),
                  alignRight: true,
                ),
              ],
            ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '*Total on Location - Cum. Leased',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 10,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mudTreatedSnapshotMock() {
    const headers = [
      'Addition',
      'Active System\n(bbl)',
      'Frac 1\n(bbl)',
      'Frac 2\n(bbl)',
    ];
    const rows = [
      ['Receive Mud', '100.000', '0', '0'],
      ['Base Fluid', '0', '0', '0'],
      ['Weight Material', '0', '0', '0'],
      ['Products', '1.000', '0.500', '0.447'],
      ['Water', '0', '0', '0'],
      ['Formation', '0', '0', '0'],
      ['Cuttings', '0', '0', '0'],
      ['Volume Not Fluid', '0', '0.000', '0.000'],
      ['Sub Total', '101.000', '0.500', '0.447'],
      ['Total', '', '', '101.947'],
    ];

    return Container(
      width: 655,
      height: 336,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 22,
            color: const Color(0xFFF7F7F7),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Mud Treated',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 8.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.close,
                  size: 11,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _snapshotCell(
                        headers[0],
                        width: 70,
                        header: true,
                        alignCenter: true,
                      ),
                      _snapshotCell(
                        headers[1],
                        width: 72,
                        header: true,
                        alignCenter: true,
                      ),
                      _snapshotCell(
                        headers[2],
                        width: 72,
                        header: true,
                        alignCenter: true,
                      ),
                      _snapshotCell(
                        headers[3],
                        width: 72,
                        header: true,
                        alignCenter: true,
                      ),
                    ],
                  ),
                  for (final row in rows)
                    Row(
                      children: [
                        _snapshotCell(row[0], width: 70),
                        _snapshotCell(
                          row[1],
                          width: 72,
                          fill: const Color(0xFFFFFFD8),
                          alignRight: true,
                        ),
                        _snapshotCell(
                          row[2],
                          width: 72,
                          fill: const Color(0xFFFFFFD8),
                          alignRight: true,
                        ),
                        _snapshotCell(
                          row[3],
                          width: 72,
                          fill: const Color(0xFFFFFFD8),
                          alignRight: true,
                        ),
                      ],
                    ),
                  const Spacer(),
                  Text(
                    'Active System',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 7.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                        width: 94,
                        child: Text(
                          'From Reserve Pits',
                          style: AppTheme.bodyLarge.copyWith(fontSize: 7.2),
                        ),
                      ),
                      _snapshotCell(
                        '0.000',
                        width: 72,
                        fill: const Color(0xFFFFFFD8),
                        alignRight: true,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(bbl)',
                        style: AppTheme.bodyLarge.copyWith(fontSize: 7.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SizedBox(
                        width: 94,
                        child: Text(
                          'Mud Treated',
                          style: AppTheme.bodyLarge.copyWith(fontSize: 7.2),
                        ),
                      ),
                      _snapshotCell(
                        '101.000',
                        width: 72,
                        fill: const Color(0xFFFFFFD8),
                        alignRight: true,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(bbl)',
                        style: AppTheme.bodyLarge.copyWith(fontSize: 7.2),
                      ),
                      const Spacer(),
                      _smallButton('Close'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _snapshotCell(
    String text, {
    required double width,
    bool header = false,
    bool alignRight = false,
    bool alignCenter = false,
    Color? fill,
    Color? textColor,
  }) {
    return Container(
      width: width,
      height: header ? 16 : 14.5,
      alignment: alignCenter
          ? Alignment.center
          : alignRight
          ? Alignment.centerRight
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: fill ?? (header ? AppTheme.tableHeaderBlue : Colors.white),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        textAlign: alignCenter ? TextAlign.center : TextAlign.left,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: header ? 5.8 : 6.2,
          height: 1.0,
          fontWeight: header || text.isNotEmpty
              ? FontWeight.w700
              : FontWeight.w400,
          color: textColor ?? AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _operationDetailPage({
    required String operation,
    Widget? body,
    required List<String> paragraphs,
    Widget? screenshot,
    List<List<String>> numberedParagraphs = const [],
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        screenshot ??
            _operationDetailMock(
              operation: operation,
              body: body ?? const SizedBox.shrink(),
            ),
        const SizedBox(height: 24),
        for (final paragraph in paragraphs) _manualParagraph(paragraph),
        for (final numberedParagraph in numberedParagraphs)
          _numberedManualParagraph(numberedParagraph[0], numberedParagraph[1]),
      ],
    );
  }

  Widget _operationDetailMock({
    required String operation,
    required Widget body,
  }) {
    return Container(
      width: 720,
      height: 480,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Operation'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* BURGAN 1', 1),
                      _treeLine('5/6/2022', 2),
                      _treeLine('# 24 22482.0 ft', 2),
                      _treeLine('5/7/2022', 2),
                      _treeLine('# 25 22482.0 ft', 2),
                      _treeLine('5/8/2022', 2),
                      _treeLine('# 26 22482.0 ft', 2),
                      _treeLine('5/9/2022', 2),
                      _treeLine('# 27 22482.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _operationRowsTableMock(activeOperation: operation),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRect(
                            child: SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: body,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Current-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiveProductBodyMock() {
    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _operationFieldRow('BOL No.', ''),
          const SizedBox(height: 8),
          _operationSmallTable(
            title: 'Product',
            headers: const ['Product', 'Code', 'Unit', 'Amount'],
            widths: const [118, 52, 62, 58],
            rows: const [
              ['DIESEL, GAL', '', '1.00 gal', ''],
              ['BARITE 4.1, TON', '', '1.00 Ton', ''],
            ],
            minRows: 8,
          ),
          const SizedBox(height: 8),
          _operationSmallTable(
            title: 'Package',
            headers: const ['Package', 'Code', 'Unit', 'Amount'],
            widths: const [118, 52, 62, 58],
            rows: const [
              ['PALLETS, EA', '', '1', ''],
              ['SHRINK WRAP, EA', '', '1', ''],
            ],
            minRows: 4,
          ),
        ],
      ),
    );
  }

  Widget _returnProductBodyMock() {
    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _operationFieldRow('BOL No.', ''),
              const SizedBox(width: 12),
              _manualActionButton('Return All Inventory', width: 112),
            ],
          ),
          const SizedBox(height: 8),
          _operationSmallTable(
            title: 'Product',
            headers: const ['Product', 'Code', 'Unit', 'Amount'],
            widths: const [118, 52, 62, 58],
            rows: const [
              ['BARITE 4.1, TON', '', '1.00 Ton', ''],
              ['DIESEL, GAL', '', '1.00 gal', '11269.0'],
              ['BY, SACK', '', '30.00 lb', '100.0'],
              ['CACO3, 50#', '', '50.00 lb', '175.0'],
            ],
            minRows: 8,
          ),
          const SizedBox(height: 8),
          _operationSmallTable(
            title: 'Package',
            headers: const ['Package', 'Code', 'Unit', 'Amount'],
            widths: const [118, 52, 62, 58],
            rows: const [
              ['PALLETS, EA', '', '1', '12.00'],
              ['SHRINK WRAP, EA', '', '1', '6.00'],
            ],
            minRows: 4,
          ),
        ],
      ),
    );
  }

  Widget _transferMudBodyMock() {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _operationFieldRow('From', 'Active System'),
          const SizedBox(height: 8),
          _operationSmallTable(
            title: '',
            headers: const ['Pit', 'Vol.\n(bbl)'],
            widths: const [130, 80],
            rows: const [
              ['Frac 4', '92.00'],
              ['Frac 6', '80.00'],
            ],
            minRows: 8,
          ),
        ],
      ),
    );
  }

  Widget _receiveMudBodyMock() {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _operationFieldRow('BOL No.', ''),
          const SizedBox(height: 8),
          _operationFormTable(const [
            ['Premixed Mud', 'Report 10 - Receive 9', ''],
            ['MW', '15.20', '(ppg)'],
            ['Mud Type', '', ''],
            ['Leasing Fee', '10.00', '(\$/bbl)'],
            ['From', '', ''],
            ['To', '', ''],
            ['Vol.', '', '(bbl)'],
            ['Leased', 'checked', ''],
          ]),
        ],
      ),
    );
  }

  Widget _returnLostMudBodyMock() {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _operationCheckboxLine('Premixed Mud', false),
          const SizedBox(height: 6),
          _operationFormTable(const [
            ['From', 'Frac 4', ''],
            ['To', 'FFO Langon', ''],
            ['Vol. Returned', '173.00', '(bbl)'],
            ['MW', '', '(ppg)'],
            ['Mud Type', '', ''],
            ['RGL', '', ''],
            ['Vol. Lost', '', '(bbl)'],
            ['Cost of Lost', '', '(\$)'],
            ['Leased', 'checked', ''],
          ]),
        ],
      ),
    );
  }

  Widget _addWaterBodyMock() {
    return SizedBox(
      width: 288,
      child: _operationFormTable(const [
        ['To', 'Active System', ''],
        ['Vol.', '', '(bbl)'],
      ]),
    );
  }

  Widget _switchPitsBodyMock() {
    return SizedBox(
      width: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pitSwitchTable('Active Pits - Check to Move to Reserve Pits', const [
            ['Active System', 'checked'],
            ['Slug Pit', ''],
            ['Trip Tank', ''],
          ]),
          const SizedBox(height: 10),
          _pitSwitchTable('Reserve Pits - Check to Move to Active Pits', const [
            ['Frac 6', ''],
            ['Frac 1', ''],
            ['Frac 2', ''],
            ['Frac 3', ''],
            ['Gas Buster', ''],
            ['Mixing Pits', ''],
          ]),
        ],
      ),
    );
  }

  Widget _switchMudTypeBodyMock() {
    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _switchMudSection(
            '1. Remove Mud from Active Pits',
            'Transfer to',
            const [
              ['Pit', 'Vol.\n(bbl)'],
              ['', ''],
            ],
          ),
          const SizedBox(height: 6),
          _switchMudSection(
            '2. Fill Active Pits',
            'Make Reserve Pits Active Pits',
            const [
              ['Pit', 'Measured Vol.\n(bbl)'],
              ['', ''],
            ],
          ),
          const SizedBox(height: 6),
          _switchMudSection(
            '3. Displace Fluid in Hole with',
            'Reserve Pits',
            const [
              ['Pit', 'Vol.\n(bbl)'],
              ['', ''],
            ],
          ),
        ],
      ),
    );
  }

  Widget _otherVolumeAdditionBodyMock() {
    return SizedBox(
      width: 290,
      child: _operationSmallTable(
        title: 'Other Vol. Addition - Active System',
        headers: const ['Addition', 'Vol.\n(bbl)'],
        widths: const [148, 80],
        rows: const [
          ['Formation', ''],
          ['Cuttings', ''],
          ['Volume Not Fluid', ''],
        ],
        minRows: 6,
      ),
    );
  }

  Widget _mudLossActiveBodyMock() {
    return SizedBox(
      width: 300,
      child: _operationSmallTable(
        title: 'Mud Loss - Active System',
        headers: const ['Loss', 'Vol.\n(bbl)'],
        widths: const [150, 80],
        rows: const [
          ['Cuttings/Retention', ''],
          ['Seepage', ''],
          ['Dump', ''],
          ['Shakers', ''],
          ['Centrifuge', ''],
          ['Evaporation', ''],
          ['Pit Cleaning', ''],
          ['Formation', ''],
          ['Abandon in Hole', ''],
          ['Left behind Casing', ''],
          ['Tripping', ''],
        ],
        minRows: 12,
      ),
    );
  }

  Widget _mudLossReserveBodyMock() {
    return SizedBox(
      width: 340,
      child: _operationSmallTable(
        title: 'Mud Loss - Reserve Pit',
        headers: const [
          'Reserve Pits',
          'Dump\n(bbl)',
          'Evaporation\n(bbl)',
          'Pit Cleaning\n(bbl)',
        ],
        widths: const [106, 70, 78, 78],
        rows: const [
          ['Frac 6', '', '', ''],
          ['Frac 1', '', '', ''],
        ],
        minRows: 12,
      ),
    );
  }

  Widget _operationFieldRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _gridCell(value, width: 145, yellow: true),
      ],
    );
  }

  Widget _operationFormTable(List<List<String>> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Row(
            children: [
              _gridCell(row[0], width: 112),
              _gridCell(
                row[1] == 'checked' ? 'X' : row[1],
                width: 118,
                yellow: true,
                alignCenter: row[1] == 'checked',
              ),
              _gridCell(row[2], width: 58),
            ],
          ),
      ],
    );
  }

  Widget _operationCheckboxLine(String label, bool checked) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade500),
          ),
          child: checked
              ? const Icon(Icons.check, size: 10, color: AppTheme.textPrimary)
              : null,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _operationSmallTable({
    required String title,
    required List<String> headers,
    required List<double> widths,
    required List<List<String>> rows,
    int minRows = 0,
  }) {
    final paddedRows = [
      ...rows,
      for (var i = rows.length; i < minRows; i++)
        List<String>.filled(headers.length, ''),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              title,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              _gridCell(
                headers[i],
                width: widths[i],
                header: true,
                alignCenter: true,
              ),
          ],
        ),
        for (final row in paddedRows)
          Row(
            children: [
              for (var i = 0; i < headers.length; i++)
                _gridCell(
                  i < row.length ? row[i] : '',
                  width: widths[i],
                  yellow: i > 0,
                  alignRight: i > 0,
                ),
            ],
          ),
      ],
    );
  }

  Widget _pitSwitchTable(String title, List<List<String>> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            _gridCell('Pit', width: 130, header: true),
            _gridCell('Checked', width: 62, header: true, alignCenter: true),
            _gridCell(
              'Measured Vol.\n(bbl)',
              width: 78,
              header: true,
              alignCenter: true,
            ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              _gridCell(row[0], width: 130, yellow: true),
              _gridCell(
                row[1] == 'checked' ? 'X' : '',
                width: 62,
                yellow: true,
                alignCenter: true,
              ),
              _gridCell('', width: 78, alignRight: true),
            ],
          ),
      ],
    );
  }

  Widget _switchMudSection(
    String title,
    String choice,
    List<List<String>> rows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        _operationCheckboxLine(choice, true),
        const SizedBox(height: 3),
        _operationSmallTable(
          title: '',
          headers: rows.first,
          widths: const [128, 82],
          rows: rows.skip(1).toList(),
          minRows: 2,
        ),
      ],
    );
  }

  Widget _manualHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTheme.titleMedium.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _manualParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 15,
          height: 1.35,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _manualNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        '*Note - $text',
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 15,
          height: 1.35,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _offshoreConnectionMock() {
    return Container(
      width: 285,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offshore Connection',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          Row(
            children: [
              Expanded(child: _checkboxMock('Riser', true)),
              Expanded(child: _checkboxMock('Boost Line', false)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _checkboxMock('Kill Line', false)),
              Expanded(child: _checkboxMock('Choke Line', false)),
            ],
          ),
          Text(
            'ML = 0.0 (ft)',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 10,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCasedHoleDropdownMock() {
    return SizedBox(
      width: 400,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _reportCasingTable(const [
              ['Conductor', '20.000', '94.000', '18.000'],
              ['Surface', '13.375', '54.000', '12.615'],
              ['', '', '', ''],
              ['', '', '', ''],
              ['', '', '', ''],
            ]),
          ),
          const SizedBox(width: 6),
          _casingDropdownMock(),
        ],
      ),
    );
  }

  Widget _wellInputFrame({
    required String activeTab,
    required double height,
    required Widget child,
  }) {
    return Container(
      width: 645,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 27,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Casing',
                  'Interval',
                  'Plan',
                  'Survey',
                ])
                  Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == activeTab
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* TEST WELL 1', 1),
                      _treeLine('4/12/2022 19:00', 2),
                      _treeLine('# 1 1965.0 ft', 2),
                      _treeLine('4/13/2022 19:00', 2),
                      _treeLine('# 2 3076.0 ft', 2),
                      _treeLine('4/14/2022 18:00', 2),
                      _treeLine('# 3 5156.0 ft', 2),
                      _treeLine('4/15/2022 18:00', 2),
                      _treeLine('# 4 6518.0 ft', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Sample-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _casingGrid({
    required List<String> headers,
    required List<List<String>> rows,
    required int minRows,
  }) {
    final allRows = [
      ...rows,
      for (var i = rows.length; i < minRows; i++)
        List<String>.filled(headers.length, ''),
    ];

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              _gridCell(
                headers[i],
                width: _casingColumnWidth(i),
                header: true,
                alignCenter: true,
              ),
          ],
        ),
        for (final row in allRows)
          Row(
            children: [
              for (var i = 0; i < headers.length; i++)
                _gridCell(
                  row[i],
                  width: _casingColumnWidth(i),
                  yellow: i == 2 || i == 3 || i == 5,
                  alignRight: i >= 2,
                ),
            ],
          ),
      ],
    );
  }

  double _casingColumnWidth(int index) {
    const widths = [74.0, 64.0, 50.0, 54.0, 50.0, 50.0, 56.0, 48.0, 48.0];
    return widths[index];
  }

  Widget _gridCell(
    String text, {
    required double width,
    bool header = false,
    bool yellow = false,
    bool alignRight = false,
    bool alignCenter = false,
  }) {
    return Container(
      width: width,
      height: header ? 30 : 20,
      alignment: alignCenter
          ? Alignment.center
          : alignRight
          ? Alignment.centerRight
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: header
            ? AppTheme.tableHeaderBlue
            : yellow
            ? const Color(0xFFFFFFD8)
            : Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        textAlign: alignCenter ? TextAlign.center : TextAlign.left,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: header ? 8.5 : 9,
          fontWeight: header || text.isNotEmpty
              ? FontWeight.w700
              : FontWeight.w400,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _reportSideField(String label, String value) {
    return Row(
      children: [
        _gridCell(label, width: 78, yellow: false),
        _gridCell(value, width: 52, yellow: true, alignRight: true),
      ],
    );
  }

  Widget _reportCasingTable(List<List<String>> rows) {
    const headers = ['Description', 'OD\n(in)', 'Wt.\n(lb/ft)', 'ID\n(in)'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cased Hole',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            for (final h in headers)
              _gridCell(h, width: 58, header: true, alignCenter: true),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (final cell in row)
                _gridCell(
                  cell,
                  width: 58,
                  yellow: true,
                  alignRight: cell != row[0],
                ),
            ],
          ),
      ],
    );
  }

  Widget _casingDropdownMock() {
    final items = const [
      'Conductor',
      'Surface',
      'Intermediate',
      'Production',
      'Production 5',
    ];
    return Container(
      width: 110,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                item,
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 8.5,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _drillStringMock(List<List<String>> rows) {
    const headers = ['Description', 'OD\n(in)', 'ID\n(in)', 'Len.\n(ft)'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drill String',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Row(
          children: [
            for (final h in headers)
              _gridCell(h, width: 55, header: true, alignCenter: true),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (final cell in row)
                _gridCell(cell, width: 55, alignRight: cell != row[0]),
            ],
          ),
      ],
    );
  }

  Widget _smallBitPanelMock() {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bit',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          _reportSideField('Mfr.', 'ULTRERA'),
          _reportSideField('Type', 'RRJ75U'),
          _reportSideField('No. of Bits', '2'),
          _reportSideField('Size', '12.250'),
          _reportSideField('Depth-in', '80.0'),
          _reportSideField('Depth', '1965.0'),
        ],
      ),
    );
  }

  Widget _wellMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 28,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Well',
                  'Casing',
                  'Interval',
                  'Plan',
                  'Survey',
                ])
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Well'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('* TEST WELL 1', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                      _treeLine('Report 3', 2),
                      _treeLine('Report 4', 2),
                      _treeLine('Report 5', 2),
                      _treeLine('Report 6', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 245,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _wellFieldRow('Well Name/No.', 'TEST WELL 1'),
                          _wellFieldRow('API Well No.', '1703127116'),
                          _wellFieldRow('Spud Date', '1/4/2022'),
                          _wellFieldRow('Section/Township/Range', '32-11N-13W'),
                          _wellFieldRow('Longitude', ''),
                          _wellFieldRow('Latitude', ''),
                          _wellFieldRow('KOP', '', unit: '(ft)'),
                          _wellFieldRow('LP', '', unit: '(ft)'),
                          const SizedBox(height: 12),
                          Text(
                            'Memo',
                            style: AppTheme.bodyLarge.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 245,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Sample-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wellFieldRow(String label, String value, {String unit = ''}) {
    return Row(
      children: [
        Container(
          width: 122,
          height: 20,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            border: Border.all(color: Colors.grey.shade300, width: 0.6),
          ),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(fontSize: 9),
          ),
        ),
        Container(
          width: 92,
          height: 20,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: value.isEmpty ? Colors.white : const Color(0xFFFFFFD8),
            border: Border.all(color: Colors.grey.shade300, width: 0.6),
          ),
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 9,
              fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 31,
          height: 20,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 0.6),
          ),
          child: Text(unit, style: AppTheme.bodyLarge.copyWith(fontSize: 8.5)),
        ),
      ],
    );
  }

  Widget _padDetailPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The user enters pad information such as location, field/block, rig, operator, contractor, company representative, area, water depth, riser details, line IDs, and any other pad-level notes required for the project.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Operator and related selections are loaded from the Mud Company setup. If the Mud Company database is not configured, the related dropdowns may not show selectable values.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        _padDetailMock(),
      ],
    );
  }

  Widget _padDetailMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 28,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Pad',
                  'Inventory',
                  'Pit',
                  'Pump',
                  'SCE',
                  'Formation',
                  'Report',
                  'Alert',
                ])
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Pad'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('Well 1', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                      _treeLine('Well 2', 1),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 220,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final label in const [
                                'Location',
                                'Field/Block',
                                'Rig',
                                'Country/Area',
                                'State/Province',
                                'County',
                                'Operator',
                                'Contractor',
                                'Riser OD',
                                'Choke Line ID',
                                'Kill Line ID',
                              ])
                                _padDetailRow(label),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Logo',
                                style: AppTheme.bodyLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                width: 86,
                                height: 70,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.tableHeaderBlue,
                                  border: Border.all(
                                    color: AppTheme.tableBorderBlue,
                                  ),
                                ),
                                child: Text(
                                  'MSR2\nDMR',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Memo',
                                style: AppTheme.bodyLarge.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _padDetailRow(String label) {
    return Row(
      children: [
        Container(
          width: 104,
          height: 20,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 0.6),
          ),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(fontSize: 10),
          ),
        ),
        Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFD8),
              border: Border.all(color: Colors.grey.shade300, width: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inventoryPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inventoryMock(),
        const SizedBox(height: 22),
        Text(
          'Products, packages, engineering items, and services are selected from the Mud Company setup. After an item is added at Pad level, it is stored with the current project data. If the master item details need to change, update the Mud Company setup first, then pick the inventory again from Inventory Pickup.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _manualBullet(
          'Vol. Addition: when selected, consumed product volume is calculated and added into the mud volume workflow.',
        ),
        _manualBullet(
          'Concentration - Calculate: when selected, the product concentration is calculated and shown in concentration tables.',
        ),
        _manualBullet(
          'Concentration - Plot: becomes available for products with concentration calculation enabled. Select the products that should appear in output and recap concentration plots.',
        ),
        _manualBullet(
          'Pre-mixed mud: records whole mud received or prepared in the field. The product components are still selected from the Mud Company setup.',
        ),
        const SizedBox(height: 16),
        Text(
          'Tax can be enabled for inventory items when tax should be included in report cost calculations. If the tax option is not selected, no tax is applied for that item.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'MSR2_DMR provides three ways to apply changed inventory prices. A changed price is highlighted until it is applied; after applying, the new price is used in the selected report range.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _applyChangedPricesMock(),
        const SizedBox(height: 14),
        _numberedHelp(
          '1.',
          'Apply changed prices to all: use this when the item price was wrong from the first report and should be updated across all reports.',
        ),
        _numberedHelp(
          '2.',
          'Apply changed prices from now on: use this when the new price should apply from the current report date and time forward.',
        ),
        _numberedHelp(
          '3.',
          'Apply changed prices from: use this when the new price should start from a specific date selected by the user.',
        ),
        const SizedBox(height: 10),
        Text(
          'Example: if a product price is corrected after several drilling days, choose the correct price application mode so inventory cost and report totals recalculate from the intended point.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _inventoryMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 28,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Pad',
                  'Inventory',
                  'Pit',
                  'Pump',
                  'SCE',
                  'Formation',
                  'Report',
                  'Alert',
                ])
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Inventory'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('Well 1', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                      _treeLine('Well 2', 1),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _miniTabRow(const ['Products', 'Services']),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _inventoryGrid(
                                  headers: const [
                                    'Product',
                                    'Code',
                                    'SG',
                                    'Unit',
                                    'Price',
                                    'Initial',
                                    'Group',
                                    'Vol.',
                                    'Calc.',
                                    'Plot',
                                    'Tax',
                                  ],
                                  rows: const [
                                    [
                                      'DIESEL',
                                      '',
                                      '0.78',
                                      '1 gal',
                                      '0.00',
                                      '100.00',
                                      'Base Fluid',
                                      'x',
                                      'x',
                                      '',
                                      'x',
                                    ],
                                    [
                                      'BARITE',
                                      '',
                                      '4.10',
                                      '100 Ton',
                                      '145.00',
                                      '100.00',
                                      'Weight Material',
                                      'x',
                                      'x',
                                      '',
                                      'x',
                                    ],
                                    [
                                      'BENTONITE',
                                      '',
                                      '2.60',
                                      '50 lb',
                                      '0.00',
                                      '100.00',
                                      'Viscosifier',
                                      'x',
                                      'x',
                                      'x',
                                      '',
                                    ],
                                    [
                                      'LIME',
                                      '',
                                      '2.20',
                                      '50 lb',
                                      '0.00',
                                      '100.00',
                                      'Alkalinity',
                                      'x',
                                      '',
                                      '',
                                      '',
                                    ],
                                    [
                                      'PAC-LV',
                                      '',
                                      '1.59',
                                      '50 lb',
                                      '0.00',
                                      '100.00',
                                      'Filtration',
                                      'x',
                                      'x',
                                      'x',
                                      '',
                                    ],
                                  ],
                                  height: 155,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Report 10 - Receive',
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: _inventoryGrid(
                                        headers: const [
                                          'Product',
                                          'Code',
                                          'SG',
                                          'Conc.',
                                          'Unit',
                                        ],
                                        rows: const [
                                          ['', '', '', '', ''],
                                          ['', '', '', '', ''],
                                          ['', '', '', '', ''],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Pre-mixed Mud',
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _inventoryGrid(
                                    headers: const [
                                      'Description',
                                      'MW',
                                      'Leasing Fee',
                                      'Mud Type',
                                      'Tax',
                                    ],
                                    rows: const [
                                      ['Receive 1', '15.20', '10.00', '', ''],
                                      ['Receive 2', '15.20', '12.00', '', ''],
                                      ['Receive 3', '15.20', '12.00', '', ''],
                                    ],
                                    height: 78,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bulk Tank Setup Fee',
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _fieldLine('Tax Rate (%)'),
                                  const SizedBox(height: 6),
                                  _smallButton('Inventory Pickup'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Apply Changed Prices',
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  _radioMock('to All', selected: true),
                                  _radioMock('from Now On', selected: false),
                                  Row(
                                    children: [
                                      _radioMock('from', selected: false),
                                      const SizedBox(width: 4),
                                      Expanded(child: _fieldLine('7/1/2026')),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _smallButton('Apply'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventoryGrid({
    required List<String> headers,
    required List<List<String>> rows,
    double? height,
  }) {
    final table = <List<String>>[headers, ...rows];
    return SizedBox(
      height: height,
      child: Column(
        children: [
          for (var rowIndex = 0; rowIndex < table.length; rowIndex++)
            Expanded(
              child: Row(
                children: [
                  for (final cell in table[rowIndex])
                    Expanded(
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: rowIndex == 0
                              ? AppTheme.tableHeaderBlue
                              : const Color(0xFFFFFFD8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          cell,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyLarge.copyWith(
                            fontSize: rowIndex == 0 ? 8 : 9,
                            fontWeight: rowIndex == 0
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _applyChangedPricesMock() {
    return Container(
      width: 378,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply Changed Prices',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _radioMock('to all', selected: true),
          _radioMock('from Now On', selected: false),
          Row(
            children: [
              _radioMock('from', selected: false),
              const SizedBox(width: 10),
              SizedBox(width: 100, child: _fieldLine('7/1/2026')),
              const Spacer(),
              _smallButton('Apply'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pitPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'In the Pit window, pad-level pits are defined for use by the reports. Each row stores the pit description, capacity, and initial active status. The calculated volume assigned to a pit should not exceed the pit capacity.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Initial Active is used for the first report. When checked, the pit starts as part of the active circulating system connected to the pump. When not checked, the pit starts as reserve or storage. After reports already exist, active and reserve status should be changed through the report operation workflow, such as Switch Pit, so report history remains consistent.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        _pitMock(),
      ],
    );
  }

  Widget _pitMock() {
    final rows = const [
      ['1', 'Frac 6', '500.00', ''],
      ['2', 'Active System', '600.00', 'x'],
      ['3', 'Slug Pit', '100.00', 'x'],
      ['4', 'Trip Tank', '80.00', 'x'],
      ['5', 'Frac 1', '500.00', ''],
      ['6', 'Frac 2', '500.00', ''],
      ['7', 'Frac 3', '500.00', ''],
      ['8', 'Frac 4', '500.00', ''],
      ['9', 'Frac 5', '500.00', ''],
      ['10', 'Gas Buster', '65.00', ''],
      ['11', 'WBM Disposal', '2500.00', ''],
      ['12', 'Mixing Pits', '300.00', ''],
      ['13', 'Frac 7', '500.00', ''],
      ['14', '', '', ''],
      ['15', '', '', ''],
      ['16', '', '', ''],
      ['17', '', '', ''],
      ['18', '', '', ''],
      ['19', '', '', ''],
      ['20', '', '', ''],
      ['21', '', '', ''],
      ['22', '', '', ''],
      ['23', '', '', ''],
      ['24', '', '', ''],
      ['25', '', '', ''],
    ];

    return Container(
      width: 338,
      height: 494,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                _pitCell('', width: 34, header: true),
                _pitCell('Pit', width: 106, header: true),
                _pitCell('Capacity\n(bbl)', width: 88, header: true),
                _pitCell('Initial Active', width: 90, header: true),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.tableHeaderBlue,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      for (final row in rows)
                        Expanded(
                          child: Row(
                            children: [
                              _pitCell(row[0], width: 34, alignRight: true),
                              _pitCell(row[1], width: 106),
                              _pitCell(row[2], width: 88, alignRight: true),
                              _pitCell(
                                '',
                                width: 90,
                                checkbox: true,
                                checked: row[3] == 'x',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 17,
                  color: Colors.grey.shade200,
                  child: Column(
                    children: [
                      Container(
                        height: 18,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Expanded(child: Container(color: Colors.grey.shade300)),
                      Container(
                        height: 18,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pitCell(
    String text, {
    required double width,
    bool header = false,
    bool alignRight = false,
    bool checkbox = false,
    bool checked = false,
  }) {
    return Container(
      width: width,
      alignment: checkbox
          ? Alignment.center
          : alignRight
          ? Alignment.centerRight
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: header ? AppTheme.tableHeaderBlue : Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: checkbox
          ? Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 13,
              color: Colors.grey.shade700,
            )
          : Text(
              text,
              maxLines: header ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              textAlign: header ? TextAlign.center : TextAlign.left,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: header ? 8 : 9,
                fontWeight: header || text.isNotEmpty
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: AppTheme.textPrimary,
                height: 1.0,
              ),
            ),
    );
  }

  Widget _pumpPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pumpMock(),
        const SizedBox(height: 24),
        Text(
          'The Pump window defines pad-level pumps that can be selected later in daily reports. Each pump stores the pump type, model, liner ID, rod OD, stroke length, efficiency, displacement, maximum pump pressure, maximum horsepower, and surface line information.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'If the calculated or entered daily report pump pressure and horsepower exceed the maximum values defined here, MSR2_DMR shows warnings in the output alert area so the setup can be reviewed.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Text(
            'Copyright (C) 2026 Bits and Bytes IT Solution. All Rights Reserved.',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pumpMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 28,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Pad',
                  'Inventory',
                  'Pit',
                  'Pump',
                  'SCE',
                  'Formation',
                  'Report',
                  'Alert',
                ])
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Pump'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('Well 1', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                      _treeLine('Well 2', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Pump',
                          style: AppTheme.bodyLarge.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _pumpGrid(),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              border: Border(
                                left: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 0.6,
                                ),
                                right: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 0.6,
                                ),
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Sample-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pumpGrid() {
    final headers = const [
      '#',
      'Type',
      'Model',
      'Liner ID\n(in)',
      'Rod OD\n(in)',
      'Stk. Length\n(ft)',
      'Efficiency\n(%)',
      'Displ.\n(bbl/stk)',
      'Max. Pump P.\n(psi)',
      'Max. HP\n(HP)',
      'Surface Line\nLength (ft)',
      'ID (in)',
    ];
    final rows = const [
      [
        '1',
        'Triplex',
        'PZ-11',
        '6.500',
        '',
        '11.000',
        '95.0',
        '0.1073',
        '',
        '',
        '',
        '',
      ],
      [
        '2',
        'Triplex',
        'PZ-11',
        '5.250',
        '',
        '11.000',
        '95.0',
        '0.0700',
        '',
        '',
        '',
        '',
      ],
      ['3', '', '', '', '', '', '', '', '', '', '', ''],
      ['4', '', '', '', '', '', '', '', '', '', '', ''],
      ['5', '', '', '', '', '', '', '', '', '', '', ''],
      ['6', '', '', '', '', '', '', '', '', '', '', ''],
      ['7', '', '', '', '', '', '', '', '', '', '', ''],
      ['8', '', '', '', '', '', '', '', '', '', '', ''],
      ['9', '', '', '', '', '', '', '', '', '', '', ''],
      ['10', '', '', '', '', '', '', '', '', '', '', ''],
    ];
    final table = <List<String>>[headers, ...rows];

    return SizedBox(
      height: 128,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                for (var rowIndex = 0; rowIndex < table.length; rowIndex++)
                  Expanded(
                    child: Row(
                      children: [
                        for (
                          var colIndex = 0;
                          colIndex < table[rowIndex].length;
                          colIndex++
                        )
                          Expanded(
                            flex: _pumpColumnFlex(colIndex),
                            child: Container(
                              alignment: colIndex == 0 || colIndex >= 3
                                  ? Alignment.center
                                  : Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              decoration: BoxDecoration(
                                color: rowIndex == 0
                                    ? AppTheme.tableHeaderBlue
                                    : colIndex == 4 || colIndex == 7
                                    ? const Color(0xFFFFFFD8)
                                    : Colors.white,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                table[rowIndex][colIndex],
                                maxLines: rowIndex == 0 ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: colIndex == 0 || colIndex >= 3
                                    ? TextAlign.center
                                    : TextAlign.left,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontSize: rowIndex == 0 ? 7.5 : 8.5,
                                  fontWeight:
                                      rowIndex == 0 ||
                                          table[rowIndex][colIndex].isNotEmpty
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  height: 1.0,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 17,
            color: Colors.grey.shade200,
            child: Column(
              children: [
                Container(
                  height: 18,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Expanded(child: Container(color: Colors.grey.shade300)),
                Container(
                  height: 18,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _pumpColumnFlex(int index) {
    switch (index) {
      case 0:
        return 2;
      case 1:
      case 2:
        return 5;
      case 10:
      case 11:
        return 6;
      default:
        return 4;
    }
  }

  Widget _scePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceMock(),
        const SizedBox(height: 18),
        Text(
          'SCE contains two pad-level tables:',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _manualBullet(
          'Shaker: when Plot is selected, shaker screen data can be included in recap plots. If Plot is not selected, the shaker remains available for reports but is not plotted. Up to five shakers can be selected for plotting.',
        ),
        _manualBullet(
          'Solid Control Equipment: when Plot is selected, the equipment data can be included in recap plots. If Plot is not selected, it remains stored but is not shown in recap plots.',
        ),
      ],
    );
  }

  Widget _sceMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 28,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Pad',
                  'Inventory',
                  'Pit',
                  'Pump',
                  'SCE',
                  'Formation',
                  'Report',
                  'Alert',
                ])
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'SCE'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('Well 1', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                      _treeLine('Well 2', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 205,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Shaker',
                                style: AppTheme.bodyLarge.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _sceTable(
                                headers: const [
                                  'Shaker',
                                  'Model',
                                  'No. of Screen',
                                  'Plot',
                                ],
                                rows: const [
                                  ['1', '140/140/140/140', '8', ''],
                                  ['2', '170/170/170/140', '8', ''],
                                  ['3', '170/140/140/140', '8', ''],
                                  ['4', '170/170/140/140', '8', ''],
                                  ['5', '', '', ''],
                                  ['6', '', '', ''],
                                  ['7', '', '', ''],
                                  ['8', '', '', ''],
                                  ['9', '', '', ''],
                                  ['10', '', '', ''],
                                  ['Mud Cleaner', '', '', ''],
                                  ['Dryer', '', '', ''],
                                ],
                                plotColumn: 3,
                                height: 142,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 245,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Solid Control Equipment',
                                style: AppTheme.bodyLarge.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _sceTable(
                                headers: const [
                                  'Type',
                                  'Model 1',
                                  'Model 2',
                                  'Model 3',
                                  'Plot',
                                ],
                                rows: const [
                                  ['Degasser', '', '', '', ''],
                                  ['Desander', '', '', '', ''],
                                  ['Desilter', '', '', '', ''],
                                  ['Centrifuge', '', '', '', ''],
                                  ['Barite Rec.', '', '', '', ''],
                                ],
                                plotColumn: 4,
                                height: 82,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(color: const Color(0xFFF0F0F0)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Sample-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sceTable({
    required List<String> headers,
    required List<List<String>> rows,
    required int plotColumn,
    required double height,
  }) {
    final table = <List<String>>[headers, ...rows];

    return SizedBox(
      height: height,
      child: Column(
        children: [
          for (var rowIndex = 0; rowIndex < table.length; rowIndex++)
            Expanded(
              child: Row(
                children: [
                  for (
                    var colIndex = 0;
                    colIndex < table[rowIndex].length;
                    colIndex++
                  )
                    Expanded(
                      flex: colIndex == 0 ? 4 : 3,
                      child: Container(
                        alignment: colIndex == plotColumn
                            ? Alignment.center
                            : Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: rowIndex == 0
                              ? AppTheme.tableHeaderBlue
                              : Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.6,
                          ),
                        ),
                        child: colIndex == plotColumn && rowIndex > 0
                            ? Icon(
                                Icons.check_box_outline_blank,
                                size: 12,
                                color: Colors.grey.shade700,
                              )
                            : Text(
                                table[rowIndex][colIndex],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontSize: rowIndex == 0 ? 7.5 : 8.5,
                                  fontWeight:
                                      rowIndex == 0 ||
                                          table[rowIndex][colIndex].isNotEmpty
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: AppTheme.textPrimary,
                                  height: 1.0,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _formationPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formation data is optional. When it is entered, the calculated bottom-hole ECD in the daily report is compared with the pore and fracture limits. If ECD is below the pore limit or above the fracture limit, MSR2_DMR shows the proper warning in the output alert table.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _formationMock(),
        const SizedBox(height: 18),
        Text(
          'Pore and fracture information can be entered as density, gradient, or pressure depending on the available formation data. After the input type is selected, related values are calculated into the light-yellow fields from the Formation Pressure action. The graph on the right follows the selected input type; change the input type first when the plotted formation view needs to change.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _formationMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 28,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Pad',
                  'Inventory',
                  'Pit',
                  'Pump',
                  'SCE',
                  'Formation',
                  'Report',
                  'Alert',
                ])
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Formation'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('Well 1', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                      _treeLine('Well 2', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_box,
                                    size: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Pore and Fracture from top downward',
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.settings_outlined,
                                    size: 13,
                                    color: AppTheme.primaryColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _formationGrid(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _formationGraphPanel(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'Formation properties below the last entered depth are constant.',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formationGrid() {
    final headers = const [
      '#',
      'Description',
      'Btm TVD\n(ft)',
      'Density\n(ppg)',
      'Pore\n(ppg)',
      '(psi)',
      'Frac.\n(ppg)',
      '(psi)',
      'Lithology',
    ];
    final rows = const [
      ['1', 'Shale', '1000.0', '10.00', '0.520', '520', '0.572', '572', ''],
      ['2', 'Carbon', '5000.0', '12.00', '0.624', '3120', '0.676', '3380', ''],
      [
        '3',
        'Production',
        '10000.0',
        '13.00',
        '0.676',
        '6760',
        '0.780',
        '7800',
        '',
      ],
      ['4', 'Water', '15000.0', '12.00', '0.624', '9360', '0.676', '10140', ''],
      ['5', '', '', '', '', '', '', '', ''],
      ['6', '', '', '', '', '', '', '', ''],
      ['7', '', '', '', '', '', '', '', ''],
      ['8', '', '', '', '', '', '', '', ''],
      ['9', '', '', '', '', '', '', '', ''],
      ['10', '', '', '', '', '', '', '', ''],
      ['11', '', '', '', '', '', '', '', ''],
      ['12', '', '', '', '', '', '', '', ''],
      ['13', '', '', '', '', '', '', '', ''],
      ['14', '', '', '', '', '', '', '', ''],
      ['15', '', '', '', '', '', '', '', ''],
      ['16', '', '', '', '', '', '', '', ''],
      ['17', '', '', '', '', '', '', '', ''],
      ['18', '', '', '', '', '', '', '', ''],
      ['19', '', '', '', '', '', '', '', ''],
      ['20', '', '', '', '', '', '', '', ''],
      ['21', '', '', '', '', '', '', '', ''],
      ['22', '', '', '', '', '', '', '', ''],
      ['23', '', '', '', '', '', '', '', ''],
    ];
    final table = <List<String>>[headers, ...rows];

    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                for (var rowIndex = 0; rowIndex < table.length; rowIndex++)
                  Expanded(
                    child: Row(
                      children: [
                        for (
                          var colIndex = 0;
                          colIndex < table[rowIndex].length;
                          colIndex++
                        )
                          Expanded(
                            flex: _formationColumnFlex(colIndex),
                            child: Container(
                              alignment: colIndex == 1
                                  ? Alignment.centerLeft
                                  : Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              decoration: BoxDecoration(
                                color: rowIndex == 0
                                    ? AppTheme.tableHeaderBlue
                                    : colIndex == 4 ||
                                          colIndex == 5 ||
                                          colIndex == 6 ||
                                          colIndex == 7
                                    ? const Color(0xFFFFFFD8)
                                    : Colors.white,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                table[rowIndex][colIndex],
                                maxLines: rowIndex == 0 ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: colIndex == 1
                                    ? TextAlign.left
                                    : TextAlign.center,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontSize: rowIndex == 0 ? 7.5 : 8.3,
                                  fontWeight:
                                      rowIndex == 0 ||
                                          table[rowIndex][colIndex].isNotEmpty
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  height: 1.0,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 17,
            color: Colors.grey.shade200,
            child: Column(
              children: [
                Container(
                  height: 18,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Expanded(child: Container(color: Colors.grey.shade300)),
                Container(
                  height: 18,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _formationColumnFlex(int index) {
    switch (index) {
      case 0:
        return 2;
      case 1:
        return 7;
      case 8:
        return 5;
      default:
        return 4;
    }
  }

  Widget _formationGraphPanel() {
    return Container(
      width: 112,
      height: 268,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Stack(
        children: [
          for (var i = 1; i < 5; i++)
            Positioned(
              left: 0,
              right: 0,
              top: i * 52.0,
              child: Container(height: 0.6, color: Colors.grey.shade300),
            ),
          for (var i = 1; i < 4; i++)
            Positioned(
              top: 0,
              bottom: 0,
              left: i * 28.0,
              child: Container(width: 0.6, color: Colors.grey.shade300),
            ),
          Positioned(
            left: 26,
            top: 42,
            width: 2,
            height: 180,
            child: Container(color: Colors.blue.shade500),
          ),
          Positioned(
            left: 58,
            top: 20,
            width: 2,
            height: 210,
            child: Container(color: Colors.red.shade500),
          ),
        ],
      ),
    );
  }

  Widget _padReportPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _padReportMock(),
        const SizedBox(height: 24),
        Text(
          'The user can decide whether selected report parameters are included in hydraulics calculations.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _manualBullet(
          'ROP - Rate of Penetration: when selected, MSR2_DMR calculates cuttings fraction, slip velocity, travel ratio, and the related ECD effect.',
        ),
        _manualBullet(
          'RPM - Rotary Speed: when selected, additional annular pressure loss caused by rotation is included.',
        ),
        _manualBullet(
          'Eccentricity: when selected, the tool joint OD and ID are used to calculate pipe eccentricity and its effect on annular pressure loss.',
        ),
        const SizedBox(height: 14),
        Text(
          'If multiple rheology tests are recorded for the same mud sample, Multi-rheology can be enabled. This allows up to three rheology test data sets to be entered for one mud sample.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _padReportMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 28,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Pad',
                  'Inventory',
                  'Pit',
                  'Pump',
                  'SCE',
                  'Formation',
                  'Report',
                  'Alert',
                ])
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Report'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('Well 1', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                      _treeLine('Well 2', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _reportOptionGroup(
                          'Factors Considered in Hydraulics Calculation',
                          const [
                            ('ROP', true),
                            ('RPM', true),
                            ('Eccentricity', false),
                          ],
                          width: 180,
                        ),
                        const SizedBox(width: 28),
                        _reportOptionGroup('Rheology', const [
                          ('Multi-rheology', false),
                        ], width: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Sample-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportOptionGroup(
    String title,
    List<(String, bool)> options, {
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    option.$2 ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 13,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    option.$1,
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _alertPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The user can specify the safety margin used for comparison.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _alertInputMock(),
        const SizedBox(height: 18),
        Text(
          'MSR2_DMR compares report parameters such as pump pressure, pump horsepower, bottom-hole ECD, and the plan limits defined for each well. Maximum pump pressure and horsepower are taken from the pump table. Pore and fracture limits are taken from the formation table. Planned well values are taken from the Plan tab.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'If a daily report value is within the safe margin, the output alert table shows green. A yellow warning indicates the value is near the limit. A red warning indicates the value is outside the allowed limit.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        _planLimitMock(),
        const SizedBox(height: 22),
        _outputAlertMock(),
      ],
    );
  }

  Widget _alertInputMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Input',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 28,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                const SizedBox(width: 100),
                for (final tab in const [
                  'Pad',
                  'Inventory',
                  'Pit',
                  'Pump',
                  'SCE',
                  'Formation',
                  'Report',
                  'Alert',
                ])
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Alert'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: const Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 105,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('New Pad', 0),
                      _treeLine('Well 1', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                      _treeLine('Well 2', 1),
                      _treeLine('Report 1', 2),
                      _treeLine('Report 2', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _alertMarginRow(),
                        const SizedBox(height: 8),
                        _alertColorBar(),
                        const SizedBox(height: 10),
                        _alertLegend(Colors.green.shade700, 'Safe [0, 80] %'),
                        _alertLegend(
                          Colors.yellow.shade600,
                          'Warning (80, 100] %',
                        ),
                        _alertLegend(Colors.red.shade600, 'Failed'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Text(
              'C:/MSR2_DMR/Sample-Project.msr',
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertMarginRow() {
    return SizedBox(
      width: 185,
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 0.6),
              ),
              child: Text(
                'Safety Margin',
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Container(
            width: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFD8),
              border: Border.all(color: Colors.grey.shade300, width: 0.6),
            ),
            child: Text(
              '80.0',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300, width: 0.6),
            ),
            child: Text('(%)', style: AppTheme.bodyLarge.copyWith(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _alertColorBar() {
    return SizedBox(
      width: 185,
      height: 16,
      child: Row(
        children: [
          Expanded(flex: 8, child: Container(color: Colors.green.shade700)),
          Expanded(flex: 2, child: Container(color: Colors.yellow.shade600)),
          Expanded(flex: 2, child: Container(color: Colors.red.shade600)),
        ],
      ),
    );
  }

  Widget _alertLegend(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 10,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planLimitMock() {
    final rows = const [
      ['TD', '22482.0', '(ft)'],
      ['Days', '27', '(-)'],
      ['Total Cost', '150000.00', r'($)'],
    ];

    return Container(
      width: 405,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Row(
              children: [
                for (final tab in const [
                  'Well',
                  'Casing',
                  'Interval',
                  'Plan',
                  'Survey',
                ])
                  Container(
                    width: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == 'Plan'
                          ? Colors.white
                          : AppTheme.tableHeaderBlue,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final row in rows)
            Row(
              children: [
                _planCell(row[0], width: 180, fill: true),
                _planCell(row[1], width: 120, alignRight: true),
                _planCell(row[2], width: 102),
              ],
            ),
        ],
      ),
    );
  }

  Widget _planCell(
    String text, {
    required double width,
    bool fill = false,
    bool alignRight = false,
  }) {
    return Container(
      width: width,
      height: 26,
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: fill ? const Color(0xFFF0F0F0) : Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: Text(
        text,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 10,
          fontWeight: text.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _outputAlertMock() {
    return Container(
      width: 655,
      height: 370,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 26,
            color: AppTheme.panelHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'MSR2_DMR - Daily Report',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 95,
                  color: const Color(0xFFF3F6FA),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _treeLine('Summary', 0),
                      _treeLine('Detail', 0),
                      _treeLine('Daily Cost', 0),
                      _treeLine('Total Cost', 0),
                      _treeLine('Survey', 0),
                      _treeLine('Alert', 0),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _progressMock(),
                        const SizedBox(height: 10),
                        Text(
                          'Alert',
                          style: AppTheme.bodyLarge.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(child: _alertOutputTable()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressMock() {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      padding: const EdgeInsets.all(7),
      child: Column(
        children: [
          _progressRow('Depth', 0.92, Colors.blue.shade300),
          _progressRow('Day', 0.96, Colors.blue.shade300),
          _progressRow('Cost', 0.40, Colors.red.shade500),
        ],
      ),
    );
  }

  Widget _progressRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              label,
              style: AppTheme.bodyLarge.copyWith(fontSize: 8.5),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertOutputTable() {
    final rows = const [
      ['Pump P.', 'psi', '4830', '0 - 0', 'red'],
      ['Pump HP', 'HP', '1537.5', '0 - 0', 'red'],
      ['BH ECD', 'ppg', '17.35', '12.56 - 14.12', 'red'],
      ['MW', 'ppg', '15.30', '11.00 - 13.00', 'red'],
      ['Viscosity', 'sec/qt', '56.0', '18.0 - 20.0', 'red'],
      ['PV', 'cP', '34.0', '', 'green'],
      ['YP', 'lbf/100ft2', '9.0', '', 'green'],
      ['HTHP Filtrate', 'ml/30min', '8.80', '', 'green'],
    ];

    return Column(
      children: [
        Row(
          children: [
            _alertHeaderCell('Parameter', flex: 4),
            _alertHeaderCell('Unit', flex: 2),
            _alertHeaderCell('Value', flex: 2),
            _alertHeaderCell('Range', flex: 3),
            _alertHeaderCell('Warning', flex: 2),
          ],
        ),
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                _alertBodyCell(row[0], flex: 4),
                _alertBodyCell(row[1], flex: 2),
                _alertBodyCell(row[2], flex: 2, alignRight: true),
                _alertBodyCell(row[3], flex: 3),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: row[4] == 'red'
                          ? Colors.red.shade600
                          : Colors.green.shade700,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _alertHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.tableHeaderBlue,
          border: Border.all(color: Colors.grey.shade300, width: 0.6),
        ),
        child: Text(
          text,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _alertBodyCell(
    String text, {
    required int flex,
    bool alignRight = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 0.6),
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 8.5,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _padContextMenuMock() {
    return Container(
      width: 245,
      height: 185,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 10,
            bottom: 10,
            width: 150,
            child: Container(
              color: const Color(0xFFF4F6F8),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _treeLine('New Pad', 0),
                  _treeLine('Well 1', 1),
                  _treeLine('Report 1', 2),
                  _treeLine('Report 2', 2),
                  _treeLine('Well 2', 1),
                  _treeLine('Report 1', 2),
                ],
              ),
            ),
          ),
          Positioned(
            left: 80,
            top: 24,
            width: 132,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(2, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _contextMenuRow('Add Well', enabled: true),
                  _contextMenuRow('Rename', enabled: false),
                  _contextMenuRow('Expand All', enabled: true),
                  _contextMenuRow('Collapse All', enabled: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextMenuRow(String label, {required bool enabled}) {
    return Container(
      height: 30,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 12,
          color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _menuToolbarPage() {
    const links = ['Home', 'Report', 'Utility & Help'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toolbarOverviewMock(),
        const SizedBox(height: 28),
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: InkWell(
              onTap: () => onNavigate(link),
              child: Text(
                link,
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _toolbarOverviewMock() {
    final items = <({IconData icon, String label})>[
      (icon: Icons.note_add_outlined, label: '1'),
      (icon: Icons.folder_open_outlined, label: '2'),
      (icon: Icons.save_outlined, label: '3'),
      (icon: Icons.copy_outlined, label: '4'),
      (icon: Icons.account_tree_outlined, label: '5'),
      (icon: Icons.description_outlined, label: '6'),
      (icon: Icons.dashboard_customize_outlined, label: '7'),
      (icon: Icons.lock_outline, label: '8'),
      (icon: Icons.play_arrow_outlined, label: '9'),
      (icon: Icons.settings_outlined, label: '10'),
      (icon: Icons.calendar_month_outlined, label: '11'),
    ];

    return Container(
      width: 372,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            child: Row(
              children: [
                for (final tab in const ['Home', 'Report', 'Utility', 'Help'])
                  Container(
                    width: 74,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white24)),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 34,
            color: AppTheme.tableHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: AppTheme.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 32,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: Center(child: _toolbarNumber(item.label)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarNumber(String number) {
    return CircleAvatar(
      radius: 10,
      backgroundColor: Colors.blue.shade600,
      child: Text(
        number,
        style: AppTheme.bodyLarge.copyWith(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _homeToolbarPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toolbarOverviewMock(),
        const SizedBox(height: 22),
        _numberedHelp(
          '1.',
          'New clears the current input entries so a new project or pad file can be started.',
        ),
        _numberedHelp(
          '2.',
          'Open displays a file dialog for selecting an existing MSR2_DMR data file or project file.',
        ),
        _numberedHelp(
          '3.',
          'Save stores the current input data. Use it after editing pad, well, report, inventory, or configuration data.',
        ),
        _numberedHelp(
          '4.',
          'Save As stores the current data under a different file name or location when a separate copy is required.',
        ),
        _numberedHelp(
          '5.',
          'Carry-over Pad copies selected pad information and inventory values into a new pad setup.',
        ),
        const SizedBox(height: 8),
        _carryOverPadMock(),
        const SizedBox(height: 10),
        _manualBullet(
          'Pad data and final inventory: product/package opening values are copied from the final values of the previous pad/report set.',
        ),
        _manualBullet(
          'Pad data and initial inventory: product/package opening values are copied from the configured initial inventory tables.',
        ),
        const SizedBox(height: 10),
        _numberedHelp(
          '6.',
          'New Report creates a blank daily report under the active well. The active well or report must be selected first.',
        ),
        _numberedHelp(
          '7.',
          'Carry-over copies selected values from the previous report into the current report, such as mud properties, operation data, pump data, pit data, and remarks when enabled.',
        ),
        const SizedBox(height: 8),
        _optionsMock(compact: true),
        const SizedBox(height: 10),
        _numberedHelp(
          '8.',
          'Lock changes the edit status of the current screen. Locked reports protect previously entered data from accidental edits.',
        ),
        _numberedHelp(
          '9.',
          'Calculate refreshes the active report calculations. If required inputs are missing, correct the highlighted issue and calculate again.',
        ),
        _numberedHelp(
          '10.',
          'Options controls units, report carry-over preferences, language, backup, solids-analysis display preferences, mud-volume warning, inventory warning, and multiple daily report behavior.',
        ),
        const SizedBox(height: 8),
        _optionsMock(compact: false),
        const SizedBox(height: 12),
        _manualBullet(
          'Carry-over: controls whether mud properties and operation information are copied from the previous report.',
        ),
        _manualBullet(
          'Solids analysis: controls whether negative solids-analysis values are displayed or replaced according to the configured preference.',
        ),
        _manualBullet(
          'Mud volume: enables a warning when the mud volume is not balanced.',
        ),
        _manualBullet(
          'Inventory: enables warning behavior for negative inventory values.',
        ),
        _manualBullet(
          'Multiple Daily Reports: enables multiple reports to be generated for the same day when required.',
        ),
        const SizedBox(height: 10),
        _numberedHelp(
          '11.',
          'Mud Company Setup stores company details, engineers, products, services, operators, categories, currency, and other master data used by pads and daily reports.',
        ),
        const SizedBox(height: 8),
        _mudCompanySetupMock(),
        const SizedBox(height: 12),
        _manualBullet(
          'Import existing master data when a compatible company setup file is available.',
        ),
        _manualBullet('Export current company setup data for reuse or backup.'),
        _manualBullet(
          'Currency settings apply to prices used in inventory, cost, and report calculations.',
        ),
        _manualBullet(
          'Products, services, engineering, operators, and other categories are defined here for later selection in pads and reports.',
        ),
      ],
    );
  }

  Widget _numberedHelp(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              number,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carryOverPadMock() {
    return _dialogMock(
      width: 480,
      title: 'Carry-over Pad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLine('New Pad Name'),
          const SizedBox(height: 14),
          Text(
            'Copy contents',
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _radioMock('Pad data and final inventory', selected: true),
          _radioMock('Pad data and initial inventory', selected: false),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _smallButton('OK'),
              const SizedBox(width: 10),
              _smallButton('Cancel'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionsMock({required bool compact}) {
    return _dialogMock(
      width: compact ? 386 : 445,
      height: compact ? 164 : 410,
      title: 'Options',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _optionNav('Unit', false),
                _optionNav('Report', true),
                _optionNav('Language', false),
                _optionNav('Backup', false),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Carry-over'),
                _checkboxMock('Mud Properties', true),
                _checkboxMock('Operation', true),
                _radioMock('All', selected: true),
                _radioMock('Consume Service Only', selected: false),
                if (!compact) ...[
                  const SizedBox(height: 8),
                  _sectionHeader('Solids Analysis'),
                  _checkboxMock('Show Negative Values', false),
                  _sectionHeader('Mud Vol.'),
                  _checkboxMock('Check Mud Vol.', true),
                  _sectionHeader('Inventory'),
                  _checkboxMock('Negative Inventory Warning', true),
                  _sectionHeader('Multiple Daily Reports'),
                  _checkboxMock('Multiple Daily Reports', true),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _smallButton('OK'),
                      const SizedBox(width: 8),
                      _smallButton('Cancel'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mudCompanySetupMock() {
    return _dialogMock(
      width: 600,
      height: 350,
      title: 'Mud Company Setup',
      child: Row(
        children: [
          SizedBox(
            width: 210,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniTabRow(const [
                  'Mud Company',
                  'Product',
                  'Services',
                  'Others',
                ]),
                const SizedBox(height: 10),
                _fieldLine('Company'),
                _fieldLine('Address'),
                _fieldLine('Phone'),
                _fieldLine('E-mail'),
                const SizedBox(height: 12),
                Container(
                  width: 110,
                  height: 48,
                  alignment: Alignment.center,
                  color: AppTheme.tableHeaderBlue,
                  child: Text(
                    'MSR2_DMR',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _fieldLine('Currency'),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 24,
                  color: AppTheme.tableHeaderBlue,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Engineer',
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 3.8,
                        ),
                    itemCount: 32,
                    itemBuilder: (_, index) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _smallButton('Save'),
                    const SizedBox(width: 8),
                    _smallButton('Close'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogMock({
    required double width,
    double height = 208,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            color: AppTheme.tableHeaderBlue,
            child: Text(
              title,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(10), child: child),
          ),
        ],
      ),
    );
  }

  Widget _fieldLine(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radioMock(String label, {required bool selected}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 14,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 5),
          Text(label, style: AppTheme.bodyLarge.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _checkboxMock(String label, bool checked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 14,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 5),
          Text(label, style: AppTheme.bodyLarge.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Container(
      height: 20,
      margin: const EdgeInsets.only(bottom: 5),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: AppTheme.tableHeaderBlue,
      child: Text(
        label,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _optionNav(String label, bool active) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      color: active ? AppTheme.tableHeaderBlue : Colors.white,
      child: Text(
        label,
        style: AppTheme.bodyLarge.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _smallButton(String label) {
    return Container(
      width: 74,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(label, style: AppTheme.bodyLarge.copyWith(fontSize: 11)),
    );
  }

  Widget _reportToolbarPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportToolbarMock(),
        const SizedBox(height: 28),
        _numberedHelp(
          '1.',
          'Report Manager is used to locate, select, and delete existing reports by well and search criteria. If a report is removed, later inventory and volume values may be recalculated from the remaining report sequence.',
        ),
        const SizedBox(height: 8),
        _reportManagerMock(),
        const SizedBox(height: 18),
        _numberedHelp(
          '2.',
          'Well Comparison lets the user select wells from the current pad or other pads and compare selected well/report information side by side.',
        ),
        const SizedBox(height: 8),
        _wellComparisonMock(),
        const SizedBox(height: 18),
        _numberedHelp(
          '3.',
          'Recap generates summary views when the focus is on a well or report. The recap output collects daily data over the selected well and displays it in tables, charts, and dashboard panels.',
        ),
        const SizedBox(height: 8),
        _mockAppScreenshot(
          title: 'MSR2_DMR - Recap',
          leftMenu: const [
            'Summary',
            'Cost',
            'Usage',
            'Hydraulics',
            'Solids',
            'Volume',
            'Survey',
          ],
          tabs: const ['Home', 'Report'],
          panels: const [
            'Wellbore Schematic',
            'KPI Dashboard',
            'Top Products',
            'Cost Distribution',
            'Progress',
            'Mud Weight',
          ],
        ),
        const SizedBox(height: 18),
        _numberedHelp(
          '4.',
          'Cost of Pad generates a pad-level cost summary report showing current pad cost, well totals, inventory quantities, and product/service cost details.',
        ),
        const SizedBox(height: 8),
        _costOfPadMock(),
      ],
    );
  }

  Widget _reportToolbarMock() {
    final items = <IconData>[
      Icons.manage_search_outlined,
      Icons.compare_arrows_outlined,
      Icons.insert_chart_outlined,
      Icons.receipt_long_outlined,
    ];
    return Container(
      width: 214,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            color: AppTheme.panelHeaderBlue,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 0, 0),
                    child: Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final tab in const [
                      'Home',
                      'Report',
                      'Utility',
                      'Help',
                    ])
                      Container(
                        width: 52,
                        height: 25,
                        alignment: Alignment.center,
                        color: tab == 'Report'
                            ? Colors.white
                            : AppTheme.panelHeaderBlue,
                        child: Text(
                          tab,
                          style: AppTheme.bodyLarge.copyWith(
                            color: tab == 'Report'
                                ? AppTheme.textPrimary
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                for (final icon in items)
                  SizedBox(
                    width: 44,
                    child: Icon(icon, size: 18, color: AppTheme.textPrimary),
                  ),
              ],
            ),
          ),
          Container(
            height: 34,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                for (var i = 1; i <= 4; i++) ...[
                  _toolbarNumber('$i'),
                  const SizedBox(width: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportManagerMock() {
    return _dialogMock(
      width: 590,
      height: 292,
      title: 'Report Manager',
      child: Row(
        children: [
          SizedBox(
            width: 205,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLine('Current Well'),
                Text(
                  'Search Criteria',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Column(
                    children: [
                      for (final item in const [
                        'Date',
                        'Report No.',
                        'Depth',
                        'Mud Weight',
                        'Activity',
                        'Remarks',
                      ])
                        Container(
                          height: 24,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            item,
                            style: AppTheme.bodyLarge.copyWith(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _smallButton('Clear All'),
                    const SizedBox(width: 8),
                    _smallButton('Search'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Result',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Expanded(child: _simpleGrid(columns: 6, rows: 8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _smallButton('Delete'),
                    const SizedBox(width: 8),
                    _smallButton('Select'),
                    const SizedBox(width: 8),
                    _smallButton('Close'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wellComparisonMock() {
    return _dialogMock(
      width: 590,
      height: 310,
      title: 'Well Comparison',
      child: Row(
        children: [
          Expanded(child: _simpleGrid(columns: 6, rows: 7)),
          const SizedBox(width: 14),
          Expanded(child: _simpleGrid(columns: 6, rows: 5)),
        ],
      ),
    );
  }

  Widget _costOfPadMock() {
    return Container(
      width: 485,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            alignment: Alignment.center,
            child: Text(
              'Cost Summary - Pad',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _summaryRow(const ['Pad', 'New Pad', 'Operator', 'MSR2_DMR']),
          _summaryRow(const [
            'Field/Block',
            'Current Field',
            'Contractor',
            'Contractor',
          ]),
          _summaryRow(const ['Generated Date', 'Current Date', '', '']),
          Container(
            height: 26,
            alignment: Alignment.center,
            color: AppTheme.tableHeaderBlue,
            child: Text(
              'Cost Summary',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _simpleGrid(columns: 7, rows: 4, height: 92),
          Container(
            height: 26,
            alignment: Alignment.center,
            color: AppTheme.tableHeaderBlue,
            child: Text(
              'Inventory',
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _simpleGrid(columns: 8, rows: 7, height: 145),
        ],
      ),
    );
  }

  Widget _summaryRow(List<String> cells) {
    return Row(
      children: [
        for (final cell in cells)
          Expanded(
            child: Container(
              height: 24,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, width: 0.6),
              ),
              child: Text(
                cell,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyLarge.copyWith(fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _simpleGrid({
    required int columns,
    required int rows,
    double? height,
  }) {
    return SizedBox(
      height: height,
      child: Column(
        children: [
          for (var row = 0; row < rows; row++)
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < columns; col++)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: row == 0
                              ? AppTheme.tableHeaderBlue
                              : const Color(0xFFFFFFD8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _utilityHelpPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _utilityToolbarMock(),
        const SizedBox(height: 26),
        _numberedHelp(
          '1.',
          'Engineering Tools opens calculation utilities for hydraulics, pressure, mud weight, volume, pump output, oil mud, maximum ROP, solids removal performance, and SCE cost effectiveness.',
        ),
        _numberedHelp(
          '2.',
          'Unit Conversion opens the conversion tool for switching between configured engineering units.',
        ),
        _numberedHelp('3.', 'Calculator opens the Windows system calculator.'),
        _numberedHelp('4.', 'Notepad opens the Windows system notepad.'),
        const SizedBox(height: 18),
        _helpToolbarMock(),
        const SizedBox(height: 24),
        Text(
          'The Help menu contains the user manual, about information, and abbreviation list for MSR2_DMR.',
          style: AppTheme.bodyLarge.copyWith(
            fontSize: 15,
            height: 1.35,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _utilityToolbarMock() {
    final utilityItems = <IconData>[
      Icons.construction_outlined,
      Icons.swap_horiz_outlined,
      Icons.calculate_outlined,
      Icons.note_alt_outlined,
    ];
    return _smallRibbonMock(
      activeTab: 'Utility',
      icons: utilityItems,
      numbers: const ['1', '2', '3', '4'],
      width: 218,
    );
  }

  Widget _helpToolbarMock() {
    final helpItems = <IconData>[
      Icons.info_outline,
      Icons.sort_by_alpha_outlined,
      Icons.menu_book_outlined,
    ];
    return _smallRibbonMock(
      activeTab: 'Help',
      icons: helpItems,
      numbers: const [],
      width: 224,
    );
  }

  Widget _smallRibbonMock({
    required String activeTab,
    required List<IconData> icons,
    required List<String> numbers,
    required double width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 24,
            color: AppTheme.panelHeaderBlue,
            child: Row(
              children: [
                for (final tab in const ['Home', 'Report', 'Utility', 'Help'])
                  Container(
                    width: 54,
                    alignment: Alignment.center,
                    color: tab == activeTab
                        ? Colors.white
                        : AppTheme.panelHeaderBlue,
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        color: tab == activeTab
                            ? AppTheme.textPrimary
                            : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 34,
            color: AppTheme.tableHeaderBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final icon in icons)
                  Expanded(
                    child: Icon(icon, size: 18, color: AppTheme.textPrimary),
                  ),
              ],
            ),
          ),
          if (numbers.isNotEmpty)
            Container(
              height: 34,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (final number in numbers)
                    Expanded(
                      child: Center(child: _toolbarNumber(number)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _calloutNumber(String number, String label) {
    return Container(
      width: 124,
      height: 30,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F3FB),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.blue.shade600,
            child: Text(
              number,
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockTreeStructure() {
    return Container(
      width: 535,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _treeLine('New Pad', 0),
                _treeLine('TEST WELL 1', 1),
                _treeLine('4/12/2026 19:00', 2),
                _treeLine('#1 1965.0 ft', 2),
                _treeLine('4/13/2026 19:00', 2),
                _treeLine('#2 3076.0 ft', 2),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniTabRow(const [
                  'Pad',
                  'Inventory',
                  'Pit',
                  'Pump',
                  'SCE',
                  'Formation',
                  'Report',
                  'Alert',
                ]),
                const SizedBox(height: 8),
                _miniTabRow(const [
                  'Well',
                  'Casing',
                  'Interval',
                  'Plan',
                  'Survey',
                ]),
                const SizedBox(height: 8),
                _miniTabRow(const [
                  'Well',
                  'Mud',
                  'Pump',
                  'Operation',
                  'Pit',
                  'Safety',
                  'Remarks',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _treeLine(String text, int indent) {
    return Padding(
      padding: EdgeInsets.only(left: indent * 12.0),
      child: SizedBox(
        height: 20,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniTabRow(List<String> tabs) {
    return Wrap(
      spacing: 0,
      children: [
        for (final tab in tabs)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.tableHeaderBlue,
              border: Border.all(color: AppTheme.tableBorderBlue),
            ),
            child: Text(
              tab,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _manualBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '-',
            style: AppTheme.bodyLarge.copyWith(fontSize: 15, height: 1.35),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tourStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              number,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyLarge.copyWith(
                fontSize: 15,
                height: 1.35,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockAppScreenshot({
    required String title,
    required List<String> leftMenu,
    required List<String> tabs,
    required List<String> panels,
  }) {
    return Container(
      width: 620,
      height: 275,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.shade300, width: 1),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: AppTheme.panelHeaderBlue,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 26,
            color: AppTheme.tableHeaderBlue,
            child: Row(
              children: [
                for (final tab in tabs)
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppTheme.tableBorderBlue),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 110,
                  color: const Color(0xFFF2F6FB),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in leftMenu)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyLarge.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final panel in panels)
                          Container(
                            width: 145,
                            height: 78,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFD8),
                              border: Border.all(
                                color: AppTheme.tableBorderBlue,
                              ),
                            ),
                            child: Text(
                              panel,
                              style: AppTheme.bodyLarge.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureList() {
    const features = [
      'Mud company setup for products, services and other catalog data',
      'Pad, well and report management in one workflow',
      'Daily mud report entry and review',
      'Pump, pit, SCE, operation and remarks tracking',
      'Well comparison for planned and actual report data',
      'Solids analysis and mud property calculations',
      'Hydraulics and rheology support tables',
      'Cost, usage, concentration and volume reporting',
      'Land and offshore well information support',
      'Water-based, oil-based and synthetic mud type workflows',
      'Salt system support for NaCl, CaCl2, mixed salts and formate brines',
      'Rheology model support for Bingham, Power-law and Herschel-Bulkley data',
      'Inventory movement, received, consumed, returned and lost mud tracking',
      'Safety checklist and operational notes',
      'Low inventory visibility and stock review support',
      'Wellbore schematic and survey-related views',
      'One-page and multi-page report output options',
      'Letter, legal and A4 report page setup',
      'Tabular database style input screens',
      'Unit conversion and customizable unit preferences',
      'Engineering tools for drilling calculations',
      'Automatic local data organization for report continuity',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 15,
                    height: 1.25,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 15,
                      height: 1.25,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _topicBody(String topic) {
    switch (topic) {
      case 'Background':
        return 'MSR2_DMR is built for drilling mud reporting workflows where accurate daily records, clear mud-property tracking, and reliable inventory visibility are required.\n\n'
            'The application helps rig and office teams capture well information, report mud checks, manage pump and pit data, review survey-related information, and prepare structured outputs from the same project dataset.\n\n'
            'Mud engineers can use the system to organize routine reporting tasks such as mud properties, solids analysis, hydraulics-related values, treatments, usage, and stock movement. The goal is to reduce repeated manual entry, keep report data consistent, and make the information easier to review across pads, wells, and reports.\n\n'
            'MSR2_DMR is developed by Bits and Bytes IT Solution for daily drilling mud reporting, engineering support, and operational record management.';
      case 'Engineering Features':
        return 'Engineering tools, mud reporting, pump information, survey views, solids analysis, hydraulics, and inventory records are organized so report data can be reviewed consistently.';
      case 'Copyright and Disclaimer':
        return 'MSR2_DMR, its user interface, documentation, report layouts, and related application content are protected by copyright and are provided by Bits and Bytes IT Solution.\n\n'
            'The software is designed to support drilling mud reporting, engineering review, inventory tracking, and operational record management. Every effort is made to keep workflows and calculations consistent; however, final results depend on the information entered by the user, selected units, configured well data, and field conditions.\n\n'
            'Users are responsible for checking report values, confirming assumptions, and applying professional judgment before using any output for operational or commercial decisions. Bits and Bytes IT Solution does not accept liability for losses, damages, or incorrect decisions resulting from misuse, modified data, incorrect inputs, or unauthorized distribution of this software.';
      case 'Technical Support':
        return 'For questions, comments, or support requests about MSR2_DMR, please contact:\n\n'
            'Bits and Bytes IT Solution\n'
            'First Floor, Office No-2, G-9, G Block,\n'
            'Sector 63, Noida, Uttar Pradesh 201307\n\n'
            'Email: support@bitsandbytesitsolution.com\n'
            'Website: https://bitsandbytesitsolution.com';
      case 'Main Structure':
        return 'MSR2_DMR is organized around the main application areas used during daily drilling mud reporting: Home, Report, Utility, Help, and Admin Control.\n\n'
            'The working screens are grouped so users can move from setup and pad-level information to well data, report entry, calculations, exports, and reference help without changing the project context.';
      case 'Pad (Well)/Report Management':
        return 'Pad, well, and report management keeps operational data connected from the pad level down to individual well reports.\n\n'
            'A pad can contain multiple wells, and each well can maintain report records for mud properties, pumps, pits, operations, remarks, inventory usage, and related engineering review. This structure helps the same dataset flow into comparison, reporting, and export screens.';
      case 'Hardware and System Requirements':
        return 'MSR2_DMR is designed for Windows desktop workstations used for drilling mud reporting and engineering review. Systems with additional memory, faster processors, and reliable storage will provide better performance when working with large report histories or exported spreadsheets.\n\n'
            'The minimum hardware and system requirements are:\n\n'
            'Microsoft Windows 10 or later\n'
            'Microsoft Excel 2016 or later, or a compatible spreadsheet application for opening exported reports\n'
            'Dual-core Intel or AMD processor, 1.4 GHz or higher; quad-core CPU recommended\n'
            '4 GB RAM minimum, 8 GB RAM recommended\n'
            'At least 500 MB free disk space for installation and local report files\n'
            '1280 x 768 display resolution or higher\n'
            'Network/database access when the configured backend is used for shared project data\n\n'
            'For best desktop display, keep Windows display scaling at 100% or use the project-recommended scaling setting.';
      case 'Installing the Software':
        return 'MSR2_DMR is installed from the approved setup package provided by Bits and Bytes IT Solution or your project administrator.\n\n'
            'Before installing the software, sign in to Windows as an administrator or as a user with permission to install desktop applications.\n\n'
            'Run the MSR2_DMR setup file and follow the on-screen instructions. Keep the default installation path unless your organization has provided a specific application folder.\n\n'
            'After setup is complete, start MSR2_DMR from the desktop shortcut or the Windows Start menu.\n\n'
            'Before entering live report data, confirm that the API endpoint, database connection, export folder, and report storage location are configured correctly for your environment.';
      case 'Licensing the Software':
        return 'To obtain or renew an MSR2_DMR software license, contact Bits and Bytes IT Solution or your project administrator.\n\n'
            'Bits and Bytes IT Solution\n'
            'First Floor, Office No-2, G-9, G Block,\n'
            'Sector 63, Noida, Uttar Pradesh 201307\n'
            'Email: support@bitsandbytesitsolution.com\n'
            'Website: https://bitsandbytesitsolution.com\n\n'
            'For license activation:\n\n'
            '1. Start MSR2_DMR from the desktop shortcut or Windows Start menu.\n'
            '2. If license activation is required, enter the license or activation information provided by the administrator.\n'
            '3. Confirm the company/user details and complete activation.\n'
            '4. Restart the application if prompted.\n\n'
            'If activation fails, contact support with the user name, company name, installation details, and any error message shown by the software.';
      case 'Menu/Toolbar':
        return 'The menu and toolbar provide quick access to common input actions such as opening a project, saving data, refreshing calculations, exporting reports, and moving between major application areas.\n\n'
            'Available actions may change depending on the selected pad, well, report, or utility screen.';
      case 'Home':
        return 'The Home menu contains the main project actions used to create, open, save, and manage the active MSR2_DMR work area.';
      case 'Utility & Help':
        return 'The Utility and Help menu areas provide engineering tools, unit conversion, calculator, notepad access, this user manual, abbreviations, and application information.';
      case 'Pad':
        return 'The Pad input area contains data shared across wells and reports. Typical pad-level tabs include inventory, pit, pump, SCE, formation, report, and alert information.';
      case 'Inventory':
        return 'Inventory stores pad-level product, package, service, and engineering quantities used by wells and daily reports. Values entered here can affect usage, cost, and report summaries.';
      case 'Pit':
        return 'Pit stores pad-level pit descriptions and capacities. These entries are used when tracking mud volume and pit-related report information.';
      case 'Pump':
        return 'Pump stores pad-level pump configuration such as pump type, liner size, stroke length, efficiency, output, and related pump setup values.';
      case 'SCE':
        return 'SCE stores solids control equipment information such as shakers, screens, centrifuge, desander, desilter, and related equipment details.';
      case 'Formation':
        return 'Formation stores pad-level formation information used for reference during reporting and engineering review.';
      case 'Alert':
        return 'Alert stores pad-level warning and reminder information used to support review of operational or reporting conditions.';
      case 'Well':
        return 'The Well input area contains well-specific setup data. Typical well-level tabs include well details, casing, interval, plan, and survey information.';
      case 'Casing':
        return 'Casing stores well-level casing and hole-section information used by daily reports, hydraulics, and wellbore-related output views.';
      case 'Interval':
        return 'Interval stores well-level drilling interval information for planning and reporting reference.';
      case 'Plan':
        return 'Plan stores planned well values such as TD, days, and cost targets used for comparison and alert checks.';
      case 'Survey':
        return 'Survey stores directional survey data used for well path, TVD, and related wellbore calculations.';
      case 'Report':
        return 'The Report input area contains daily report data under the selected well. Typical report-level tabs include well, mud, pump, operation, pit, safety, and remarks information.';
      default:
        return '';
    }
  }

  void _goNext() {
    if (topic == 'Comparison Job Explorer') {
      onNavigate(_comparisonJobExplorerLinks.values.first);
      return;
    }
    final comparisonIndex = _comparisonJobExplorerLinks.values
        .toList()
        .indexOf(topic);
    if (comparisonIndex >= 0 &&
        comparisonIndex < _comparisonJobExplorerLinks.length - 1) {
      onNavigate(
        _comparisonJobExplorerLinks.values.elementAt(comparisonIndex + 1),
      );
      return;
    }
    if (topic == 'Recap Job Explorer') {
      onNavigate(_recapJobExplorerLinks.values.first);
      return;
    }
    final recapIndex = _recapJobExplorerLinks.values.toList().indexOf(topic);
    if (recapIndex >= 0 && recapIndex < _recapJobExplorerLinks.length - 1) {
      onNavigate(_recapJobExplorerLinks.values.elementAt(recapIndex + 1));
      return;
    }
    if (topic == 'Recap Home & Report') {
      onNavigate('Recap Options');
      return;
    }
    if (topic == 'Recap Options') {
      onNavigate('Recap Job Explorer');
      return;
    }
    if (topic == 'Recap Toolbar') {
      onNavigate('Recap Home & Report');
      return;
    }
    if (topic == 'Recap Windows') {
      onNavigate('Recap Toolbar');
      return;
    }
    if (topic == 'Output Survey') {
      onNavigate('Output Alert');
      return;
    }
    if (topic == 'Output Time Distribution') {
      onNavigate('Output Survey');
      return;
    }
    if (topic == 'Output Concentration') {
      onNavigate('Output Time Distribution');
      return;
    }
    if (topic == 'Output Total Cost') {
      onNavigate('Output Concentration');
      return;
    }
    if (topic == 'Output Daily Cost') {
      onNavigate('Output Total Cost');
      return;
    }
    if (topic == 'Output Detail') {
      onNavigate('Output Daily Cost');
      return;
    }
    if (topic == 'Output Summary') {
      onNavigate('Output Detail');
      return;
    }
    if (topic == 'Introduction') {
      onNavigate(_introLinks.first);
      return;
    }
    if (topic == 'MSR2_DMR Structure') {
      onNavigate(_structureLinks.first);
      return;
    }
    if (topic == 'Getting Started') {
      onNavigate(_gettingStartedLinks.first);
      return;
    }
    if (topic == 'Input Windows') {
      onNavigate(_inputWindowTopic(_inputWindowLinks.first));
      return;
    }
    if (topic == 'Well') {
      onNavigate('Well Detail');
      return;
    }
    if (topic == 'Well Detail') {
      onNavigate('Casing');
      return;
    }
    final index = _introLinks.indexOf(topic);
    if (index >= 0 && index < _introLinks.length - 1) {
      onNavigate(_introLinks[index + 1]);
      return;
    }
    final structureIndex = _structureLinks.indexOf(topic);
    if (structureIndex >= 0 && structureIndex < _structureLinks.length - 1) {
      onNavigate(_structureLinks[structureIndex + 1]);
      return;
    }
    final gettingStartedIndex = _gettingStartedLinks.indexOf(topic);
    if (gettingStartedIndex >= 0 &&
        gettingStartedIndex < _gettingStartedLinks.length - 1) {
      onNavigate(_gettingStartedLinks[gettingStartedIndex + 1]);
      return;
    }
    final inputWindowIndex = _inputWindowLinks.indexOf(topic);
    if (inputWindowIndex >= 0 &&
        inputWindowIndex < _inputWindowLinks.length - 1) {
      onNavigate(_inputWindowTopic(_inputWindowLinks[inputWindowIndex + 1]));
      return;
    }
    final wellIndex = _wellLevelLinks.indexOf(topic);
    if (wellIndex >= 0 && wellIndex < _wellLevelLinks.length - 1) {
      onNavigate(_wellLevelTopic(_wellLevelLinks[wellIndex + 1]));
      return;
    }
    final operationIndex = _operationLinkLabels.indexOf(topic);
    if (operationIndex >= 0 &&
        operationIndex < _operationLinkLabels.length - 1) {
      onNavigate(_operationLinkLabels[operationIndex + 1]);
      return;
    }
    final reportIndex = _reportLevelLinks.indexOf(_displayTitle);
    if (reportIndex >= 0 && reportIndex < _reportLevelLinks.length - 1) {
      onNavigate(_reportLevelTopic(_reportLevelLinks[reportIndex + 1]));
    }
  }

  void _goBack() {
    if (topic == 'Comparison Job Explorer') {
      onNavigate('Comparison Toolbar');
      return;
    }
    final comparisonIndex = _comparisonJobExplorerLinks.values
        .toList()
        .indexOf(topic);
    if (comparisonIndex == 0) {
      onNavigate('Comparison Job Explorer');
      return;
    }
    if (comparisonIndex > 0) {
      onNavigate(
        _comparisonJobExplorerLinks.values.elementAt(comparisonIndex - 1),
      );
      return;
    }
    if (topic == 'Recap Job Explorer') {
      onNavigate('Recap Options');
      return;
    }
    final recapIndex = _recapJobExplorerLinks.values.toList().indexOf(topic);
    if (recapIndex == 0) {
      onNavigate('Recap Job Explorer');
      return;
    }
    if (recapIndex > 0) {
      onNavigate(_recapJobExplorerLinks.values.elementAt(recapIndex - 1));
      return;
    }
    if (topic == 'Recap Options') {
      onNavigate('Recap Home & Report');
      return;
    }
    if (topic == 'Recap Home & Report') {
      onNavigate('Recap Toolbar');
      return;
    }
    if (topic == 'Recap Toolbar') {
      onNavigate('Recap Windows');
      return;
    }
    if (topic == 'Recap Windows') {
      onNavigate('Output Survey');
      return;
    }
    if (topic == 'Output Survey') {
      onNavigate('Output Time Distribution');
      return;
    }
    if (topic == 'Output Time Distribution') {
      onNavigate('Output Concentration');
      return;
    }
    if (topic == 'Output Concentration') {
      onNavigate('Output Total Cost');
      return;
    }
    if (topic == 'Output Total Cost') {
      onNavigate('Output Daily Cost');
      return;
    }
    if (topic == 'Output Daily Cost') {
      onNavigate('Output Detail');
      return;
    }
    if (topic == 'Output Detail') {
      onNavigate('Output Summary');
      return;
    }
    if (topic == 'Output Summary') {
      onNavigate('Output Job Explorer');
      return;
    }
    if (topic == 'Output Job Explorer') {
      onNavigate('Introduction');
      return;
    }
    if (topic == 'Output Home') {
      onNavigate('Output Toolbar');
      return;
    }
    if (topic == 'Output Options') {
      onNavigate('Introduction');
      return;
    }
    if (topic == 'Pad Detail') {
      onNavigate('Pad');
      return;
    }
    if (topic == 'Well Detail') {
      onNavigate('Well');
      return;
    }
    if (topic == 'Input Report') {
      onNavigate('Input Windows');
      return;
    }
    if (_operationLinkLabels.contains(topic)) {
      onNavigate('Report Operation');
      return;
    }
    if (topic.startsWith('Report ')) {
      onNavigate('Input Report');
      return;
    }
    if (_structureLinks.contains(topic)) {
      onNavigate('MSR2_DMR Structure');
      return;
    }
    if (_gettingStartedLinks.contains(topic)) {
      onNavigate('Getting Started');
      return;
    }
    if (topic == 'Pad Report' ||
        (_padLevelLinks.contains(topic) &&
            topic != 'Pad' &&
            topic != 'Report')) {
      onNavigate('Pad');
      return;
    }
    if (_wellLevelLinks.contains(topic) && topic != 'Well') {
      onNavigate('Well');
      return;
    }
    if (_inputWindowLinks.contains(topic)) {
      onNavigate('Input Windows');
      return;
    }
    if (_menuToolbarLinks.contains(topic)) {
      onNavigate('Menu/Toolbar');
      return;
    }
    onNavigate('Introduction');
  }

  String get _breadcrumb {
    if (_comparisonJobExplorerLinks.containsValue(topic)) {
      return 'MSR2_DMR >> Well Comparison Windows >> Comparison Job Explorer >>';
    }
    if (topic == 'Comparison Job Explorer') {
      return 'MSR2_DMR >> Well Comparison Windows >>';
    }
    if (topic == 'Comparison Toolbar') {
      return 'MSR2_DMR >> Well Comparison Windows >>';
    }
    if (topic == 'Well Comparison Windows') {
      return 'MSR2_DMR >>';
    }
    if (_recapJobExplorerLinks.containsValue(topic)) {
      return 'MSR2_DMR >> Recap Windows >> Recap Job Explorer >>';
    }
    if (topic == 'Recap Job Explorer') {
      return 'MSR2_DMR >> Recap Windows >>';
    }
    if (topic == 'Recap Home & Report' || topic == 'Recap Options') {
      return 'MSR2_DMR >> Recap Windows >> Toolbar >>';
    }
    if (topic == 'Recap Toolbar') {
      return 'MSR2_DMR >> Recap Windows >>';
    }
    if (topic == 'Recap Windows') {
      return 'MSR2_DMR >>';
    }
    if (topic == 'Output Toolbar') {
      return 'MSR2_DMR >> Output Windows >>';
    }
    if (topic == 'Output Home') {
      return 'MSR2_DMR >> Output Windows >> Toolbar >>';
    }
    if (topic == 'Output Survey') {
      return 'MSR2_DMR >> Output Windows >> Output Job Explorer >>';
    }
    if (topic == 'Output Time Distribution') {
      return 'MSR2_DMR >> Output Windows >> Output Job Explorer >>';
    }
    if (topic == 'Output Concentration') {
      return 'MSR2_DMR >> Output Windows >> Output Job Explorer >>';
    }
    if (topic == 'Output Total Cost') {
      return 'MSR2_DMR >> Output Windows >> Output Job Explorer >>';
    }
    if (topic == 'Output Daily Cost') {
      return 'MSR2_DMR >> Output Windows >> Output Job Explorer >>';
    }
    if (topic == 'Output Detail') {
      return 'MSR2_DMR >> Output Windows >> Output Job Explorer >>';
    }
    if (topic == 'Output Summary') {
      return 'MSR2_DMR >> Output Windows >> Output Job Explorer >>';
    }
    if (topic == 'Output Job Explorer') {
      return 'MSR2_DMR >> Output Windows >>';
    }
    if (topic == 'Output Options') {
      return 'MSR2_DMR >> Output Windows >> Toolbar >>';
    }
    if (topic == 'Introduction' ||
        topic == 'MSR2_DMR Structure' ||
        topic == 'Getting Started' ||
        topic == 'Input Windows') {
      return 'MSR2_DMR >>';
    }
    if (_structureLinks.contains(topic)) {
      return 'MSR2_DMR >> MSR2_DMR Structure >>';
    }
    if (_gettingStartedLinks.contains(topic)) {
      return 'MSR2_DMR >> Getting Started >>';
    }
    if (topic == 'Pad Detail') {
      return 'MSR2_DMR >> Input Windows >> Pad >>';
    }
    if (topic == 'Well Detail') {
      return 'MSR2_DMR >> Input Windows >> Well >>';
    }
    if (topic == 'Input Report') {
      return 'MSR2_DMR >> Input Windows >>';
    }
    if (_operationLinkLabels.contains(topic)) {
      return 'MSR2_DMR >> Input Windows >> Report >> Operation >>';
    }
    if (_snapshotLinks.contains(topic)) {
      return 'MSR2_DMR >> Input Windows >> Report >> Snapshots >>';
    }
    if (_reportPitsLinks.contains(topic)) {
      return 'MSR2_DMR >> Input Windows >> Report >> Pits >>';
    }
    if (topic.startsWith('Report ')) {
      return 'MSR2_DMR >> Input Windows >> Report >>';
    }
    if (topic == 'Pad Report' ||
        (_padLevelLinks.contains(topic) &&
            topic != 'Pad' &&
            topic != 'Report')) {
      return 'MSR2_DMR >> Input Windows >> Pad >>';
    }
    if (_wellLevelLinks.contains(topic) && topic != 'Well') {
      return 'MSR2_DMR >> Input Windows >> Well >>';
    }
    if (_inputWindowLinks.contains(topic)) {
      return 'MSR2_DMR >> Input Windows >>';
    }
    if (_menuToolbarLinks.contains(topic)) {
      return 'MSR2_DMR >> Input Windows >> Menu/Toolbar >>';
    }
    return 'MSR2_DMR >> Introduction >>';
  }

  String get _displayTitle {
    for (final entry in _comparisonJobExplorerLinks.entries) {
      if (entry.value == topic) {
        return entry.key;
      }
    }
    for (final entry in _recapJobExplorerLinks.entries) {
      if (entry.value == topic) {
        return entry.key;
      }
    }
    if (topic == 'Recap Home & Report') {
      return 'Home & Report';
    }
    if (topic == 'Recap Options') {
      return 'Options';
    }
    if (topic == 'Output Survey') {
      return 'Survey';
    }
    if (topic == 'Output Time Distribution') {
      return 'Time Distribution';
    }
    if (topic == 'Output Concentration') {
      return 'Concentration';
    }
    if (topic == 'Output Total Cost') {
      return 'Total Cost';
    }
    if (topic == 'Output Daily Cost') {
      return 'Daily Cost';
    }
    if (topic == 'Output Detail') {
      return 'Detail';
    }
    if (topic == 'Output Summary') {
      return 'Summary';
    }
    if (topic == 'Output Options') {
      return 'Options';
    }
    if (topic == 'Output Toolbar') {
      return 'Toolbar';
    }
    if (topic == 'Output Home') {
      return 'Home';
    }
    if (topic == 'Pad Detail') {
      return 'Pad';
    }
    if (topic == 'Pad Report') {
      return 'Report';
    }
    if (topic == 'Well Detail') {
      return 'Well';
    }
    if (topic == 'Input Report' || topic == 'Toolbar Report') {
      return 'Report';
    }
    if (topic.startsWith('Report ')) {
      return topic.replaceFirst('Report ', '');
    }
    return topic;
  }
}

class _ManualWellborePainter extends CustomPainter {
  const _ManualWellborePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final line = Paint()
      ..color = const Color(0xFF26384A)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final casing = Paint()
      ..color = const Color(0xFF5E88B5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final marker = Paint()
      ..color = const Color(0xFFE07B32)
      ..strokeWidth = 4;

    canvas.drawLine(
      Offset(center - 17, 10),
      Offset(center - 17, size.height - 10),
      line,
    );
    canvas.drawLine(
      Offset(center + 17, 10),
      Offset(center + 17, size.height - 10),
      line,
    );
    canvas.drawLine(
      Offset(center - 7, 18),
      Offset(center - 7, size.height - 18),
      casing,
    );
    canvas.drawLine(
      Offset(center + 7, 18),
      Offset(center + 7, size.height - 18),
      casing,
    );
    canvas.drawLine(
      Offset(center - 20, size.height * 0.28),
      Offset(center + 20, size.height * 0.28),
      marker,
    );

    final path = Path()..moveTo(center, size.height * 0.52);
    for (var y = size.height * 0.52; y < size.height - 10; y += 8) {
      path.lineTo(center + ((y ~/ 8).isEven ? 1.5 : -1.5), y);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MainStructureArrowPainter extends CustomPainter {
  const _MainStructureArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    void arrow(Offset start, Offset end) {
      canvas.drawLine(start, end, paint);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      const arrowLength = 8.0;
      const arrowAngle = math.pi / 7;
      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowLength * math.cos(angle - arrowAngle),
          end.dy - arrowLength * math.sin(angle - arrowAngle),
        )
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowLength * math.cos(angle + arrowAngle),
          end.dy - arrowLength * math.sin(angle + arrowAngle),
        );
      canvas.drawPath(path, paint);
    }

    arrow(const Offset(270, 74), const Offset(186, 74));
    arrow(const Offset(104, 134), const Offset(104, 188));
    arrow(const Offset(244, 266), const Offset(290, 266));
    arrow(const Offset(462, 271), const Offset(502, 271));
    arrow(const Offset(152, 340), const Offset(152, 378));
    arrow(const Offset(152, 378), const Offset(290, 438));
    arrow(const Offset(462, 437), const Offset(505, 437));
    arrow(const Offset(45, 340), const Offset(45, 442));
    arrow(const Offset(194, 503), const Offset(230, 526));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PadReportArrowPainter extends CustomPainter {
  const _PadReportArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final blue = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    void arrow(Offset start, Offset end, Paint paint) {
      canvas.drawLine(start, end, paint);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      const arrowLength = 8.0;
      const arrowAngle = math.pi / 7;
      final path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowLength * math.cos(angle - arrowAngle),
          end.dy - arrowLength * math.sin(angle - arrowAngle),
        )
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowLength * math.cos(angle + arrowAngle),
          end.dy - arrowLength * math.sin(angle + arrowAngle),
        );
      canvas.drawPath(path, paint);
    }

    arrow(const Offset(172, 184), const Offset(214, 184), blue);
    arrow(const Offset(248, 184), const Offset(306, 184), red);
    arrow(const Offset(306, 199), const Offset(248, 199), blue);
    arrow(const Offset(231, 216), const Offset(231, 300), red);
    arrow(const Offset(474, 226), const Offset(474, 406), red);
    arrow(const Offset(432, 406), const Offset(432, 288), blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SurveyMiniPlotPainter extends CustomPainter {
  const _SurveyMiniPlotPainter(
    this.title,
    this.verticalLabel,
    this.horizontalLabel,
  );

  final String title;
  final String verticalLabel;
  final String horizontalLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final grid = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 0.7;
    final actual = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final plan = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final chart = Rect.fromLTWH(26, 20, size.width - 34, size.height - 45);
    _paintSmallText(canvas, title, Offset(size.width / 2, 5), center: true);
    canvas.drawRect(chart, border);

    for (var i = 1; i < 8; i++) {
      final x = chart.left + chart.width * i / 8;
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), grid);
    }
    for (var i = 1; i < 7; i++) {
      final y = chart.top + chart.height * i / 7;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    final redPath = Path()
      ..moveTo(chart.left + 8, chart.top + 6)
      ..lineTo(chart.left + 10, chart.top + 34)
      ..lineTo(chart.left + 20, chart.top + 62)
      ..lineTo(chart.left + 52, chart.bottom - 8);
    final bluePath = Path()
      ..moveTo(chart.left + 5, chart.top + 8)
      ..cubicTo(
        chart.left + 24,
        chart.top + 34,
        chart.left + 50,
        chart.top + 46,
        chart.right - 8,
        chart.top + 48,
      );
    canvas.drawPath(redPath, actual);
    canvas.drawPath(bluePath, plan);

    _paintSmallText(
      canvas,
      verticalLabel,
      Offset(2, chart.top + chart.height / 2),
      rotate: -math.pi / 2,
    );
    _paintSmallText(
      canvas,
      horizontalLabel,
      Offset(size.width / 2, size.height - 14),
      center: true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RheologyCurvePainter extends CustomPainter {
  const _RheologyCurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final grid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.7;
    final curve = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final reference = Paint()
      ..color = Colors.pink.shade200
      ..strokeWidth = 1.2;

    final chart = Rect.fromLTWH(34, 18, size.width - 48, size.height - 46);
    _paintSmallText(
      canvas,
      'Shear Stress vs. Shear Rate',
      Offset(size.width / 2, 4),
      center: true,
    );
    canvas.drawRect(chart, border);

    for (var i = 1; i < 9; i++) {
      final x = chart.left + chart.width * i / 9;
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), grid);
    }
    for (var i = 1; i < 7; i++) {
      final y = chart.top + chart.height * i / 7;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    canvas.drawLine(
      Offset(chart.left, chart.top + chart.height * 0.42),
      Offset(chart.right, chart.top + chart.height * 0.42),
      reference,
    );

    final path = Path()
      ..moveTo(chart.left + 12, chart.bottom - 18)
      ..lineTo(chart.left + chart.width * 0.35, chart.bottom - 58)
      ..lineTo(chart.left + chart.width * 0.63, chart.top + 70)
      ..lineTo(chart.right - 12, chart.top + 28);
    canvas.drawPath(path, curve);

    final dotPaint = Paint()..color = Colors.blue.shade700;
    for (final point in [
      Offset(chart.left + chart.width * 0.35, chart.bottom - 58),
      Offset(chart.left + chart.width * 0.63, chart.top + 70),
      Offset(chart.right - 12, chart.top + 28),
    ]) {
      canvas.drawCircle(point, 3, dotPaint);
    }

    _paintSmallText(
      canvas,
      'Shear Stress (lbf/100ft2)',
      Offset(4, chart.top + chart.height / 2),
      rotate: -math.pi / 2,
    );
    _paintSmallText(
      canvas,
      'Shear Rate (1/s)',
      Offset(size.width / 2, size.height - 18),
      center: true,
    );
    _paintSmallText(
      canvas,
      'Sample 1',
      Offset(chart.left + chart.width * 0.48, size.height - 32),
      center: true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DoglegPlotPainter extends CustomPainter {
  const _DoglegPlotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final grid = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 0.7;
    final actual = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final plan = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final chart = Rect.fromLTWH(34, 18, size.width - 48, size.height - 42);
    _paintSmallText(canvas, 'Dogleg', Offset(size.width / 2, 3), center: true);
    canvas.drawRect(chart, border);

    for (var i = 1; i < 10; i++) {
      final x = chart.left + chart.width * i / 10;
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), grid);
    }
    for (var i = 1; i < 8; i++) {
      final y = chart.top + chart.height * i / 8;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }

    final redPath = Path()
      ..moveTo(chart.left + 8, chart.top + 9)
      ..lineTo(chart.left + 9, chart.top + 48)
      ..lineTo(chart.left + 58, chart.top + 48)
      ..lineTo(chart.left + 58, chart.top + 72)
      ..lineTo(chart.right - 70, chart.top + 72)
      ..lineTo(chart.right - 70, chart.bottom - 28)
      ..lineTo(chart.left + 30, chart.bottom - 28)
      ..lineTo(chart.left + 30, chart.bottom - 10);
    final bluePath = Path()
      ..moveTo(chart.left + 12, chart.top + 26)
      ..lineTo(chart.right - 10, chart.top + 20)
      ..moveTo(chart.left + 22, chart.top + 50)
      ..lineTo(chart.right - 50, chart.top + 46)
      ..moveTo(chart.left + 16, chart.top + 66)
      ..lineTo(chart.right - 115, chart.top + 80);
    canvas.drawPath(bluePath, plan);
    canvas.drawPath(redPath, actual);

    _paintSmallText(
      canvas,
      'MD (ft)',
      Offset(3, chart.top + chart.height / 2),
      rotate: -math.pi / 2,
    );
    _paintSmallText(
      canvas,
      'Dogleg Severity ( /100ft)',
      Offset(size.width / 2, size.height - 13),
      center: true,
    );

    final legendY = size.height - 7;
    canvas.drawLine(Offset(52, legendY), Offset(68, legendY), actual);
    _paintSmallText(canvas, 'TEST WELL 1', Offset(72, legendY - 5));
    canvas.drawLine(Offset(128, legendY), Offset(144, legendY), plan);
    _paintSmallText(canvas, 'Plan', Offset(148, legendY - 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PitSnapshotSchematicPainter extends CustomPainter {
  const _PitSnapshotSchematicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 0.8;
    final casingPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;
    final pipePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1.4;
    final orange = Paint()
      ..color = const Color(0xFFE97B31)
      ..strokeWidth = 4;
    final red = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.2;

    final leftX = 78.0;
    final rightX = 154.0;
    final top = 30.0;
    final bottom = size.height - 18;

    _paintSmallText(canvas, 'MD/TVD (ft)', const Offset(8, 20));
    _paintSmallText(canvas, 'Shoe (ft)', const Offset(82, 20));

    for (final depth in const [0, 5000, 10000, 15000, 22482]) {
      final y = top + (bottom - top) * depth / 22482;
      canvas.drawCircle(Offset(35, y), 2, Paint()..color = Colors.red.shade300);
      _paintSmallText(
        canvas,
        depth == 0 ? '0.0' : depth.toString(),
        Offset(8, y - 5),
      );
      if (depth > 0 && depth < 22482) {
        canvas.drawLine(Offset(52, y), Offset(leftX + 12, y), axisPaint);
      }
    }

    canvas.drawLine(Offset(leftX, top), Offset(leftX, bottom), casingPaint);
    canvas.drawLine(
      Offset(leftX + 12, top),
      Offset(leftX + 12, bottom),
      casingPaint,
    );
    canvas.drawLine(Offset(rightX, top), Offset(rightX, bottom), casingPaint);
    canvas.drawLine(
      Offset(rightX + 12, top),
      Offset(rightX + 12, bottom),
      casingPaint,
    );
    canvas.drawLine(
      Offset(leftX - 20, top + 8),
      Offset(leftX, top + 8),
      axisPaint,
    );
    canvas.drawLine(
      Offset(rightX - 20, top + 8),
      Offset(rightX, top + 8),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftX + 6, top),
      Offset(leftX + 6, bottom - 6),
      pipePaint,
    );
    canvas.drawLine(
      Offset(rightX + 6, top),
      Offset(rightX + 6, bottom - 6),
      pipePaint,
    );
    canvas.drawLine(
      Offset(leftX, top + 20),
      Offset(leftX + 12, top + 20),
      orange,
    );
    canvas.drawLine(
      Offset(rightX, top + 20),
      Offset(rightX + 12, top + 20),
      orange,
    );

    final wiggle = Path()..moveTo(leftX + 6, bottom - 112);
    for (var i = 0; i < 11; i++) {
      final y = bottom - 112 + i * 9;
      wiggle.lineTo(leftX + 6 + (i.isEven ? 3 : -3), y);
    }
    canvas.drawPath(wiggle, pipePaint);

    canvas.drawLine(Offset(48, top + 4), Offset(104, top + 4), red);
    canvas.drawLine(Offset(48, bottom), Offset(104, bottom), red);
    _paintSmallText(canvas, '0.0', const Offset(47, 8));
    _paintSmallText(canvas, '1965.0', Offset(83, top + 26));
    _paintSmallText(canvas, '10870.0', Offset(87, top + 122));
    _paintSmallText(canvas, '22482.0', Offset(8, bottom - 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TotalCostMiniChartPainter extends CustomPainter {
  const _TotalCostMiniChartPainter({
    required this.points,
    required this.lineColor,
  });

  final List<Offset> points;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(18, 4, size.width - 22, size.height - 18);
    final gridPaint = Paint()
      ..color = const Color(0xFFD8E1EC)
      ..strokeWidth = 0.7;
    final axisPaint = Paint()
      ..color = const Color(0xFF8292A6)
      ..strokeWidth = 0.9;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (var index = 0; index <= 5; index++) {
      final x = chart.left + chart.width * index / 5;
      final y = chart.top + chart.height * index / 5;
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), gridPaint);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    canvas.drawLine(
      Offset(chart.left, chart.top),
      Offset(chart.left, chart.bottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chart.left, chart.bottom),
      Offset(chart.right, chart.bottom),
      axisPaint,
    );

    if (points.isNotEmpty) {
      final path = Path();
      for (var index = 0; index < points.length; index++) {
        final point = points[index];
        final plotted = Offset(
          chart.left + point.dx * chart.width,
          chart.top + point.dy * chart.height,
        );
        if (index == 0) {
          path.moveTo(plotted.dx, plotted.dy);
        } else {
          path.lineTo(plotted.dx, plotted.dy);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    _paintSmallText(canvas, '0', Offset(chart.left - 3, chart.bottom + 2));
    _paintSmallText(canvas, '30', Offset(chart.right - 7, chart.bottom + 2));
  }

  @override
  bool shouldRepaint(covariant _TotalCostMiniChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}

class _ConcentrationTrendPainter extends CustomPainter {
  const _ConcentrationTrendPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(5, 4, size.width - 10, size.height - 8);
    final gridPaint = Paint()
      ..color = const Color(0xFFD8E1EC)
      ..strokeWidth = 0.6;
    final linePaint = Paint()
      ..color = const Color(0xFF5D9FE5)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (var index = 0; index <= 8; index++) {
      final x = chart.left + chart.width * index / 8;
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), gridPaint);
    }
    for (var index = 0; index <= 3; index++) {
      final y = chart.top + chart.height * index / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    if (points.isEmpty) return;
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final plotted = Offset(
        chart.left + point.dx * chart.width,
        chart.top + point.dy * chart.height,
      );
      if (index == 0) {
        path.moveTo(plotted.dx, plotted.dy);
      } else {
        path.lineTo(plotted.dx, plotted.dy);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ConcentrationTrendPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

void _paintSmallText(
  Canvas canvas,
  String text,
  Offset offset, {
  bool center = false,
  double rotate = 0,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 7.5,
        fontWeight: FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  canvas.save();
  canvas.translate(offset.dx, offset.dy);
  if (rotate != 0) {
    canvas.rotate(rotate);
  }
  final dx = center ? -painter.width / 2 : 0.0;
  painter.paint(canvas, Offset(dx, 0));
  canvas.restore();
}

class _PrintTopicsDialog extends StatefulWidget {
  const _PrintTopicsDialog();

  @override
  State<_PrintTopicsDialog> createState() => _PrintTopicsDialogState();
}

class _PrintTopicsDialogState extends State<_PrintTopicsDialog> {
  var _selection = _PrintTopicSelection.selectedTopic;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        width: 450,
        height: 270,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppTheme.tableHeaderBlue,
                border: Border(
                  bottom: BorderSide(color: AppTheme.tableBorderBlue),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Print Topics',
                    style: AppTheme.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(Icons.close, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You can print the selected topic or all the topics in the selected heading. What would you like to do?',
                      style: AppTheme.bodyLarge.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    _radioRow(
                      _PrintTopicSelection.selectedTopic,
                      'Print the selected topic',
                    ),
                    const SizedBox(height: 8),
                    _radioRow(
                      _PrintTopicSelection.headingAndSubtopics,
                      'Print the selected heading and all subtopics',
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 112,
                          height: 36,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(_selection),
                            child: Text(
                              'OK',
                              style: AppTheme.bodyLarge.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 112,
                          height: 36,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: AppTheme.bodyLarge.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioRow(_PrintTopicSelection value, String label) {
    return InkWell(
      onTap: () => setState(() => _selection = value),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Radio<_PrintTopicSelection>(
              value: value,
              groupValue: _selection,
              onChanged: (next) {
                if (next != null) setState(() => _selection = next);
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTheme.bodyLarge.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

enum _PrintTopicSelection { selectedTopic, headingAndSubtopics }

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

class _ManualNode {
  const _ManualNode(this.title, {this.children = const [], String? topic})
    : topic = topic ?? title;

  final String title;
  final String topic;
  final List<_ManualNode> children;
}
