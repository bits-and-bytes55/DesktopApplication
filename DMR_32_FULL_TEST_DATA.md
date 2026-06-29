# DMR 32 - Full Application Test Data

Reference: `DMR 32 KOC-UQDF MG-0377 _UPDC-880 26-June-2026.xlsx`

Use report date `26-Jun-2026` and report number `32`.

## 1. Pad / Well Setup

Enter this data in Pad and Well setup:

| Field | Value |
|---|---|
| Project ID | Use the active project ID |
| Well Name | MG-0377 |
| Rig Name | UPDC-880 |
| Field/Block | Magwa |
| Location/State | South Kuwait |
| Operator | Kuwait Oil Company |
| Contractor | UPDC |
| Operator Representatives | Abdur Rahman Khan / Dauren Zhakuda |
| Contractor Representatives | Nitesh / Yakut |
| Spud Date | 26-May-2026 |
| Formation | Ratawi limestone |
| MD | 7137 ft |
| TVD | 7137 ft |
| Activity | Drilling |
| Bit Depth | 7137 ft |
| Fluid Name | OBM 80/20 |
| Fluid Type | Oil-based |

## 2. Well - Cased Hole / Open Hole

Enter in `Report > Well`:

| Type | OD (in) | Shoe MD (ft) |
|---|---:|---:|
| Conductor | 40.000 | 60.0 |
| Surface casing | 30.000 | 324.0 |
| Cased 1 | 24.000 | 3857.0 |
| Cased 2 | 18.625 | 6013.0 |
| 16" open hole | 16.000 | 7137.0 |

## 3. Well - Drill String

Enter in `Report > Well > Drill String` in this order:

| Description | OD (in) | ID (in) | Length (ft) |
|---|---:|---:|---:|
| DP | 5.500 | 4.670 | 6407.2 |
| 5 1/2" HWDP | 5.500 | 4.000 | 92.0 |
| 6 5/8" HWDP | 6.625 | 4.500 | 94.6 |
| 8 1/4" DC | 8.250 | 2.810 | 92.5 |
| 8" DRILLING JAR | 8.000 | 2.750 | 17.1 |
| 8 1/4" DC | 8.250 | 2.750 | 93.1 |
| 10" DC | 10.000 | 3.000 | 279.3 |
| 15 7/8" STRING STAB | 15.400 | 3.000 | 7.0 |

The first six generated hydraulic Type columns should be:

1. `17.239 x 5.500 x 4.670`
2. `16.000 x 5.500 x 4.670`
3. `16.000 x 5.500 x 4.000`
4. `16.000 x 6.625 x 4.500`
5. `16.000 x 8.250 x 2.810`
6. `16.000 x 8.000 x 2.750`

## 4. Well - Bit and Nozzles

| Field | Value |
|---|---|
| Bit Type | TFR716 |
| Bit Model | NOV |
| Bit Size | 16.000 in |
| Nozzle Count | 9 |
| Nozzle Size | 16 (1/32 in) |
| Expected TFA | 1.767 in2 |

## 5. Well - General / Drilling Parameters

| Field | Value |
|---|---:|
| Rotary | 140 rpm |
| ROP | 23 ft/hr |
| Weight on Bit | 30,000 lbf |
| Pick Up Weight | Enter report value if available |
| Slack Off Weight | Enter report value if available |
| On-Bottom Rotate Weight | Enter report value if available |
| Off-Bottom Rotate Weight | Enter report value if available |
| Bottom Hole Circulating Temperature | Enter report value if available |
| Pump Pressure | 3450 psi |
| Pump Rate | 1100 gpm |

## 6. Pit - Active System

| Pit | Volume (bbl) | Density | Fluid Type |
|---|---:|---:|---|
| Sand Trap | 140.00 | 12.80 | OBM 80/20 |
| Degasser | 163.00 | 12.80 | OBM 80/20 |
| Desilter | 150.00 | 12.80 | OBM 80/20 |
| Intermediate 1 | 160.00 | 12.80 | OBM 80/20 |
| Suction 1 | 140.00 | 12.80 | OBM 80/20 |
| Suction 2 | 132.59 | 12.80 | OBM 80/20 |

