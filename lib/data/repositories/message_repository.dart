import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';
import 'repository_error.dart';

class MessageRepository {
  MessageRepository({required String? accessToken})
      : _accessToken = accessToken;

  final String? _accessToken;

  bool get _canUseSupabase =>
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  void _requireSupabase() {
    if (!_canUseSupabase) {
      throw RepositoryException(
        'Reconnectez-vous pour commander par message.',
      );
    }
  }

  Future<Conversation> startOrderConversation({
    required String customerId,
    required List<ConversationOrderItem> items,
    required double total,
  }) async {
    _requireSupabase();
    try {
      final client = Supabase.instance.client;
      final inserted = await client
          .from('conversations')
          .insert({
            'customer_id': customerId,
            'status': ConversationStatus.awaitingConfirmation.id,
            'title': 'Commande NovaShop',
            'total_amount': total,
          })
          .select()
          .single();
      final conversation = Conversation.fromJson(inserted);
      await client.from('conversation_order_items').insert(
            items
                .map(
                  (item) => {
                    'conversation_id': conversation.id,
                    'listing_id': item.listingId,
                    'variant_id': item.variantId,
                    'title': item.title,
                    'quantity': item.quantity,
                    'unit_price': item.unitPrice,
                    'total_price': item.totalPrice,
                    'options': item.options,
                  },
                )
                .toList(),
          );
      await sendSystemMessage(
        conversation.id,
        _summaryMessage(items, total),
      );
      return conversation;
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<ConversationMessage>> getMessages(String conversationId) async {
    _requireSupabase();
    final rows = await Supabase.instance.client
        .from('conversation_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return rows
        .whereType<Map>()
        .map((row) => ConversationMessage.fromJson(
              Map<String, dynamic>.from(row),
            ))
        .toList();
  }

  Stream<List<ConversationMessage>> watchMessages(String conversationId) {
    _requireSupabase();
    final controller = StreamController<List<ConversationMessage>>();
    RealtimeChannel? channel;

    Future<void> emitLatest() async {
      if (!controller.isClosed) {
        controller.add(await getMessages(conversationId));
      }
    }

    emitLatest();
    channel = Supabase.instance.client
        .channel('conversation_messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversation_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (_) => emitLatest(),
        )
        .subscribe();

    controller.onCancel = () async {
      if (channel != null) {
        await Supabase.instance.client.removeChannel(channel);
      }
    };
    return controller.stream;
  }

  Future<void> sendCustomerMessage(String conversationId, String body) {
    return _sendMessage(
      conversationId,
      author: ConversationMessageAuthor.customer,
      body: body,
    );
  }

  Future<void> sendNovaShopMessage(String conversationId, String body) {
    return _sendMessage(
      conversationId,
      author: ConversationMessageAuthor.novaShop,
      body: body,
    );
  }

  Future<void> sendSystemMessage(String conversationId, String body) {
    return _sendMessage(
      conversationId,
      author: ConversationMessageAuthor.system,
      body: body,
    );
  }

  Future<void> confirmDelivery(String conversationId) async {
    _requireSupabase();
    await Supabase.instance.client
        .from('conversations')
        .update({'status': ConversationStatus.buyerConfirmed.id}).eq(
            'id', conversationId);
    await sendSystemMessage(
      conversationId,
      'Livraison confirmee par l acheteur. Merci pour votre confiance.',
    );
  }

  Future<void> _sendMessage(
    String conversationId, {
    required ConversationMessageAuthor author,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    _requireSupabase();
    await Supabase.instance.client.from('conversation_messages').insert({
      'conversation_id': conversationId,
      'author': switch (author) {
        ConversationMessageAuthor.customer => 'customer',
        ConversationMessageAuthor.novaShop => 'nova_shop',
        ConversationMessageAuthor.system => 'system',
      },
      'body': trimmed,
    });
  }

  String _summaryMessage(List<ConversationOrderItem> items, double total) {
    final lines = [
      'Nouvelle demande de commande:',
      for (final item in items)
        '- ${item.quantity} x ${item.title}'
            '${item.options.isEmpty ? '' : ' (${item.options.values.join(', ')})'}',
      'Total estime: ${total.toStringAsFixed(0)} XOF',
    ];
    return lines.join('\n');
  }
}
