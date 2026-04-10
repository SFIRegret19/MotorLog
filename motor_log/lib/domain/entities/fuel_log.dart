class FuelLog {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int odometer; // Пробег на момент заправки
  final double liters; // Залито литров
  final double pricePerLiter; // Цена за литр
  final double totalCost; // Итоговая стоимость

  FuelLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
  });

  // В Базу Данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'odometer': odometer,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'totalCost': totalCost,
    };
  }

  // ИЗ Базы Данных (ЭТОГО МЕТОДА НЕ ХВАТАЛО)
  factory FuelLog.fromMap(Map<String, dynamic> map) {
    return FuelLog(
      id: map['id'],
      vehicleId: map['vehicleId'],
      date: DateTime.parse(map['date']), // Возвращаем строку обратно в дату
      odometer: map['odometer'],
      liters: map['liters'],
      pricePerLiter: map['pricePerLiter'],
      totalCost: map['totalCost'],
    );
  }
}