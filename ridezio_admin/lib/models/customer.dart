class Customer {
  final int id;
  final String firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final bool isActive;
  final String createdAt;

  Customer({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    required this.isActive,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      firstName: json['first_name'] ?? 'Unknown',
      lastName: json['last_name'],
      email: json['email'] ?? '',
      phone: json['phone'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }
}
