import 'json_utils.dart';

enum ConversationStatus {
  draft,
  awaitingConfirmation,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  buyerConfirmed,
  cancelled;

  String get id => switch (this) {
        ConversationStatus.awaitingConfirmation => 'awaiting_confirmation',
        ConversationStatus.outForDelivery => 'out_for_delivery',
        ConversationStatus.buyerConfirmed => 'buyer_confirmed',
        _ => name,
      };

  static ConversationStatus fromId(String? id) {
    return ConversationStatus.values.firstWhere(
      (status) => status.id == id,
      orElse: () => ConversationStatus.draft,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.customerId,
    required this.status,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final ConversationStatus status;
  final String title;
  final String createdAt;
  final String updatedAt;

  Conversation copyWith({
    ConversationStatus? status,
    String? updatedAt,
  }) {
    return Conversation(
      id: id,
      customerId: customerId,
      status: status ?? this.status,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: Json.str(json['id']),
      customerId: Json.str(json['customerId'] ?? json['customer_id']),
      status: ConversationStatus.fromId(Json.str(json['status'], 'draft')),
      title: Json.str(json['title'], 'Commande NovaShop'),
      createdAt: Json.str(json['createdAt'] ?? json['created_at']),
      updatedAt: Json.str(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'status': status.id,
      'title': title,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

enum ConversationMessageAuthor { customer, novaShop, system }

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.conversationId,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final ConversationMessageAuthor author;
  final String body;
  final String createdAt;

  bool get isCustomer => author == ConversationMessageAuthor.customer;
  bool get isSystem => author == ConversationMessageAuthor.system;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    final rawAuthor = Json.str(json['author'], 'system');
    return ConversationMessage(
      id: Json.str(json['id']),
      conversationId:
          Json.str(json['conversationId'] ?? json['conversation_id']),
      author: switch (rawAuthor) {
        'customer' => ConversationMessageAuthor.customer,
        'nova_shop' || 'novashop' => ConversationMessageAuthor.novaShop,
        _ => ConversationMessageAuthor.system,
      },
      body: Json.str(json['body']),
      createdAt: Json.str(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'author': switch (author) {
        ConversationMessageAuthor.customer => 'customer',
        ConversationMessageAuthor.novaShop => 'nova_shop',
        ConversationMessageAuthor.system => 'system',
      },
      'body': body,
      'createdAt': createdAt,
    };
  }
}

class ConversationOrderItem {
  const ConversationOrderItem({
    required this.listingId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.variantId,
    this.options = const {},
  });

  final String listingId;
  final String title;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? variantId;
  final Map<String, String> options;

  Map<String, dynamic> toJson() {
    return {
      'listingId': listingId,
      'title': title,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'variantId': variantId,
      'options': options,
    };
  }
}
