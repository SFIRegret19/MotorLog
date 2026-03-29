class Consumable {
  final String id;
  final String vehicleId;
  final String name;
  final int resourceLimit;
  double currentWear; // В процентах от 0.0 до 1.0

  Consumable({
    required this.id,
    required this.vehicleId,
    required this.name,
    required this.resourceLimit,
    required this.currentWear,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'name': name,
      'resourceLimit': resourceLimit,
      'currentWear': currentWear,
    };
  }

  factory Consumable.fromMap(Map<String, dynamic> map) {
    return Consumable(
      id: map['id'],
      vehicleId: map['vehicleId'],
      name: map['name'],
      resourceLimit: map['resourceLimit'],
      currentWear: map['currentWear'],
    );
  }
}
