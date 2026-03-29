import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor_log/core/theme/app_theme.dart';

void main() {
  testWidgets('renders a themed MotorLog shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('MotorLog')),
          body: const Center(
            child: Text('Ваш гараж пуст. Добавьте машину!'),
          ),
        ),
      ),
    );

    expect(find.text('MotorLog'), findsOneWidget);
    expect(find.text('Ваш гараж пуст. Добавьте машину!'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.theme?.scaffoldBackgroundColor, AppTheme.bgWhite);
  });
}
