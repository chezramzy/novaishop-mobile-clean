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
    required List<ConversationOrderItem> items,
  }) async {
    _requireSupabase();
    try {
      final row = await Supabase.instance.client.rpc(
        'create_order_conversation_from_cart',
        params: {
          'p_items': items.map((item) => item.toJson()).toList(),
        },
      );
      return Conversation.fromJson(Map<String, dynamic>.from(row as Map));
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

  Future<Conversation> getConversation(String conversationId) async {
    _requireSupabase();
    try {
      final row = await Supabase.instance.client
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .single();
      return Conversation.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Stream<Conversation> watchConversation(Conversation initial) {
    _requireSupabase();
    final controller = StreamController<Conversation>();
    RealtimeChannel? channel;

    Future<void> emitLatest() async {
      if (!controller.isClosed) {
        controller.add(await getConversation(initial.id));
      }
    }

    controller.add(initial);
    channel = Supabase.instance.client
        .channel('conversation:${initial.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: initial.id,
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
    try {
      await Supabase.instance.client.rpc(
        'confirm_order_conversation_delivery',
        params: {'p_conversation_id': conversationId},
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
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
}
