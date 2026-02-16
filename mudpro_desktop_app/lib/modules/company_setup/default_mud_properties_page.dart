import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/others_model.dart';

class DefaultMudPropertiesPage extends StatefulWidget {
  const DefaultMudPropertiesPage({super.key});

  @override
  State<DefaultMudPropertiesPage> createState() => _DefaultMudPropertiesPageState();
}

class _DefaultMudPropertiesPageState extends State<DefaultMudPropertiesPage> {
  final OthersController _controller = OthersController();
  
  List<WaterBasedItem> _waterBasedItems = [];
  List<OilBasedItem> _oilBasedItems = [];
  List<SyntheticItem> _syntheticItems = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _controller.getWaterBased(),
        _controller.getOilBased(),
        _controller.getSynthetic(),
      ]);

      setState(() {
        _waterBasedItems = results[0] as List<WaterBasedItem>;
        _oilBasedItems = results[1] as List<OilBasedItem>;
        _syntheticItems = results[2] as List<SyntheticItem>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('Failed to load data: $e');
      }
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
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildPropertiesTable(),
                  ),
                  const SizedBox(height: 16),
                  _buildFooterButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildPropertiesTable() {
    final maxRows = [
      _waterBasedItems.length,
      _oilBasedItems.length,
      _syntheticItems.length,
    ].reduce((a, b) => a > b ? a : b);

    const colWidths = [60.0, null, null, null]; // #, Water-based, Oil-based, Synthetic

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
                _buildHeaderCell('#', colWidths[0], true),
                _buildHeaderCell('Water-based', colWidths[1], false),
                _buildHeaderCell('Oil-based', colWidths[2], false),
                _buildHeaderCell('Synthetic', colWidths[3], false),
              ],
            ),
          ),
          
          // Data Rows
          if (maxRows == 0)
            Container(
              height: 100,
              child: const Center(
                child: Text(
                  'No data available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: maxRows,
              itemBuilder: (context, index) {
                return Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
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
                      _buildDataCell(
                        index < _waterBasedItems.length 
                            ? _waterBasedItems[index].name 
                            : '-',
                        colWidths[1],
                        AppTheme.primaryColor.withOpacity(0.03),
                      ),
                      _buildDataCell(
                        index < _oilBasedItems.length 
                            ? _oilBasedItems[index].name 
                            : '-',
                        colWidths[2],
                        const Color(0xff8B4513).withOpacity(0.03),
                      ),
                      _buildDataCell(
                        index < _syntheticItems.length 
                            ? _syntheticItems[index].name 
                            : '-',
                        colWidths[3],
                        const Color(0xff20B2AA).withOpacity(0.03),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double? width, bool isFirst) {
    if (isFirst) {
      return Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Center(
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
      );
    } else {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Center(
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
        ),
      );
    }
  }

  Widget _buildNumberCell(int index) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
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

  Widget _buildDataCell(String text, double? width, Color backgroundColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            right: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: text == '-' ? Colors.grey.shade400 : AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Text(
                  'Water: ${_waterBasedItems.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff8B4513).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xff8B4513).withOpacity(0.2)),
                ),
                child: Text(
                  'Oil: ${_oilBasedItems.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff20B2AA).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xff20B2AA).withOpacity(0.2)),
                ),
                child: Text(
                  'Synthetic: ${_syntheticItems.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
    );
  }
}