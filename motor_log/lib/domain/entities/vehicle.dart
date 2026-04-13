class Vehicle {
  final String? id; // Сделаем id необязательным для новых машин
  final String brand;
  final String model;
  final int year;
  final String vin;
  int currentMileage;
  int isSynced; // 0 = Offline, 1 = Online

  Vehicle({
    this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.vin,
    required this.currentMileage,
    this.isSynced = 0, // По умолчанию машина не синхронизирована
  });

  // Превращаем объект машины в таблицу для SQLite (Map)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'vin': vin,
      'currentMileage': currentMileage,
      'isSynced': isSynced,
    };
  }

  // Создаем объект машины из данных из базы
  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      brand: map['brand'],
      model: map['model'],
      year: map['year'],
      vin: map['vin'],
      currentMileage: map['currentMileage'],
      isSynced: map['isSynced'] ?? 0,
    );
  }
}
