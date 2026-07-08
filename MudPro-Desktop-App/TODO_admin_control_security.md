# Admin Control Security Feature TODO

## Required behavior

- The app may install and launch on any Windows system.
- `Admin Control` must always be accessible from the top menu, even on a new or unauthorized system.
- All normal software areas must stay blocked until the current device is approved by an admin.
- Admin can open `Admin Control`, log in, and approve/enable the current device from the same system.
- After approval, the app should continue into the normal flow without needing to create a new pad/well/report.

## Device access rules

- Identify the current system using:
  - MAC address
  - IP address
  - Hostname/device name
  - Installation ID
  - App version, if available
- Do not rely only on IP address because it can change.
- Backend must enforce device access, not only Flutter UI.
- Unauthorized devices should be able to call only:
  - device auth/check/register APIs
  - admin login/password/device approval APIs

## Admin password rules

- Admin page is password protected.
- Initial admin password setup is allowed only if no admin password exists.
- Admin password change requires:
  - current password
  - new password
  - confirm password
- Password must be changed every 30 days.
- If password is older than 30 days, show warning in `Admin Control`.
- Forgotten/reset password flow can be allowed maximum 2 times.
- Store only password hash on backend. Never store plain password.

## Admin Control page sections

1. Admin Login / Session
   - Login form
   - Logout
   - Session expiry message

2. Password Management
   - Last password changed date
   - Days remaining / expired warning
   - Current password
   - New password
   - Confirm password
   - Change password action

3. Current Device
   - MAC address
   - IP address
   - Hostname
   - Installation ID
   - Authorization status
   - Approve/enable current device after admin login

4. Device Access List
   - Device name
   - MAC address
   - IP address
   - Installation ID
   - Status: allowed / blocked / pending
   - Last seen
   - Enable / disable / delete actions

5. Security Logs
   - Admin login success/failure
   - Password changes
   - Device approvals/blocks
   - Unauthorized launch attempts

## Backend modules

- `AdminCredential` model
- `AuthorizedDevice` model
- `SecurityLog` model
- `adminControl.routes.js`
- `adminControl.controller.js`
- `deviceAuth.routes.js`
- `deviceAuth.controller.js`
- Device auth middleware for protected data routes

## Frontend modules

- `AdminControlView`
- `AdminControlController`
- `AdminControlApiService`
- Device identity service using existing installation identity where possible
- App startup access gate
- Top menu `Admin Control` entry that remains enabled even when unauthorized

## Implementation order

1. Done - Backend models and basic APIs.
2. Done - Flutter API endpoint constants and device identity payload.
3. Done - Admin Control UI shell available from top menu.
4. Done - Login/setup password flow.
5. Done - Current device approval flow.
6. Done - App access gate that blocks normal pages but leaves Admin Control open.
7. Done - Backend middleware for real API protection.
8. Done - Security logs and 30-day password warning.

## Remaining verification

- Run a full Flutter build after local Dart/Flutter tooling responds.
- Launch app with backend and verify:
  - new device opens only Admin Control
  - admin password can be created
  - admin login works
  - current device can be approved
  - normal tabs become available after approval
  - blocked device receives `DEVICE_NOT_AUTHORIZED` from normal APIs

## Important constraints

- Do not break old pad/well/report data loading.
- Do not force new pad/well/report creation after authorization.
- Do not block `Admin Control` on unauthorized systems.
- Do not expose admin password in logs or local storage.
