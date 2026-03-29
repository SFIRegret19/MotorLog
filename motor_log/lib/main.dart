import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/garage_screen.dart';

void main() async {
  // ЭТА СТРОКА ОБЯЗАТЕЛЬНА:
  // Она инициализирует связь между кодом Dart и нативной частью (Android/iOS)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MotorLogApp());
}

class MotorLogApp extends StatelessWidget {
  const MotorLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const GarageScreen(),
    );
  }
}
