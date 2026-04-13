class Consumable {
  final String id;
  final String vehicleId;
  final String name;
  final int resourceLimit;
  double currentWear;
  final String notes;
  final int initialMileage; // пробег детали при покупке

  Consumable({
    required this.id,
    required this.vehicleId,
    required this.name,
    required this.resourceLimit,
    required this.currentWear,
    this.notes = '',
    this.initialMileage = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'name': name,
      'resourceLimit': resourceLimit,
      'currentWear': currentWear,
      'notes': notes,
      'initialMileage': initialMileage,
    };
  }

  factory Consumable.fromMap(Map<String, dynamic> map) {
    return Consumable(
      id: map['id'],
      vehicleId: map['vehicleId'],
      name: map['name'],
      resourceLimit: map['resourceLimit'],
      currentWear: map['currentWear'],
      notes: map['notes'] ?? '',
      initialMileage: map['initialMileage'] ?? 0,
    );
  }
}