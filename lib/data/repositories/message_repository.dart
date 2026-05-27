import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';
import 'repository_error.dart';

class MessageRepository {
  MessageRepository({required String? accessToken}) : _accessToken = accessToken;

  static const _conversationsKey = 'novaishop.local.conversations';
  static const _messagesKey = 'novaishop.local.conversation_messages';

  final String? _accessToken;

  bool get _canUseSupabase =>
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  Future<Conversation> startOrderConversation({
    required String customerId,
    required List<ConversationOrderItem> items,
    required double total,
  }) async {
    if (_canUseSupabase) {
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

    final now = DateTime.now().toUtc().toIso8601String();
    final conversation = Conversation(
      id: 'conversation-${DateTime.now().microsecondsSinceEpoch}',
      customerId: customerId,
      status: ConversationStatus.awaitingConfirmation,
      title: 'Commande NovaShop',
      createdAt: now,
      updatedAt: now,
    );
    final conversations = await _readList(_conversationsKey)
      ..add(conversation.toJson());
    await _writeList(_conversationsKey, conversations);
    await sendSystemMessage(conversation.id, _summaryMessage(items, total));
    await sendNovaShopMessage(
      conversation.id,
      'Bonjour, votre demande de commande est bien recue. '
      'NovaShop va confirmer la disponibilite et organiser la livraison ici.',
    );
    return conversation;
  }

  Future<List<ConversationMessage>> getMessages(String conversationId) async {
    if (_canUseSupabase) {
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

    final rows = await _readList(_messagesKey);
    return rows
        .where((row) => row['conversationId'] == conversationId)
        .map(ConversationMessage.fromJson)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Stream<List<ConversationMessage>> watchMessages(String conversationId) {
    if (_canUseSupabase) {
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

    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => getMessages(conversationId),
    ).asyncMap((future) => future);
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
    if (_canUseSupabase) {
      await Supabase.instance.client
          .from('conversations')
          .update({'status': ConversationStatus.buyerConfirmed.id})
          .eq('id', conversationId);
    } else {
      final conversations = await _readList(_conversationsKey);
      final index =
          conversations.indexWhere((row) => row['id'] == conversationId);
      if (index != -1) {
        conversations[index] = {
          ...conversations[index],
          'status': ConversationStatus.buyerConfirmed.id,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        };
        await _writeList(_conversationsKey, conversations);
      }
    }
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

    if (_canUseSupabase) {
      await Supabase.instance.client.from('conversation_messages').insert({
        'conversation_id': conversationId,
        'author': switch (author) {
          ConversationMessageAuthor.customer => 'customer',
          ConversationMessageAuthor.novaShop => 'nova_shop',
          ConversationMessageAuthor.system => 'system',
        },
        'body': trimmed,
      });
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final message = ConversationMessage(
      id: 'message-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      author: author,
      body: trimmed,
      createdAt: now,
    );
    final rows = await _readList(_messagesKey)..add(message.toJson());
    await _writeList(_messagesKey, rows);
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

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }
}
