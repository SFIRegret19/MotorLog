class ServiceEvent {
  final String id;
  final String vehicleId;
  final String date;
  final int mileage;
  final double totalCost;
  final String description;

  ServiceEvent({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.mileage,
    required this.totalCost,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date,
      'mileage': mileage,
      'totalCost': totalCost,
      'description': description,
    };
  }
}
