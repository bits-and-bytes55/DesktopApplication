import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/others_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/default_mud_properties_page.dart';

class OthersPage extends StatefulWidget {
  const OthersPage({super.key});

  @override
  State<OthersPage> createState() => _OthersPageState();
}

class _OthersPageState extends State<OthersPage> {
  int _activityRowCount = 1;
  int _additionRowCount = 1;
  int _lossRowCount = 1;
  int _waterRowCount = 1;
  int _oilRowCount = 1;
  int _syntheticRowCount = 1;

  late final OthersController _controller = OthersController();

  List<ActivityItem> _loadedActivities = [];
  List<AdditionItem> _loadedAdditions = [];
  List<LossItem> _loadedLosses = [];
  List<WaterBasedItem> _loadedWaterBased = [];
  List<OilBasedItem> _loadedOilBased = [];
  List<SyntheticItem> _loadedSynthetic = [];

  Set<int> _lockedActivityRows = {};
  Set<int> _lockedAdditionRows = {};
  Set<int> _lockedLossRows = {};
  Set<int> _lockedWaterRows = {};
  Set<int> _lockedOilRows = {};
  Set<int> _lockedSyntheticRows = {};

  bool _isLoading = true;

  List<TextEditingController> _genSingleCol(int count) =>
      List.generate(count, (_) => TextEditingController());

  int _getRowCountForTable(String title) {
    switch (title) {
      case 'Addition': return _additionRowCount;
      case 'Loss': return _lossRowCount;
      case 'Water-based': return _waterRowCount;
      case 'Oil-based': return _oilRowCount;
      case 'Synthetic': return _syntheticRowCount;
      default: return 1;
    }
  }

  List<TextEditingController> _activityControllers = [];
  List<TextEditingController> _additionControllers = [];
  List<TextEditingController> _lossControllers = [];
  List<TextEditingController> _waterControllers = [];
  List<TextEditingController> _oilControllers = [];
  List<TextEditingController> _syntheticControllers = [];