## 7. Pit - Reserve

| Pit | Volume (bbl) | Density | Fluid Type |
|---|---:|---:|---|
| Intermediate 2 | 73.00 | 12.80 | OBM 80/20 |
| Intermediate 3 | 200.00 | 12.80 | 40 ppb LCM |
| Suction 3 | 50.00 | 12.80 | Hi-Vis |
| Slug Tank | 20.00 | 14.60 | Slug |
| Reserve 1A | 98.00 | 12.80 | OBM 80/20 |
| Reserve 1B | 19.00 | 16.00 | OBM 80/20 |
| Reserve 1C | 144.00 | 12.80 | OBM 80/20 |

## 8. Mud Properties - Oil Based

Use three samples in `Report > Mud`.

| Property | Sample 1 | Sample 2 | Sample 3 | Plan |
|---|---:|---:|---:|---|
| Description | OBM 80/20 | OBM 80/20 | OBM 80/20 | |
| Sample From | Flow Line | Flow Line | Suction | |
| Time | 23:30 | 16:00 | 06:00 | |
| Flowline Temperature | 145 | 140 | | |
| Depth | 7130 | 7018 | 6980 | |
| MW | 12.80 | 12.40 | 12.00 | 10.50-16.30 |
| Funnel Viscosity | 55 | 54 | 53 | |
| Temperature for PV | 150 | 150 | 150 | |
| PV | 25 | 24 | 24 | 15-50 |
| YP | 18 | 17 | 16 | 12-20 |
| R600 | 68 | 65 | 64 | |
| R300 | 43 | 41 | 40 | |
| R200 | 26 | 25 | 25 | |
| R100 | 22 | 21 | 21 | |
| R6 | 8 | 8 | 8 | |
| R3 | 7 | 7 | 7 | |
| Gel 10 sec | 9 | 8 | 8 | |
| Gel 10 min | 16 | 15 | 15 | |
| Gel 30 min | 21 | 20 | 20 | |
| Temperature for HTHP | 300 | 300 | 300 | 300 |
| HTHP Filtrate | 3.80 | 4.00 | 3.80 | 3-5 |
| HTHP Cake Thickness | 1 | 1 | 1 | 1 |
| Solids | 22.2 | 20.8 | 19.5 | |
| Oil | 62.0 | 63.3 | 64.7 | |
| Water | 15.8 | 15.9 | 15.8 | |
| Oil/Water Ratio | 80/20 | 80/20 | 80/20 | |
| Alkalinity Mud (POM) | 3.60 | 3.80 | 3.80 | |
| Chlorides Whole Mud | 31000 | 29000 | 30000 | |
| Electrical Stability | 824 | 806 | 768 | 700-950 |

Expected calculated mud-property outputs:

| Property | Sample 1 | Sample 2 | Sample 3 |
|---|---:|---:|---:|
| Excess Lime | 4.66 | 4.92 | 4.92 |
| Solids Adjusted for Salt | 20.3 | 19.0 | 17.7 |
| Salt Content Water Phase | 24.4 | 23.1 | 23.8 |
| WPS | 244337 | 231111 | 238334 |
| Brine Density | 9.87 | 9.77 | 9.82 |
| Brine Content | 17.7 | 17.7 | 17.6 |

Specific Gravity:

| Field | Value |
|---|---:|
| Oil SG | 0.84 |
| LGS SG | 2.60 |
| HGS SG | 4.20 |

## 9. Expected Solids Analysis

| Property | Sample 1 | Sample 2 | Sample 3 |
|---|---:|---:|---:|
| Brine Density | 9.87 | 9.77 | 9.82 |
| Brine % | 17.7 | 17.7 | 17.6 |
| LGS % | 3.1 | 3.2 | 3.5 |
| LGS lb/bbl | 27.81 | 29.02 | 31.85 |
| HGS % | 17.2 | 15.8 | 14.2 |
| HGS lb/bbl | 253.49 | 232.42 | 208.74 |
| Average SG Solids | 3.96 | 3.93 | 3.88 |

## 10. Pump

Enter three pumps:

