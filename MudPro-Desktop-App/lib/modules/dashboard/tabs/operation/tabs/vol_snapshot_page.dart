import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// Controller
class VolumeSnapshotController extends GetxController {
  // Left Table - Active System Volume
  final startVol = '0.00'.obs;
  final receiveMud = ''.obs;
  final baseFluid = ''.obs;
  final weightMaterial = '56.42'.obs;
  final products = '32.29'.obs;
  final water = '1411.29'.obs;
  final formation = ''.obs;
  final cuttings = ''.obs;
  final cuttingsRetention = ''.obs;
  final seepage = ''.obs;
  final dump = ''.obs;
  final shakers = '15.00'.obs;
  final centrifuge = ''.obs;
  final evaporation = ''.obs;
  final pitCleaning = '15.00'.obs;
  final formationLoss = ''.obs;
  final abandonInHole = ''.obs;
  final leftBehindCasing = ''.obs;
  final tripping = ''.obs;
  final fromStorage = ''.obs;
  final toStorage = '1,000.00'.obs;
  final returnVol = ''.obs;
  final endVol = '385.00'.obs;
  final endVolActiveSystem = '0.00'.obs;
  final additionTotal = '1500.00'.obs;
  final lossTotal = '-1,100.00'.obs;

  // Right Top Table - Storage Loss
  final storageDump = ''.obs;
  final storageEvaporation = ''.obs;
  final storagePitCleaning = ''.obs;
  final premixedMud = ''.obs;
  final leasedMudReceived = ''.obs;
  final leasedMudReturned = ''.obs;
  final nonLeasedMudReceived = ''.obs;
  final nonLeasedMudReturned = ''.obs;
  final cumLeased = ''.obs;
  final volumeSummary = ''.obs;

  // Right Middle Table - Hole Vol. Difference
  final hole = '61.23'.obs;
  final activePits = '323.78'.obs;
  final activeSystem = '385.00'.obs;
  final totalStorage = '1,108.00'.obs;
  final totalOnLocation = '1,431.00'.obs;
  final cumLeasedHole = '0.00'.obs;
  final volumeDifference = '1,465.00'.obs;
  final totalOnLocationCumLeased = ''.obs;

  // Volume badges
  final vol840 = '(840)'.obs;
  final vol840Storage = '(840)'.obs;
  final vol840Difference = '(840)'.obs;
}

