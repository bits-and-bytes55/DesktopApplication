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
