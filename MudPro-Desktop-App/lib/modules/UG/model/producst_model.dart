class ProductModel {
  final int id;
  String product;
  String code;
  String sg;
  String unit;
  String price;
  String initial;
  String group;

  bool volAdd;
  bool calculate;
  bool tax;

  ProductModel({
    required this.id,
    required this.product,
    required this.code,
    required this.sg,
    required this.unit,
    required this.price,
    required this.initial,
    required this.group,
    this.volAdd = false,
    this.calculate = false,
    this.tax = false,
  });
}


class PremixModel {
  final String id;
  String description;
  String mw;
  String leasingFee;
  String mudType;
  bool tax;

  PremixModel({
    required this.id,
    required this.description,
    required this.mw,
    required this.leasingFee,
    required this.mudType,
    this.tax = false,
  });
}


class ObmModel {
  final String id;
  String product;
  String code;
  String sg;
  String conc;

  ObmModel({
    required this.id,
    required this.product,
    required this.code,
    required this.sg,
    required this.conc,
  });
}


class PackageModel {
  String id, package, code, unit, price, initial;
  bool tax;
  PackageModel(this.id, this.package, this.code, this.unit, this.price, this.initial, this.tax);
}

class EngineeringModel {
  String id, name, code, unit, price;
  bool tax;
  EngineeringModel(this.id, this.name, this.code, this.unit, this.price, this.tax);
}

class ServiceModel {
  String id, service, code, unit, price;
  bool tax;
  ServiceModel(this.id, this.service, this.code, this.unit, this.price, this.tax);
}