// Main Page
class VolumeSnapshotPage extends GetView<VolumeSnapshotController> {
  const VolumeSnapshotPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(VolumeSnapshotController());

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        title: const Text(
          'Volume Snapshot',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Table
                Expanded(
                  flex: 1,
                  child: _buildLeftTable(constraints.maxHeight - 24),
                ),
                const SizedBox(width: 12),
                // Right Tables
                Expanded(
                  flex: 1,
                  child: _buildRightTables(constraints.maxHeight - 24),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftTable(double availableHeight) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F3),
        border: Border.all(color: const Color(0xFFB8B8B8), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFB8B8B8), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Active System Volume',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Obx(() => Text(
                  'Vol. ${controller.vol840.value}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                )),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildLeftRow('Start Vol.', controller.startVol, hasValue: true),
                  _buildSectionHeader('Addition'),
                  _buildLeftRowWithSubItems([
                    _buildLeftRow('Receive Mud', controller.receiveMud, indent: 1),
                    _buildLeftRow('Base Fluid', controller.baseFluid, indent: 1),
                    _buildLeftRow('Weight Material', controller.weightMaterial, indent: 1, hasValue: true),
                    _buildLeftRow('Products', controller.products, indent: 1, hasValue: true),
                    _buildLeftRow('Water', controller.water, indent: 1, hasValue: true),
                    _buildLeftRow('Formation', controller.formation, indent: 1),
                    _buildLeftRow('Cuttings', controller.cuttings, indent: 1),
                    _buildLeftRow('Cuttings/Retention', controller.cuttingsRetention, indent: 1),
                    _buildLeftRow('Seepage', controller.seepage, indent: 1),
                  ], totalValue: controller.additionTotal),
                  _buildSectionHeader('Loss'),
                  _buildLeftRowWithSubItems([
                    _buildLeftRow('Dump', controller.dump, indent: 1),
                    _buildLeftRow('Shakers', controller.shakers, indent: 1, hasValue: true),
                    _buildLeftRow('Centrifuge', controller.centrifuge, indent: 1),
                    _buildLeftRow('Evaporation', controller.evaporation, indent: 1),
                    _buildLeftRow('Pit Cleaning', controller.pitCleaning, indent: 1, hasValue: true),
                    _buildLeftRow('Formation', controller.formationLoss, indent: 1),
                    _buildLeftRow('Abandon in Hole', controller.abandonInHole, indent: 1),
                    _buildLeftRow('Left behind Casing', controller.leftBehindCasing, indent: 1),
                    _buildLeftRow('Tripping', controller.tripping, indent: 1),
                  ], totalValue: controller.lossTotal),
                  _buildSectionHeader('Transfer'),
                  _buildLeftRowWithSubItems([
                    _buildLeftRow('From Storage', controller.fromStorage, indent: 1),
                    _buildLeftRow('To Storage', controller.toStorage, indent: 1, hasValue: true, isNegative: true),
                    _buildLeftRow('Return', controller.returnVol, indent: 1),
                  ]),
                  const Divider(height: 1, thickness: 1.5, color: Color(0xFFB8B8B8)),
                  _buildLeftRow('End Vol.', controller.endVol, hasValue: true, isBold: true),
                  _buildLeftRow('End Vol. - Active System', controller.endVolActiveSystem, hasValue: true, isBold: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFFE6E6FA),
        border: Border(
          top: BorderSide(color: Color(0xFFB8B8B8), width: 1),
          bottom: BorderSide(color: Color(0xFFB8B8B8), width: 1),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B0082),
        ),
      ),
    );
  }

  Widget _buildLeftRowWithSubItems(List<Widget> items, {RxString? totalValue}) {
    return Column(
      children: [
        ...items,
        if (totalValue != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFD0D0D0), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Spacer(),
                Obx(() => Text(
                  totalValue.value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.right,
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLeftRow(
    String label,
    RxString value, {
    int indent = 0,
    bool hasValue = false,
    bool isBold = false,
    bool isNegative = false,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 10 + (indent * 20.0),
        right: 10,
        top: 4,
        bottom: 4,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD0D0D0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Obx(() {
              return TextField(
                controller: TextEditingController(text: value.value)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: value.value.length),
                  ),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: hasValue || isBold ? FontWeight.w600 : FontWeight.normal,
                  color: isNegative ? Colors.red : const Color(0xFF333333),
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (newValue) => value.value = newValue,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRightTables(double availableHeight) {
    final tableHeight = (availableHeight - 24) / 3;
    
    return Column(
      children: [
        // Storage Loss Table
        SizedBox(
          height: tableHeight,
          child: _buildStorageLossTable(),
        ),
        const SizedBox(height: 12),
        // Hole Vol. Difference Table
        SizedBox(
          height: tableHeight,
          child: _buildHoleVolDifferenceTable(),
        ),
        const SizedBox(height: 12),
        // OK Button
        SizedBox(
          height: tableHeight,
          child: Align(
            alignment: Alignment.topRight,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0D0D0),
                foregroundColor: const Color(0xFF333333),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageLossTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F3),
        border: Border.all(color: const Color(0xFFB8B8B8), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFB8B8B8), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Storage Loss',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Obx(() => Text(
                  'Vol. ${controller.vol840Storage.value}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                )),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildRightRow('Dump', controller.storageDump),
                  _buildRightRow('Evaporation', controller.storageEvaporation),
                  _buildRightRow('Pit Cleaning', controller.storagePitCleaning),
                  _buildRightRow('Premixed Mud', controller.premixedMud),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFB8B8B8)),
                  _buildRightRow('Leased Mud Received', controller.leasedMudReceived),
                  _buildRightRow('Leased Mud Returned', controller.leasedMudReturned),
                  _buildRightRow('Non-leased Mud Received', controller.nonLeasedMudReceived),
                  _buildRightRow('Non-leased Mud Returned', controller.nonLeasedMudReturned),
                  _buildRightRow('Cum. Leased', controller.cumLeased),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFB8B8B8)),
                  _buildRightRow('Volume Summary', controller.volumeSummary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoleVolDifferenceTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F3),
        border: Border.all(color: const Color(0xFFB8B8B8), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFB8B8B8), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Hole Vol. Difference',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Obx(() => Text(
                  'Vol. ${controller.vol840Difference.value}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                )),
              ],
            ),
          ),
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildRightRow('Hole', controller.hole, hasValue: true),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFB8B8B8)),
                  _buildRightRow('Active Pits', controller.activePits, hasValue: true),
                  _buildRightRow('Active System', controller.activeSystem, hasValue: true),
                  _buildRightRow('Total Storage', controller.totalStorage, hasValue: true),
                  _buildRightRow('Total on Location', controller.totalOnLocation, hasValue: true),
                  _buildRightRow('Cum. Leased', controller.cumLeasedHole, hasValue: true),
                  _buildRightRow('Volume Difference*', controller.volumeDifference, hasValue: true),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFB8B8B8)),
                  _buildRightRow('Total on Location - Cum. Leased', controller.totalOnLocationCumLeased),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightRow(String label, RxString value, {bool hasValue = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD0D0D0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              return TextField(
                controller: TextEditingController(text: value.value)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: value.value.length),
                  ),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: const Color(0xFF333333),
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (newValue) => value.value = newValue,
              );
            }),
          ),
        ],
      ),
    );
  }
}

