// lib/models/service_model.dart

class ServiceItem {
  final String? id;
  final String name;
  final String code;
  final String unit;
  final double price;
  String initial;
  bool tax;

  ServiceItem({
    this.id,
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
    this.initial = '',
    this.tax = false,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['_id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      unit: json['unit'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      initial: json['initial']?.toString() ?? '',
      tax: json['tax'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'unit': unit,
      'price': price,
      'initial': initial,
      'tax': tax,
    };
  }
}

class PackageItem {
  final String? id;
  final String name;
  final String code;
  final String unit;
  final double price;
  String initial;
  bool tax;

  PackageItem({
    this.id,
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
    this.initial = '',
    this.tax = false,
  });

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      id: json['_id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      unit: json['unit'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      initial: json['initial']?.toString() ?? '',
      tax: json['tax'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'unit': unit,
      'price': price,
      'initial': initial,
      'tax': tax,
    };
  }
}

class EngineeringItem {
  final String? id;
  final String name;
  final String code;
  final String unit;
  final double price;
  String initial;
  bool tax;

  EngineeringItem({
    this.id,
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
    this.initial = '',
    this.tax = false,
  });

  factory EngineeringItem.fromJson(Map<String, dynamic> json) {
    return EngineeringItem(
      id: json['_id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      unit: json['unit'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      initial: json['initial']?.toString() ?? '',
      tax: json['tax'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'unit': unit,
      'price': price,
      'initial': initial,
      'tax': tax,
    };
  }
}