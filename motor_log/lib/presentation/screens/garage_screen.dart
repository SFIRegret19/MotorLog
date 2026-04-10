import 'package:flutter/material.dart';
import '../../data/datasources/db_helper.dart';
import '../../domain/entities/vehicle.dart';
import '../../core/theme/app_theme.dart';
import 'add_vehicle_screen.dart';
import 'consumables_screen.dart';
import 'ai_chat_screen.dart';
import 'add_fuel_screen.dart';
import 'statistics_screen.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  List<Vehicle> _vehicles =[];
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

  // МЕТОД ДЛЯ УДАЛЕНИЯ 
  void _deleteVehicle(String id) async {
    await DbHelper.instance.deleteVehicle(id);
    _refreshVehicles(); // Обновляем список после удаления
  }

  // ДИАЛОГ ПОДТВЕРЖДЕНИЯ УДАЛЕНИЯ 
  void _showDeleteDialog(Vehicle car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: Text(
          'Вы уверены, что хотите удалить ${car.brand} ${car.model} из гаража?',
        ),
        actions:[
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

  // ДИАЛОГ ОБНОВЛЕНИЯ ПРОБЕГА 
  void _showUpdateMileageDialog(Vehicle car) {
    final controller = TextEditingController(text: car.currentMileage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновить пробег'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Текущий пробег (км)',
            border: OutlineInputBorder(),
          ),
        ),
        actions:[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
            onPressed: () async {
              final newMileage = int.tryParse(controller.text);
              if (newMileage != null && newMileage >= car.currentMileage) {
                // Вызываем метод обновления в БД
                await DbHelper.instance.updateVehicleMileage(car.id!, newMileage);
                if (!mounted) return;
                Navigator.pop(context);
                _refreshVehicles();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пробег обновлен! Износ деталей пересчитан.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пробег не может быть меньше текущего!')),
                );
              }
            },
            child: const Text('Сохранить', style: TextStyle(color: Colors.black)),
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
                          children:[
                            // ШАПКА КАРТОЧКИ (Аватар, название, корзина)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:[
                                Row(
                                  children:[
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
                            
                            // СТРОКА ПРОБЕГА
                            Row(
                              children:[
                                Text(
                                  'Пробег: ${car.currentMileage} км',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note, color: AppTheme.accentPurple),
                                  onPressed: () => _showUpdateMileageDialog(car),
                                  tooltip: 'Обновить пробег',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // --- СЕТКА КНОПОК 2x2 ---
                            Column(
                              children:[
                                Row(
                                  children:[
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryPurple,
                                          minimumSize: const Size(0, 45),
                                        ),
                                        icon: const Icon(Icons.build, color: AppTheme.accentPurple, size: 18),
                                        label: const Text('ТО', style: TextStyle(color: Colors.black)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => ConsumablesScreen(vehicleId: car.id!)),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.accentPurple, // Выделяем цветом
                                          minimumSize: const Size(0, 45),
                                        ),
                                        icon: const Icon(Icons.local_gas_station, color: Colors.white, size: 18),
                                        label: const Text('Заправка', style: TextStyle(color: Colors.white)),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddFuelScreen(vehicleId: car.id!, currentMileage: car.currentMileage),
                                            ),
                                          );
                                          if (result == true) _refreshVehicles();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children:[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.accentPurple,
                                          side: const BorderSide(color: AppTheme.accentPurple),
                                          minimumSize: const Size(0, 45),
                                        ),
                                        icon: const Icon(Icons.bar_chart, size: 18),
                                        label: const Text('Статистика'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => StatisticsScreen(vehicleId: car.id!)),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.accentPurple,
                                          side: const BorderSide(color: AppTheme.accentPurple),
                                          minimumSize: const Size(0, 45),
                                        ),
                                        icon: const Icon(Icons.smart_toy, size: 18),
                                        label: const Text('AI-Совет'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AiChatScreen(carInfo: '${car.brand} ${car.model}'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // -----------------------------
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