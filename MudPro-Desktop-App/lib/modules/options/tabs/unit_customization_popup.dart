import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';

/// =======================================================
/// LOCAL ENUM (POPUP ONLY – NOT CONNECTED TO MAIN PAGE)
/// =======================================================
enum PopupUnitSystem { us, si }

/// =======================================================
/// CONTROLLER (POPUP SCOPE ONLY)
/// =======================================================
class UnitCustomizationController extends GetxController {
  /// Radio buttons (popup only)
  final selectedRadio = PopupUnitSystem.us.obs;

  /// Left table selection
  final selectedLeftIndex = 0.obs;

  /// Methods for left panel buttons
  void insertBefore() {
    // Implementation to insert before selected index
  }

  void insertAfter() {
    // Implementation to insert after selected index
  }

  void deleteSelected() {
    // Implementation to delete selected item
  }
}

/// =======================================================
/// POPUP DIALOG
/// =======================================================
class UnitSystemCustomizationPopup extends StatelessWidget {
  UnitSystemCustomizationPopup({super.key});

  final controller = Get.put(UnitCustomizationController());
  final mainController = Get.find<OptionsController>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
          maxHeight: 700,
          minWidth: 800,
          minHeight: 500,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                _header(),
                _radioRow(),
                 Divider(height: 1, color: Colors.grey.shade300),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return _mobileLayout();
                      } else {
                        return _desktopLayout();
                      }
                    },
                  ),
                ),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        _leftPanel(),
        Container(
          width: 1,
          color: Colors.grey.shade300,
          height: double.infinity,
        ),
        Expanded(child: _rightPanel()),
      ],
    );
  }

  Widget _mobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _leftPanel(),
          Container(
            height: 1,
            color: Colors.grey.shade300,
            width: double.infinity,
          ),
          SizedBox(
            height: 400,
            child: _rightPanel(),
          ),
        ],
      ),
    );
  }

  /// ===================================================
  /// HEADER
  /// ===================================================
  Widget _header() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              Icons.tune,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Unit System Customization',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(Get.context!).pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ===================================================
  /// RADIO ROW (ISOLATED)
  /// ===================================================
  Widget _radioRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardColor,
      child: Obx(() {
        return Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _buildRadioButton(PopupUnitSystem.us, 'US Oil Field'),
            _buildRadioButton(PopupUnitSystem.si, 'SI'),
          ],
        );
      }),
    );
  }

  Widget _buildRadioButton(PopupUnitSystem value, String label) {
    return InkWell(
      onTap: () => controller.selectedRadio.value = value,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: controller.selectedRadio.value == value
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            width: controller.selectedRadio.value == value ? 2 : 1,
          ),
          color: controller.selectedRadio.value == value
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          boxShadow: controller.selectedRadio.value == value
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: controller.selectedRadio.value == value
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                  width: controller.selectedRadio.value == value ? 6 : 2,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: controller.selectedRadio.value == value
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===================================================
  /// LEFT PANEL
  /// ===================================================
  Widget _leftPanel() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 280,
        minWidth: 200,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.secondaryColor.withOpacity(0.1),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.list,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Unit Systems',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() {
                      return Text(
                        '${mainController.unitSystems.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: Container(
                color: AppTheme.backgroundColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: mainController.unitSystems.length,
                  itemBuilder: (_, index) {
                    return Obx(() {
                      final isSelected =
                          controller.selectedLeftIndex.value == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                controller.selectedLeftIndex.value = index,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: isSelected
                                    ? null
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.secondaryColor
                                              .withOpacity(0.2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      mainController.unitSystems[index],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
            ),

            // Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _leftButton('Insert Before', Icons.add, controller.insertBefore)),
                      const SizedBox(width: 8),
                      Expanded(child: _leftButton('Insert After', Icons.add, controller.insertAfter)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _leftButton('Delete Selected', Icons.delete_outline, controller.deleteSelected,
                      isDanger: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftButton(String text, IconData icon, VoidCallback onTap,
      {bool isDanger = false}) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDanger
              ? AppTheme.errorColor
              : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: Icon(
          icon,
          size: 16,
        ),
        label: Text(
          text,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// ===================================================
  /// RIGHT PANEL
  /// ===================================================
  Widget _rightPanel() {
    return Column(
      children: [
        // Header
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: AppTheme.tableHeaderDecoration.gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Parameters',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: Text(
                  'Unit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table
        Expanded(
          child: Container(
            color: Colors.white,
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                itemCount: mainController.parameters.length,
                itemBuilder: (_, index) {
                  return Obx(() {
                    return Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: index % 2 == 0
                            ? Colors.white
                            : AppTheme.cardColor,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          hoverColor: AppTheme.primaryColor.withOpacity(0.05),
                          child: Row(
                            children: [
                              // Number
                              SizedBox(
                                width: 60,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.secondaryColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      mainController.parameters[index]['number']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Parameter Name
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    mainController.parameters[index]['name']!,
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                              // Unit Dropdown
                              SizedBox(
                                width: 180,
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: mainController.customUnits[index],
                                        icon: Icon(
                                          Icons.arrow_drop_down,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                        menuMaxHeight: 300,
                                        dropdownColor: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        onChanged: (v) =>
                                            mainController.customUnits[index] = v!,
                                        items: mainController.allUnits
                                            .map(
                                              (u) => DropdownMenuItem(
                                                value: u,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 28,
                                                        height: 28,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: AppTheme
                                                              .primaryColor
                                                              .withOpacity(0.1),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            u.substring(0, 1),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppTheme
                                                                  .primaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          u,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 13,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ===================================================
  /// FOOTER
  /// ===================================================
  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.infoColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${mainController.parameters.length} parameters configured',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: AppTheme.secondaryButtonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.all(Colors.white),
                    foregroundColor:
                        MaterialStateProperty.all(AppTheme.textPrimary),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: AppTheme.primaryButtonStyle,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}