| Pump | Liner ID | Stroke Length | Efficiency | Stroke/Min |
|---|---:|---:|---:|---:|
| 1 | 5.000 | 12.000 | 97.0 | 74 |
| 2 | 5.000 | 12.000 | 97.0 | 74 |
| 3 | 5.000 | 12.000 | 97.0 | 74 |

Expected displacement for each pump: `0.1179 bbl/stroke`.

## 11. SCE

Enter in `Report > SCE`:

| Type | Info/API Number | Hours |
|---|---|---:|
| Shaker 1 | 100/100/100/100 | 13 |
| Shaker 2 | 100/100/100/100 | 13 |
| Shaker 3 | 100/100/100/100 | 13 |
| Shaker 4 | 100/100/100/100 | 13 |
| Cleaner | 120/120/120/120 | 13 |

## 12. Operation / Volume Transactions

Create these report operations:

| Operation | Daily Volume |
|---|---:|
| Receive Whole Mud | 450.00 bbl |
| Add Water | 10.00 bbl |
| Product Addition | 6.16 bbl |
| Weight Material Addition | 20.40 bbl |
| Receive from Reserve/Other | 98.00 bbl |
| Transfer to Reserve/Other | 435.00 bbl |
| Shakers/Hydroclones Loss | 3.00 bbl |
| Cuttings Retention Loss | 39.00 bbl |
| Evaporation Loss | 15.00 bbl |
| Tripping Loss | 7.00 bbl |

Expected daily totals:

| Output | Value |
|---|---:|
| Total Additions | 584.56 bbl |
| Total Losses | 64.00 bbl |
| Final Active Volume | 2800.21 bbl |
| Active Pit Volume | 885.59 bbl |
| Annular Volume | 1771.09 bbl |
| Drillstring Volume | 143.53 bbl |
| Downhole Volume | 1914.62 bbl |
| Total Circulation Volume | 2800.21 bbl |
| Reserve Volume | 3078.00 bbl |
| Total Fluid at Rigsite | 5878.21 bbl |

## 13. Inventory Products Used Today

Ensure these products exist in Inventory, enable Plot, then consume:

| Product | Unit | Price (KWD) | Daily Used | Cum. Used |
|---|---|---:|---:|---:|
| BARITE - 4.2 SG BULK | 1.00 Ton | 72.000 | 15.00 | 408.00 |
| MAXLIG | 50.00 lb | 21.000 | 34.00 | 90.00 |
| MAXWET XL | 55.00 gal | 142.000 | 1.00 | 4.00 |
| 18.7ppg OBM (95/5) with 4.2SG | 1.00 bbl | 26.669 | 450.00 | 1700.00 |

Expected daily product cost: `13937.050 KWD`.

Other products required to check the complete inventory export:

`CALCIUM CHLORIDE GRAN`, `CAUSTIC SODA`, `Chrome Free Ligno Sulphonate`,
`CITRIC ACID`, `MAXSWEEP`, `MICA COARSE`, `MICA FINE`, `MICA MEDIUM`,
`NUTSHELLS COARSE`, `NUTSHELLS FINE`, `NUTSHELLS MEDIUM`,
`POTASSIUM CHLORIDE`, `QDEFOAM S`, `QSCAV H2S`, `QSTAR MT`, `QXAN`,
`SIZED CALCIUM CARBONATE`, `SODA ASH`, `SODIUM BICARBONATE`, `WELLKLEEN`,
`ZINC CARBONATE`, `Lime`, `STRATALUBE`, `MAXPHALT L`, `Diesel`, `QCIDE T`,
`QPAC HV`, `QPAC LV`, `GILSONITE AQUASOL 300`, `MAXCAP L`, `QSTAR HT`,
`DRILLING DETERGENT`, `Heavy Duty Crane services`, `COTTON SEED HULL`,
`Bentonite - API Grade Sec 9`, `MAXRELEASE W`, `QMAXCOAT`, `QSCAV O2`,
`GS SEAL`, `MARBLE SIZED`, `LCM MIX COARSE`, `LCM MIX FINE`,
`LCM MIX MEDIUM`, `MAGMA FIBER FINE`, `QMAXTHIN`.

