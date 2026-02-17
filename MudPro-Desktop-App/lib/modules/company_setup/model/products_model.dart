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
      'SG': num.tryParse(sg.trim()) ?? 0,
      'Unit': {
        'Num': int.tryParse(unitNum.trim()) ?? 0,
        'Class': unitClass.trim(),
      },
      'Group': group.trim(),
      'Retail': retail.trim().isEmpty ? 'No' : retail.trim(),
    };

    // Add optional fields only if they have values
    if (a.trim().isNotEmpty) {
      json['A'] = num.tryParse(a.trim()) ?? 0;
    }
    if (b.trim().isNotEmpty) {
      json['B'] = num.tryParse(b.trim()) ?? 0;
    }

    return json;
  }

  // Convert from API response
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'],
      product: json['Product'] ?? '',
      code: json['Code'] ?? '',
      sg: json['SG']?.toString() ?? '',
      unitNum: json['Unit']?['Num']?.toString() ?? '',
      unitClass: json['Unit']?['Class'] ?? '',
      group: json['Group'] ?? '',
      retail: json['Retail'] ?? '',
      a: json['A']?.toString() ?? '',
      b: json['B']?.toString() ?? '',
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