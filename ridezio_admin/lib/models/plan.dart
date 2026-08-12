class Plan {
  final int id;
  final String name;
  final String description;
  final num monthlyPrice;
  final num yearlyPrice;
  final int maxVehicles;
  final int maxShops;
  final List<dynamic> features;
  final bool isFeatured;

  Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxVehicles,
    required this.maxShops,
    required this.features,
    required this.isFeatured,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      monthlyPrice: json['monthly_price'] != null ? (num.tryParse(json['monthly_price'].toString()) ?? 0) : 0,
      yearlyPrice: json['yearly_price'] != null ? (num.tryParse(json['yearly_price'].toString()) ?? 0) : 0,
      maxVehicles: json['max_vehicles'] != null ? (int.tryParse(json['max_vehicles'].toString()) ?? 0) : 0,
      maxShops: json['max_shops'] != null ? (int.tryParse(json['max_shops'].toString()) ?? 0) : 0,
      features: json['features'] ?? [],
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
    );
  }
}

class ShopSubscription {
  final int id;
  final Plan? plan;
  final num amountPaid;
  final String status;
  final String validUntil;

  ShopSubscription({
    required this.id,
    this.plan,
    required this.amountPaid,
    required this.status,
    required this.validUntil,
  });

  factory ShopSubscription.fromJson(Map<String, dynamic> json) {
    return ShopSubscription(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      plan: json['plan'] != null ? Plan.fromJson(json['plan']) : null,
      amountPaid: json['amount_paid'] != null ? (num.tryParse(json['amount_paid'].toString()) ?? 0) : 0,
      status: json['status'] ?? '',
      validUntil: json['valid_until']?.toString() ?? '',
    );
  }
}
