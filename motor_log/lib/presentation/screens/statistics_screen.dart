import 'package:flutter/material.dart';
import '../../data/datasources/db_helper.dart';
import '../../domain/entities/fuel_log.dart';
import '../../core/theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  final String vehicleId;
  const StatisticsScreen({super.key, required this.vehicleId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<FuelLog> _logs =[];
  bool _isLoading = true;

  // Переменные для статистики
  double _totalSpent = 0.0;
  double _totalLiters = 0.0;
  double _averageConsumption = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() async {
    final logs = await DbHelper.instance.getFuelLogs(widget.vehicleId);
    
    double spent = 0;
    double liters = 0;
    double avg = 0;

    if (logs.isNotEmpty) {
      for (var log in logs) {
        spent += log.totalCost;
        liters += log.liters;
      }

      // Для расчета расхода нужно минимум 2 заправки, чтобы узнать пройденную дистанцию
      if (logs.length >= 2) {
        // Сортируем по пробегу по возрастанию
        logs.sort((a, b) => a.odometer.compareTo(b.odometer));
        int distance = logs.last.odometer - logs.first.odometer;
        
        if (distance > 0) {
          // Убираем литры первой заправки из расчета, так как это была "отправная точка"
          double litersForDistance = liters - logs.first.liters;
          avg = (litersForDistance / distance) * 100;
        }
      }
    }

    setState(() {
      _logs = logs;
      _totalSpent = spent;
      _totalLiters = liters;
      _averageConsumption = avg;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика авто')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:[
                  // КАРТОЧКА СРЕДНЕГО РАСХОДА
                  _buildStatCard(
                    title: 'Средний расход',
                    value: _logs.length >= 2 ? '${_averageConsumption.toStringAsFixed(1)} л/100 км' : 'Мало данных',
                    icon: Icons.speed,
                    color: Colors.orangeAccent,
                    subtitle: _logs.length < 2 ? 'Добавьте еще заправки для расчета' : null,
                  ),
                  const SizedBox(height: 12),

                  // РЯД ИЗ ДВУХ КАРТОЧЕК (ДЕНЬГИ И ЛИТРЫ)
                  Row(
                    children:[
                      Expanded(
                        child: _buildStatCard(
                          title: 'Потрачено',
                          value: '${_totalSpent.toStringAsFixed(0)} ₽',
                          icon: Icons.account_balance_wallet,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Залито',
                          value: '${_totalLiters.toStringAsFixed(0)} л',
                          icon: Icons.local_gas_station,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('История заправок:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // ИСТОРИЯ ЗАПРАВОК
                  Expanded(
                    child: _logs.isEmpty
                        ? const Center(child: Text('Нет данных о заправках'))
                        : ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              // Сортируем для вывода от новых к старым
                              _logs.sort((a, b) => b.date.compareTo(a.date));
                              final log = _logs[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppTheme.primaryPurple,
                                    child: Icon(Icons.ev_station, color: AppTheme.accentPurple),
                                  ),
                                  title: Text('${log.liters} л  •  ${log.totalCost.toStringAsFixed(0)} ₽'),
                                  subtitle: Text('Пробег: ${log.odometer} км'),
                                  trailing: Text(
                                    '${log.date.day}.${log.date.month}.${log.date.year}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // Вспомогательный виджет для красивых карточек
  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryPurple, width: 1.5),
        boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.redAccent)),
          ]
        ],
      ),
    );
  }
}