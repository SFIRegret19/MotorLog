import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/consumable.dart';

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
  Future<void> initDefaultConsumables(String vehicleId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> defaults = [
      {'name': 'Масло моторное', 'limit': 10000},
      {'name': 'Фильтр масляный', 'limit': 10000},
      {'name': 'Тормозные колодки', 'limit': 30000},
    ];

    for (int i = 0; i < defaults.length; i++) {
      final item = defaults[i];
      await db.insert('consumables', {
        // Создаем уникальный ID: ID_машины + индекс + название
        'id': '${vehicleId}_${i}_${item['name']}',
        'vehicleId': vehicleId,
        'name': item['name'],
        'resourceLimit': item['limit'],
        'currentWear': 0.05,
      });
    }
  }
}
