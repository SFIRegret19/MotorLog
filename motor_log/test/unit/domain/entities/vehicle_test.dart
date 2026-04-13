import 'package:flutter_test/flutter_test.dart';
import 'package:motor_log/domain/entities/vehicle.dart';

void main() {
  group('Vehicle', () {
    test('toMap serializes all fields', () {
      final vehicle = Vehicle(
        id: 'vehicle-1',
        brand: 'BMW',
        model: 'X5',
        year: 2021,
        vin: 'VIN123456789',
        currentMileage: 45000,
      );

      expect(vehicle.toMap(), {
        'id': 'vehicle-1',
        'brand': 'BMW',
        'model': 'X5',
        'year': 2021,
        'vin': 'VIN123456789',
        'currentMileage': 45000,
      });
    });

    test('fromMap restores entity from persisted data', () {
      final vehicle = Vehicle.fromMap({
        'id': 'vehicle-2',
        'brand': 'Toyota',
        'model': 'Camry',
        'year': 2019,
        'vin': 'VIN000000001',
        'currentMileage': 78000,
      });

      expect(vehicle.id, 'vehicle-2');
      expect(vehicle.brand, 'Toyota');
      expect(vehicle.model, 'Camry');
      expect(vehicle.year, 2019);
      expect(vehicle.vin, 'VIN000000001');
      expect(vehicle.currentMileage, 78000);
    });

    test('toMap supports vehicles without id before persistence', () {
      final vehicle = Vehicle(
        brand: 'Kia',
        model: 'Rio',
        year: 2022,
        vin: 'VINNEWCAR',
        currentMileage: 1200,
      );

      expect(vehicle.toMap()['id'], isNull);
      expect(vehicle.toMap()['brand'], 'Kia');
      expect(vehicle.toMap()['currentMileage'], 1200);
    });
  });
}
