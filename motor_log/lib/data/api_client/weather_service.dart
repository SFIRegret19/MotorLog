import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherInfo {
  final String temp;
  final String description;
  final String advice;

  WeatherInfo({
    required this.temp,
    required this.description,
    required this.advice,
  });
}

class WeatherService {
  static final String _apiKey =
      dotenv.env['WEATHER_API_KEY'] ?? ''; // API ключ OpenWeather
  final Dio _dio = Dio();

  Future<WeatherInfo?> getCurrentWeatherAndAdvice() async {
    try {
      // 1. Проверяем разрешения на GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null; // GPS выключен

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      // 2. Получаем координаты (Широта и Долгота)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Делаем запрос к OpenWeather
      final response = await _dio.get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: {
          'lat': position.latitude,
          'lon': position.longitude,
          'appid': _apiKey,
          'units': 'metric', // Градусы Цельсия
          'lang': 'ru', // Русский язык описания
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final double temp = data['main']['temp'];
        final String description = data['weather'][0]['description'];
        final int weatherId = data['weather'][0]['id'];

        // 4. ГЕНЕРИРУЕМ УМНЫЙ СОВЕТ НА ОСНОВЕ ПОГОДЫ
        String advice =
            "Отличная погода для поездки! Не забывайте пристегиваться.";

        if (temp < 0) {
          advice =
              "Ожидается гололедица. Проверьте давление в шинах и залейте зимнюю омывайку.";
        } else if (temp > 30) {
          advice =
              "Жара! Следите за температурой двигателя и уровнем антифриза.";
        } else if (weatherId >= 200 && weatherId < 600) {
          // Дождь или гроза
          advice =
              "Осадки и снижение видимости. Проверьте состояние щеток стеклоочистителя.";
        } else if (weatherId >= 600 && weatherId < 700) {
          // Снег
          advice =
              "Снег! Будьте осторожны, держите дистанцию и проверьте заряд АКБ.";
        }

        return WeatherInfo(
          temp: '${temp.round()}°C',
          description: description,
          advice: advice,
        );
      }
    } catch (e) {
      print("Ошибка погоды: $e");
      return null;
    }
    return null;
  }
}
