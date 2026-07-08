import 'dart:convert';
import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ffi/ffi.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/UG_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/formation_controller.dart';
import 'package:mudpro_desktop_app/modules/UG/model/formation_row_model.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:win32/win32.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/ug_ui_pattern.dart';

const Color _formationPoreColor = Color(0xFF22A33B);
const Color _formationFracColor = Color(0xFFFF2A2A);

class FormationView extends StatefulWidget {
  const FormationView({super.key});

  @override
  State<FormationView> createState() => _FormationViewState();
}

class _FormationViewState extends State<FormationView> {
  static const double _rowHeight = 27;
  static const double _headerTopHeight = 34;
  static const double _headerBottomHeight = 24;
  static const Color _borderColor = ugBorder;
  static const Color _headerColor = ugColumnHeader;
  static const Color _highlightColor = ugLockedEditable;

  final UgController ugController = Get.find<UgController>();
  final FormationController controller = Get.isRegistered<FormationController>()
      ? Get.find<FormationController>()
      : Get.put(FormationController());
  final ScrollController _scrollController = ScrollController();
  final Map<int, FocusNode> _lithologyFocusNodes = <int, FocusNode>{};

  FormationRow? _clipboard;

  @override
  void dispose() {
    _scrollController.dispose();
    for (final node in _lithologyFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isLocked => ugController.isLocked.value;

  bool get _rowsReadOnly => _isLocked || controller.poreFromTop.value;

  bool _rowHasData(FormationRow row) => row.hasData;

  _FormationLayout _layoutFor(double totalWidth, bool showGraph) {
    final desiredGraphWidth = showGraph
        ? (totalWidth * 0.20).clamp(220.0, 284.0)
        : 0.0;
    final graphWidth = showGraph
        ? math.min(desiredGraphWidth, math.max(0.0, totalWidth - 24))
        : 0.0;
    return _FormationLayout(
      gap: showGraph ? 8 : 0,
      graphWidth: graphWidth,
      indexWidth: 54,
      descriptionWidth: 196,
      tvdWidth: 132,
      dataWidth: 88,
      lithologyWidth: 124,
    );
  }

  bool _isModeEditable(String field) {
    switch (controller.mode.value) {
      case 'Density':
        return field == 'porePpg' || field == 'fracPpg';
      case 'Pressure':
        return field == 'porePsi' || field == 'fracPsi';
      case 'Gradient':
      default:
        return field == 'poreGrad' || field == 'fracGrad';
    }
  }

  Color _cellColor({
    required bool editableWhenUnlocked,
    bool highlightWhenReadOnly = true,
  }) {
    if (_rowsReadOnly) return _highlightColor;
    if (editableWhenUnlocked) return Colors.white;
    return highlightWhenReadOnly ? _highlightColor : Colors.white;
  }

  PopupMenuItem<String> _menuItem(
    String value,
    String label,
    String shortcut, {
    required bool enabled,
  }) {
    final color = enabled ? const Color(0xFF2F2F2F) : const Color(0xFF9EA4AD);
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.wellLikeBodyText.copyWith(color: color),
          ),
          const SizedBox(width: 20),
          Text(
            shortcut,
            style: AppTheme.wellLikeBodyText.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _showRowMenu(TapDownDetails details, int index) async {
    final row = controller.rows[index];
    final hasData = _rowHasData(row);
    final canMoveToTop = !_rowsReadOnly && hasData && index > 0;
    final canMoveToBottom =
        !_rowsReadOnly && hasData && index < controller.rows.length - 1;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _menuItem('cut', 'Cut', 'Ctrl+X', enabled: !_rowsReadOnly && hasData),
        _menuItem('copy', 'Copy', 'Ctrl+C', enabled: hasData),
        _menuItem(
          'paste',
          'Paste',
          'Ctrl+V',
          enabled: !_rowsReadOnly && _clipboard != null,
        ),
        _menuItem('delete', 'Delete', 'Delete', enabled: !_rowsReadOnly && hasData),
        const PopupMenuDivider(),
        _menuItem('top', 'To the Top', 'Ctrl+Up', enabled: canMoveToTop),
        _menuItem(
          'bottom',
          'To the Bottom',
          'Ctrl+Down',
          enabled: canMoveToBottom,
        ),
      ],
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'cut':
        _clipboard = row.clone();
        controller.clearRow(index);
        break;
      case 'copy':
        _clipboard = row.clone();
        break;
      case 'paste':
        if (_clipboard != null) {
          controller.pasteRow(index, _clipboard!);
        }
        break;
      case 'delete':
        controller.clearRow(index);
        break;
      case 'top':
        controller.moveRowToTop(index);
        break;
      case 'bottom':
        controller.moveRowToBottom(index);
        break;
    }
  }

  Widget _headerCell(
    String text, {
    required double width,
    double height = _headerBottomHeight,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: const BoxDecoration(
        color: ugColumnHeader,
        border: Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: 2,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _indexCell(FormationRow row, int index, _FormationLayout layout) {
    return Container(
      width: layout.indexWidth,
      height: _rowHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: _isLocked ? _highlightColor : Colors.white,
        border: const Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: Text(
              row.hasData ? '▸' : '',
              style: const TextStyle(fontSize: 9, color: Color(0xFF5B6470)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${index + 1}',
              style: AppTheme.wellLikeBodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableTextCell({
    required String value,
    required ValueChanged<String> onChanged,
    required double width,
    required bool editableWhenUnlocked,
    bool highlightWhenReadOnly = true,
    TextAlign textAlign = TextAlign.left,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isEditable = !_rowsReadOnly && editableWhenUnlocked;
    return Container(
      width: width,
      height: _rowHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _cellColor(
          editableWhenUnlocked: editableWhenUnlocked,
          highlightWhenReadOnly: highlightWhenReadOnly,
        ),
        border: const Border(
          right: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: isEditable
          ? TextFormField(
              key: ValueKey(value),
              initialValue: value,
              onChanged: onChanged,
              textAlign: textAlign,
              inputFormatters: inputFormatters,
              style: AppTheme.wellLikeBodyText,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 5),
              ),
            )
          : Align(
              alignment: textAlign == TextAlign.left
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Text(
                value,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: value.isEmpty
                      ? const Color(0xFFB2B7BF)
                      : const Color(0xFF2F2F2F),
                ),
              ),
            ),
    );
  }

  Widget _lithologyCell(FormationRow row, int index, _FormationLayout layout) {
    final imageBytes = _decodeLithologyImage(row.lithology.value);
    final focusNode = _lithologyFocusNodes.putIfAbsent(
      index,
      () => FocusNode(debugLabel: 'Formation lithology $index'),
    );
    final child = imageBytes == null
        ? Text(
            'No image data',
            style: const TextStyle(fontSize: 10, color: Color(0xFF4A4F57)),
            overflow: TextOverflow.ellipsis,
          )
        : ClipRect(
            child: Image.memory(
              imageBytes,
              width: layout.lithologyWidth - 8,
              height: _rowHeight - 4,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const Text(
                'No image data',
                style: TextStyle(fontSize: 10, color: Color(0xFF4A4F57)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        final isPaste = HardwareKeyboard.instance.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyV;
        if (!_rowsReadOnly && isPaste && event is KeyDownEvent) {
          _pasteLithologyImageFromClipboard(index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        canRequestFocus: true,
        onTap: _rowsReadOnly ? null : () {},
        onTapDown: _rowsReadOnly
            ? null
            : (details) async {
                focusNode.requestFocus();
                await _showLithologyMenu(details, row, index);
              },
        child: Container(
          width: layout.lithologyWidth,
          height: _rowHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _rowsReadOnly ? _highlightColor : Colors.white,
            border: const Border(
              right: BorderSide(color: _borderColor),
              bottom: BorderSide(color: _borderColor),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _showLithologyMenu(
    TapDownDetails details,
    FormationRow row,
    int index,
  ) async {
    final hasClipboardImage = _readWindowsClipboardImage() != null;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        _menuItem('paste_image', 'Paste', 'Click', enabled: hasClipboardImage),
        _menuItem('upload_image', 'Upload', 'Browse', enabled: true),
        if (row.lithology.value.trim().isNotEmpty)
        _menuItem('clear_image', 'Clear', 'Delete', enabled: !_rowsReadOnly),
      ],
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'paste_image':
        await _pasteLithologyImageFromClipboard(index);
        break;
      case 'upload_image':
        await _pickLithologyImage(row);
        break;
      case 'clear_image':
        controller.updateLithology(index, '');
        break;
    }
  }

  Future<bool> _pasteLithologyImageFromClipboard(int index) async {
    final image = _readWindowsClipboardImage();
    if (image == null || image.bytes.isEmpty) return false;
    controller.updateLithology(
      index,
      'data:${image.mimeType};base64,${base64Encode(image.bytes)}',
    );
    return true;
  }

  _ClipboardImage? _readWindowsClipboardImage() {
    if (!Platform.isWindows) return null;

    if (OpenClipboard(0) == 0) return null;

    try {
      final pngBytes = _readRegisteredClipboardFormat(
        const ['PNG', 'image/png'],
      );
      if (pngBytes != null && pngBytes.isNotEmpty) {
        return _ClipboardImage(bytes: pngBytes, mimeType: 'image/png');
      }

      final dibFormat =
          IsClipboardFormatAvailable(CF_DIBV5) != 0 ? CF_DIBV5 : CF_DIB;
      if (IsClipboardFormatAvailable(dibFormat) == 0) return null;

      final dibBytes = _readClipboardFormatBytes(dibFormat);
      final bmpBytes = dibBytes == null ? null : _dibToBmpBytes(dibBytes);
      if (bmpBytes != null && bmpBytes.isNotEmpty) {
        return _ClipboardImage(bytes: bmpBytes, mimeType: 'image/bmp');
      }

      final bitmapBytes = _readBitmapClipboardBytes();
      if (bitmapBytes != null && bitmapBytes.isNotEmpty) {
        return _ClipboardImage(bytes: bitmapBytes, mimeType: 'image/bmp');
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      CloseClipboard();
    }
  }

  Uint8List? _readRegisteredClipboardFormat(List<String> names) {
    for (final name in names) {
      final namePointer = name.toNativeUtf16();
      try {
        final format = RegisterClipboardFormat(namePointer);
        if (format != 0 && IsClipboardFormatAvailable(format) != 0) {
          return _readClipboardFormatBytes(format);
        }
      } finally {
        calloc.free(namePointer);
      }
    }
    return null;
  }

  Uint8List? _readClipboardFormatBytes(int format) {
    final rawHandle = GetClipboardData(format);
    if (rawHandle == 0) return null;

    final handle = Pointer.fromAddress(rawHandle);
    final size = GlobalSize(handle);
    if (size <= 0) return null;

    final lockedMemory = GlobalLock(handle);
    if (lockedMemory == nullptr) return null;

    try {
      return Uint8List.fromList(lockedMemory.cast<Uint8>().asTypedList(size));
    } finally {
      GlobalUnlock(handle);
    }
  }

  Uint8List? _readBitmapClipboardBytes() {
    if (IsClipboardFormatAvailable(CF_BITMAP) == 0) return null;

    final hBitmap = GetClipboardData(CF_BITMAP);
    if (hBitmap == 0) return null;

    final hdc = CreateCompatibleDC(0);
    if (hdc == 0) return null;

    final bitmapInfo = calloc<BITMAPINFO>();
    try {
      bitmapInfo.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();

      final headerResult = GetDIBits(
        hdc,
        hBitmap,
        0,
        0,
        nullptr,
        bitmapInfo,
        DIB_RGB_COLORS,
      );
      if (headerResult == 0) return null;

      final header = bitmapInfo.ref.bmiHeader;
      final width = header.biWidth;
      final height = header.biHeight < 0 ? -header.biHeight : header.biHeight;
      final bitCount = header.biBitCount;
      if (width <= 0 || height <= 0 || bitCount <= 0) return null;

      final bytesPerLine = (((width * bitCount) + 31) ~/ 32) * 4;
      final imageSize = header.biSizeImage > 0
          ? header.biSizeImage
          : bytesPerLine * height;
      if (imageSize <= 0) return null;

      final pixelBuffer = calloc<Uint8>(imageSize);
      try {
        final imageResult = GetDIBits(
          hdc,
          hBitmap,
          0,
          height,
          pixelBuffer,
          bitmapInfo,
          DIB_RGB_COLORS,
        );
        if (imageResult == 0) return null;

        final dibHeaderSize = bitmapInfo.ref.bmiHeader.biSize;
        final dibBytes = Uint8List(dibHeaderSize + imageSize);
        final dibView = ByteData.sublistView(dibBytes);

        dibView.setUint32(0, bitmapInfo.ref.bmiHeader.biSize, Endian.little);
        dibView.setInt32(4, bitmapInfo.ref.bmiHeader.biWidth, Endian.little);
        dibView.setInt32(8, bitmapInfo.ref.bmiHeader.biHeight, Endian.little);
        dibView.setUint16(12, bitmapInfo.ref.bmiHeader.biPlanes, Endian.little);
        dibView.setUint16(
          14,
          bitmapInfo.ref.bmiHeader.biBitCount,
          Endian.little,
        );
        dibView.setUint32(
          16,
          bitmapInfo.ref.bmiHeader.biCompression,
          Endian.little,
        );
        dibView.setUint32(20, imageSize, Endian.little);
        dibView.setInt32(
          24,
          bitmapInfo.ref.bmiHeader.biXPelsPerMeter,
          Endian.little,
        );
        dibView.setInt32(
          28,
          bitmapInfo.ref.bmiHeader.biYPelsPerMeter,
          Endian.little,
        );
        dibView.setUint32(
          32,
          bitmapInfo.ref.bmiHeader.biClrUsed,
          Endian.little,
        );
        dibView.setUint32(
          36,
          bitmapInfo.ref.bmiHeader.biClrImportant,
          Endian.little,
        );
        dibBytes.setRange(
          dibHeaderSize,
          dibHeaderSize + imageSize,
          pixelBuffer.asTypedList(imageSize),
        );
        return _dibToBmpBytes(dibBytes);
      } finally {
        calloc.free(pixelBuffer);
      }
    } finally {
      calloc.free(bitmapInfo);
      DeleteDC(hdc);
    }
  }

  Uint8List? _dibToBmpBytes(Uint8List dibBytes) {
    if (dibBytes.length < 40) return null;

    final dibData = ByteData.sublistView(dibBytes);
    final dibHeaderSize = dibData.getUint32(0, Endian.little);
    if (dibHeaderSize <= 0 || dibHeaderSize > dibBytes.length) return null;

    final pixelOffset = 14 + _dibPixelOffset(dibData, dibBytes.length);
    final fileSize = 14 + dibBytes.length;
    final bmpBytes = Uint8List(fileSize);
    final bmpData = ByteData.sublistView(bmpBytes);

    bmpBytes[0] = 0x42;
    bmpBytes[1] = 0x4D;
    bmpData.setUint32(2, fileSize, Endian.little);
    bmpData.setUint32(10, pixelOffset, Endian.little);
    bmpBytes.setRange(14, fileSize, dibBytes);
    return bmpBytes;
  }

  int _dibPixelOffset(ByteData dibData, int length) {
    final headerSize = dibData.getUint32(0, Endian.little);
    if (headerSize < 40 || length < headerSize) return headerSize;

    final bitCount = dibData.getUint16(14, Endian.little);
    final compression = dibData.getUint32(16, Endian.little);
    final colorsUsed = dibData.getUint32(32, Endian.little);
    final colorTableEntries = bitCount <= 8
        ? (colorsUsed > 0 ? colorsUsed : 1 << bitCount)
        : 0;
    final bitfieldMaskBytes = compression == BI_BITFIELDS && headerSize == 40
        ? 12
        : 0;
    return headerSize + bitfieldMaskBytes + (colorTableEntries * 4);
  }

  Future<void> _pickLithologyImage(FormationRow row) async {
    final index = controller.rows.indexOf(row);
    if (index < 0) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (bytes == null || bytes.isEmpty) return;

    final extension = (file!.extension ?? 'png').toLowerCase();
    final mime = extension == 'jpg' || extension == 'jpeg'
        ? 'image/jpeg'
        : extension == 'webp'
            ? 'image/webp'
            : extension == 'bmp'
                ? 'image/bmp'
                : 'image/png';
    controller.updateLithology(
      index,
      'data:$mime;base64,${base64Encode(bytes)}',
    );
  }

  Uint8List? _decodeLithologyImage(String value) {
    final raw = value.trim();
    if (!raw.startsWith('data:image/')) return null;
    final commaIndex = raw.indexOf(',');
    if (commaIndex < 0) return null;
    try {
      return base64Decode(raw.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Widget _buildRow(FormationRow row, int index, _FormationLayout layout) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => _showRowMenu(details, index),
      child: Row(
        children: [
          _indexCell(row, index, layout),
          _editableTextCell(
            value: row.description.value,
            onChanged: (value) => controller.updateDescription(index, value),
            width: layout.descriptionWidth,
            editableWhenUnlocked: true,
            textAlign: TextAlign.left,
          ),
          _editableTextCell(
            value: row.tvd.value,
            onChanged: (value) => controller.updateTvd(index, value),
            width: layout.tvdWidth,
            editableWhenUnlocked: true,
            textAlign: TextAlign.left,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _editableTextCell(
            value: row.porePpg.value,
            onChanged: (value) =>
                controller.updateValue(index, 'porePpg', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('porePpg'),
            textAlign: TextAlign.left,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
            ],
          ),
          _editableTextCell(
            value: row.poreGrad.value,
            onChanged: (value) =>
                controller.updateValue(index, 'poreGrad', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('poreGrad'),
            textAlign: TextAlign.left,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _editableTextCell(
            value: controller.calculatedPressureText(row, pore: true),
            onChanged: (value) =>
                controller.updateValue(index, 'porePsi', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('porePsi'),
            textAlign: TextAlign.left,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _editableTextCell(
            value: row.fracPpg.value,
            onChanged: (value) =>
                controller.updateValue(index, 'fracPpg', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('fracPpg'),
            textAlign: TextAlign.left,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
            ],
          ),
          _editableTextCell(
            value: row.fracGrad.value,
            onChanged: (value) =>
                controller.updateValue(index, 'fracGrad', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('fracGrad'),
            textAlign: TextAlign.left,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _editableTextCell(
            value: controller.calculatedPressureText(row, pore: false),
            onChanged: (value) =>
                controller.updateValue(index, 'fracPsi', value),
            width: layout.dataWidth,
            editableWhenUnlocked: _isModeEditable('fracPsi'),
            textAlign: TextAlign.left,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}$')),
            ],
          ),
          _lithologyCell(row, index, layout),
        ],
      ),
    );
  }

  Widget _topControls() {
    return Obx(
      () => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        color: AppTheme.primaryColor,
        child: Row(
          children: [
            Checkbox(
              value: controller.poreFromTop.value,
              onChanged: _isLocked
                  ? null
                  : (value) => controller.setPoreFromTop(value ?? true),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Pore and Fracture (from top down)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 92,
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: _isLocked ? _highlightColor : Colors.white,
                border: Border.all(color: _borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.mode.value,
                  items: const [
                    DropdownMenuItem(value: 'Density', child: Text('Density')),
                    DropdownMenuItem(
                      value: 'Gradient',
                      child: Text('Gradient'),
                    ),
                    DropdownMenuItem(
                      value: 'Pressure',
                      child: Text('Pressure'),
                    ),
                  ],
                  onChanged: _isLocked
                      ? null
                      : (value) => controller.setMode(value ?? 'Density'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2F2F2F),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, size: 14),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: controller.isGraphVisible.value
                    ? const Color(0xFFE9F2FF)
                    : Colors.white,
                border: Border.all(color: _borderColor),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 13,
                tooltip: 'Graph',
                onPressed: controller.toggleGraph,
                icon: const Icon(Icons.show_chart, color: Color(0xFF2265A8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(_FormationLayout layout) {
    return Column(
      children: [
        Row(
          children: [
            _headerCell('', width: layout.indexWidth, height: _headerTopHeight),
            _headerCell(
              'Description',
              width: layout.descriptionWidth,
              height: _headerTopHeight,
            ),
            _headerCell(
              'Btm TVD\n${AppUnits.unitText('(ft)')}',
              width: layout.tvdWidth,
              height: _headerTopHeight,
            ),
            _headerCell(
              'Pore',
              width: layout.dataWidth * 3,
              height: _headerTopHeight,
            ),
            _headerCell(
              'Frac.',
              width: layout.dataWidth * 3,
              height: _headerTopHeight,
            ),
            _headerCell(
              'Lithology',
              width: layout.lithologyWidth,
              height: _headerTopHeight,
            ),
          ],
        ),
        Row(
          children: [
            _headerCell('', width: layout.indexWidth),
            _headerCell('', width: layout.descriptionWidth),
            _headerCell('', width: layout.tvdWidth),
            _headerCell(AppUnits.unitText('(ppg)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(psi/ft)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(psi)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(ppg)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(psi/ft)'), width: layout.dataWidth),
            _headerCell(AppUnits.unitText('(psi)'), width: layout.dataWidth),
            _headerCell('', width: layout.lithologyWidth),
          ],
        ),
      ],
    );
  }

  Widget _tableBody(_FormationLayout layout) {
    return Obx(
      () {
        final readOnly = _rowsReadOnly;
        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: ListView.builder(
            key: ValueKey(readOnly),
            controller: _scrollController,
            itemCount: controller.rows.length,
            itemBuilder: (_, index) =>
                _buildRow(controller.rows[index], index, layout),
          ),
        );
      },
    );
  }

  Widget _formationTable(_FormationLayout layout) {
    return SizedBox(
      width: layout.tableWidth,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            _topControls(),
            _tableHeader(layout),
            Expanded(child: _tableBody(layout)),
            Container(
              height: 28,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: const Text(
                'Formation properties below the last entered depth are constant.',
                style: TextStyle(fontSize: 10, color: Color(0xFF3E5D7A)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _graphPanel(_FormationLayout layout) {
    return Obx(() {
      if (!controller.isGraphVisible.value) {
        return const SizedBox.shrink();
      }

      return Container(
        width: layout.graphWidth,
        margin: EdgeInsets.only(left: layout.gap),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            const Text(
              'Formation P.',
              style: AppTheme.wellLikeBodyText,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: CustomPaint(
                painter: _FormationGraphPainter(
                  mode: controller.mode.value,
                  porePoints: controller.showPoreGraph.value
                      ? controller.graphPoints(pore: true)
                      : const <FormationGraphPoint>[],
                  fracPoints: controller.showFracGraph.value
                      ? controller.graphPoints(pore: false)
                      : const <FormationGraphPoint>[],
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: controller.showPoreGraph.value,
                  onChanged: (value) =>
                      controller.showPoreGraph.value = value ?? true,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  activeColor: _formationPoreColor,
                ),
                const Text(
                  'Pore',
                  style: AppTheme.wellLikeBodyText,
                ),
                const SizedBox(width: 10),
                Checkbox(
                  value: controller.showFracGraph.value,
                  onChanged: (value) =>
                      controller.showFracGraph.value = value ?? true,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  activeColor: _formationFracColor,
                ),
                const Text(
                  'Frac',
                  style: AppTheme.wellLikeBodyText,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ugPageBackground,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: LayoutBuilder(
        builder: (context, constraints) => Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final layout = _layoutFor(
            constraints.maxWidth,
            controller.isGraphVisible.value,
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _formationTable(layout),
                  ),
                ),
              ),
              _graphPanel(layout),
            ],
          );
        }),
      ),
    );
  }
}

class _FormationLayout {
  final double gap;
  final double graphWidth;
  final double indexWidth;
  final double descriptionWidth;
  final double tvdWidth;
  final double dataWidth;
  final double lithologyWidth;
  double get tableWidth =>
      indexWidth +
      descriptionWidth +
      tvdWidth +
      (dataWidth * 6) +
      lithologyWidth +
      4;

  const _FormationLayout({
    required this.gap,
    required this.graphWidth,
    required this.indexWidth,
    required this.descriptionWidth,
    required this.tvdWidth,
    required this.dataWidth,
    required this.lithologyWidth,
  });
}

class _ClipboardImage {
  final Uint8List bytes;
  final String mimeType;

  const _ClipboardImage({required this.bytes, required this.mimeType});
}

class _FormationGraphPainter extends CustomPainter {
  final String mode;
  final List<FormationGraphPoint> porePoints;
  final List<FormationGraphPoint> fracPoints;

  const _FormationGraphPainter({
    required this.mode,
    required this.porePoints,
    required this.fracPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 52.0;
    const rightPad = 16.0;
    const topPad = 18.0;
    const bottomPad = 52.0;
    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      math.max(0, size.width - leftPad - rightPad),
      math.max(0, size.height - topPad - bottomPad),
    );

    final axisPaint = Paint()
      ..color = const Color(0xFFB7BDC7)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final chartBackgroundPaint = Paint()..color = Colors.white;
    final gridPaint = Paint()
      ..color = const Color(0xFFD8DCE3)
      ..strokeWidth = 1;

    canvas.drawRect(chartRect, chartBackgroundPaint);
    canvas.drawRect(chartRect, axisPaint);

    final allPoints = [...porePoints, ...fracPoints];
    final maxTvd = _niceAxisMax(
      allPoints.isEmpty
          ? 2000
          : allPoints.map((item) => item.tvd).reduce(math.max),
      minimum: 2000,
      step: 500,
    );
    final maxValue = _niceAxisMax(
      allPoints.isEmpty
          ? _defaultValueAxisMax
          : allPoints.map((item) => item.value).reduce(math.max),
      minimum: _defaultValueAxisMax,
      step: _valueAxisStep,
    );

    final yStep = _tvdAxisStep(maxTvd);
    final xTicks = (maxValue / _valueAxisStep).round();
    for (int i = 1; i < xTicks; i++) {
      final value = i * _valueAxisStep;
      final dx = chartRect.left + (value / maxValue) * chartRect.width;
      canvas.drawLine(
        Offset(dx, chartRect.top),
        Offset(dx, chartRect.bottom),
        gridPaint,
      );
    }
    final yTicks = (maxTvd / yStep).round();
    for (int i = 1; i < yTicks; i++) {
      final tvd = i * yStep;
      final dy = chartRect.top + (tvd / maxTvd) * chartRect.height;
      canvas.drawLine(
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        gridPaint,
      );
    }

    _drawAxisLabels(canvas, chartRect, maxTvd, maxValue);
    _drawLine(
      canvas,
      chartRect,
      porePoints,
      maxTvd,
      maxValue,
      _formationPoreColor,
    );
    _drawLine(
      canvas,
      chartRect,
      fracPoints,
      maxTvd,
      maxValue,
      _formationFracColor,
    );
  }

  double get _defaultValueAxisMax {
    switch (mode) {
      case 'Density':
        return 14;
      case 'Pressure':
        return 2000;
      case 'Gradient':
      default:
        return 1;
    }
  }

  double get _valueAxisStep {
    switch (mode) {
      case 'Density':
        return 2;
      case 'Pressure':
        return 500;
      case 'Gradient':
      default:
        return 0.1;
    }
  }

  double _tvdAxisStep(double maxTvd) {
    if (maxTvd <= 2000) return 500;
    if (maxTvd <= 5000) return 1000;
    return 2000;
  }

  double _niceAxisMax(
    double value, {
    required double minimum,
    required double step,
  }) {
    final target = math.max(value, minimum);
    return (target / step).ceil() * step;
  }

  void _drawAxisLabels(
    Canvas canvas,
    Rect rect,
    double maxTvd,
    double maxValue,
  ) {
    final labelStyle = const TextStyle(
      fontSize: 10,
      color: Color(0xFF4A4F57),
    );
    final axisStyle = const TextStyle(fontSize: 11, color: Color(0xFF2F2F2F));

    final yStep = _tvdAxisStep(maxTvd);
    final yTicks = (maxTvd / yStep).round();
    for (int i = 0; i <= yTicks; i++) {
      final tvd = i * yStep;
      final y = rect.top + (tvd / maxTvd) * rect.height;
      final painter = TextPainter(
        text: TextSpan(text: tvd.toStringAsFixed(0), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(rect.left - painter.width - 8, y - 6));
    }

    final xTicks = (maxValue / _valueAxisStep).round();
    for (int i = 0; i <= xTicks; i++) {
      final value = i * _valueAxisStep;
      final x = rect.left + (value / maxValue) * rect.width;
      final painter = TextPainter(
        text: TextSpan(text: _formatAxisValue(value), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x - (painter.width / 2), rect.bottom + 8));
    }

    final yAxis = TextPainter(
      text: TextSpan(
        text: 'TVD ${AppUnits.unitText('(ft)')}',
        style: axisStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(16, rect.center.dy + (yAxis.width / 2));
    canvas.rotate(-math.pi / 2);
    yAxis.paint(canvas, Offset.zero);
    canvas.restore();

    final xAxis = TextPainter(
      text: TextSpan(
        text: _xAxisTitle,
        style: axisStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xAxis.paint(
      canvas,
      Offset(rect.center.dx - (xAxis.width / 2), rect.bottom + 28),
    );
  }

  String get _xAxisTitle {
    switch (mode) {
      case 'Density':
        return 'Density ${AppUnits.unitText('(ppg)')}';
      case 'Pressure':
        return 'Pressure ${AppUnits.unitText('(psi)')}';
      case 'Gradient':
      default:
        return 'P. Gradient ${AppUnits.unitText('(psi/ft)')}';
    }
  }

  String _formatAxisValue(double value) {
    if (mode == 'Gradient') {
      return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    }
    return value.toStringAsFixed(0);
  }

  void _drawLine(
    Canvas canvas,
    Rect rect,
    List<FormationGraphPoint> points,
    double maxTvd,
    double maxValue,
    Color color,
  ) {
    if (points.isEmpty) return;
    final path = Path();
    path.moveTo(rect.left, rect.top);
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = rect.left + (point.value / maxValue) * rect.width;
      final y = rect.top + (point.tvd / maxTvd) * rect.height;
      path.lineTo(x, y);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FormationGraphPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.porePoints != porePoints ||
        oldDelegate.fracPoints != fracPoints;
  }
}
