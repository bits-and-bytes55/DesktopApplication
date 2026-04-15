import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';

class RemarksView extends StatefulWidget {
  const RemarksView({super.key});

  @override
  State<RemarksView> createState() => _RemarksViewState();
}

class _RemarksViewState extends State<RemarksView> {
  final DashboardController controller = Get.find<DashboardController>();
  final TextEditingController recommendedCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();
  final TextEditingController recapCtrl = TextEditingController();
  final TextEditingController internalCtrl = TextEditingController();

  File? selectedFile;

  // Text formatting states
  bool isBoldRemarks = false;
  bool isItalicRemarks = false;
  bool isBoldRecap = false;
  bool isItalicRecap = false;
  bool isBoldInternal = false;
  bool isItalicInternal = false;
  bool isBoldRecommended = false;
  bool isItalicRecommended = false;

  // ---------------- FILE PICK ----------------
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  void deleteFile() {
    setState(() {
      selectedFile = null;
    });
  }

  // ---------------- TEXT FORMATTING FUNCTIONS ----------------
  void _toggleBold(String editorType) {
    setState(() {
      switch (editorType) {
        case 'recommended':
          isBoldRecommended = !isBoldRecommended;
          break;
        case 'remarks':
          isBoldRemarks = !isBoldRemarks;
          break;
        case 'recap':
          isBoldRecap = !isBoldRecap;
          break;
        case 'internal':
          isBoldInternal = !isBoldInternal;
          break;
      }
    });
    _applyTextFormatting(editorType);
  }

  void _toggleItalic(String editorType) {
    setState(() {
      switch (editorType) {
        case 'recommended':
          isItalicRecommended = !isItalicRecommended;
          break;
        case 'remarks':
          isItalicRemarks = !isItalicRemarks;
          break;
        case 'recap':
          isItalicRecap = !isItalicRecap;
          break;
        case 'internal':
          isItalicInternal = !isItalicInternal;
          break;
      }
    });
    _applyTextFormatting(editorType);
  }

