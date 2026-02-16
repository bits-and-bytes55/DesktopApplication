import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/company_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/engineers_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class MudCompanyPage extends StatefulWidget {
  const MudCompanyPage({super.key});

  @override
  State<MudCompanyPage> createState() => _MudCompanyPageState();
}

class _MudCompanyPageState extends State<MudCompanyPage> {
  final EngineerController engineerController = Get.put(EngineerController());
  final CompanyController companyController = Get.put(CompanyController());

  final ScrollController _tableScrollController = ScrollController();

  @override
  void dispose() {
    _tableScrollController.dispose();
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
            child: Row(
              children: [
                _leftSection(),
                const SizedBox(width: 12),
                Expanded(child: _rightSection()),
              ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: const Icon(Icons.business, color: Colors.white, size: 18),
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
                    _twoColumnRow('Company Name', companyController.companyNameController, Icons.business),
                    const SizedBox(height: 6),
                    _twoColumnRow('Address', companyController.addressController, Icons.location_on),
                    const SizedBox(height: 6),
                    _twoColumnRow('Phone', companyController.phoneController, Icons.phone),
                    const SizedBox(height: 6),
                    _twoColumnRow('E-mail', companyController.emailController, Icons.email),
                    
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
                        onPressed: companyController.isSaving.value
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
                          companyController.isSaving.value ? 'Saving...' : 'Save Company Details',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _twoColumnRow(String label, TextEditingController controller, IconData icon) {
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
                colors: [AppTheme.cardColor, AppTheme.cardColor.withOpacity(0.9)],
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
              child: TextField(
                controller: controller,
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
        ],
      ),
    );
  }

  // Only the _logoUploadSection() widget - replace in your MudCompanyPage

Widget _logoUploadSection() {
  return Obx(() {
    final logoUrl = companyController.logoUrl.value;
    final hasSelectedFile = companyController.selectedLogoFile.value != null;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          // Logo Preview
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: logoUrl.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 36,
                          color: AppTheme.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No Logo Selected',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: hasSelectedFile
                            ? Image.file(
                                companyController.selectedLogoFile.value!,
                                fit: BoxFit.contain,
                              )
                            : Image.network(
                                logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.broken_image,
                                    size: 36,
                                    color: AppTheme.errorColor,
                                  );
                                },
                              ),
                      ),
                    ),
            ),
          ),
          
          // Upload Controls
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasSelectedFile
                        ? companyController.selectedLogoFile.value!.path.split('/').last
                        : (logoUrl.isNotEmpty ? 'Logo uploaded' : 'No file selected'),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => companyController.pickLogoImage(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(80, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file, size: 12),
                  label: const Text('Browse', style: TextStyle(fontSize: 11)),
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
                colors: [AppTheme.cardColor, AppTheme.cardColor.withOpacity(0.9)],
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
                Icon(Icons.currency_exchange, size: 14, color: AppTheme.textSecondary),
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
              child: Obx(() => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: companyController.currencySymbol.value,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.primaryColor),
                  style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                  onChanged: (v) => companyController.currencySymbol.value = v!,
                  items: const ['₹', '\$', '€', '£', '¥', '₩']
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                ),
              )),
            ),
          ),
        ],
      )
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
                colors: [AppTheme.cardColor, AppTheme.cardColor.withOpacity(0.9)],
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
                Icon(Icons.format_list_numbered, size: 14, color: AppTheme.textSecondary),
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
              child: Obx(() => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: companyController.currencyFormat.value,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.primaryColor),
                  style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                  onChanged: (v) => companyController.currencyFormat.value = v!,
                  items: const ['0', '0.0', '0.00', '0.000', '0.0000']
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // RIGHT SECTION - Engineers Table (FIXED STRUCTURE)
  // ======================================================
  Widget _rightSection() {
    // Fixed column widths
    const double numberWidth = 50.0;
    const double firstNameWidth = 150.0;
    const double lastNameWidth = 150.0;
    const double cellWidth = 150.0;
    const double officeWidth = 160.0;
    const double emailWidth = 200.0;

    return Container(
      decoration: AppTheme.elevatedCardDecoration,
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
                _HeaderCell(firstNameWidth, 'First Name', Icons.person),
                _verticalDivider(),
                _HeaderCell(lastNameWidth, 'Last Name', Icons.person_outline),
                _verticalDivider(),
                _HeaderCell(cellWidth, 'Cell', Icons.phone_android),
                _verticalDivider(),
                _HeaderCell(officeWidth, 'Office', Icons.phone),
                _verticalDivider(),
                _HeaderCell(emailWidth, 'E-mail', Icons.email),
              ],
            ),
          ),
          
          // Table Body
          Expanded(
            child: Obx(() {
              if (engineerController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final rowCount = engineerController.rowControllers.length;

              return Scrollbar(
                controller: _tableScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: ListView.builder(
                  controller: _tableScrollController,
                  itemCount: rowCount,
                  itemBuilder: (_, index) {
                    final row = engineerController.rowControllers[index];
                    final isSaved = row.engineerId != null;
                    
                    return Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : AppTheme.cardColor,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          _numberCell(numberWidth, index + 1, isSaved),
                          _verticalDivider(),
                          _editableCell(firstNameWidth, row.firstNameController, 'First name', index, isSaved),
                          _verticalDivider(),
                          _editableCell(lastNameWidth, row.lastNameController, 'Last name', index, isSaved),
                          _verticalDivider(),
                          _editableCell(cellWidth, row.cellController, 'Cell', index, isSaved),
                          _verticalDivider(),
                          _editableCell(officeWidth, row.officeController, 'Office', index, isSaved),
                          _verticalDivider(),
                          _editableCell(emailWidth, row.emailController, 'Email', index, isSaved),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
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
              border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
            ),
            child: Obx(() {
              final totalEngineers = engineerController.engineers.length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.infoColor),
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
                        onPressed: engineerController.isSaving.value
                            ? null
                            : () => engineerController.saveAllRows(),
                        style: AppTheme.primaryButtonStyle.copyWith(
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          minimumSize: MaterialStateProperty.all(const Size(0, 32)),
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
                          engineerController.isSaving.value ? 'Saving...' : 'Save All',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 32),
                        ),
                        icon: const Icon(Icons.close, size: 14, color: Colors.red),
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

  Widget _numberCell(double width, int number, bool isSaved) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSaved ? AppTheme.primaryColor : AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _editableCell(
    double width,
    TextEditingController controller,
    String hint,
    int rowIndex,
    bool isSaved,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        enabled: !isSaved,
        onChanged: (_) {
          engineerController.checkAndAddRow(rowIndex);
        },
        style: TextStyle(
          fontSize: 12,
          color: isSaved ? AppTheme.textSecondary : AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: isSaved ? '' : hint,
          hintStyle: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary.withOpacity(0.4),
          ),
        ),
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