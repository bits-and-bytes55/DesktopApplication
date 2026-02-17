// lib/modules/company_setup/controller/company_controller.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/company_model.dart';

class CompanyController extends GetxController {
  final AuthRepository _repository = AuthRepository();

  // ===============================
  // STATE
  // ===============================
  final Rx<Company?> company = Rx<Company?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // ===============================
  // FORM CONTROLLERS
  // ===============================
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // ===============================
  // LOGO (BASE64)
  // ===============================
  final RxString logoUrl = ''.obs;      // preview / server url
  final RxString logoBase64 = ''.obs;   // base64 for API

  // ===============================
  // CURRENCY
  // ===============================
  final RxString currencySymbol = '₹'.obs;
  final RxString currencyFormat = '0.00'.obs;

  // ===============================
  // ALERTS
  // ===============================
  final RxString alertMessage = ''.obs;
  final RxString errorMessage = ''.obs;

  // ===============================
  // LIFECYCLE
  // ===============================
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
    super.onClose();
  }

  // ===============================
  // PICK IMAGE → BASE64
  // ===============================
  Future<void> pickLogoAndConvert() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        Uint8List bytes = result.files.single.bytes!;
        logoBase64.value = base64Encode(bytes);

        // preview in UI
        logoUrl.value = "data:image/png;base64,${logoBase64.value}";
      }
    } catch (e) {
      _showError("Image selection failed");
    }
  }

  // ===============================
  // GET COMPANY
  // ===============================
  Future<void> fetchCompanyDetails() async {
    isLoading.value = true;

    final result = await _repository.getCompanyDetails();

    if (result['success'] == true && result['data'] != null) {
      company.value = result['data'];
      _populateControllers();
    }

    isLoading.value = false;
  }

  void _populateControllers() {
    final data = company.value;
    if (data == null) return;

    companyNameController.text = data.companyName;
    addressController.text = data.address;
    phoneController.text = data.phone;
    emailController.text = data.email;

    logoUrl.value = data.logoUrl ?? '';
    currencySymbol.value = data.currencySymbol;
    currencyFormat.value = data.currencyFormat;
  }

  // ===============================
  // SAVE / UPDATE COMPANY
  // ===============================
  Future<void> saveCompanyDetails() async {
    if (!_validate()) return;

    isSaving.value = true;

    final Map<String, dynamic> payload = {
      "companyName": companyNameController.text.trim(),
      "address": addressController.text.trim(),
      "phone": phoneController.text.trim(),
      "email": emailController.text.trim(),
      "currencySymbol": currencySymbol.value,
      "currencyFormat": currencyFormat.value,
      if (logoBase64.value.isNotEmpty)
        "logoBase64": "data:image/png;base64,${logoBase64.value}",
    };

    final Map<String, dynamic> result =
        company.value == null
            ? await _repository.addCompanyDetails(payload)
            : await _repository.updateCompanyDetails(payload);

    if (result['success'] == true) {
      _showSuccess(result['message'] ?? "Company saved");
      logoBase64.value = '';
      await fetchCompanyDetails();
    } else {
      _showError(result['message'] ?? "Failed to save company");
    }

    isSaving.value = false;
  }

  // ===============================
  // VALIDATION
  // ===============================
  bool _validate() {
    if (companyNameController.text.trim().isEmpty) {
      _showError("Company name is required");
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      _showError("Address is required");
      return false;
    }
    if (phoneController.text.trim().isEmpty) {
      _showError("Phone is required");
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      _showError("Email is required");
      return false;
    }
    return true;
  }

  // ===============================
  // ALERT HELPERS
  // ===============================
  void _showSuccess(String msg) {
    alertMessage.value = msg;
    errorMessage.value = '';
    Future.delayed(const Duration(seconds: 3), () {
      alertMessage.value = '';
    });
  }

  void _showError(String msg) {
    errorMessage.value = msg;
    alertMessage.value = '';
    Future.delayed(const Duration(seconds: 3), () {
      errorMessage.value = '';
    });
  }
}
