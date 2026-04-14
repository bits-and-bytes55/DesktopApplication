// ─── Product Inventory Model ──────────────────────────────────
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';

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
    // Handle both nested Unit object and flat unit field
    String unitValue = "";
    if (json['Unit'] != null && json['Unit'] is Map) {
      unitValue = json['Unit']['Class']?.toString() ?? "";
    } else {
      unitValue = json['unit']?.toString() ?? json['Unit']?.toString() ?? "";
    }
    
    return ProductInventoryModel(
      id: json['_id']?.toString(),
      product: json['Product'] ?? "",
      code: json['Code'] ?? "",
      sg: json['SG']?.toString() ?? "",
      unit: unitValue,
      // Fix: Map 'A' from API response to price field (API uses 'A' for price)
      price: json['A']?.toString() ?? json['price']?.toString() ?? "",
      initial: json['initial']?.toString() ?? json['Initial']?.toString() ?? "",
      group: json['Group'] ?? "",
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
