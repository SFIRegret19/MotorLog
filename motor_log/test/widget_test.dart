import 'package:flutter_test/flutter_test.dart';
import 'package:motor_log/main.dart';

void main() {
  testWidgets('Проверка запуска MotorLog', (WidgetTester tester) async {
    // Пытаемся запустить наше приложение (теперь оно называется MotorLogApp)
    await tester.pumpWidget(const MotorLogApp());

    // Проверяем, что на экране есть текст 'MotorLog'
    expect(find.text('MotorLog'), findsOneWidget);
  });
}
