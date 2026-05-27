import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/session/session_scope.dart';
import '../../data/models/auth_user.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import 'assistant_message.dart';

/// Quick-suggestion prompts offered to the user.
class _Suggestion {
  const _Suggestion(this.label, this.icon, this.prompt);

  final String label;
  final IconData icon;
  final String prompt;
}

const _suggestions = [
  _Suggestion(
    'Suivi de commande',
    Icons.local_shipping_outlined,
    'Comment puis-je suivre ma commande ?',
  ),
  _Suggestion(
    'Retours & remboursements',
    Icons.assignment_return_outlined,
    'Quelle est la procédure pour retourner un article ?',
  ),
  _Suggestion(
    'Devenir vendeur',
    Icons.storefront_outlined,
    'Comment devenir vendeur sur NovAiShop ?',
  ),
  _Suggestion(
    'Moyens de paiement',
    Icons.credit_card_outlined,
    'Quels moyens de paiement sont acceptés ?',
  ),
  _Suggestion(
    'Livraison',
    Icons.schedule_outlined,
    'Quels sont les délais de livraison ?',
  ),
  _Suggestion(
    'Sécurité du compte',
    Icons.shield_outlined,
    'Comment sécuriser mon compte NovAiShop ?',
  ),
];

/// The NovAiShop AI assistant chat. A polished conversation UI with
/// animated message bubbles, a typing indicator and quick suggestions.
class AssistantTab extends StatefulWidget {
  const AssistantTab({super.key});

  @override
  State<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<AssistantTab> {
  static const _storageKey = 'novaishop.assistant.conversation';

  final _input = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];

  bool _sending = false;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _restoreConversation();
  }

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _restoreConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final restored = decoded
            .map((e) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (mounted) {
          setState(() => _messages.addAll(restored));
        }
      }
    } catch (_) {
      // Start from an empty conversation when restore fails.
    }
    if (mounted) {
      setState(() => _restored = true);
      _scrollToBottom();
    }
  }

  Future<void> _persistConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode([for (final m in _messages) m.toJson()]),
      );
    } catch (_) {
      // Persistence is best-effort.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 220,
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
    });
  }

  String _resolveRole() {
    final role = context.read<SessionScope>().role;
    return role?.apiRole ?? AccountRole.individualBuyer.apiRole;
  }

  Future<void> _send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _sending) return;
    if (text.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre message est trop court.'),
        ),
      );
      return;
    }

    _input.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(
        ChatMessage(
          author: ChatAuthor.user,
          text: text,
          timestamp: DateTime.now(),
        ),
      );
      _sending = true;
    });
    _scrollToBottom();

    try {
      final response = await context.read<AiRepository>().chat(
            role: _resolveRole(),
            message: text,
          );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            author: ChatAuthor.assistant,
            text: response.answer,
            timestamp: DateTime.now(),
            sources: response.sources,
          ),
        );
        _sending = false;
      });
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            author: ChatAuthor.assistant,
            text: error.message,
            timestamp: DateTime.now(),
            failed: true,
          ),
        );
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            author: ChatAuthor.assistant,
            text: 'Une erreur est survenue. Veuillez réessayer.',
            timestamp: DateTime.now(),
            failed: true,
          ),
        );
        _sending = false;
      });
    }
    _scrollToBottom();
    await _persistConversation();
  }

  Future<void> _clearConversation() async {
    setState(_messages.clear);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation effacée.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _messages.isNotEmpty;
    return SoftGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(
              title: 'Assistant IA',
              showBack: false,
              trailing: hasMessages
                  ? CircleIconButton(
                      icon: Icons.delete_outline_rounded,
                      onPressed: _clearConversation,
                      tooltip: 'Effacer la conversation',
                    )
                  : null,
            ),
          ),
          Expanded(
            child: !_restored
                ? const NovaLoadingView()
                : hasMessages
                    ? _ConversationView(
                        messages: _messages,
                        sending: _sending,
                        scrollController: _scrollController,
                      )
                    : _WelcomeView(onSuggestion: _send),
          ),
          _Composer(
            controller: _input,
            sending: _sending,
            onSend: () => _send(_input.text),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- welcome --------------------------- */

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        Center(
          child: Container(
            height: 96,
            width: 96,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 46,
              color: AppColors.ink,
            ),
          ).popIn(),
        ),
        const SizedBox(height: 20),
        Text(
          'Bonjour, comment puis-je vous aider ?',
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ).fadeSlideIn(),
        const SizedBox(height: 8),
        Text(
          'Posez votre question sur vos commandes, les retours, la vente '
          'ou le paiement. L\'assistant NovAiShop vous répond instantanément.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ).fadeSlideIn(delay: AppMotion.fast),
        const SizedBox(height: 24),
        Text('Suggestions', style: AppTypography.subtitle).fadeSlideIn(
          delay: AppMotion.normal,
        ),
        const SizedBox(height: 12),
        ...StaggeredEntrance.all(
          [
            for (final suggestion in _suggestions)
              _SuggestionTile(
                suggestion: suggestion,
                onTap: () => onSuggestion(suggestion.prompt),
              ),
          ],
          baseDelay: AppMotion.normal,
        ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              suggestion.icon,
              size: 20,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suggestion.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(
            Icons.north_east_rounded,
            size: 16,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

/* ------------------------- conversation ------------------------- */

class _ConversationView extends StatelessWidget {
  const _ConversationView({
    required this.messages,
    required this.sending,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final bool sending;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: messages.length + (sending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= messages.length) {
          return const _TypingIndicator();
        }
        return _MessageBubble(message: messages[index]);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isUser = message.isUser;
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isUser
            ? AppColors.deepInk
            : message.failed
                ? colors.blush
                : colors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: colors.isDark ? .3 : .06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: isUser ? AppColors.surface : colors.textPrimary,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isUser && message.sources.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final source in message.sources)
                  NovaBadge(
                    label: source,
                    icon: Icons.menu_book_outlined,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const _AssistantAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    ).fadeSlideIn(beginOffsetY: 0.12);
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 32,
      decoration: const BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 17,
        color: AppColors.ink,
      ),
    );
  }
}

/// Three pulsing dots shown while the assistant is generating a reply.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.colors.shadow.withValues(
                    alpha: context.colors.isDark ? .3 : .06,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                        child: _Dot(
                          progress: ((_controller.value + i * 0.22) % 1.0),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ).fadeSlideIn();
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    // A smooth up-down bounce: 0 -> 1 -> 0 across the cycle.
    final bounce = 1 - (progress * 2 - 1).abs();
    return Transform.translate(
      offset: Offset(0, -4 * bounce),
      child: Container(
        height: 7,
        width: 7,
        decoration: BoxDecoration(
          color: context.colors.textPrimary
              .withValues(alpha: 0.35 + 0.55 * bounce),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/* --------------------------- composer --------------------------- */

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: colors.isDark ? .35 : .07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Posez votre question…',
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(sending: sending, onTap: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onTap});

  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: sending ? 0.9 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      child: Material(
        color: sending ? context.colors.surfaceMuted : AppColors.lime,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: sending ? null : onTap,
          child: SizedBox(
            height: 48,
            width: 48,
            child: sending
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: context.colors.textPrimary,
                    ),
                  )
                : const Icon(
                    Icons.arrow_upward_rounded,
                    color: AppColors.ink,
                  ),
          ),
        ),
      ),
    );
  }
}
