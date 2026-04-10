class ChatMessage {
  final String text;
  final bool isUser; // true - сообщение от пользователя, false - от ИИ
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}