// lib/models/service_model.dart

class ServiceItem {
  final String? id;
  final String name;
  final String code;
  final String unit;
  final double price;

  ServiceItem({
    this.id,
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['_id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      unit: json['unit'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'unit': unit,
      'price': price,
    };
  }
}

class PackageItem {
  final String? id;
  final String name;
  final String code;
  final String unit;
  final double price;

  PackageItem({
    this.id,
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
  });

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      id: json['_id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      unit: json['unit'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'unit': unit,
      'price': price,
    };
  }
}

class EngineeringItem {
  final String? id;
  final String name;
  final String code;
  final String unit;
  final double price;

  EngineeringItem({
    this.id,
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
  });

  factory EngineeringItem.fromJson(Map<String, dynamic> json) {
    return EngineeringItem(
      id: json['_id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      unit: json['unit'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'unit': unit,
      'price': price,
    };
  }
}