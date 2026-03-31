class ConsumeProductModel {
  String? id;
  String? productId; // Reference to Product
  String code;
  double? sg;
  String unit;
  double price;
  double initial;
  double adjust;
  double used;
  double final_;
  double cost;
  double volumeBbl;
  int numberOfBags;
  double weightPerBag;
  DateTime? createdAt;
  DateTime? updatedAt;

  ConsumeProductModel({
    this.id,
    this.productId,
    this.code = '',
    this.sg,
    this.unit = '',
    this.price = 0.0,
    this.initial = 0.0,
    this.adjust = 0.0,
    this.used = 0.0,
    this.final_ = 0.0,
    this.cost = 0.0,
    this.volumeBbl = 0.0,
    this.numberOfBags = 0,
    this.weightPerBag = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  // From JSON
  factory ConsumeProductModel.fromJson(Map<String, dynamic> json) {
    return ConsumeProductModel(
      id: json['_id'] as String?,
      productId: json['product'] is String 
          ? json['product'] as String 
          : (json['product'] as Map<String, dynamic>?)?['_id'] as String?,
      code: json['code'] as String? ?? '',
      sg: (json['sg'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      initial: (json['initial'] as num?)?.toDouble() ?? 0.0,
      adjust: (json['adjust'] as num?)?.toDouble() ?? 0.0,
      used: (json['used'] as num?)?.toDouble() ?? 0.0,
      final_: (json['final'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      volumeBbl: (json['volumeBbl'] as num?)?.toDouble() ?? 0.0,
      numberOfBags: json['numberOfBags'] as int? ?? 0,
      weightPerBag: (json['weightPerBag'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (productId != null) 'product': productId,
      'code': code,
      'sg': sg,
      'unit': unit,
      'price': price,
      'initial': initial,
      'adjust': adjust,
      'used': used,
      'final': final_,
      'cost': cost,
      'volumeBbl': volumeBbl,
      'numberOfBags': numberOfBags,
      'weightPerBag': weightPerBag,
    };
  }

  // Calculate values locally
  void calculate() {
    // Calculate final
    final_ = initial - adjust - used;
    
    // Calculate cost
    cost = used * price;
    
    // Calculate volume in BBL
    if (sg != null && sg! > 0) {
      final totalWeight = numberOfBags * weightPerBag;
      volumeBbl = double.parse((totalWeight / (sg! * 158.987)).toStringAsFixed(3));
    } else {
      volumeBbl = 0.0;
    }
  }

  @override
  String toString() {
    return 'ConsumeProductModel(id: $id, code: $code, cost: $cost, volumeBbl: $volumeBbl)';
  }
}