## 14. Engineering

| Engineering | Daily Qty | Cumulative Qty | Daily Cost |
|---|---:|---:|---:|
| Mud Supervisor-Deep-1 | 1.00 | 26.00 | 180.000 KWD |

Expected daily engineering cost: `180.000 KWD`.

## 15. Remarks

Recommended Treatment:

```text
* Received & charged 450 bbls 18.7 ppg OBM, OWR 95/5, with 4.2 SG BARITE.
* Weighed up the active system with 16 ppg OBM, OWR 80/20, 4.2 SG barite from 12.0 ppg to 12.8 ppg in stages.
* Recorded 9.7 ppg last pore pressure.
* Treated active system with 0.66 ppb MAXLIG to control HTHP fluid loss below 4 ml.
* Keep checking shaker screens for damage on each connection and replace damaged screens.
* Weight up reserve mud to 12.8 ppg with bulk barite and add MAXWET XL as wetting agent.
* Keep adding 1 bbl/hr water while drilling the 16 inch section to compensate evaporation.
* Received chemicals as per inventory.
* Circulated 18.7 ppg OBM in the MMP, each tank for one hour every 12 hours.
* Barite 4.2 SG bulk stock: 388 MT. Diesel stock: 625 bbl.
```

Operational Comments:

```text
Pulled out 16 inch rotary stiff BHA with NOV PDC bit to surface.
Observed a nut bolt stuck in the bit after POOH.
Ran in hole with 16 inch rotary stiff BHA to 6,980 ft.
Drilled 16 inch hole from 6,980 ft to 7,137 ft with full returns.
WOB 20-40 klb, RPM 140, torque 5-19 kft-lb, flow rate 1000-1100 gpm,
SPP 2900-3450 psi and average ROP 23 ft/hr.
Increased mud weight gradually from 12.0 ppg to 12.8 ppg.
Observed intermittent torque spike.
Next operation: POOH to surface, then RIH with directional BHA and drill to section TD.
```

## 16. Expected Hydraulics Output

These are calculated/export outputs, not manual inputs:

| Output | Seg 1 | Seg 2 | Seg 3 | Seg 4 | Seg 5 | Seg 6 |
|---|---:|---:|---:|---:|---:|---:|
| Length | 6013.0 | 394.2 | 92.0 | 94.6 | 92.5 | 17.1 |
| Annular Velocity | 101.0 | 119.4 | 119.4 | 127.1 | 143.5 | 140.4 |
| Critical Velocity | 223.5 | 229.6 | 229.6 | 235.8 | 246.5 | 244.7 |
| DS Velocity | 20.6 | 20.6 | 28.1 | 22.2 | 56.9 | 59.4 |
| DS Pressure Loss | 1445 | 1540 | 1586 | 1614 | 1866 | 1917 |
| Annular Pressure Loss | 48 | 4 | 1 | 1 | 1 | 0 |

Additional expected outputs:

| Output | Value |
|---|---|
| Total Pressure Loss | 3495 psi |
| Bit Loss | 457 / 13.1% |
| DS Loss | 2862 / 81.9% |
| Annular Loss | 176 / 5.0% |
| ECD at Shoe | 12.95 ppg |
| ECD at TD | 13.27 ppg |
| ESD at Shoe | 12.80 ppg |
| ESD at TD | 12.80 ppg |
| Bit Jet Velocity | 200 ft/s |
| Bit HHP / HSI | 293.2 / 1.46 |
| PV / YP | 25.0 / 18.0 |

## 17. Final Export Checks

Generate both reports and verify:

1. DMR header and both logos.
2. All six Rheology/Hydraulics Type columns.
3. Strokes and Minutes headings.
4. DMR mud properties and solids analysis.
5. Pressure loss, ECD/ESD and bit hydraulic outputs.
6. Pump, SCE, active pits and reserve pits.
7. Recommended Treatment and Operational Comments.
8. Inventory report products, cumulative quantities and concentration columns.
9. Daily Product Cost `13937.050 KWD`.
10. Daily Engineering Cost `180.000 KWD`.
