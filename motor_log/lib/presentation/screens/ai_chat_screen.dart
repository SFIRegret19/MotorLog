import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';

class AiChatScreen extends StatefulWidget {
  final String carInfo; // Передаем инфу о машине, чтобы ИИ "знал" о ней
  const AiChatScreen({super.key, required this.carInfo});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages =[];
  bool _isTyping = false; // Флаг для анимации "ИИ печатает..."

  @override
  void initState() {
    super.initState();
    // Приветственное сообщение от ИИ
    _messages.add(ChatMessage(
      text: 'Привет! Я твой MotorLog-ассистент. Я вижу, у тебя ${widget.carInfo}. Чем могу помочь?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // МЕТОД, КОТОРЫЙ В БУДУЩЕМ ЗАМЕНИТСЯ НА РЕАЛЬНЫЙ ЗАПРОС К НЕЙРОСЕТИ
  Future<String> _getMockAiResponse(String userText) async {
    final text = userText.toLowerCase();
    
    // Имитация задержки сети
    await Future.delayed(const Duration(seconds: 2));

    // Простая логика моков по ключевым словам
    if (text.contains('масло')) {
      return 'Для вашего авто лучше использовать синтетическое масло 5W-30. Регламент замены - каждые 7500 км.';
    } else if (text.contains('то') || text.contains('обслуживани')) {
      return 'На вашем текущем пробеге рекомендуется проверить ремень ГРМ, заменить масляный фильтр и осмотреть тормозные колодки.';
    } else if (text.contains('погод') || text.contains('зим')) {
      return 'Скоро холода! Не забудьте проверить плотность антифриза и переобуть резину. Давление в шинах зимой лучше держать на 0.2 бара выше нормы.';
    }
    return 'Интересный вопрос! В альфа-версии я знаю только про масло, ТО и погоду. В будущем я отвечу на всё!';
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text;
    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true, timestamp: DateTime.now()));
      _controller.clear();
      _isTyping = true; // Показываем индикатор загрузки
    });

    // Получаем ответ от ИИ (пока от мока)
    final aiResponse = await _getMockAiResponse(userText);

    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: aiResponse, isUser: false, timestamp: DateTime.now()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const[
            Icon(Icons.smart_toy, color: AppTheme.accentPurple),
            SizedBox(width: 8),
            Text('Motor AI'),
          ],
        ),
      ),
      body: Column(
        children:[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ассистент печатает...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.accentPurple : AppTheme.primaryPurple.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8).copyWith(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children:[
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Спросите совет по авто...',
                filled: true,
                fillColor: AppTheme.primaryPurple.withOpacity(0.2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.accentPurple,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}