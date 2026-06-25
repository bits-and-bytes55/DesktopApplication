import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/mud_properties_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/mud_properties_model.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/mud_controller.dart';
import 'package:mudpro_desktop_app/modules/options/unit_definitions.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class DefaultMudPropertiesPage extends StatefulWidget {
  const DefaultMudPropertiesPage({super.key});

  @override
  State<DefaultMudPropertiesPage> createState() =>
      _DefaultMudPropertiesPageState();
}

class _DefaultMudPropertiesPageState extends State<DefaultMudPropertiesPage> {
  final MudPropertiesController _controller = MudPropertiesController();

  // ✅ Static data loaded directly from Flutter - no API call
  final MudPropertiesStaticData _staticData = MudPropertiesStaticData.defaultData;

  // ✅ Only selected data is fetched from backend
  SelectedMudProperties _selected = SelectedMudProperties(
    waterBased: [],
    oilBased: [],
    synthetic: [],
  );

  bool _isLoading = true;
  bool _isSaving = false;
  final Map<String, String> _unitOverrides = {};
  final Map<String, String> _formatOverrides = {};
  static const List<String> _formatOptions = [
    'Default',
    '0',
    '0.0',
    '0.00',
    '0.000',
    '0.0000',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSelected();
  }

  Future<void> _fetchSelected() async {
    setState(() => _isLoading = true);
    try {
      final selected = await _controller.getSelectedMudProperties();
      setState(() {
        _selected = selected;
        _primeUnitOverrides();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showError('Failed to load saved selections: $e');
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      final saved = await _controller.saveSelectedMudProperties(_selected);
      setState(() {
        _selected = saved;
        _isSaving = false;
      });
      if (Get.isRegistered<MudController>()) {
        await Get.find<MudController>().refreshMudPropertyUnitsFromSetup();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
	            content: Text('Default mud properties saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) _showError('Failed to save default mud properties: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _primeUnitOverrides() {
    _unitOverrides.clear();
    _formatOverrides.clear();
    for (final item in _selected.waterBased) {
      _unitOverrides[_unitKey('water', item.name)] = item.unit;
      _formatOverrides[_unitKey('water', item.name)] = item.format;
    }
    for (final item in _selected.oilBased) {
      _unitOverrides[_unitKey('oil', item.name)] = item.unit;
      _formatOverrides[_unitKey('oil', item.name)] = item.format;
    }
    for (final item in _selected.synthetic) {
      _unitOverrides[_unitKey('synthetic', item.name)] = item.unit;
      _formatOverrides[_unitKey('synthetic', item.name)] = item.format;
    }
  }

  String _unitKey(String col, String name) => '$col::${name.trim()}';

  List<MudPropertyItem> _selectedList(String col) {
    if (col == 'water') return _selected.waterBased;
    if (col == 'oil') return _selected.oilBased;
    return _selected.synthetic;
  }

  SelectedMudProperties _copyWithList(String col, List<MudPropertyItem> list) {
    if (col == 'water') return _selected.copyWith(waterBased: list);
    if (col == 'oil') return _selected.copyWith(oilBased: list);
    return _selected.copyWith(synthetic: list);
  }

  bool _containsByName(List<MudPropertyItem> items, MudPropertyItem item) =>
      items.any((selected) => selected.name == item.name);

  String _currentUnit(String col, MudPropertyItem item) {
    final override = _unitOverrides[_unitKey(col, item.name)];
    if (override != null) return override;
    final selected = _selectedList(col).where((e) => e.name == item.name);
    if (selected.isNotEmpty) return selected.first.unit;
    return item.unit;
  }

  String _currentFormat(String col, MudPropertyItem item) {
    final override = _formatOverrides[_unitKey(col, item.name)];
    if (override != null && override.trim().isNotEmpty) return override;
    final selected = _selectedList(col).where((e) => e.name == item.name);
    if (selected.isNotEmpty && selected.first.format.trim().isNotEmpty) {
      return selected.first.format;
    }
    return item.format;
  }

  MudPropertyItem _withCurrentUnit(String col, MudPropertyItem item) =>
      MudPropertyItem(
        name: item.name,
        unit: _currentUnit(col, item),
        format: _currentFormat(col, item),
      );

  String _displayName(String col, MudPropertyItem item) {
    if (col == 'water' &&
        (item.name == 'Filtrate Alkalinity (Pf)' ||
            item.name == 'Filtrate Alkalinity (Mf)')) {
      return 'Filtrate Alkalinity';
    }
    return item.name;
  }

  void _toggleItem(String col, MudPropertyItem item) {
    setState(() {
      final list = List<MudPropertyItem>.from(_selectedList(col));
      if (_containsByName(list, item)) {
        list.removeWhere((selected) => selected.name == item.name);
      } else {
        list.add(_withCurrentUnit(col, item));
      }
      _selected = _copyWithList(col, list);
    });
  }

  void _toggleSelectAll(String col) {
    setState(() {
      if (col == 'water') {
        final allSelected = _staticData.waterBased
            .every((item) => _containsByName(_selected.waterBased, item));
        _selected = _selected.copyWith(
          waterBased: allSelected
              ? []
              : _staticData.waterBased
                  .map((item) => _withCurrentUnit(col, item))
                  .toList(),
        );
      } else if (col == 'oil') {
        final allSelected = _staticData.oilBased
            .every((item) => _containsByName(_selected.oilBased, item));
        _selected = _selected.copyWith(
          oilBased: allSelected
              ? []
              : _staticData.oilBased
                  .map((item) => _withCurrentUnit(col, item))
                  .toList(),
        );
      } else if (col == 'synthetic') {
        final allSelected = _staticData.synthetic
            .every((item) => _containsByName(_selected.synthetic, item));
        _selected = _selected.copyWith(
          synthetic: allSelected
              ? []
              : _staticData.synthetic
                  .map((item) => _withCurrentUnit(col, item))
                  .toList(),
        );
      }
    });
  }

  bool _isAllSelected(String col) {
    if (col == 'water') {
      return _staticData.waterBased.isNotEmpty &&
          _staticData.waterBased
              .every((i) => _containsByName(_selected.waterBased, i));
    } else if (col == 'oil') {
      return _staticData.oilBased.isNotEmpty &&
          _staticData.oilBased
              .every((i) => _containsByName(_selected.oilBased, i));
    } else {
      return _staticData.synthetic.isNotEmpty &&
          _staticData.synthetic
              .every((i) => _containsByName(_selected.synthetic, i));
    }
  }

  void _changeUnit(String col, MudPropertyItem item, String unit) {
    setState(() {
      _unitOverrides[_unitKey(col, item.name)] = unit;
      final list = List<MudPropertyItem>.from(_selectedList(col));
      final index = list.indexWhere((selected) => selected.name == item.name);
      if (index >= 0) {
        list[index] = MudPropertyItem(
          name: item.name,
          unit: unit,
          format: _currentFormat(col, item),
        );
        _selected = _copyWithList(col, list);
      }
    });
  }

  void _changeFormat(String col, MudPropertyItem item, String format) {
    setState(() {
      _formatOverrides[_unitKey(col, item.name)] = format;
      final list = List<MudPropertyItem>.from(_selectedList(col));
      final index = list.indexWhere((selected) => selected.name == item.name);
      if (index >= 0) {
        list[index] = MudPropertyItem(
          name: item.name,
          unit: _currentUnit(col, item),
          format: format,
        );
        _selected = _copyWithList(col, list);
      }
    });
  }

  List<String> _unitOptionsFor(MudPropertyItem item) {
    final key = item.name.toLowerCase().replaceAll('*', '').trim();
    if (key.contains('flowline') ||
        key.contains('t. for pv') ||
        key.contains('t. for hthp') ||
        key.contains('hthp temp') ||
        key.contains('rheology temp')) {
      return const ['degF', 'degC'];
    }
    if (key == 'depth' || key.startsWith('depth ')) {
      return const ['m', 'ft'];
    }
    if (key == 'mw' || key.startsWith('mw ') || key.contains('mud weight')) {
      return UnitDefinitions.parameterUnits['33']!
          .map(_stripParens)
          .toList(growable: false);
    }
    return [item.unit];
  }

  String _stripParens(String unit) {
    final text = unit.trim();
    if (text.startsWith('(') && text.endsWith(')')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Default Mud Properties'),
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildPropertiesTable()),
                  const SizedBox(height: 16),
                  _buildFooterButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildPropertiesTable() {
    final maxRows = [
      _staticData.waterBased.length,
      _staticData.oilBased.length,
      _staticData.synthetic.length,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
            child: Row(
              children: [
                _buildHeaderCell('#', 50, isFixed: true),
                _buildHeaderCell('Water-based', null,
                    col: 'water', showSelectAll: true, flex: 2),
                _buildHeaderCell('Unit', 80, isFixed: true),
                _buildHeaderCell('Format', 82, isFixed: true),
                _buildHeaderCell('Oil-based', null,
                    col: 'oil', showSelectAll: true, flex: 2),
                _buildHeaderCell('Unit', 80, isFixed: true),
                _buildHeaderCell('Format', 82, isFixed: true),
                _buildHeaderCell('Synthetic', null,
                    col: 'synthetic', showSelectAll: true, flex: 2),
                _buildHeaderCell('Unit', 80, isFixed: true),
                _buildHeaderCell('Format', 82, isFixed: true),
              ],
            ),
          ),

          // Data Rows
          Expanded(
            child: maxRows == 0
                ? const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: maxRows,
                    itemBuilder: (context, index) {
                      return Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: index % 2 == 0
                              ? Colors.white
                              : Colors.grey.shade50,
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.tableGridBlue,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildNumberCell(index),
                            _buildSelectableCell(
                              col: 'water',
                              index: index,
                              items: _staticData.waterBased,
                              selectedItems: _selected.waterBased,
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.03),
                            ),
                            _buildUnitCell('water', index, _staticData.waterBased),
                            _buildFormatCell(
                                'water', index, _staticData.waterBased),
                            _buildSelectableCell(
                              col: 'oil',
                              index: index,
                              items: _staticData.oilBased,
                              selectedItems: _selected.oilBased,
                              backgroundColor:
                                  const Color(0xff8B4513).withOpacity(0.03),
                            ),
                            _buildUnitCell('oil', index, _staticData.oilBased),
                            _buildFormatCell('oil', index, _staticData.oilBased),
                            _buildSelectableCell(
                              col: 'synthetic',
                              index: index,
                              items: _staticData.synthetic,
                              selectedItems: _selected.synthetic,
                              backgroundColor:
                                  const Color(0xff20B2AA).withOpacity(0.03),
                            ),
                            _buildUnitCell(
                                'synthetic', index, _staticData.synthetic),
                            _buildFormatCell(
                                'synthetic', index, _staticData.synthetic),
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

  Widget _buildHeaderCell(
    String text,
    double? fixedWidth, {
    bool isFixed = false,
    String? col,
    bool showSelectAll = false,
    int flex = 1,
  }) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSelectAll && col != null) ...[
          GestureDetector(
            onTap: () => _toggleSelectAll(col),
            child: Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _isAllSelected(col) ? Colors.white : Colors.transparent,
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: _isAllSelected(col)
                  ? Icon(Icons.check, size: 12, color: AppTheme.primaryColor)
                  : null,
            ),
          ),
        ],
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final decoration = BoxDecoration(
      border: Border(
        right: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
      ),
    );

    if (isFixed) {
      return Container(
        width: fixedWidth,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: decoration,
        child: Center(child: content),
      );
    } else {
      return Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: decoration,
          child: Center(child: content),
        ),
      );
    }
  }

  Widget _buildUnitCell(String col, int index, List<MudPropertyItem> items) {
    final hasItem = index < items.length;
    final item = hasItem ? items[index] : null;
    final unit = item == null ? '-' : _currentUnit(col, item);
    final options = item == null ? const <String>[] : _unitOptionsFor(item);
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        ),
      ),
      child: Center(
        child: item == null
            ? Text(
                unit,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: options.contains(unit) ? unit : options.first,
                  isExpanded: true,
                  isDense: true,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  onChanged: (value) {
                    if (value != null) _changeUnit(col, item, value);
                  },
                  items: options
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
    );
  }

  Widget _buildFormatCell(String col, int index, List<MudPropertyItem> items) {
    final hasItem = index < items.length;
    final item = hasItem ? items[index] : null;
    final format = item == null ? '-' : _currentFormat(col, item);
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        ),
      ),
      child: Center(
        child: item == null
            ? Text(
                format,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _formatOptions.contains(format) ? format : 'Default',
                  isExpanded: true,
                  isDense: true,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  onChanged: (value) {
                    if (value != null) _changeFormat(col, item, value);
                  },
                  items: _formatOptions
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
    );
  }

  Widget _buildNumberCell(int index) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppTheme.tableGridBlue, width: 1),
        ),
      ),
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableCell({
    required String col,
    required int index,
    required List<MudPropertyItem> items,
    required List<MudPropertyItem> selectedItems,
    required Color backgroundColor,
  }) {
    final hasItem = index < items.length;
    final item = hasItem ? items[index] : null;
    final text = item == null ? '-' : _displayName(col, item);
    final isSelected =
        item != null && _containsByName(selectedItems, item);

    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: item != null ? () => _toggleItem(col, item) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.12)
                : backgroundColor,
            border: Border(
              right: BorderSide(color: AppTheme.tableGridBlue, width: 1),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: !hasItem
                  ? Colors.grey.shade400
                  : isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildCountBadge(
                  'Water: ${_selected.waterBased.length}', AppTheme.primaryColor),
              const SizedBox(width: 6),
              _buildCountBadge(
                  'Oil: ${_selected.oilBased.length}', const Color(0xff8B4513)),
              const SizedBox(width: 6),
              _buildCountBadge(
                  'Synthetic: ${_selected.synthetic.length}',
                  const Color(0xff20B2AA)),
            ],
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: _isSaving ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  minimumSize: Size.zero,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
