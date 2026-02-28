class MudPropertiesStaticData {
  final List<String> waterBased;
  final List<String> oilBased;
  final List<String> synthetic;

  MudPropertiesStaticData({
    required this.waterBased,
    required this.oilBased,
    required this.synthetic,
  });

  // ✅ All static data hardcoded - no API call needed
  static MudPropertiesStaticData get defaultData => MudPropertiesStaticData(
        waterBased: [
          'Flowline T.',
          'Depth',
          '*MW',
          'Funnel Visc.',
          'T. for PV',
          '*PV',
          '*YP',
          'Gel Str. 10s',
          'Gel Str. 10m',
          'Gel Str. 30m',
          'API Filtrate',
          'API Cake Thickness',
          'T. for HTHP',
          'HTHP Filtrate',
          'HTHP Cake Thickness',
          '*Solids',
          '*Oil',
          '*Water',
          'Sand Content',
          'MBT Capacity',
          'pH',
          'Mud Alkalinity',
          'Filtrate Alkalinity',
          'Filtrate Alkalinity',
          'Calcium',
          '*Chlorides',
          'Total Hardness',
          'Excess Lime',
          'K+',
          'Make up Water: Chlorides',
          'Solids Adjusted for Salt',
          'Fine LCM',
          'Coarse LCM',
        ],
        oilBased: [
          'Flowline T.',
          'Depth',
          '*MW',
          'Funnel Visc.',
          'T. for PV',
          '*PV',
          '*YP',
          'Gel Str. 10s',
          'Gel Str. 10m',
          'Gel Str. 30m',
          'T. for HTHP',
          'HTHP Filtrate',
          'HTHP Cake Thickness',
          '*Solids',
          '*Oil',
          '*Water',
          'Oil/water Ratio',
          '*Alkalinity Mud (pom)',
          'Excess Lime',
          '*Chlorides Whole Mud',
          'Solids Adjusted for Salt (%)',
          'Salt Content Water Phase (%)',
          'WPS',
          'CaCl2 Wt. (%)',
          'CaCl2',
          'Brine Density',
          'Electrical Stability',
          'Water Activity',
          'Fine LCM',
          'Coarse LCM',
        ],
        synthetic: [
          'Flowline T.',
          'Depth',
          '*MW',
          'Funnel Visc.',
          'T. for PV',
          '*PV',
          '*YP',
          'Gel Str. 10s',
          'Gel Str. 10m',
          'Gel Str. 30m',
          'T. for HTHP',
          'HTHP Filtrate',
          'HTHP Cake Thickness',
          '*Solids (%)',
          '*Oil (%)',
          '*Water (%)',
          'Oil/water Ratio',
          '*Alkalinity Mud (pom)',
          'Excess Lime',
          '*Chlorides Whole Mud',
          'Solids Adjusted for Salt (%)',
          'Salt Content Water Phase (%)',
          'WPS',
          'CaCl2 Wt. (%)',
          'CaCl2',
          'NaCl2 Wt. (%)',
          'NaCl2',
          'Brine Density',
          'Electrical Stability',
          'Water Activity',
          'Fine LCM',
          'Coarse LCM',
        ],
      );
}

class SelectedMudProperties {
  final List<String> waterBased;
  final List<String> oilBased;
  final List<String> synthetic;

  SelectedMudProperties({
    required this.waterBased,
    required this.oilBased,
    required this.synthetic,
  });

  factory SelectedMudProperties.fromJson(Map<String, dynamic> json) {
    return SelectedMudProperties(
      waterBased: List<String>.from(json['waterBased'] ?? []),
      oilBased: List<String>.from(json['oilBased'] ?? []),
      synthetic: List<String>.from(json['synthetic'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'waterBased': waterBased,
        'oilBased': oilBased,
        'synthetic': synthetic,
      };

  SelectedMudProperties copyWith({
    List<String>? waterBased,
    List<String>? oilBased,
    List<String>? synthetic,
  }) {
    return SelectedMudProperties(
      waterBased: waterBased ?? this.waterBased,
      oilBased: oilBased ?? this.oilBased,
      synthetic: synthetic ?? this.synthetic,
    );
  }
}