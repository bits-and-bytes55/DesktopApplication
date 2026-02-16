// lib/models/company_model.dart

class Company {
  final String? id;
  final String companyName;
  final String address;
  final String phone;
  final String email;
  final String? logoUrl;
  final String currencySymbol;
  final String currencyFormat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Company({
    this.id,
    required this.companyName,
    required this.address,
    required this.phone,
    required this.email,
    this.logoUrl,
    required this.currencySymbol,
    required this.currencyFormat,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create Company from JSON
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'] as String?,
      companyName: json['companyName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      currencySymbol: json['currencySymbol'] as String? ?? '₹',
      currencyFormat: json['currencyFormat'] as String? ?? '0.00',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  // Method to convert Company to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'companyName': companyName,
      'address': address,
      'phone': phone,
      'email': email,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl,
      'currencySymbol': currencySymbol,
      'currencyFormat': currencyFormat,
    };
  }

  // Method to create a copy with updated fields
  Company copyWith({
    String? id,
    String? companyName,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? currencySymbol,
    String? currencyFormat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyFormat: currencyFormat ?? this.currencyFormat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}