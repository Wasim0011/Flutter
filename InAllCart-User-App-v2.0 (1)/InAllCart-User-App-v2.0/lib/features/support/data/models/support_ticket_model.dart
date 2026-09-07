class SupportCategory {
  final int id;
  final String name;
  final String icon;
  final String? description;

  const SupportCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
  });

  factory SupportCategory.fromJson(dynamic json) {
    if (json is String) {
      return SupportCategory(
        id: json.hashCode.abs(),
        name: json,
        icon: 'help_outline',
      );
    }
    final map = json as Map<String, dynamic>;
    return SupportCategory(
      id: map['id'] as int? ?? (map['name'] as String? ?? 'General').hashCode.abs(),
      name: map['name'] as String? ?? 'General',
      icon: map['icon'] as String? ?? 'help_outline',
      description: map['description'] as String?,
    );
  }
}

class SupportTicket {
  final int id;
  final String ticketNumber;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String? firebaseChatId;
  final SupportCategory? category;
  final SupportMessage? latestMessage;
  final List<SupportMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.firebaseChatId,
    this.category,
    this.latestMessage,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => ['open', 'in_progress', 'waiting_user'].contains(status);

  String get statusLabel {
    switch (status) {
      case 'open':         return 'Open';
      case 'in_progress':  return 'In Progress';
      case 'waiting_user': return 'Waiting';
      case 'resolved':     return 'Resolved';
      case 'closed':       return 'Closed';
      default:             return status;
    }
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as int,
      ticketNumber: json['ticket_number'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      firebaseChatId: json['firebase_chat_id'] as String?,
      category: json['category'] != null
          ? SupportCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      latestMessage: json['latest_message'] != null
          ? SupportMessage.fromJson(json['latest_message'] as Map<String, dynamic>)
          : null,
      messages: (json['messages'] as List? ?? [])
          .map((m) => SupportMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class SupportMessage {
  final int id;
  final String message;
  final List<String> attachments;
  final bool isAdmin;
  final DateTime? readAt;
  final DateTime createdAt;
  final SupportUser? user;

  const SupportMessage({
    required this.id,
    required this.message,
    this.attachments = const [],
    required this.isAdmin,
    this.readAt,
    required this.createdAt,
    this.user,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as int,
      message: json['message'] as String,
      attachments: (json['attachments'] as List? ?? []).cast<String>(),
      isAdmin: json['is_admin'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null
          ? SupportUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SupportUser {
  final int id;
  final String name;
  final String? avatar;

  const SupportUser({required this.id, required this.name, this.avatar});

  factory SupportUser.fromJson(Map<String, dynamic> json) {
    return SupportUser(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
    );
  }
}
