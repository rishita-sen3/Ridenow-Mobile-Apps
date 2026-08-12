class PremiumAddon {
  final int id;
  final String name;
  final String description;
  final num price;
  final int durationDays;

  PremiumAddon({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
  });

  factory PremiumAddon.fromJson(Map<String, dynamic> json) {
    return PremiumAddon(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] != null ? (num.tryParse(json['price'].toString()) ?? 0) : 0,
      durationDays: json['duration_days'] != null ? (int.tryParse(json['duration_days'].toString()) ?? 0) : 0,
    );
  }
}

class ShopPremiumAddon {
  final int id;
  final PremiumAddon? addon;
  final num amountPaid;
  final String status;
  final String validUntil;

  ShopPremiumAddon({
    required this.id,
    this.addon,
    required this.amountPaid,
    required this.status,
    required this.validUntil,
  });

  factory ShopPremiumAddon.fromJson(Map<String, dynamic> json) {
    return ShopPremiumAddon(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      addon: json['addon'] != null ? PremiumAddon.fromJson(json['addon']) : null,
      amountPaid: json['amount_paid'] != null ? (num.tryParse(json['amount_paid'].toString()) ?? 0) : 0,
      status: json['status'] ?? '',
      validUntil: json['valid_until']?.toString() ?? '',
    );
  }
}