  void _applyTextFormatting(String editorType) {
    TextEditingController controller;
    bool isBold;
    bool isItalic;

    switch (editorType) {
      case 'recommended':
        controller = recommendedCtrl;
        isBold = isBoldRecommended;
        isItalic = isItalicRecommended;
        break;
      case 'remarks':
        controller = remarksCtrl;
        isBold = isBoldRemarks;
        isItalic = isItalicRemarks;
        break;
      case 'recap':
        controller = recapCtrl;
        isBold = isBoldRecap;
        isItalic = isItalicRecap;
        break;
      case 'internal':
        controller = internalCtrl;
        isBold = isBoldInternal;
        isItalic = isItalicInternal;
        break;
      default:
        return;
    }

    final selection = controller.selection;
    final text = controller.text;
    
    if (selection.isValid && !selection.isCollapsed) {
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);
      
      String formattedText = selectedText;
      
      if (isBold) {
        formattedText = '*$formattedText*';
      }
      if (isItalic) {
        formattedText = '_${formattedText}_';
      }
      
      final newText = text.replaceRange(start, end, formattedText);
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start + formattedText.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
   
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================= LEFT BIG EDITOR =================
                  Expanded(
                    flex: 4,
                    child: _buildEditorContainer(
                      title: 'Recommended Tour Treatments',
                      controller: recommendedCtrl,
                      icon: Icons.medical_services,
                      editorType: 'recommended',
                      isBold: isBoldRecommended,
                      isItalic: isItalicRecommended,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ================= MIDDLE EDITORS (INCREASED HEIGHT) =================
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // REMARKS EDITOR - Increased height
                        Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: _buildEditorContainer(
                            title: 'Remarks',
                            controller: remarksCtrl,
                            icon: Icons.comment,
                            editorType: 'remarks',
                            isBold: isBoldRemarks,
                            isItalic: isItalicRemarks,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // RECAP REMARKS EDITOR - Increased height
                        Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: _buildEditorContainer(
                            title: 'Recap Remarks',
                            controller: recapCtrl,
                            icon: Icons.summarize,
                            editorType: 'recap',
                            isBold: isBoldRecap,
                            isItalic: isItalicRecap,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // INTERNAL NOTES EDITOR - Increased height
                        Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: _buildEditorContainer(
                            title: 'Internal Notes',
                            controller: internalCtrl,
                            icon: Icons.note,
                            editorType: 'internal',
                            isBold: isBoldInternal,
                            isItalic: isItalicInternal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ================= RIGHT IMAGE PANEL (FIXED HEIGHT) =================
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2, // Fixed width
                    child: _buildRightPanel(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= ENHANCED EDITOR CONTAINER =================
  Widget _buildEditorContainer({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required String editorType,
    required bool isBold,
    required bool isItalic,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Editor Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.tableHeadColor, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      return Text(
                        '${value.text.length} chars',
                        style: AppTheme.caption.copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Enhanced Text Editor
          Expanded(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Obx(() => TextField(
                  controller: controller,
                  readOnly: this.controller.isLocked.value,
                  maxLines: null,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your ${title.toLowerCase()} here...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    filled: true,
                    fillColor: this.controller.isLocked.value ? Colors.grey.shade100 : Colors.white,
                  ),
                )),
              ),
            ),
          ),
          
          // Editor Footer with Formatting Buttons
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Obx(() => Row(
              children: [
                // Bold Button
                GestureDetector(
                  onTap: this.controller.isLocked.value ? null : () => _toggleBold(editorType),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: this.controller.isLocked.value
                          ? Colors.grey.shade300
                          : (isBold ? AppTheme.primaryColor : Colors.white),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: this.controller.isLocked.value
                            ? Colors.grey.shade400
                            : (isBold ? AppTheme.primaryColor : Colors.grey.shade300),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.format_bold,
                        size: 16,
                        color: this.controller.isLocked.value
                            ? Colors.grey.shade500
                            : (isBold ? Colors.white : AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Italic Button
                GestureDetector(
                  onTap: this.controller.isLocked.value ? null : () => _toggleItalic(editorType),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: this.controller.isLocked.value
                          ? Colors.grey.shade300
                          : (isItalic ? AppTheme.primaryColor : Colors.white),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: this.controller.isLocked.value
                            ? Colors.grey.shade400
                            : (isItalic ? AppTheme.primaryColor : Colors.grey.shade300),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.format_italic,
                        size: 16,
                        color: this.controller.isLocked.value
                            ? Colors.grey.shade500
                            : (isItalic ? Colors.white : AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // List Button (Placeholder)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: this.controller.isLocked.value ? Colors.grey.shade300 : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: this.controller.isLocked.value ? Colors.grey.shade400 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.format_list_bulleted,
                      size: 16,
                      color: this.controller.isLocked.value ? Colors.grey.shade500 : AppTheme.textSecondary,
                    ),
                  ),
                ),

                const Spacer(),

                // Clear Button
                TextButton.icon(
                  onPressed: this.controller.isLocked.value ? null : () {
                    controller.clear();
                    setState(() {
                      // Reset formatting states for this editor
                      switch (editorType) {
                        case 'recommended':
                          isBoldRecommended = false;
                          isItalicRecommended = false;
                          break;
                        case 'remarks':
                          isBoldRemarks = false;
                          isItalicRemarks = false;
                          break;
                        case 'recap':
                          isBoldRecap = false;
                          isItalicRecap = false;
                          break;
                        case 'internal':
                          isBoldInternal = false;
                          isItalicInternal = false;
                          break;
                      }
                    });
                  },
                  icon: Icon(
                    Icons.clear_all,
                    size: 16,
                    color: this.controller.isLocked.value ? Colors.grey.shade500 : AppTheme.errorColor,
                  ),
                  label: Text(
                    'Clear',
                    style: AppTheme.caption.copyWith(
                      color: this.controller.isLocked.value ? Colors.grey.shade500 : AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  // ================= RIGHT IMAGE PANEL (FIXED HEIGHT) =================
  Widget _buildRightPanel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // Fixed height - screen का 60%
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.tableHeadColor, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Document Attachment',
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Image Preview Area (Fixed Height)
          Container(
            height: MediaQuery.of(context).size.height * 0.3, // Preview area की fixed height
            padding: const EdgeInsets.all(12),
            child: _buildPreviewArea(),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // File Info
                if (selectedFile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 18,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedFile!.path.split('/').last,
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                '${(selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No file selected',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Buttons Row
                Obx(() => Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: this.controller.isLocked.value ? null : pickFile,
                        icon: const Icon(Icons.cloud_upload, size: 16),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: this.controller.isLocked.value ? Colors.grey.shade400 : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: this.controller.isLocked.value ? null : (selectedFile != null ? deleteFile : null),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: this.controller.isLocked.value ? Colors.grey.shade400 : AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ENHANCED PREVIEW AREA =================
  Widget _buildPreviewArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: selectedFile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      size: 30,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Preview',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload an image to preview',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _buildFilePreview(),
    );
  }

  Widget _buildFilePreview() {
    final extension = selectedFile!.path.split('.').last.toLowerCase();
    final fileName = selectedFile!.path.split('/').last;

    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          selectedFile!,
          fit: BoxFit.contain,
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondaryColor.withOpacity(0.1),
            ),
            child: Icon(
              _getFileIcon(extension),
              size: 30,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              fileName,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${extension.toUpperCase()} File',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_fields;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  void dispose() {
    recommendedCtrl.dispose();
    remarksCtrl.dispose();
    recapCtrl.dispose();
    internalCtrl.dispose();
    super.dispose();
  }
}