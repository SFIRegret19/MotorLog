import 'package:flutter_test/flutter_test.dart';
import 'package:motor_log/data/api_client/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeatherService', () {
    test('WeatherInfo stores weather data for widget rendering', () {
      final info = WeatherInfo(
        temp: '5°C',
        description: 'пасмурно',
        advice: 'Проверьте состояние щеток стеклоочистителя.',
      );

      expect(info.temp, '5°C');
      expect(info.description, 'пасмурно');
      expect(info.advice, contains('щеток'));
    });

    test('getCurrentWeatherAndAdvice returns null when platform services are unavailable', () async {
      final service = WeatherService();
      final result = await service.getCurrentWeatherAndAdvice();
      expect(result, isNull);
    });
  });
}
