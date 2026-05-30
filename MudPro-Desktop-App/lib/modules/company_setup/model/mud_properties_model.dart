class MudPropertyItem {
  final String name;
  final String unit;

  MudPropertyItem({required this.name, required this.unit});

  factory MudPropertyItem.fromJson(Map<String, dynamic> json) {
    return MudPropertyItem(
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MudPropertyItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          unit == other.unit;

  @override
  int get hashCode => name.hashCode ^ unit.hashCode;
}

class MudPropertiesStaticData {
  final List<MudPropertyItem> waterBased;
  final List<MudPropertyItem> oilBased;
  final List<MudPropertyItem> synthetic;

  MudPropertiesStaticData({
    required this.waterBased,
    required this.oilBased,
    required this.synthetic,
  });

  // ✅ Data updated with units from Excel
  static MudPropertiesStaticData get defaultData => MudPropertiesStaticData(
        waterBased: [
          MudPropertyItem(name: 'Flowline T.', unit: 'degF'),
          MudPropertyItem(name: 'Depth', unit: 'm'),
          MudPropertyItem(name: '*MW', unit: 'ppg'),
          MudPropertyItem(name: 'Funnel Visc.', unit: 'sec'),
          MudPropertyItem(name: 'T. for PV', unit: 'degF'),
          MudPropertyItem(name: '*PV', unit: 'cp'),
          MudPropertyItem(name: '*YP', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'Gel Str. 10s', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'Gel Str. 10m', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'Gel Str. 30m', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'API Filtrate', unit: 'ml'),
          MudPropertyItem(name: 'API Cake Thickness', unit: '1/32 in'),
          MudPropertyItem(name: 'T. for HTHP', unit: 'degF'),
          MudPropertyItem(name: 'HTHP Filtrate', unit: 'ml'),
          MudPropertyItem(name: 'HTHP Cake Thickness', unit: '1/32 in'),
          MudPropertyItem(name: '*Solids', unit: '% vol'),
          MudPropertyItem(name: '*Oil', unit: '% vol'),
          MudPropertyItem(name: '*Water', unit: '% vol'),
          MudPropertyItem(name: 'Sand Content', unit: '% vol'),
          MudPropertyItem(name: 'MBT Capacity', unit: 'ppb'),
          MudPropertyItem(name: 'pH', unit: '-'),
          MudPropertyItem(name: 'Mud Alkalinity', unit: 'ml'),
          MudPropertyItem(name: 'Filtrate Alkalinity (Pf)', unit: 'ml'),
          MudPropertyItem(name: 'Filtrate Alkalinity (Mf)', unit: 'ml'),
          MudPropertyItem(name: 'Calcium', unit: 'mg/l'),
          MudPropertyItem(name: '*Chlorides', unit: 'mg/l'),
          MudPropertyItem(name: 'Total Hardness', unit: 'mg/l'),
          MudPropertyItem(name: 'Excess Lime', unit: 'lb/bbl'),
          MudPropertyItem(name: 'K+', unit: '%'),
          MudPropertyItem(name: 'Make up Water: Chlorides', unit: 'mg/l'),
          MudPropertyItem(name: 'Solids Adjusted for Salt', unit: '% vol'),
        ],
        oilBased: [
          MudPropertyItem(name: 'Flowline T.', unit: 'degF'),
          MudPropertyItem(name: 'Depth', unit: 'm'),
          MudPropertyItem(name: '*MW', unit: 'ppg'),
          MudPropertyItem(name: 'Funnel Visc.', unit: 'sec'),
          MudPropertyItem(name: 'T. for PV', unit: 'degF'),
          MudPropertyItem(name: 'R600', unit: 'rpm'),
          MudPropertyItem(name: 'R300', unit: 'rpm'),
          MudPropertyItem(name: 'R200', unit: 'rpm'),
          MudPropertyItem(name: 'R100', unit: 'rpm'),
          MudPropertyItem(name: 'R6', unit: 'rpm'),
          MudPropertyItem(name: 'R3', unit: 'rpm'),
          MudPropertyItem(name: '*PV', unit: 'cp'),
          MudPropertyItem(name: '*YP', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'Gel Str. 10s', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'Gel Str. 10m', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'Gel Str. 30m', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'T. for HTHP', unit: 'degF'),
          MudPropertyItem(name: 'HTHP Filtrate', unit: 'ml'),
          MudPropertyItem(name: 'HTHP Cake Thickness', unit: '1/32 in'),
          MudPropertyItem(name: '*Solids', unit: '% vol'),
          MudPropertyItem(name: '*Oil', unit: '% vol'),
          MudPropertyItem(name: '*Water', unit: '% vol'),
          MudPropertyItem(name: 'Oil/water Ratio', unit: 'ratio'),
          MudPropertyItem(name: '*Alkalinity Mud (pom)', unit: 'ml'),
          MudPropertyItem(name: 'Excess Lime', unit: 'lb/bbl'),
          MudPropertyItem(name: '*Chlorides Whole Mud', unit: 'mg/l'),
          MudPropertyItem(name: 'Solids Adjusted for Salt (%)', unit: '% vol'),
          MudPropertyItem(name: 'Salt Content Water Phase (%)', unit: '% wt'),
          MudPropertyItem(name: 'WPS', unit: 'ppm'),
          MudPropertyItem(name: 'CaCl2 Wt. (%)', unit: '% wt'),
          MudPropertyItem(name: 'CaCl2', unit: 'mg/l'),
          MudPropertyItem(name: 'Brine Density', unit: 'ppg'),
          MudPropertyItem(name: 'Electrical Stability', unit: 'volts'),
          MudPropertyItem(name: 'Water Activity', unit: 'aw'),
          MudPropertyItem(name: 'Fine LCM', unit: 'lb/bbl'),
          MudPropertyItem(name: 'Coarse LCM', unit: 'lb/bbl'),
        ],
        synthetic: [
          MudPropertyItem(name: 'Flowline T.', unit: 'degF'),
          MudPropertyItem(name: 'Depth', unit: 'm'),
          MudPropertyItem(name: '*MW', unit: 'ppg'),
          MudPropertyItem(name: 'Funnel Visc.', unit: 'sec'),
          MudPropertyItem(name: 'T. for PV', unit: 'degF'),
          MudPropertyItem(name: '*PV', unit: 'cp'),
          MudPropertyItem(name: '*YP', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'Gel Str. 10s', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'Gel Str. 10m', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'Gel Str. 30m', unit: 'lb/100ft²'),
          MudPropertyItem(name: 'T. for HTHP', unit: 'degF'),
          MudPropertyItem(name: 'HTHP Filtrate', unit: 'ml'),
          MudPropertyItem(name: 'HTHP Cake Thickness', unit: '1/32 in'),
          MudPropertyItem(name: '*Solids (%)', unit: '% vol'),
          MudPropertyItem(name: '*Oil (%)', unit: '% vol'),
          MudPropertyItem(name: '*Water (%)', unit: '% vol'),
          MudPropertyItem(name: 'Oil/water Ratio', unit: 'ratio'),
          MudPropertyItem(name: '*Alkalinity Mud (pom)', unit: 'ml'),
          MudPropertyItem(name: 'Excess Lime', unit: 'lb/bbl'),
          MudPropertyItem(name: '*Chlorides Whole Mud', unit: 'mg/l'),
          MudPropertyItem(name: 'Solids Adjusted for Salt (%)', unit: '% vol'),
          MudPropertyItem(name: 'Salt Content Water Phase (%)', unit: '% wt'),
          MudPropertyItem(name: 'WPS', unit: 'ppm'),
          MudPropertyItem(name: 'CaCl2 Wt. (%)', unit: '% wt'),
          MudPropertyItem(name: 'CaCl2', unit: 'mg/l'),
          MudPropertyItem(name: 'NaCl2 Wt. (%)', unit: '% wt'),
          MudPropertyItem(name: 'NaCl2', unit: 'mg/l'),
          MudPropertyItem(name: 'Brine Density', unit: 'ppg'),
          MudPropertyItem(name: 'Electrical Stability', unit: 'volts'),
          MudPropertyItem(name: 'Water Activity', unit: 'aw'),
          MudPropertyItem(name: 'Fine LCM', unit: 'lb/bbl'),
          MudPropertyItem(name: 'Coarse LCM', unit: 'lb/bbl'),
        ],
      );
}

class SelectedMudProperties {
  final List<MudPropertyItem> waterBased;
  final List<MudPropertyItem> oilBased;
  final List<MudPropertyItem> synthetic;

  SelectedMudProperties({
    required this.waterBased,
    required this.oilBased,
    required this.synthetic,
  });

  factory SelectedMudProperties.fromJson(Map<String, dynamic> json) {
    return SelectedMudProperties(
      waterBased: (json['waterBased'] as List?)
              ?.map((e) => MudPropertyItem.fromJson(e))
              .toList() ??
          [],
      oilBased: (json['oilBased'] as List?)
              ?.map((e) => MudPropertyItem.fromJson(e))
              .toList() ??
          [],
      synthetic: (json['synthetic'] as List?)
              ?.map((e) => MudPropertyItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'waterBased': waterBased.map((e) => e.toJson()).toList(),
        'oilBased': oilBased.map((e) => e.toJson()).toList(),
        'synthetic': synthetic.map((e) => e.toJson()).toList(),
      };

  SelectedMudProperties copyWith({
    List<MudPropertyItem>? waterBased,
    List<MudPropertyItem>? oilBased,
    List<MudPropertyItem>? synthetic,
  }) {
    return SelectedMudProperties(
      waterBased: waterBased ?? this.waterBased,
      oilBased: oilBased ?? this.oilBased,
      synthetic: synthetic ?? this.synthetic,
    );
  }
}
