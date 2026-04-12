import 'package:flutter_test/flutter_test.dart';
import 'package:motor_log/domain/entities/fuel_log.dart';

void main() {
  group('FuelLog', () {
    test('toMap serializes values and converts date to ISO string', () {
      final log = FuelLog(
        id: 'fuel-1',
        vehicleId: 'vehicle-1',
        date: DateTime.utc(2026, 4, 12, 14, 30),
        odometer: 50500,
        liters: 42.5,
        pricePerLiter: 57.8,
        totalCost: 2456.5,
      );

      expect(log.toMap(), {
        'id': 'fuel-1',
        'vehicleId': 'vehicle-1',
        'date': '2026-04-12T14:30:00.000Z',
        'odometer': 50500,
        'liters': 42.5,
        'pricePerLiter': 57.8,
        'totalCost': 2456.5,
      });
    });

    test('fromMap restores log including parsed DateTime', () {
      final log = FuelLog.fromMap({
        'id': 'fuel-2',
        'vehicleId': 'vehicle-7',
        'date': '2026-03-01T10:15:00.000Z',
        'odometer': 81234,
        'liters': 36.0,
        'pricePerLiter': 60.5,
        'totalCost': 2178.0,
      });

      expect(log.id, 'fuel-2');
      expect(log.vehicleId, 'vehicle-7');
      expect(log.date, DateTime.utc(2026, 3, 1, 10, 15));
      expect(log.odometer, 81234);
      expect(log.liters, 36.0);
      expect(log.pricePerLiter, 60.5);
      expect(log.totalCost, 2178.0);
    });
  });
}
