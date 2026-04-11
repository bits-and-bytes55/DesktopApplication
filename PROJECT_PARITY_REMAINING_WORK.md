# New Project vs Old App Remaining Work

Date: 2026-04-11

## Comparison Basis

This note is based on:

- Current frontend/backend code in this project
- Old desktop artifacts available in:
  - `C:\Users\ManojThakur\Desktop\New Project\desktop_app_unpacked.xml`
  - `C:\Users\ManojThakur\Desktop\New Project\desktop app.mud`
  - `C:\Users\ManojThakur\Desktop\New Project\DMR-Proto-Type -R2.0.xlsm`

Because the old app source is not available as normal Flutter code, parity status below is an implementation-level estimate based on current working flow, old artifact labels, and existing UI/report structure.

## Overall Status

- Estimated overall old-app parity done: about `55% to 65%`
- Estimated remaining work: about `35% to 45%`
- Core input/workflow modules are much further along than report/export modules

Rough split:

- Core operational/input side: about `70% to 80%` done
- Daily report/report-output/export side: about `35% to 45%` done

## Already Done or Close to Done

### Core workflow area

- Pad / Well / Report selection context is working
- Major input flow for `mud`, `pump`, `operation`, `pit` has already been carried forward
- Pump page overflow/UI issue was fixed
- Report-linked data flow has been improved in multiple places

### Detail report area

- Geometry is live from current project data
- Volume snapshot flow is connected
- Circulation / annular hydraulics is live
- Solids analysis is live
- Bit hydraulics is live

### Alert area

- Alert summary is live
- Alert usage chart is live
- Alert inventory page is live
- Alert table/prediction page is live from inventory snapshot

### Concentration area

- Concentration current table is now live from UG inventory snapshot
- Concentration graph is now live
- Concentration report reference/history view is added

## Partial Modules

These areas exist, but are not yet fully same-to-same with old app behavior.

### 1. Concentration history parity

- Current concentration page is live
- But true historical concentration by report/system is not fully available yet
- Current history tab is a report-reference view, not true archived concentration history
- Reason: backend does not yet store full report-wise concentration history snapshots

### 2. Alert prediction parity

- Alert pages are live
- But forward usage is still mostly derived from current snapshot usage
- True old-app style multi-day historical prediction logic still needs matching if old app had deeper usage history formulas

### 3. Daily cost usage table

- Inventory snapshot-backed usage table exists
- But full old-app parity across all daily cost tabs/charts/totals still not complete

### 4. WBM/Excel export

- Export path exists in code
- Backend Excel export controller exists
- But report generation is currently failing and still needs debugging

## Major Remaining Work

## Priority 1: Report Output / Export Blockers

### A. Excel / WBM Report Generation

Current state:

- Export flow exists in frontend and backend
- User-facing report generation is failing right now

Remaining work:

- Verify frontend request/response flow
- Verify backend export endpoint response
- Verify template loading and workbook generation
- Verify selected report data is correctly included
- Verify downloaded file opens correctly every time

This is an immediate blocker because export/report parity is a major old-app function.

### B. Report Menu Items Still Placeholder

These report menu entries are not yet implemented same-to-same:

- Daily Report
- Detail Report
- Safety Card
- Hydraulics Report
- WITSML Report
- Export to HYDPRO

Current state:

- UI/menu entries are present
- Most of them still show placeholder content or incomplete routing

## Priority 2: Daily Report Sidebar Modules Still Incomplete

### A. Daily Cost module

Current state:

- `table usage` has live inventory snapshot linkage
- Product chart page still uses static sample values
- Others chart page still uses static sample values
- Percentage/table side still needs parity verification and likely live wiring

Remaining work:

- Replace static product chart with live category/product cost data
- Replace static others chart with real service/engineering/package cost data
- Match old app formulas and grouping
- Match totals/subtotals/tax/cumulative behavior report-wise

### B. Total Cost module

Current state:

- Current table still has sample rows and sample amounts
- Not fully live from backend/report history

Remaining work:

- Build live total cost history dataset by report
- Match product/premixed/package/service/engineering totals
- Match subtotal/tax/total/cumulative values with old app
- Build chart from real report history

### C. Time Distribution module

Current state:

- Current table is local/static/manual sample data
- Graph/table is not old-app parity yet

Remaining work:

- Add backend persistence for time distribution rows
- Make table report-linked
- Make graph read real time distribution values
- Match totals/percent formulas to old app

### D. Survey module

Current state:

- Survey pages exist
- Actual/planned tables are still static/manual style
- Full report-linked survey parity is not complete

Remaining work:

- Connect actual survey rows to real survey source data
- Connect planned survey rows
- Connect graph and 3D graph to real survey data
- Match calculations like TVD, Vsec, N/S, E/W, dogleg to old app output

## Priority 3: Backend Data Gaps for Full Parity

Full parity still needs backend support in some areas:

- Report-wise concentration history storage
- Report-wise time distribution storage
- Survey storage and retrieval if not already complete
- Report-wise total cost history aggregation
- More complete export/report aggregation logic
- Possibly PDF/Safety/WITSML specific output endpoints

Without these backend pieces, some frontend tabs can look correct but still cannot become true old-app parity.

## Priority 4: Cross-Checking Against Old App Calculations

Even where modules are now working, parity still needs formula-by-formula validation.

Still required:

- Compare old app output vs new app output on same well/report
- Verify bit hydraulics numbers
- Verify circulation totals and pressure-loss breakdowns
- Verify solids analysis values
- Verify concentration values
- Verify daily cost and total cost values
- Verify export sheets against old `.xlsm` output

This step is mandatory before calling the migration complete.

## Priority 5: Final QA / UI / Regression Pass

Before project can be treated as old-app equivalent:

- Check all tabs with real data
- Check multiple wells and multiple reports
- Check layout overflow on desktop sizes
- Check state refresh when changing report/well
- Check export/download/open behavior
- Check empty-state behavior
- Check error handling for missing backend data

## Module-by-Module Status Snapshot

### Near parity / usable

- Well / report context
- Mud
- Pump
- Operation
- Pit
- Geometry
- Volume snapshot
- Circulation hydraulics
- Solids analysis
- Bit hydraulics
- Alert
- Concentration current/graph

### Partial / still needs parity work

- Concentration history
- Alert prediction depth/history logic
- Daily cost
- WBM / Excel export

### Mostly pending

- Total cost
- Time distribution
- Survey
- Daily Report output
- Detail Report output
- Safety Card
- Hydraulics Report output
- WITSML Report output
- Export to HYDPRO
- Utilities / Help real functionality

## Best Current Estimate of Remaining Scope

If we count old-app parity as the finish line, the biggest remaining chunks are:

1. Report/export layer completion
2. Daily cost + total cost parity
3. Survey parity
4. Time distribution parity
5. Backend storage support for history-style report tabs
6. End-to-end calculation validation against old app

## Suggested Execution Order

Recommended next order after this note:

1. Fix Excel / WBM export generation
2. Finish Daily Cost live parity
3. Finish Total Cost live parity
4. Finish Time Distribution
5. Finish Survey
6. Implement remaining report outputs: Daily Report, Detail Report, Safety Card, Hydraulics, WITSML, HYDPRO export
7. Run full comparison test against old app

## Bottom Line

The new project is no longer at the starting stage. Core workflow migration has moved forward well, but full old-desktop parity is still not complete. The biggest unfinished side is no longer the basic input modules; it is the report, history, export, and validation layer.
