import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/mud_properties_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/mud_properties_model.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) _showError('Failed to save: $e');
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

  void _toggleItem(String col, MudPropertyItem item) {
    setState(() {
      if (col == 'water') {
        final list = List<MudPropertyItem>.from(_selected.waterBased);
        list.contains(item) ? list.remove(item) : list.add(item);
        _selected = _selected.copyWith(waterBased: list);
      } else if (col == 'oil') {
        final list = List<MudPropertyItem>.from(_selected.oilBased);
        list.contains(item) ? list.remove(item) : list.add(item);
        _selected = _selected.copyWith(oilBased: list);
      } else if (col == 'synthetic') {
        final list = List<MudPropertyItem>.from(_selected.synthetic);
        list.contains(item) ? list.remove(item) : list.add(item);
        _selected = _selected.copyWith(synthetic: list);
      }
    });
  }

  void _toggleSelectAll(String col) {
    setState(() {
      if (col == 'water') {
        final allSelected = _staticData.waterBased
            .every((item) => _selected.waterBased.contains(item));
        _selected = _selected.copyWith(
          waterBased: allSelected ? [] : List.from(_staticData.waterBased),
        );
      } else if (col == 'oil') {
        final allSelected = _staticData.oilBased
            .every((item) => _selected.oilBased.contains(item));
        _selected = _selected.copyWith(
          oilBased: allSelected ? [] : List.from(_staticData.oilBased),
        );
      } else if (col == 'synthetic') {
        final allSelected = _staticData.synthetic
            .every((item) => _selected.synthetic.contains(item));
        _selected = _selected.copyWith(
          synthetic: allSelected ? [] : List.from(_staticData.synthetic),
        );
      }
    });
  }

  bool _isAllSelected(String col) {
    if (col == 'water') {
      return _staticData.waterBased.isNotEmpty &&
          _staticData.waterBased
              .every((i) => _selected.waterBased.contains(i));
    } else if (col == 'oil') {
      return _staticData.oilBased.isNotEmpty &&
          _staticData.oilBased.every((i) => _selected.oilBased.contains(i));
    } else {
      return _staticData.synthetic.isNotEmpty &&
          _staticData.synthetic.every((i) => _selected.synthetic.contains(i));
    }
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
        borderRadius: BorderRadius.circular(6),
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
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                _buildHeaderCell('#', 50, isFixed: true),
                _buildHeaderCell('Water-based', null,
                    col: 'water', showSelectAll: true, flex: 2),
                _buildHeaderCell('Unit', 80, isFixed: true),
                _buildHeaderCell('Oil-based', null,
                    col: 'oil', showSelectAll: true, flex: 2),
                _buildHeaderCell('Unit', 80, isFixed: true),
                _buildHeaderCell('Synthetic', null,
                    col: 'synthetic', showSelectAll: true, flex: 2),
                _buildHeaderCell('Unit', 80, isFixed: true),
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
                        height: 42,
                        decoration: BoxDecoration(
                          color: index % 2 == 0
                              ? Colors.white
                              : Colors.grey.shade50,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
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
                            _buildUnitCell(index, _staticData.waterBased),
                            _buildSelectableCell(
                              col: 'oil',
                              index: index,
                              items: _staticData.oilBased,
                              selectedItems: _selected.oilBased,
                              backgroundColor:
                                  const Color(0xff8B4513).withOpacity(0.03),
                            ),
                            _buildUnitCell(index, _staticData.oilBased),
                            _buildSelectableCell(
                              col: 'synthetic',
                              index: index,
                              items: _staticData.synthetic,
                              selectedItems: _selected.synthetic,
                              backgroundColor:
                                  const Color(0xff20B2AA).withOpacity(0.03),
                            ),
                            _buildUnitCell(index, _staticData.synthetic),
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

  Widget _buildUnitCell(int index, List<MudPropertyItem> items) {
    final hasItem = index < items.length;
    final unit = hasItem ? items[index].unit : '-';
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Center(
        child: Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
          overflow: TextOverflow.ellipsis,
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
          right: BorderSide(color: Colors.grey.shade300, width: 1),
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
    final text = item?.name ?? '-';
    final isSelected = item != null && selectedItems.contains(item);

    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: item != null ? () => _toggleItem(col, item) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.12)
                : backgroundColor,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300, width: 1),
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