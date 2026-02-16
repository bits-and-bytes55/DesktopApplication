import 'package:flutter/material.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/service_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
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

  final List<List<TextEditingController>> packageControllers = _generateControllers();
  final List<List<TextEditingController>> servicesControllers = _generateControllers();
  final List<List<TextEditingController>> engineeringControllers = _generateControllers();

  static List<List<TextEditingController>> _generateControllers() {
    return List.generate(5, (_) => List.generate(4, (_) => TextEditingController()));
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadPackages(),
        _loadServices(),
        _loadEngineering(),
      ]);
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
    final selectedPkgs = selectedPackageIndices.map((i) => existingPackages[i]).toList();
    final selectedSrvs = selectedServiceIndices.map((i) => existingServices[i]).toList();
    final selectedEngs = selectedEngineeringIndices.map((i) => existingEngineering[i]).toList();

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
          newPackages.add(PackageItem(
            name: row[0].text.trim(),
            code: row[1].text.trim(),
            unit: row[2].text.trim(),
            price: double.tryParse(row[3].text) ?? 0.0,
          ));
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
          newServices.add(ServiceItem(
            name: row[0].text.trim(),
            code: row[1].text.trim(),
            unit: row[2].text.trim(),
            price: double.tryParse(row[3].text) ?? 0.0,
          ));
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
          newEngineering.add(EngineeringItem(
            name: row[0].text.trim(),
            code: row[1].text.trim(),
            unit: row[2].text.trim(),
            price: double.tryParse(row[3].text) ?? 0.0,
          ));
        }
      }

      if (newEngineering.isEmpty) {
        _showError('Please add at least one new engineering item');
        setState(() => _isLoading = false);
        return;
      }

      final result = await controller.addEngineering(newEngineering);
      
      if (result['success'] == true) {
        _showSuccess(result['message'] ?? 'Engineering items saved successfully!');
        
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
    for (var table in [packageControllers, servicesControllers, engineeringControllers]) {
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 1200) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildTableSections(constraints),
                          ),
                        );
                      } else {
                        return Row(
                          children: _buildTableSections(constraints),
                        );
                      }
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

  List<Widget> _buildTableSections(BoxConstraints constraints) {
    return [
      _tableSection(
        title: 'Package',
        existingData: existingPackages,
        controllers: packageControllers,
        icon: Icons.inventory,
        gradient: AppTheme.primaryGradient,
        constraints: constraints,
        onSave: _savePackages,
        selectedIndices: selectedPackageIndices,
        isPackage: true,
      ),
      const SizedBox(width: 12),
      _tableSection(
        title: 'Services',
        existingData: existingServices,
        controllers: servicesControllers,
        icon: Icons.miscellaneous_services,
        gradient: AppTheme.secondaryGradient,
        constraints: constraints,
        onSave: _saveServices,
        selectedIndices: selectedServiceIndices,
        isService: true,
      ),
      const SizedBox(width: 12),
      _tableSection(
        title: 'Engineering',
        existingData: existingEngineering,
        controllers: engineeringControllers,
        icon: Icons.engineering,
        gradient: AppTheme.accentGradient,
        constraints: constraints,
        onSave: _saveEngineering,
        selectedIndices: selectedEngineeringIndices,
        isEngineering: true,
      ),
    ];
  }

  Widget _tableSection({
    required String title,
    required List<dynamic> existingData,
    required List<List<TextEditingController>> controllers,
    required IconData icon,
    required Gradient gradient,
    required BoxConstraints constraints,
    required VoidCallback onSave,
    required Set<int> selectedIndices,
    bool isPackage = false,
    bool isService = false,
    bool isEngineering = false,
  }) {
    final isSmallScreen = constraints.maxWidth < 400;
    final widths = isSmallScreen
        ? [25.0, 100.0, 50.0, 40.0, 50.0]
        : [35.0, 150.0, 75.0, 65.0, 75.0];

    return Expanded(
      child: Container(
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
            _sectionHeader(title, icon, gradient, selectedIndices.length),
            _tableHeader(widths),
            Container(height: 1, color: Colors.grey.shade300),
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
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Gradient gradient, int selectedCount) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (selectedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Selected: $selectedCount',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(List<double> widths) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.tableHeadColor.withOpacity(0.9),
            AppTheme.tableHeadColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          _HeaderCell(width: widths[0], text: '', icon: Icons.numbers),
          _HeaderCell(width: widths[1], text: 'Name', icon: Icons.text_fields),
          _HeaderCell(width: widths[2], text: 'Code', icon: Icons.code),
          _HeaderCell(width: widths[3], text: 'Unit', icon: Icons.linear_scale),
          Expanded(child: _HeaderCell(text: 'Price (\$)', icon: Icons.attach_money)),
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
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : (isExisting
                        ? const Color(0xffF3F4F6)
                        : (index % 2 == 0 ? Colors.white : AppTheme.cardColor)),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Row(
                  children: [
                    _numberCell(index + 1, widths[0], isExisting, isSelected),
                    Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                    if (isExisting) ...[
                      _lockedCell(widths[1], existingData[index].name),
                      Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                      _lockedCell(widths[2], existingData[index].code),
                      Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                      _lockedCell(widths[3], existingData[index].unit),
                      Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                      _lockedCell(widths[4], existingData[index].price.toString()),
                    ] else ...[
                      _editCell(widths[1], controllers[index - existingData.length][0]),
                      Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                      _editCell(widths[2], controllers[index - existingData.length][1]),
                      Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                      _editCell(widths[3], controllers[index - existingData.length][2]),
                      Container(width: 1, height: double.infinity, color: Colors.grey.shade300),
                      _editCell(widths[4], controllers[index - existingData.length][3]),
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
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.lock,
                  size: 10,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : (isLocked
                        ? Colors.grey.withOpacity(0.3)
                        : AppTheme.secondaryColor.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  ),
                ),
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
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
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
        style: TextStyle(fontSize: 11, color: AppTheme.textPrimary),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _tableSaveButton(VoidCallback onSave, String title) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Save $title',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerButtons() {
    final totalSelected = selectedPackageIndices.length +
        selectedServiceIndices.length +
        selectedEngineeringIndices.length;

    return Container(
      height: 52,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (totalSelected > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Total Selected: $totalSelected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.errorColor),
              foregroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Close'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: totalSelected == 0 ? null : _applySelectedServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Apply Selected'),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final double? width;
  final String text;
  final IconData icon;

  const _HeaderCell({this.width, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
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


