import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_models.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:path/path.dart' as p;

class RemarksView extends StatefulWidget {
  const RemarksView({super.key});

  @override
  State<RemarksView> createState() => _RemarksViewState();
}

class _RemarksViewState extends State<RemarksView> {
  static const int _maxAttachmentBytes = 5 * 1024 * 1024;
  static const Color _editorFill = Color(0xffFFFDE7);

  final DashboardController dashboard = Get.find<DashboardController>();
  final ReportContextController reports = reportContext;

  final TextEditingController recommendedCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();
  final TextEditingController recapCtrl = TextEditingController();
  final TextEditingController internalCtrl = TextEditingController();

  Worker? _reportWorker;
  bool _isHydrating = false;
  bool _isDirty = false;
  bool _isSaving = false;
  String _loadedReportId = '';

  File? _pickedFile;
  ReportAttachment? _storedAttachment;
  bool _attachmentDirty = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      recommendedCtrl,
      remarksCtrl,
      recapCtrl,
      internalCtrl,
    ]) {
      controller.addListener(_handleTextChanged);
    }

    _reportWorker = ever<String>(
      reports.selectedReportId,
      (_) => _loadSelectedReport(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSelectedReport());
  }

  void _handleTextChanged() {
    if (_isHydrating || _isDirty) return;
    if (mounted) setState(() => _isDirty = true);
  }

  void _loadSelectedReport() {
    final report = reports.selectedReport;
    final reportId = report?.id ?? '';
    if (_loadedReportId == reportId && !_isDirty) return;

    _isHydrating = true;
    recommendedCtrl.text = report?.recommendedTreatment ?? '';
    remarksCtrl.text = report?.remarks ?? '';
    recapCtrl.text = report?.recapRemarks ?? '';
    internalCtrl.text = report?.internalNotes ?? '';
    _isHydrating = false;

    if (!mounted) return;
    setState(() {
      _loadedReportId = reportId;
      _pickedFile = null;
      _storedAttachment = report?.remarksAttachment;
      _attachmentDirty = false;
      _isDirty = false;
    });
  }

  Future<void> pickFile() async {
    if (dashboard.isLocked.value) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;

    final file = File(path);
    final size = await file.length();
    if (size > _maxAttachmentBytes) {
      _showMessage('Attachment must be 5 MB or smaller.', isError: true);
      return;
    }

    setState(() {
      _pickedFile = file;
      _storedAttachment = null;
      _attachmentDirty = true;
      _isDirty = true;
    });
  }

  void deleteFile() {
    if (dashboard.isLocked.value) return;
    setState(() {
      _pickedFile = null;
      _storedAttachment = null;
      _attachmentDirty = true;
      _isDirty = true;
    });
  }

  Future<void> _saveRemarks() async {
    if (_isSaving) return;
    if (!reports.hasSelectedReport) {
      _showMessage('Select a report first.', isError: true);
      return;
    }
    if (dashboard.isLocked.value) {
      _showMessage('Unlock the document before saving.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'recommendedTreatment': recommendedCtrl.text.trim(),
        'remarks': remarksCtrl.text.trim(),
        'recapRemarks': recapCtrl.text.trim(),
        'internalNotes': internalCtrl.text.trim(),
      };

      if (_attachmentDirty) {
        payload['remarksAttachment'] = await _buildAttachmentPayload();
      }

      await reports.updateSelectedReport(payload);
      _loadSelectedReport();
      _showMessage('Remarks saved.');
    } catch (e) {
      _showMessage(_friendlyError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<Map<String, dynamic>?> _buildAttachmentPayload() async {
    final file = _pickedFile;
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.length > _maxAttachmentBytes) {
      throw Exception('Attachment must be 5 MB or smaller.');
    }

    final fileName = p.basename(file.path);
    return {
      'fileName': fileName,
      'mimeType': _mimeTypeFor(fileName),
      'size': bytes.length,
      'data': base64Encode(bytes),
    };
  }

  Future<void> _reloadReport() async {
    try {
      await reports.reloadData();
      _loadSelectedReport();
      _showMessage('Remarks reloaded.');
    } catch (e) {
      _showMessage(_friendlyError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final report = reports.selectedReport;
      final isLocked = dashboard.isLocked.value || report == null;
      final isLoading = reports.isLoading.value;

      return Container(
        color: AppTheme.backgroundColor,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(report, isLocked, isLoading),
            const SizedBox(height: 10),
            if (report == null)
              Expanded(child: _buildEmptyState(isLoading))
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 1050) {
                      return _buildNarrowLayout(isLocked);
                    }
                    return _buildWideLayout(isLocked);
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildToolbar(AppReport? report, bool isLocked, bool isLoading) {
    final reportLabel = report == null
        ? 'No report selected'
        : report.userReportNo.isNotEmpty
            ? 'Report ${report.userReportNo}'
            : 'Report ${report.reportNo}';

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.notes, size: 18, color: AppTheme.tableHeadColor),
          const SizedBox(width: 8),
          Text(
            'Remarks',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          _statusChip(reportLabel, AppTheme.primaryColor),
          const SizedBox(width: 8),
          if (_isDirty)
            _statusChip('Unsaved changes', AppTheme.warningColor)
          else
            _statusChip('Saved', AppTheme.successColor),
          const Spacer(),
          TextButton.icon(
            onPressed: isLoading ? null : _reloadReport,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reload'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: isLocked || !_isDirty || _isSaving ? null : _saveRemarks,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 16),
            label: Text(_isSaving ? 'Saving' : 'Save'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: AppTheme.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildWideLayout(bool isLocked) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _buildMemoPanel(
            title: 'Recommended Tour Treatments',
            controller: recommendedCtrl,
            icon: Icons.assignment_turned_in_outlined,
            isLocked: isLocked,
            hintText: 'Recommended tour treatments',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                child: _buildMemoPanel(
                  title: 'Remarks',
                  controller: remarksCtrl,
                  icon: Icons.forum_outlined,
                  isLocked: isLocked,
                  hintText: 'Operational comments',
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _buildMemoPanel(
                  title: 'Recap Remarks',
                  controller: recapCtrl,
                  icon: Icons.summarize_outlined,
                  isLocked: isLocked,
                  hintText: 'Recap remarks',
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _buildMemoPanel(
                  title: 'Internal Notes',
                  controller: internalCtrl,
                  icon: Icons.lock_outline,
                  isLocked: isLocked,
                  hintText: 'Internal notes',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 270, child: _buildAttachmentPanel(isLocked)),
      ],
    );
  }

  Widget _buildNarrowLayout(bool isLocked) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 380,
            child: _buildMemoPanel(
              title: 'Recommended Tour Treatments',
              controller: recommendedCtrl,
              icon: Icons.assignment_turned_in_outlined,
              isLocked: isLocked,
              hintText: 'Recommended tour treatments',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: _buildMemoPanel(
              title: 'Remarks',
              controller: remarksCtrl,
              icon: Icons.forum_outlined,
              isLocked: isLocked,
              hintText: 'Operational comments',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: _buildMemoPanel(
              title: 'Recap Remarks',
              controller: recapCtrl,
              icon: Icons.summarize_outlined,
              isLocked: isLocked,
              hintText: 'Recap remarks',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: _buildMemoPanel(
              title: 'Internal Notes',
              controller: internalCtrl,
              icon: Icons.lock_outline,
              isLocked: isLocked,
              hintText: 'Internal notes',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 340, child: _buildAttachmentPanel(isLocked)),
        ],
      ),
    );
  }

  Widget _buildMemoPanel({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required bool isLocked,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.tableHeadColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => Text(
                    '${value.text.length}',
                    style: AppTheme.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: isLocked,
              maxLines: null,
              minLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimary,
                height: 1.35,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTheme.bodySmall.copyWith(
                  color: Colors.grey.shade500,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: isLocked ? Colors.grey.shade100 : _editorFill,
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPanel(bool isLocked) {
    final hasAttachment = _pickedFile != null || _storedAttachment != null;
    final fileName = _attachmentName();
    final fileSize = _attachmentSize();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.tableHeadColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Attachment',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _buildPreviewArea(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasAttachment
                            ? Icons.insert_drive_file_outlined
                            : Icons.info_outline,
                        size: 16,
                        color: hasAttachment
                            ? AppTheme.tableHeadColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasAttachment ? fileName : 'No attachment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (hasAttachment)
                              Text(
                                _formatBytes(fileSize),
                                style: AppTheme.caption,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLocked ? null : pickFile,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('Upload'),
                        style: AppTheme.primaryButtonStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLocked || !hasAttachment ? null : deleteFile,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    final pickedFile = _pickedFile;
    if (pickedFile != null) {
      final fileName = p.basename(pickedFile.path);
      if (_isImage(fileName, _mimeTypeFor(fileName))) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(pickedFile, fit: BoxFit.contain),
        );
      }
      return _fileIconPreview(fileName, _mimeTypeFor(fileName));
    }

    final stored = _storedAttachment;
    if (stored != null) {
      final bytes = _decodeAttachment(stored);
      if (bytes != null && _isImage(stored.fileName, stored.mimeType)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(bytes, fit: BoxFit.contain),
        );
      }
      return _fileIconPreview(stored.fileName, stored.mimeType);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          'No Preview',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _fileIconPreview(String fileName, String mimeType) {
    final icon = _fileIcon(fileName, mimeType);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: AppTheme.tableHeadColor),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: isLoading
            ? CircularProgressIndicator(color: AppTheme.tableHeadColor)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 44,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create and select a report first.',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _attachmentName() {
    final picked = _pickedFile;
    if (picked != null) return p.basename(picked.path);
    return _storedAttachment?.fileName ?? '';
  }

  int _attachmentSize() {
    final picked = _pickedFile;
    if (picked != null) return picked.lengthSync();
    return _storedAttachment?.size ?? 0;
  }

  Uint8List? _decodeAttachment(ReportAttachment attachment) {
    try {
      if (attachment.data.isEmpty) return null;
      return base64Decode(attachment.data);
    } catch (_) {
      return null;
    }
  }

  bool _isImage(String fileName, String mimeType) {
    final lowerName = fileName.toLowerCase();
    final lowerMime = mimeType.toLowerCase();
    return lowerMime.startsWith('image/') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png');
  }

  IconData _fileIcon(String fileName, String mimeType) {
    final lowerName = fileName.toLowerCase();
    final lowerMime = mimeType.toLowerCase();
    if (lowerMime.contains('pdf') || lowerName.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (lowerName.endsWith('.xls') || lowerName.endsWith('.xlsx')) {
      return Icons.table_chart_outlined;
    }
    if (lowerName.endsWith('.doc') || lowerName.endsWith('.docx')) {
      return Icons.description_outlined;
    }
    if (lowerName.endsWith('.txt')) return Icons.text_snippet_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    return 'application/octet-stream';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  @override
  void dispose() {
    _reportWorker?.dispose();
    recommendedCtrl.dispose();
    remarksCtrl.dispose();
    recapCtrl.dispose();
    internalCtrl.dispose();
    super.dispose();
  }
}
