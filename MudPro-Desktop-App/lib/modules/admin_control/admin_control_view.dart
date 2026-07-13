import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/admin_control/admin_control_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class AdminControlView extends StatelessWidget {
  AdminControlView({super.key});

  final AdminControlController c = Get.isRegistered<AdminControlController>()
      ? Get.find<AdminControlController>()
      : Get.put(AdminControlController(), permanent: true);

  final _loginPassword = TextEditingController();
  final _setupPassword = TextEditingController();
  final _setupConfirm = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _resetPassword = TextEditingController();
  final _resetConfirm = TextEditingController();
  final _accessCode = TextEditingController();
  final _customAccessDays = TextEditingController(text: '1');

  static const _blue = AppTheme.primaryColor;
  static const _border = Color(0xFFB9D4EF);
  static const _pageBg = Color(0xFFEAF4FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      padding: const EdgeInsets.all(14),
      child: Obx(
        () => Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topHeader(),
                const SizedBox(height: 10),
                if (!c.isDeviceAllowed.value) _unauthorizedBanner(),
                if (c.message.value.isNotEmpty) _messageBox(),
                if (c.passwordExpired.value) _expiryWarning(),
                Expanded(
                  child: c.isAdminLoggedIn.value
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 430,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _currentDeviceCard(),
                                    const SizedBox(height: 10),
                                    _passwordCard(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(child: _devicesCard()),
                                  const SizedBox(height: 10),
                                  Expanded(child: _logsCard()),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: 560,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _adminAccessCard(),
                                  if (!c.isDeviceAllowed.value) ...[
                                    const SizedBox(height: 10),
                                    _activateAccessCodeCard(),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
            if (c.isLoading.value)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _blue,
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Admin Control',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (c.isAdminLoggedIn.value) ...[
            TextButton.icon(
              onPressed: () => c.logout(),
              icon: const Icon(Icons.logout, color: Colors.white, size: 16),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            onPressed: c.loadInitial,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
            label: const Text(
              'Refresh',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unauthorizedBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          border: Border.all(color: const Color(0xFFFFC107)),
        ),
        child: Text(
          _unauthorizedMessage(),
          style: const TextStyle(
            color: Color(0xFF2F2F2F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _unauthorizedMessage() {
    final status = '${c.currentDevice['status'] ?? ''}'.toLowerCase();
    if (status == 'expired') {
      return 'This device access has expired. Please contact admin.';
    }
    if (status == 'blocked') {
      return 'This device is blocked. Please contact admin.';
    }
    return 'This device is not authorized. Login to Admin Control to approve this device.';
  }

  Widget _messageBox() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
        ),
        child: Text(
          c.message.value,
          style: AppTheme.wellLikeBodyText,
        ),
      ),
    );
  }

  Widget _expiryWarning() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          border: Border.all(color: const Color(0xFFFFC107)),
        ),
        child: const Text(
          'Admin password has expired. Change password is mandatory.',
          style: TextStyle(
            color: Color(0xFF2F2F2F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: _blue,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(10), child: child),
        ],
      ),
    );
  }

  Widget _currentDeviceCard() {
    final device = c.currentDevice;
    final status = '${device['status'] ?? 'pending'}';
    final allowed = device['allowed'] == true || status == 'allowed';
    return _card(
      'Current Device',
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Text('Status', style: AppTheme.wellLikeBodyText),
                ),
                _statusBadge(allowed ? 'allowed' : status),
              ],
            ),
          ),
          _infoRow('Hostname', '${device['hostname'] ?? ''}'),
          _infoRow('MAC Address', '${device['macAddress'] ?? ''}'),
          _infoRow('IP Address', '${device['ipAddress'] ?? ''}'),
          _infoRow('Installation ID', '${device['installationId'] ?? ''}'),
          _infoRow('Machine Key', '${device['machineKey'] ?? ''}'),
          _infoRow('Access Type', '${device['accessType'] ?? 'none'}'),
          _infoRow('Expires At', _displayValue(device['accessExpiresAt'])),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton.icon(
              onPressed: c.isAdminLoggedIn.value ? c.approveCurrentDevice : null,
              icon: const Icon(Icons.verified_user, size: 16),
              label: const Text('Approve This Device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminAccessCard() {
    return _card(
      'Admin Login',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_adminLoginMessage(), style: AppTheme.wellLikeBodyText),
          const SizedBox(height: 8),
          if (!c.isStatusLoaded.value) ...[
            const SizedBox(
              height: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ] else if (!c.isPasswordSetup.value) ...[
            _passwordField(_setupPassword, 'New password'),
            const SizedBox(height: 6),
            _passwordField(_setupConfirm, 'Confirm password'),
            const SizedBox(height: 8),
            _button(
              'Create Admin Password',
              () => c.setupPassword(
                _setupPassword.text,
                _setupConfirm.text,
              ),
            ),
          ] else ...[
            _passwordField(_loginPassword, 'Admin password'),
            const SizedBox(height: 8),
            _button('Login', () => c.login(_loginPassword.text)),
          ],
        ],
      ),
    );
  }

  Widget _activateAccessCodeCard() {
    return _card(
      'Activate Device Access',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the 10 digit access code provided by admin.',
            style: AppTheme.wellLikeBodyText,
          ),
          const SizedBox(height: 8),
          _textField(_accessCode, '10 digit access code'),
          const SizedBox(height: 8),
          _button(
            'Activate Access',
            () => c.verifyAccessCode(_accessCode.text),
          ),
        ],
      ),
    );
  }

  Widget _generatedCodeCard() {
    if (c.generatedAccessCode.value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          border: Border.all(color: const Color(0xFFFFC107)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generated Access Code', style: AppTheme.wellLikeBodyText),
            const SizedBox(height: 6),
            SelectableText(
              c.generatedAccessCode.value,
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(
              c.generatedAccessCodeMessage.value,
              style: AppTheme.wellLikeBodyText.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _adminLoginMessage() {
    if (!c.isStatusLoaded.value) {
      return 'Checking admin password status...';
    }
    return c.isPasswordSetup.value
        ? 'Enter admin password to manage device access.'
        : 'No admin password exists. Create it first.';
  }

  Widget _passwordCard() {
    return _card(
      'Password Management',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Days remaining', '${c.daysRemaining.value}'),
          const SizedBox(height: 8),
          _passwordField(_currentPassword, 'Current password'),
          const SizedBox(height: 6),
          _passwordField(_newPassword, 'New password'),
          const SizedBox(height: 6),
          _passwordField(_confirmPassword, 'Confirm password'),
          const SizedBox(height: 8),
          _button(
            'Change Password',
            c.isAdminLoggedIn.value
                ? () => c.changePassword(
                      currentPassword: _currentPassword.text,
                      newPassword: _newPassword.text,
                      confirmPassword: _confirmPassword.text,
                    )
                : null,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(
            'Reset Password (${c.resetCount.value}/2 used)',
            style: AppTheme.wellLikeBodyText,
          ),
          const SizedBox(height: 6),
          _passwordField(_resetPassword, 'Reset new password'),
          const SizedBox(height: 6),
          _passwordField(_resetConfirm, 'Confirm reset password'),
          const SizedBox(height: 8),
          _button(
            'Reset Password',
            c.resetCount.value < 2
                ? () => c.resetPassword(
                      newPassword: _resetPassword.text,
                      confirmPassword: _resetConfirm.text,
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _devicesCard() {
    return _largeCard(
      'Device Access List',
      [
        _generatedCodeCard(),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              TextButton.icon(
                onPressed: c.isAdminLoggedIn.value ? c.refreshDevices : null,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Devices'),
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                child: _textField(_customAccessDays, 'Custom days'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: c.devices.length,
            itemBuilder: (_, index) {
              final device = c.devices[index];
              final id = '${device['_id'] ?? ''}';
              final status = '${device['status'] ?? ''}';
              return ListTile(
                dense: true,
                title: Text(
                  '${device['hostname'] ?? 'Unknown device'}',
                  style: AppTheme.wellLikeBodyText,
                ),
                subtitle: Text(
                  _deviceSubtitle(device),
                  style: AppTheme.wellLikeBodyText.copyWith(fontSize: 10),
                ),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    _statusBadge(status),
                    _durationButton(id, '1D', 1),
                    _durationButton(id, '2D', 2),
                    _durationButton(id, '7D', 7),
                    _customDurationButton(id),
                    TextButton(
                      onPressed: c.isAdminLoggedIn.value && id.isNotEmpty
                          ? () =>
                              c.updateDeviceStatus(id: id, status: 'allowed')
                          : null,
                      child: const Text('Allow'),
                    ),
                    TextButton(
                      onPressed: c.isAdminLoggedIn.value && id.isNotEmpty
                          ? () =>
                              c.updateDeviceStatus(id: id, status: 'blocked')
                          : null,
                      child: const Text('Block'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _deviceSubtitle(Map<String, dynamic> device) {
    final expires = '${device['accessExpiresAt'] ?? ''}';
    final accessType = '${device['accessType'] ?? 'none'}';
    final lines = <String>[
      '${device['macAddress'] ?? ''}',
      '${device['installationId'] ?? ''}',
      if (accessType != 'none') 'Access: $accessType',
      if (expires.isNotEmpty && expires != 'null') 'Expires: $expires',
    ];
    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  Widget _durationButton(String id, String label, int days) {
    return TextButton(
      onPressed: c.isAdminLoggedIn.value && id.isNotEmpty
          ? () => c.generateAccessCode(id: id, durationDays: days)
          : null,
      child: Text(label),
    );
  }

  Widget _customDurationButton(String id) {
    return TextButton(
      onPressed: c.isAdminLoggedIn.value && id.isNotEmpty
          ? () {
              final days = int.tryParse(_customAccessDays.text.trim()) ?? 1;
              c.generateAccessCode(id: id, durationDays: days);
            }
          : null,
      child: const Text('Custom'),
    );
  }

  Widget _logsCard() {
    return _largeCard(
      'Security Logs',
      [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: c.isAdminLoggedIn.value ? c.refreshLogs : null,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh Logs'),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: c.logs.length,
            itemBuilder: (_, index) {
              final log = c.logs[index];
              return ListTile(
                dense: true,
                title: Text(
                  '${log['type'] ?? ''}',
                  style: AppTheme.wellLikeBodyText,
                ),
                subtitle: Text(
                  '${log['message'] ?? ''}\n${log['createdAt'] ?? ''}',
                  style: AppTheme.wellLikeBodyText.copyWith(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _largeCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: _blue,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: AppTheme.wellLikeBodyText),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTheme.wellLikeBodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase().trim();
    final color = switch (normalized) {
      'allowed' => const Color(0xFF1E8E3E),
      'blocked' => const Color(0xFFD93025),
      'expired' => const Color(0xFF6F42C1),
      _ => const Color(0xFFB7791F),
    };
    final label = switch (normalized) {
      'allowed' => 'Allowed',
      'blocked' => 'Blocked',
      'expired' => 'Expired',
      _ => 'Pending',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  String _displayValue(dynamic value) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text == 'null') {
      return '-';
    }
    return text;
  }

  Widget _textField(TextEditingController controller, String hint) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        style: AppTheme.wellLikeBodyText,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget _passwordField(TextEditingController controller, String hint) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        obscureText: true,
        style: AppTheme.wellLikeBodyText,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
        ),
        child: Text(text),
      ),
    );
  }
}
