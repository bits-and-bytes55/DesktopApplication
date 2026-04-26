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

//   ProductModel toProductModel() {
//   return ProductModel(
//     id: id,
//     product: product,
//     code: code,
//     sg: sg,
//     unitNum: unit,
//     price: price,
//     initial: initial,
//     group: group,
//     volAdd: volAdd,
//     calculate: calculate,
//     plot: plot ?? false,
//     tax: tax,
//   );
// }

  factory ProductInventoryModel.fromJson(Map<String, dynamic> json) {
    final unitValue = _mergeUnitParts(json['Unit'] ?? json['unit']);

    bool boolValue(dynamic value) {
      if (value is bool) return value;
      final text = value?.toString().toLowerCase().trim() ?? '';
      return text == 'true' || text == '1' || text == 'yes';
    }
    
    return ProductInventoryModel(
      id: json['_id']?.toString(),
      product: json['product']?.toString() ?? json['Product']?.toString() ?? "",
      code: json['code']?.toString() ?? json['Code']?.toString() ?? "",
      sg: json['sg']?.toString() ?? json['SG']?.toString() ?? "",
      unit: unitValue,
      // Fix: Map 'A' from API response to price field (API uses 'A' for price)
      price: json['A']?.toString() ?? json['price']?.toString() ?? "",
      initial: json['initial']?.toString() ?? json['Initial']?.toString() ?? "",
      group: json['group']?.toString() ?? json['Group']?.toString() ?? "",
      volAdd: boolValue(json['volAdd']),
      calculate: boolValue(json['calculate']),
      plot: boolValue(json['plot']),
      tax: boolValue(json['tax']),
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

String _mergeUnitParts(dynamic rawUnit) {
  if (rawUnit is Map) {
    final map = Map<String, dynamic>.from(rawUnit);
    final num = map['Num']?.toString().trim() ?? '';
    final unitClass = map['Class']?.toString().trim() ?? '';
    return [num, unitClass].where((part) => part.isNotEmpty).join(' ');
  }

  return rawUnit?.toString().trim() ?? '';
}
