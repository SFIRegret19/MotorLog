import 'package:flutter_test/flutter_test.dart';
import 'package:motor_log/domain/entities/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('stores user message attributes', () {
      final timestamp = DateTime.utc(2026, 4, 12, 9, 0);
      final message = ChatMessage(
        text: 'Когда менять масло?',
        isUser: true,
        timestamp: timestamp,
      );

      expect(message.text, 'Когда менять масло?');
      expect(message.isUser, isTrue);
      expect(message.timestamp, timestamp);
    });

    test('stores assistant message attributes', () {
      final timestamp = DateTime.utc(2026, 4, 12, 9, 1);
      final message = ChatMessage(
        text: 'Проверьте регламент и текущий пробег.',
        isUser: false,
        timestamp: timestamp,
      );

      expect(message.text, contains('пробег'));
      expect(message.isUser, isFalse);
      expect(message.timestamp, timestamp);
    });
  });
}
