# Task: Fetch Inventory Data in dailycost_table_usage.dart

## Completed Tasks:

### 1. Created inventory_snapshot_controller.dart
- Location: `MudPro-Desktop-App/lib/modules/daily_report/controller/inventory_snapshot_controller.dart`
- Methods:
  - `getInventorySnapshot()` - fetches inventory data from GET `/api/inventory/`
  - `generateInventorySnapshot()` - generates snapshot using POST `/api/inventory/generate`

### 2. Updated dailycost_table_usage.dart
- Location: `MudPro-Desktop-App/lib/modules/daily_report/tabs/daily_cost/tabs/dailycost_table_usage.dart`
- Added import for controller
- Added state variables: `_inventoryData`, `_isLoading`
- Added `_fetchInventoryData()` method that calls generate and get APIs on init
- Data is now fetched dynamically from the backend inventory controller

### Notes:
- UI remains unchanged as per user requirement
- Data is fetched on page load and stored in `_inventoryData`
- The `_inventoryData` list can be used to populate table rows dynamically
