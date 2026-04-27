import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/engineers_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_setup_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudCompanyPage extends StatefulWidget {
  const MudCompanyPage({super.key});

  @override
  State<MudCompanyPage> createState() => _MudCompanyPageState();
}

class _MudCompanyPageState extends State<MudCompanyPage> {
  final EngineerController engineerController = Get.find<EngineerController>();
  final CompanyController companyController = Get.find<CompanyController>();
  final CompanySetupController companySetupController =
      Get.find<CompanySetupController>();

  final ScrollController _tableScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _tableScrollController.dispose();
    _horizontalScrollController.dispose();
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
            child: Obx(
              () => IgnorePointer(
                ignoring: companySetupController.isLocked.value,
                child: Opacity(
                  opacity: companySetupController.isLocked.value ? 0.6 : 1.0,
                  child: Row(
                    children: [
                      _leftSection(),
                      const SizedBox(width: 12),
                      Expanded(child: _rightSection()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Top right alerts
          Positioned(
            top: 20,
            right: 20,
            child: Obx(() {
              final alertMsg = engineerController.alertMessage.value.isNotEmpty
                  ? engineerController.alertMessage.value
                  : companyController.alertMessage.value;
              final errorMsg = engineerController.errorMessage.value.isNotEmpty
                  ? engineerController.errorMessage.value
                  : companyController.errorMessage.value;

              if (alertMsg.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alertMsg,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (errorMsg.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        errorMsg,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // LEFT SECTION
  // ======================================================
  Widget _leftSection() {
    return Container(
      width: 360,
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mud Company Settings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              if (companyController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Company Information'),
                    const SizedBox(height: 8),
                    _twoColumnRow(
                      'Company Name',
                      companyController.companyNameController,
                      Icons.business,
                    ),
                    const SizedBox(height: 6),
                    _twoColumnRow(
                      'Address',
                      companyController.addressController,
                      Icons.location_on,
                    ),
                    const SizedBox(height: 6),
                    _twoColumnRow(
                      'Phone',
                      companyController.phoneController,
                      Icons.phone,
                    ),
                    const SizedBox(height: 6),
                    _twoColumnRow(
                      'E-mail',
                      companyController.emailController,
                      Icons.email,
                    ),

                    const SizedBox(height: 20),

                    _sectionTitle('Company Logo'),
                    const SizedBox(height: 8),
                    _logoUploadSection(),

                    const SizedBox(height: 20),

                    _sectionTitle('Currency Settings'),
                    const SizedBox(height: 8),
                    _currencyRow(),
                    const SizedBox(height: 6),
                    _currencyFormatRow(),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed:
                            (companyController.isSaving.value ||
                                companySetupController.isLocked.value)
                            ? null
                            : () => companyController.saveCompanyDetails(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: companyController.isSaving.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, size: 16),
                        label: Text(
                          companyController.isSaving.value
                              ? 'Saving...'
                              : 'Save Company Details',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _twoColumnRow(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.cardColor,
                  AppTheme.cardColor.withOpacity(0.9),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Obx(
                () => TextField(
                  controller: controller,
                  readOnly: companySetupController.isLocked.value,
                  style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Enter $label...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoUploadSection() {
    return Obx(() {
      final logoUrl = companyController.logoUrl.value;
      final hasLogo = logoUrl.isNotEmpty;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Center(
                child: !hasLogo
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 36,
                            color: AppTheme.textSecondary.withOpacity(0.4),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'No Logo Selected',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: logoUrl.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(logoUrl.split(',').last),
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              )
                            : Image.network(
                                logoUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print("IMAGE LOAD ERROR: $error");
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 36,
                                        color: AppTheme.textSecondary
                                            .withOpacity(0.4),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Failed to load',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
              ),
            ),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasLogo ? 'Logo uploaded' : 'No file selected',
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Obx(
                    () => ElevatedButton.icon(
                      onPressed: companySetupController.isLocked.value
                          ? null
                          : () => companyController.pickLogoAndConvert(),
                      icon: const Icon(Icons.upload_file, size: 12),
                      label: const Text(
                        'Browse',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: companySetupController.isLocked.value
                            ? Colors.grey
                            : AppTheme.primaryColor,
                        minimumSize: const Size(80, 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _currencyRow() {
    final currencyOptions =
        {
              'â‚¹',
              '\$',
              'â‚¬',
              'Â£',
              'Â¥',
              'â‚©',
              'Kwd',
              companyController.currencySymbol.value,
            }
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList();
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.cardColor,
                  AppTheme.cardColor.withOpacity(0.9),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Symbol',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Obx(
                () => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: companyController.currencySymbol.value,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    onChanged: companySetupController.isLocked.value
                        ? null
                        : (v) => companyController.currencySymbol.value = v!,
                    items: currencyOptions,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyFormatRow() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.cardColor,
                  AppTheme.cardColor.withOpacity(0.9),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_numbered,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Format',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Obx(
                () => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: companyController.currencyFormat.value,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    onChanged: companySetupController.isLocked.value
                        ? null
                        : (v) => companyController.currencyFormat.value = v!,
                    items: const ['0', '0.0', '0.00', '0.000', '0.0000']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 12),
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
    );
  }

  // ======================================================
  // RIGHT SECTION — Engineers Table
  // ======================================================
  Widget _rightSection() {
    const double numberWidth = 50.0;
    const double firstNameWidth = 130.0;
    const double lastNameWidth = 130.0;
    const double cellWidth = 130.0;
    const double officeWidth = 180.0;
    const double emailWidth = 230.0;
    const double actionsWidth = 100.0;

    return Container(
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width:
                      966, // Exact total of fixed widths (50+130+130+130+180+230+100 + 6 dividers)
                  child: Column(
                    children: [
                      // Header
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.headerGradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            _HeaderCell(numberWidth, '#', Icons.numbers),
                            _verticalDivider(),
                            _HeaderCell(
                              firstNameWidth,
                              'First Name',
                              Icons.person,
                            ),
                            _verticalDivider(),
                            _HeaderCell(
                              lastNameWidth,
                              'Last Name',
                              Icons.person_outline,
                            ),
                            _verticalDivider(),
                            _HeaderCell(cellWidth, 'Cell', Icons.phone_android),
                            _verticalDivider(),
                            _HeaderCell(officeWidth, 'Office', Icons.phone),
                            _verticalDivider(),
                            _HeaderCell(emailWidth, 'E-mail', Icons.email),
                            _verticalDivider(),
                            _HeaderCell(
                              actionsWidth,
                              'Actions',
                              Icons.settings,
                            ),
                          ],
                        ),
                      ),

                      // Table Body
                      Expanded(
                        child: Obx(() {
                          if (engineerController.isLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final rowCount =
                              engineerController.rowControllers.length;

                          return Scrollbar(
                            controller: _tableScrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            child: ListView.builder(
                              controller: _tableScrollController,
                              itemCount: rowCount,
                              itemBuilder: (_, index) {
                                final row =
                                    engineerController.rowControllers[index];
                                final isSaved = row.engineerId != null;
                                final isEditing =
                                    isSaved &&
                                    engineerController
                                            .editingEngineerId
                                            .value ==
                                        row.engineerId;

                                return Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isEditing
                                        ? const Color(0xffEFF6FF)
                                        : isSaved
                                        ? const Color(0xffF3F4F6)
                                        : (index % 2 == 0
                                              ? Colors.white
                                              : AppTheme.cardColor),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _numberCell(
                                        numberWidth,
                                        index + 1,
                                        isSaved,
                                        isEditing: isEditing,
                                      ),
                                      _verticalDivider(),
                                      _editableCell(
                                        firstNameWidth,
                                        isEditing
                                            ? engineerController.inlineFirstName
                                            : row.firstNameController,
                                        'First name',
                                        index,
                                        isSaved && !isEditing,
                                      ),
                                      _verticalDivider(),
                                      _editableCell(
                                        lastNameWidth,
                                        isEditing
                                            ? engineerController.inlineLastName
                                            : row.lastNameController,
                                        'Last name',
                                        index,
                                        isSaved && !isEditing,
                                      ),
                                      _verticalDivider(),
                                      _editableCell(
                                        cellWidth,
                                        isEditing
                                            ? engineerController.inlineCell
                                            : row.cellController,
                                        'Cell',
                                        index,
                                        isSaved && !isEditing,
                                      ),
                                      _verticalDivider(),
                                      _editableCell(
                                        officeWidth,
                                        isEditing
                                            ? engineerController.inlineOffice
                                            : row.officeController,
                                        'Office',
                                        index,
                                        isSaved && !isEditing,
                                      ),
                                      _verticalDivider(),
                                      _editableCell(
                                        emailWidth,
                                        isEditing
                                            ? engineerController.inlineEmail
                                            : row.emailController,
                                        'Email',
                                        index,
                                        (row.engineerId != null &&
                                                !isEditing) ||
                                            companySetupController
                                                .isLocked
                                                .value,
                                      ),
                                      _verticalDivider(),
                                      _actionsCell(
                                        actionsWidth,
                                        row,
                                        index,
                                        isEditing,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Obx(() {
              final totalEngineers = engineerController.engineers.length;
              return Row(
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
                        '$totalEngineers engineer${totalEngineers != 1 ? 's' : ''} • Mud Company Directory',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: companySetupController.isLocked.value
                            ? null
                            : () => companySetupController.handleImport(),
                        style: AppTheme.secondaryButtonStyle.copyWith(
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          minimumSize: MaterialStateProperty.all(
                            const Size(0, 32),
                          ),
                        ),
                        icon: const Icon(Icons.file_upload, size: 14),
                        label: const Text(
                          'Import',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => companySetupController.handleExport(),
                        style: AppTheme.secondaryButtonStyle.copyWith(
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          minimumSize: MaterialStateProperty.all(
                            const Size(0, 32),
                          ),
                        ),
                        icon: const Icon(Icons.file_download, size: 14),
                        label: const Text(
                          'Export',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed:
                            (engineerController.isSaving.value ||
                                companySetupController.isLocked.value)
                            ? null
                            : () => engineerController.saveAllRows(),
                        style: AppTheme.primaryButtonStyle.copyWith(
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          minimumSize: MaterialStateProperty.all(
                            const Size(0, 32),
                          ),
                        ),
                        icon: engineerController.isSaving.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, size: 14),
                        label: Text(
                          engineerController.isSaving.value
                              ? 'Saving...'
                              : 'Save All',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        icon: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Close',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.grey.shade300,
    );
  }

  Widget _numberCell(
    double width,
    int number,
    bool isSaved, {
    bool isEditing = false,
  }) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSaved && !isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.lock, size: 10, color: Colors.grey.shade400),
            ),
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.edit, size: 10, color: Colors.blue.shade400),
            ),
          Text(
            number.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isEditing
                  ? Colors.blue
                  : isSaved
                  ? AppTheme.primaryColor
                  : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableCell(
    double width,
    TextEditingController controller,
    String hint,
    int rowIndex,
    bool isCellLocked,
  ) {
    return Container(
      width: width,
      color: companySetupController.isLocked.value ? null : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        enabled: !isCellLocked,
        onChanged: (_) {
          // Only trigger auto-add for truly new (unsaved) rows
          final row = engineerController.rowControllers[rowIndex];
          if (row.engineerId == null) {
            engineerController.checkAndAddRow(rowIndex);
          }
        },
        style: TextStyle(
          fontSize: 12,
          color: isCellLocked ? AppTheme.textSecondary : AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: isCellLocked ? '' : hint,
          hintStyle: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _actionsCell(
    double width,
    EngineerRowControllers row,
    int rowIndex,
    bool isEditing,
  ) {
    final isSaved = row.engineerId != null;

    // New unsaved row — no actions
    if (!isSaved) {
      return Container(
        width: width,
        alignment: Alignment.center,
        child: Text(
          '-',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
        ),
      );
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: isEditing
            ? [
                // Save inline edit
                IconButton(
                  onPressed: engineerController.isSaving.value
                      ? null
                      : () => engineerController.saveInlineEdit(),
                  icon: engineerController.isSaving.value
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        )
                      : const Icon(Icons.save, size: 16),
                  color: Colors.green,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: 'Save',
                ),
                const SizedBox(width: 4),
                // Cancel inline edit
                IconButton(
                  onPressed: () => engineerController.cancelInlineEdit(),
                  icon: const Icon(Icons.close, size: 16),
                  color: Colors.orange,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: 'Cancel',
                ),
              ]
            : [
                // Start inline edit
                IconButton(
                  onPressed: () => engineerController.startInlineEdit(row),
                  icon: const Icon(Icons.edit, size: 16),
                  color: Colors.blue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: 'Edit',
                ),
                const SizedBox(width: 4),
                // Delete
                IconButton(
                  onPressed: () {
                    final engineerName =
                        '${row.firstNameController.text} ${row.lastNameController.text}';
                    engineerController.showDeleteConfirmation(
                      context,
                      row.engineerId!,
                      engineerName,
                    );
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: 'Delete',
                ),
              ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final double width;
  final String text;
  final IconData icon;

  const _HeaderCell(this.width, this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
