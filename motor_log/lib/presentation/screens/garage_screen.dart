import 'package:flutter/material.dart';
import '../../data/datasources/db_helper.dart';
import '../../domain/entities/vehicle.dart';
import '../../core/theme/app_theme.dart';
import 'add_vehicle_screen.dart';
import 'consumables_screen.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshVehicles();
  }

  // Метод для загрузки машин из базы данных
  void _refreshVehicles() async {
    final data = await DbHelper.instance.getVehicles();
    setState(() {
      _vehicles = data;
      _isLoading = false;
    });
  }

  // МЕТОД ДЛЯ УДАЛЕНИЯ (Новое)
  void _deleteVehicle(String id) async {
    await DbHelper.instance.deleteVehicle(id);
    _refreshVehicles(); // Обновляем список после удаления
  }

  // ДИАЛОГ ПОДТВЕРЖДЕНИЯ УДАЛЕНИЯ (Новое)
  void _showDeleteDialog(Vehicle car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: Text(
          'Вы уверены, что хотите удалить ${car.brand} ${car.model} из гаража?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _deleteVehicle(car.id!);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MotorLog')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
          ? const Center(child: Text('Ваш гараж пуст. Добавьте машину!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final car = _vehicles[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppTheme.primaryPurple,
                                  child: Icon(
                                    Icons.directions_car,
                                    color: AppTheme.accentPurple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${car.brand} ${car.model}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // КНОПКА УДАЛЕНИЯ (Новое)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _showDeleteDialog(car),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Пробег: ${car.currentMileage} км',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ConsumablesScreen(vehicleId: car.id!),
                              ),
                            );
                          },
                          child: const Text(
                            'Детали ТО',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryPurple,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
          if (result == true) _refreshVehicles();
        },
        child: const Icon(Icons.add, color: AppTheme.accentPurple),
      ),
    );
  }
}