  List<TextEditingController> get activity => _activityControllers;
  List<TextEditingController> get addition => _additionControllers;
  List<TextEditingController> get loss => _lossControllers;
  List<TextEditingController> get water => _waterControllers;
  List<TextEditingController> get oil => _oilControllers;
  List<TextEditingController> get synthetic => _syntheticControllers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchAllData();
  }

  void _initializeControllers() {
    _activityControllers = _genSingleCol(_activityRowCount);
    _additionControllers = _genSingleCol(_additionRowCount);
    _lossControllers = _genSingleCol(_lossRowCount);
    _waterControllers = _genSingleCol(_waterRowCount);
    _oilControllers = _genSingleCol(_oilRowCount);
    _syntheticControllers = _genSingleCol(_syntheticRowCount);

    _addListenersToControllers(_activityControllers, 'Activity');
    _addListenersToControllers(_additionControllers, 'Addition');
    _addListenersToControllers(_lossControllers, 'Loss');
    _addListenersToControllers(_waterControllers, 'Water-based');
    _addListenersToControllers(_oilControllers, 'Oil-based');
    _addListenersToControllers(_syntheticControllers, 'Synthetic');
  }

  void _addListenersToControllers(List<TextEditingController> controllers, String tableType) {
    for (int i = 0; i < controllers.length; i++) {
      controllers[i].addListener(() {
        if (controllers[i].text.trim().isNotEmpty && i == controllers.length - 1) {
          _addNewRow(tableType);
        }
      });
    }
  }

  void _addNewRow(String tableType) {
    setState(() {
      switch (tableType) {
        case 'Activity':
          _activityRowCount++;
          _activityControllers.add(TextEditingController());
          _activityControllers.last.addListener(() {
            if (_activityControllers.last.text.trim().isNotEmpty) {
              _addNewRow('Activity');
            }
          });
          break;
        case 'Addition':
          _additionRowCount++;
          _additionControllers.add(TextEditingController());
          _additionControllers.last.addListener(() {
            if (_additionControllers.last.text.trim().isNotEmpty) {
              _addNewRow('Addition');
            }
          });
          break;
        case 'Loss':
          _lossRowCount++;
          _lossControllers.add(TextEditingController());
          _lossControllers.last.addListener(() {
            if (_lossControllers.last.text.trim().isNotEmpty) {
              _addNewRow('Loss');
            }
          });
          break;
        case 'Water-based':
          _waterRowCount++;
          _waterControllers.add(TextEditingController());
          _waterControllers.last.addListener(() {
            if (_waterControllers.last.text.trim().isNotEmpty) {
              _addNewRow('Water-based');
            }
          });
          break;
        case 'Oil-based':
          _oilRowCount++;
          _oilControllers.add(TextEditingController());
          _oilControllers.last.addListener(() {
            if (_oilControllers.last.text.trim().isNotEmpty) {
              _addNewRow('Oil-based');
            }
          });
          break;
        case 'Synthetic':
          _syntheticRowCount++;
          _syntheticControllers.add(TextEditingController());
          _syntheticControllers.last.addListener(() {
            if (_syntheticControllers.last.text.trim().isNotEmpty) {
              _addNewRow('Synthetic');
            }
          });
          break;
      }
    });
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _controller.getActivities(),
        _controller.getAdditions(),
        _controller.getLosses(),
        _controller.getWaterBased(),
        _controller.getOilBased(),
        _controller.getSynthetic(),
      ]);

      setState(() {
        _loadedActivities = results[0] as List<ActivityItem>;
        _loadedAdditions = results[1] as List<AdditionItem>;
        _loadedLosses = results[2] as List<LossItem>;
        _loadedWaterBased = results[3] as List<WaterBasedItem>;
        _loadedOilBased = results[4] as List<OilBasedItem>;
        _loadedSynthetic = results[5] as List<SyntheticItem>;

        _activityRowCount = _loadedActivities.length + 1;
        _additionRowCount = _loadedAdditions.length + 1;
        _lossRowCount = _loadedLosses.length + 1;
        _waterRowCount = _loadedWaterBased.length + 1;
        _oilRowCount = _loadedOilBased.length + 1;
        _syntheticRowCount = _loadedSynthetic.length + 1;

        _initializeControllers();

        _lockedActivityRows.clear();
        _lockedAdditionRows.clear();
        _lockedLossRows.clear();
        _lockedWaterRows.clear();
        _lockedOilRows.clear();
        _lockedSyntheticRows.clear();

        for (int i = 0; i < _loadedActivities.length; i++) {
          _activityControllers[i].text = _loadedActivities[i].description;
          _lockedActivityRows.add(i);
        }
        for (int i = 0; i < _loadedAdditions.length; i++) {
          _additionControllers[i].text = _loadedAdditions[i].name;
          _lockedAdditionRows.add(i);
        }
        for (int i = 0; i < _loadedLosses.length; i++) {
          _lossControllers[i].text = _loadedLosses[i].name;
          _lockedLossRows.add(i);
        }
        for (int i = 0; i < _loadedWaterBased.length; i++) {
          _waterControllers[i].text = _loadedWaterBased[i].name;
          _lockedWaterRows.add(i);
        }
        for (int i = 0; i < _loadedOilBased.length; i++) {
          _oilControllers[i].text = _loadedOilBased[i].name;
          _lockedOilRows.add(i);
        }
        for (int i = 0; i < _loadedSynthetic.length; i++) {
          _syntheticControllers[i].text = _loadedSynthetic[i].name;
          _lockedSyntheticRows.add(i);
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load data: $e');
    }
  }

  void _showAlert(String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  backgroundColor == const Color(0xff10B981) ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  void _showSuccess(String message) => _showAlert(message, const Color(0xff10B981));
  void _showError(String message) => _showAlert(message, const Color(0xffEF4444));

  @override
  void dispose() {
    for (var controller in [...activity, ...addition, ...loss, ...water, ...oil, ...synthetic]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _twoColTable(title: 'Activity', controllers: activity, width: 350),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _singleColTable(title: 'Addition', controllers: addition),
                          const SizedBox(width: 12),
                          _singleColTable(title: 'Loss', controllers: loss),
                          const SizedBox(width: 12),
                          _singleColTable(title: 'Water-based', controllers: water),
                          const SizedBox(width: 12),
                          _singleColTable(title: 'Oil-based', controllers: oil),
                          const SizedBox(width: 12),
                          _singleColTable(title: 'Synthetic', controllers: synthetic),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _footerButtons(),
          ],
        ),
      ),
    );
  }

  Widget _twoColTable({required String title, required List<TextEditingController> controllers, required double width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionHeader(title, Icons.list_alt, AppTheme.primaryGradient),
          _headerRowFlexible(['#', 'Description', 'Actions'], [50.0, null, 80.0]),
          Expanded(child: _rows2ColFlexible(controllers)),
          _tableSaveButton(title),
        ],
      ),
    );
  }

  Widget _rows2ColFlexible(List<TextEditingController> controllers) {
    final scrollController = ScrollController();
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        itemCount: _activityRowCount,
        itemBuilder: (_, row) {
          final isLocked = _lockedActivityRows.contains(row);
          final item = isLocked && row < _loadedActivities.length ? _loadedActivities[row] : null;
          return Container(
            height: 32,
            decoration: BoxDecoration(
              color: row % 2 == 0 ? Colors.white : AppTheme.cardColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  _numCell(row),
                  Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                  Expanded(child: _editCellFlexible(controllers[row], isLocked: isLocked)),
                  Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                  _actionCell(isLocked, item, 'Activity'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rowsSingleColFlexible(List<TextEditingController> controllers, int rowCount, String tableTitle) {
    final scrollController = ScrollController();
    Set<int> lockedRows = _getLockedRowsForTable(tableTitle);
    List<dynamic> loadedItems = _getLoadedItemsForTable(tableTitle);

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        itemCount: rowCount,
        itemBuilder: (_, row) {
          final isLocked = lockedRows.contains(row);
          final item = isLocked && row < loadedItems.length ? loadedItems[row] : null;
          return Container(
            height: 32,
            decoration: BoxDecoration(
              color: row % 2 == 0 ? Colors.white : AppTheme.cardColor,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  _numCell(row),
                  Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                  Expanded(child: _editCellFlexible(controllers[row], isLocked: isLocked)),
                  Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                  _actionCell(isLocked, item, tableTitle),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _singleColTable({required String title, required List<TextEditingController> controllers}) {
    final gradients = [
      AppTheme.secondaryGradient,
      AppTheme.accentGradient,
      AppTheme.headerGradient,
      LinearGradient(colors: [Color(0xffFFB347), Color(0xffFFCC33)]),
      LinearGradient(colors: [Color(0xffDA70D6), Color(0xff9370DB)]),
      LinearGradient(colors: [Color(0xff20B2AA), Color(0xff40E0D0)]),
    ];

    final icons = [Icons.add_circle, Icons.remove_circle, Icons.water_drop, Icons.local_gas_station, Icons.science];
    final iconIndex = ['Addition', 'Loss', 'Water-based', 'Oil-based', 'Synthetic'].indexOf(title);

    final tableWidth = 250.0;

    return Container(
      width: tableWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionHeader(
            title,
            iconIndex >= 0 ? icons[iconIndex] : Icons.category,
            iconIndex >= 0 ? gradients[iconIndex] : AppTheme.primaryGradient,
          ),
          _headerRowFlexible(['#', title, 'Actions'], [50.0, null, 80.0]),
          Expanded(child: _rowsSingleColFlexible(controllers, _getRowCountForTable(title), title)),
          _tableSaveButton(title),
        ],
      ),
    );
  }

  Widget _tableSaveButton(String tableTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ElevatedButton(
        onPressed: () => _saveTableData(tableTitle),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 1,
        ),
        child: const Text('Save', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Widget _rowsSingleCol(List<TextEditingController> controllers, double secondColWidth, int rowCount, String tableTitle) {
    final scrollController = ScrollController();
    Set<int> lockedRows = _getLockedRowsForTable(tableTitle);
    List<dynamic> loadedItems = _getLoadedItemsForTable(tableTitle);

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        itemCount: rowCount,
        itemBuilder: (_, row) {
          final isLocked = lockedRows.contains(row);
          final item = isLocked && row < loadedItems.length ? loadedItems[row] : null;
          return Container(
            height: 32,
            decoration: BoxDecoration(
              color: row % 2 == 0 ? Colors.white : AppTheme.cardColor,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                children: [
                  _numCell(row),
                  Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                  _editCell(secondColWidth, controllers[row], isLocked: isLocked),
                  Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                  _actionCell(isLocked, item, tableTitle),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Set<int> _getLockedRowsForTable(String title) {
    switch (title) {
      case 'Activity': return _lockedActivityRows;
      case 'Addition': return _lockedAdditionRows;
      case 'Loss': return _lockedLossRows;
      case 'Water-based': return _lockedWaterRows;
      case 'Oil-based': return _lockedOilRows;
      case 'Synthetic': return _lockedSyntheticRows;
      default: return {};
    }
  }

  List<dynamic> _getLoadedItemsForTable(String title) {
    switch (title) {
      case 'Activity': return _loadedActivities;
      case 'Addition': return _loadedAdditions;
      case 'Loss': return _loadedLosses;
      case 'Water-based': return _loadedWaterBased;
      case 'Oil-based': return _loadedOilBased;
      case 'Synthetic': return _loadedSynthetic;
      default: return [];
    }
  }

  Widget _sectionHeader(String text, IconData icon, Gradient gradient) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow(List<String> labels, List<double> widths) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.tableHeadColor.withOpacity(0.9), AppTheme.tableHeadColor.withOpacity(0.8)],
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isLast = i == labels.length - 1;
          return Container(
            width: widths[i],
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border(
                right: isLast ? BorderSide.none : BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              ),
            ),
            child: Center(
              child: Text(
                labels[i],
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _headerRowFlexible(List<String> labels, List<double?> widths) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.tableHeadColor.withOpacity(0.9), AppTheme.tableHeadColor.withOpacity(0.8)],
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            if (widths[i] != null)
              Container(
                width: widths[i]!,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  border: Border(
                    right: i == labels.length - 1 ? BorderSide.none : BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      right: i == labels.length - 1 ? BorderSide.none : BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _numCell(int row) {
    return SizedBox(
      width: 50,
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.secondaryGradient),
          child: Center(
            child: Text('${row + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _editCell(double width, TextEditingController controller, {bool isLocked = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        readOnly: isLocked,
        style: TextStyle(fontSize: 12, color: isLocked ? Colors.grey : AppTheme.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
          filled: isLocked,
          fillColor: isLocked ? Colors.grey.shade100 : Colors.transparent,
        ),
      ),
    );
  }

  Widget _editCellFlexible(TextEditingController controller, {bool isLocked = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        readOnly: isLocked,
        style: TextStyle(fontSize: 12, color: isLocked ? Colors.grey : AppTheme.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
          filled: isLocked,
          fillColor: isLocked ? Colors.grey.shade100 : Colors.transparent,
        ),
      ),
    );
  }

  Widget _actionCell(bool isLocked, dynamic item, String tableType) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: isLocked
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _showUpdateDialog(item, tableType),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.edit, size: 14, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _deleteItem(item, tableType),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.delete, size: 14, color: AppTheme.errorColor),
                  ),
                ),
              ],
            )
          : SizedBox(),
    );
  }

 // In OthersPage, update the _footerButtons widget:
Widget _footerButtons() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    margin: const EdgeInsets.only(top: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () => Get.to(() => const DefaultMudPropertiesPage()), // Remove data passing
          icon: const Icon(Icons.settings, size: 16),
          label: const Text('Mud Properties'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
        ),
      ],
    ),
  );
}

  Future<void> _showUpdateDialog(dynamic item, String tableType) async {
    final controller = TextEditingController(
      text: tableType == 'Activity' ? (item as ActivityItem).description : (item as dynamic).name,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update $tableType'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: tableType == 'Activity' ? 'Description' : 'Name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateItem(item, controller.text.trim(), tableType);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateItem(dynamic item, String newValue, String tableType) async {
    if (newValue.isEmpty) {
      _showError('Value cannot be empty');
      return;
    }

    Map<String, dynamic> result;
    switch (tableType) {
      case 'Activity':
        result = await _controller.updateActivity(
          (item as ActivityItem).id!,
          ActivityItem(id: item.id, description: newValue),
        );
        break;
      case 'Addition':
        result = await _controller.updateAddition(
          (item as AdditionItem).id!,
          AdditionItem(id: item.id, name: newValue),
        );
        break;
      case 'Loss':
        result = await _controller.updateLoss(
          (item as LossItem).id!,
          LossItem(id: item.id, name: newValue),
        );
        break;
      case 'Water-based':
        result = await _controller.updateWaterBased(
          (item as WaterBasedItem).id!,
          WaterBasedItem(id: item.id, name: newValue),
        );
        break;
      case 'Oil-based':
        result = await _controller.updateOilBased(
          (item as OilBasedItem).id!,
          OilBasedItem(id: item.id, name: newValue),
        );
        break;
      case 'Synthetic':
        result = await _controller.updateSynthetic(
          (item as SyntheticItem).id!,
          SyntheticItem(id: item.id, name: newValue),
        );
        break;
      default:
        return;
    }

    if (result['success'] == true) {
      _showSuccess(result['message'] ?? '$tableType updated successfully');
      await _fetchAllData();
    } else {
      _showError(result['message'] ?? 'Failed to update $tableType');
    }
  }

  Future<void> _deleteItem(dynamic item, String tableType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this $tableType?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    Map<String, dynamic> result;
    switch (tableType) {
      case 'Activity':
        result = await _controller.deleteActivity((item as ActivityItem).id!);
        break;
      case 'Addition':
        result = await _controller.deleteAddition((item as AdditionItem).id!);
        break;
      case 'Loss':
        result = await _controller.deleteLoss((item as LossItem).id!);
        break;
      case 'Water-based':
        result = await _controller.deleteWaterBased((item as WaterBasedItem).id!);
        break;
      case 'Oil-based':
        result = await _controller.deleteOilBased((item as OilBasedItem).id!);
        break;
      case 'Synthetic':
        result = await _controller.deleteSynthetic((item as SyntheticItem).id!);
        break;
      default:
        return;
    }

    if (result['success'] == true) {
      _showSuccess(result['message'] ?? '$tableType deleted successfully');
      await _fetchAllData();
    } else {
      _showError(result['message'] ?? 'Failed to delete $tableType');
    }
  }

  Future<void> _saveTableData(String tableTitle) async {
    try {
      List<String> newData = [];
      List<TextEditingController> controllers = [];
      Set<int> lockedRows = {};

      switch (tableTitle) {
        case 'Activity':
          controllers = _activityControllers;
          lockedRows = _lockedActivityRows;
          break;
        case 'Addition':
          controllers = _additionControllers;
          lockedRows = _lockedAdditionRows;
          break;
        case 'Loss':
          controllers = _lossControllers;
          lockedRows = _lockedLossRows;
          break;
        case 'Water-based':
          controllers = _waterControllers;
          lockedRows = _lockedWaterRows;
          break;
        case 'Oil-based':
          controllers = _oilControllers;
          lockedRows = _lockedOilRows;
          break;
        case 'Synthetic':
          controllers = _syntheticControllers;
          lockedRows = _lockedSyntheticRows;
          break;
      }

      for (int i = 0; i < controllers.length; i++) {
        if (!lockedRows.contains(i) && controllers[i].text.trim().isNotEmpty) {
          newData.add(controllers[i].text.trim());
        }
      }

      if (newData.isEmpty) {
        _showError('No new data to save');
        return;
      }

      Map<String, dynamic> result;
      if (newData.length == 1) {
        switch (tableTitle) {
          case 'Activity':
            result = await _controller.addActivities([ActivityItem(description: newData[0])]);
            break;
          case 'Addition':
            result = await _controller.addAdditions([AdditionItem(name: newData[0])]);
            break;
          case 'Loss':
            result = await _controller.addLosses([LossItem(name: newData[0])]);
            break;
          case 'Water-based':
            result = await _controller.addWaterBased([WaterBasedItem(name: newData[0])]);
            break;
          case 'Oil-based':
            result = await _controller.addOilBased([OilBasedItem(name: newData[0])]);
            break;
          case 'Synthetic':
            result = await _controller.addSynthetic([SyntheticItem(name: newData[0])]);
            break;
          default:
            return;
        }
      } else {
        switch (tableTitle) {
          case 'Activity':
            result = await _controller.addActivities(newData.map((e) => ActivityItem(description: e)).toList());
            break;
          case 'Addition':
            result = await _controller.addAdditions(newData.map((e) => AdditionItem(name: e)).toList());
            break;
          case 'Loss':
            result = await _controller.addLosses(newData.map((e) => LossItem(name: e)).toList());
            break;
          case 'Water-based':
            result = await _controller.addWaterBased(newData.map((e) => WaterBasedItem(name: e)).toList());
            break;
          case 'Oil-based':
            result = await _controller.addOilBased(newData.map((e) => OilBasedItem(name: e)).toList());
            break;
          case 'Synthetic':
            result = await _controller.addSynthetic(newData.map((e) => SyntheticItem(name: e)).toList());
            break;
          default:
            return;
        }
      }

      if (result['success'] == true) {
        for (int i = 0; i < controllers.length; i++) {
          if (!lockedRows.contains(i) && controllers[i].text.trim().isNotEmpty) {
            switch (tableTitle) {
              case 'Activity':
                _lockedActivityRows.add(i);
                break;
              case 'Addition':
                _lockedAdditionRows.add(i);
                break;
              case 'Loss':
                _lockedLossRows.add(i);
                break;
              case 'Water-based':
                _lockedWaterRows.add(i);
                break;
              case 'Oil-based':
                _lockedOilRows.add(i);
                break;
              case 'Synthetic':
                _lockedSyntheticRows.add(i);
                break;
            }
          }
        }

        _showSuccess(result['message'] ?? 'Data saved successfully');
        await _fetchAllData();
      } else {
        _showError(result['message'] ?? 'Failed to save data');
      }
    } catch (e) {
      _showError('Error saving data: $e');
    }
  }
}