class Borrow {
  final int id;
  final String borrowId;
  final String borrowerName;
  final String phoneNumber;
  final String? email;
  final String? address;
  final String itemName;
  final String? itemDescription;
  final String borrowDate;
  final String expectedReturnDate;
  final String? actualReturnDate;
  final num amount;
  final String? paymentId;
  final String? paymentMethod;
  final String paymentStatus;
  final String status;
  final String createdAt;

  Borrow({
    required this.id,
    required this.borrowId,
    required this.borrowerName,
    required this.phoneNumber,
    this.email,
    this.address,
    required this.itemName,
    this.itemDescription,
    required this.borrowDate,
    required this.expectedReturnDate,
    this.actualReturnDate,
    required this.amount,
    this.paymentId,
    this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
  });

  factory Borrow.fromJson(Map<String, dynamic> json) {
    return Borrow(
      id: json['id'],
      borrowId: json['borrow_id'] ?? '',
      borrowerName: json['borrower_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      address: json['address'],
      itemName: json['item_name'] ?? '',
      itemDescription: json['item_description'],
      borrowDate: json['borrow_date'] ?? '',
      expectedReturnDate: json['expected_return_date'] ?? '',
      actualReturnDate: json['actual_return_date'],
      amount: json['amount'] != null ? num.tryParse(json['amount'].toString()) ?? 0 : 0,
      paymentId: json['payment_id'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'pending',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'borrow_id': borrowId,
      'borrower_name': borrowerName,
      'phone_number': phoneNumber,
      'email': email,
      'address': address,
      'item_name': itemName,
      'item_description': itemDescription,
      'borrow_date': borrowDate,
      'expected_return_date': expectedReturnDate,
      'actual_return_date': actualReturnDate,
      'amount': amount,
      'payment_id': paymentId,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'status': status,
      'created_at': createdAt,
    };
  }
}
