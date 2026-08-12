class Booking {
  final int id;
  final String bookingReference;
  final String status;
  final num totalAmount;
  final String createdAt;
  final String startDatetime;
  final String? endDatetime;
  final num totalHours;
  final num rentalAmount;
  final num securityDeposit;
  final bool isExtended;
  final int extendedHours;
  final num extendedAmount;
  final num paidAmount;
  final String paymentStatus;
  final String? returnVideoPath;
  final String? customerName;
  final String? vehicleName;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? vehicle;

  Booking({
    required this.id,
    required this.bookingReference,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.startDatetime,
    this.endDatetime,
    required this.totalHours,
    required this.rentalAmount,
    required this.securityDeposit,
    required this.isExtended,
    required this.extendedHours,
    required this.extendedAmount,
    required this.paidAmount,
    required this.paymentStatus,
    this.returnVideoPath,
    this.customerName,
    this.vehicleName,
    this.customer,
    this.vehicle,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      bookingReference: json['booking_reference'] ?? 'RN-${json['id']}',
      status: json['status'] ?? 'pending',
      totalAmount: json['total_amount'] ?? 0,
      createdAt: json['created_at'] ?? '',
      startDatetime: json['start_datetime'] ?? json['created_at'] ?? '',
      endDatetime: json['end_datetime'],
      totalHours: json['total_hours'] ?? 0,
      rentalAmount: json['rental_amount'] ?? 0,
      securityDeposit: json['security_deposit'] ?? 0,
      isExtended: json['is_extended'] == 1 || json['is_extended'] == true,
      extendedHours: json['extended_hours'] ?? 0,
      extendedAmount: json['extended_amount'] ?? 0,
      paidAmount: json['paid_amount'] ?? 0,
      paymentStatus: json['payment_status'] ?? 'pending',
      returnVideoPath: json['return_video_path'],
      customerName: json['customer']?['first_name'] ?? 'Unknown Customer',
      vehicleName: json['vehicle']?['brand'] != null 
          ? '${json['vehicle']['brand']} ${json['vehicle']['model']}' 
          : 'Unknown Vehicle',
      customer: json['customer'],
      vehicle: json['vehicle'],
    );
  }
}
