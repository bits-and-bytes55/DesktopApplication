# TODO - Shaker Table Dropdown Implementation

## Task: Add dropdown for "No. of Screen" in SCE View and connect with Pump Tab

### Files modified:
1. [x] sce_view.dart - Added dropdown (1-8) for "No. of Screen" column
2. [x] sce_controller.dart - Added getScreensByModel method
3. [x] pump_tab_content.dart - Changed to use per-row model-based calculation for screen cols

### Implementation Summary:
1. ✅ sce_view.dart: Added `_screensDropdownCell` widget with dropdown (1-8 options)
2. ✅ sce_controller.dart: Added `getScreensByModel(String model)` method to get screens count per model
3. ✅ pump_tab_content.dart: Changed from global `maxScreenCols` to per-row calculation using `getScreensByModel(shaker.model.value)`

### How it works:
- In SCE View: User clicks on "No. of Screen" cell → dropdown appears with options 1-8
- In Pump Tab: When a model is selected, the number of editable screen columns is determined by that model's "screens" value from SCE data
- If model has 5 screens selected in SCE → only 5 screen columns are editable in Pump Tab
