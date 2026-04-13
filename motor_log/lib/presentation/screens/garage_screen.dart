import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; 

import '../../data/datasources/db_helper.dart';
import '../../domain/entities/vehicle.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api_client/weather_service.dart';
import '../../data/sync_manager/sync_manager.dart';
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

  WeatherInfo? _weatherInfo;
  bool _isWeatherLoading = true;

  bool _isOnline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _refreshVehicles();
    _loadWeather();
    _initConnectivity(); 
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); 
    super.dispose();
  }

  void _initConnectivity() {
    Connectivity().checkConnectivity().then((results) {
      if (!results.contains(ConnectivityResult.none)) {
        _autoSync();
      }
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        _autoSync();
      } else {
        if (mounted) {
          setState(() => _isOnline = false);
        }
      }
    });
  }
  
  void _autoSync() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() => _isOnline = false); 
      }
      return; 
    }

    final syncManager = SyncManager();
    final count = await syncManager.syncVehicles();
    
    if (mounted) {
      setState(() {
        _isOnline = (count != -1);
      });

      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Авто-синхронизация: отправлено $count записей'), 
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _loadWeather() async {
    setState(() { _isWeatherLoading = true; });
    final weatherService = WeatherService();
    final info = await weatherService.getCurrentWeatherAndAdvice();
    if (mounted) {
      setState(() {
        _weatherInfo = info;
        _isWeatherLoading = false;
      });
    }
  }

  void _refreshVehicles() async {
    final data = await DbHelper.instance.getVehicles();
    setState(() {
      _vehicles = data;
      _isLoading = false;
    });
  }

  void _deleteVehicle(String id) async {
    await DbHelper.instance.deleteVehicle(id);
    _refreshVehicles();
  }

  void _showDeleteDialog(Vehicle car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автомобиль?'),
        content: Text('Вы уверены, что хотите удалить ${car.brand} ${car.model} из гаража?'),
        actions:[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
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

  void _showUpdateMileageDialog(Vehicle car) {
    final controller = TextEditingController(text: car.currentMileage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновить пробег'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Текущий пробег (км)', border: OutlineInputBorder()),
        ),
        actions:[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
            onPressed: () async {
              final newMileage = int.tryParse(controller.text);
              if (newMileage != null && newMileage >= car.currentMileage) {
                await DbHelper.instance.updateVehicleMileage(car.id!, newMileage);
                if (!mounted) return;
                Navigator.pop(context);
                _refreshVehicles();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пробег обновлен! Износ деталей пересчитан.')),
                );
                _autoSync(); 
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

  Widget _buildWeatherWidget() {
    if (_isWeatherLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blue[100]!, width: 1.5),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_weatherInfo == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[400]!, width: 1.5),
        ),
        child: Row(
          children:[
            const Icon(Icons.location_off, color: Colors.grey, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  const Text('Погода недоступна', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Включите GPS и интернет, затем нажмите обновить.', 
                      style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              onPressed: _loadWeather,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue[100]!, width: 1.5),
      ),
      child: Row(
        children:[
          const Icon(Icons.cloud_sync, color: Colors.blue, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text('${_weatherInfo!.description}, ${_weatherInfo!.temp}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(_weatherInfo!.advice, style: TextStyle(fontSize: 12, color: Colors.blue[900])),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _loadWeather),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // ЗАГОЛОВОК ПО ЦЕНТРУ
        title: const Text('MotorLog'),
        actions:[
          // ИНДИКАТОР СПРАВА
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isOnline ? Colors.green : Colors.red),
              ),
              child: Row(
                children:[
                  Icon(
                    _isOnline ? Icons.cloud_done : Icons.cloud_off, 
                    size: 14, 
                    color: _isOnline ? Colors.green[700] : Colors.red[700]
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                      color: _isOnline ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children:[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildWeatherWidget(),
                ),
                Expanded(
                  child: _vehicles.isEmpty
                      ? const Center(child: Text('Ваш гараж пуст. Добавьте машину!'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _vehicles.length,
                          itemBuilder: (context, index) {
                            final car = _vehicles[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children:[
                                            const CircleAvatar(
                                              backgroundColor: AppTheme.primaryPurple,
                                              child: Icon(Icons.directions_car, color: AppTheme.accentPurple),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '${car.brand} ${car.model}',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _showDeleteDialog(car),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children:[
                                        const SizedBox(width: 8),
                                        Text('Пробег: ${car.currentMileage} км', style: const TextStyle(fontSize: 15)),
                                        IconButton(
                                          icon: const Icon(Icons.edit_note, color: AppTheme.accentPurple, size: 20),
                                          onPressed: () => _showUpdateMileageDialog(car),
                                          tooltip: 'Обновить пробег',
                                        ),
                                      ],
                                    ),
                                    
                                    // --- ОТОБРАЖЕНИЕ VIN НОМЕРА ---
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'VIN: ${car.vin}',
                                          style: TextStyle(
                                            fontSize: 12, 
                                            color: Colors.grey[700], 
                                            fontFamily: 'monospace',
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),

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
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ConsumablesScreen(vehicleId: car.id!)));
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.accentPurple,
                                                  minimumSize: const Size(0, 45),
                                                ),
                                                icon: const Icon(Icons.local_gas_station, color: Colors.white, size: 18),
                                                label: const Text('Заправка', style: TextStyle(color: Colors.white)),
                                                onPressed: () async {
                                                  final result = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => AddFuelScreen(vehicleId: car.id!, currentMileage: car.currentMileage)),
                                                  );
                                                  if (result == true) {
                                                    _refreshVehicles();
                                                    _autoSync(); 
                                                  }
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
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen(vehicleId: car.id!)));
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
                                                    MaterialPageRoute(builder: (context) => AiChatScreen(carInfo: '${car.brand} ${car.model}')),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryPurple,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
          if (result == true) {
            _refreshVehicles();
            _autoSync(); 
          }
        },
        child: const Icon(Icons.add, color: AppTheme.accentPurple),
      ),
    );
  }
}