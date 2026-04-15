import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/view/right_section/interval/controller/interval_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class IntervalLeftPanel extends StatelessWidget {
  const IntervalLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<IntervalController>();

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────
          Container(
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(Icons.layers, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  "Intervals",
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${c.intervals.length} items",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ],
            ),
          ),

          // ── LIST ────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              final nodes = c.flatList;
              if (nodes.isEmpty) {
                return Center(
                  child: Text("No intervals",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(6),
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

          // ── ICON BUTTON BAR ─────────────────────────────────────
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _iconBtn(
                  icon: Icons.vertical_align_top,
                  tooltip: "Insert Before",
                  onTap: c.isSaving.value ? null : c.insertBefore,
                ),
                _iconBtn(
                  icon: Icons.vertical_align_bottom,
                  tooltip: "Insert After",
                  onTap: c.isSaving.value ? null : c.insertAfter,
                ),
                _iconBtn(
                  icon: Icons.delete_outline,
                  tooltip: "Remove Selected",
                  color: AppTheme.errorColor,
                  onTap: (c.isSaving.value || c.selected.value == null)
                      ? null
                      : c.removeSelected,
                ),
                _iconBtn(
                  icon: Icons.folder_outlined,
                  tooltip: "Group Intervals",
                  onTap: c.isSaving.value
                      ? null
                      : () => _showGroupDialog(context, c),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  // ── compact icon button ──────────────────────────────────────────
  Widget _iconBtn({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color? color,
  }) {
    final col = color ?? AppTheme.primaryColor;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null ? Colors.grey.shade400 : col,
          ),
        ),
      ),
    );
  }

  // ── Group Interval Dialog ────────────────────────────────────────
  void _showGroupDialog(BuildContext context, IntervalController c) {
    final nameCtrl   = TextEditingController();
    final selected   = <String>{}.obs;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Group Intervals", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group name field
              const Text("Group Name", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              SizedBox(
                height: 34,
                child: TextField(
                  controller: nameCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    hintText: "Enter group name",
                    hintStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text("Select interval(s) to Group",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              // Interval checkboxes
              SizedBox(
                height: 200,
                child: Obx(() => ListView(
                  children: c.intervals.map((iv) {
                    return Obx(() => CheckboxListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(iv.name, style: const TextStyle(fontSize: 11)),
                      value: selected.contains(iv.id),
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) {
                        if (v == true) {
                          selected.add(iv.id);
                        } else {
                          selected.remove(iv.id);
                        }
                      },
                    ));
                  }).toList(),
                )),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || selected.isEmpty) return;
              Navigator.pop(context);
              await c.createGroup(nameCtrl.text.trim(), selected.toList());
            },
            child: const Text("Save", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  INTERVAL TILE — double-tap to rename
// ════════════════════════════════════════════════════════════════════
class _IntervalTile extends StatefulWidget {
  final IntervalItem       iv;
  final IntervalController c;
  const _IntervalTile({required this.iv, required this.c});

  @override
  State<_IntervalTile> createState() => _IntervalTileState();
}

class _IntervalTileState extends State<_IntervalTile> {
  bool _editing = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.iv.name);
  }

  @override
  void didUpdateWidget(_IntervalTile old) {
    super.didUpdateWidget(old);
    if (old.iv.id != widget.iv.id) {
      _nameCtrl.text = widget.iv.name;
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _submit() {
    final newName = _nameCtrl.text.trim();
    if (newName.isNotEmpty && newName != widget.iv.name) {
      widget.c.renameInterval(widget.iv, newName);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final c        = widget.c;
    final iv       = widget.iv;
    final isInGroup = iv.groupId != null;

    return Obx(() {
      final isSelected = c.selected.value?.id == iv.id;
      return GestureDetector(
        onTap: () => c.selectInterval(iv),
        onDoubleTap: () => setState(() {
          _editing  = true;
          _nameCtrl.text = iv.name;
        }),
        child: Container(
          margin: EdgeInsets.only(
            left: isInGroup ? 14 : 0,
            bottom: 2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Index badge
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${c.intervals.indexOf(iv) + 1}',
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Name / edit field
              Expanded(
                child: _editing
                    ? TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _submit(),
                        onEditingComplete: _submit,
                      )
                    : Text(
                        iv.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              if (isSelected && !_editing)
                Icon(Icons.check_circle, size: 13, color: AppTheme.primaryColor),
            ],
          ),
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════════
//  GROUP TILE — collapse / expand + delete
// ════════════════════════════════════════════════════════════════════
class _GroupTile extends StatelessWidget {
  final IntervalGroup      group;
  final IntervalController c;
  const _GroupTile({required this.group, required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final collapsed = group.collapsed;
      return Column(
        children: [
          GestureDetector(
            onTap: () => c.toggleGroupCollapse(group),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    collapsed ? Icons.add_box_outlined : Icons.indeterminate_check_box_outlined,
                    size: 15,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Delete group button
                  Tooltip(
                    message: "Remove Group",
                    child: InkWell(
                      onTap: () => _confirmDeleteGroup(context),
                      child: Icon(Icons.close, size: 13, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  void _confirmDeleteGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Group", style: TextStyle(fontSize: 13)),
        content: Text(
          "Remove group \"${group.name}\"? The intervals inside will remain.",
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              Navigator.pop(context);
              c.deleteGroup(group.id);
            },
            child: const Text("Remove", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}