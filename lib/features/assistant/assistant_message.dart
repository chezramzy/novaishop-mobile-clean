/// The author of a chat message.
enum ChatAuthor { user, assistant }

/// A single message in the AI assistant conversation.
class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.text,
    required this.timestamp,
    this.sources = const [],
    this.failed = false,
  });

  final ChatAuthor author;
  final String text;
  final DateTime timestamp;

  /// Knowledge sources cited by the assistant (assistant messages only).
  final List<String> sources;

  /// Whether the message represents a failed send (user messages only).
  final bool failed;

  bool get isUser => author == ChatAuthor.user;

  ChatMessage copyWith({bool? failed}) {
    return ChatMessage(
      author: author,
      text: text,
      timestamp: timestamp,
      sources: sources,
      failed: failed ?? this.failed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author.name,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'sources': sources,
      'failed': failed,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      author: (json['author'] as String?) == 'user'
          ? ChatAuthor.user
          : ChatAuthor.assistant,
      text: json['text'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      sources: ((json['sources'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      failed: json['failed'] as bool? ?? false,
    );
  }
}
