class Vehicle {
  final int? id;
  final int? shopId;
  final String type;
  final String brand;
  final String model;
  final String registrationNumber;
  final double hourlyRate;
  final double dailyRate;
  final double weeklyRate;
  final double monthlyRate;
  final double securityDeposit;
  final String status;
  final String? imageUrl;
  final String? color;
  final String? fuelType;
  final int? seatingCapacity;

  Vehicle({
    this.id,
    this.shopId,
    required this.type,
    required this.brand,
    required this.model,
    required this.registrationNumber,
    required this.hourlyRate,
    required this.dailyRate,
    this.weeklyRate = 0.0,
    this.monthlyRate = 0.0,
    this.securityDeposit = 0.0,
    this.status = 'available',
    this.imageUrl,
    this.color,
    this.fuelType,
    this.seatingCapacity,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      shopId: json['shop_id'],
      type: json['type'] ?? 'bike',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      hourlyRate: double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0.0,
      dailyRate: double.tryParse(json['daily_rate']?.toString() ?? '0') ?? 0.0,
      weeklyRate: double.tryParse(json['weekly_rate']?.toString() ?? '0') ?? 0.0,
      monthlyRate: double.tryParse(json['monthly_rate']?.toString() ?? '0') ?? 0.0,
      securityDeposit: double.tryParse(json['security_deposit']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'available',
      imageUrl: json['image_url'],
      color: json['color'],
      fuelType: json['fuel_type'],
      seatingCapacity: json['seating_capacity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'type': type,
      'brand': brand,
      'model': model,
      'registration_number': registrationNumber,
      'hourly_rate': hourlyRate,
      'daily_rate': dailyRate,
      'weekly_rate': weeklyRate,
      'monthly_rate': monthlyRate,
      'security_deposit': securityDeposit,
      'status': status,
      'color': color,
      'fuel_type': fuelType,
      'seating_capacity': seatingCapacity,
    };
  }
}
