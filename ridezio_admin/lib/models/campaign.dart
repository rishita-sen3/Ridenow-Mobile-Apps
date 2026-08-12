class Campaign {
  final int id;
  final String title;
  final String code;
  final String discountType;
  final num discountValue;
  final String startDate;
  final String endDate;
  final int? minDays;
  final String? details;
  final String status;
  final String createdAt;

  Campaign({
    required this.id,
    required this.title,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.minDays,
    this.details,
    required this.status,
    required this.createdAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? '',
      code: json['code'] ?? '',
      discountType: json['discount_type'] ?? 'percentage',
      discountValue: json['discount_value'] != null ? (num.tryParse(json['discount_value'].toString()) ?? 0) : 0,
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      minDays: json['min_days'] != null ? int.tryParse(json['min_days'].toString()) : null,
      details: json['details'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
