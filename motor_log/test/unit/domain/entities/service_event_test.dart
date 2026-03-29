import 'package:flutter_test/flutter_test.dart';
import 'package:motor_log/domain/entities/service_event.dart';

void main() {
  group('ServiceEvent', () {
    test('toMap serializes service event for persistence', () {
      final event = ServiceEvent(
        id: 'service-1',
        vehicleId: 'vehicle-1',
        date: '2026-03-29',
        mileage: 45200,
        totalCost: 12500.5,
        description: 'Плановое ТО с заменой масла',
      );

      expect(event.toMap(), {
        'id': 'service-1',
        'vehicleId': 'vehicle-1',
        'date': '2026-03-29',
        'mileage': 45200,
        'totalCost': 12500.5,
        'description': 'Плановое ТО с заменой масла',
      });
    });
  });
}
