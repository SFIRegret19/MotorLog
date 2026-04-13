import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/vehicle.dart';
import '../datasources/db_helper.dart';

class SyncManager {
  final Dio _dio = Dio();
  
  // БЕРЕМ АДРЕС СЕРВЕРА ИЗ .env ФАЙЛА (если его там нет, используем заглушку)
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000'; 

  Future<int> syncVehicles() async {
    int syncedCount = 0;
    
    try {
      // 1. Достаем из SQLite все машины с isSynced == 0
      List<Vehicle> unsyncedVehicles = await DbHelper.instance.getUnsyncedVehicles();

      if (unsyncedVehicles.isEmpty) {
        return 0; // Синхронизировать нечего
      }

      // 2. Отправляем каждую машину на Python-сервер
      for (var car in unsyncedVehicles) {
        final response = await _dio.post(
          '$_baseUrl/api/sync/vehicle',
          data: car.toMap(),
        );

        if (response.statusCode == 200) {
          // 3. Если сервер ответил 200 (ОК), помечаем в SQLite как isSynced = 1
          await DbHelper.instance.markVehicleAsSynced(car.id!);
          syncedCount++;
        }
      }
      return syncedCount;
    } catch (e) {
      print("Ошибка синхронизации: $e");
      return -1; // Ошибка сети
    }
  }
}