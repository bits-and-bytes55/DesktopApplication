class PremixModel {
  String? id; // MongoDB ID
  String description;
  String mw;
  String leasingFee;
  String mudType;
  bool tax;

  PremixModel({
    this.id,
    required this.description,
    required this.mw,
    required this.leasingFee,
    required this.mudType,
    this.tax = false,
  });

  // Convert from JSON
  factory PremixModel.fromJson(Map<String, dynamic> json) {
    return PremixModel(
      id: json['_id'] ?? json['id'],
      description: json['description'] ?? '',
      mw: json['mw'] ?? '',
      leasingFee: json['leasingFee'] ?? '',
      mudType: json['mudType'] ?? '',
      tax: json['tax'] ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'description': description,
      'mw': mw,
      'leasingFee': leasingFee,
      'mudType': mudType,
      'tax': tax,
    };
  }

  // Check if row is filled
  bool isFilled() {
    return description.isNotEmpty &&
           mw.isNotEmpty &&
           leasingFee.isNotEmpty &&
           mudType.isNotEmpty;
  }

  // Copy with method for updates
  PremixModel copyWith({
    String? id,
    String? description,
    String? mw,
    String? leasingFee,
    String? mudType,
    bool? tax,
  }) {
    return PremixModel(
      id: id ?? this.id,
      description: description ?? this.description,
      mw: mw ?? this.mw,
      leasingFee: leasingFee ?? this.leasingFee,
      mudType: mudType ?? this.mudType,
      tax: tax ?? this.tax,
    );
  }
}

class ObmModel {
  String? id; // MongoDB ID
  String product;
  String code;
  String sg;
  String conc;
  String unit;

  ObmModel({
    this.id,
    required this.product,
    required this.code,
    required this.sg,
    required this.conc,
    required this.unit,
  });

  // Convert from JSON
  factory ObmModel.fromJson(Map<String, dynamic> json) {
    return ObmModel(
      id: json['_id'] ?? json['id'],
      product: json['product'] ?? '',
      code: json['code'] ?? '',
      sg: json['sg'] ?? '',
      conc: json['conc'] ?? '',
      unit: json['unit'] ?? '',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'product': product,
      'code': code,
      'sg': sg,
      'conc': conc,
      'unit': unit,
    };
  }

  // Check if row is filled
  bool isFilled() {
    return product.isNotEmpty &&
           code.isNotEmpty &&
           sg.isNotEmpty &&
           conc.isNotEmpty;
  }

  // Copy with method for updates
  ObmModel copyWith({
    String? id,
    String? product,
    String? code,
    String? sg,
    String? conc,
    String? unit,
  }) {
    return ObmModel(
      id: id ?? this.id,
      product: product ?? this.product,
      code: code ?? this.code,
      sg: sg ?? this.sg,
      conc: conc ?? this.conc,
      unit: unit ?? this.unit,
    );
  }
}