import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/conversation.dart';
import '../../data/repositories/message_repository.dart';
import '../../design/design_system.dart';

class OrderConversationArgs {
  const OrderConversationArgs({required this.conversation});

  final Conversation conversation;
}

/// WhatsApp-style order thread. The customer only sees NovaShop as the
/// counterpart; partner attribution remains internal.
class OrderConversationScreen extends StatefulWidget {
  const OrderConversationScreen({required this.conversation, super.key});

  final Conversation conversation;

  @override
  State<OrderConversationScreen> createState() =>
      _OrderConversationScreenState();
}

class _OrderConversationScreenState extends State<OrderConversationScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await context
          .read<MessageRepository>()
          .sendCustomerMessage(widget.conversation.id, text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmDelivery() async {
    await context
        .read<MessageRepository>()
        .confirmDelivery(widget.conversation.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Livraison confirmee.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: ScreenHeader(
              title: 'NovaShop',
              trailing: NovaBadge(
                label: _statusLabel(widget.conversation.status),
                tone: NovaBadgeTone.primary,
                dense: true,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ConversationMessage>>(
              stream: context
                  .read<MessageRepository>()
                  .watchMessages(widget.conversation.id),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const [];
                if (messages.isEmpty) {
                  return const NovaEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Conversation en cours',
                    message: 'NovaShop prepare le suivi de votre commande.',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return _MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NovaButton.secondary(
                    label: 'Confirmer la livraison',
                    icon: Icons.verified_rounded,
                    onPressed: _confirmDelivery,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Message a NovaShop',
                            filled: true,
                            fillColor: context.colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      CircleIconButton(
                        icon: Icons.send_rounded,
                        tooltip: 'Envoyer',
                        onPressed: _sending ? null : _send,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ConversationStatus status) {
    return switch (status) {
      ConversationStatus.awaitingConfirmation => 'A confirmer',
      ConversationStatus.confirmed => 'Confirmee',
      ConversationStatus.preparing => 'Preparation',
      ConversationStatus.outForDelivery => 'Livraison',
      ConversationStatus.delivered => 'Livree',
      ConversationStatus.buyerConfirmed => 'Terminee',
      ConversationStatus.cancelled => 'Annulee',
      ConversationStatus.draft => 'Brouillon',
    };
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.isCustomer;
    final isSystem = message.isSystem;
    final color = isSystem
        ? context.colors.surfaceMuted
        : isCustomer
            ? AppColors.deepInk
            : context.colors.surface;
    final foreground = isCustomer ? Colors.white : context.colors.textPrimary;

    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Text(
            message.body,
            style: TextStyle(color: foreground, height: 1.35),
          ),
        ),
      ),
    );
  }
}
