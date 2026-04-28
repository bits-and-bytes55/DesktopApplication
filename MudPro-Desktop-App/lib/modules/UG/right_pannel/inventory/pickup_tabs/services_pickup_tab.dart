import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/inventory_store/inventory_store.dart';

class ServicesPickupPage extends StatefulWidget {
  const ServicesPickupPage({super.key});

  @override
  State<ServicesPickupPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPickupPage> {
  final ServiceController controller = ServiceController();
  bool _isLoading = false;

  final Set<String> existingPackageIds = {};
  final Set<String> existingServiceIds = {};
  final Set<String> existingEngineeringIds = {};

  // Selection tracking
  final Set<int> selectedPackageIndices = {};
  final Set<int> selectedServiceIndices = {};
  final Set<int> selectedEngineeringIndices = {};

  List<PackageItem> existingPackages = [];
  List<ServiceItem> existingServices = [];
  List<EngineeringItem> existingEngineering = [];

  final List<List<TextEditingController>> packageControllers =
      _generateControllers();
  final List<List<TextEditingController>> servicesControllers =
      _generateControllers();
  final List<List<TextEditingController>> engineeringControllers =
      _generateControllers();

  static List<List<TextEditingController>> _generateControllers() {
    return List.generate(
      5,
      (_) => List.generate(4, (_) => TextEditingController()),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadPackages(), _loadServices(), _loadEngineering()]);
    } catch (e) {
      _showError('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPackages() async {
    try {
      existingPackages = await controller.getPackages();
      existingPackageIds.clear();
      for (var pkg in existingPackages) {
        if (pkg.id != null) existingPackageIds.add(pkg.id!);
      }
      setState(() {});
    } catch (e) {
      print('Error loading packages: $e');
    }
  }

  Future<void> _loadServices() async {
    try {
      existingServices = await controller.getServices();
      existingServiceIds.clear();
      for (var srv in existingServices) {
        if (srv.id != null) existingServiceIds.add(srv.id!);
      }
      setState(() {});
    } catch (e) {
      print('Error loading services: $e');
    }
  }

  Future<void> _loadEngineering() async {
    try {
      existingEngineering = await controller.getEngineering();
      existingEngineeringIds.clear();
      for (var eng in existingEngineering) {
        if (eng.id != null) existingEngineeringIds.add(eng.id!);
      }
      setState(() {});
    } catch (e) {
      print('Error loading engineering: $e');
    }
  }

  void _applySelectedServices() {
    final selectedPkgs = selectedPackageIndices
        .map((i) => existingPackages[i])
        .toList();
    final selectedSrvs = selectedServiceIndices
        .map((i) => existingServices[i])
        .toList();
    final selectedEngs = selectedEngineeringIndices
        .map((i) => existingEngineering[i])
        .toList();

    Get.find<InventoryServicesStore>().setSelectedServices(
      packages: selectedPkgs,
      services: selectedSrvs,
      engineering: selectedEngs,
    );

    Navigator.pop(context);
    Get.snackbar(
      'Success',
      '${selectedPkgs.length + selectedSrvs.length + selectedEngs.length} items applied to inventory',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Color(0xff10B981),
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
  }

  Future<void> _savePackages() async {
    setState(() => _isLoading = true);
    try {
      List<PackageItem> newPackages = [];
      for (var row in packageControllers) {
        if (row[0].text.trim().isNotEmpty) {
          newPackages.add(
            PackageItem(
              name: row[0].text.trim(),
              code: row[1].text.trim(),
              unit: row[2].text.trim(),
              price: double.tryParse(row[3].text) ?? 0.0,
            ),
          );
        }
      }

      if (newPackages.isEmpty) {
        _showError('Please add at least one new package');
        setState(() => _isLoading = false);
        return;
      }

      final result = await controller.addPackages(newPackages);

      if (result['success'] == true) {
        _showSuccess(result['message'] ?? 'Packages saved successfully!');

        for (var row in packageControllers) {
          for (var ctrl in row) {
            ctrl.clear();
          }
        }

        await _loadPackages();
      } else {
        _showError(result['message'] ?? 'Failed to save packages');
      }
    } catch (e) {
      _showError('Failed to save packages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveServices() async {
    setState(() => _isLoading = true);
    try {
      List<ServiceItem> newServices = [];
      for (var row in servicesControllers) {
        if (row[0].text.trim().isNotEmpty) {
          newServices.add(
            ServiceItem(
              name: row[0].text.trim(),
              code: row[1].text.trim(),
              unit: row[2].text.trim(),
              price: double.tryParse(row[3].text) ?? 0.0,
            ),
          );
        }
      }

      if (newServices.isEmpty) {
        _showError('Please add at least one new service');
        setState(() => _isLoading = false);
        return;
      }

      final result = await controller.addServices(newServices);

      if (result['success'] == true) {
        _showSuccess(result['message'] ?? 'Services saved successfully!');

        for (var row in servicesControllers) {
          for (var ctrl in row) {
            ctrl.clear();
          }
        }

        await _loadServices();
      } else {
        _showError(result['message'] ?? 'Failed to save services');
      }
    } catch (e) {
      _showError('Failed to save services: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEngineering() async {
    setState(() => _isLoading = true);
    try {
      List<EngineeringItem> newEngineering = [];
      for (var row in engineeringControllers) {
        if (row[0].text.trim().isNotEmpty) {
          newEngineering.add(
            EngineeringItem(
              name: row[0].text.trim(),
              code: row[1].text.trim(),
              unit: row[2].text.trim(),
              price: double.tryParse(row[3].text) ?? 0.0,
            ),
          );
        }
      }

      if (newEngineering.isEmpty) {
        _showError('Please add at least one new engineering item');
        setState(() => _isLoading = false);
        return;
      }

      final result = await controller.addEngineering(newEngineering);

      if (result['success'] == true) {
        _showSuccess(
          result['message'] ?? 'Engineering items saved successfully!',
        );

        for (var row in engineeringControllers) {
          for (var ctrl in row) {
            ctrl.clear();
          }
        }

        await _loadEngineering();
      } else {
        _showError(result['message'] ?? 'Failed to save engineering');
      }
    } catch (e) {
      _showError('Failed to save engineering: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    _showAlert(message, const Color(0xff10B981));
  }

  void _showError(String message) {
    _showAlert(message, const Color(0xffEF4444));
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
                  backgroundColor == const Color(0xff10B981)
                      ? Icons.check_circle
                      : Icons.error,
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
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }

  @override
  void dispose() {
    for (var table in [
      packageControllers,
      servicesControllers,
      engineeringControllers,
    ]) {
      for (var row in table) {
        for (var ctrl in row) {
          ctrl.dispose();
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final sectionWidth = constraints.maxWidth < 1180
                          ? 360.0
                          : (constraints.maxWidth - 16) / 3;
                      return Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildTableSections(sectionWidth),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _footerButtons(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildTableSections(double sectionWidth) {
    return [
      SizedBox(
        width: sectionWidth,
        child: _tableSection(
          title: 'Package',
          existingData: existingPackages,
          controllers: packageControllers,
          onSave: _savePackages,
          selectedIndices: selectedPackageIndices,
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: sectionWidth,
        child: _tableSection(
          title: 'Services',
          existingData: existingServices,
          controllers: servicesControllers,
          onSave: _saveServices,
          selectedIndices: selectedServiceIndices,
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: sectionWidth,
        child: _tableSection(
          title: 'Engineering',
          existingData: existingEngineering,
          controllers: engineeringControllers,
          onSave: _saveEngineering,
          selectedIndices: selectedEngineeringIndices,
        ),
      ),
    ];
  }

  Widget _tableSection({
    required String title,
    required List<dynamic> existingData,
    required List<List<TextEditingController>> controllers,
    required VoidCallback onSave,
    required Set<int> selectedIndices,
  }) {
    const widths = [30.0, 138.0, 72.0, 64.0, 78.0];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC7CBD2)),
      ),
      child: Column(
        children: [
          _sectionHeader(title, selectedIndices.length),
          _tableHeader(widths),
          Container(height: 1, color: const Color(0xFFC7CBD2)),
          Expanded(
            child: _tableRows(
              existingData,
              controllers,
              widths,
              selectedIndices,
            ),
          ),
          _tableSaveButton(onSave, title),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int selectedCount) {
    return Container(
      height: 28,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2F2F2F),
              ),
            ),
          ),
          if (selectedCount > 0)
            Text(
              '$selectedCount selected',
              style: const TextStyle(fontSize: 10, color: Color(0xFF5F6B7A)),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<double> widths) {
    return Container(
      height: 30,
      color: const Color(0xFFF3F3F3),
      child: Row(
        children: [
          _HeaderCell(width: widths[0], text: ''),
          _HeaderCell(width: widths[1], text: 'Name'),
          _HeaderCell(width: widths[2], text: 'Code'),
          _HeaderCell(width: widths[3], text: 'Unit'),
          Expanded(child: _HeaderCell(text: 'Price (\$)')),
        ],
      ),
    );
  }

  Widget _tableRows(
    List<dynamic> existingData,
    List<List<TextEditingController>> controllers,
    List<double> widths,
    Set<int> selectedIndices,
  ) {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        itemCount: existingData.length + controllers.length,
        itemBuilder: (_, index) {
          final isExisting = index < existingData.length;
          final isSelected = selectedIndices.contains(index);

          return InkWell(
            onTap: isExisting
                ? () {
                    setState(() {
                      if (selectedIndices.contains(index)) {
                        selectedIndices.remove(index);
                      } else {
                        selectedIndices.add(index);
                      }
                    });
                  }
                : null,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFDCE9F9)
                    : (isExisting ? Colors.white : const Color(0xFFFFF9CC)),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.6),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Row(
                  children: [
                    _numberCell(index + 1, widths[0], isExisting, isSelected),
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: Colors.grey.shade300,
                    ),
                    if (isExisting) ...[
                      _lockedCell(widths[1], existingData[index].name),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      _lockedCell(widths[2], existingData[index].code),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      _lockedCell(widths[3], existingData[index].unit),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      _lockedCell(
                        widths[4],
                        existingData[index].price.toString(),
                      ),
                    ] else ...[
                      _editCell(
                        widths[1],
                        controllers[index - existingData.length][0],
                      ),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      _editCell(
                        widths[2],
                        controllers[index - existingData.length][1],
                      ),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      _editCell(
                        widths[3],
                        controllers[index - existingData.length][2],
                      ),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      _editCell(
                        widths[4],
                        controllers[index - existingData.length][3],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _numberCell(int number, double width, bool isLocked, bool isSelected) {
    return SizedBox(
      width: width,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLocked)
              Icon(
                isSelected ? Icons.check_circle : Icons.chevron_right,
                size: 11,
                color: isSelected ? const Color(0xFF2E74C9) : Colors.grey,
              ),
            const SizedBox(width: 2),
            Text(
              '$number',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2E74C9)
                    : const Color(0xFF2F2F2F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockedCell(double width, String value) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF2F2F2F)),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _editCell(double width, TextEditingController controller) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF2F2F2F)),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 7),
        ),
      ),
    );
  }

  Widget _tableSaveButton(VoidCallback onSave, String title) {
    return Container(
      height: 42,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: OutlinedButton(
          onPressed: _isLoading ? null : onSave,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E74C9),
            side: const BorderSide(color: Color(0xFF9BBBEA)),
            shape: const RoundedRectangleBorder(),
          ),
          child: Text(
            'Save $title',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _footerButtons() {
    final totalSelected =
        selectedPackageIndices.length +
        selectedServiceIndices.length +
        selectedEngineeringIndices.length;

    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC7CBD2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (totalSelected > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Selected: $totalSelected',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2E74C9),
                ),
              ),
            ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC7CBD2)),
              foregroundColor: const Color(0xFF2F2F2F),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text('Close'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: totalSelected == 0 ? null : _applySelectedServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E74C9),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final double? width;
  final String text;

  const _HeaderCell({this.width, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2F2F2F),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
