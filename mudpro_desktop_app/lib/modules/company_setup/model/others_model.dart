// lib/modules/company_setup/model/others_model.dart

class ActivityItem {
  final String? id;
  final String description;

  ActivityItem({
    this.id,
    required this.description,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['_id'],
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
    };
  }

  bool hasData() => description.trim().isNotEmpty;
}

class AdditionItem {
  final String? id;
  final String name;

  AdditionItem({
    this.id,
    required this.name,
  });

  factory AdditionItem.fromJson(Map<String, dynamic> json) {
    return AdditionItem(
      id: json['_id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  bool hasData() => name.trim().isNotEmpty;
}

class LossItem {
  final String? id;
  final String name;

  LossItem({
    this.id,
    required this.name,
  });

  factory LossItem.fromJson(Map<String, dynamic> json) {
    return LossItem(
      id: json['_id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  bool hasData() => name.trim().isNotEmpty;
}

class WaterBasedItem {
  final String? id;
  final String name;

  WaterBasedItem({
    this.id,
    required this.name,
  });

  factory WaterBasedItem.fromJson(Map<String, dynamic> json) {
    return WaterBasedItem(
      id: json['_id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  bool hasData() => name.trim().isNotEmpty;
}

class OilBasedItem {
  final String? id;
  final String name;

  OilBasedItem({
    this.id,
    required this.name,
  });

  factory OilBasedItem.fromJson(Map<String, dynamic> json) {
    return OilBasedItem(
      id: json['_id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  bool hasData() => name.trim().isNotEmpty;
}

class SyntheticItem {
  final String? id;
  final String name;

  SyntheticItem({
    this.id,
    required this.name,
  });

  factory SyntheticItem.fromJson(Map<String, dynamic> json) {
    return SyntheticItem(
      id: json['_id'],
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  bool hasData() => name.trim().isNotEmpty;
}