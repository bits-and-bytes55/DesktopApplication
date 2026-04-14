// lib/models/engineer_model.dart

class Engineer {
  final String? id;
  final String firstName;
  final String lastName;
  final String cell;
  final String office;
  final String email;
  final String? photo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Engineer({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.cell,
    required this.office,
    required this.email,
    this.photo,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create Engineer from JSON
  factory Engineer.fromJson(Map<String, dynamic> json) {
    return Engineer(
      id: json['_id'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      cell: json['cell'] as String? ?? '',
      office: json['office'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photo: json['photo'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  // Method to convert Engineer to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'cell': cell,
      'office': office,
      'email': email,
      if (photo != null && photo!.isNotEmpty) 'photo': photo,
    };
  }

  // Method to create a copy with updated fields
  Engineer copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? cell,
    String? office,
    String? email,
    String? photo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Engineer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      cell: cell ?? this.cell,
      office: office ?? this.office,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isEmpty => 
      firstName.isEmpty && 
      lastName.isEmpty && 
      cell.isEmpty && 
      office.isEmpty && 
      email.isEmpty;
}