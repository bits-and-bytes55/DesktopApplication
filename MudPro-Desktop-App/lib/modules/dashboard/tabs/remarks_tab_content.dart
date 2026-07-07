import 'dart:async';
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
  static const Color _pageBackground = Color(0xFFF4F6FA);
  static const Color _sectionHeader = Color(0xFF6C9BCF);
  static const Color _lockedEditable = Color(0xFFFFF7CC);

  final DashboardController dashboard = Get.find<DashboardController>();
  final ReportContextController reports = reportContext;

  final TextEditingController recommendedCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();
  final TextEditingController recapCtrl = TextEditingController();
  final TextEditingController internalCtrl = TextEditingController();

  Worker? _reportWorker;
  Timer? _autoSaveTimer;
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
    if (_isHydrating) return;
    if (!_isDirty && mounted) setState(() => _isDirty = true);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (_isHydrating ||
        dashboard.isLocked.value ||
        !reports.hasSelectedReport) {
      return;
    }
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_isSaving) {
        _scheduleAutoSave();
      } else {
        _saveRemarks(silent: true);
      }
    });
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
    _scheduleAutoSave();
  }

  void deleteFile() {
    if (dashboard.isLocked.value) return;
    setState(() {
      _pickedFile = null;
      _storedAttachment = null;
      _attachmentDirty = true;
      _isDirty = true;
    });
    _scheduleAutoSave();
  }

  Future<void> _saveRemarks({bool silent = false}) async {
    _autoSaveTimer?.cancel();
    if (!mounted) return;
    if (_isSaving) return;
    if (!reports.hasSelectedReport) {
      if (!silent) _showMessage('Select a report first.', isError: true);
      return;
    }
    if (dashboard.isLocked.value) {
      if (!silent) {
        _showMessage('Unlock the document before saving.', isError: true);
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final recommended = recommendedCtrl.text.trim();
      final remarks = remarksCtrl.text.trim();
      final recap = recapCtrl.text.trim();
      final internal = internalCtrl.text.trim();
      final payload = <String, dynamic>{
        'recommendedTreatment': recommended,
        'remarks': remarks,
        'recapRemarks': recap,
        'internalNotes': internal,
      };

      if (_attachmentDirty) {
        payload['remarksAttachment'] = await _buildAttachmentPayload();
      }

      await reports.updateSelectedReport(payload);
      final changedDuringSave =
          recommendedCtrl.text.trim() != recommended ||
          remarksCtrl.text.trim() != remarks ||
          recapCtrl.text.trim() != recap ||
          internalCtrl.text.trim() != internal;
      if (changedDuringSave) {
        if (mounted) setState(() => _isDirty = true);
        _scheduleAutoSave();
      } else {
        _loadSelectedReport();
      }
      if (!silent) _showMessage('Remarks saved.');
    } catch (e) {
      if (!silent) _showMessage(_friendlyError(e), isError: true);
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

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 11,
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
      child: Obx(() {
        final report = reports.selectedReport;
        final isLocked = dashboard.isLocked.value || report == null;
        final isLoading = reports.isLoading.value;

        return Container(
          color: _pageBackground,
          padding: const EdgeInsets.all(6),
          child: report == null
              ? _buildEmptyState(isLoading)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 1050) {
                      return _buildNarrowLayout(isLocked);
                    }
                    return _buildWideLayout(isLocked);
                  },
                ),
        );
      }),
    );
  }

  Widget _buildWideLayout(bool isLocked) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                child: _buildMemoPanel(
                  title: 'Recommended Tour Treatments',
                  controller: recommendedCtrl,
                  icon: Icons.assignment_turned_in_outlined,
                  isLocked: isLocked,
                  hintText: 'Recommended tour treatments',
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildMemoPanel(
                  title: 'Recap Remarks',
                  controller: remarksCtrl,
                  icon: Icons.forum_outlined,
                  isLocked: isLocked,
                  hintText: 'Recap remarks',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                child: _buildMemoPanel(
                  title: 'Operational Comments',
                  controller: recapCtrl,
                  icon: Icons.summarize_outlined,
                  isLocked: isLocked,
                  hintText: 'Operational comments',
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildMemoPanel(
                        title: 'Internal Notes',
                        controller: internalCtrl,
                        icon: Icons.lock_outline,
                        isLocked: isLocked,
                        hintText: 'Internal notes',
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 250,
                      child: _buildAttachmentPanel(isLocked),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: _buildMemoPanel(
              title: 'Recap Remarks',
              controller: remarksCtrl,
              icon: Icons.forum_outlined,
              isLocked: isLocked,
              hintText: 'Recap remarks',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: _buildMemoPanel(
              title: 'Operational Comments',
              controller: recapCtrl,
              icon: Icons.summarize_outlined,
              isLocked: isLocked,
              hintText: 'Operational comments',
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(title, icon),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.tableBorderBlue),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
            ),
            child: TextField(
              controller: controller,
              readOnly: isLocked,
              maxLines: null,
              minLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: AppTheme.bodySmall.copyWith(
                fontFamily: 'Segoe UI',
                fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTheme.bodySmall.copyWith(
                  fontFamily: 'Segoe UI',
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: isLocked ? _lockedEditable : Colors.white,
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentPanel(bool isLocked) {
    final hasAttachment = _pickedFile != null || _storedAttachment != null;
    final fileName = _attachmentName();
    final fileSize = _attachmentSize();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('Attachment', Icons.attach_file),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.tableBorderBlue),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
            ),
            child: _buildPreviewArea(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: isLocked ? null : pickFile,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(38),
            side: BorderSide(color: AppTheme.tableBorderBlue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            foregroundColor: Colors.white,
            backgroundColor: AppTheme.primaryColor,
            disabledForegroundColor: Colors.white70,
            disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.55),
          ),
          child: const Text('Upload'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: isLocked || !hasAttachment ? null : deleteFile,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(38),
            side: BorderSide(color: AppTheme.tableBorderBlue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            foregroundColor: Colors.white,
            backgroundColor: AppTheme.primaryColor,
            disabledForegroundColor: Colors.white70,
            disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.55),
          ),
          child: const Text('Delete'),
        ),
        if (hasAttachment) ...[
          const SizedBox(height: 8),
          Text(
            hasAttachment ? fileName : '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.caption.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(_formatBytes(fileSize), style: AppTheme.caption),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: _sectionHeader,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
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
        color: Colors.white,
        border: Border.all(color: AppTheme.tableBorderBlue),
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
                color: Colors.black,
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
        border: Border.all(color: AppTheme.tableBorderBlue),
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
    _autoSaveTimer?.cancel();
    _reportWorker?.dispose();
    recommendedCtrl.dispose();
    remarksCtrl.dispose();
    recapCtrl.dispose();
    internalCtrl.dispose();
    super.dispose();
  }
}
