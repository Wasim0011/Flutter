class CustomerComplaintModel {
  final int id;
  final int? orderId;
  final String category;
  final String description;
  final String status;
  final String actionTaken;
  final double? penaltyAmount;
  final String? adminNotes;
  final List<String> attachments;
  final DateTime createdAt;

  const CustomerComplaintModel({
    required this.id,
    this.orderId,
    required this.category,
    required this.description,
    required this.status,
    required this.actionTaken,
    this.penaltyAmount,
    this.adminNotes,
    required this.attachments,
    required this.createdAt,
  });

  factory CustomerComplaintModel.fromJson(Map<String, dynamic> json) {
    return CustomerComplaintModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int?,
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      actionTaken: json['action_taken'] as String? ?? 'none',
      penaltyAmount: json['penalty_amount'] != null
          ? double.tryParse(json['penalty_amount'].toString())
          : null,
      adminNotes: json['admin_notes'] as String?,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
