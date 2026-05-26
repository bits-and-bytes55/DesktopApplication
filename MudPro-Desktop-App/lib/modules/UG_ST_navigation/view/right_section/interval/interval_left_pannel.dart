import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/modules/well_context/pad_well_controller.dart';

const Color _ivlBorder = Color(0xFFC9CED6);
const Color _ivlHeader = Color(0xFFF3F3F3);
bool _intervalContextMenuOpen = false;
int _intervalChildMenuStartedAt = 0;

class IntervalLeftPanel extends StatelessWidget {
  const IntervalLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<IntervalController>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _ivlBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) => _showRootMenu(context, details, c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _ivlBorder),
                ),
                child: Column(
                  children: [
                    _rootHeader(),
                    Expanded(
                      child: Obx(() {
                        if (c.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        final nodes = c.flatList;
                        if (nodes.isEmpty) {
                          return const Center(
                            child: Text(
                              'No intervals',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          itemCount: nodes.length,
                          itemBuilder: (_, i) {
                            final node = nodes[i];
                            return node.isGroup
                                ? _GroupTile(group: node.group!, c: c)
                                : _IntervalTile(iv: node.interval!, c: c);
                          },
                        );
                      }),
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

  Widget _rootHeader() {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: _ivlHeader,
        border: Border(bottom: BorderSide(color: _ivlBorder)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 13,
            color: Color(0xFF5B6470),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Obx(
              () => Text(
                padWellContext.selectedWellName.isEmpty
                    ? 'Well'
                    : padWellContext.selectedWellName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F2F2F),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRootMenu(
    BuildContext context,
    TapDownDetails details,
    IntervalController c,
  ) async {
    final requestedAt = DateTime.now().millisecondsSinceEpoch;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!context.mounted ||
        _intervalContextMenuOpen ||
        _intervalChildMenuStartedAt >= requestedAt) {
      return;
    }
    _intervalContextMenuOpen = true;
    String? action;
    try {
      action = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        ),
        items: [
          _menuItem('add_after', 'Add Interval', enabled: !c.isSaving.value),
          _menuItem('group', 'Group Intervals', enabled: !c.isSaving.value),
          const PopupMenuDivider(),
          _menuItem('copy', 'Copy', enabled: false),
          _menuItem('paste', 'Paste', enabled: false),
          _menuItem('delete', 'Delete', enabled: false),
          _menuItem('top', 'To the Top', enabled: false),
          _menuItem('bottom', 'To the Bottom', enabled: false),
        ],
      );
    } finally {
      _intervalContextMenuOpen = false;
    }

    if (!context.mounted) return;
    switch (action) {
      case 'add_after':
        await c.insertAfter();
        break;
      case 'group':
        _showGroupDialog(context, c);
        break;
    }
  }

  void _showGroupDialog(BuildContext context, IntervalController c) {
    final nameCtrl = TextEditingController();
    final selected = <String>{}.obs;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Group Intervals',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Group Name',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 11),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select interval(s) to Group',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 180,
                child: Obx(
                  () => ListView(
                    children: c.intervals.map((iv) {
                      return Obx(
                        () => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            iv.name,
                            style: const TextStyle(fontSize: 10),
                          ),
                          value: selected.contains(iv.id),
                          onChanged: (checked) {
                            if (checked == true) {
                              selected.add(iv.id);
                            } else {
                              selected.remove(iv.id);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 11)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || selected.isEmpty) return;
              Navigator.pop(context);
              await c.createGroup(nameCtrl.text.trim(), selected.toList());
            },
            style: ElevatedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('Save', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _IntervalTile extends StatefulWidget {
  final IntervalItem iv;
  final IntervalController c;

  const _IntervalTile({required this.iv, required this.c});

  @override
  State<_IntervalTile> createState() => _IntervalTileState();
}

class _IntervalTileState extends State<_IntervalTile> {
  bool _editing = false;
  late final TextEditingController _nameCtrl;
  late final FocusNode _renameFocusNode;
  String _lastSavedName = '';
  bool _renameDirty = false;
  bool _renameSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.iv.name);
    _renameFocusNode = FocusNode();
    _renameFocusNode.addListener(_handleRenameFocusChange);
    _lastSavedName = widget.iv.name.trim();
  }

  @override
  void didUpdateWidget(covariant _IntervalTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iv.id != widget.iv.id || !_editing) {
      _nameCtrl.text = widget.iv.name;
      _lastSavedName = widget.iv.name.trim();
      _renameDirty = false;
    }
  }

  @override
  void dispose() {
    _renameFocusNode.removeListener(_handleRenameFocusChange);
    _renameFocusNode.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _handleRenameFocusChange() {
    if (!_renameFocusNode.hasFocus && _editing) {
      _submitRename();
    }
  }

  void _submitRename() {
    if (!_editing) return;
    final next = _nameCtrl.text.trim();
    if (_renameDirty) {
      unawaited(_saveRename(next));
    }
    if (mounted) {
      setState(() => _editing = false);
    }
  }

  void _markRenameDirty(String value) {
    _renameDirty = value.trim() != _lastSavedName;
  }

  Future<void> _saveRename(String value) async {
    final next = value.trim();
    if (next.isEmpty || next == _lastSavedName) return;

    if (_renameSaving) {
      return;
    }

    _renameSaving = true;
    try {
      final saved = await widget.c.renameInterval(widget.iv, next);
      if (saved) {
        _lastSavedName = next;
        _renameDirty = false;
      }
    } finally {
      _renameSaving = false;
    }
  }

  Future<void> _showMenu(TapDownDetails details) async {
    if (_intervalContextMenuOpen) return;
    _intervalChildMenuStartedAt = DateTime.now().millisecondsSinceEpoch;
    _intervalContextMenuOpen = true;
    widget.c.selectInterval(widget.iv);
    String? action;
    try {
      action = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        ),
        items: [
          _menuItem('before', 'Add Before', enabled: !widget.c.isSaving.value),
          _menuItem('after', 'Add After', enabled: !widget.c.isSaving.value),
          _menuItem('rename', 'Rename', enabled: !widget.c.isSaving.value),
          _menuItem(
            'delete',
            'Delete',
            enabled: !widget.c.isSaving.value,
            danger: true,
          ),
          _menuItem(
            'group',
            'Group Intervals',
            enabled: !widget.c.isSaving.value,
          ),
          const PopupMenuDivider(),
          _menuItem('copy', 'Copy', enabled: false),
          _menuItem('paste', 'Paste', enabled: false),
          _menuItem('top', 'To the Top', enabled: false),
          _menuItem('bottom', 'To the Bottom', enabled: false),
        ],
      );
    } finally {
      _intervalContextMenuOpen = false;
    }

    if (!mounted) return;
    switch (action) {
      case 'before':
        await widget.c.insertBefore();
        break;
      case 'after':
        await widget.c.insertAfter();
        break;
      case 'rename':
        _startRename(widget.iv.name);
        break;
      case 'delete':
        await widget.c.removeSelected();
        break;
      case 'group':
        const panel = IntervalLeftPanel();
        // ignore: use_build_context_synchronously
        panel._showGroupDialog(context, widget.c);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final iv = widget.iv;
    final isInGroup = iv.groupId != null;

    return Obx(() {
      final isSelected = c.selected.value?.id == iv.id;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => c.selectInterval(iv),
        onDoubleTap: () => _startRename(iv.name),
        onSecondaryTapDown: _showMenu,
        child: Container(
          height: 24,
          margin: EdgeInsets.only(left: isInGroup ? 18 : 0),
          color: isSelected ? const Color(0xFFD9E7F8) : Colors.transparent,
          child: Row(
            children: [
              const SizedBox(width: 8),
              if (isInGroup)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.subdirectory_arrow_right,
                    size: 11,
                    color: Color(0xFF6E6E6E),
                  ),
                ),
              Expanded(
                child: _editing
                    ? TextField(
                        controller: _nameCtrl,
                        focusNode: _renameFocusNode,
                        autofocus: true,
                        style: const TextStyle(fontSize: 10),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: _markRenameDirty,
                        onSubmitted: (_) => _submitRename(),
                        onEditingComplete: _submitRename,
                      )
                    : Text(
                        iv.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? const Color(0xFF1D4F91)
                              : const Color(0xFF2F2F2F),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _startRename(String value) {
    setState(() {
      _editing = true;
      _nameCtrl.text = value;
      _lastSavedName = value.trim();
      _renameDirty = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _renameFocusNode.requestFocus();
      }
    });
  }
}

class _GroupTile extends StatelessWidget {
  final IntervalGroup group;
  final IntervalController c;

  const _GroupTile({required this.group, required this.c});

  Future<void> _showMenu(BuildContext context, TapDownDetails details) async {
    if (_intervalContextMenuOpen) return;
    _intervalChildMenuStartedAt = DateTime.now().millisecondsSinceEpoch;
    _intervalContextMenuOpen = true;
    String? action;
    try {
      action = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        ),
        items: [
          _menuItem(
            'toggle',
            group.collapsed ? 'Expand' : 'Collapse',
            enabled: !c.isSaving.value,
          ),
          _menuItem('group', 'Group Intervals', enabled: !c.isSaving.value),
          _menuItem(
            'delete',
            'Delete Group',
            enabled: !c.isSaving.value,
            danger: true,
          ),
          const PopupMenuDivider(),
          _menuItem('copy', 'Copy', enabled: false),
          _menuItem('paste', 'Paste', enabled: false),
          _menuItem('top', 'To the Top', enabled: false),
          _menuItem('bottom', 'To the Bottom', enabled: false),
        ],
      );
    } finally {
      _intervalContextMenuOpen = false;
    }

    if (!context.mounted) return;
    switch (action) {
      case 'toggle':
        await c.toggleGroupCollapse(group);
        break;
      case 'delete':
        await c.deleteGroup(group.id);
        break;
      case 'group':
        const panel = IntervalLeftPanel();
        // ignore: use_build_context_synchronously
        panel._showGroupDialog(context, c);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => c.toggleGroupCollapse(group),
      onSecondaryTapDown: (details) => _showMenu(context, details),
      child: Container(
        height: 24,
        color: const Color(0xFFF6F8FB),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              group.collapsed
                  ? Icons.add_box_outlined
                  : Icons.indeterminate_check_box_outlined,
              size: 12,
              color: const Color(0xFF4A5F7A),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F2F2F),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

PopupMenuItem<String> _menuItem(
  String value,
  String label, {
  required bool enabled,
  bool danger = false,
}) {
  final color = !enabled
      ? const Color(0xFF9EA4AD)
      : danger
      ? const Color(0xFFC62828)
      : const Color(0xFF2F2F2F);
  return PopupMenuItem<String>(
    value: value,
    enabled: enabled,
    height: 28,
    child: Text(label, style: TextStyle(fontSize: 11, color: color)),
  );
}
