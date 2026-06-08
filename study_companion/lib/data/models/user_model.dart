class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? token;
  final String? phone;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.token,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'],
      email: json['email'] ?? '',
      role: json['role'],
      token: json['token'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      if (token != null) 'token': token,
      if (phone != null) 'phone': phone,
    };
  }
}
