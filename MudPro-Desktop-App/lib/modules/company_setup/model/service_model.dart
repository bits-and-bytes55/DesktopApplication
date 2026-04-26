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
      id: _readString(json, const ['_id', 'id']),
      name: _readString(json, const [
        'name',
        'Name',
        'itemName',
        'serviceName',
      ]),
      code: _readString(json, const ['code', 'Code']),
      unit: _normalizeUnit(_readString(json, const ['unit', 'Unit'])),
      price: _readDouble(json, const ['price', 'Price']),
      initial: _readString(json, const ['initial', 'Initial']),
      tax: _readBool(json, const ['tax', 'Tax']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'code': code.trim(),
      'unit': _normalizeUnit(unit),
      'price': price,
      'initial': initial.trim(),
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
      id: _readString(json, const ['_id', 'id']),
      name: _readString(json, const [
        'name',
        'Name',
        'itemName',
        'packageName',
      ]),
      code: _readString(json, const ['code', 'Code']),
      unit: _normalizeUnit(_readString(json, const ['unit', 'Unit'])),
      price: _readDouble(json, const ['price', 'Price']),
      initial: _readString(json, const ['initial', 'Initial']),
      tax: _readBool(json, const ['tax', 'Tax']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'code': code.trim(),
      'unit': _normalizeUnit(unit),
      'price': price,
      'initial': initial.trim(),
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
      id: _readString(json, const ['_id', 'id']),
      name: _readString(json, const [
        'name',
        'Name',
        'itemName',
        'engineeringName',
      ]),
      code: _readString(json, const ['code', 'Code']),
      unit: _normalizeUnit(_readString(json, const ['unit', 'Unit'])),
      price: _readDouble(json, const ['price', 'Price']),
      initial: _readString(json, const ['initial', 'Initial']),
      tax: _readBool(json, const ['tax', 'Tax']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'code': code.trim(),
      'unit': _normalizeUnit(unit),
      'price': price,
      'initial': initial.trim(),
      'tax': tax,
    };
  }
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final parsed = double.tryParse(value.toString().trim());
    if (parsed != null) return parsed;
  }
  return 0.0;
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
  }
  return false;
}

String _normalizeUnit(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}
