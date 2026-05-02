class ProductModel {
  String? id;
  String product;
  String code;
  String sg;
  String unitNum;
  String unitClass;
  String group;
  String retail;
  String a;
  String b;
  String price;
  String initial;
  bool volAdd;
  bool calculate;
  bool plot;
  bool tax;
  bool isSelected;
  bool isDeleted;
  DateTime? createdAt;
  DateTime? updatedAt;

  String get formattedUnit => unitNum.isEmpty && unitClass.isEmpty 
    ? "" 
    : "${unitNum.trim()} ${unitClass.trim()}".trim();

  ProductModel({
    this.id,
    this.product = '',
    this.code = '',
    this.sg = '',
    this.unitNum = '',
    this.unitClass = '',
    this.group = '',
    this.retail = '',
    this.a = '',
    this.b = '',
    this.price = '',
    this.initial = '',
    this.volAdd = false,
    this.calculate = false,
    this.plot = false,
    this.tax = false,
    this.isSelected = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for API (single product)
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'Product': product.trim(),
      'Code': code.trim(),
      'SG': sg.trim(),
      'Unit': {
        'Num': unitNum.trim(),
        'Class': unitClass.trim(),
      },
      'Group': group.trim(),
      'Retail': retail.trim(),
    };

    // Add optional fields only if they have values
    if (a.trim().isNotEmpty) {
      json['A'] = a.trim();
    }
    if (b.trim().isNotEmpty) {
      json['B'] = b.trim();
    }

    return json;
  }

  // Convert from API response
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final unit = _parseProductUnit(json['Unit'] ?? json['unit']);
    return ProductModel(
      id: json['_id'],
      product: json['Product'] ?? '',
      code: json['Code'] ?? '',
      sg: json['SG']?.toString() ?? '',
      unitNum: unit['num'] ?? '',
      unitClass: unit['class'] ?? '',
      group: json['Group'] ?? '',
      retail: json['Retail'] ?? '',
      a: json['A']?.toString() ?? '',
      b: json['B']?.toString() ?? '',
      price: json['A']?.toString() ?? json['A']?.toString() ?? '',
      initial: json['initial']?.toString() ?? json['Initial']?.toString() ?? '',
      volAdd: json['volAdd'] ?? false,
      calculate: json['calculate'] ?? false,
      plot: json['plot'] ?? false,
      tax: json['tax'] == true || json['tax'] == 'true', // Handle both bool and string
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  // Check if product has any data
  bool hasData() {
    return product.trim().isNotEmpty ||
           code.trim().isNotEmpty ||
           sg.trim().isNotEmpty ||
           unitNum.trim().isNotEmpty ||
           unitClass.trim().isNotEmpty ||
           group.trim().isNotEmpty ||
           retail.trim().isNotEmpty ||
           a.trim().isNotEmpty ||
           b.trim().isNotEmpty;
  }

  // Check if product is valid (all required fields filled)
  bool isValid() {
    return product.trim().isNotEmpty &&
           code.trim().isNotEmpty &&
           sg.trim().isNotEmpty &&
           unitNum.trim().isNotEmpty &&
           unitClass.trim().isNotEmpty &&
           group.trim().isNotEmpty;
  }

  // Create a copy
  ProductModel copyWith({
    String? id,
    String? product,
    String? code,
    String? sg,
    String? unitNum,
    String? unitClass,
    String? group,
    String? retail,
    String? a,
    String? b,
  }) {
    return ProductModel(
      id: id ?? this.id,
      product: product ?? this.product,
      code: code ?? this.code,
      sg: sg ?? this.sg,
      unitNum: unitNum ?? this.unitNum,
      unitClass: unitClass ?? this.unitClass,
      group: group ?? this.group,
      retail: retail ?? this.retail,
      a: a ?? this.a,
      b: b ?? this.b,
    );
  }

  // Clear all fields
  void clear() {
    product = '';
    code = '';
    sg = '';
    unitNum = '';
    unitClass = '';
    group = '';
    retail = '';
    a = '';
    b = '';
  }
}

Map<String, String> _parseProductUnit(dynamic rawUnit) {
  if (rawUnit is Map) {
    final map = Map<String, dynamic>.from(rawUnit);
    return {
      'num': map['Num']?.toString().trim() ?? '',
      'class': map['Class']?.toString().trim() ?? '',
    };
  }

  final raw = rawUnit?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return {'num': '', 'class': ''};
  }

  final match = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*(.*)$').firstMatch(raw);
  if (match == null) {
    return {'num': '', 'class': raw};
  }

  return {
    'num': match.group(1)?.trim() ?? '',
    'class': match.group(2)?.trim() ?? '',
  };
}
