// lib/modules/company_setup/controller/company_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/company_model.dart';

class CompanyController extends GetxController {
  final _repository = AuthRepository();

  // Observable company data
  final Rx<Company?> company = Rx<Company?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // Text controllers for form fields
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController logoUrlController = TextEditingController();

  // Observable for logo
  final RxString logoUrl = ''.obs;
  final Rx<File?> selectedLogoFile = Rx<File?>(null);

  // Observable for currency settings
  final RxString currencySymbol = '₹'.obs;
  final RxString currencyFormat = '0.00'.obs;

  // Alert messages
  final RxString alertMessage = ''.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanyDetails();
  }

  @override
  void onClose() {
    companyNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    logoUrlController.dispose();
    super.onClose();
  }

  // Pick logo image
  Future<void> pickLogoImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        selectedLogoFile.value = File(result.files.single.path!);
        logoUrl.value = result.files.single.path!;
        logoUrlController.text = result.files.single.name;
      }
    } catch (e) {
      _showError('Error picking image: ${e.toString()}');
    }
  }

  // Fetch company details
  Future<void> fetchCompanyDetails() async {
    isLoading.value = true;
    
    final result = await _repository.getCompanyDetails();
    
    if (result['success'] == true && result['data'] != null) {
      company.value = result['data'] as Company;
      _populateControllers();
    }
    
    isLoading.value = false;
  }

  // Populate controllers with fetched data
  void _populateControllers() {
    if (company.value != null) {
      companyNameController.text = company.value!.companyName;
      addressController.text = company.value!.address;
      phoneController.text = company.value!.phone;
      emailController.text = company.value!.email;
      
      // Set logo URL from server
      if (company.value!.logoUrl != null && company.value!.logoUrl!.isNotEmpty) {
        // If logoUrl starts with /uploads, construct full URL
        if (company.value!.logoUrl!.startsWith('/uploads')) {
          logoUrl.value = 'https://mudpro-desktop-app.onrender.com${company.value!.logoUrl}';
        } else {
          logoUrl.value = company.value!.logoUrl!;
        }
      }
      
      currencySymbol.value = company.value!.currencySymbol;
      currencyFormat.value = company.value!.currencyFormat;
    }
  }

  // Save company details
  Future<void> saveCompanyDetails() async {
    // Validation
    if (companyNameController.text.trim().isEmpty) {
      _showError('Company name is required');
      return;
    }
    if (addressController.text.trim().isEmpty) {
      _showError('Address is required');
      return;
    }
    if (phoneController.text.trim().isEmpty) {
      _showError('Phone is required');
      return;
    }
    if (emailController.text.trim().isEmpty) {
      _showError('Email is required');
      return;
    }

    isSaving.value = true;

    final newCompany = Company(
      id: company.value?.id,
      companyName: companyNameController.text.trim(),
      address: addressController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      logoUrl: company.value?.logoUrl, // Keep existing logo URL
      currencySymbol: currencySymbol.value,
      currencyFormat: currencyFormat.value,
    );

    Map<String, dynamic> result;
    if (company.value != null) {
      // Update existing company
      result = await _repository.updateCompanyDetails(
        newCompany, 
        logoFile: selectedLogoFile.value,
      );
    } else {
      // Add new company
      result = await _repository.addCompanyDetails(
        newCompany, 
        logoFile: selectedLogoFile.value,
      );
    }

    if (result['success'] == true) {
      company.value = result['data'] as Company?;
      selectedLogoFile.value = null; // Clear selected file
      _showSuccess(result['message'] ?? 'Company details saved successfully');
      await fetchCompanyDetails();
    } else {
      _showError(result['message'] ?? 'Failed to save company details');
    }

    isSaving.value = false;
  }

  void _showSuccess(String message) {
    alertMessage.value = message;
    errorMessage.value = '';
    
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      alertMessage.value = '';
    });
  }

  void _showError(String message) {
    errorMessage.value = message;
    alertMessage.value = '';
    
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      errorMessage.value = '';
    });
  }
}