import 'dart:async';

import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/admin_control/admin_control_api_service.dart';
import 'package:mudpro_desktop_app/modules/installation/installation_identity.dart';

class AdminControlController extends GetxController {
  final isLoading = false.obs;
  final isAdminLoggedIn = false.obs;
  final isPasswordSetup = true.obs;
  final isStatusLoaded = false.obs;
  final passwordExpired = false.obs;
  final daysRemaining = 30.obs;
  final message = ''.obs;
  final currentDevice = <String, dynamic>{}.obs;
  final devices = <Map<String, dynamic>>[].obs;
  final logs = <Map<String, dynamic>>[].obs;
  final adminToken = ''.obs;
  final isDeviceAllowed = false.obs;
  final resetCount = 0.obs;
  final generatedAccessCode = ''.obs;
  final generatedAccessCodeMessage = ''.obs;
  Timer? _sessionTimer;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    await _run(() async {
      currentDevice.value = await InstallationIdentity.currentDevicePayload();
      await refreshStatus();
      await refreshCurrentDevice();
    });
  }

  Future<void> refreshStatus() async {
    final response = await AdminControlApiService.getStatus();
    final data = Map<String, dynamic>.from(response['data'] ?? {});
    isPasswordSetup.value = data['isSetup'] == true;
    isStatusLoaded.value = true;
    passwordExpired.value = data['expired'] == true;
    daysRemaining.value = int.tryParse('${data['daysRemaining'] ?? 0}') ?? 0;
    resetCount.value = int.tryParse('${data['resetCount'] ?? 0}') ?? 0;
  }

  Future<void> refreshCurrentDevice() async {
    final response = await AdminControlApiService.checkDeviceAccess();
    final data = Map<String, dynamic>.from(response['data'] ?? {});
    currentDevice.value = {
      ...currentDevice.value,
      ...data,
      'allowed': response['allowed'] == true,
    };
    isDeviceAllowed.value = response['allowed'] == true;
  }

  Future<void> verifyAccessCode(String code) async {
    await _run(() async {
      final response = await AdminControlApiService.verifyAccessCode(code);
      final data = Map<String, dynamic>.from(response['data'] ?? {});
      currentDevice.value = {
        ...currentDevice.value,
        ...data,
        'allowed': response['allowed'] == true,
      };
      isDeviceAllowed.value = response['allowed'] == true;
      message.value = response['message']?.toString() ?? 'Device access activated';
    });
  }

  Future<void> setupPassword(String password, String confirmPassword) async {
    await _run(() async {
      try {
        await AdminControlApiService.setupPassword(
          password: password,
          confirmPassword: confirmPassword,
        );
        message.value = 'Admin password configured';
      } catch (error) {
        final text = error.toString().replaceFirst('Exception: ', '');
        if (text == 'Admin password is already configured') {
          isPasswordSetup.value = true;
          message.value = 'Admin password already configured. Please login.';
        } else {
          rethrow;
        }
      }
      await refreshStatus();
    });
  }

  Future<void> login(String password) async {
    await _run(() async {
      final response = await AdminControlApiService.login(password);
      final data = Map<String, dynamic>.from(response['data'] ?? {});
      adminToken.value = '${data['sessionToken'] ?? ''}';
      isAdminLoggedIn.value = true;
      message.value = 'Admin login successful';
      _startSessionTimer();
      await refreshStatus();
      await _refreshDevices();
      await _refreshLogs();
    });
  }

  void logout({String text = 'Admin logged out'}) {
    _sessionTimer?.cancel();
    adminToken.value = '';
    isAdminLoggedIn.value = false;
    devices.clear();
    logs.clear();
    generatedAccessCode.value = '';
    generatedAccessCodeMessage.value = '';
    message.value = text;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _run(() async {
      await AdminControlApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        adminToken: adminToken.value,
      );
      message.value = 'Admin password changed';
      await refreshStatus();
    });
  }

  Future<void> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _run(() async {
      await AdminControlApiService.resetPassword(
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      message.value = 'Admin password reset successful';
      await refreshStatus();
    });
  }

  Future<void> approveCurrentDevice() async {
    await _run(() async {
      final response =
          await AdminControlApiService.registerCurrentDevice(adminToken.value);
      final device = Map<String, dynamic>.from(response['data'] ?? {});
      final id = '${device['_id'] ?? ''}';
      if (id.isNotEmpty) {
        await AdminControlApiService.updateDeviceStatus(
          id: id,
          status: 'allowed',
          adminToken: adminToken.value,
        );
      }
      message.value = 'Current device approved';
      await refreshCurrentDevice();
      await _refreshDevices();
    });
  }

  Future<void> refreshDevices() async {
    await _run(_refreshDevices);
  }

  Future<void> _refreshDevices() async {
    final response = await AdminControlApiService.getDevices(adminToken.value);
    devices.value = (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> updateDeviceStatus({
    required String id,
    required String status,
  }) async {
    await _run(() async {
      await AdminControlApiService.updateDeviceStatus(
        id: id,
        status: status,
        adminToken: adminToken.value,
      );
      await _refreshDevices();
      await refreshCurrentDevice();
      message.value = 'Device ${status == 'allowed' ? 'allowed' : 'blocked'}';
    });
  }

  Future<void> generateAccessCode({
    required String id,
    required int durationDays,
  }) async {
    await _run(() async {
      final response = await AdminControlApiService.generateAccessCode(
        id: id,
        durationDays: durationDays,
        adminToken: adminToken.value,
      );
      final data = Map<String, dynamic>.from(response['data'] ?? {});
      generatedAccessCode.value = '${data['code'] ?? ''}';
      generatedAccessCodeMessage.value =
          'Valid for $durationDays day${durationDays == 1 ? '' : 's'}. Code expires in 24 hours.';
      await _refreshDevices();
      await _refreshLogs();
      message.value = 'Access code generated';
    });
  }

  Future<void> refreshLogs() async {
    await _run(_refreshLogs);
  }

  Future<void> _refreshLogs() async {
    final response = await AdminControlApiService.getLogs(adminToken.value);
    logs.value = (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      isLoading.value = true;
      message.value = '';
      await action();
    } catch (error) {
      final text = error.toString().replaceFirst('Exception: ', '');
      if (text == 'SESSION_EXPIRED') {
        logout(text: 'Session expired. Please login again.');
      } else {
        message.value = text;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 30), () {
      logout(text: 'Session expired. Please login again.');
    });
  }

  @override
  void onClose() {
    _sessionTimer?.cancel();
    super.onClose();
  }
}
