import 'package:flutter_test/flutter_test.dart';
import 'package:motor_log/domain/entities/consumable.dart';

void main() {
  group('Consumable', () {
    test('toMap serializes current state for database storage', () {
      final consumable = Consumable(
        id: 'consumable-1',
        vehicleId: 'vehicle-1',
        name: 'Моторное масло',
        resourceLimit: 10000,
        currentWear: 0.35,
      );

      expect(consumable.toMap(), {
        'id': 'consumable-1',
        'vehicleId': 'vehicle-1',
        'name': 'Моторное масло',
        'resourceLimit': 10000,
        'currentWear': 0.35,
      });
    });

    test('fromMap restores consumable with wear value', () {
      final consumable = Consumable.fromMap({
        'id': 'consumable-2',
        'vehicleId': 'vehicle-2',
        'name': 'Тормозные колодки',
        'resourceLimit': 30000,
        'currentWear': 0.8,
      });

      expect(consumable.id, 'consumable-2');
      expect(consumable.vehicleId, 'vehicle-2');
      expect(consumable.name, 'Тормозные колодки');
      expect(consumable.resourceLimit, 30000);
      expect(consumable.currentWear, 0.8);
    });
  });
}
