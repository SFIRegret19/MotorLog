import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/consumable.dart';
import '../../domain/entities/fuel_log.dart';
import '../../domain/entities/service_event.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('motorlog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. Таблица Автомобилей (Vehicle)
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        brand TEXT,
        model TEXT,
        year INTEGER,
        vin TEXT,
        currentMileage INTEGER
      )
    ''');

    // 2. Таблица Расходников (Consumable) - добавлена связь vehicleId
    await db.execute('''
      CREATE TABLE consumables (
        id TEXT PRIMARY KEY,
        vehicleId TEXT,
        name TEXT,
        resourceLimit INTEGER,
        currentWear REAL, 
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    // 3. Таблица Сервисных событий (ServiceEvent) - из твоей диаграммы
    await db.execute('''
      CREATE TABLE service_events (
        id TEXT PRIMARY KEY,
        vehicleId TEXT,
        date TEXT,
        mileage INTEGER,
        totalCost REAL,
        description TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    // 4. Расписание обслуживания (MaintenanceSchedule)
    await db.execute('''
      CREATE TABLE maintenance_schedules (
        id TEXT PRIMARY KEY,
        vehicleId TEXT,
        title TEXT,
        intervalKm INTEGER,
        intervalDays INTEGER,
        lastServiceMileage INTEGER,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    // 5. Таблица Заправок (Fuel Logs)
    await db.execute('''
      CREATE TABLE fuel_logs (
        id TEXT PRIMARY KEY,
        vehicleId TEXT,
        date TEXT,
        odometer INTEGER,
        liters REAL,
        pricePerLiter REAL,
        totalCost REAL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');
  }



  // --- МЕТОДЫ ДЛЯ РАБОТЫ С МАШИНАМИ ---

  // Метод для вставки авто
  Future<void> insertVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    await db.insert(
      'vehicles',
      vehicle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Метод получения авто
  Future<List<Vehicle>> getVehicles() async {
    final db = await instance.database;
    final result = await db.query('vehicles');
    // Превращаем List<Map> в List<Vehicle>
    return result.map((json) => Vehicle.fromMap(json)).toList();
  }

  // Метод удаления авто
  Future<void> deleteVehicle(String id) async {
    final db = await instance.database;
    // Благодаря ON DELETE CASCADE в структуре БД,
    // при удалении машины её расходники удалятся автоматически
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

// ОБНОВЛЕНИЕ ПРОБЕГА С УМНЫМ РАСЧЕТОМ ИЗНОСА
  Future<void> updateVehicleMileage(String vehicleId, int newMileage) async {
    final db = await instance.database;

    // 1. Получаем текущие данные машины, чтобы узнать старый пробег
    final vehicleMaps = await db.query('vehicles', where: 'id = ?', whereArgs: [vehicleId]);
    if (vehicleMaps.isEmpty) return;
    
    final int oldMileage = vehicleMaps.first['currentMileage'] as int;
    final int delta = newMileage - oldMileage;

    // Проблема 1: Если пробег не изменился или стал меньше (ошибка ввода), ничего не считаем
    if (delta <= 0) return;

    // 2. Обновляем пробег в таблице машин
    await db.update('vehicles', {'currentMileage': newMileage}, where: 'id = ?', whereArgs: [vehicleId]);

    // 3. Получаем все расходники этой машины
    final consumables = await getConsumables(vehicleId);

    for (var item in consumables) {
      // Проблема 2: Рассчитываем износ индивидуально!
      // Рост износа = пройденное расстояние / лимит ресурса этой детали
      double wearIncrease = delta / item.resourceLimit;
      
      // Обновляем значение, ограничивая его максимумом 1.0 (100%)
      item.currentWear = (item.currentWear + wearIncrease).clamp(0.0, 1.0);
      
      await updateConsumable(item);
    }
  }

  // --- МЕТОДЫ ДЛЯ РАБОТЫ С РАСХОДНИКАМИ ---

  Future<List<Consumable>> getConsumables(String vehicleId) async {
    final db = await instance.database;
    final result = await db.query(
      'consumables',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
    // Превращаем List<Map> в List<Consumable>
    return result.map((json) => Consumable.fromMap(json)).toList();
  }

  Future<void> insertConsumable(dynamic item) async {
    final db = await instance.database;
    await db.insert('consumables', item.toMap());
  }

  Future<void> updateConsumable(Consumable item) async {
    final db = await instance.database;
    await db.update(
      'consumables',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteConsumable(String id) async {
    final db = await instance.database;
    await db.delete('consumables', where: 'id = ?', whereArgs: [id]);
  }

  // Авто-генерация расходников для новой машины
  // Настройка реалистичных лимитов при создании машины
  Future<void> initDefaultConsumables(String vehicleId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> defaults = [
      {'name': 'Масло моторное', 'limit': 7500},     // Ресурс 7.5к км
      {'name': 'Фильтр воздушный', 'limit': 15000},  // Ресурс 15к км
      {'name': 'Тормозные колодки', 'limit': 30000}, // Ресурс 30к км
    ];

    for (int i = 0; i < defaults.length; i++) {
      final item = defaults[i];
      await db.insert('consumables', {
        'id': '${vehicleId}_${i}', 
        'vehicleId': vehicleId,
        'name': item['name'],
        'resourceLimit': item['limit'], // Используем индивидуальный лимит
        'currentWear': 0.0, // Новая машина - 0% износа
      });
    }
  }


  // --- МЕТОДЫ ДЛЯ ЗАПРАВОК (FUEL LOGS) ---

  Future<void> insertFuelLog(FuelLog log) async {
    final db = await instance.database;
    await db.insert('fuel_logs', log.toMap());

    // УМНАЯ ЛОГИКА: Проверяем, если пробег на заправке больше текущего пробега авто
    final vehicleMaps = await db.query('vehicles', where: 'id = ?', whereArgs: [log.vehicleId]);
    if (vehicleMaps.isNotEmpty) {
      final currentMileage = vehicleMaps.first['currentMileage'] as int;
      if (log.odometer > currentMileage) {
        // Вызываем НАШ ЖЕ метод обновления пробега!
        // Он сам обновит цифру у машины и пересчитает износ всех расходников!
        await updateVehicleMileage(log.vehicleId, log.odometer);
      }
    }
  }

  Future<List<FuelLog>> getFuelLogs(String vehicleId) async {
    final db = await instance.database;
    final result = await db.query('fuel_logs', where: 'vehicleId = ?', whereArgs: [vehicleId], orderBy: 'odometer DESC');
    // Чтобы этот код не светился красным, убедись, что создал файл fuel_log.dart с методом fromMap (я давал его в прошлом сообщении)
    return result.map((json) => FuelLog.fromMap(json)).toList();
  }

  // --- МЕТОДЫ ДЛЯ СЕРВИСНЫХ СОБЫТИЙ (SERVICE EVENTS) ---
  Future<void> insertServiceEvent(ServiceEvent event) async {
    final db = await instance.database;
    await db.insert('service_events', event.toMap());
  }

  Future<List<ServiceEvent>> getServiceEvents(String vehicleId) async {
    final db = await instance.database;
    final result = await db.query('service_events', where: 'vehicleId = ?', whereArgs: [vehicleId]);
    return result.map((json) => ServiceEvent(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      date: json['date'] as String,
      mileage: json['mileage'] as int,
      totalCost: json['totalCost'] as double,
      description: json['description'] as String,
    )).toList();
  }
}