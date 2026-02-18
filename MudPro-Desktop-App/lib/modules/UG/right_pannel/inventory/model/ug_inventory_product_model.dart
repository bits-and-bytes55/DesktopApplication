// ─── Product Inventory Model ──────────────────────────────────
class ProductInventoryModel {
  String? id;
  String product;
  String code;
  String sg;
  String unit;
  String price;
  String initial;
  String group;
  bool volAdd;
  bool calculate;
  bool? plot;
  bool tax;

  ProductInventoryModel({
    this.id,
    this.product = "",
    this.code = "",
    this.sg = "",
    this.unit = "",
    this.price = "",
    this.initial = "",
    this.group = "",
    this.volAdd = false,
    this.calculate = false,
    this.plot = false,
    this.tax = false,
  });

  factory ProductInventoryModel.fromJson(Map<String, dynamic> json) {
    return ProductInventoryModel(
      id: json['_id']?.toString(),
      product: json['product'] ?? "",
      code: json['code'] ?? "",
      sg: json['sg'] ?? "",
      unit: json['unit'] ?? "",
      price: json['price'] ?? "",
      initial: json['initial'] ?? "",
      group: json['group'] ?? "",
      volAdd: json['volAdd'] ?? false,
      calculate: json['calculate'] ?? false,
      plot: json['plot'] ?? false,
      tax: json['tax'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'product': product,
        'code': code,
        'sg': sg,
        'unit': unit,
        'price': price,
        'initial': initial,
        'group': group,
        'volAdd': volAdd,
        'calculate': calculate,
        'plot': plot,
        'tax': tax,
      };
}

// ─── Premixed Mud Model ───────────────────────────────────────
class PremixModel {
  String? id;
  String description;
  String mw;
  String leasingFee;
  String mudType;
  bool tax;

  PremixModel({
    this.id,
    this.description = "",
    this.mw = "",
    this.leasingFee = "",
    this.mudType = "",
    this.tax = false,
  });

  factory PremixModel.fromJson(Map<String, dynamic> json) {
    return PremixModel(
      id: json['_id']?.toString(),
      description: json['description'] ?? "",
      mw: json['mw'] ?? "",
      leasingFee: json['leasingFee'] ?? "",
      mudType: json['mudType'] ?? "",
      tax: json['tax'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'description': description,
        'mw': mw,
        'leasingFee': leasingFee,
        'mudType': mudType,
        'tax': tax,
      };
}

// ─── OBM Model ────────────────────────────────────────────────
class ObmModel {
  String? id;
  String product;
  String code;
  String sg;
  String conc;

  ObmModel({
    this.id,
    this.product = "",
    this.code = "",
    this.sg = "",
    this.conc = "",
  });

  factory ObmModel.fromJson(Map<String, dynamic> json) {
    return ObmModel(
      id: json['_id']?.toString(),
      product: json['product'] ?? "",
      code: json['code'] ?? "",
      sg: json['sg'] ?? "",
      conc: json['conc'] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'product': product,
        'code': code,
        'sg': sg,
        'conc': conc,
      };
}